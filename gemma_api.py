import requests
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

OLLAMA_URL = "http://localhost:11434/api/generate"


@app.route("/gemma/explain", methods=["POST"])
def explain():
    data = request.get_json()
    zone = data.get("zone", "")
    risk_score = data.get("risk_score", 0)

    prompt = (
        f"You are a women's safety risk analyst for Chennai. "
        f"Zone pincode: {zone}. Risk score: {risk_score}/100. "
        f"In 2-3 sentences, explain why this zone has this risk level "
        f"and what factors contribute to it. "
        f"Consider that false negatives — predicting safe when dangerous — are unacceptable "
        f"in this safety-critical system. Err toward caution in your assessment."
    )

    resp = requests.post(OLLAMA_URL, json={
        "model": "gemma3:4b",
        "prompt": prompt,
        "stream": False,
    }, timeout=60)
    resp.raise_for_status()

    return jsonify({"explanation": resp.json().get("response", "")})


@app.route("/gemma/dispatch", methods=["POST"])
def dispatch():
    data = request.get_json()
    zone = data.get("zone", "")
    risk_score = data.get("risk_score", 0)
    time = data.get("time", "")
    nearby_units = data.get("nearby_units", 0)

    prompt = (
        f"You are a Chennai police dispatch commander. "
        f"Zone pincode: {zone}, risk score: {risk_score}/100, "
        f"current time: {time}, available patrol units: {nearby_units}. "
        f"Give a specific 2-3 sentence patrol deployment recommendation — "
        f"where to position units, patrol frequency, and priority level."
    )

    resp = requests.post(OLLAMA_URL, json={
        "model": "gemma3:4b",
        "prompt": prompt,
        "stream": False,
    }, timeout=60)
    resp.raise_for_status()

    return jsonify({"recommendation": resp.json().get("response", "")})


@app.route("/gemma/checkin", methods=["POST"])
def checkin():
    data = request.get_json()
    user_name = data.get("user_name", "User")
    zone = data.get("zone", "Chennai")
    time = data.get("time", "")

    prompt = (
        f"You are Rakshak AI, a women's safety companion in Chennai. "
        f"Generate a warm, bilingual safety check-in message for {user_name} "
        f"who is currently in {zone} at {time}. "
        f"Format your response exactly as: "
        f"'Hi {user_name}, [one sentence in English noting it's late and they're away from home]. "
        f"Are you safe? / வணக்கம் {user_name}, [Tamil translation of the English sentence]. "
        f"நீங்கள் பாதுகாப்பாக இருக்கிறீர்களா?' "
        f"Be warm and caring, not alarming. Output only the message, nothing else."
    )

    resp = requests.post(OLLAMA_URL, json={
        "model": "gemma3:4b",
        "prompt": prompt,
        "stream": False,
    }, timeout=60)
    resp.raise_for_status()

    return jsonify({"message": resp.json().get("response", "")})


@app.route("/gemma/escalate", methods=["POST"])
def escalate():
    import datetime

    data = request.get_json()
    user = data.get("user", "Unknown")
    zone = data.get("zone", "Chennai")
    reason = data.get("reason", "no_response")

    prompt = (
        f"You are Rakshak AI generating a police alert. "
        f"User {user} in {zone}, Chennai did not respond to a safety check-in. "
        f"Reason code: {reason}. "
        f"Write a brief 1-2 sentence police dispatch alert message describing "
        f"the situation and confirming that 2 nearby patrol units are being notified. "
        f"Be direct and professional. Output only the alert message."
    )

    resp = requests.post(OLLAMA_URL, json={
        "model": "gemma3:4b",
        "prompt": prompt,
        "stream": False,
    }, timeout=60)
    resp.raise_for_status()

    alert_message = resp.json().get("response", "")

    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] ESCALATION ALERT — user={user}, zone={zone}, reason={reason}")
    print(f"[{timestamp}] Alert: {alert_message}")

    return jsonify({
        "alert_message": alert_message,
        "units_notified": 2,
    })


if __name__ == "__main__":
    app.run(port=5001, debug=False)
