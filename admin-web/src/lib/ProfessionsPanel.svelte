<script lang="ts">
  import { FLASH_SUCCESS_MS } from './adminFormHelpers'
  import LevelPreview from './LevelPreview.svelte'
  import {
    createProfession,
    deleteProfession,
    getProfessionDefaults,
    getProfessionProfile,
    listProfessions,
    updateProfession,
    validateProfessionKeys,
    type ProfessionDefaultsResult,
    type ProfessionProfileResult,
    type ProfessionItem,
    type ProfessionValidateResult
  } from './registry'

  let professionItems = $state<ProfessionItem[]>([])
  let loading = $state<boolean>(false)
  let error = $state<string>('')
  let search = $state<string>('')
  let actionCategory = $state<string>('')
  let validateKeysInput = $state<string>('')
  let actionLoading = $state<boolean>(false)
  let actionError = $state<string>('')
  let defaultsResult = $state<ProfessionDefaultsResult | null>(null)
  let validationResult = $state<ProfessionValidateResult | null>(null)
  let profileResult = $state<ProfessionProfileResult | null>(null)

  let crudLoading = $state<boolean>(false)
  let crudError = $state<string>('')
  /** CRUD + defaults / validate / profile — egy közös siker-szalag. */
  let panelSuccess = $state<string>('')
  let flashTimer: ReturnType<typeof setTimeout> | undefined
  let actionFieldErrors = $state<Record<string, string>>({})
  let newFieldErrors = $state<Record<string, string>>({})
  let editFieldErrors = $state<Record<string, string>>({})
  let newCategory = $state<string>('')
  let newName = $state<string>('')
  let newDisplayName = $state<string>('')
  let newProfileKey = $state<string>('')
  let newEnabled = $state<boolean>(true)
  let newMaxCap = $state<string>('')
  let editItem = $state<ProfessionItem | null>(null)
  let editDisplayName = $state<string>('')
  let editEnabled = $state<boolean>(true)
  let editProfileKey = $state<string>('')
  let editMaxCap = $state<string>('')

  const normalizedSearch = $derived(search.trim().toLowerCase())
  const filteredItems = $derived(
    normalizedSearch.length === 0
      ? professionItems
      : professionItems.filter((item) => {
          const haystack = `${item.displayName} ${item.category}.${item.name} ${item.profileKey}`.toLowerCase()
          return haystack.includes(normalizedSearch)
        })
  )
  const enabledCount = $derived(filteredItems.filter((item) => item.enabled).length)
  const disabledCount = $derived(filteredItems.length - enabledCount)
  const categoryOptions = $derived(Array.from(new Set(professionItems.map((item) => item.category))).sort())
  const profileKeyHints = $derived(
    Array.from(new Set(professionItems.map((i) => i.profileKey).filter(Boolean))).sort()
  )

  function flashOk(msg: string) {
    panelSuccess = msg
    crudError = ''
    actionError = ''
    if (flashTimer) {
      clearTimeout(flashTimer)
    }
    flashTimer = setTimeout(() => {
      panelSuccess = ''
      flashTimer = undefined
    }, FLASH_SUCCESS_MS)
  }

  function validateNewProfessionForm(): boolean {
    const e: Record<string, string> = {}
    if (!newCategory.trim()) {
      e.category = 'A kategória kötelező.'
    }
    if (!newName.trim()) {
      e.name = 'A profession kulcs (name) kötelező.'
    }
    if (!newProfileKey.trim()) {
      e.profileKey = 'A level profile key kötelező.'
    }
    const cap = newMaxCap.trim()
    if (cap !== '') {
      const n = Number(cap)
      if (!Number.isFinite(n) || n < 0) {
        e.maxProficiency = 'Szám ≥ 0, vagy üresen hagyva nincs plafon.'
      }
    }
    newFieldErrors = e
    return Object.keys(e).length === 0
  }

  function validateEditProfessionForm(): boolean {
    const e: Record<string, string> = {}
    if (!editDisplayName.trim()) {
      e.displayName = 'A megjelenített név nem lehet üres.'
    }
    if (!editProfileKey.trim()) {
      e.profileKey = 'A level profile key kötelező.'
    }
    const cap = editMaxCap.trim()
    if (cap !== '') {
      const n = Number(cap)
      if (!Number.isFinite(n) || n < 0) {
        e.maxProficiency = 'Szám ≥ 0, vagy üres a plafon törléséhez.'
      }
    }
    editFieldErrors = e
    return Object.keys(e).length === 0
  }
  async function refresh() {
    loading = true
    error = ''
    try {
      professionItems = await listProfessions()
      if (!actionCategory && professionItems.length > 0) {
        actionCategory = professionItems[0].category
      }
    } catch (err) {
      error = err instanceof Error ? err.message : 'Profession lista betoltese sikertelen.'
    } finally {
      loading = false
    }
  }

  $effect(() => {
    void refresh()
  })

  $effect(() => {
    if (editItem) {
      editDisplayName = editItem.displayName
      editEnabled = editItem.enabled
      editProfileKey = editItem.profileKey
      editMaxCap = editItem.maxProficiency == null ? '' : String(editItem.maxProficiency)
    }
  })

  function clearCrudError() {
    crudError = ''
  }

  function beginEdit(item: ProfessionItem) {
    clearCrudError()
    editFieldErrors = {}
    editItem = item
  }

  function cancelEdit() {
    editItem = null
    editFieldErrors = {}
  }

  async function onCreateProfession() {
    if (!validateNewProfessionForm()) {
      return
    }
    crudLoading = true
    crudError = ''
    const max =
      newMaxCap.trim() === ''
        ? null
        : (() => {
            const n = Number(newMaxCap)
            return Number.isFinite(n) ? n : null
          })()
    try {
      await createProfession({
        category: newCategory.trim(),
        name: newName.trim(),
        displayName: newDisplayName.trim() || newName.trim(),
        profileKey: newProfileKey.trim(),
        enabled: newEnabled,
        maxProficiency: max
      })
      newName = ''
      newDisplayName = ''
      newMaxCap = ''
      newFieldErrors = {}
      await refresh()
      flashOk('Profession létrehozva.')
    } catch (err) {
      crudError = err instanceof Error ? err.message : 'Letrehozas sikertelen.'
    } finally {
      crudLoading = false
    }
  }

  async function onUpdateProfession() {
    if (!editItem) {
      return
    }
    if (!validateEditProfessionForm()) {
      return
    }
    crudLoading = true
    crudError = ''
    const maxStr = editMaxCap.trim()
    try {
      await updateProfession(editItem.category, editItem.name, {
        displayName: editDisplayName.trim(),
        enabled: editEnabled,
        profileKey: editProfileKey.trim(),
        maxProficiency: maxStr === '' ? false : Number(maxStr)
      })
      editItem = null
      editFieldErrors = {}
      await refresh()
      flashOk('Profession frissítve.')
    } catch (err) {
      crudError = err instanceof Error ? err.message : 'Frissites sikertelen.'
    } finally {
      crudLoading = false
    }
  }

  async function onDeleteProfession() {
    if (!editItem) {
      return
    }
    if (!window.confirm(`Torolni: ${editItem.category}.${editItem.name} ?`)) {
      return
    }
    crudLoading = true
    crudError = ''
    try {
      await deleteProfession(editItem.category, editItem.name)
      editItem = null
      editFieldErrors = {}
      await refresh()
      flashOk('Profession törölve.')
    } catch (err) {
      crudError = err instanceof Error ? err.message : 'Torles sikertelen.'
    } finally {
      crudLoading = false
    }
  }

  function parseKeysInput(input: string): string[] {
    return input
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean)
  }

  async function runLoadDefaults() {
    actionFieldErrors = {}
    if (!actionCategory.trim()) {
      actionFieldErrors = { category: 'Válassz kategóriát a defaults lekéréshez.' }
      actionError = ''
      return
    }
    actionLoading = true
    actionError = ''
    defaultsResult = null
    try {
      defaultsResult = await getProfessionDefaults(actionCategory)
      const n = Object.keys(defaultsResult.defaults).length
      flashOk(`Defaults lekérve: ${n} kulcs a(z) «${defaultsResult.category}» kategóriában.`)
    } catch (err) {
      actionError = err instanceof Error ? err.message : 'A defaults lekérése sikertelen.'
    } finally {
      actionLoading = false
    }
  }

  async function runValidateKeys() {
    actionFieldErrors = {}
    if (!actionCategory.trim()) {
      actionFieldErrors = { category: 'Válassz kategóriát a validációhoz.' }
      actionError = ''
      return
    }
    const keys = parseKeysInput(validateKeysInput)
    if (keys.length === 0) {
      actionFieldErrors = { keys: 'Adj meg legalább egy profession kulcsot (vesszővel elválasztva).' }
      actionError = ''
      return
    }
    actionLoading = true
    actionError = ''
    validationResult = null
    try {
      validationResult = await validateProfessionKeys(actionCategory, keys)
      const v = validationResult
      flashOk(
        `Kulcsok ellenőrizve (${keys.length} bemenet): ${v.valid.length} rendben, ${v.invalid.length} érvénytelen, ${v.missingProfile.length} hiányzó profile.`
      )
    } catch (err) {
      actionError = err instanceof Error ? err.message : 'A kulcsvalidáció sikertelen.'
    } finally {
      actionLoading = false
    }
  }

  async function runLoadProfile(category: string, name: string) {
    actionLoading = true
    actionError = ''
    profileResult = null
    try {
      const pr = await getProfessionProfile(category, name)
      profileResult = pr
      flashOk(`Profile betöltve: ${pr.category}.${pr.name}`)
    } catch (err) {
      actionError = err instanceof Error ? err.message : 'A profile lekérése sikertelen.'
    } finally {
      actionLoading = false
    }
  }

  $effect(() => {
    if (actionCategory.trim() && actionFieldErrors.category) {
      const { category: _c, ...rest } = actionFieldErrors
      actionFieldErrors = rest
    }
  })

  $effect(() => {
    void validateKeysInput
    if (actionFieldErrors.keys) {
      const { keys: _k, ...rest } = actionFieldErrors
      actionFieldErrors = rest
    }
  })
