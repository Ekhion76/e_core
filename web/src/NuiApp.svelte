<script lang="ts">
  import { onMount } from 'svelte'
  import { postNui } from './lib/nui'
  import { rankData, type LevelRow } from './lib/rankData'
  import AdminConsole from './AdminConsole.svelte'

  type InitPayload = {
    metadata?: Record<string, Record<string, number>>
    levels?: LevelRow[]
    locale?: Record<string, string>
    laborLimit?: number
    abilityLimit?: number
    displayComponent?: {
      statisticsPage?: string[]
      icon?: boolean
      laborHud?: boolean
    }
  }

  type PopupPayload = {
    category: string
    name: string
    baseLevel?: number
    newLevel: number
  }

  let locale = $state<Record<string, string>>({})
  let metadata = $state<Record<string, Record<string, number>>>({})
  let levels = $state<LevelRow[]>([])
  let laborLimit = $state(0)
  let displayComponent = $state({
    statisticsPage: [] as string[],
    icon: false,
    laborHud: false
  })

  let pageOpen = $state(false)
  let hudOpen = $state(false)
  let adminOpen = $state(false)
  let selectedCategory = $state('')
  let popup = $state<PopupPayload | null>(null)
  let popupClear = $state<ReturnType<typeof setTimeout> | null>(null)

  const statColors = [
    '#ec6f86',
    '#4573e7',
    '#d187ef',
    '#fe816d',
    '#7e69ff',
    '#ffba6d',
    '#b2f068',
    '#45b4e7',
    '#ad61ed'
  ]

  function translate(key: string): string {
    return locale[key] ?? key
  }

  function numberFormat(num: number | undefined): string {
    if (num === undefined || num === null || Number.isNaN(Number(num))) {
      return '0'
    }
    return Number(num).toLocaleString('hu-HU')
  }

  function getCssVar(name: string): string {
    if (typeof getComputedStyle === 'undefined') {
      return '#94a3b8'
    }
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim() || '#94a3b8'
  }

  const categories = $derived(
    (displayComponent.statisticsPage ?? []).filter((c) => metadata[c] !== undefined && metadata[c] !== null)
  )

  $effect(() => {
    if (categories.length > 0 && (selectedCategory === '' || !metadata[selectedCategory])) {
      selectedCategory = categories[0]
    }
  })

  function sortedStatEntries(data: Record<string, number>): [string, number, string][] {
    const arr: [string, number, string][] = Object.keys(data).map((key) => [key, data[key], translate(key)])
    arr.sort((a, b) => a[2].localeCompare(b[2], 'hu'))
    return arr
  }

  function statRank(value: number) {
    const r = rankData(value, levels)
    const maxLevel = Math.max(0, levels.length - 1)
    if (!r) {
      return { level: 0, progress: 0, levelClass: 'lvl_0' as string }
    }
    const lvl = r.level === maxLevel ? 'famed' : String(r.level)
    return { level: r.level, progress: r.progress, levelClass: `lvl_${lvl}` }
  }

  function closeStatsPage() {
    pageOpen = false
    postNui('exit')
  }

  function handleMessage(event: MessageEvent) {
    const item = event.data
    if (!item || typeof item !== 'object' || typeof item.action !== 'string') {
      return
    }

    switch (item.action) {
      case 'INIT': {
        locale = (item as InitPayload).locale ?? {}
        metadata = (item as InitPayload).metadata ?? {}
        levels = ((item as InitPayload).levels ?? []) as LevelRow[]
        laborLimit = Number((item as InitPayload).laborLimit) || 0
        displayComponent = {
          statisticsPage: (item as InitPayload).displayComponent?.statisticsPage ?? [],
          icon: (item as InitPayload).displayComponent?.icon === true,
          laborHud: (item as InitPayload).displayComponent?.laborHud === true
        }
        break
      }
      case 'UPDATE': {
        if (item.subject === 'page') {
          metadata = item.metadata ?? {}
        } else if (item.subject === 'hud') {
          metadata = item.metadata ?? {}
        }
        break
      }
      case 'OPEN': {
        if (item.subject === 'page') {
          metadata = item.metadata ?? metadata
          pageOpen = true
        } else if (item.subject === 'hud') {
          hudOpen = true
        }
        break
      }
      case 'CLOSE': {
        if (item.subject === 'page') {
          pageOpen = false
        } else if (item.subject === 'hud') {
          hudOpen = false
        } else if (item.subject === 'all') {
          pageOpen = false
          hudOpen = false
          adminOpen = false
        }
        break
      }
      case 'POPUP': {
        if (popupClear) {
          clearTimeout(popupClear)
        }
        popup = item.data as PopupPayload
        popupClear = setTimeout(() => {
          popup = null
          popupClear = null
        }, 5000)
        break
      }
      case 'WEB_OPEN':
        adminOpen = true
        break
      case 'WEB_CLOSE':
        adminOpen = false
        break
      default:
        break
    }
  }

  onMount(() => {
    window.addEventListener('message', handleMessage)
    postNui('nuiReady')
    return () => {
      window.removeEventListener('message', handleMessage)
      if (popupClear) {
        clearTimeout(popupClear)
      }
    }
  })

  function onKeyup(e: KeyboardEvent) {
    if (e.key !== 'Escape') {
      return
    }
    if (adminOpen) {
      return
    }
    if (pageOpen) {
      closeStatsPage()
    }
  }
</script>

<svelte:window onkeyup={onKeyup} />

