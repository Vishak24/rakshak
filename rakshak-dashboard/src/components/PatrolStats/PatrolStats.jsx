import React from 'react'
import s from './PatrolStats.module.css'
import { useLivePatrols } from '../../hooks/useLivePatrols'
import { PATROL_ROUTES } from '../../data/patrolRoutes'

const STATUS_COLOR = {
  Patrolling: '#00e5ff',
  Responding: '#ef4444',
  AtScene:    '#22c55e',
}

const STATUS_LABEL = {
  Patrolling: 'Patrolling',
  Responding: '🚔 En Route',
  AtScene:    'At Scene',
}

/**
 * PatrolStats — shows all patrol units.
 * Uses live /patrols API data when available; falls back to PATROL_ROUTES (12 units).
 * Officer count always reflects PATROL_ROUTES.length (12).
 */
export default function PatrolStats() {
  const { patrolStates } = useLivePatrols()

  // Use live data if available, otherwise show all 12 from PATROL_ROUTES
  const units = patrolStates.length > 0
    ? patrolStates
    : PATROL_ROUTES.map(r => ({
        id:      r.id,
        name:    r.name,
        vehicle: r.id,
        zone:    r.zone,
        status:  'Patrolling',
      }))

  const total = PATROL_ROUTES.length  // always 12

  return (
    <div className={s.card}>
      <div className={s.hdr}>
        <div className={s.bar} />
        <span className={s.title}>OFFICERS ON DUTY</span>
        <span className={s.totalBadge}>{total} units</span>
      </div>

      <div className={s.unitList}>
        {units.map(p => {
          const col   = STATUS_COLOR[p.status] ?? '#00e5ff'
          const label = STATUS_LABEL[p.status] ?? p.status
          return (
            <div key={p.id} className={s.unitRow}>
              <div className={s.unitDot} style={{ background: col }} />
              <span className={s.unitVehicle}>{p.id}</span>
              <span className={s.unitName}>{p.name ?? p.zone}</span>
              <span className={s.unitStatus} style={{ color: col }}>
                {label}
              </span>
            </div>
          )
        })}
      </div>
    </div>
  )
}
