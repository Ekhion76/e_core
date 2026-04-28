--- Admin domain (client): side-effect bootstrap only.
--- Event/NUI callback registrations stay here, RPC behavior lives in `client_nui_logic.lua`.
local adminNui = lib.require('src/runtime/admin/client_nui_logic')

RegisterNetEvent('e_core:nuiAdminRpcResult', function(requestId, result)
    adminNui.onNuiAdminRpcResult(requestId, result)
end)

RegisterNUICallback('eCoreAdminApi', function(data, cb)
    adminNui.onNuiAdminApi(data, cb)
end)
