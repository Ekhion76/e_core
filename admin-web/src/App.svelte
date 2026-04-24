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
  import DocumentationPanel from './lib/DocumentationPanel.svelte'
  import ProfessionsPanel from './lib/ProfessionsPanel.svelte'
  import LevelProfilesPanel from './lib/LevelProfilesPanel.svelte'

  type TabId =
    | 'overview'
    | 'diagnostics'
    | 'documentation'
    | 'professions'
    | 'level-profiles'

  type Tab = { id: TabId; label: string }
  const docsHomeUrl =
    (import.meta.env.VITE_DOCS_BASE_URL as string | undefined)?.trim() || 'https://example.github.io/e_core-docs/'

  const tabs: Tab[] = [
    { id: 'overview', label: 'Overview' },
    { id: 'diagnostics', label: 'Diagnostics' },
    { id: 'documentation', label: 'Documentation' },
    { id: 'professions', label: 'Professions' },
    { id: 'level-profiles', label: 'Level Profiles' }
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
      diagnosticsRuns = diagnosticsRuns.map((item) => (item.runId === run.runId ? run : item))
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
</script>

<main class="layout">
  <header class="header">
    <h1>e_core Admin Console</h1>
    <p>Fazis 3.5 MVP kezdovaz - Svelte 5 runes alapon</p>
  </header>

  <nav class="tabs" aria-label="Admin tabs">
    {#each tabs as tab}
      <button
        type="button"
        class:active={tab.id === activeTab}
        onclick={() => selectTab(tab.id)}
      >
        {tab.label}
      </button>
    {/each}
  </nav>

  <section class="panel">
    <h2>{activeTabLabel}</h2>

    {#if activeTab === 'overview'}
      <p>Rendszer allapot, aktiv cleanup jobok es utolso diagnostics futasok helye.</p>
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
    {:else}
      <LevelProfilesPanel />
    {/if}
  </section>
</main>
