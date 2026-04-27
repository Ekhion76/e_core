<script lang="ts">
  import { postNui } from './nui'

  export type HudAnchor = 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' | 'center'
  export type HudPos = { x: number; y: number; w: number; h: number; anchor: HudAnchor }
  export type HudElement = { id: string; label: string; pos: HudPos }

  let {
    active = false,
    elements = [] as HudElement[]
  } = $props<{ active: boolean; elements: HudElement[] }>()

  let draggingId = $state<string | null>(null)
  let dragOffset = $state({ x: 0, y: 0 })
  let localPositions = $state<Record<string, HudPos>>({})
  let rafPreview = $state<number | null>(null)

  function clamp01(v: number): number {
    if (v < 0) return 0
    if (v > 1) return 1
    return v
  }

  function cssByAnchor(anchor: HudAnchor): string {
    if (anchor === 'top-right') return 'right:0;top:0;'
    if (anchor === 'bottom-left') return 'left:0;bottom:0;'
    if (anchor === 'bottom-right') return 'right:0;bottom:0;'
    if (anchor === 'center') return 'left:50%;top:50%;'
    return 'left:0;top:0;'
  }

  function toElementStyle(pos: HudPos): string {
    const x = `${(pos.x * 100).toFixed(3)}%`
    const y = `${(pos.y * 100).toFixed(3)}%`
    const w = `${(pos.w * 100).toFixed(3)}%`
    const h = `${(pos.h * 100).toFixed(3)}%`
    if (pos.anchor === 'center') {
      return `${cssByAnchor(pos.anchor)}width:${w};height:${h};transform:translate(calc(-50% + ${x}), calc(-50% + ${y}));`
    }
    if (pos.anchor === 'top-right') {
      return `${cssByAnchor(pos.anchor)}width:${w};height:${h};transform:translate(calc(-1 * ${x}), ${y});`
    }
    if (pos.anchor === 'bottom-left') {
      return `${cssByAnchor(pos.anchor)}width:${w};height:${h};transform:translate(${x}, calc(-1 * ${y}));`
    }
    if (pos.anchor === 'bottom-right') {
      return `${cssByAnchor(pos.anchor)}width:${w};height:${h};transform:translate(calc(-1 * ${x}), calc(-1 * ${y}));`
    }
    return `${cssByAnchor(pos.anchor)}width:${w};height:${h};transform:translate(${x}, ${y});`
  }

  function schedulePreview(id: string, pos: HudPos): void {
    if (rafPreview !== null) {
      cancelAnimationFrame(rafPreview)
    }
    rafPreview = requestAnimationFrame(() => {
      postNui('hudPreview', { id, pos })
      rafPreview = null
    })
  }

  function startDrag(e: MouseEvent, item: HudElement): void {
    if (!active) return
    draggingId = item.id
    dragOffset = { x: e.clientX / window.innerWidth - item.pos.x, y: e.clientY / window.innerHeight - item.pos.y }
    e.preventDefault()
  }

  function stopDrag(): void {
    draggingId = null
  }

  function updateDrag(e: MouseEvent): void {
    if (!draggingId || !active) return
    const current = localPositions[draggingId] ?? elements.find((it) => it.id === draggingId)?.pos
    if (!current) return
    const next: HudPos = {
      ...current,
      x: clamp01(e.clientX / window.innerWidth - dragOffset.x),
      y: clamp01(e.clientY / window.innerHeight - dragOffset.y)
    }
    localPositions = { ...localPositions, [draggingId]: next }
    schedulePreview(draggingId, next)
  }

  function commitAndClose(): void {
    const elementsPayload: Record<string, HudPos> = {}
    for (const item of elements) {
      elementsPayload[item.id] = localPositions[item.id] ?? item.pos
    }
    postNui('hudCommit', { v: 1, elements: elementsPayload })
  }

  function cancelEdit(): void {
    postNui('hudEditExit')
  }

  $effect(() => {
    const next: Record<string, HudPos> = {}
    for (const item of elements) {
      next[item.id] = item.pos
    }
    localPositions = next
  })
</script>

<svelte:window onmousemove={updateDrag} onmouseup={stopDrag} />

<div class="hud-edit-overlay" data-active={active}>
  <div class="hud-edit-ghost-layer">
    {#if active}
      {#each elements as item (item.id)}
        {@const p = localPositions[item.id] ?? item.pos}
        <button class="hud-ghost-box" style={toElementStyle(p)} onmousedown={(e) => startDrag(e, item)}>
          <span>{item.label}</span>
        </button>
      {/each}
      <div class="hud-edit-toolbar">
        <button type="button" onclick={commitAndClose}>Mentés</button>
        <button type="button" class="secondary" onclick={cancelEdit}>Mégse</button>
      </div>
    {/if}
  </div>
</div>

<style>
  .hud-edit-overlay {
    position: fixed;
    inset: 0;
    pointer-events: none;
    z-index: 9999;
  }
  .hud-edit-overlay[data-active='true'] .hud-edit-ghost-layer {
    pointer-events: all;
  }
  .hud-edit-ghost-layer {
    position: absolute;
    inset: 0;
    pointer-events: none;
  }
  .hud-ghost-box {
    position: absolute;
    border: 1px dashed #93c5fd;
    background: #1e3a8a33;
    color: #dbeafe;
    cursor: move;
    user-select: none;
    display: inline-flex;
    align-items: center;
    justify-content: center;
  }
  .hud-edit-toolbar {
    position: absolute;
    right: 1rem;
    top: 1rem;
    display: flex;
    gap: 0.5rem;
    pointer-events: all;
  }
  .hud-edit-toolbar button {
    border: 1px solid #3b82f6;
    background: #1e40af;
    color: #eff6ff;
    border-radius: 6px;
    padding: 0.35rem 0.6rem;
    cursor: pointer;
  }
  .hud-edit-toolbar button.secondary {
    border-color: #64748b;
    background: #334155;
  }
</style>

