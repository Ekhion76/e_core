# e_core

Experimental project.

It is an adapter for compatibility with ESX and QBCore frameworks and includes skill and lab system and helper functions.


Its purpose is to bring the functions of different frameworks to a common denominator.

import into fxmanifest.lua file:

```lua
shared_scripts {
     '@e_core/imports.lua'
}
```

imports.lua loads the current framework.
You don't need the es_extended import.lua file!

The user manual is not ready even because I am constantly modifying the functions, which may affect the structure.

I will describe two examples to show the intention:

```lua
local hf = eCore.helper

eCore.isLoggedIn()

eCore.createUsableItem("portable_chemist", function(source, item)

end)


eCore.triggerCallback('eco_crafting:serverSync', function(portableWorkstations, aceAllowed, inventoryLimits)
end)

eCore.createCallback('eco_crafting:serverSync', function(source, cb)

end)
```

If you use eCore features, your script will be portable. 
It would be even better if there were already a similar initiative to bring the frameworks to a common denominator. For now, this initiative is based on the needs of my own scripts.
