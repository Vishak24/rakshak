import React, { useState, useCallback } from 'react'
import Sidebar           from './components/Sidebar/Sidebar'
import RiskHeatmap       from './components/RiskHeatmap/RiskHeatmap'
import AlertsPanel       from './components/AlertsPanel/AlertsPanel'
import Reports           from './components/Reports/Reports'
import UsersNotHomeCard  from './components/UsersNotHomeCard/UsersNotHomeCard'
import PatrolDetailPanel from './components/PatrolDetailPanel/PatrolDetailPanel'
import PatrolStats       from './components/PatrolStats/PatrolStats'
import GemmaPanel        from './components/GemmaPanel/GemmaPanel'
import { useRiskData }    from './hooks/useRiskData'
import { useSosEvents }   from './hooks/useSosEvents'
import { useLivePatrols } from './hooks/useLivePatrols'
import styles from './App.module.css'

export default function App() {
  const [lang, setLang]             = useState('en')
  const [activeView, setActiveView] = useState('dashboard')
  const [selectedPatrolId, setSelectedPatrolId] = useState(null)
  const [selectedZone, setSelectedZone]         = useState(null)

  const { data: apiData, loading, error, refetch } = useRiskData()
  const { events, total }                          = useSosEvents()
  const { patrolStates }                           = useLivePatrols()

  const selectedPatrol = selectedPatrolId
    ? patrolStates.find(p => p.id === selectedPatrolId) ?? null
    : null

  const handlePatrolClick = useCallback((patrol) => {
    setSelectedPatrolId(patrol.id)
  }, [])

  return (
    <div className={activeView === 'reports' ? styles.appReports : styles.app}>
      <Sidebar
        lang={lang}
        onLangToggle={() => setLang(l => l === 'en' ? 'ta' : 'en')}
        onRefetch={refetch}
        isRefetching={loading}
        activeView={activeView}
        onViewChange={setActiveView}
      />

      <main className={styles.main}>
        {error && (
          <div className={styles.errorBanner}>
            ⚠ API error: {error}
          </div>
        )}

        {activeView === 'dashboard' && (
          <>
            <RiskHeatmap
              apiData={apiData}
              lang={lang}
              onPatrolClick={handlePatrolClick}
            />

            <div className={styles.chartsRow}>
              {/* Zone overview — live risk data */}
              <div className={styles.chartCard}>
                <div className={styles.chartHdr}>
                  <div className={styles.chartBar} style={{ background: 'var(--accent)' }} />
                  <span className={styles.chartTtl}>ZONE OVERVIEW</span>
                </div>
                <div className={styles.overviewBody}>
                  {loading && (
                    <span style={{ color: 'var(--muted)', fontSize: 12 }}>Loading…</span>
                  )}
                  {!loading && apiData && (
                    <table className={styles.ovTable}>
                      <thead>
                        <tr><th>Zone</th><th>Risk</th><th>Index</th><th>Conf.</th></tr>
                      </thead>
                      <tbody>
                        {Array.from(apiData.entries()).slice(0, 8).map(([code, d]) => {
                          const col = d.riskLevel === 'HIGH'   ? '#FF3B5C'
                                    : d.riskLevel === 'MEDIUM' ? '#F59E0B' : '#22C55E'
                          const isSelected = selectedZone?.code === code
                          return (
                            <tr
                              key={code}
                              style={{
                                cursor: 'pointer',
                                background: isSelected ? 'rgba(168,85,247,0.08)' : undefined,
                              }}
                              onClick={() => setSelectedZone({
                                code,
                                riskLevel: d.riskLevel,
                                riskScore: Math.round((d.riskIndex ?? 0) * 100),
                              })}
                            >
                              <td>{code}</td>
                              <td style={{ color: col, fontWeight: 700 }}>{d.riskLevel}</td>
                              <td>{d.riskIndex  != null ? Math.round(d.riskIndex  * 100) : '—'}</td>
                              <td>{d.confidence != null ? Math.round(d.confidence * 100) + '%' : '—'}</td>
                            </tr>
                          )
                        })}
                      </tbody>
                    </table>
                  )}
                </div>
              </div>

              {/* Live patrol list from /patrols */}
              <PatrolStats />

              {/* Active journeys — only shown after 10 PM with live data */}
              <UsersNotHomeCard />
            </div>
          </>
        )}

        {activeView === 'reports' && (
          <Reports resolvedIncidents={[]} />
        )}
      </main>

      {activeView === 'dashboard' && (
        <div className={styles.rightCol}>
          <GemmaPanel
            selectedZone={selectedZone}
            patrolCount={patrolStates.length}
          />
          <AlertsPanel
            events={events}
            total={total}
            lang={lang}
          />
        </div>
      )}

      <PatrolDetailPanel
        patrol={selectedPatrol}
        onClose={() => setSelectedPatrolId(null)}
        dispatchPatrol={() => {}}
      />
    </div>
  )
}
