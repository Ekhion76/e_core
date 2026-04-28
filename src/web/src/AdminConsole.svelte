<script lang="ts">
  import {
    cancelDiagnosticsRun,
    getDiagnosticsRun,
    listDiagnosticsRuns,
    listDiagnosticsTests,
    runDiagnosticsTests,
    type DiagnosticsTest,
    type DiagnosticsRun
  } from './lib/diagnostics'
  import DiagnosticsPanel from './lib/DiagnosticsPanel.svelte'
  import IntegrityPanel from './lib/IntegrityPanel.svelte'
  import DocumentationPanel from './lib/DocumentationPanel.svelte'
  import ProfessionsPanel from './lib/ProfessionsPanel.svelte'
  import LevelProfilesPanel from './lib/LevelProfilesPanel.svelte'
  import InventorySamplesPanel from './lib/InventorySamplesPanel.svelte'
  import DeniedAuditPanel from './lib/DeniedAuditPanel.svelte'
  import { postNui } from './lib/nui'

  type TabId =
    | 'overview'
    | 'diagnostics'
    | 'integrity'
    | 'documentation'
    | 'professions'
    | 'level-profiles'
    | 'inventory-samples'
    | 'denied-audit'

  type Tab = { id: TabId; label: string }

  const docsHomeUrl =
    (import.meta.env.VITE_DOCS_BASE_URL as string | undefined)?.trim() || 'https://example.github.io/e_core-docs/'

  const tabs: Tab[] = [
    { id: 'overview', label: 'Overview' },
    { id: 'diagnostics', label: 'Diagnostics' },
    { id: 'integrity', label: 'Integritás' },
    { id: 'documentation', label: 'Documentation' },
    { id: 'professions', label: 'Professions' },
    { id: 'level-profiles', label: 'Level Profiles' },
    { id: 'inventory-samples', label: 'Inventory minta' },
    { id: 'denied-audit', label: 'Denied audit' }
  ]

  let activeTab = $state<TabId>('overview')
  const activeTabLabel = $derived(tabs.find((tab) => tab.id === activeTab)?.label ?? 'Overview')
  let diagnosticsRuns = $state<DiagnosticsRun[]>([])
  let diagnosticsTests = $state<DiagnosticsTest[]>([])
  let selectedTests = $state<string[]>([])
  let diagnosticsLoading = $state<boolean>(false)
  let testsLoading = $state<boolean>(false)
  let isRunningSelected = $state<boolean>(false)
  let diagnosticsError = $state<string>('')
  let isCancelling = $state<boolean>(false)

  let selectedRunId = $state<string>('')
  const selectedRun = $derived(
    diagnosticsRuns.find((run) => run.runId === selectedRunId) ?? diagnosticsRuns[0]
  )

  function selectTab(tabId: TabId) {
    activeTab = tabId
  }

  function selectRun(runId: string) {
    selectedRunId = runId
  }

  function shouldPoll(run: DiagnosticsRun | undefined): boolean {
    return run?.status === 'queued' || run?.status === 'running'
  }

  async function refreshRuns() {
    diagnosticsLoading = true
    diagnosticsError = ''
    try {
      const runs = await listDiagnosticsRuns()
      diagnosticsRuns = runs
      if (!selectedRunId && runs.length > 0) {
        selectedRunId = runs[0].runId
      }
    } catch (error) {
      diagnosticsError = error instanceof Error ? error.message : 'Unknown diagnostics load error'
    } finally {
      diagnosticsLoading = false
    }
  }

  async function refreshTests() {
    testsLoading = true
    diagnosticsError = ''
    try {
      diagnosticsTests = await listDiagnosticsTests()
      if (selectedTests.length === 0 && diagnosticsTests.length > 0) {
        selectedTests = [diagnosticsTests[0].key]
      }
    } catch (error) {
      diagnosticsError = error instanceof Error ? error.message : 'Unknown diagnostics tests load error'
    } finally {
      testsLoading = false
    }
  }

  async function refreshSelectedRun() {
    if (!selectedRunId) {
      return
    }
    try {
      const run = await getDiagnosticsRun(selectedRunId)
      const idx = diagnosticsRuns.findIndex((item) => item.runId === run.runId)
      if (idx >= 0) {
        diagnosticsRuns = diagnosticsRuns.map((item) => (item.runId === run.runId ? run : item))
      } else {
        diagnosticsRuns = [run, ...diagnosticsRuns]
      }
    } catch (error) {
      diagnosticsError = error instanceof Error ? error.message : 'Unknown diagnostics run refresh error'
    }
  }

  async function cancelSelectedRun() {
    if (!selectedRun || !shouldPoll(selectedRun)) {
      return
    }
    isCancelling = true
    diagnosticsError = ''
    try {
      await cancelDiagnosticsRun(selectedRun.runId)
      await refreshSelectedRun()
    } catch (error) {
      diagnosticsError = error instanceof Error ? error.message : 'Cancel failed'
    } finally {
      isCancelling = false
    }
  }

  function toggleTest(testKey: string) {
    if (selectedTests.includes(testKey)) {
      selectedTests = selectedTests.filter((item) => item !== testKey)
      return
    }
    selectedTests = [...selectedTests, testKey]
  }

  async function runSelectedTests() {
    if (selectedTests.length === 0) {
      return
    }
    isRunningSelected = true
    diagnosticsError = ''
    try {
      const { runId } = await runDiagnosticsTests(selectedTests)
      await refreshRuns()
      selectedRunId = runId
      await refreshSelectedRun()
    } catch (error) {
      diagnosticsError = error instanceof Error ? error.message : 'Run selected failed'
    } finally {
      isRunningSelected = false
    }
  }

  $effect(() => {
    if (activeTab !== 'diagnostics') {
      return
    }

    void refreshRuns()
    void refreshTests()
  })

  $effect(() => {
    if (activeTab !== 'diagnostics' || !selectedRunId || !shouldPoll(selectedRun)) {
      return
    }

    const intervalId = setInterval(() => {
      void refreshSelectedRun()
    }, 2500)

    return () => clearInterval(intervalId)
  })

  function closeConsole() {
    postNui('webAdminExit')
  }
