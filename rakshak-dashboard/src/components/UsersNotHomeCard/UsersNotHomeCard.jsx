import React, { useState, useEffect } from 'react'
import s from './UsersNotHomeCard.module.css'
import { ENDPOINTS } from '../../config/api'

/**
 * Renders only after 10 PM (hour >= 22) AND only if /police/citizens/active
 * returns real data. No fallback mock entries — hides entirely if API is empty.
 */
export default function UsersNotHomeCard() {
  const [hour,       setHour]       = useState(() => new Date().getHours())
  const [zoneData,   setZoneData]   = useState([])
  const [totalCount, setTotalCount] = useState(0)

  useEffect(() => {
    const id = setInterval(() => setHour(new Date().getHours()), 60_000)
    return () => clearInterval(id)
  }, [])

  useEffect(() => {
    if (hour < 22) return

    const fetchActive = async () => {
      try {
        const res = await fetch(`${ENDPOINTS.citizensActive}?after_hour=22`, {
          signal: AbortSignal.timeout(8000),
        })
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        const data = await res.json()

        const byPincode = data.by_pincode ?? []
        const total     = data.total_count ?? 0

        if (Array.isArray(byPincode) && byPincode.length > 0) {
          setZoneData(byPincode.map(z => ({
            zone:  z.area ?? z.pincode?.toString() ?? 'Zone',
            count: z.count ?? 0,
          })))
          setTotalCount(total)
        }
      } catch {
        // API unavailable — keep empty, don't show mock data
      }
    }

    fetchActive()
    const id = setInterval(fetchActive, 60_000)
    return () => clearInterval(id)
  }, [hour])

  // Hide before 10 PM or if no live data
  if (hour < 22 || zoneData.length === 0) return null

  const displayTotal = totalCount > 0
    ? totalCount
    : zoneData.reduce((sum, z) => sum + z.count, 0)

  return (
    <div className={s.card}>
      <div className={s.hdr}>
        <div className={s.bar} />
        <span className={s.title}>ACTIVE JOURNEYS UNRESOLVED</span>
        <span className={s.badge}>{displayTotal > 0 ? `${displayTotal} total` : 'POST 10PM'}</span>
      </div>

      <div className={s.list}>
        {zoneData.map(({ zone, count }) => (
          <div key={zone} className={s.row}>
            <span className={s.zoneName}>{zone}</span>
            <div className={s.right}>
              <span className={s.count}>{count}</span>
              {count > 10 && (
                <span className={s.warn} title="High density">⚠</span>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
