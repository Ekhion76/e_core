# CLIENT SIDE exports.e_core

## getMeta
Returns the player's entire meta database

**@return**: table
```lua
exports.e_core:getMeta()
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
- result: meta value or if the request failed then false
- reason: if the request failed, then the reason
```lua
local result, reason = exports.e_core:getAbility('crafting', 'weaponry')
```


## getCrafting, getHarvesting, getReputation
This is a sugar that makes using getAbility easier.
Query the proficiency within the Crafting category.
If no metaName is specified, the entire category is returned

**@return**: table or number

```lua
exports.e_core:getCrafting(metaName)
exports.e_core:getHarvesting(metaName)
exports.e_core:getReputation(metaName)
```
Crafting: **metaName**: string (optional) *weaponry, cooking, handicraft, chemist, etc. or none*

Harvesting: **metaName**: string (optional) *husbandry, farming, fishing, logging, gathering, mining, etc. or none*

Reputation: **metaName**: string (optional) *thief, safe_cracker, money_launderer, life_saver etc. or none*

```lua
exports.e_core:getCrafting('weaponry')
exports.e_core:getHarvesting('fishing')
exports.e_core:getReputation('life_saver')
```

## getLabor
Returns the player's labor points

**@return**: number
```lua
exports.e_core:getLabor()
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

## getHelper
Returns a table containing useful helper functions (libs/helper.lua)

**@return**: table helper functions

```lua
exports.e_core:getHelper()
```
