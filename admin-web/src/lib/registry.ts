import { levelsFromEasyGeneratorUnknown } from './adminFormHelpers'

type AdminApiResponse<T> = {
  ok: boolean
  code: string
  message?: string
  data?: T
}

type UnknownRecord = Record<string, any>

export type ProfessionItem = {
  category: string
  name: string
  displayName: string
  profileKey: string
  enabled: boolean
  maxProficiency: number | null
}

export type LevelProfileItem = {
  profileKey: string
  displayName: string
  mode: 'easy' | 'advanced'
  levels: number
  levelsData: Record<string, unknown> | unknown[]
  linkedProfessions: number
  updatedAt: string
}

export type ProfessionDefaultsResult = {
  category: string
  defaults: Record<string, number>
}

export type ProfessionValidateResult = {
  valid: string[]
  invalid: string[]
  missingProfile: string[]
}

export type ProfessionProfileResult = {
  category: string
  name: string
  profile: {
    profileKey: string
    displayName: string
    mode: 'easy' | 'advanced'
    levels: Record<string, unknown> | unknown[]
  }
}

export type ProfessionCreateInput = {
  category: string
  name: string
  displayName?: string
  enabled?: boolean
  profileKey: string
  maxProficiency?: number | null
}

export type ProfessionUpdateInput = {
  displayName?: string
  enabled?: boolean
  profileKey?: string
  /** Szerver: `false` törli a felső korlátot, szám = új plafon. */
  maxProficiency?: number | null | false
}

export type LevelProfileCreateInput = {
  profileKey: string
  displayName?: string
  mode?: 'easy' | 'advanced'
  levels?: unknown[] | Record<string, unknown>
  easyGenerator?: unknown
}

export type LevelProfileUpdateInput = {
  displayName?: string
  mode?: 'easy' | 'advanced'
  levels?: unknown[] | Record<string, unknown>
  easyGenerator?: unknown
}

const useMock = import.meta.env.VITE_USE_MOCK_REGISTRY !== 'false'

const MOCK_PROFESSIONS_TEMPLATE: ProfessionItem[] = [
  {
    category: 'crafting',
    name: 'weaponry',
    displayName: 'Weaponry',
    profileKey: 'default_crafting',
    enabled: true,
    maxProficiency: 1000
  },
  {
    category: 'crafting',
    name: 'armorsmith',
    displayName: 'Armorsmith',
    profileKey: 'default_crafting',
    enabled: true,
    maxProficiency: 950
  },
  {
    category: 'harvesting',
    name: 'gathering',
    displayName: 'Gathering',
    profileKey: 'default_harvesting',
    enabled: true,
    maxProficiency: null
  },
  {
    category: 'special',
    name: 'chemistry',
    displayName: 'Chemistry',
    profileKey: 'advanced_special',
    enabled: false,
    maxProficiency: 600
  }
]

/** Ugyanaz a séma, mint a szerver `normalize_levels_table`: limit + módosítók 0–100. */
function mockLevelRows(
  count: number,
  seed: number
): Array<Record<string, number>> {
  const rows: Array<Record<string, number>> = []
  for (let i = 0; i < count; i++) {
    const t = i / Math.max(1, count - 1)
    const f = (base: number, spread: number) =>
      Math.min(100, Math.max(0, Math.floor(base + spread * t + (seed * 7 + i * 3) % 5)))
    rows.push({
      limit: 100 * (i + 1),
      labor: f(8, 55),
      time: f(10, 50),
      price: f(5, 40),
      chance: f(6, 60),
      speed: f(7, 45)
    })
  }
  return rows
}

const MOCK_LEVEL_PROFILES_TEMPLATE: LevelProfileItem[] = [
  {
    profileKey: 'default_crafting',
    displayName: 'Default Crafting',
    mode: 'easy',
    levels: 10,
    levelsData: mockLevelRows(10, 1),
    linkedProfessions: 2,
    updatedAt: '2026-04-24 17:20'
  },
  {
    profileKey: 'default_harvesting',
    displayName: 'Default Harvesting',
    mode: 'easy',
    levels: 8,
    levelsData: mockLevelRows(8, 2),
    linkedProfessions: 1,
    updatedAt: '2026-04-24 17:18'
  },
  {
    profileKey: 'advanced_special',
    displayName: 'Advanced Special',
    mode: 'advanced',
    levels: 12,
    levelsData: mockLevelRows(12, 3),
    linkedProfessions: 1,
    updatedAt: '2026-04-24 17:15'
  }
]

