<script lang="ts">
  import LevelPreview from './LevelPreview.svelte'
  import {
    defaultEasyGeneratorForm,
    easyGeneratorApiPayload,
    FLASH_SUCCESS_MS,
    generateEasyLevelsFromForm,
    parseLevelsJsonSafe,
    type EasyGeneratorForm
  } from './adminFormHelpers'
  import {
    createLevelProfile,
    deleteLevelProfile,
    listLevelProfiles,
    updateLevelProfile,
    type LevelProfileItem
  } from './registry'

  let profileItems = $state<LevelProfileItem[]>([])
  let loading = $state<boolean>(false)
  let error = $state<string>('')
  let search = $state<string>('')
  let selectedProfile = $state<LevelProfileItem | null>(null)
  let crudLoading = $state<boolean>(false)
  let crudError = $state<string>('')
  let crudSuccess = $state<string>('')
  let flashTimer: ReturnType<typeof setTimeout> | undefined

  let newProfileKey = $state<string>('')
  let newDisplayName = $state<string>('')
  let newMode = $state<'easy' | 'advanced'>('easy')
  const defaultLevelsSample = `[
  { "limit": 100, "labor": 10, "time": 10, "price": 5, "chance": 5, "speed": 5 },
  { "limit": 200, "labor": 18, "time": 18, "price": 12, "chance": 12, "speed": 12 }
]`
  let newLevelsJson = $state<string>(defaultLevelsSample)
  let newFieldErrors = $state<Record<string, string>>({})
  let createUseEasyOnly = $state<boolean>(false)
  let easyForm = $state<EasyGeneratorForm>(defaultEasyGeneratorForm())

  let editDisplayName = $state<string>('')
  let editMode = $state<'easy' | 'advanced'>('easy')
  let editLevelsJson = $state<string>('')
  let editFieldErrors = $state<Record<string, string>>({})
  let easyFormEdit = $state<EasyGeneratorForm>(defaultEasyGeneratorForm())

  const normalizedSearch = $derived(search.trim().toLowerCase())
  const filteredItems = $derived(
    normalizedSearch.length === 0
      ? profileItems
      : profileItems.filter((item) => {
          const haystack = `${item.displayName} ${item.profileKey} ${item.mode}`.toLowerCase()
          return haystack.includes(normalizedSearch)
        })
  )
  const easyCount = $derived(filteredItems.filter((item) => item.mode === 'easy').length)
  const advancedCount = $derived(filteredItems.length - easyCount)

  function flashOk(msg: string) {
    crudSuccess = msg
    crudError = ''
    if (flashTimer) {
      clearTimeout(flashTimer)
    }
    flashTimer = setTimeout(() => {
      crudSuccess = ''
      flashTimer = undefined
    }, FLASH_SUCCESS_MS)
  }

  async function refresh() {
    loading = true
    error = ''
    try {
      const list = await listLevelProfiles()
      profileItems = list
      if (selectedProfile) {
        const still = list.find((p) => p.profileKey === selectedProfile!.profileKey)
        selectedProfile = still ?? (list[0] ?? null)
      } else if (list.length > 0) {
        selectedProfile = list[0]
      }
    } catch (err) {
      error = err instanceof Error ? err.message : 'Level profile lista betoltese sikertelen.'
    } finally {
      loading = false
    }
  }

  $effect(() => {
    void refresh()
  })

  $effect(() => {
    const s = selectedProfile
    if (!s) {
      return
    }
    editDisplayName = s.displayName
    editMode = s.mode
    editLevelsJson = JSON.stringify(s.levelsData, null, 2)
    editFieldErrors = {}
  })

  function pasteEasyIntoNewJson() {
    crudError = ''
    newFieldErrors = {}
    try {
      const rows = generateEasyLevelsFromForm(easyForm)
      newLevelsJson = JSON.stringify(rows, null, 2)
      createUseEasyOnly = false
      flashOk('Easy sorok beillesztve a JSON mezőbe (ellenőrizd, majd ments).')
    } catch (err) {
      crudError = err instanceof Error ? err.message : 'Generálás sikertelen.'
    }
  }

  function pasteEasyIntoEditJson() {
    crudError = ''
    editFieldErrors = {}
    try {
      const rows = generateEasyLevelsFromForm(easyFormEdit)
      editLevelsJson = JSON.stringify(rows, null, 2)
      flashOk('Easy sorok beillesztve a szerkesztett JSON mezőbe.')
    } catch (err) {
      crudError = err instanceof Error ? err.message : 'Generálás sikertelen.'
    }
  }

  async function onCreate() {
    crudLoading = true
    crudError = ''
    newFieldErrors = {}
    if (!newProfileKey.trim()) {
      newFieldErrors = { profileKey: 'A profile key megadása kötelező.' }
      crudLoading = false
      return
    }
    try {
      const createdPk = newProfileKey.trim()
      if (createUseEasyOnly) {
        try {
          generateEasyLevelsFromForm(easyForm)
        } catch (err) {
          crudError = err instanceof Error ? err.message : 'Easy generátor érvénytelen.'
          crudLoading = false
          return
        }
        await createLevelProfile({
          profileKey: createdPk,
          displayName: newDisplayName.trim() || createdPk,
          mode: newMode,
          easyGenerator: easyGeneratorApiPayload(easyForm)
        })
      } else {
        const parsed = parseLevelsJsonSafe(newLevelsJson)
        if (!parsed.ok) {
          newFieldErrors = { levels: parsed.message }
          crudLoading = false
          return
        }
        await createLevelProfile({
          profileKey: createdPk,
          displayName: newDisplayName.trim() || createdPk,
          mode: newMode,
          levels: parsed.value
        })
      }
      newProfileKey = ''
      newDisplayName = ''
      newMode = 'easy'
      newLevelsJson = defaultLevelsSample
      createUseEasyOnly = false
      easyForm = defaultEasyGeneratorForm()
      await refresh()
      selectedProfile = profileItems.find((p) => p.profileKey === createdPk) ?? profileItems[0] ?? null
      flashOk('Level profile létrehozva.')
    } catch (err) {
      crudError = err instanceof Error ? err.message : 'Letrehozas sikertelen.'
    } finally {
      crudLoading = false
    }
  }

  async function onUpdate() {
    if (!selectedProfile) {
      return
    }
    crudLoading = true
    crudError = ''
    editFieldErrors = {}
    const parsed = parseLevelsJsonSafe(editLevelsJson)
    if (!parsed.ok) {
      editFieldErrors = { levels: parsed.message }
      crudLoading = false
      return
    }
    if (!editDisplayName.trim()) {
      editFieldErrors = { displayName: 'A megjelenített név nem lehet üres.' }
      crudLoading = false
      return
    }
    try {
      const updated = await updateLevelProfile(selectedProfile.profileKey, {
        displayName: editDisplayName.trim(),
        mode: editMode,
        levels: parsed.value
      })
      await refresh()
      selectedProfile = profileItems.find((p) => p.profileKey === updated.profileKey) ?? null
      flashOk('Level profile frissítve.')
    } catch (err) {
      crudError = err instanceof Error ? err.message : 'Frissites sikertelen.'
    } finally {
      crudLoading = false
    }
  }

  async function onDelete() {
    if (!selectedProfile) {
      return
    }
    if (!window.confirm(`Torolni a profile-t: ${selectedProfile.profileKey} ?`)) {
      return
    }
    crudLoading = true
    crudError = ''
    try {
      await deleteLevelProfile(selectedProfile.profileKey)
      selectedProfile = null
      await refresh()
      flashOk('Level profile törölve.')
    } catch (err) {
      crudError = err instanceof Error ? err.message : 'Torles sikertelen.'
    } finally {
      crudLoading = false
    }
  }
