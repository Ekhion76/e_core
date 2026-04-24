# CLIENT SIDE exports.e_core

## getMeta
Returns the player's entire meta database, or one category by key.

**@param** `meta` (optional): string category key; trimmed like on the server. Non-string or empty after trim → **`false`, `reason`** (`eCoreErr.no_valid_meta_name`).

**@return**: full `ECO.meta` table | one category value | **`nil`** if the key is missing | **`false`, reason`** on invalid `meta` argument

```lua
local all = exports.e_core:getMeta()
local crafting = exports.e_core:getMeta('crafting')
local badMeta, errReason = exports.e_core:getMeta(123) -- false, no_valid_meta_name
```

## getAbility
Query the proficiency within the Crafting category.
If no metaName is specified, the entire category is returned
```lua
exports.e_core:getAbility(category, metaName)
```

**category**: string (required) *crafting, reputation, harvesting, special, labor, etc.*
 
**metaName**: string (optional) *weaponry, cooking, handicraft, chemist, etc. or none*

**@return**: 
- result: meta value, whole category table, or **`false`** if the request failed
- reason: if the request failed, then the reason (`category_does_not_exist`, `meta_does_not_exist`, `no_valid_meta_name`)

Category and optional name are **trim**med; whitespace-only or non-string → `no_valid_meta_name`. Stored proficiency **`false`** is returned as-is (not confused with „missing”).

```lua
local result, reason = exports.e_core:getAbility('crafting', 'weaponry')
```

## getLabor
Returns the player's labor points.

**@return**: **`true`, number** on success (balance may be **0**). **`false`, reason** on error (`eCoreErr`).

```lua
local ok, laborOrReason = exports.e_core:getLabor()
if not ok then return end
-- laborOrReason is the balance
```

## getLevel
Returns the player's level based on their proficiency point. (level ranges: config/levels.lua)

**value**: value number of points achieved in profession

**@return**: number the number of the player's level in the profession

```lua
exports.e_core:getLevel(value)
```

## getDiscounts
It returns the discounts as a percentage, depending on the player's proficiency

**value**: value number of points achieved in profession

**@return**: table returns the discounts corresponding to the level
```lua
exports.e_core:getDiscounts(value)
```

## getConfig
Returns the e_core config file

**@return**: table 
```lua
exports.e_core:getConfig()
```

## isReady

**@return**: boolean – `true` csak akkor, ha az item registry (`REGISTERED_ITEMS`) sikeresen betöltött és a core késznek tekinti magát. Betöltés alatt és timeout után `false`. Finomabb háromállapot: `eCore:isReady()` (`nil` / `false` / `true`).

```lua
if exports.e_core:isReady() then
    -- biztonságos item / súly logika
end
```

## Helper functions (hf)

There is **no** `exports.e_core:getHelper()` export. Use `getCore()` and read `.helper` (same table as `eCore.helper` inside e_core; built from `libs/helper.lua` + `libs/helper_ecore.lua`).

**@return**: table – helper methods on the core object

```lua
local eCore = exports.e_core:getCore()
local hf = eCore.helper
-- e.g. hf.trim(s), hf.isPopulatedTable(t)
```
