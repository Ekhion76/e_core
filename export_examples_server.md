# SERVER SIDE EXPORTS

## getLabor
Returns the player's labor points

**playerId**: number (source)

**@return**: number, nil | boolean, string (reason)
```lua
exports.e_core:getLabor(playerId)
```

## setLabor

**playerId**: number (source)

**amount**: number of labor points

**@return**: boolean success and, in case of an error, the reason as well
```lua
exports.e_core:setLabor(playerId, amount)
```

## removeLabor

**playerId**: number (source)

**amount**: number of labor points

**@return**: boolean success and, in case of an error, the reason as well
```lua
exports.e_core:removeLabor(playerId, amount)
```

## addLabor

**playerId**: number (source)

**amount**: number of labor points

**@return**: boolean success and, in case of an error, the reason as well
```lua
exports.e_core:addLabor(playerId, amount)
```

## registerMeta

Register metadata if not exists. Adds the new keys to the given category.
If the meta key already exists, it will not overwrite or delete existing meta keys.

**playerId**: number (source)

**category**: string *eg.: crafting, reputation, harvesting, special, ...*

**defaultValue**: table *key => value pairs, eg.: {cooking = 0, weaponry = 0}*

**@return**: boolean success and, in case of an error, the reason as well
```lua
exports.e_core:registerMeta(playerId, category, defaultValue)
```

## getMeta
Returns all elements of the category. If no meta key is specified, the entire meta database is returned.

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

**@return**: table *returns the discounts corresponding to the level*
```lua
exports.e_core:getDiscounts(value)
```

## ability
General function for querying and manipulating metadata. 
It can be used by itself and by the wrapper functions below.

It only works with already existing metadata, the category and the meta name are also required

**playerId**: number (required) (source)

**category**: string (required) *eg.: crafting, reputation, harvesting, special, ...*

**name**: string (required) *eg.: weaponry*

**value**: any value (required)

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

**@return**: number – alkalmazott DB migrációk közül a legnagyobb `id` (`e_core_migrations` tábla). **0** ha üres vagy a tábla még nem létezik. Részlet: `docs/DB_MIGRATIONS_HU.md`.

```lua
local v = exports.e_core:getDbSchemaVersion()
-- indulás után tipikusan 1 (egyetlen migráció a repóban); új migráció = nagyobb szám
```