<div id="meta_hud" class="nui-hud" style:display={hudOpen ? 'block' : 'none'}>
  <div class="hud_item">
    <div class="hud_info">
      <div class="hud_name" id="labor_hud_name">LABOR</div>
      <div class="hud_point" id="labor_hud_point">{metadata.labor?.val ?? ''}</div>
    </div>
    <div class="hud_bar">
      <span
        class="hud_progress"
        id="labor_hud_progress"
        style:width="{(() => {
          const v = Number(metadata.labor?.val)
          if (!laborLimit || Number.isNaN(v)) {
            return '0%'
          }
          return `${Math.floor((v / laborLimit) * 100)}%`
        })()}"
      ></span>
    </div>
  </div>
</div>

<div id="container" style:display={pageOpen ? 'flex' : 'none'}>
  <div class="wrapper">
    <button type="button" id="close" class="close btn right" onclick={closeStatsPage} aria-label="Close">
      <i class="fa-solid fa-xmark"></i>
    </button>
    <h1 class="center">SKILLS</h1>
    <nav id="meta_categories">
      <ul class="menu" id="meta_categories_menu">
        {#each categories as categoryName}
          <li class:selected={selectedCategory === categoryName}>
            <button
              type="button"
              id="{categoryName}_menu_item"
              class="category_menu_item block_bg_2"
              onclick={() => {
                selectedCategory = categoryName
              }}
            >
              {translate(categoryName)}
            </button>
          </li>
        {/each}
      </ul>
    </nav>
    <div class="content">
      {#each categories as categoryName}
        <section
          id="{categoryName}_section"
          class="category_section"
          style:display={selectedCategory === categoryName ? 'block' : 'none'}
        >
          <h2>{translate(categoryName)}</h2>
          <div id="{categoryName}_section_content">
            <ul class="stats">
              {#each sortedStatEntries(metadata[categoryName] ?? {}) as statData, idx}
                {@const rk = statRank(statData[1])}
                {@const letter = displayComponent.icon ? '' : statData[2].substring(0, 1)}
                {@const bgImage = displayComponent.icon ? `url(img/${statData[0]}.png)` : ''}
                <li class="block_bg_1">
                  <span
                    class="icon"
                    style:background-color={displayComponent.icon ? 'transparent' : statColors[idx % statColors.length]}
                    style:background-image={displayComponent.icon ? bgImage : 'none'}
                    style:background-size={displayComponent.icon ? 'cover' : undefined}
                    style:background-position={displayComponent.icon ? 'center' : undefined}
                  >
                    {#if !displayComponent.icon}{letter}{/if}
                  </span>
                  <span class="data">
                    <span class="name level {rk.levelClass}" id="{statData[0]}_name">{statData[2]}</span>
                    <span class="{statData[0]}_value value">{numberFormat(statData[1])}</span>
                    <span class="bar">
                      <span
                        class="{statData[0]}_progress progress"
                        style:width="{rk.progress}%"
                      ></span>
                    </span>
                  </span>
                </li>
              {/each}
            </ul>
          </div>
        </section>
      {/each}
    </div>
    <div class="footer"></div>
  </div>
</div>

{#if adminOpen}
  <div class="admin-overlay">
    <AdminConsole />
  </div>
{/if}

{#if popup}
  {@const color =
    popup.newLevel === levels.length - 1
      ? getCssVar('--lvl-famed-color')
      : getCssVar(`--lvl-${popup.newLevel}-color`)}
  <div
    class="popup_container"
    id="popup_container"
    style:border-color={color}
    style:box-shadow={`0 0 3rem ${color}`}
  >
    <h1>{translate('level_up')}</h1>
    <h4>{translate(popup.category)}</h4>
    <h2>{translate(popup.name)}</h2>
    <span class="up_level" style:background-color={color}>
      {popup.newLevel === levels.length - 1 ? '⭐' : popup.newLevel}
    </span>
    <span class="level_name" style:color={color}>{translate('level ' + popup.newLevel)}</span>
  </div>
{/if}

<style>
  .admin-overlay {
    position: fixed;
    /* Nem teljes képernyő: ~15% üres sáv minden oldalon */
    inset: 15%;
    z-index: 12000;
    overflow: auto;
    background: rgba(8, 12, 20, 0.92);
    padding: 0.75rem;
    border-radius: 12px;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
    min-height: 0;
    /* CEF / nagy felbontás: +1 gyökér-rem a web konzolon belül */
    /* font-size: 1.0625rem; */
    font-size: 0.6rem;
  }
  .admin-overlay :global(.layout.layout--overlay) {
    width: 100%;
    max-width: none;
    flex: 1;
    min-height: 0;
  }
  .category_menu_item {
    cursor: pointer;
    border: none;
    font: inherit;
    color: inherit;
    width: 100%;
    text-align: left;
  }
  .category_menu_item.selected {
    outline: 2px solid #60a5fa;
  }
  .popup_container {
    position: fixed;
    left: 50%;
    top: 35%;
    transform: translateX(-50%);
    z-index: 15000;
    padding: 1.5rem 2rem;
    border: 3px solid;
    border-radius: 12px;
    background: rgba(15, 23, 42, 0.95);
    text-align: center;
    animation: popIn 0.25s ease;
  }
  @keyframes popIn {
    from {
      opacity: 0;
      transform: translateX(-50%) scale(0.9);
    }
    to {
      opacity: 1;
      transform: translateX(-50%) scale(1);
    }
  }
</style>
