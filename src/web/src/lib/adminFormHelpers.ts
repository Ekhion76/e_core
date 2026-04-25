/** Ugyanaz a logika, mint a szerver `generate_easy_levels` (professions.lua). */

export const FLASH_SUCCESS_MS = 4500

const LEVEL_KEYS = ['labor', 'time', 'price', 'chance', 'speed'] as const

function clampInt(n: number, lo: number, hi: number): number {
  const x = Math.floor(n)
  if (x < lo) return lo
  if (x > hi) return hi
  return x
}

function easingFactor(index: number, total: number, curveType: string): number {
  if (total <= 1) {
    return 1
  }
  const t = (index - 1) / (total - 1)
  if (curveType === 'aggressive') {
    return t * t
  }
  if (curveType === 'soft') {
    return Math.sqrt(t)
  }
  return t
}

export type EasyGeneratorForm = {
  milestones: number
  maxPoints: number
  curveType: 'linear' | 'soft' | 'aggressive'
  maxLabor: number
  maxTime: number
  maxPrice: number
  maxChance: number
  maxSpeed: number
}

export function defaultEasyGeneratorForm(): EasyGeneratorForm {
  return {
    milestones: 6,
    maxPoints: 1200,
    curveType: 'linear',
    maxLabor: 40,
    maxTime: 40,
    maxPrice: 35,
    maxChance: 45,
    maxSpeed: 35
  }
}

/** Szerverrel megegyező easy level sorok (mock + UI előnézet / beillesztés). */
export function generateEasyLevelsFromForm(form: EasyGeneratorForm): Record<string, number>[] {
  const milestones = Math.floor(Number(form.milestones))
  const maxPoints = Math.floor(Number(form.maxPoints))
  if (milestones < 2) {
    throw new Error('Milestones: legalább 2.')
  }
  if (maxPoints <= 0) {
    throw new Error('Max points: pozitív egész szám kell.')
  }
  const curveType = form.curveType
  if (curveType !== 'linear' && curveType !== 'soft' && curveType !== 'aggressive') {
    throw new Error('Görbe: linear, soft vagy aggressive.')
  }
  const max: Record<(typeof LEVEL_KEYS)[number], number> = {
    labor: clampInt(form.maxLabor, 0, 100),
    time: clampInt(form.maxTime, 0, 100),
    price: clampInt(form.maxPrice, 0, 100),
    chance: clampInt(form.maxChance, 0, 100),
    speed: clampInt(form.maxSpeed, 0, 100)
  }
  const levels: Record<string, number>[] = []
  for (let i = 1; i <= milestones; i++) {
    const f = easingFactor(i, milestones, curveType)
    const row: Record<string, number> = {
      limit: Math.floor((maxPoints * i) / milestones)
    }
    for (const key of LEVEL_KEYS) {
      row[key] = Math.floor(max[key] * f)
    }
    levels.push(row)
  }
  return levels
}

/** Szerver `easyGenerator` body: a `max` a felső szint plafon értékei (0–100). */
export function easyGeneratorApiPayload(form: EasyGeneratorForm): Record<string, unknown> {
  return {
    milestones: Math.floor(Number(form.milestones)),
    maxPoints: Math.floor(Number(form.maxPoints)),
    curveType: form.curveType,
    max: {
      labor: clampInt(form.maxLabor, 0, 100),
      time: clampInt(form.maxTime, 0, 100),
      price: clampInt(form.maxPrice, 0, 100),
      chance: clampInt(form.maxChance, 0, 100),
      speed: clampInt(form.maxSpeed, 0, 100)
    }
  }
}

export function parseLevelsJsonSafe(raw: string): { ok: true; value: unknown[] } | { ok: false; message: string } {
  const trimmed = raw.trim()
  if (trimmed === '') {
    return { ok: false, message: 'A levels mező nem lehet üres.' }
  }
  try {
    const parsed: unknown = JSON.parse(raw)
    if (!Array.isArray(parsed)) {
      return { ok: false, message: 'A levels értéke JSON tömb kell legyen (level sorok).' }
    }
    if (parsed.length === 0) {
      return { ok: false, message: 'Legalább egy level sor kell a tömbben.' }
    }
    return { ok: true, value: parsed }
  } catch (e) {
    if (e instanceof SyntaxError) {
      return { ok: false, message: 'Érvénytelen JSON szintaxis a levels mezőben.' }
    }
    return { ok: false, message: 'A levels JSON nem olvasható be.' }
  }
}

export function levelsFromEasyGeneratorUnknown(raw: unknown): Record<string, number>[] {
  if (typeof raw !== 'object' || raw === null) {
    throw new Error('easyGenerator: objektum szükséges.')
  }
  const o = raw as Record<string, unknown>
  const form: EasyGeneratorForm = {
    milestones: Number(o.milestones),
    maxPoints: Number(o.maxPoints),
    curveType:
      o.curveType === 'soft' || o.curveType === 'aggressive' ? o.curveType : 'linear',
    maxLabor: Number((o.max as Record<string, unknown>)?.labor ?? 0),
    maxTime: Number((o.max as Record<string, unknown>)?.time ?? 0),
    maxPrice: Number((o.max as Record<string, unknown>)?.price ?? 0),
    maxChance: Number((o.max as Record<string, unknown>)?.chance ?? 0),
    maxSpeed: Number((o.max as Record<string, unknown>)?.speed ?? 0)
  }
  return generateEasyLevelsFromForm(form)
}
