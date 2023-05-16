# e_core

#### What is e_core for?
The e_core is an adapter that provides support for compatibility with ESX and QBCore, QBox frameworks.

##### Its goal:
- to ensure framework-independent operation for eco_crafting and future scripts
- to provide users with customization

##### It provides a connecting surface:
- to insert your own inventory functions/exports (addItem, removeItem, etc..)
- for inserting message systems (sendNotify, drawText, hideText, progressbar)
- in addition, various core functions can be adapted using the examples shown in the script

##### Contain:
- a skill (xp) and labor system that uses a built-in metadata repository.
- lua helper functions
- fiveM utility functions

If you have a basic server, no changes are necessary.
If you use ox_inventory, no changes are needed.

**IMPORTANT!** Due to the overwriting of later updates, it is advisable to make all changes in the 'standalone' folder!
The 'standalone' folder is nothing more than a collection of override functions. All functions in the bridge folder can be copied to the 'standalone' folder and overwritten there.
**IMPORTANT!** Copy the bridge functions to the 'standalone' folder and overwrite them! (of course only if necessary)

Example of customization:

```lua
    function eCore:sendMessage(message, mType, mSec) -- bridge/esx/client.lua

        ESX.ShowNotification(message, mSec, mType)
    end

    --- OVERRIDE a standalone mappában:
    
    function eCore:sendMessage(message, mType, mSec) -- standalone/overrides/core/client.lua

        PELDA.SajatUzenom(message, mSec, mType)
    end
```
Example of overriding an inventory function:
```lua
    function eCore:removeItem(xPlayer, item, count, metadata, slot) -- bridge/esx/server.lua
    
        xPlayer.removeInventoryItem(item, count, metadata, slot)
    end

    --- OVERRIDE a standalone mappában:
    
    function eCore:removeItem(xPlayer, item, count, metadata, slot) -- standalone/overrides/avp_grid_inventory/server.lua
    
        return exports["avp_grid_inventory"]:RemoveItemBy(xPlayer.source, count, item)
    end
```
## Labor and skill system:

The concept works along the lines of the ArcheAge MMORPG. Completing each job costs labor points, which also increases the character's skill.

For example, if you harvest a vegetable with my collecting script, it costs 5 lab points and it is added to the harvesting skill. This way, you can later receive discounts according to the rank setting, for example: faster harvesting, for fewer work points.

In the crafting system, it can be set that an item can only be produced after acquiring a certain skill and how many labor points it costs to make it.

With the help of exports, you can incorporate this into any of your own scripts. See:

-- export_examples_server.md

-- export_examples_client.md
