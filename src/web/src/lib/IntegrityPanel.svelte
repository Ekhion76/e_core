<script lang="ts">
  import { onMount, onDestroy } from 'svelte'
  import { postNui } from './nui'

  type RowStatus = 'idle' | 'pending' | 'running' | 'pass' | 'fail' | 'skipped' | 'cancelled'

  type IntegrityStep = { id: string; label: string }

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

  let rowStatus = $state<Record<string, RowStatus>>({})
  let liveHint = $state('')
  let logLines = $state<string[]>([])
  let progressLogLines = $state<string[]>([])

  const displaySteps = $derived(stepsForForm())

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

  function resetInlineUi() {
    liveHint = ''
    logLines = []
    progressLogLines = []
    const next: Record<string, RowStatus> = {}
    for (const s of displaySteps) {
      next[s.id] = 'idle'
    }
    rowStatus = next
  }

  function setRow(id: string, status: RowStatus) {
    rowStatus = { ...rowStatus, [id]: status }
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
        const next: Record<string, RowStatus> = { ...rowStatus }
        for (const it of items) {
          const id = String((it as { id?: string }).id || '')
          if (id) {
            next[id] = 'pending'
          }
        }
        rowStatus = next
        break
      }
      case 'DIAGNOSTICS_CHECKLIST_SET': {
        const id = String(item.id || '')
        const raw = String(item.status || 'pending')
        let ui: RowStatus = 'idle'
        if (raw === 'ok') {
          ui = 'pass'
        } else if (raw === 'fail') {
          ui = 'fail'
        } else if (raw === 'running') {
          ui = 'running'
        } else if (raw === 'skipped') {
          ui = 'skipped'
        } else if (raw === 'cancelled') {
          ui = 'cancelled'
        } else if (raw === 'pending') {
          ui = 'pending'
        }
        if (id) {
          setRow(id, ui)
        }
        break
      }
      case 'DIAGNOSTICS_LIVE_HINT':
        liveHint = String(item.text || '')
        break
      case 'DIAGNOSTICS_LOG_SET': {
        const lines = Array.isArray(item.lines) ? item.lines.map((x: unknown) => String(x)) : []
        logLines = lines
        break
      }
      case 'DIAGNOSTICS_APPEND': {
        const lines = Array.isArray(item.lines) ? item.lines.map((x: unknown) => String(x)) : []
        progressLogLines = lines
        break
      }
      case 'DIAGNOSTICS_INLINE_LOG': {
        const lines = Array.isArray(item.lines) ? item.lines.map((x: unknown) => String(x)) : []
        logLines = [...logLines, ...lines]
        break
      }
      default:
        break
    }
  }

  function runFullIntegrityChecklist(): void {
    fullRunBusy = true
    resetInlineUi()
    postNui('integrityDiagnosticsRun', { opts: buildIntegrityOpts() })
    setTimeout(() => {
      fullRunBusy = false
    }, 800)
  }

  function runSingleStep(stepId: string): void {
    rowBusy = { ...rowBusy, [stepId]: true }
    postNui('integrityDiagnosticsRun', {
      opts: { ...buildIntegrityOpts(), onlyStep: stepId }
    })
    setTimeout(() => {
      rowBusy = { ...rowBusy, [stepId]: false }
    }, 600)
  }

  function statusIcon(id: string): string {
    const s = rowStatus[id] ?? 'idle'
    if (s === 'running') {
      return '…'
    }
    if (s === 'pass') {
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
    return ''
  }

  function iconClass(id: string): string {
    const s = rowStatus[id] ?? 'idle'
    if (s === 'pass') {
      return 'icon-pass'
    }
    if (s === 'fail') {
      return 'icon-fail'
    }
    if (s === 'running') {
      return 'icon-run'
    }
    if (s === 'skipped' || s === 'cancelled') {
      return 'icon-skip'
    }
    if (s === 'pending') {
      return 'icon-pending'
    }
    return 'icon-idle'
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

  let lastStepIds = $state('')

  $effect(() => {
    const k = displaySteps.map((s) => s.id).join(',')
    if (k === lastStepIds) {
      return
    }
    lastStepIds = k
    const next: Record<string, RowStatus> = {}
    for (const s of displaySteps) {
      next[s.id] = rowStatus[s.id] ?? 'idle'
    }
    rowStatus = next
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
          onclick={runFullIntegrityChecklist}
          disabled={fullRunBusy}
          title="Szerver checklist + napló + kliens progress; eredmény a jobb oldalon."
        >
          {fullRunBusy ? 'Indítás…' : 'Összes teszt futtatása'}
        </button>
      </div>
      <p class="muted small">
        A checklist és a szerver napló itt, a jobb oldalon jelenik meg. A progress sáv a játék UI-ban (ox_lib / egyéb)
        látszik a háttérben.
      </p>
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

    <div class="card">
      <h3>Integritás lépések</h3>
      <p class="muted small">Egy lépés futtatása külön (szerver + szükség esetén kliens progress).</p>
      <ul class="step-list">
        {#each displaySteps as step (step.id)}
          <li class="step-row">
            <span class="step-icon {iconClass(step.id)}" aria-hidden="true">{statusIcon(step.id)}</span>
            <div class="step-meta">
              <strong>{step.label}</strong>
              <span class="mono">{step.id}</span>
            </div>
            <button
              type="button"
              class="secondary"
              onclick={() => runSingleStep(step.id)}
              disabled={rowBusy[step.id] === true || fullRunBusy}
            >
              {rowBusy[step.id] ? 'Fut…' : 'Futtatás'}
            </button>
          </li>
        {/each}
      </ul>
    </div>
  </div>

  <div class="integrity-col integrity-col--right">
    <div class="card log-card">
      <h3>Eredmény napló</h3>
      {#if liveHint.trim()}
        <div class="hint-strip">{liveHint}</div>
      {/if}
      <div class="log-scroll" role="log" aria-live="polite">
        {#if logLines.length === 0 && progressLogLines.length === 0}
          <p class="muted small">Indítás után itt jelennek meg a szerver sorok és a progress összefoglaló.</p>
        {:else}
          {#each logLines as line}
            <div class="log-line {lineTone(line)}">{line}</div>
          {/each}
          {#if progressLogLines.length > 0}
            <div class="log-subhead">Kliens progress</div>
            {#each progressLogLines as line}
              <div class="log-line log-line--prog {lineTone(line)}">{line}</div>
            {/each}
          {/if}
        {/if}
      </div>
    </div>
  </div>
</div>

<style>
  .integrity-layout {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(280px, 0.95fr);
    gap: 1rem;
    align-items: stretch;
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
  }
  .log-card {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-height: 12rem;
    max-height: min(70vh, 42rem);
  }
  .hint-strip {
    margin: 0 0 0.5rem;
    padding: 0.45rem 0.6rem;
    border-radius: 8px;
    background: #1e3a5f;
    border: 1px solid #334e7a;
    color: #dbeafe;
    font-size: 0.9rem;
  }
  .log-scroll {
    flex: 1;
    min-height: 0;
    overflow-y: auto;
    padding: 0.35rem 0.15rem 0.35rem 0;
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
  .log-line--prog {
    color: #a5c4e8;
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
  .log-subhead {
    margin: 0.75rem 0 0.25rem;
    font-weight: 700;
    color: #93c5fd;
    font-size: 0.78rem;
    text-transform: uppercase;
    letter-spacing: 0.04em;
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
    color: #9fb2d8;
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
  .step-icon {
    width: 1.75rem;
    text-align: center;
    font-size: 1.2rem;
    font-weight: 800;
  }
  .icon-pass {
    color: #4ade80;
  }
  .icon-fail {
    color: #f87171;
  }
  .icon-run {
    color: #fbbf24;
  }
  .icon-skip {
    color: #94a3b8;
  }
  .icon-idle {
    color: #475569;
  }
  .icon-pending {
    color: #64748b;
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
</style>
