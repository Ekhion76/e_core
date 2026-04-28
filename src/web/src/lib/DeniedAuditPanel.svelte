<script lang="ts">
  import {
    getDeniedAuditConfig,
    listDeniedAudit,
    purgeDeniedAudit,
    type DeniedAuditItem,
    type DeniedAuditStorage
  } from './registry'

  let storage = $state<DeniedAuditStorage>('mysql')
  let enabled = $state(true)
  let configLoading = $state(true)
  let configError = $state('')

  let sectionFilter = $state('')
  let actionFilter = $state('')
  let limit = $state(20)
  let offset = $state(0)
  let total = $state(0)
  let items = $state<DeniedAuditItem[]>([])
  let listLoading = $state(false)
  let listError = $state('')
  let dataSource = $state<string | undefined>(undefined)

  let purgeBusy = $state(false)
  let purgeMessage = $state('')

  async function loadConfig() {
    configLoading = true
    configError = ''
    try {
      const c = await getDeniedAuditConfig()
      storage = c.storage
      enabled = c.enabled
    } catch (e) {
      configError = e instanceof Error ? e.message : 'Config hiba'
    } finally {
      configLoading = false
    }
  }

  async function loadList() {
    if (!enabled) {
      items = []
      total = 0
      return
    }
    listLoading = true
    listError = ''
    try {
      const res = await listDeniedAudit({
        section: sectionFilter.trim() || undefined,
        action: actionFilter.trim() || undefined,
        limit,
        offset
      })
      items = res.items
      total = res.total
      dataSource = res.dataSource
    } catch (e) {
      items = []
      total = 0
      listError = e instanceof Error ? e.message : 'Lista hiba'
    } finally {
      listLoading = false
    }
  }

  async function runPurgeDryRun() {
    if (storage !== 'mysql') {
      purgeMessage = 'Purge csak storage=mysql mellett érhető el.'
      return
    }
    purgeBusy = true
    purgeMessage = ''
    try {
      const r = await purgeDeniedAudit(true)
      purgeMessage = `Dry-run: ${r.wouldDelete ?? 0} sor törölhető (retention: ${r.retentionDays ?? '—'} nap).`
    } catch (e) {
      purgeMessage = e instanceof Error ? e.message : 'Purge dry-run hiba'
    } finally {
      purgeBusy = false
    }
  }

  async function runPurge() {
    if (storage !== 'mysql') {
      purgeMessage = 'Purge csak storage=mysql mellett érhető el.'
      return
    }
    if (!confirm('Biztosan futtatod a retention purge-ot? (MySQL: régi sorok törlése)')) {
      return
    }
    purgeBusy = true
    purgeMessage = ''
    try {
      const r = await purgeDeniedAudit(false)
      purgeMessage = `Purge kész: ${r.deleted ?? 0} sor törölve.`
      await loadList()
    } catch (e) {
      purgeMessage = e instanceof Error ? e.message : 'Purge hiba'
    } finally {
      purgeBusy = false
    }
  }

  function prevPage() {
    offset = Math.max(0, offset - limit)
    void loadList()
  }

  function nextPage() {
    if (offset + limit < total) {
      offset = offset + limit
      void loadList()
    }
  }

  $effect(() => {
    void loadConfig()
  })

  $effect(() => {
    if (configLoading || !enabled) {
      return
    }
    void loadList()
  })
</script>

