import { ENDPOINTS } from '../config/api'

export async function fetchGemmaInsight(zone, riskScore) {
  const resp = await fetch(ENDPOINTS.gemmaExplain, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ zone, risk_score: riskScore }),
  })
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
  const data = await resp.json()
  return data.explanation ?? ''
}

export async function fetchGemmaDispatch(zone, riskScore, time, nearbyUnits) {
  const resp = await fetch(ENDPOINTS.gemmaDispatch, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ zone, risk_score: riskScore, time, nearby_units: nearbyUnits }),
  })
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
  const data = await resp.json()
  return data.recommendation ?? ''
}