let mockProfessionsStore: ProfessionItem[] = structuredClone(MOCK_PROFESSIONS_TEMPLATE)
let mockLevelProfilesStore: LevelProfileItem[] = structuredClone(MOCK_LEVEL_PROFILES_TEMPLATE)

function syncMockProfileLinks() {
  for (const p of mockLevelProfilesStore) {
    p.linkedProfessions = mockProfessionsStore.filter((x) => x.profileKey === p.profileKey).length
    const ld = p.levelsData
    p.levels = Array.isArray(ld) ? ld.length : typeof ld === 'object' && ld !== null ? Object.keys(ld).length : 0
  }
}

syncMockProfileLinks()

function getApiBaseUrl(): string {
  return (import.meta.env.VITE_ADMIN_API_BASE_URL as string | undefined)?.trim() ?? ''
}

function getAuthHeaders(): Record<string, string> {
  const identifierHeader =
    (import.meta.env.VITE_ADMIN_IDENTIFIER_HEADER as string | undefined)?.trim() || 'x-ecore-identifier'
  const tokenHeader = (import.meta.env.VITE_ADMIN_TOKEN_HEADER as string | undefined)?.trim() || 'x-ecore-token'

  const identifier = (import.meta.env.VITE_ADMIN_IDENTIFIER as string | undefined)?.trim() ?? ''
  const token = (import.meta.env.VITE_ADMIN_TOKEN as string | undefined)?.trim() ?? ''

  const headers: Record<string, string> = {}
  if (identifier) {
    headers[identifierHeader] = identifier
  }
  if (token) {
    headers[tokenHeader] = token
  }
  return headers
}

function normalizeBase(baseUrl: string): string {
  return baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl
}

function joinUrl(baseUrl: string, path: string): string {
  const normalizedPath = path.startsWith('/') ? path : `/${path}`
  return `${normalizeBase(baseUrl)}${normalizedPath}`
}

function encodeQuery(params: Record<string, string>): string {
  const pairs: string[] = []
  for (const [key, value] of Object.entries(params)) {
    if (!key) continue
    pairs.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
  }
  return pairs.join('&')
}

async function getJson(url: string): Promise<any> {
  const response = await fetch(url, {
    headers: getAuthHeaders()
  })
  const text = await response.text()
  let data: any
  try {
    data = text ? JSON.parse(text) : {}
  } catch {
    throw new Error(`${url} -> HTTP ${response.status}, nem JSON valasz`)
  }
  if (response.status === 401) {
    throw new Error((data as AdminApiResponse<UnknownRecord>)?.message ?? 'HTTP 401')
  }
  if (!response.ok) {
    throw new Error(
      (data as AdminApiResponse<UnknownRecord>)?.message ?? `${url} -> HTTP ${response.status}`
    )
  }
  return data
}

async function adminRequest<T = UnknownRecord>(
  method: 'GET' | 'POST' | 'PUT' | 'DELETE',
  path: string,
  options?: { query?: Record<string, string>; body?: unknown }
): Promise<AdminApiResponse<T>> {
  const baseUrl = getApiBaseUrl()
  if (!baseUrl) {
    throw new Error('VITE_ADMIN_API_BASE_URL not configured')
  }
  let url = joinUrl(baseUrl, path)
  if (options?.query && Object.keys(options.query).length > 0) {
    const q = encodeQuery(options.query)
    url = url.includes('?') ? `${url}&${q}` : `${url}?${q}`
  }
  const headers: Record<string, string> = { ...getAuthHeaders() }
  const init: RequestInit = { method, headers }
  if (options?.body !== undefined && method !== 'GET' && method !== 'DELETE') {
    headers['Content-Type'] = 'application/json'
    init.body = JSON.stringify(options.body)
  }
  const response = await fetch(url, init)
  const text = await response.text()
  let data: AdminApiResponse<T>
  try {
    data = text ? JSON.parse(text) : { ok: false, code: 'empty', message: 'Ures valasz' }
  } catch {
    throw new Error(`Nem JSON valasz: ${path} (HTTP ${response.status})`)
  }
  if (response.status === 401) {
    throw new Error(data.message ?? 'HTTP 401 — auth sikertelen')
  }
  if (!response.ok) {
    throw new Error(data.message ?? `HTTP ${response.status}`)
  }
  return data
}