</script>

<div class="admin-grid">
  <div class="card">
    <div class="card-header">
      <h3>Level Profiles</h3>
      <div class="toolbar-actions">
        <button type="button" class="secondary" onclick={refresh} disabled={loading || crudLoading}>
          {loading ? 'Loading...' : 'Refresh'}
        </button>
      </div>
    </div>
    <p class="muted panel-intro">
      Új profil: kitölthető <strong>JSON levels</strong> tömb, vagy csak <strong>easy generátor</strong> (szerver
      ugyanazt a sémát használja). Szerkesztéshez a JSON mező kötelező; easy blokk opcionálisan beilleszt ide.
    </p>
    {#if crudSuccess}
      <p class="flash-success">{crudSuccess}</p>
    {/if}
    {#if crudError}
      <p class="error">{crudError}</p>
    {/if}
    <input
      class="search-input"
      type="search"
      placeholder="Kereses: profile key, nev, mod..."
      bind:value={search}
    />
    {#if error}
      <p class="error">{error}</p>
    {/if}

    <div class="result-block crud-block">
      <h4>Uj level profile</h4>
      <div class="action-grid">
        <div>
          <label class="field-label" for="npk">Profile key</label>
          <input
            id="npk"
            class="search-input compact-input"
            class:input-invalid={!!newFieldErrors.profileKey}
            type="text"
            bind:value={newProfileKey}
          />
          {#if newFieldErrors.profileKey}
            <p class="field-error">{newFieldErrors.profileKey}</p>
          {/if}
        </div>
        <div>
          <label class="field-label" for="ndn">Display name</label>
          <input id="ndn" class="search-input compact-input" type="text" bind:value={newDisplayName} />
        </div>
        <div>
          <label class="field-label" for="nm">Mode</label>
          <select id="nm" class="search-input compact-input" bind:value={newMode}>
            <option value="easy">easy</option>
            <option value="advanced">advanced</option>
          </select>
        </div>
        <div class="crud-check-row">
          <label class="field-label" for="easy-only"
            ><input id="easy-only" type="checkbox" bind:checked={createUseEasyOnly} /> Csak easy generátor (JSON
            figyelmen kívül hagyva)</label
          >
        </div>
        {#if !createUseEasyOnly}
          <div class="crud-levels-field">
            <label class="field-label" for="nlv">Levels (JSON array)</label>
            <textarea
              id="nlv"
              class="search-input levels-json"
              class:input-invalid={!!newFieldErrors.levels}
              rows="8"
              bind:value={newLevelsJson}
              disabled={createUseEasyOnly}
            ></textarea>
            {#if newFieldErrors.levels}
              <p class="field-error">{newFieldErrors.levels}</p>
            {/if}
          </div>
        {/if}
        <details class="easy-gen-details">
          <summary>Easy generátor (milestones / maxPoints / görbe / max módosítók)</summary>
          <div class="easy-gen-grid">
            <div>
              <label class="field-label" for="eg-m">Milestones (≥2)</label>
              <input id="eg-m" class="search-input compact-input" type="number" min="2" bind:value={easyForm.milestones} />
            </div>
            <div>
              <label class="field-label" for="eg-mp">Max points</label>
              <input id="eg-mp" class="search-input compact-input" type="number" min="1" bind:value={easyForm.maxPoints} />
            </div>
            <div>
              <label class="field-label" for="eg-c">Görbe</label>
              <select id="eg-c" class="search-input compact-input" bind:value={easyForm.curveType}>
                <option value="linear">linear</option>
                <option value="soft">soft</option>
                <option value="aggressive">aggressive</option>
              </select>
            </div>
            <div>
              <label class="field-label" for="eg-ml">maxLabor</label>
              <input id="eg-ml" class="search-input compact-input" type="number" min="0" max="100" bind:value={easyForm.maxLabor} />
            </div>
            <div>
              <label class="field-label" for="eg-mt">maxTime</label>
              <input id="eg-mt" class="search-input compact-input" type="number" min="0" max="100" bind:value={easyForm.maxTime} />
            </div>
            <div>
              <label class="field-label" for="eg-mp2">maxPrice</label>
              <input id="eg-mp2" class="search-input compact-input" type="number" min="0" max="100" bind:value={easyForm.maxPrice} />
            </div>
            <div>
              <label class="field-label" for="eg-mc">maxChance</label>
              <input id="eg-mc" class="search-input compact-input" type="number" min="0" max="100" bind:value={easyForm.maxChance} />
            </div>
            <div>
              <label class="field-label" for="eg-ms">maxSpeed</label>
              <input id="eg-ms" class="search-input compact-input" type="number" min="0" max="100" bind:value={easyForm.maxSpeed} />
            </div>
            <div class="toolbar-actions easy-gen-actions">
              <button type="button" class="secondary" disabled={createUseEasyOnly} onclick={pasteEasyIntoNewJson}>
                Beilleszt az új JSON mezőbe
              </button>
            </div>
          </div>
        </details>
        <div class="toolbar-actions">
          <button type="button" class="secondary" disabled={crudLoading} onclick={onCreate}>Letrehozas</button>
        </div>
      </div>
    </div>

    <div class="status-cards">
      <div class="status-card">
        <span>Visible</span>
        <strong>{filteredItems.length}</strong>
      </div>
      <div class="status-card">
        <span>Easy</span>
        <strong>{easyCount}</strong>
      </div>
      <div class="status-card">
        <span>Advanced</span>
        <strong>{advancedCount}</strong>
      </div>
      <div class="status-card">
        <span>Linked professions</span>
        <strong>{filteredItems.reduce((sum, item) => sum + item.linkedProfessions, 0)}</strong>
      </div>
    </div>

    {#if selectedProfile}
      <div class="action-results">
        <div class="result-block">
          <h4>Selected: {selectedProfile.profileKey}</h4>
          <p class="muted">linked professions: {selectedProfile.linkedProfessions}</p>
          <p class="muted">updated: {selectedProfile.updatedAt}</p>
          <div class="action-grid crud-edit-grid">
            <div>
              <label class="field-label" for="edn">Display name</label>
              <input
                id="edn"
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
              <label class="field-label" for="edm">Mode</label>
              <select id="edm" class="search-input compact-input" bind:value={editMode}>
                <option value="easy">easy</option>
                <option value="advanced">advanced</option>
              </select>
            </div>
            <div class="crud-levels-field">
              <label class="field-label" for="elv">Levels (JSON array)</label>
              <textarea
                id="elv"
                class="search-input levels-json"
                class:input-invalid={!!editFieldErrors.levels}
                rows="10"
                bind:value={editLevelsJson}
              ></textarea>
              {#if editFieldErrors.levels}
                <p class="field-error">{editFieldErrors.levels}</p>
              {/if}
            </div>
            <details class="easy-gen-details">
              <summary>Easy → beillesztés (szerkesztett JSON)</summary>
              <div class="easy-gen-grid">
                <div>
                  <label class="field-label" for="ege-m">Milestones</label>
                  <input id="ege-m" class="search-input compact-input" type="number" min="2" bind:value={easyFormEdit.milestones} />
                </div>
                <div>
                  <label class="field-label" for="ege-mp">Max points</label>
                  <input id="ege-mp" class="search-input compact-input" type="number" min="1" bind:value={easyFormEdit.maxPoints} />
                </div>
                <div>
                  <label class="field-label" for="ege-c">Görbe</label>
                  <select id="ege-c" class="search-input compact-input" bind:value={easyFormEdit.curveType}>
                    <option value="linear">linear</option>
                    <option value="soft">soft</option>
                    <option value="aggressive">aggressive</option>
                  </select>
                </div>
                <div>
                  <label class="field-label" for="ege-ml">maxLabor</label>
                  <input id="ege-ml" class="search-input compact-input" type="number" min="0" max="100" bind:value={easyFormEdit.maxLabor} />
                </div>
                <div>
                  <label class="field-label" for="ege-mt">maxTime</label>
                  <input id="ege-mt" class="search-input compact-input" type="number" min="0" max="100" bind:value={easyFormEdit.maxTime} />
                </div>
                <div>
                  <label class="field-label" for="ege-mp2">maxPrice</label>
                  <input id="ege-mp2" class="search-input compact-input" type="number" min="0" max="100" bind:value={easyFormEdit.maxPrice} />
                </div>
                <div>
                  <label class="field-label" for="ege-mc">maxChance</label>
                  <input id="ege-mc" class="search-input compact-input" type="number" min="0" max="100" bind:value={easyFormEdit.maxChance} />
                </div>
                <div>
                  <label class="field-label" for="ege-ms">maxSpeed</label>
                  <input id="ege-ms" class="search-input compact-input" type="number" min="0" max="100" bind:value={easyFormEdit.maxSpeed} />
                </div>
                <div class="toolbar-actions easy-gen-actions">
                  <button type="button" class="secondary" onclick={pasteEasyIntoEditJson}>Beilleszt JSON mezőbe</button>
                </div>
              </div>
            </details>
            <div class="toolbar-actions crud-edit-actions">
              <button type="button" class="secondary" disabled={crudLoading} onclick={onUpdate}>Frissites</button>
              <button type="button" class="secondary" disabled={crudLoading} onclick={onDelete}>Torles</button>
            </div>
          </div>
          <LevelPreview levels={selectedProfile.levelsData} />
        </div>
      </div>
    {/if}
  </div>

  <div class="card">
    <div class="card-header">
      <h3>Profile Catalog</h3>
    </div>

    <ul class="simple-list">
      {#each filteredItems as item}
        <li>
          <div class="simple-list-main">
            <strong>{item.displayName}</strong>
            <small>{item.profileKey}</small>
          </div>
          <div class="simple-list-meta">
            <button type="button" class="secondary small-btn" onclick={() => (selectedProfile = item)}>
              Kivalasztas
            </button>
            <span class={`status status-${item.mode === 'easy' ? 'running' : 'queued'}`}>
              {item.mode}
            </span>
            <span>levels: {item.levels}</span>
            <span>linked: {item.linkedProfessions}</span>
            <span>updated: {item.updatedAt}</span>
          </div>
        </li>
      {/each}
    </ul>
    {#if !loading && filteredItems.length === 0}
      <p class="muted">Nincs talalat a jelenlegi szuresre.</p>
    {/if}
  </div>
</div>
