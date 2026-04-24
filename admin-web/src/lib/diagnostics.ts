export type RunStatus = 'queued' | 'running' | 'passed' | 'failed' | 'cancelled'

export type DocHint = {
  docId: string
  sectionKey: string
  severity: 'low' | 'medium' | 'high'
  confidence: number
  title: string
  docUrl?: string
}

export type DiagnosticsRun = {
  runId: string
  testKey: string
  status: RunStatus
  startedAt: string
  durationMs: number
  summary: string
  docHints: DocHint[]
  steps: DiagnosticsStep[]
  logs: DiagnosticsLogEntry[]
  resultDetails: DiagnosticsResultDetail[]
}

export type DiagnosticsTest = {
  key: string
  label: string
  description: string
  docHints: DocHint[]
}

export type DiagnosticsStep = {
  id: string
  label: string
  status: 'pending' | 'running' | 'passed' | 'failed'
}

export type DiagnosticsLogEntry = {
  ts: string
  level: 'info' | 'warn' | 'error'
  message: string
}

export type DiagnosticsResultDetail = {
  key: string
  code: string
  issueCount: number
  summary: string
  passed: boolean
  docHints: DocHint[]
}

type DiagnosticsApiResponse<T> = {
  ok: boolean
  code: string
  message?: string
  data?: T
}

const useMock = import.meta.env.VITE_USE_MOCK_DIAGNOSTICS !== 'false'
const docsBaseUrl =
  (import.meta.env.VITE_DOCS_BASE_URL as string | undefined)?.trim() || 'https://example.github.io/e_core-docs'

function buildDocUrl(docId: string, sectionKey: string): string {
  const slug = String(docId || '')
    .toLowerCase()
    .replace(/_hu$/i, '')
    .replace(/_/g, '-')
  const section = String(sectionKey || '').trim()
  return section ? `${docsBaseUrl}/${slug}/#${section}` : `${docsBaseUrl}/${slug}/`
}

function normalizeHint(hint: any): DocHint {
  const docId = String(hint?.docId ?? '')
  const sectionKey = String(hint?.sectionKey ?? '')
  return {
    docId,
    sectionKey,
    severity: (hint?.severity ?? 'medium') as 'low' | 'medium' | 'high',
    confidence: Number(hint?.confidence ?? 0),
    title: String(hint?.title ?? hint?.docId ?? 'Recommended doc'),
    docUrl: String(hint?.docUrl ?? buildDocUrl(docId, sectionKey))
  }
}
const mockTests: DiagnosticsTest[] = [
  {
    key: 'profession-key-validation',
    label: 'Profession Key Validation',
    description: 'Registry kulcsok validalasa kategoriankent.',
    docHints: [
      {
        docId: 'PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU',
        sectionKey: 'f3-e3-profession-key-validation',
        severity: 'high',
        confidence: 0.95,
        title: 'Profession key validacio'
        ,docUrl: buildDocUrl('PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU', 'f3-e3-profession-key-validation')
      }
    ]
  },
  {
    key: 'registry-health',
    label: 'Registry Health',
    description: 'Profil kapcsolat es levels konzisztencia ellenorzese.',
    docHints: []
  },
  {
    key: 'meta-cleanup-dry-run',
    label: 'Meta Cleanup Dry Run',
    description: 'Dry-run futtatasa torles nelkul.',
    docHints: []
  }
]

