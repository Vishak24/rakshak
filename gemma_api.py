"""
Rakshak 2.0 — Local Safety Mesh API
Gemma 4 via Ollama | Offline-resilient | Port 5001
"""
import json
import math
import sys
import uuid
from datetime import datetime, timezone

import ollama
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app, origins=[
    'https://rakshak-police.pages.dev',
    'https://rakshak-citizen-app.pages.dev',
    'http://localhost:5173',
])

# Swap to 'gemma4:e2b' when the model is pulled locally
MODEL = 'gemma3:4b'

SAFETY_RULE = (
    "This is a safety-critical system serving women in Chennai. "
    "False negatives — predicting safe when dangerous — are unacceptable. "
    "Err toward caution."
)

# ── In-memory database proxies ────────────────────────────────────────────────

ACTIVE_INCIDENTS: list[dict] = []

PATROL_UNITS: list[dict] = [
    {"unit_id": "PATROL_1", "name": "Mylapore Mobile Car",        "lat": 13.0330, "lng": 80.2690, "status": "AVAILABLE"},
    {"unit_id": "PATROL_2", "name": "T. Nagar Interceptor",        "lat": 13.0418, "lng": 80.2337, "status": "AVAILABLE"},
    {"unit_id": "PATROL_3", "name": "Marina Beach Quick Response", "lat": 13.0500, "lng": 80.2824, "status": "AVAILABLE"},
]

# ── Helpers ───────────────────────────────────────────────────────────────────

def _generate(prompt: str) -> str:
    response = ollama.generate(model=MODEL, prompt=prompt)
    return response.response


def _strip_json(text: str) -> str:
    """Remove markdown code fences Gemma sometimes wraps around JSON."""
    text = text.strip()
    if text.startswith('```'):
        lines = text.splitlines()
        lines = lines[1:]
        if lines and lines[-1].strip() == '```':
            lines = lines[:-1]
        text = '\n'.join(lines).strip()
    return text


def _parse_json(text: str, fallback: dict) -> dict:
    try:
        return json.loads(_strip_json(text))
    except (json.JSONDecodeError, ValueError):
        return fallback


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


# ── A. POST /gemma/explain ────────────────────────────────────────────────────

@app.route('/gemma/explain', methods=['POST'])
def explain():
    data             = request.get_json()
    zone             = data.get('zone', '')
    time_str         = data.get('time', '')
    police_eta       = int(data.get('police_eta', 8))
    reporting_delay  = int(data.get('reporting_delay', 3))

    prompt = (
        f"{SAFETY_RULE} "
        f"You are the Rakshak 2.0 Spatio-Temporal Safety Analyzer. "
        f"A high police ETA combined with a late-night window drastically lowers the zone safety index. "
        f"Reporting delays above 5 minutes compound risk further. "
        f"Zone: {zone}. Current time: {time_str}. "
        f"Police ETA: {police_eta} minutes. Incident reporting delay: {reporting_delay} minutes. "
        f"Output ONLY a valid JSON object — no markdown, no explanation — matching exactly:\n"
        f'{{"safety_score": <int 1-10>, "risk_level": "<LOW|MEDIUM|HIGH>", '
        f'"bilingual_analysis": "<one concise English warning.\\n\\n<Tamil equivalent>"}}'
    )

    raw = _generate(prompt)
    result = _parse_json(raw, {
        'safety_score': 5,
        'risk_level': 'MEDIUM',
        'bilingual_analysis': (
            'Safety analysis unavailable — treat as elevated risk.\n\n'
            'பாதுகாப்பு பகுப்பாய்வு கிடைக்கவில்லை — உயர் ஆபத்தாக கருதவும்.'
        ),
    })
    return jsonify(result)


# ── B. POST /gemma/checkin ────────────────────────────────────────────────────

