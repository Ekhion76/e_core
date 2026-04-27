# SERVER SIDE EXPORTS

## getCore() curated fields (e_core 0.1.3+)

Same as on the client: `eCore.framework`, `eCore.config`, `eCore.i18n`, `eCore.util` are merged onto the object returned by `exports.e_core:getCore()`.

Additionally, when `src/imports/server/discord_log.lua` is loaded by **e_core**, you can build webhooks via the thin wrapper:

```lua
local eCore = exports.e_core:getCore()
local log = eCore.log and eCore.log.discord and eCore.log.discord.create('https://discord.com/api/webhooks/...', 'MyBot')
if log then
    log:content('Hello from server'):send()
end
```

## getLabor
Returns the player's labor points.

**playerId**: number (source)

**@return**: On success **`true`, number** (balance may be **0** — use the boolean first value, not `if exports.e_core:getLabor(id) then`). On error **`false`, reason** (`eCoreErr`).

```lua
local ok, laborOrReason = exports.e_core:getLabor(playerId)
if not ok then
    -- laborOrReason == eCoreErr.not_found_metadata, etc.
    return
end
-- laborOrReason is the balance (number)
```

## setLabor

**playerId**: number (source)

**amount**: number of labor points — **non-negative** (`tonumber`); negatív / NaN → `not_valid_amount`.

**@return**: boolean success and, in case of an error, the reason as well

```lua
exports.e_core:setLabor(playerId, amount)
```

## removeLabor

**playerId**: number (source)

**amount**: must be a **positive** number; cannot exceed current balance → otherwise **`not_enough_labor`**.

**@return**: boolean success and, in case of an error, the reason as well
```lua
exports.e_core:removeLabor(playerId, amount)
```

## addLabor

**playerId**: number (source)

**amount**: must be a **positive** number; otherwise `not_valid_amount`.

**@return**: boolean success and, in case of an error, the reason as well
```lua
exports.e_core:addLabor(playerId, amount)
```

## registerMeta

Register metadata if not exists. Adds the new keys to the given category.
If the meta key already exists, it will not overwrite or delete existing meta keys.

**Contract / edge cases**

- **category** and keys inside **defaultValue**: leading/trailing spaces are **trimmed**; empty category → error.
- **defaultValue**: `nil` is treated as `{}`. Any other non-table type → `meta_default_must_be_table`.
- **Reserved root keys** (not allowed as **category**): `login`, `logout`, `labor` → `reserved_meta_category`. Use labor exports / `getMeta` for labor; do not re-register core fields.
- **New category**: a **shallow copy** of `defaultValue` is stored (caller mutating their table later does not change stored meta).
- **Merge path**: only **string** keys from `defaultValue`; a key is added only if **missing** (`rawget`); existing values (including `0` / `false`) are **not** overwritten. If the existing slot is not a table (corrupt data) → `meta_category_not_table`.

**playerId**: number (source)

**category**: string *eg.: crafting, reputation, harvesting, special, ...*

**defaultValue**: table *key => value pairs, eg.: {cooking = 0, weaponry = 0}*

**@return**: boolean success and, in case of an error, the reason as well
```lua
exports.e_core:registerMeta(playerId, category, defaultValue)
```

## getMeta
Returns all elements of the category. If no meta key is specified, the entire meta database is returned.

If **meta** is provided, it must be a non-empty string after **trim** (including reads of `labor` / `login` / `logout`). Wrong type or empty → `no_valid_meta_name`.

**playerId**: number (source)

**meta**: string (optional) *eg.: crafting, reputation, harvesting, special, ...*

**@return**: boolean|table success or values
```lua
exports.e_core:getMeta(playerId, meta)

local metaData = exports.e_core:getMeta(1, 'crafting')
print(json.encode(metaData, {indent = true}))
```


## setMeta

Gives a value to a meta variable. Overwrites the original value.

**Contract**

- **meta** (category key): trimmed; empty → error. Same **reserved** names as `registerMeta` (`login`, `logout`, `labor`) → `reserved_meta_category`.
- **value** must be a **table** (a shallow copy is stored) → otherwise `meta_value_must_be_table`.

**playerId**: number (source)

**meta**: string *eg.: crafting, reputation, harvesting, special, ...*

