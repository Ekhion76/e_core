<script lang="ts">
  import { adminGetInventorySamples, type InventorySamplesData } from './registry'

  /** Pretty-print a JSON line from the server (`json.encode` is usually compact). */
  function formatInventoryJson(raw: string): string {
    const s = String(raw ?? '').trim()
    if (!s) return ''
    try {
      return JSON.stringify(JSON.parse(s), null, 2)
    } catch {
      return s
    }
  }

  /** `type="number"` bind can coerce to `number` — always normalise before `.trim()`. */
  let targetSource = $state<string | number>('')
  let loading = $state(false)
  let error = $state('')
  let hint = $state('')
  let result = $state<InventorySamplesData | null>(null)

  async function loadSamples() {
    loading = true
    error = ''
    hint = ''
    try {
      const ts = String(targetSource ?? '').trim()
      let opt: { targetSource?: number } | undefined
      if (ts !== '') {
        const num = Math.floor(Number(ts))
        if (!Number.isFinite(num) || num < 1) {
          throw new Error('A targetSource legyen pozitív egész szám vagy üres (saját játékos).')
        }
        opt = { targetSource: num }
      }
      const { message, data } = await adminGetInventorySamples(opt)
      result = data
      hint = message ?? ''
    } catch (e) {
      result = null
      error = e instanceof Error ? e.message : 'Ismeretlen hiba'
    } finally {
      loading = false
    }
  }
</script>

<div class="inv-grid">
  <div class="card">
    <div class="card-header">
      <h3>Inventory minta (Config.fields)</h3>
      <button type="button" class="secondary" onclick={loadSamples} disabled={loading}>
        {loading ? 'Betöltés…' : 'Frissítés'}
      </button>
    </div>

    <p class="muted">
      A szerver a <code>eCore:getInventory(target)</code> listából legfeljebb <strong>3</strong> sort ad vissza. A kulcsok
      alapján állítsd be az <code>overrides/**/config.lua</code> <code>Config.fields</code> mezőt. Ha az
      <code>ox_inventory</code> resource fut, a panel külön blokkban a nyers ox slotmintákat is megjeleníti.
    </p>

    <label class="field">
      <span>targetSource (üres = saját)</span>
      <input type="number" min="1" bind:value={targetSource} placeholder="pl. 12" />
    </label>

    {#if error}
      <p class="error">{error}</p>
    {/if}
    {#if hint}
      <p class="hint">{hint}</p>
    {/if}
  </div>

  {#if result}
    <div class="card">
      <h4>Összegzés</h4>
      <ul class="meta-list">
        <li><strong>framework</strong>: {result.framework ?? '—'}</li>
        <li><strong>targetSource</strong>: {result.targetSource}</li>
        <li><strong>ecoreInitFailed</strong>: {String(result.ecoreInitFailed)}</li>
      </ul>
    </div>

    <div class="card">
      <h4>Bridge — eCore:getInventory</h4>
      <p class="muted">
        topLevelKeys (max 48): <code>{result.bridge.topLevelKeys.join(', ') || '—'}</code><br />
        becsült sor / kulcs: <strong>{result.bridge.rowEstimate}</strong> · minták:
        <strong>{result.bridge.sampleCount}</strong>
      </p>
      {#if result.bridge.sampleCount === 0}
        <p class="muted">Nincs felismert item-sor (név / item string + opcionális darab).</p>
      {:else}
        {#each result.bridge.sampleJson as block, i}
          <details open={i === 0}>
            <summary>Minta #{i + 1} (bridge)</summary>
            <pre class="dump">{formatInventoryJson(block)}</pre>
          </details>
        {/each}
      {/if}
    </div>

    {#if result.oxInventory.resourceStarted}
      <div class="card">
        <h4>ox_inventory — nyers slotok</h4>
        <p class="muted">
          Minták: <strong>{result.oxInventory.sampleCount}</strong>
          {#if result.oxInventory.inventoryMeta}
            · meta: weight={result.oxInventory.inventoryMeta.weight ?? '—'}, maxWeight={result.oxInventory.inventoryMeta
              .maxWeight ?? '—'}, slots={result.oxInventory.inventoryMeta.slots ?? '—'}
          {/if}
        </p>
        {#if result.oxInventory.sampleCount === 0}
          <p class="muted">Nincs felismert slot-sor (üres items vagy más hiba).</p>
        {:else}
          {#each result.oxInventory.sampleJson as block, i}
            <details open={i === 0}>
              <summary>Minta #{i + 1} (ox)</summary>
              <pre class="dump">{formatInventoryJson(block)}</pre>
            </details>
          {/each}
        {/if}
      </div>
    {/if}
  {/if}
</div>

<style>
  .inv-grid {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
  .field {
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
    margin-top: 0.75rem;
    max-width: 16rem;
  }
  .field input {
    padding: 0.45rem 0.6rem;
    border-radius: 6px;
    border: 1px solid #31466f;
    background: #0f172a;
    color: #e2ecff;
  }
  .muted {
    color: #9fb2d8;
    font-size: 0.9rem;
    line-height: 1.45;
  }
  .muted code {
    font-size: 0.85em;
    padding: 0.1em 0.35em;
    border-radius: 4px;
    background: #182746;
  }
  .error {
    color: #fecaca;
    margin-top: 0.5rem;
  }
  .hint {
    color: #a7f3d0;
    margin-top: 0.5rem;
    font-size: 0.9rem;
  }
  .meta-list {
    margin: 0;
    padding-left: 1.2rem;
    color: #e2ecff;
  }
  details {
    margin-top: 0.75rem;
    border: 1px solid #31466f;
    border-radius: 8px;
    padding: 0.5rem 0.75rem;
    background: #0b1220;
  }
  summary {
    cursor: pointer;
    font-weight: 600;
    color: #cbd5f5;
  }
  .dump {
    margin: 0.5rem 0 0;
    padding: 0.65rem 0.75rem;
    overflow-x: auto;
    max-height: 22rem;
    overflow-y: auto;
    font-size: 0.78rem;
    line-height: 1.35;
    background: #020617;
    border-radius: 6px;
    border: 1px solid #1e293b;
    color: #e2e8f0;
    white-space: pre-wrap;
    word-break: break-word;
  }
</style>
