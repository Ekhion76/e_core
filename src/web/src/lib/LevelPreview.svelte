<script lang="ts">
  import {
    LEVEL_MODIFIER_KEYS,
    formatLevelCell,
    shouldRenderLevelTable,
    toLevelEntries
  } from './levelPreview'

  let { levels, title = 'Level preview', previewLimit = 8 } = $props<{
    levels: unknown
    title?: string
    previewLimit?: number
  }>()

  const entries = $derived(toLevelEntries(levels))
  const useTable = $derived(shouldRenderLevelTable(entries))
  let showAll = $state(false)

  const visible = $derived(showAll ? entries : entries.slice(0, previewLimit))
  const overflow = $derived(Math.max(0, entries.length - previewLimit))
</script>

{#if entries.length > 0}
  <div class="levels-preview">
    <div class="levels-preview-header">
      <h4>{title}</h4>
      {#if overflow > 0}
        {#if !showAll}
          <button type="button" class="secondary small-btn" onclick={() => (showAll = true)}>
            Osszes level ({entries.length} sor)
          </button>
        {:else}
          <button type="button" class="secondary small-btn" onclick={() => (showAll = false)}>
            Csak elso {previewLimit} sor
          </button>
        {/if}
      {/if}
    </div>

    {#if useTable}
      <div class="levels-table-wrap">
        <table class="levels-table">
          <thead>
            <tr>
              <th>#</th>
              <th>limit</th>
              {#each LEVEL_MODIFIER_KEYS as k}
                <th>{k}</th>
              {/each}
            </tr>
          </thead>
          <tbody>
            {#each visible as level}
              <tr>
                <td>{level.key}</td>
                <td>{formatLevelCell(level.value as Record<string, unknown>, 'limit')}</td>
                {#each LEVEL_MODIFIER_KEYS as k}
                  <td>{formatLevelCell(level.value as Record<string, unknown>, k)}</td>
                {/each}
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    {:else}
      <ul>
        {#each visible as level}
          <li>
            <span class="level-key">#{level.key}</span>
            <code>{JSON.stringify(level.value)}</code>
          </li>
        {/each}
      </ul>
    {/if}
  </div>
{/if}
