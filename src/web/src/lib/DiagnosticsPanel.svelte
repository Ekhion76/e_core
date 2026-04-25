<script lang="ts">
  import type { DiagnosticsRun, DiagnosticsStep, DiagnosticsTest } from './diagnostics'

  type Props = {
    diagnosticsRuns: DiagnosticsRun[]
    diagnosticsTests: DiagnosticsTest[]
    selectedRun: DiagnosticsRun | undefined
    selectedTests: string[]
    diagnosticsLoading: boolean
    testsLoading: boolean
    isRunningSelected: boolean
    diagnosticsError: string
    isCancelling: boolean
    onRefreshRuns: () => Promise<void>
    onRunSelectedTests: () => Promise<void>
    onToggleTest: (testKey: string) => void
    onSelectRun: (runId: string) => void
    onCancelSelectedRun: () => Promise<void>
    shouldPoll: (run: DiagnosticsRun | undefined) => boolean
  }

  let {
    diagnosticsRuns,
    diagnosticsTests,
    selectedRun,
    selectedTests,
    diagnosticsLoading,
    testsLoading,
    isRunningSelected,
    diagnosticsError,
    isCancelling,
    onRefreshRuns,
    onRunSelectedTests,
    onToggleTest,
    onSelectRun,
    onCancelSelectedRun,
    shouldPoll
  }: Props = $props()

  function stepStatusLabel(step: DiagnosticsStep): string {
    if (step.status === 'pending') return 'pending'
    if (step.status === 'running') return 'running'
    if (step.status === 'failed') return 'failed'
    return 'passed'
  }
</script>

