export type LevelRow = { limit?: number }

export function rankData(
  value: number,
  levels: LevelRow[]
): { level: number; progress: number } | false {
  const numberOfRanks = Array.isArray(levels) ? levels.length : 0
  if (numberOfRanks === 0 || value === undefined || value === null || Number.isNaN(Number(value))) {
    return false
  }
  const v = Number(value)
  const lim0 = Number(levels[0]?.limit)
  if (v < lim0) {
    return {
      level: 0,
      progress: v > 0 ? Math.floor((v / lim0) * 100) : 0
    }
  }
  for (let i = 1; i < numberOfRanks; i += 1) {
    const cur = Number(levels[i]?.limit)
    const prev = Number(levels[i - 1]?.limit)
    if (cur !== undefined && cur > v) {
      const range = cur - prev
      return {
        level: i,
        progress: Math.floor(((v - prev) / range) * 100)
      }
    }
  }
  return {
    level: numberOfRanks - 1,
    progress: 100
  }
}
