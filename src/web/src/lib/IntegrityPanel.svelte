<script lang="ts">
  import { onMount, onDestroy } from 'svelte'
  import { fade, fly, slide } from 'svelte/transition'
  import { fetchNui } from './nui'

  type IntegrityStatus = 'pending' | 'running' | 'ok' | 'fail' | 'skipped' | 'cancelled'
  type IntegrityStep = { id: string; label: string }
  type IntegrityTestRow = {
    id: string
    label: string
    status: IntegrityStatus
    detail: string
    updatedAt: number
  }

  const BASE_STEPS: IntegrityStep[] = [
    { id: 'env', label: 'Környezet (resource, framework, isReady)' },
    { id: 'registry', label: 'Profession registry konzisztencia' },
    { id: 'weight', label: 'Aktuális súly (getInventoryWeight)' },
    { id: 'maxw', label: 'Max súly (getPlayerMaxWeight / Config)' },
    { id: 'carry', label: 'canCarryItem (teszt item × mennyiség)' },
    { id: 'mutate', label: 'addItem → removeItem teszt' },
    { id: 'progress', label: 'Kliens progress sáv' }
  ]

  /** Fix értékek – az Integritás fülön szerkeszthető mezők küldése a teljes futáshoz. */
  const FIXED_DEFAULTS_INFO: { label: string; value: string }[] = [
    {
      label: 'Cooldown (két teljes futtatás között)',
      value: '1500 ms alap (min. 1500; operator.integrityCheck.cooldownMs). Egy lépés gomb: nincs cooldown.'
    },
    { label: 'Teszt mennyiség (alap)', value: '1 db' },
    { label: 'addItem → removeItem próba', value: 'bekapcsolva (tryAddRemove)' },
    { label: 'Progress teszt időtartam', value: '3000 ms' },
    { label: 'F8 / konzol print (admin futásnál is)', value: 'kikapcsolva' },
    { label: 'UI lépésköz (szerver tick)', value: '55 ms (0–400)' }
  ]

  function stepsForForm(): IntegrityStep[] {
    const out: IntegrityStep[] = []
    for (const s of BASE_STEPS) {
      if (s.id === 'mutate' && !tryAddRemove) {
        continue
      }
      if (s.id === 'carry') {
        out.push({
          id: 'carry',
          label: `canCarryItem (${String(testItem ?? '').trim() || 'water'} × ${Math.max(1, Number(testItemAmount) || 1)})`
        })
        continue
      }
      out.push(s)
    }
    return out
  }

  let testItem = $state('water')
  let testItemAmount = $state(1)
  let cooldownMs = $state(1500)
  let tryAddRemove = $state(true)
  let progressDurationMs = $state(3000)
  let printToConsole = $state(false)
  let uiStepMs = $state(55)

  let fullRunBusy = $state(false)
  let rowBusy = $state<Record<string, boolean>>({})
  let rows = $state<Record<string, IntegrityTestRow>>({})
  let rowOrder = $state<string[]>([])
  let liveHint = $state('')
  let logLines = $state<string[]>([])
  let awaitingProgress = $state(false)
  let currentScope = $state<'full' | 'single' | 'verify_failed' | null>(null)
  let scopedIds = $state<string[]>([])
  let autoScrollLog = $state(true)
  let logContainer: HTMLDivElement | null = null
  let reportStatus = $state('')

  const displaySteps = $derived(stepsForForm())
  const displayRows = $derived.by(() => {
    const fallback = displaySteps
    const ids = rowOrder.length > 0 ? rowOrder : fallback.map((x) => x.id)
    return ids.map((id) => {
      const fromState = rows[id]
      if (fromState) {
        return fromState
      }
      const fromBase = fallback.find((x) => x.id === id)
      return {
        id,
        label: fromBase?.label ?? id,
        status: 'pending' as IntegrityStatus,
        detail: '',
        updatedAt: 0
      }
    })
  })
  const failedIds = $derived(displayRows.filter((r) => r.status === 'fail').map((r) => r.id))
  const failedRows = $derived(displayRows.filter((r) => r.status === 'fail'))
  const shouldVerify = $derived(failedIds.length > 0)
  const primaryLabel = $derived(shouldVerify ? 'Verify Changes' : 'Run Full Integrity Check')

  function buildIntegrityOpts(): Record<string, unknown> {
    return {
      inlineAdmin: true,
      cooldownMs: Math.max(1500, Number(cooldownMs) || 1500),
      testItem: String(testItem ?? '').trim() || 'water',
      testItemAmount: Math.max(1, Number(testItemAmount) || 1),
      tryAddRemove,
      progressDurationMs: Math.max(1000, Math.min(60000, Number(progressDurationMs) || 3000)),
      useNui: true,
      printToConsole,
      uiStepMs: Math.max(0, Math.min(400, Number(uiStepMs) || 55))
    }
  }

  function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => {
      setTimeout(resolve, ms)
    })
  }

  function trimLog(lines: string[]): string[] {
    const MAX_LOG_LINES = 200
    if (lines.length <= MAX_LOG_LINES) {
      return lines
    }
    return lines.slice(lines.length - MAX_LOG_LINES)
  }

  function isTerminal(status: IntegrityStatus): boolean {
    return status === 'ok' || status === 'fail' || status === 'skipped' || status === 'cancelled'
  }

  function setScopedBusy(scope: 'full' | 'single' | 'verify_failed' | null, ids: string[]) {
    currentScope = scope
    scopedIds = [...ids]
    if (scope === 'full' || scope === 'verify_failed') {
      fullRunBusy = true
    }
  }

  function maybeResolveScope() {
    if (!currentScope || scopedIds.length === 0) {
      return
    }
    const done = scopedIds.every((id) => {
      const row = rows[id]
      return row ? isTerminal(row.status) : false
    })
    if (!done) {
      return
    }
    if (currentScope === 'full' || currentScope === 'verify_failed') {
      fullRunBusy = false
    }
    currentScope = null
    scopedIds = []
  }

  function ensureRow(id: string, label?: string): IntegrityTestRow {
    const current = rows[id]
    if (current) {
      if (label && label !== current.label) {
        const merged = { ...current, label }
        rows = { ...rows, [id]: merged }
        return merged
      }
      return current
    }
    const fallback = displaySteps.find((x) => x.id === id)
    const created: IntegrityTestRow = {
      id,
      label: label ?? fallback?.label ?? id,
      status: 'pending',
      detail: '',
      updatedAt: Date.now()
    }
    rows = { ...rows, [id]: created }
    if (!rowOrder.includes(id)) {
      rowOrder = [...rowOrder, id]
    }
    return created
  }

  function updateRow(id: string, partial: Partial<IntegrityTestRow>) {
    const base = ensureRow(id)
    const next: IntegrityTestRow = { ...base, ...partial, updatedAt: Date.now() }
    rows = { ...rows, [id]: next }
    if (id === 'progress') {
      awaitingProgress = next.status === 'running'
    }
    if (isTerminal(next.status)) {
      rowBusy = { ...rowBusy, [id]: false }
    }
    maybeResolveScope()
  }

  function resetInlineUi() {
    liveHint = ''
    logLines = []
    awaitingProgress = false
    const next: Record<string, IntegrityTestRow> = {}
    const order: string[] = []
    for (const s of displaySteps) {
      order.push(s.id)
      next[s.id] = {
        id: s.id,
        label: s.label,
        status: 'pending',
        detail: '',
        updatedAt: Date.now()
      }
    }
    rowOrder = order
    rows = next
    rowBusy = {}
    fullRunBusy = false
    currentScope = null
    scopedIds = []
  }

  function onGameMessage(event: MessageEvent) {
    const item = event.data
    if (!item || typeof item !== 'object' || item.adminInline !== true) {
      return
    }
    const action = item.action as string

    switch (action) {
      case 'DIAGNOSTICS_RUN_START':
        resetInlineUi()
        break
      case 'DIAGNOSTICS_CHECKLIST_INIT': {
        const items = Array.isArray(item.items) ? item.items : []
        const nextRows: Record<string, IntegrityTestRow> = { ...rows }
        const nextOrder: string[] = []
        for (const it of items) {
          const id = String((it as { id?: string }).id || '').trim()
          const label = String((it as { label?: string }).label || id).trim() || id
          if (id) {
            nextOrder.push(id)
            nextRows[id] = {
              id,
              label,
              status: 'pending',
              detail: '',
              updatedAt: Date.now()
            }
          }
        }
        rowOrder = nextOrder
        rows = nextRows
        rowBusy = {}
        awaitingProgress = false
        break
      }
      case 'DIAGNOSTICS_CHECKLIST_SET': {
        const id = String(item.id || '').trim()
        const raw = String(item.status || 'pending')
        const detail = String(item.detail || '')
        let ui: IntegrityStatus = 'pending'
        if (raw === 'ok' || raw === 'fail' || raw === 'running' || raw === 'skipped' || raw === 'cancelled' || raw === 'pending') {
          ui = raw
        }
        if (id) {
          updateRow(id, { status: ui, detail })
        }
        break
      }
      case 'DIAGNOSTICS_LIVE_HINT':
        liveHint = String(item.text || '')
        break
      case 'DIAGNOSTICS_LOG_SET': {
        const lines = Array.isArray(item.lines) ? item.lines.map((x: unknown) => String(x)) : []
        logLines = trimLog(lines)
        break
      }
      case 'DIAGNOSTICS_INLINE_LOG': {
        const lines = Array.isArray(item.lines) ? item.lines.map((x: unknown) => String(x)) : []
        logLines = trimLog([...logLines, ...lines])
        break
      }
      case 'DIAGNOSTICS_APPEND': {
        const lines = Array.isArray(item.lines) ? item.lines.map((x: unknown) => String(x)) : []
        logLines = trimLog([...logLines, ...lines])
        break
      }
      default:
        break
    }
  }

  async function requestFullRun(): Promise<void> {
    resetInlineUi()
    const ids = displaySteps.map((x) => x.id)
    setScopedBusy('full', ids)
    try {
      await fetchNui('integrityCheckRequest', { opts: buildIntegrityOpts() }, 'integrityDiagnosticsRun')
    } catch {
      fullRunBusy = false
      currentScope = null
      scopedIds = []
      liveHint = 'Integrity request failed: NUI endpoint not reachable.'
      logLines = trimLog([...logLines, '[Integrity UI] NUI request failed. Check callback route.'])
    }
  }

  async function requestSingleStep(stepId: string): Promise<void> {
    rowBusy = { ...rowBusy, [stepId]: true }
    setScopedBusy('single', [stepId])
    try {
      await fetchNui('integrityCheckRequest', { opts: { ...buildIntegrityOpts(), onlyStep: stepId } }, 'integrityDiagnosticsRun')
    } catch {
      rowBusy = { ...rowBusy, [stepId]: false }
      currentScope = null
      scopedIds = []
      liveHint = `OnlyStep request failed (${stepId}).`
      logLines = trimLog([...logLines, `[Integrity UI] OnlyStep request failed: ${stepId}`])
    }
  }

  async function requestVerifyFailed(): Promise<void> {
    if (failedIds.length === 0) {
      return
    }
    setScopedBusy('verify_failed', failedIds)
    try {
      for (const stepId of failedIds) {
        rowBusy = { ...rowBusy, [stepId]: true }
        await fetchNui('integrityCheckRequest', { opts: { ...buildIntegrityOpts(), onlyStep: stepId } }, 'integrityDiagnosticsRun')
        await sleep(360)
      }
    } catch {
      fullRunBusy = false
      currentScope = null
      scopedIds = []
      liveHint = 'Verify Changes request failed.'
      logLines = trimLog([...logLines, '[Integrity UI] Verify Changes request failed.'])
    }
  }

  async function onPrimaryClick(): Promise<void> {
    if (fullRunBusy) {
      return
    }
    if (shouldVerify) {
      await requestVerifyFailed()
      return
    }
    await requestFullRun()
  }

  function statusIcon(status: IntegrityStatus): string {
    const s = status
    if (s === 'running') {
      return '⟳'
    }
    if (s === 'ok') {
      return '✓'
    }
    if (s === 'fail') {
      return '✗'
    }
    if (s === 'skipped' || s === 'cancelled') {
      return '⊘'
    }
    if (s === 'pending') {
      return '○'
    }
    return '○'
  }

  function statusClass(status: IntegrityStatus): string {
    return `is-${status}`
  }

  function buildSupportReportText(): string {
    const opts = buildIntegrityOpts()
    const now = new Date().toISOString()
    const lines: string[] = []
    lines.push('=== e_core Integrity Support Report ===')
    lines.push(`generatedAt: ${now}`)
    lines.push(`scope: checkIntegrity inline-admin run`)
    lines.push('')
    lines.push('[Options]')
    lines.push(`cooldownMs=${String(opts.cooldownMs)}`)
    lines.push(`testItem=${String(opts.testItem)}`)
    lines.push(`testItemAmount=${String(opts.testItemAmount)}`)
    lines.push(`tryAddRemove=${String(opts.tryAddRemove)}`)
    lines.push(`progressDurationMs=${String(opts.progressDurationMs)}`)
    lines.push(`printToConsole=${String(opts.printToConsole)}`)
    lines.push(`uiStepMs=${String(opts.uiStepMs)}`)
    lines.push('')
    lines.push('[Checklist]')
    for (const row of displayRows) {
      lines.push(`- ${row.id} | ${row.status} | ${row.label}${row.detail ? ` | ${row.detail}` : ''}`)
    }
    lines.push('')
    lines.push('[Failed Steps]')
    if (failedRows.length === 0) {
      lines.push('- none')
    } else {
      for (const row of failedRows) {
        lines.push(`- ${row.id} | ${row.label}${row.detail ? ` | ${row.detail}` : ''}`)
      }
    }
    lines.push('')
    lines.push('[Raw Log]')
    if (logLines.length === 0) {
      lines.push('- empty')
    } else {
      for (const line of logLines) {
        lines.push(line)
      }
    }
    return lines.join('\n')
  }

  async function copySupportReport(): Promise<void> {
    try {
      const txt = buildSupportReportText()
      await navigator.clipboard.writeText(txt)
      reportStatus = 'Report a vágólapra másolva.'
    } catch {
      reportStatus = 'Másolás sikertelen (clipboard tiltva).'
    }
  }

  function downloadSupportReport(): void {
    try {
      const txt = buildSupportReportText()
      const stamp = new Date().toISOString().replace(/[:.]/g, '-')
      const blob = new Blob([txt], { type: 'text/plain;charset=utf-8' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `e_core-integrity-report-${stamp}.txt`
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
      reportStatus = 'Report .txt letöltés indítva.'
    } catch {
      reportStatus = 'Letöltés sikertelen.'
    }
  }

  function lineTone(line: string): string {
    const t = line.toLowerCase()
    if (t.includes('hiba') || t.includes(': nem,')) {
      return 'log--bad'
    }
    if (t.includes(': ok') || t.endsWith(': ok')) {
      return 'log--ok'
    }
    if (t.startsWith('---')) {
      return 'log--sep'
    }
    return ''
  }

  onMount(() => {
    window.addEventListener('message', onGameMessage)
    resetInlineUi()
  })

  onDestroy(() => {
    window.removeEventListener('message', onGameMessage)
  })

  function onLogScroll() {
    if (!logContainer) {
      return
    }
    const threshold = 18
    const offset = logContainer.scrollHeight - (logContainer.scrollTop + logContainer.clientHeight)
    autoScrollLog = offset <= threshold
  }

  $effect(() => {
    logLines.length
    if (!autoScrollLog || !logContainer) {
      return
    }
    queueMicrotask(() => {
      if (!logContainer || !autoScrollLog) {
        return
      }
      logContainer.scrollTop = logContainer.scrollHeight
    })
  })

  let lastStepIds = $state('')
  $effect(() => {
    const k = displaySteps.map((s) => s.id).join(',')
    if (k === lastStepIds) {
      return
    }
    lastStepIds = k
    const nextRows: Record<string, IntegrityTestRow> = {}
    const nextOrder: string[] = []
    for (const s of displaySteps) {
      nextOrder.push(s.id)
      const existing = rows[s.id]
      nextRows[s.id] = existing ?? {
        id: s.id,
        label: s.label,
        status: 'pending',
        detail: '',
        updatedAt: Date.now()
      }
    }
    rowOrder = nextOrder
    rows = nextRows
  })
</script>

<div class="integrity-layout">
  <div class="integrity-col integrity-col--left">
    <div class="card">
      <div class="card-header">
        <h3>Teljes integritás vizsgálat</h3>
        <button
          type="button"
          class="primary"
          onclick={onPrimaryClick}
          disabled={fullRunBusy}
          title="Automatikus teljes futás vagy hibás sorok célzott újraellenőrzése."
        >
          {fullRunBusy ? 'Folyamatban…' : primaryLabel}
        </button>
      </div>
      <p class="muted small">
        A szerver napló a jobb oldali rögzített panelen látszik, így görgetés közben is követhető. A progress sáv a játék
        UI-ban (ox_lib / egyéb) jelenik meg a háttérben.
      </p>
    </div>

    <div class="card">
      <h3>Integritás lépések</h3>
      <p class="muted small">
        Egy lépés futtatása külön (szerver + szükség esetén kliens progress). A napló futás közben végig látszik a jobb
        oldalon.
      </p>
      <div class="report-actions">
        <button type="button" class="secondary" onclick={copySupportReport} title="Teljes support report másolása">
          Copy Report
        </button>
        <button type="button" class="secondary" onclick={downloadSupportReport} title="Teljes support report mentése txt-be">
          Save Report (.txt)
        </button>
      </div>
      {#if reportStatus}
        <p class="muted small">{reportStatus}</p>
      {/if}
      <ul class="step-list">
        {#each displayRows as row (row.id)}
          <li class="step-row {statusClass(row.status)}" transition:slide={{ duration: 140 }}>
            <span class="step-icon {statusClass(row.status)}" aria-hidden="true">{statusIcon(row.status)}</span>
            <div class="step-meta">
              <strong>{row.label}</strong>
              <span class="mono">{row.id}</span>
              {#if row.detail.trim()}
                <small class="step-detail" transition:fly={{ y: 4, duration: 150 }}>{row.detail}</small>
              {:else if row.id === 'progress' && awaitingProgress}
                <small class="step-detail is-live" transition:fly={{ y: 4, duration: 150 }}>
                  Awaiting client progress callback...
                </small>
              {/if}
            </div>
            <button
              type="button"
              class="secondary icon-button"
              onclick={() => requestSingleStep(row.id)}
              disabled={rowBusy[row.id] === true || fullRunBusy || row.status === 'running' || (row.id === 'progress' && awaitingProgress)}
              title="OnlyStep futtatás"
            >
              {rowBusy[row.id] ? '…' : row.status === 'fail' ? '↻' : '▶'}
            </button>
          </li>
        {/each}
      </ul>
    </div>

    <div class="card">
      <h3>Futási opciók</h3>
      <p class="muted small">Alapértelmezett referencia (config + szerver fixek):</p>
      <ul class="defaults-list">
        {#each FIXED_DEFAULTS_INFO as row}
          <li><span class="def-label">{row.label}:</span> {row.value}</li>
        {/each}
      </ul>

      <div class="form-grid">
        <label>
          Cooldown (ms)
          <input type="number" min="1500" max="600000" bind:value={cooldownMs} />
        </label>
        <label>
          Teszt item
          <input type="text" bind:value={testItem} placeholder="pl. water" autocomplete="off" />
        </label>
        <label>
          Mennyiség
          <input type="number" min="1" max="999" bind:value={testItemAmount} />
        </label>
        <label>
          Progress idő (ms)
          <input type="number" min="1000" max="60000" bind:value={progressDurationMs} />
        </label>
        <label>
          UI lépésköz (ms)
          <input type="number" min="0" max="400" bind:value={uiStepMs} />
        </label>
        <label class="check">
          <input type="checkbox" bind:checked={tryAddRemove} />
          addItem / removeItem próba
        </label>
        <label class="check">
          <input type="checkbox" bind:checked={printToConsole} />
          F8 print is
        </label>
      </div>
    </div>
  </div>

  <div class="integrity-col integrity-col--right">
    <div class="card log-card">
      <h3>Eredmény napló</h3>
      {#if liveHint.trim()}
        <div class="hint-strip" transition:fly={{ y: -4, duration: 160 }}>
          <span class="hint-dot" aria-hidden="true"></span>
          <span>{liveHint}</span>
        </div>
      {/if}
      <div class="log-scroll" role="log" aria-live="polite" bind:this={logContainer} onscroll={onLogScroll}>
        {#if logLines.length === 0}
          <p class="muted small">Indítás után itt jelennek meg a szerver sorok és a progress összefoglaló.</p>
        {:else}
          {#each logLines as line}
            <div class="log-line {lineTone(line)}" transition:fade={{ duration: 120 }}>{line}</div>
          {/each}
        {/if}
      </div>
    </div>
  </div>
</div>

<style>
  .integrity-layout,
  .integrity-layout * {
    --color-success: #2ecc71;
    --color-error: #e74c3c;
    --color-running: #3498db;
    --color-pending: #95a5a6;
    --color-skipped: #f39c12;
    --color-cancelled: #c084fc;
    --color-surface-dark: #0f1115;
    --color-text-muted: #a7b0c0;
  }
  .integrity-layout {
    display: grid;
    grid-template-columns: minmax(0, 1.12fr) minmax(320px, 0.88fr);
    gap: 1rem;
    align-items: start;
    min-height: 0;
  }
  @media (max-width: 900px) {
    .integrity-layout {
      grid-template-columns: 1fr;
    }
  }
  .integrity-col {
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
  .integrity-col--right {
    min-height: 0;
    position: sticky;
    top: 0.4rem;
    align-self: start;
  }
  .log-card {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-height: 12rem;
    max-height: min(78vh, 50rem);
  }
  .hint-strip {
    margin: 0 0 0.5rem;
    padding: 0.45rem 0.6rem;
    border-radius: 8px;
    background: #162638;
    border: 1px solid #2f4f72;
    color: #dbeafe;
    font-size: 0.9rem;
    display: flex;
    align-items: center;
    gap: 0.55rem;
  }
  .hint-dot {
    width: 0.62rem;
    height: 0.62rem;
    border-radius: 999px;
    background: var(--color-running);
    box-shadow: 0 0 0 0 rgba(52, 152, 219, 0.45);
    animation: hintPulse 1.15s ease-out infinite;
  }
  @keyframes hintPulse {
    0% {
      box-shadow: 0 0 0 0 rgba(52, 152, 219, 0.45);
    }
    100% {
      box-shadow: 0 0 0 8px rgba(52, 152, 219, 0);
    }
  }
  .log-scroll {
    flex: 1;
    min-height: 0;
    overflow-y: auto;
    padding: 0.5rem 0.45rem 0.5rem;
    border-radius: 8px;
    background: var(--color-surface-dark);
    border: 1px solid #212733;
    font-family: ui-monospace, 'Cascadia Code', monospace;
    font-size: 0.82rem;
    line-height: 1.45;
  }
  .log-line {
    padding: 0.12rem 0;
    color: #c6d3ee;
    white-space: pre-wrap;
    word-break: break-word;
  }
  .log--bad {
    color: #fecaca;
  }
  .log--ok {
    color: #bbf7d0;
  }
  .log--sep {
    color: #94a3b8;
    margin-top: 0.35rem;
  }
  .card-header {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
  }
  .primary {
    background: #2563eb;
    color: #f8fafc;
    border: 1px solid #1d4ed8;
    border-radius: 8px;
    padding: 0.5rem 1rem;
    cursor: pointer;
    font-weight: 600;
  }
  .primary:disabled {
    opacity: 0.55;
    cursor: not-allowed;
  }
  .secondary {
    background: #182746;
    color: #e2ecff;
    border: 1px solid #31466f;
    border-radius: 8px;
    padding: 0.4rem 0.75rem;
    cursor: pointer;
    font-size: 0.88rem;
  }
  .secondary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  .muted {
    color: var(--color-text-muted);
    margin: 0.25rem 0 0;
  }
  .muted.small {
    font-size: 0.85rem;
  }
  .defaults-list {
    margin: 0.35rem 0 1rem;
    padding-left: 1.2rem;
    color: #c6d3ee;
    font-size: 0.9rem;
  }
  .def-label {
    color: #94a3b8;
  }
  .form-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 0.75rem 1rem;
  }
  .form-grid label {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    font-size: 0.88rem;
    color: #c6d3ee;
  }
  .form-grid input[type='text'],
  .form-grid input[type='number'] {
    padding: 0.45rem 0.55rem;
    border-radius: 6px;
    border: 1px solid #31466f;
    background: #0f172a;
    color: #e2ecff;
  }
  label.check {
    flex-direction: row;
    align-items: center;
    gap: 0.5rem;
  }
  .step-list {
    list-style: none;
    margin: 0.5rem 0 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    max-height: min(46vh, 28rem);
    overflow-y: auto;
    padding-right: 0.2rem;
  }
  .report-actions {
    display: flex;
    gap: 0.55rem;
    margin: 0.35rem 0 0.5rem;
    flex-wrap: wrap;
  }
  .step-row {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 0.65rem;
    padding: 0.55rem 0.65rem;
    border: 1px solid #31466f;
    border-radius: 8px;
    background: #182746;
  }
  .step-row.is-running {
    border-color: color-mix(in srgb, var(--color-running) 50%, #31466f);
  }
  .step-row.is-ok {
    border-color: color-mix(in srgb, var(--color-success) 45%, #31466f);
  }
  .step-row.is-fail {
    border-color: color-mix(in srgb, var(--color-error) 50%, #31466f);
  }
  .step-row.is-skipped {
    border-color: color-mix(in srgb, var(--color-skipped) 50%, #31466f);
  }
  .step-row.is-cancelled {
    border-color: color-mix(in srgb, var(--color-cancelled) 45%, #31466f);
  }
  .step-icon {
    width: 1.75rem;
    text-align: center;
    font-size: 1.2rem;
    font-weight: 800;
  }
  .step-icon.is-ok {
    color: var(--color-success);
  }
  .step-icon.is-fail {
    color: var(--color-error);
  }
  .step-icon.is-running {
    color: var(--color-running);
  }
  .step-icon.is-skipped {
    color: var(--color-skipped);
  }
  .step-icon.is-cancelled {
    color: var(--color-cancelled);
  }
  .step-icon.is-pending {
    color: var(--color-pending);
  }
  .step-meta {
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
  }
  .step-meta strong {
    font-weight: 600;
    line-height: 1.35;
    color: #f1f5f9;
  }
  .step-meta .mono {
    font-family: ui-monospace, monospace;
    font-size: 0.78rem;
    color: #94a3b8;
  }
  .step-detail {
    margin: 0.1rem 0 0;
    font-size: 0.78rem;
    line-height: 1.35;
    color: #c6d3ee;
  }
  .step-detail.is-live {
    color: #93c5fd;
  }
  .icon-button {
    min-width: 2.4rem;
    font-weight: 700;
    padding-inline: 0.55rem;
  }
</style>
