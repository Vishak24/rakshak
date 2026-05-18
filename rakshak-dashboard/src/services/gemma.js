import { ENDPOINTS } from '../config/api'

/**
 * POST /gemma/explain
 * Returns { safety_score, risk_level, bilingual_analysis }
 * police_eta and reporting_delay use operational defaults when not supplied.
 */
export async function fetchGemmaInsight(zone, _riskScore, policeEta = 8, reportingDelay = 3) {
  const time = new Date().toLocaleTimeString('en-IN', {
    hour: '2-digit', minute: '2-digit', hour12: false,
  })
  const resp = await fetch(ENDPOINTS.gemmaExplain, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ zone, time, police_eta: policeEta, reporting_delay: reportingDelay }),
  })
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
  return resp.json()   // { safety_score, risk_level, bilingual_analysis }
}

/**
 * GET /api/incidents
 * Returns the in-memory incident array from the local safety mesh.
 */
export async function fetchIncidents() {
  const resp = await fetch(ENDPOINTS.incidentsList)
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
  return resp.json()
}

/**
 * POST /gemma/dispatch
 * Requires an incident_id from ACTIVE_INCIDENTS.
 * Returns { directive, unit_id, unit_name, distance_km, incident_id }
 */
export async function fetchGemmaDispatch(incidentId, zone) {
  const resp = await fetch(ENDPOINTS.gemmaDispatch, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ incident_id: incidentId, zone }),
  })
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
  return resp.json()   // { directive, unit_id, unit_name, distance_km }
}
