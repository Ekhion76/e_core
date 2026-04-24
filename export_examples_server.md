# SERVER SIDE EXPORTS

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