</script>

<main class="layout layout--overlay layout--scrollable">
  <header class="header header--with-close">
    <div>
      <h1>e_core Admin</h1>
    </div>
    <button type="button" class="overlay-close" onclick={closeConsole} title="Bezárás">✕</button>
  </header>

  <nav class="tabs" aria-label="Web tabs">
    {#each tabs as tab}
      <button type="button" class:active={tab.id === activeTab} onclick={() => selectTab(tab.id)}>
        {tab.label}
      </button>
    {/each}
  </nav>

  <section class="panel panel--body">
    <h2>{activeTabLabel}</h2>

    {#if activeTab === 'overview'}
      <p>Rendszer állapot, cleanup jobok és diagnostics futások helye.</p>
    {:else if activeTab === 'integrity'}
      <IntegrityPanel />
    {:else if activeTab === 'diagnostics'}
      <DiagnosticsPanel
        diagnosticsRuns={diagnosticsRuns}
        diagnosticsTests={diagnosticsTests}
        selectedRun={selectedRun}
        selectedTests={selectedTests}
        diagnosticsLoading={diagnosticsLoading}
        testsLoading={testsLoading}
        isRunningSelected={isRunningSelected}
        diagnosticsError={diagnosticsError}
        isCancelling={isCancelling}
        onRefreshRuns={refreshRuns}
        onRunSelectedTests={runSelectedTests}
        onToggleTest={toggleTest}
        onSelectRun={selectRun}
        onCancelSelectedRun={cancelSelectedRun}
        shouldPoll={shouldPoll}
      />
    {:else if activeTab === 'documentation'}
      <DocumentationPanel docsHomeUrl={docsHomeUrl} />
    {:else if activeTab === 'professions'}
      <ProfessionsPanel />
    {:else if activeTab === 'inventory-samples'}
      <InventorySamplesPanel />
    {:else if activeTab === 'denied-audit'}
      <DeniedAuditPanel />
    {:else}
      <LevelProfilesPanel />
    {/if}
  </section>
</main>

<style>
  .layout--overlay.layout--scrollable {
    display: flex;
    flex-direction: column;
    min-height: 0;
    max-height: 100%;
    overflow: hidden;
  }
  .layout--overlay {
    max-width: none;
    margin: 0;
    min-height: 100%;
    border-radius: 0;
    border: none;
  }
  :global(.panel.panel--body) {
    flex: 1;
    min-height: 0;
    overflow-y: auto;
    overflow-x: hidden;
  }
  .header--with-close {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 1rem;
  }
  .overlay-close {
    flex-shrink: 0;
    width: 2.25rem;
    height: 2.25rem;
    border-radius: 8px;
    border: 1px solid #31466f;
    background: #182746;
    color: #e2ecff;
    font-size: 1.1rem;
    cursor: pointer;
  }
  .overlay-close:hover {
    border-color: #f87171;
    color: #fecaca;
  }
</style>