const mockRuns: DiagnosticsRun[] = [
  {
    runId: 'diag-20260424-001',
    testKey: 'profession-key-validation',
    status: 'failed',
    startedAt: '2026-04-24 17:09',
    durationMs: 1820,
    summary: '2 invalid profession kulcs talalva startup validacio kozben.',
    docHints: [
      {
        docId: 'PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU',
        sectionKey: 'f3-e3-profession-key-validation',
        severity: 'high',
        confidence: 0.97,
        title: 'Profession key validacio es cleanup terv'
        ,docUrl: buildDocUrl('PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU', 'f3-e3-profession-key-validation')
      },
      {
        docId: 'PUBLIC_API_HU',
        sectionKey: 'diagnostics-admin-run',
        severity: 'medium',
        confidence: 0.86,
        title: 'Diagnostics admin futtatas API szerzodes',
        docUrl: buildDocUrl('PUBLIC_API_HU', 'diagnostics-admin-run')
      }
    ],
    steps: [
      { id: 'load-registry', label: 'Registry betoltese', status: 'passed' },
      { id: 'validate-keys', label: 'Kulcs validacio', status: 'failed' },
      { id: 'collect-doc-hints', label: 'Doc hint generalas', status: 'passed' }
    ],
    logs: [
      { ts: '17:09:01', level: 'info', message: 'Run started: profession-key-validation' },
      { ts: '17:09:02', level: 'info', message: 'Registry loaded: 6 professions.' },
      { ts: '17:09:03', level: 'error', message: 'Invalid keys detected: cooking_typo, chemst.' }
    ],
    resultDetails: [
      {
        key: 'profession-key-validation',
        code: 'profession_not_found',
        issueCount: 2,
        summary: 'A profession kulcsvalidáció hibákat talált.',
        passed: false,
        docHints: [
          {
            docId: 'PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU',
            sectionKey: 'f3-e3-profession-key-validation',
            severity: 'high',
            confidence: 0.97,
            title: 'Profession key validacio es cleanup terv',
            docUrl: buildDocUrl('PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU', 'f3-e3-profession-key-validation')
          }
        ]
      }
    ]
  },
  {
    runId: 'diag-20260424-002',
    testKey: 'registry-health',
    status: 'passed',
    startedAt: '2026-04-24 17:14',
    durationMs: 740,
    summary: 'Registry tabla, profile kapcsolat es levels konzisztencia rendben.',
    docHints: [],
    steps: [
      { id: 'load-registry', label: 'Registry betoltese', status: 'passed' },
      { id: 'check-profiles', label: 'Profile link ellenorzes', status: 'passed' },
      { id: 'check-levels', label: 'Levels konzisztencia', status: 'passed' }
    ],
    logs: [
      { ts: '17:14:00', level: 'info', message: 'Run started: registry-health' },
      { ts: '17:14:00', level: 'info', message: 'All profile links are valid.' },
      { ts: '17:14:01', level: 'info', message: 'Completed with status passed.' }
    ],
    resultDetails: [
      {
        key: 'registry_integrity',
        code: 'ok',
        issueCount: 0,
        summary: 'A profession registry konzisztens.',
        passed: true,
        docHints: []
      }
    ]
  },
  {
    runId: 'diag-20260424-003',
    testKey: 'meta-cleanup-dry-run',
    status: 'running',
    startedAt: '2026-04-24 17:16',
    durationMs: 0,
    summary: 'Dry-run sorban all, status poll folyamatban.',
    docHints: [],
    steps: [
      { id: 'queue', label: 'Sorba allitas', status: 'passed' },
      { id: 'scan-meta', label: 'Meta scan dry-run', status: 'running' },
      { id: 'report', label: 'Riport generalas', status: 'pending' }
    ],
    logs: [
      { ts: '17:16:10', level: 'info', message: 'Run queued: meta-cleanup-dry-run' },
      { ts: '17:16:12', level: 'info', message: 'Scanning players metadata in batches...' }
    ],
    resultDetails: []
  }
]

function getApiBaseUrl(): string {
  return (import.meta.env.VITE_DIAGNOSTICS_API_BASE_URL as string | undefined)?.trim() ?? ''
}