function unwrapItems(payload: any): any[] {
  if (Array.isArray(payload)) {
    return payload
  }

  const data = (payload as AdminApiResponse<UnknownRecord>)?.data
  if (Array.isArray(data?.items)) return data.items
  if (Array.isArray(data?.professions)) return data.professions
  if (Array.isArray(data?.profiles)) return data.profiles

  if (Array.isArray(payload?.items)) return payload.items
  if (Array.isArray(payload?.professions)) return payload.professions
  if (Array.isArray(payload?.profiles)) return payload.profiles

  return []
}

function normalizeProfession(input: any): ProfessionItem {
  const profileKey = String(input?.profileKey ?? input?.levelProfileKey ?? input?.profile?.profileKey ?? '')
  return {
    category: String(input?.category ?? ''),
    name: String(input?.name ?? ''),
    displayName: String(input?.displayName ?? input?.display_name ?? input?.name ?? ''),
    profileKey,
    enabled: input?.enabled === true,
    maxProficiency: input?.maxProficiency == null ? null : Number(input?.maxProficiency ?? 0)
  }
}

function normalizeLevelProfile(input: any): LevelProfileItem {
  const levelsRaw = input?.levels
  const levels = Array.isArray(levelsRaw)
    ? levelsRaw.length
    : typeof levelsRaw === 'object' && levelsRaw !== null
      ? Object.keys(levelsRaw).length
      : Number(input?.levelsCount ?? 0)

  return {
    profileKey: String(input?.profileKey ?? input?.profile_key ?? ''),
    displayName: String(input?.displayName ?? input?.display_name ?? input?.profileKey ?? 'Unknown profile'),
    mode: input?.mode === 'easy' ? 'easy' : 'advanced',
    levels,
    levelsData:
      (Array.isArray(levelsRaw) || (typeof levelsRaw === 'object' && levelsRaw !== null)
        ? levelsRaw
        : {}) as Record<string, unknown> | unknown[],
    linkedProfessions: Number(
      input?.professionCount ?? input?.usageCount ?? input?.linkedProfessions ?? 0
    ),
    updatedAt: String(input?.updatedAt ?? input?.updated_at ?? '-')
  }
}

export async function listProfessions(): Promise<ProfessionItem[]> {
  if (useMock) {
    return structuredClone(mockProfessionsStore)
  }

  const baseUrl = getApiBaseUrl()
  if (!baseUrl) {
    throw new Error('VITE_ADMIN_API_BASE_URL not configured')
  }

  const payload = await getJson(joinUrl(baseUrl, '/admin/professions'))
  const items = unwrapItems(payload)
  return items.map(normalizeProfession)
}

export async function listLevelProfiles(): Promise<LevelProfileItem[]> {
  if (useMock) {
    return structuredClone(mockLevelProfilesStore)
  }

  const baseUrl = getApiBaseUrl()
  if (!baseUrl) {
    throw new Error('VITE_ADMIN_API_BASE_URL not configured')
  }

  const payload = await getJson(joinUrl(baseUrl, '/admin/level-profiles'))
  const items = unwrapItems(payload)
  return items.map(normalizeLevelProfile)
}

export async function getProfessionDefaults(category: string): Promise<ProfessionDefaultsResult> {
  const normalizedCategory = String(category || '').trim()
  if (!normalizedCategory) {
    throw new Error('Category is required')
  }

  if (useMock) {
    const defaults: Record<string, number> = {}
    for (const row of mockProfessionsStore) {
      if (row.category === normalizedCategory && row.enabled) {
        defaults[row.name] = 0
      }
    }
    return { category: normalizedCategory, defaults }
  }

  const baseUrl = getApiBaseUrl()
  if (!baseUrl) {
    throw new Error('VITE_ADMIN_API_BASE_URL not configured')
  }

  const query = encodeQuery({ category: normalizedCategory })
  const payload = (await getJson(
    joinUrl(baseUrl, `/admin/professions/defaults?${query}`)
  )) as AdminApiResponse<{ category?: string; defaults?: Record<string, number> }>

  if (!payload.ok) {
    throw new Error(payload.message ?? payload.code ?? 'Defaults request failed')
  }

  return {
    category: String(payload.data?.category ?? normalizedCategory),
    defaults: (payload.data?.defaults ?? {}) as Record<string, number>
  }
}

