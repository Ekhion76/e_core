--- Quote domain facade (server).
--- Pure module contract: no side effects (cache invalidation hooks live in init.lua).

local M = {}
local impl = lib.require('src/runtime/quote/server')

--- @param playerId number
--- @param context table|nil
--- @return boolean ok
--- @return table|string quoteOrErr
function M.getLaborQuote(playerId, context)
    return impl.getLaborQuote(playerId, context)
end

--- @param playerId number
--- @return nil
function M.invalidateLaborQuoteCache(playerId)
    impl.invalidateLaborQuoteCache(playerId)
end

return M
