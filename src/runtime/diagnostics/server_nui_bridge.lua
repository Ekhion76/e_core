--- Diagnostics domain (server): side-effect bootstrap only.
--- Net event registration stays here, diagnostics RPC logic lives in `nui_logic.lua`.
local diagnosticsNui = lib.require('src/runtime/diagnostics/nui_logic')

RegisterNetEvent('e_core:nuiDiagnosticsRpc', function(requestId, data)
    diagnosticsNui.onNuiDiagnosticsRpc(source, requestId, data)
end)
