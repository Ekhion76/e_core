--- DB domain facade (server).
--- Pure module contract: no side effects (bootstrap is triggered from init.lua).

local M = {}
local impl = lib.require('src/runtime/db/server')

function M.saveMeta(...)
    return impl.saveMeta(...)
end

function M.saveAllMeta(...)
    return impl.saveAllMeta(...)
end

function M.loadMeta(...)
    return impl.loadMeta(...)
end

return M