export async function validateProfessionKeys(
  category: string,
  keys: string[]
): Promise<ProfessionValidateResult> {
  const normalizedCategory = String(category || '').trim()
  if (!normalizedCategory) {
    throw new Error('Category is required')
  }

  const normalizedKeys = keys.map((item) => String(item || '').trim()).filter(Boolean)

  if (useMock) {
    const validSet = new Set(
      mockProfessionsStore
        .filter((row) => row.category === normalizedCategory && row.enabled)
        .map((row) => row.name)
    )
    return {
      valid: normalizedKeys.filter((key) => validSet.has(key)),
      invalid: normalizedKeys.filter((key) => !validSet.has(key)),
      missingProfile: []
    }
  }

  const baseUrl = getApiBaseUrl()
  if (!baseUrl) {
    throw new Error('VITE_ADMIN_API_BASE_URL not configured')
  }

  const query = encodeQuery({
    category: normalizedCategory,
    keys: normalizedKeys.join(',')
  })
  const payload = (await getJson(
    joinUrl(baseUrl, `/admin/professions/validate?${query}`)
  )) as AdminApiResponse<ProfessionValidateResult>

  if (!payload.ok) {
    throw new Error(payload.message ?? payload.code ?? 'Validation request failed')
  }

  return {
    valid: Array.isArray(payload.data?.valid) ? payload.data!.valid : [],
    invalid: Array.isArray(payload.data?.invalid) ? payload.data!.invalid : [],
    missingProfile: Array.isArray(payload.data?.missingProfile) ? payload.data!.missingProfile : []
  }
}

export async function getProfessionProfile(category: string, name: string): Promise<ProfessionProfileResult> {
  const normalizedCategory = String(category || '').trim()
  const normalizedName = String(name || '').trim()
  if (!normalizedCategory || !normalizedName) {
    throw new Error('Category and name are required')
  }

  if (useMock) {
    const row = mockProfessionsStore.find(
      (item) => item.category === normalizedCategory && item.name === normalizedName
    )
    const profileKey = row?.profileKey ?? 'unknown_profile'
    const lp = mockLevelProfilesStore.find((p) => p.profileKey === profileKey)
    const levels = lp?.levelsData ?? []
    return {
      category: normalizedCategory,
      name: normalizedName,
      profile: {
        profileKey,
        displayName: lp?.displayName ?? row?.displayName ?? 'Unknown profile',
        mode: lp?.mode ?? 'easy',
        levels
      }
    }
  }

  const baseUrl = getApiBaseUrl()
  if (!baseUrl) {
    throw new Error('VITE_ADMIN_API_BASE_URL not configured')
  }

  const query = encodeQuery({
    category: normalizedCategory,
    name: normalizedName
  })
  const payload = (await getJson(
    joinUrl(baseUrl, `/admin/professions/profile?${query}`)
  )) as AdminApiResponse<{
    category?: string
    name?: string
    profile?: { profileKey?: string; displayName?: string; mode?: string; levels?: Record<string, unknown> | unknown[] }
  }>

  if (!payload.ok) {
    throw new Error(payload.message ?? payload.code ?? 'Profile request failed')
  }

  return {
    category: String(payload.data?.category ?? normalizedCategory),
    name: String(payload.data?.name ?? normalizedName),
    profile: {
      profileKey: String(payload.data?.profile?.profileKey ?? ''),
      displayName: String(payload.data?.profile?.displayName ?? payload.data?.profile?.profileKey ?? 'Unknown profile'),
      mode: payload.data?.profile?.mode === 'easy' ? 'easy' : 'advanced',
      levels: (payload.data?.profile?.levels ?? {}) as Record<string, unknown> | unknown[]
    }
  }
}

