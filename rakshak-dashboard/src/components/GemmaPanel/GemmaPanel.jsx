import React, { useState, useEffect, useRef } from 'react'
import s from './GemmaPanel.module.css'
import { fetchGemmaInsight, fetchGemmaDispatch, fetchIncidents } from '../../services/gemma'

function _ts() {
  return new Date().toLocaleTimeString('en-IN', {
    hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false,
  })
}

const RISK_COLOR = { HIGH: '#FF3B5C', MEDIUM: '#F59E0B', LOW: '#22C55E' }

export default function GemmaPanel({ selectedZone, patrolCount }) {
  const [insight, setInsight]               = useState(null)   // { safety_score, risk_level, bilingual_analysis }
  const [dispatch, setDispatch]             = useState(null)   // { directive, unit_name, distance_km }
  const [loadingExplain, setLoadingExplain] = useState(false)
  const [loadingDispatch, setLoadingDispatch] = useState(false)
  const [auditLog, setAuditLog]             = useState([])
  const auditEndRef = useRef(null)

  const appendAudit = (type, zone, text) =>
    setAuditLog(prev => [{ id: Date.now(), type, zone, ts: _ts(), text }, ...prev].slice(0, 20))

  useEffect(() => {
    if (!selectedZone) { setInsight(null); setDispatch(null); return }
    setInsight(null)
    setDispatch(null)
    setLoadingExplain(true)

    fetchGemmaInsight(selectedZone.code, selectedZone.riskScore)
      .then(data => {
        setInsight(data)
        appendAudit('explain', selectedZone.code, data.bilingual_analysis ?? '')
      })
      .catch(() => setInsight({ safety_score: null, risk_level: 'UNKNOWN', bilingual_analysis: 'Gemma service unavailable. Please try again.' }))
      .finally(() => setLoadingExplain(false))
  }, [selectedZone])

  const handleDispatch = async () => {
    if (!selectedZone) return
    setLoadingDispatch(true)
    setDispatch(null)
    try {
      // Find the most recent incident for this zone from the local mesh
      const incidents = await fetchIncidents()
      const match = incidents.filter(i => i.zone === selectedZone.code).at(-1)
      if (!match) {
        setDispatch({ directive: `No active incidents logged for zone ${selectedZone.code}. All clear.`, unit_name: null })
        return
      }
      const data = await fetchGemmaDispatch(match.incident_id, selectedZone.code)
      setDispatch(data)
      appendAudit('dispatch', selectedZone.code, data.directive ?? '')
    } catch {
      setDispatch({ directive: 'Gemma service unavailable. Please try again.', unit_name: null })
    } finally {
      setLoadingDispatch(false)
    }
  }

  const scoreColor = insight?.risk_level ? (RISK_COLOR[insight.risk_level] ?? '#94A3B8') : '#94A3B8'

  return (
    <div className={s.panel}>
      <div className={s.hdr}>
        <div className={s.bar} />
        <span className={s.title}>🤖 Gemma AI Analysis</span>
        <span className={s.badge}>gemma3:4b</span>
      </div>

      {!selectedZone && (
        <div className={s.empty}>Select a zone row to get AI analysis</div>
      )}

      {selectedZone && (
        <>
          <div className={s.zoneLine}>
            <span className={s.zoneCode}>{selectedZone.code}</span>
            {insight && (
              <span className={s.scoreBlock}>
                <span className={s.scoreNum} style={{ color: scoreColor }}>
                  {insight.safety_score ?? '—'}/10
                </span>
                <span className={s.riskTag} style={{ color: scoreColor }}>
                  {insight.risk_level}
                </span>
              </span>
            )}
            {!insight && (
              <span className={s.riskTag} style={{ color: RISK_COLOR[selectedZone.riskLevel] ?? '#94A3B8' }}>
                {selectedZone.riskLevel} · {selectedZone.riskScore}
              </span>
            )}
          </div>

          <div className={s.card}>
            {loadingExplain ? (
              <div className={s.thinking}><span className={s.spinner} />Gemma is thinking…</div>
            ) : (
              <p className={s.text}>{insight?.bilingual_analysis ?? ''}</p>
            )}
          </div>

          <button
            className={s.dispatchBtn}
            onClick={handleDispatch}
            disabled={loadingDispatch || loadingExplain}
          >
            {loadingDispatch ? 'Dispatching…' : 'Get Dispatch Recommendation'}
          </button>

          {(dispatch || loadingDispatch) && (
            <div className={s.card} style={{ marginTop: 6 }}>
              {loadingDispatch ? (
                <div className={s.thinking}><span className={s.spinner} />Gemma is thinking…</div>
              ) : (
                <>
                  {dispatch.unit_name && (
                    <div className={s.unitLine}>
                      <span className={s.unitBadge}>▶ {dispatch.unit_name}</span>
                      {dispatch.distance_km && (
                        <span className={s.unitDist}>{dispatch.distance_km} km</span>
                      )}
                    </div>
                  )}
                  <p className={s.text}>{dispatch.directive}</p>
                </>
              )}
            </div>
          )}
        </>
      )}

      {auditLog.length > 0 && (
        <div className={s.auditSection}>
          <div className={s.auditHdr}>
            <div className={s.auditBar} />
            <span className={s.auditLabel}>Decision Audit Log</span>
            <span className={s.auditCount}>{auditLog.length}</span>
          </div>
          <div className={s.auditScroll}>
            {auditLog.map(entry => (
              <div key={entry.id} className={s.auditEntry}>
                <div className={s.auditMeta}>
                  <span className={s.auditTs}>{entry.ts}</span>
                  <span className={`${s.auditType} ${entry.type === 'explain' ? s.auditTypeExplain : s.auditTypeDispatch}`}>
                    {entry.type === 'explain' ? 'EXPLAIN' : 'DISPATCH'}
                  </span>
                  <span className={s.auditZone}>{entry.zone}</span>
                </div>
                <p className={s.auditText}>{entry.text}</p>
              </div>
            ))}
            <div ref={auditEndRef} />
          </div>
        </div>
      )}
    </div>
  )
}
