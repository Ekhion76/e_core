--- Diagnostics domain (client): side-effect bootstrap only.
--- Event/NUI callback registrations stay here, RPC behavior lives in `client_nui_logic.lua`.
local diagnosticsNui = lib.require('src/runtime/diagnostics/client_nui_logic')

RegisterNetEvent('e_core:nuiDiagnosticsRpcResult', function(requestId, result)
    diagnosticsNui.onNuiDiagnosticsRpcResult(requestId, result)
end)

RegisterNUICallback('eCoreDiagnosticsApi', function(data, cb)
    diagnosticsNui.onNuiDiagnosticsApi(data, cb)
end)