export async function createProfession(input: ProfessionCreateInput): Promise<ProfessionItem> {
  const category = String(input.category || '').trim()
  const name = String(input.name || '').trim()
  const profileKey = String(input.profileKey || '').trim()
  if (!category || !name || !profileKey) {
    throw new Error('A category, name és profileKey megadása kötelező.')
  }
  if (useMock) {
    if (mockProfessionsStore.some((r) => r.category === category && r.name === name)) {
      throw new Error('Ilyen profession már létezik (mock).')
    }
    if (!mockLevelProfilesStore.some((p) => p.profileKey === profileKey)) {
      throw new Error('Ismeretlen level profile key (mock).')
    }
    const displayName = String(input.displayName || '').trim() || name
    const row: ProfessionItem = {
      category,
      name,
      displayName,
      profileKey,
      enabled: input.enabled !== false,
      maxProficiency:
        input.maxProficiency === undefined || input.maxProficiency === null
          ? null
          : Number(input.maxProficiency)
    }
    mockProfessionsStore.push(row)
    syncMockProfileLinks()
    return { ...row }
  }
  const payload = await adminRequest<{ profession: unknown }>('POST', '/admin/professions', { body: input })
  if (!payload.ok) {
    throw new Error(payload.message ?? String(payload.code ?? 'profession létrehozás'))
  }
  const data = (payload.data ?? {}) as { profession?: unknown }
  if (!data.profession) {
    throw new Error('Üres válasz: data.profession')
  }
  return normalizeProfession(data.profession)
}

export async function updateProfession(
  category: string,
  name: string,
  input: ProfessionUpdateInput
): Promise<ProfessionItem> {
  const c = String(category || '').trim()
  const n = String(name || '').trim()
  if (!c || !n) {
    throw new Error('A category és name megadása kötelező.')
  }
  if (useMock) {
    const idx = mockProfessionsStore.findIndex((r) => r.category === c && r.name === n)
    if (idx < 0) {
      throw new Error('Nincs ilyen profession (mock).')
    }
    const cur = mockProfessionsStore[idx]
    const next: ProfessionItem = { ...cur }
    if (input.displayName !== undefined) {
      next.displayName = String(input.displayName).trim()
    }
    if (input.enabled !== undefined) {
      next.enabled = input.enabled === true
    }
    if (input.profileKey !== undefined) {
      const pk = String(input.profileKey).trim()
      if (!mockLevelProfilesStore.some((p) => p.profileKey === pk)) {
        throw new Error('Ismeretlen level profile (mock).')
      }
      next.profileKey = pk
    }
    if (input.maxProficiency !== undefined) {
      if (input.maxProficiency === false) {
        next.maxProficiency = null
      } else {
        next.maxProficiency = input.maxProficiency === null ? null : Number(input.maxProficiency)
      }
    }
    mockProfessionsStore[idx] = next
    syncMockProfileLinks()
    return { ...next }
  }
  const payload = await adminRequest<{ profession: unknown }>('PUT', '/admin/professions', {
    query: { category: c, name: n },
    body: input
  })
  if (!payload.ok) {
    throw new Error(payload.message ?? String(payload.code ?? 'profession frissítés'))
  }
  const data = (payload.data ?? {}) as { profession?: unknown }
  if (!data.profession) {
    throw new Error('Üres válasz: data.profession')
  }
  return normalizeProfession(data.profession)
}

export async function deleteProfession(category: string, name: string): Promise<void> {
  const c = String(category || '').trim()
  const n = String(name || '').trim()
  if (!c || !n) {
    throw new Error('A category és name megadása kötelező.')
  }
  if (useMock) {
    const before = mockProfessionsStore.length
    mockProfessionsStore = mockProfessionsStore.filter((r) => !(r.category === c && r.name === n))
    if (mockProfessionsStore.length === before) {
      throw new Error('Nincs ilyen profession (mock).')
    }
    syncMockProfileLinks()
    return
  }
  const payload = await adminRequest('DELETE', '/admin/professions', { query: { category: c, name: n } })
  if (!payload.ok) {
    throw new Error(payload.message ?? String(payload.code ?? 'profession törlés'))
  }
}

