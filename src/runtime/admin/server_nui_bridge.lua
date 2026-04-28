--- Admin NUI bridge module (server): pure module, no side effects.
--- Net event registration is performed from `init.lua`.
local adminNui = lib.require('src/runtime/admin/nui_logic')

local M = {}

--- Registers admin NUI server bridge events.
--- @return nil
function M.registerServerEvents()
    RegisterNetEvent('e_core:nuiAdminRpc', function(requestId, data)
        adminNui.onNuiAdminRpc(source, requestId, data)
    end)
end

return M
