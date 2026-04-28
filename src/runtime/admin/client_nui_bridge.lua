--- Admin NUI bridge module (client): pure module, no side effects.
--- Event/NUI registrations are performed from `init_client.lua`.
local adminNui = lib.require('src/runtime/admin/client_nui_logic')

local M = {}

--- Registers admin NUI client bridge handlers.
--- @return nil
function M.registerClientHandlers()
    RegisterNetEvent('e_core:nuiAdminRpcResult', function(requestId, result)
        adminNui.onNuiAdminRpcResult(requestId, result)
    end)

    RegisterNUICallback('eCoreAdminApi', function(data, cb)
        adminNui.onNuiAdminApi(data, cb)
    end)
end

return M