export async function createLevelProfile(input: LevelProfileCreateInput): Promise<LevelProfileItem> {
  const profileKey = String(input.profileKey || '').trim()
  if (!profileKey) {
    throw new Error('A profileKey megadása kötelező.')
  }
  if (useMock) {
    if (mockLevelProfilesStore.some((p) => p.profileKey === profileKey)) {
      throw new Error('Ilyen profile már létezik (mock).')
    }
    let levels: unknown[] | Record<string, unknown>
    if (input.easyGenerator !== undefined && input.easyGenerator !== null) {
      levels = levelsFromEasyGeneratorUnknown(input.easyGenerator)
    } else if (input.levels != null) {
      levels = input.levels
    } else {
      throw new Error('Adj meg levels tömböt vagy easyGenerator objektumot.')
    }
    if (!Array.isArray(levels) && (typeof levels !== 'object' || levels === null)) {
      throw new Error('A levels formátuma érvénytelen.')
    }
    const displayName = String(input.displayName || '').trim() || profileKey
    const mode: 'easy' | 'advanced' = input.mode === 'easy' ? 'easy' : 'advanced'
    const n = Array.isArray(levels) ? levels.length : Object.keys(levels as object).length
    const item: LevelProfileItem = {
      profileKey,
      displayName,
      mode,
      levels: n,
      levelsData: levels,
      linkedProfessions: 0,
      updatedAt: new Date().toISOString().slice(0, 19).replace('T', ' ')
    }
    mockLevelProfilesStore.push(item)
    syncMockProfileLinks()
    return structuredClone(item)
  }
  const body: LevelProfileCreateInput = { ...input, profileKey }
  const payload = await adminRequest<{ profile: unknown }>('POST', '/admin/level-profiles', { body })
  if (!payload.ok) {
    throw new Error(payload.message ?? String(payload.code ?? 'level profile létrehozás'))
  }
  const data = (payload.data ?? {}) as { profile?: unknown }
  if (!data.profile) {
    throw new Error('Üres válasz: data.profile')
  }
  return normalizeLevelProfile(data.profile)
}

export async function updateLevelProfile(
  profileKey: string,
  input: LevelProfileUpdateInput
): Promise<LevelProfileItem> {
  const pk = String(profileKey || '').trim()
  if (!pk) {
    throw new Error('A profileKey megadása kötelező.')
  }
  if (useMock) {
    const idx = mockLevelProfilesStore.findIndex((p) => p.profileKey === pk)
    if (idx < 0) {
      throw new Error('Nincs ilyen profile (mock).')
    }
    const cur = mockLevelProfilesStore[idx]
    const next: LevelProfileItem = { ...cur }
    if (input.displayName !== undefined) {
      next.displayName = String(input.displayName).trim()
    }
    if (input.mode !== undefined) {
      next.mode = input.mode
    }
    if (input.easyGenerator !== undefined && input.easyGenerator !== null) {
      const generated = levelsFromEasyGeneratorUnknown(input.easyGenerator)
      next.levelsData = generated
      next.levels = generated.length
    } else if (input.levels !== undefined) {
      next.levelsData = input.levels
      const ld = input.levels
      next.levels = Array.isArray(ld) ? ld.length : Object.keys(ld as object).length
    }
    next.updatedAt = new Date().toISOString().slice(0, 19).replace('T', ' ')
    mockLevelProfilesStore[idx] = next
    syncMockProfileLinks()
    return structuredClone(next)
  }
  const payload = await adminRequest<{ profile: unknown }>('PUT', '/admin/level-profiles', {
    query: { profileKey: pk },
    body: input
  })
  if (!payload.ok) {
    throw new Error(payload.message ?? String(payload.code ?? 'level profile frissítés'))
  }
  const data = (payload.data ?? {}) as { profile?: unknown }
  if (!data.profile) {
    throw new Error('Üres válasz: data.profile')
  }
  return normalizeLevelProfile(data.profile)
}

export async function deleteLevelProfile(profileKey: string): Promise<void> {
  const pk = String(profileKey || '').trim()
  if (!pk) {
    throw new Error('A profileKey megadása kötelező.')
  }
  if (useMock) {
    const item = mockLevelProfilesStore.find((p) => p.profileKey === pk)
    if (!item) {
      throw new Error('Nincs ilyen profile (mock).')
    }
    if (item.linkedProfessions > 0) {
      throw new Error('A profile használatban van, nem törölhető (mock).')
    }
    mockLevelProfilesStore = mockLevelProfilesStore.filter((p) => p.profileKey !== pk)
    syncMockProfileLinks()
    return
  }
  const payload = await adminRequest('DELETE', '/admin/level-profiles', { query: { profileKey: pk } })
  if (!payload.ok) {
    throw new Error(payload.message ?? String(payload.code ?? 'level profile törlés'))
  }
}