async function getJson<T>(url: string): Promise<T> {
  const response = await fetch(url)
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`)
  }
  return (await response.json()) as T
}

function normalizeRun(input: any): DiagnosticsRun {
  const results = Array.isArray(input.results) ? input.results : []
  const summaryRaw = input.summary
  const summaryObj = typeof summaryRaw === 'object' && summaryRaw !== null ? summaryRaw : null

  let summaryText = String(input.summary ?? '')
  if (summaryObj) {
    const passed = Number(summaryObj.passed ?? 0)
    const failed = Number(summaryObj.failed ?? 0)
    const cancelled = summaryObj.cancelled === true
    summaryText = `passed=${passed}, failed=${failed}${cancelled ? ', cancelled=true' : ''}`
  }

  const steps: DiagnosticsStep[] = results.map((result: any, index: number) => ({
    id: String(result.key ?? `step-${index + 1}`),
    label: String(result.key ?? `Step ${index + 1}`),
    status: result.passed === true ? 'passed' : 'failed'
  }))

  const logs: DiagnosticsLogEntry[] = []
  for (const result of results) {
    const lines = Array.isArray(result?.lines) ? result.lines : []
    for (const line of lines) {
      const msg = String(line ?? '')
      let level: DiagnosticsLogEntry['level'] = 'info'
      const lower = msg.toLowerCase()
      if (lower.includes('hiba') || lower.includes('error')) {
        level = 'error'
      } else if (lower.includes('warn')) {
        level = 'warn'
      }
      logs.push({
        ts: '',
        level,
        message: msg
      })
    }
  }

  const docHints: DocHint[] = []
  const resultDetails: DiagnosticsResultDetail[] = []
  for (const result of results) {
    const hints = Array.isArray(result?.docHints) ? result.docHints : []
    const mappedHints: DocHint[] = []
    for (const hint of hints) {
      const mapped = normalizeHint(hint)
      docHints.push(mapped)
      mappedHints.push(mapped)
    }
    resultDetails.push({
      key: String(result?.key ?? ''),
      code: String(result?.code ?? ''),
      issueCount: Number(result?.issueCount ?? 0),
      summary: String(result?.summary ?? ''),
      passed: result?.passed === true,
      docHints: mappedHints
    })
  }

  return {
    runId: String(input.runId ?? input.run_id ?? ''),
    testKey: String(
      input.testKey ?? input.test_key ?? (Array.isArray(input.tests) ? input.tests.join(',') : 'unknown-test')
    ),
    status: (input.status ?? 'queued') as RunStatus,
    startedAt: String(input.startedAt ?? input.started_at ?? '-'),
    durationMs: Number(input.durationMs ?? input.duration_ms ?? 0),
    summary: summaryText,
    docHints: Array.isArray(input.docHints) ? input.docHints.map(normalizeHint) : docHints,
    steps: Array.isArray(input.steps) ? input.steps : steps,
    logs: Array.isArray(input.logs) ? input.logs : logs,
    resultDetails: Array.isArray(input.resultDetails) ? input.resultDetails : resultDetails
  }
}

export async function listDiagnosticsRuns(): Promise<DiagnosticsRun[]> {
  if (useMock) {
    return structuredClone(mockRuns)
  }

  const baseUrl = getApiBaseUrl()
  if (!baseUrl) {
    throw new Error('VITE_DIAGNOSTICS_API_BASE_URL not configured')
  }

  const payload = await getJson<DiagnosticsApiResponse<{ items?: any[]; runs?: any[] }>>(
    `${baseUrl}/diagnostics/runs`
  )
  const items = payload.data?.items ?? payload.data?.runs ?? []
  return items.map(normalizeRun)
}

export async function getDiagnosticsRun(runId: string): Promise<DiagnosticsRun> {
  if (useMock) {
    const run = mockRuns.find((item) => item.runId === runId)
    if (!run) {
      throw new Error(`Run not found: ${runId}`)
    }
    return structuredClone(run)
  }

  const baseUrl = getApiBaseUrl()
  if (!baseUrl) {
    throw new Error('VITE_DIAGNOSTICS_API_BASE_URL not configured')
  }

  const payload = await getJson<DiagnosticsApiResponse<any>>(`${baseUrl}/diagnostics/runs/${runId}`)
  if (!payload.data) {
    throw new Error(payload.message ?? 'Run payload missing')
  }
  return normalizeRun(payload.data.run ?? payload.data)
}

export async function cancelDiagnosticsRun(runId: string): Promise<void> {
  if (useMock) {
    const run = mockRuns.find((item) => item.runId === runId)
    if (run && (run.status === 'queued' || run.status === 'running')) {
      run.status = 'cancelled'
      run.summary = 'Run manually cancelled from admin UI.'
    }
    return
  }

  const baseUrl = getApiBaseUrl()
  if (!baseUrl) {
    throw new Error('VITE_DIAGNOSTICS_API_BASE_URL not configured')
  }

  const response = await fetch(`${baseUrl}/diagnostics/runs/${runId}/cancel`, { method: 'POST' })
  if (!response.ok) {
    throw new Error(`Cancel failed with HTTP ${response.status}`)
  }
}

export async function listDiagnosticsTests(): Promise<DiagnosticsTest[]> {
  if (useMock) {
    return structuredClone(mockTests)
  }

  const baseUrl = getApiBaseUrl()
  if (!baseUrl) {
    throw new Error('VITE_DIAGNOSTICS_API_BASE_URL not configured')
  }

  const payload = await getJson<DiagnosticsApiResponse<{ items?: DiagnosticsTest[] }>>(
    `${baseUrl}/diagnostics/tests`
  )
  const items = payload.data?.items ?? []
  return items.map((item) => ({
    key: String(item.key ?? ''),
    label: String(item.label ?? item.key ?? 'Unknown test'),
    description: String((item as any).description ?? (item as any).estimatedCost ?? ''),
    docHints: Array.isArray(item.docHints) ? item.docHints.map(normalizeHint) : []
  }))
}

export async function runDiagnosticsTests(tests: string[]): Promise<{ runId: string }> {
  if (!tests.length) {
    throw new Error('At least one test is required')
  }

  if (useMock) {
    const runId = `diag-${Date.now()}`
    mockRuns.unshift({
      runId,
      testKey: tests.join(','),
      status: 'queued',
      startedAt: new Date().toISOString(),
      durationMs: 0,
      summary: `Queued ${tests.length} diagnostics test(s).`,
      docHints: [],
      steps: [
        { id: 'queue', label: 'Sorba allitas', status: 'passed' },
        { id: 'execute', label: 'Tesztek futtatasa', status: 'pending' }
      ],
      logs: [{ ts: new Date().toLocaleTimeString('hu-HU'), level: 'info', message: 'Run queued from UI.' }],
      resultDetails: []
    })
    return { runId }
  }

  const baseUrl = getApiBaseUrl()
  if (!baseUrl) {
    throw new Error('VITE_DIAGNOSTICS_API_BASE_URL not configured')
  }

  const response = await fetch(`${baseUrl}/diagnostics/run`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ tests })
  })
  if (!response.ok) {
    throw new Error(`Run failed with HTTP ${response.status}`)
  }

  const payload = (await response.json()) as DiagnosticsApiResponse<{
    runId?: string
    run_id?: string
    run?: { runId?: string; run_id?: string }
  }>
  const runId = String(payload.data?.runId ?? payload.data?.run_id ?? payload.data?.run?.runId ?? '')
  if (!runId) {
    throw new Error('Missing runId in diagnostics run response')
  }
  return { runId }
}