**value**: table *key => value pairs, eg.: {cooking = 0, weaponry = 0}*

**@return**: boolean success and, in case of an error, the reason as well
```lua
exports.e_core:setMeta(playerId, meta, value)

local success, reason = exports.e_core:setMeta(1, 'crafting', {
    cooking = 4020,
    weaponry = 200
})
```


## getLevel
Returns the player's level based on their proficiency point. (level ranges: config/levels.lua)

**value**: value *number of points achieved in profession*

**@return**: number *the number of the player's level in the profession*

```lua
exports.e_core:getLevel(value)
```

## getDiscounts
It returns the discounts as a percentage, depending on the player's proficiency

**value**: value *number of points achieved in profession*

Ha nincs kitöltött `Config.levels` tábla → `false`, `not_levels_data` (`eCoreErr.not_levels_data`).

**@return**: table *returns the discounts corresponding to the level*
```lua
exports.e_core:getDiscounts(value)
```

## ability
General function for querying and manipulating metadata. 
It can be used by itself and by the wrapper functions below.

It only works with already existing metadata, the category and the meta name are also required

**Reserved categories:** `login`, `logout`, `labor` → `reserved_meta_category` (use `getLabor` / labor exports / `getMeta` for reads where appropriate). **category** and **name** are **trimmed**; empty → `no_valid_meta_name`.

**playerId**: number (required) (source)

**category**: string (required) *eg.: crafting, reputation, harvesting, special, ...*

**name**: string (required) *eg.: weaponry*

**value** (`setAbility` / `addAbility` / `removeAbility`): **number** (string számjegy is elfogadott, ha `tonumber` értelmezhető). Nem szám / hiányzó → `not_valid_amount`. (`getAbility`-nak nincs `value` paramétere.)

**@return**: boolean success and, in case of an error, the reason as well

```lua
exports.e_core:getAbility(playerId, category, name)
exports.e_core:setAbility(playerId, category, name, value)
exports.e_core:addAbility(playerId, category, name, value)
exports.e_core:removeAbility(playerId, category, name, value)
```

## getConfig
Returns the e_core config file

**@return**: table 
```lua
exports.e_core:getConfig()
```

## isReady

**@return**: boolean – `true` csak akkor, ha az item registry (`REGISTERED_ITEMS`) sikeresen betöltött. Betöltés alatt és timeout után `false`. Részletesebb állapot: `exports.e_core:getCore():isReady()` (`nil` töltés közben, `false` timeout, `true` kész).

```lua
if exports.e_core:isReady() then
    -- pl. itemhez kötött szerver logika
end
```

## getDbSchemaVersion

**@return**: number – alkalmazott DB migrációk közül a legnagyobb `id` (`e_core_migrations` tábla). **0** ha üres, a tábla még nem létezik, vagy a `MAX(id)` lekérdezés sikertelen (hibakeresés: szerver log + `docs/ECORE_ERR_HIBA_NYOMON_HU.md` §4.5). Részlet: `docs/DB_MIGRATIONS_HU.md`.

```lua
local v = exports.e_core:getDbSchemaVersion()
-- indulás után tipikusan 1 (egyetlen migráció a repóban); új migráció = nagyobb szám
```

## getProfessionRegistry

**@return**: success + profession registry map (`{ [category] = { [name] = { ... } } }`) vagy hiba (`eCoreErr.profession_registry_unavailable`).

```lua
local ok, registryOrErr = exports.e_core:getProfessionRegistry()
if not ok then
    return print(('registry load failed: %s'):format(registryOrErr))
end

local crafting = registryOrErr.crafting or {}
for professionName, row in pairs(crafting) do
    print(professionName, row.displayName, row.levelProfileKey)
end
```

## isValidProfession

**@return**: success + boolean (`true` ha létezik és engedélyezett), vagy hiba.

```lua
local ok, validOrErr = exports.e_core:isValidProfession('crafting', 'weaponry')
if not ok then
    return print(('isValidProfession error: %s'):format(validOrErr))
end

if validOrErr then
    print('profession can be used')
end
```

## getProfessionDefaults

**@return**: success + defaults map (`{ [professionName] = 0 }`) vagy hiba (`profession_category_not_found`, stb.).

