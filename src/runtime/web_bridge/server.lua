--- Web bridge domain (server): side-effect bootstrap only.
--- Net event registration stays here, access logic lives in `logic.lua`.
local webBridge = lib.require('src/runtime/web_bridge/logic')

RegisterNetEvent('e_core:web:requestOpen', function()
    webBridge.onWebRequestOpen(source)
end)
