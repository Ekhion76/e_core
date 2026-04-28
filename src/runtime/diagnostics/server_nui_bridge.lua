--- Diagnostics NUI bridge module (server): pure module, no side effects.
--- Net event registration is performed from `init.lua`.
local diagnosticsNui = lib.require('src/runtime/diagnostics/nui_logic')

local M = {}

--- Registers diagnostics NUI server bridge events.
--- @return nil
function M.registerServerEvents()
    RegisterNetEvent('e_core:nuiDiagnosticsRpc', function(requestId, data)
        diagnosticsNui.onNuiDiagnosticsRpc(source, requestId, data)
    end)
end

return M