<div class="denied-wrap">
  <div class="card">
    <div class="card-header">
      <h3>Denied audit (operátor jog)</h3>
      <button type="button" class="secondary" onclick={() => loadConfig()} disabled={configLoading}>
        {configLoading ? '…' : 'Config frissítés'}
      </button>
    </div>

    {#if configError}
      <p class="error">{configError}</p>
    {/if}

    {#if !configLoading && !configError}
      <p class="muted">
        <strong>storage</strong>: {storage}. <code>mysql</code>: tábla + lapozás + retention purge.
        <code>discord</code>: új sorok webhookra; lista a szerver memóriájából (rövid ablak, max. ~200).
      </p>
      {#if !enabled}
        <p class="hint">A denied audit ki van kapcsolva a configban.</p>
      {/if}
    {/if}
  </div>

  {#if enabled && !configLoading}
    <div class="card">
      <div class="row">
        <label class="field">
          <span>Section szűrő</span>
          <input type="text" bind:value={sectionFilter} placeholder="pl. cleanup" />
        </label>
        <label class="field">
          <span>Action szűrő</span>
          <input type="text" bind:value={actionFilter} placeholder="opcionális" />
        </label>
      </div>
      <div class="btn-row">
        <button
          type="button"
          onclick={() => {
            offset = 0
            void loadList()
          }}
          disabled={listLoading}>Szűrés / első oldal</button>
        <button type="button" class="secondary" onclick={() => loadList()} disabled={listLoading}>
          {listLoading ? 'Betöltés…' : 'Frissítés'}
        </button>
        <button type="button" class="secondary" onclick={prevPage} disabled={listLoading || offset <= 0}>Előző</button>
        <button
          type="button"
          class="secondary"
          onclick={nextPage}
          disabled={listLoading || offset + limit >= total}>Következő</button>
      </div>
      {#if dataSource}
        <p class="hint">Adatforrás: {dataSource} · összesen: {total} · offset: {offset}</p>
      {/if}
      {#if listError}
        <p class="error">{listError}</p>
      {/if}
      <table class="tbl">
        <thead>
          <tr>
            <th>id</th>
            <th>ts</th>
            <th>section</th>
            <th>action</th>
            <th>source</th>
            <th>reason</th>
          </tr>
        </thead>
        <tbody>
          {#each items as row}
            <tr>
              <td>{row.id ?? '—'}</td>
              <td class="mono">{String(row.ts ?? '—')}</td>
              <td>{row.section}</td>
              <td>{row.action}</td>
              <td>{row.source ?? '—'}</td>
              <td class="mono">{row.reason}</td>
            </tr>
          {/each}
        </tbody>
      </table>

      {#if storage === 'mysql'}
        <div class="btn-row">
          <button type="button" class="secondary" onclick={runPurgeDryRun} disabled={purgeBusy}>Purge dry-run</button>
          <button type="button" class="danger" onclick={runPurge} disabled={purgeBusy}>Purge (régi sorok)</button>
        </div>
        {#if purgeMessage}
          <p class="hint">{purgeMessage}</p>
        {/if}
      {/if}
    </div>
  {/if}
</div>

<style>
  .denied-wrap {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
  .card {
    border: 1px solid #31466f;
    border-radius: 10px;
    padding: 1rem 1.1rem;
    background: #0f1a33;
  }
  .card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
    margin-bottom: 0.75rem;
  }
  .card h3 {
    margin: 0;
    font-size: 1.05rem;
  }
  .muted {
    color: #9cb0d0;
    font-size: 0.9rem;
    line-height: 1.45;
  }
  .hint {
    color: #a7c4ff;
    font-size: 0.9rem;
  }
  .error {
    color: #fecaca;
    font-size: 0.9rem;
  }
  .row {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    margin-bottom: 0.75rem;
  }
  .field {
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
    min-width: 12rem;
  }
  .field input {
    padding: 0.45rem 0.55rem;
    border-radius: 6px;
    border: 1px solid #31466f;
    background: #182746;
    color: #e2ecff;
  }
  .btn-row {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin: 0.75rem 0;
  }
  button {
    padding: 0.45rem 0.75rem;
    border-radius: 6px;
    border: 1px solid #3b5a8a;
    background: #1e3a66;
    color: #e2ecff;
    cursor: pointer;
  }
  button.secondary {
    border-color: #31466f;
    background: #15294a;
  }
  button.danger {
    border-color: #b45353;
    background: #5c2626;
  }
  button:disabled {
    opacity: 0.55;
    cursor: not-allowed;
  }
  .tbl {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.85rem;
    margin-top: 0.5rem;
  }
  .tbl th,
  .tbl td {
    border-bottom: 1px solid #273a5c;
    padding: 0.4rem 0.35rem;
    text-align: left;
    vertical-align: top;
  }
  .tbl th {
    color: #9cb0d0;
    font-weight: 600;
  }
  .mono {
    font-family: ui-monospace, monospace;
    word-break: break-word;
  }
</style>
