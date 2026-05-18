import React, { useState, useEffect, useRef } from 'react'
import s from './GemmaPanel.module.css'
import { fetchGemmaInsight, fetchGemmaDispatch } from '../../services/gemma'

function _ts() {
  return new Date().toLocaleTimeString('en-IN', {
    hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false,
  })
}

export default function GemmaPanel({ selectedZone, patrolCount }) {
  const [explanation, setExplanation]         = useState('')
  const [recommendation, setRecommendation]   = useState('')
  const [loadingExplain, setLoadingExplain]   = useState(false)
  const [loadingDispatch, setLoadingDispatch] = useState(false)
  const [auditLog, setAuditLog]               = useState([])
  const auditEndRef = useRef(null)

  const appendAudit = (type, zone, text) => {
    setAuditLog(prev => [
      { id: Date.now(), type, zone, ts: _ts(), text },
      ...prev,
    ].slice(0, 20))
  }

  useEffect(() => {
    if (!selectedZone) {
      setExplanation('')
      setRecommendation('')
      return
    }
    setExplanation('')
    setRecommendation('')
    setLoadingExplain(true)

    fetchGemmaInsight(selectedZone.code, selectedZone.riskScore)
      .then(text => {
        setExplanation(text)
        appendAudit('explain', selectedZone.code, text)
      })
      .catch(() => setExplanation('Gemma service unavailable. Please try again.'))
      .finally(() => setLoadingExplain(false))
  }, [selectedZone])

  const handleDispatch = () => {
    if (!selectedZone) return
    setLoadingDispatch(true)
    setRecommendation('')

    const time = new Date().toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true })
    fetchGemmaDispatch(selectedZone.code, selectedZone.riskScore, time, patrolCount)
      .then(text => {
        setRecommendation(text)
        appendAudit('dispatch', selectedZone.code, text)
      })
      .catch(() => setRecommendation('Gemma service unavailable. Please try again.'))
      .finally(() => setLoadingDispatch(false))
  }

  const riskColor = (level) =>
    level === 'HIGH' ? '#FF3B5C' : level === 'MEDIUM' ? '#F59E0B' : '#22C55E'

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
            <span className={s.riskTag} style={{ color: riskColor(selectedZone.riskLevel) }}>
              {selectedZone.riskLevel} · {selectedZone.riskScore}
            </span>
          </div>

          <div className={s.card}>
            {loadingExplain ? (
              <div className={s.thinking}>
                <span className={s.spinner} />
                Gemma is thinking…
              </div>
            ) : (
              <p className={s.text}>{explanation}</p>
            )}
          </div>

          <button
            className={s.dispatchBtn}
            onClick={handleDispatch}
            disabled={loadingDispatch || loadingExplain}
          >
            {loadingDispatch ? 'Generating…' : 'Get Dispatch Recommendation'}
          </button>

          {(recommendation || loadingDispatch) && (
            <div className={s.card} style={{ marginTop: 6 }}>
              {loadingDispatch ? (
                <div className={s.thinking}>
                  <span className={s.spinner} />
                  Gemma is thinking…
                </div>
              ) : (
                <p className={s.text}>{recommendation}</p>
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