@app.route('/gemma/checkin', methods=['POST'])
def checkin():
    data       = request.get_json()
    user_input = data.get('user_input', '')
    zone       = data.get('zone', '')
    latitude   = float(data.get('latitude', 13.0827))
    longitude  = float(data.get('longitude', 80.2707))

    # Manual suppression bypass — no incident logged, no Ollama call
    if user_input.strip().upper() == 'OVERRIDE_OUT_LATE':
        return jsonify({'status': 'SAFE', 'escalated': False, 'override': True})

    prompt = (
        f"{SAFETY_RULE} "
        f"You are the Rakshak check-in safety evaluator. "
        f"A woman in Chennai zone {zone} sent this message during a nighttime check-in: '{user_input}'. "
        f"Evaluate whether she is safe. Output ONLY a valid JSON object matching exactly:\n"
        f'{{"status": "<SAFE|DISTRESS|UNCERTAIN>", "confidence_score": <float 0.0-1.0>, "reasoning": "<one sentence>"}}'
    )

    raw      = _generate(prompt)
    fallback = {'status': 'UNCERTAIN', 'confidence_score': 0.50, 'reasoning': 'Parse failure — treating as uncertain.'}
    parsed   = _parse_json(raw, fallback)

    status           = str(parsed.get('status', 'UNCERTAIN'))
    confidence_score = float(parsed.get('confidence_score', 0.50))

    # Zero-false-negative intercept: any non-SAFE result or sub-0.92 confidence triggers escalation
    escalated = (status != 'SAFE') or (confidence_score < 0.92)

    incident_id = None
    if escalated:
        incident_id = f'INC-{uuid.uuid4().hex[:8].upper()}'
        incident = {
            'incident_id':      incident_id,
            'timestamp':        datetime.now(timezone.utc).isoformat(),
            'zone':             zone,
            'latitude':         latitude,
            'longitude':        longitude,
            'user_input':       user_input,
            'gemma_status':     status,
            'confidence_score': confidence_score,
            'reasoning':        parsed.get('reasoning', ''),
            'dispatch_status':  'PENDING',
        }
        ACTIVE_INCIDENTS.append(incident)
        print(
            f"[{incident['timestamp']}] INCIDENT LOGGED {incident_id} "
            f"zone={zone} status={status} confidence={confidence_score:.2f}",
            file=sys.stderr, flush=True,
        )

    return jsonify({
        'status':           status,
        'confidence_score': confidence_score,
        'escalated':        escalated,
        'incident_id':      incident_id,
        'reasoning':        parsed.get('reasoning', ''),
    })


# ── C. GET /api/incidents ─────────────────────────────────────────────────────

@app.route('/api/incidents', methods=['GET'])
def get_incidents():
    return jsonify(ACTIVE_INCIDENTS)


# ── D. POST /gemma/dispatch ───────────────────────────────────────────────────

@app.route('/gemma/dispatch', methods=['POST'])
def dispatch():
    data        = request.get_json()
    incident_id = data.get('incident_id', '')
    zone        = data.get('zone', '')

    incident = next((i for i in ACTIVE_INCIDENTS if i['incident_id'] == incident_id), None)
    if incident is None:
        return jsonify({'error': f'Incident {incident_id} not found'}), 404

    inc_lat = incident['latitude']
    inc_lng = incident['longitude']

    units_ranked = sorted(
        [{**u, 'distance_km': _haversine_km(inc_lat, inc_lng, u['lat'], u['lng'])} for u in PATROL_UNITS],
        key=lambda u: u['distance_km'],
    )
    closest = units_ranked[0]

    patrol_summary = '\n'.join(
        f"  {u['unit_id']} — {u['name']} @ ({u['lat']}, {u['lng']}) "
        f"[{u['distance_km']:.2f} km] — {u['status']}"
        for u in units_ranked
    )

    prompt = (
        f"{SAFETY_RULE} "
        f"You are the Rakshak 2.0 Tactical Dispatch Commander for Chennai. "
        f"An incident was logged at coordinates ({inc_lat}, {inc_lng}), zone {zone}. "
        f"Available patrol units:\n{patrol_summary}\n"
        f"The closest unit is {closest['name']} ({closest['unit_id']}) at ({closest['lat']}, {closest['lng']}), "
        f"{closest['distance_km']:.2f} km away. "
        f"Issue a single tactical directive in EXACTLY this format — no extra text, no bullets, no markdown:\n"
        f"TACTICAL DIRECTION: Reroute [Unit Name] from [Current Coordinates] to target vector "
        f"in Pincode [Zone] via closest primary Chennai corridor immediately to minimize structural transit lag."
    )

    directive = _generate(prompt).strip()

    for u in PATROL_UNITS:
        if u['unit_id'] == closest['unit_id']:
            u['status'] = 'DISPATCHED'
    incident['dispatch_status'] = 'DISPATCHED'
    incident['dispatched_unit'] = closest['unit_id']

    return jsonify({
        'directive':   directive,
        'unit_id':     closest['unit_id'],
        'unit_name':   closest['name'],
        'distance_km': round(closest['distance_km'], 2),
        'incident_id': incident_id,
    })


# ── Legacy: POST /gemma/escalate (Flutter sentinel_repository.dart) ───────────

@app.route('/gemma/escalate', methods=['POST'])
def escalate():
    data   = request.get_json()
    user   = data.get('user', 'Unknown')
    zone   = data.get('zone', 'Chennai')
    reason = data.get('reason', 'no_response')

    prompt = (
        f"{SAFETY_RULE} "
        f"You are Rakshak AI generating a police alert. "
        f"User {user} in {zone}, Chennai did not respond to a safety check-in. "
        f"Reason code: {reason}. "
        f"Write a brief 1-2 sentence police dispatch alert confirming that 2 nearby patrol units are being notified. "
        f"Be direct and professional. Output only the alert message."
    )

    alert_message = _generate(prompt)
    ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f'[{ts}] ESCALATION ALERT — user={user}, zone={zone}, reason={reason}', file=sys.stderr, flush=True)

    return jsonify({'alert_message': alert_message, 'units_notified': 2})


if __name__ == '__main__':
    app.run(port=5001, debug=False)
