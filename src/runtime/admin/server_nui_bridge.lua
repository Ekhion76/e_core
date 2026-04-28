--- Admin domain (server): side-effect bootstrap only.
--- Net event registration stays here, domain logic lives in `nui_logic.lua`.
local adminNui = lib.require('src/runtime/admin/nui_logic')

RegisterNetEvent('e_core:nuiAdminRpc', function(requestId, data)
    adminNui.onNuiAdminRpc(source, requestId, data)
end)
