--- Diagnostics NUI bridge module (client): pure module, no side effects.
--- Event/NUI registrations are performed from `init_client.lua`.
local diagnosticsNui = lib.require('src/runtime/diagnostics/client_nui_logic')

local M = {}

--- Registers diagnostics NUI client bridge handlers.
--- @return nil
function M.registerClientHandlers()
    RegisterNetEvent('e_core:nuiDiagnosticsRpcResult', function(requestId, result)
        diagnosticsNui.onNuiDiagnosticsRpcResult(requestId, result)
    end)

    RegisterNUICallback('eCoreDiagnosticsApi', function(data, cb)
        diagnosticsNui.onNuiDiagnosticsApi(data, cb)
    end)
end

return M
