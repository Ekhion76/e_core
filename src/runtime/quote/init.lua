--- Quote domain init (server): side effects only (cache invalidation event hooks).

local quote = lib.require('src/runtime/quote/logic')

AddEventHandler('playerDropped', function()
    quote.invalidateLaborQuoteCache(source)
end)

AddEventHandler('e_core:playerUnload', function(playerId)
    quote.invalidateLaborQuoteCache(playerId)
end)