</script>

<div class="admin-grid">
  <div class="card">
    <div class="card-header">
      <h3>Professions</h3>
      <div class="toolbar-actions">
        <button type="button" class="secondary" onclick={refresh} disabled={loading}>
          {loading ? 'Loading...' : 'Refresh'}
        </button>
      </div>
    </div>
    <p class="muted panel-intro">
      Lista + defaults / validacio. CRUD: uj profession vagy a lista „Szerkesztes‟ utan mentes / torles.
    </p>
    {#if panelSuccess}
      <p class="flash-success">{panelSuccess}</p>
    {/if}
    {#if crudError}
      <p class="error">{crudError}</p>
    {/if}
    <div class="result-block crud-block">
      <h4>Uj profession</h4>
      <div class="action-grid">
        <div>
          <label class="field-label" for="new-cat">Category</label>
          <input
            id="new-cat"
            class="search-input compact-input"
            class:input-invalid={!!newFieldErrors.category}
            type="text"
            bind:value={newCategory}
          />
          {#if newFieldErrors.category}
            <p class="field-error">{newFieldErrors.category}</p>
          {/if}
        </div>
        <div>
          <label class="field-label" for="new-name">Name (kulcs)</label>
          <input
            id="new-name"
            class="search-input compact-input"
            class:input-invalid={!!newFieldErrors.name}
            type="text"
            bind:value={newName}
          />
          {#if newFieldErrors.name}
            <p class="field-error">{newFieldErrors.name}</p>
          {/if}
        </div>
        <div>
          <label class="field-label" for="new-dn">Display name</label>
          <input id="new-dn" class="search-input compact-input" type="text" bind:value={newDisplayName} />
        </div>
        <div>
          <label class="field-label" for="new-pk">Level profile key</label>
          <input
            id="new-pk"
            class="search-input compact-input"
            class:input-invalid={!!newFieldErrors.profileKey}
            type="text"
            bind:value={newProfileKey}
            list="profile-key-hints"
            placeholder="pl. default_crafting"
          />
          {#if newFieldErrors.profileKey}
            <p class="field-error">{newFieldErrors.profileKey}</p>
          {/if}
          <datalist id="profile-key-hints">
            {#each profileKeyHints as pk}
              <option value={pk}></option>
            {/each}
          </datalist>
        </div>
        <div>
          <label class="field-label" for="new-cap">Max proficiency (ure = nincs)</label>
          <input
            id="new-cap"
            class="search-input compact-input"
            class:input-invalid={!!newFieldErrors.maxProficiency}
            type="text"
            bind:value={newMaxCap}
          />
          {#if newFieldErrors.maxProficiency}
            <p class="field-error">{newFieldErrors.maxProficiency}</p>
          {/if}
        </div>
        <div class="crud-check-row">
          <label class="field-label" for="new-en"
            ><input id="new-en" type="checkbox" bind:checked={newEnabled} /> Enabled</label
          >
        </div>
        <div class="toolbar-actions">
          <button type="button" class="secondary" disabled={crudLoading} onclick={onCreateProfession}>
            Letrehozas
          </button>
        </div>
      </div>
    </div>
    {#if editItem}
      <div class="result-block crud-block">
        <h4>Szerkesztes: {editItem.category}.{editItem.name}</h4>
        <div class="action-grid">
          <div>
            <label class="field-label" for="ed-dn">Display name</label>
            <input
              id="ed-dn"
              class="search-input compact-input"
              class:input-invalid={!!editFieldErrors.displayName}
              type="text"
              bind:value={editDisplayName}
            />
            {#if editFieldErrors.displayName}
              <p class="field-error">{editFieldErrors.displayName}</p>
            {/if}
          </div>
          <div>
            <label class="field-label" for="ed-pk">Level profile key</label>
            <input
              id="ed-pk"
              class="search-input compact-input"
              class:input-invalid={!!editFieldErrors.profileKey}
              type="text"
              bind:value={editProfileKey}
              list="profile-key-hints"
            />
            {#if editFieldErrors.profileKey}
              <p class="field-error">{editFieldErrors.profileKey}</p>
            {/if}
          </div>
          <div>
            <label class="field-label" for="ed-cap">Max proficiency</label>
            <input
              id="ed-cap"
              class="search-input compact-input"
              class:input-invalid={!!editFieldErrors.maxProficiency}
              type="text"
              bind:value={editMaxCap}
            />
            {#if editFieldErrors.maxProficiency}
              <p class="field-error">{editFieldErrors.maxProficiency}</p>
            {/if}
          </div>
          <div class="crud-check-row">
            <label class="field-label" for="ed-en"
              ><input id="ed-en" type="checkbox" bind:checked={editEnabled} /> Enabled</label
            >
          </div>
          <div class="toolbar-actions crud-edit-actions">
            <button type="button" class="secondary" disabled={crudLoading} onclick={onUpdateProfession}>
              Frissites
            </button>
            <button type="button" class="secondary" disabled={crudLoading} onclick={onDeleteProfession}>
              Torles
            </button>
            <button type="button" class="secondary" disabled={crudLoading} onclick={cancelEdit}>Megse</button>
          </div>
        </div>
      </div>
    {/if}
    <input
      class="search-input"
      type="search"
      placeholder="Kereses: nev, kategoriakulcs, profile..."
      bind:value={search}
    />
    {#if error}
      <p class="error">{error}</p>
    {/if}
    <div class="action-grid">
      <div>
        <label class="field-label" for="profession-action-category">Category</label>
        <select
          id="profession-action-category"
          class="search-input compact-input"
          class:input-invalid={!!actionFieldErrors.category}
          bind:value={actionCategory}
        >
          {#if categoryOptions.length === 0}
            <option value="">--</option>
          {:else}
            {#each categoryOptions as category}
              <option value={category}>{category}</option>
            {/each}
          {/if}
        </select>
        {#if actionFieldErrors.category}
          <p class="field-error">{actionFieldErrors.category}</p>
        {/if}
      </div>
      <div>
        <label class="field-label" for="profession-keys-input">Keys (comma separated)</label>
        <input
          id="profession-keys-input"
          class="search-input compact-input"
          class:input-invalid={!!actionFieldErrors.keys}
          type="text"
          placeholder="weaponry, chemist, typo_profession"
          bind:value={validateKeysInput}
        />
        {#if actionFieldErrors.keys}
          <p class="field-error">{actionFieldErrors.keys}</p>
        {/if}
      </div>
      <div class="toolbar-actions">
        <button type="button" class="secondary" onclick={runLoadDefaults} disabled={actionLoading || !actionCategory}>
          Load defaults
        </button>
        <button type="button" class="secondary" onclick={runValidateKeys} disabled={actionLoading || !actionCategory}>
          Validate keys
        </button>
      </div>
    </div>
    {#if actionError}
      <p class="error">{actionError}</p>
    {/if}

    <div class="status-cards">
      <div class="status-card">
        <span>Visible</span>
        <strong>{filteredItems.length}</strong>
      </div>
      <div class="status-card">
        <span>Enabled</span>
        <strong>{enabledCount}</strong>
      </div>
      <div class="status-card">
        <span>Disabled</span>
        <strong>{disabledCount}</strong>
      </div>
      <div class="status-card">
        <span>Categories</span>
        <strong>{new Set(filteredItems.map((item) => item.category)).size}</strong>
      </div>
    </div>

    {#if defaultsResult || validationResult || profileResult}
      <div class="action-results">
        {#if defaultsResult}
          <div class="result-block">
            <h4>Defaults ({defaultsResult.category})</h4>
            <p class="muted">
              keys: {Object.keys(defaultsResult.defaults).length}
              {#if Object.keys(defaultsResult.defaults).length > 0}
                ({Object.keys(defaultsResult.defaults).join(', ')})
              {/if}
            </p>
          </div>
        {/if}
        {#if validationResult}
          <div class="result-block">
            <h4>Validation result</h4>
            <p class="muted">valid: {validationResult.valid.length} ({validationResult.valid.join(', ') || '-'})</p>
            <p class="muted">
              invalid: {validationResult.invalid.length} ({validationResult.invalid.join(', ') || '-'})
            </p>
            <p class="muted">
              missingProfile: {validationResult.missingProfile.length} ({validationResult.missingProfile.join(', ') ||
                '-'})
            </p>
          </div>
        {/if}
        {#if profileResult}
          <div class="result-block">
            <h4>Profile ({profileResult.category}.{profileResult.name})</h4>
            <p class="muted">profileKey: {profileResult.profile.profileKey}</p>
            <p class="muted">displayName: {profileResult.profile.displayName}</p>
            <p class="muted">mode: {profileResult.profile.mode}</p>
            <p class="muted">
              levels:
              {Array.isArray(profileResult.profile.levels)
                ? profileResult.profile.levels.length
                : Object.keys(profileResult.profile.levels || {}).length}
            </p>
            <LevelPreview levels={profileResult.profile.levels} />
          </div>
        {/if}
      </div>
    {/if}
  </div>

  <div class="card">
    <div class="card-header">
      <h3>Registry Entries</h3>
    </div>

    <ul class="simple-list">
      {#each filteredItems as item}
        <li>
          <div class="simple-list-main">
            <strong>{item.displayName}</strong>
            <small>{item.category}.{item.name}</small>
          </div>
          <div class="simple-list-meta">
            <button
              type="button"
              class="secondary small-btn"
              onclick={() => runLoadProfile(item.category, item.name)}
              disabled={actionLoading}
            >
              View profile
            </button>
            <button type="button" class="secondary small-btn" onclick={() => beginEdit(item)} disabled={crudLoading}>
              Szerkesztes
            </button>
            <span class={`status status-${item.enabled ? 'passed' : 'failed'}`}>
              {item.enabled ? 'enabled' : 'disabled'}
            </span>
            <span>profile: {item.profileKey}</span>
            <span>cap: {item.maxProficiency ?? 'none'}</span>
          </div>
        </li>
      {/each}
    </ul>
    {#if !loading && filteredItems.length === 0}
      <p class="muted">Nincs talalat a jelenlegi szuresre.</p>
    {/if}
  </div>
</div>