```lua
local ok, defaultsOrErr = exports.e_core:getProfessionDefaults('crafting')
if not ok then
    return print(('defaults error: %s'):format(defaultsOrErr))
end

exports.e_core:registerMeta(playerId, 'crafting', defaultsOrErr)
```

## getProfessionLevelProfile

**@return**: success + profile (`profileKey`, `displayName`, `mode`, `levels`) vagy hiba (`profession_not_found`, `profession_profile_not_found`).

```lua
local ok, profileOrErr = exports.e_core:getProfessionLevelProfile('crafting', 'weaponry')
if not ok then
    return print(('profile error: %s'):format(profileOrErr))
end

print(profileOrErr.profileKey, #profileOrErr.levels)
```

## validateProfessionKeys

**@return**: success + structured validation result (`valid`, `invalid`, `missingProfile`) vagy hiba (`profession_category_not_found`, stb.).

```lua
local ok, resultOrErr = exports.e_core:validateProfessionKeys('crafting', {
    'weaponry',
    'chemist',
    'typo_profession',
})
if not ok then
    return print(('validateProfessionKeys error: %s'):format(resultOrErr))
end

print('valid', #resultOrErr.valid)
print('invalid', #resultOrErr.invalid)
print('missingProfile', #resultOrErr.missingProfile)
```

## professionAdminList

**@return**: standard response object (`ok`, `code`, `message`, `data.items`).

```lua
local res = exports.e_core:professionAdminList()
if not res.ok then
    return print(('admin list error: %s (%s)'):format(res.code, res.message))
end

print(('profession count: %s'):format(#res.data.items))
```

## professionAdminCreate / professionAdminUpdate

```lua
local created = exports.e_core:professionAdminCreate({
    category = 'crafting',
    name = 'tailoring',
    displayName = 'Tailoring',
    profileKey = 'default_global',
    enabled = true,
})

if created.ok then
    local updated = exports.e_core:professionAdminUpdate('crafting', 'tailoring', {
        displayName = 'Tailoring Pro',
        enabled = false,
    })
    print(updated.code, updated.message)
end
```

## professionAdminSetEnabled / professionAdminDelete

```lua
local toggleRes = exports.e_core:professionAdminSetEnabled('crafting', 'tailoring', true)
print(toggleRes.code, toggleRes.message)

local deleteRes = exports.e_core:professionAdminDelete('crafting', 'tailoring')
print(deleteRes.code, deleteRes.message)
```

## professionAdminDeleteDryRun / professionAdminDeleteApply

```lua
local dryRun = exports.e_core:professionAdminDeleteDryRun('crafting', 'tailoring', {
    requestedBy = 'admin:console',
    batchSize = 500,
    auth = { source = playerId },
})
if not dryRun.ok then
    return print(('cleanup dry-run error: %s (%s)'):format(dryRun.code, dryRun.message))
end

print(dryRun.data.job.status, dryRun.data.job.stats.changed, dryRun.data.job.stats.removedKeys)

local apply = exports.e_core:professionAdminDeleteApply('crafting', 'tailoring', {
    requestedBy = 'admin:console',
    batchSize = 500,
    confirmText = 'crafting.tailoring DELETE',
    deleteProfession = true, -- opcionális: apply után törli a registry sort is
    auth = { source = playerId },
})
print(apply.code, apply.message)
-- mindkettő jobot hoz létre, állapot követéshez használd a professionAdminCleanupJobGet exportot
```

## professionAdminCleanupJobGet / Abort / Resume / Audit

