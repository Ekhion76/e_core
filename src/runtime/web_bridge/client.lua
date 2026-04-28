--- Web bridge domain (client): side-effect bootstrap only.
--- Event/NUI callback registrations stay here, behavior lives in `client_logic.lua`.
local webBridge = lib.require('src/runtime/web_bridge/client_logic')

RegisterNetEvent('e_core:web:open', function()
    webBridge.onWebOpen()
end)

RegisterNetEvent('e_core:web:nuiReady', function()
    webBridge.onWebNuiReady()
end)

RegisterNetEvent('e_core:web:deny', function(message)
    webBridge.onWebDeny(message)
end)

RegisterNUICallback('webAdminExit', function(_, cb)
    webBridge.onWebAdminExit(cb)
end)

CreateThread(function()
    webBridge.bootstrapWebCommand()
end)