<div class="diag-grid">
  <div class="card">
    <div class="card-header">
      <h3>Diagnostics Runs</h3>
      <button type="button" class="secondary" onclick={onRefreshRuns} disabled={diagnosticsLoading}>
        {diagnosticsLoading ? 'Loading...' : 'Refresh'}
      </button>
    </div>
    {#if diagnosticsError}
      <p class="error">{diagnosticsError}</p>
    {/if}

    <div class="status-cards">
      <div class="status-card">
        <span>Queued</span>
        <strong>{diagnosticsRuns.filter((run) => run.status === 'queued').length}</strong>
      </div>
      <div class="status-card">
        <span>Running</span>
        <strong>{diagnosticsRuns.filter((run) => run.status === 'running').length}</strong>
      </div>
      <div class="status-card">
        <span>Passed</span>
        <strong>{diagnosticsRuns.filter((run) => run.status === 'passed').length}</strong>
      </div>
      <div class="status-card">
        <span>Failed</span>
        <strong>{diagnosticsRuns.filter((run) => run.status === 'failed').length}</strong>
      </div>
    </div>

    <div class="test-catalog">
      <div class="card-header">
        <h4>Test Catalog</h4>
        <button
          type="button"
          class="secondary"
          onclick={onRunSelectedTests}
          disabled={isRunningSelected || selectedTests.length === 0}
        >
          {isRunningSelected ? 'Starting...' : 'Run selected'}
        </button>
      </div>
      {#if testsLoading}
        <p class="muted">Test lista betoltese...</p>
      {:else}
        <ul class="tests-list">
          {#each diagnosticsTests as test}
            <li>
              <label>
                <input
                  type="checkbox"
                  checked={selectedTests.includes(test.key)}
                  onchange={() => onToggleTest(test.key)}
                />
                <span>
                  <strong>{test.label}</strong>
                  <small>{test.description}</small>
                </span>
              </label>
            </li>
          {/each}
        </ul>
      {/if}
    </div>

    <ul class="run-list">
      {#each diagnosticsRuns as run}
        <li>
          <button
            type="button"
            class:selected={run.runId === selectedRun?.runId}
            onclick={() => onSelectRun(run.runId)}
          >
            <span class="run-main">
              <strong>{run.testKey}</strong>
              <span class="run-id">{run.runId}</span>
            </span>
            <span class={`status status-${run.status}`}>{run.status}</span>
          </button>
        </li>
      {/each}
    </ul>
    {#if diagnosticsRuns.length === 0 && !diagnosticsLoading}
      <p class="muted">Nincs elerheto diagnostics run.</p>
    {/if}
  </div>

  {#if selectedRun}
    <div class="card">
      <div class="card-header">
        <h3>Run Details</h3>
        <button
          type="button"
          class="secondary"
          onclick={onCancelSelectedRun}
          disabled={!shouldPoll(selectedRun) || isCancelling}
        >
          {isCancelling ? 'Cancelling...' : 'Cancel Run'}
        </button>
      </div>
      <div class="kv">
        <span>run_id</span>
        <code>{selectedRun.runId}</code>
      </div>
      <div class="kv">
        <span>status</span>
        <span class={`status status-${selectedRun.status}`}>{selectedRun.status}</span>
      </div>
      <div class="kv">
        <span>started_at</span>
        <span>{selectedRun.startedAt}</span>
      </div>
      <div class="kv">
        <span>duration_ms</span>
        <span>{selectedRun.durationMs}</span>
      </div>
      <p class="summary">{selectedRun.summary}</p>

      <h4>Run Steps</h4>
      {#if selectedRun.steps.length === 0}
        <p class="muted">Ehhez a futashoz nincs step adat.</p>
      {:else}
        <ul class="steps-list">
          {#each selectedRun.steps as step}
            <li>
              <span>{step.label}</span>
              <span class={`status status-${stepStatusLabel(step)}`}>{stepStatusLabel(step)}</span>
            </li>
          {/each}
        </ul>
      {/if}

      <h4>Live Log</h4>
      {#if selectedRun.logs.length === 0}
        <p class="muted">Nincs log bejegyzes.</p>
      {:else}
        <div class="log-panel">
          {#each selectedRun.logs as log}
            <p>
              <span class="log-ts">{log.ts}</span>
              <span class={`log-level log-${log.level}`}>{log.level}</span>
              <span>{log.message}</span>
            </p>
          {/each}
        </div>
      {/if}

      <h4>Recommended Docs</h4>
      {#if selectedRun.docHints.length === 0}
        <p class="muted">Ehhez a futashoz nincs javasolt dokumentacio.</p>
      {:else}
        <ul class="doc-hints">
          {#each selectedRun.docHints as hint}
            <li>
              <div>
                <strong>{hint.title}</strong>
                <p>
                  {#if hint.docUrl}
                    <a href={hint.docUrl} target="_blank" rel="noreferrer">
                      Relevans szekcio megnyitasa
                    </a>
                  {:else}
                    <span class="hint-missing-link">Szekcio link hamarosan elerheto</span>
                  {/if}
                </p>
              </div>
              <span class="meta">
                {hint.severity} · {Math.round(hint.confidence * 100)}%
              </span>
            </li>
          {/each}
        </ul>
      {/if}

      <h4>Result Details</h4>
      {#if selectedRun.resultDetails.length === 0}
        <p class="muted">Ehhez a futashoz nincs result detail adat.</p>
      {:else}
        <ul class="result-details">
          {#each selectedRun.resultDetails as result}
            <li>
              <div class="result-main">
                <strong>{result.key}</strong>
                <p>{result.summary}</p>
              </div>
              <div class="result-meta">
                <span class={`status status-${result.passed ? 'passed' : 'failed'}`}>
                  {result.passed ? 'passed' : 'failed'}
                </span>
                <span>code: {result.code || '-'}</span>
                <span>issues: {result.issueCount}</span>
              </div>
              {#if result.docHints.length > 0}
                <div class="result-hints">
                  <strong>Doc hints</strong>
                  <ul>
                    {#each result.docHints as hint}
                      <li>
                        {#if hint.docUrl}
                          <a href={hint.docUrl} target="_blank" rel="noreferrer">
                            Relevans szekcio megnyitasa
                          </a>
                        {:else}
                          <span class="hint-missing-link">Szekcio link hamarosan elerheto</span>
                        {/if}
                        <small>{Math.round(hint.confidence * 100)}%</small>
                      </li>
                    {/each}
                  </ul>
                </div>
              {/if}
            </li>
          {/each}
        </ul>
      {/if}
    </div>
  {/if}
</div>
