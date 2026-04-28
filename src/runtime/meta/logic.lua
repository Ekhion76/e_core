--- Meta domain facade (server).
--- Pure module contract: no side effects (events/timers are in init.lua).

local M = {}
local impl = lib.require('src/runtime/meta/server')

function M.resolveAbilityCap(...)
    return impl.resolveAbilityCap(...)
end

function M.setMeta(...)
    return impl.setMeta(...)
end

function M.getMeta(...)
    return impl.getMeta(...)
end

function M.registerMeta(...)
    return impl.registerMeta(...)
end

function M.getAbility(...)
    return impl.getAbility(...)
end

function M.addAbility(...)
    return impl.addAbility(...)
end

function M.removeAbility(...)
    return impl.removeAbility(...)
end

function M.setAbility(...)
    return impl.setAbility(...)
end

function M.syncRequest(...)
    return impl.syncRequest(...)
end

function M.prepareMeta(...)
    return impl.prepareMeta(...)
end

function M.saveRequest(...)
    return impl.saveRequest(...)
end

return M