```lua
local listRes = exports.e_core:professionAdminCleanupJobList({
    status = 'queued', -- opcionális filterek: status, mode, category, name
    limit = 20,
    offset = 0,
    auth = { source = playerId },
})
print(listRes.code, listRes.data.total, #listRes.data.items)

local state = exports.e_core:professionAdminCleanupJobGet('cleanup-00000001', {
    auth = { source = playerId },
})
print(state.code, state.data and state.data.job and state.data.job.status)

local abortRes = exports.e_core:professionAdminCleanupJobAbort('cleanup-00000001', {
    requestedBy = 'admin:console',
    auth = { source = playerId },
})
print(abortRes.code, abortRes.message)

local resumeRes = exports.e_core:professionAdminCleanupJobResume('cleanup-00000001', {
    requestedBy = 'admin:console',
    auth = { source = playerId },
})
print(resumeRes.code, resumeRes.message)

local audit = exports.e_core:professionAdminAuditList(20, {
    auth = { source = playerId },
})
print(audit.code, #audit.data.items)

local deniedAudit = exports.e_core:adminApiDeniedAuditList({
    section = 'cleanup', -- opcionális: cleanup / diagnostics
    action = 'professionAdminCleanupJobAbort', -- opcionális
    limit = 20,
    offset = 0,
    auth = { source = playerId },
})
print(deniedAudit.code, deniedAudit.data.total, #deniedAudit.data.items)
if deniedAudit.ok and deniedAudit.data.items[1] then
    local item = deniedAudit.data.items[1]
    print(
        item.eventType,
        item.actor and item.actor.requestedBy,
        item.target and item.target.action,
        item.outcome and item.outcome.status
    )
end

local purge = exports.e_core:adminApiDeniedAuditPurge({
    auth = { source = playerId },
})
print(purge.code, purge.data and purge.data.deleted)

local purgeDryRun = exports.e_core:adminApiDeniedAuditPurge({
    dryRun = true,
    auth = { source = playerId },
})
print(purgeDryRun.code, purgeDryRun.data and purgeDryRun.data.wouldDelete)
```

## levelProfileAdminList

```lua
local res = exports.e_core:levelProfileAdminList()
if not res.ok then
    return print(('profile list error: %s (%s)'):format(res.code, res.message))
end

for _, profile in ipairs(res.data.items) do
    print(profile.profileKey, profile.mode, #profile.levels, profile.professionCount)
end
```

## levelProfileAdminCreate / levelProfileAdminUpdate

```lua
local createRes = exports.e_core:levelProfileAdminCreate({
    profileKey = 'crafting_easy_v1',
    displayName = 'Crafting Easy v1',
    mode = 'easy',
    easyGenerator = {
        milestones = 8,
        maxPoints = 80000,
        curveType = 'soft',
        max = {
            labor = 20,
            time = 15,
            price = 10,
            chance = 8,
            speed = 12,
        },
    },
})

if createRes.ok then
    local updateRes = exports.e_core:levelProfileAdminUpdate('crafting_easy_v1', {
        mode = 'advanced',
        levels = createRes.data.profile.levels,
    })
    print(updateRes.code, updateRes.message)
end
```

## levelProfileAdminDelete

```lua
local deleteRes = exports.e_core:levelProfileAdminDelete('crafting_easy_v1')
print(deleteRes.code, deleteRes.message)
```

## diagnosticsAdminListTests

```lua
local res = exports.e_core:diagnosticsAdminListTests({
    auth = { source = playerId },
})
if not res.ok then
    return print(('diagnostics list error: %s (%s)'):format(res.code, res.message))
end

for _, test in ipairs(res.data.items) do
    print(test.key, test.severity, test.estimatedCost, #test.docHints)
end
```

## diagnosticsAdminRun / diagnosticsAdminGetRun / diagnosticsAdminCancelRun

```lua
-- A `profession-key-validation` teszt eredményében (`run.results[]`) sikertelen kulcsok esetén
-- a belső `code` = `profession_key_validation_failed` (nem `profession_not_found`).

local runRes = exports.e_core:diagnosticsAdminRun({
    requestedBy = 'admin:console',
    tests = { 'registry_integrity', 'profession-key-validation' },
    professionKeysByCategory = {
        crafting = { 'weaponry', 'chemist', 'typo_profession' },
    },
    auth = { source = playerId },
})
if not runRes.ok then
    return print(('run error: %s (%s)'):format(runRes.code, runRes.message))
end

local runId = runRes.data.run.runId
local state = exports.e_core:diagnosticsAdminGetRun(runId, {
  auth = { source = playerId },
})
-- Ismeretlen / lejárt `runId`: `state.ok == false`, `state.code == 'diagnostics_run_not_found'`.
print(state.code, state.data and state.data.run and state.data.run.status)

-- Optional cancel for queued/running runs:
-- local cancel = exports.e_core:diagnosticsAdminCancelRun(runId, { auth = { source = playerId } })
-- ugyanígy: `diagnostics_run_not_found`, ha a futás már nincs a memóriában
-- print(cancel.code, cancel.message)
```
