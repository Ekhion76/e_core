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

**values**: table *key => value pairs, eg.: {cooking = 0, weaponry = 0}*

**@return**: boolean success and, in case of an error, the reason as well
```lua
exports.e_core:registerMeta(playerId, category, amount)
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

**operation**: string (required) *(add | remove | get | set)*

**category**: string (required) *eg.: crafting, reputation, harvesting, special, ...*

**name**: string (required) *eg.: weaponry*

**value**: any value  (required)

**@return**: boolean success and, in case of an error, the reason as well

```lua
exports.e_core:ability(playerId, operation, category, name, value)
```

The additional exports are wrappers for the ability, for ease of use

Here is an example of wrapping:
```
exports.e_core("getCrafting", function(playerId, name)
    return ability(playerId, 'get', 'crafting', name)
end)
```
**ability wrappers for crafting**

```lua
exports.e_core:getCrafting(playerId, name)
exports.e_core:addCrafting(playerId, name, value)
exports.e_core:removeCrafting(playerId, name, value)
exports.e_core:setCrafting(playerId, name, value)
```

**ability wrappers for harvesting**

```lua
exports.e_core:getHarvesting(playerId, name)
exports.e_core:addHarvesting(playerId, name, value)
exports.e_core:removeHarvesting(playerId, name, value)
exports.e_core:setHarvesting(playerId, name, value)
```

**ability wrappers for reputation**

```lua
exports.e_core:getReputation(playerId, name)
exports.e_core:addReputation(playerId, name, value)
exports.e_core:removeReputation(playerId, name, value)
exports.e_core:setReputation(playerId, name, value)
```


## getConfig
Returns the e_core config file

**@return**: table 
```lua
exports.e_core:getConfig()
```
