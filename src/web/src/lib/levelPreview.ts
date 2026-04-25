export const LEVEL_MODIFIER_KEYS = ['labor', 'time', 'price', 'chance', 'speed'] as const

export type LevelEntry = { key: string; value: unknown }

export function toLevelEntries(levels: unknown): LevelEntry[] {
  if (levels === undefined || levels === null) {
    return []
  }
  if (Array.isArray(levels)) {
    return levels.map((row, index) => ({ key: String(index + 1), value: row }))
  }
  if (typeof levels === 'object') {
    return Object.entries(levels as Record<string, unknown>)
      .sort((a, b) => Number(a[0]) - Number(b[0]))
      .map(([key, value]) => ({ key, value }))
  }
  return []
}

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v)
}

/** Megegyezik a szerver `normalize_levels_table` sor-alakjával: `limit` + módosítók. */
export function isStandardLevelRow(value: unknown): boolean {
  if (!isPlainObject(value)) {
    return false
  }
  const lim = value.limit
  if (lim === undefined || lim === null) {
    return false
  }
  if (typeof lim === 'number') {
    return Number.isFinite(lim)
  }
  if (typeof lim === 'string') {
    return lim.trim() !== '' && !Number.isNaN(Number(lim))
  }
  return false
}

export function shouldRenderLevelTable(entries: LevelEntry[]): boolean {
  if (entries.length === 0) {
    return false
  }
  return entries.every((e) => isStandardLevelRow(e.value))
}

export function formatLevelCell(row: Record<string, unknown>, col: string): string {
  const v = row[col]
  if (v === undefined || v === null) {
    return '—'
  }
  if (typeof v === 'number' && Number.isFinite(v)) {
    return String(Math.trunc(v))
  }
  if (typeof v === 'string' && v.trim() !== '' && !Number.isNaN(Number(v))) {
    return String(Math.trunc(Number(v)))
  }
  if (typeof v === 'string') {
    return v
  }
  return JSON.stringify(v)
}
