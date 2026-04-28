--- Web bridge domain module (client): pure module, no side effects.
--- Event/NUI registrations are performed from `init_client.lua`.
local webBridge = lib.require('src/runtime/web_bridge/client_logic')

local M = {}

--- Registers web bridge client handlers and startup command.
--- @return nil
function M.registerClientHandlers()
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
end

return M
