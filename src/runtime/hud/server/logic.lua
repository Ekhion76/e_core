--- HUD domain facade (server).
--- Pure module contract: no event registration side effects.

local M = {}
local impl = lib.require('src/runtime/hud/server/layout')

--- @param playerId number
--- @param payload table|nil
--- @return nil
function M.commitLayout(playerId, payload)
    impl.commitLayout(playerId, payload)
end

return M
