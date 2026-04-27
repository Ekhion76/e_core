# e_core

#### What is e_core for?
The e_core is an adapter that provides support for compatibility with ESX and QBCore, QBox frameworks.

##### Its goal:
- to ensure framework-independent operation for eco_crafting and future scripts
- to provide users with customization
- **SDK-style layer:** not merely internal glue—a documented, versioned public surface that external resources and eco scripts can rely on (API contract, changelog, supported stack matrix, predictable startup and errors)

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

Config files:
- src/standalone/config/ - global settings
- overrides/custom_inventory/config.lua - Inventory specific settings

**IMPORTANT!** Start e_core before eco scripts in `server.cfg`. Start the **legacy core** (`es_extended` or `qb-core`) before e_core so framework globals and item registry can initialise.

If both cores are running by mistake, set `setr e_core:framework "esx"` or `"qb"` (default `auto` will **error**). See `docs/FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md`.

```
    # ECO SCRIPTS
    ensure e_core
    ensure eco_crafting
```
**IMPORTANT!** To keep updates safe, do all customizations in the `overrides/` folder.
The `overrides/` folder is the customization layer. Functions from `src/bridge/` can be copied there and overridden when needed.
**IMPORTANT!** Override bridge behavior only inside `overrides/`.

#### For developers / AI and Cursor context

When starting a new chat or refactor, link or attach:

- [docs/INDEX_HU.md](docs/INDEX_HU.md) – documentation map (start here)
- [docs/PROJECT_STRUCTURE.txt](docs/PROJECT_STRUCTURE.txt) – folder roles and file tree
- [docs/PUBLIC_API_HU.md](docs/PUBLIC_API_HU.md) – public `exports.e_core:*` + `eCore:` contract
- [docs/AI_SUPPORT_REFERENCE_HU.txt](docs/AI_SUPPORT_REFERENCE_HU.txt) – deep reference (Hungarian) + GYIK
- [docs/SUPPORTED_STACK_MATRIX_HU.md](docs/SUPPORTED_STACK_MATRIX_HU.md) – supported stack tiers / overrides
- [docs/SZERVER_OPERATOR_CHECKLIST_HU.md](docs/SZERVER_OPERATOR_CHECKLIST_HU.md) – server operator checklist (Hungarian)
- [docs/DB_MIGRATIONS_HU.md](docs/DB_MIGRATIONS_HU.md) – MySQL migrations, `e_core_migrations`, `getDbSchemaVersion` (Hungarian)
- [docs/LUA_LS_AND_CI_HU.md](docs/LUA_LS_AND_CI_HU.md) – LuaLS, luacheck, GitHub Actions (Hungarian)

Example of customization:

```lua
    function eCore:sendMessage(message, mType, mSec) -- src/bridge/esx/client.lua

        ESX.ShowNotification(message, mSec, mType)
    end

    --- OVERRIDE in the 'overrides/core' folder:
    
    function eCore:sendMessage(message, mType, mSec) -- overrides/core/client.lua

        EXAMPLE.MyOwnNotify(message, mSec, mType)
    end
```
Example of overriding an inventory function:
```lua
    function eCore:removeItem(xPlayer, item, count, metadata, slot) -- src/bridge/esx/server.lua
    
        xPlayer.removeInventoryItem(item, count, metadata, slot)
    end

    --- OVERRIDE in the 'overrides/...' folder:
    
    function eCore:removeItem(xPlayer, item, count, metadata, slot) -- overrides/avp_grid_inventory/server.lua
    
        return exports["avp_grid_inventory"]:RemoveItemBy(xPlayer.source, count, item)
    end
```
## Labor and skill system:

The concept works along the lines of the ArcheAge MMORPG. Completing each job costs labor points, which also increases the character's skill.

For example, if you harvest a vegetable with my collecting script, it costs 5 lab points and it is added to the harvesting skill. This way, you can later receive discounts according to the rank setting, for example: faster harvesting, for fewer work points.

In the crafting system, it can be set that an item can only be produced after acquiring a certain skill and how many labor points it costs to make it.

With the help of exports, you can incorporate this into any of your own scripts. See:

- export_examples_server.md
- export_examples_client.md

The e_core uses both ESX and QBCore script details.
