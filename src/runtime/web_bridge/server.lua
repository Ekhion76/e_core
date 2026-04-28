--- Web bridge domain module (server): pure module, no side effects.
--- Net event registration is performed from `init.lua`.
local webBridge = lib.require('src/runtime/web_bridge/logic')

local M = {}

--- Registers web bridge server net events.
--- @return nil
function M.registerServerEvents()
    RegisterNetEvent('e_core:web:requestOpen', function()
        webBridge.onWebRequestOpen(source)
    end)
end

return M
