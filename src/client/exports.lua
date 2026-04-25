--- Client-side `exports.e_core:*` registry (contract source: `docs/PUBLIC_API_HU.md` §2).
--- This file intentionally contains thin export bindings only.
--- exports ---
exports("getAbility", getAbility)
exports("getMeta", getMeta)

--- Returns current labor points on client cache.
--- @return number labor Current labor points.
exports("getLabor", getLabor)


--- SHARED exports --

exports('getLevel', getLevel)
exports('getDiscounts', getDiscounts)

--- Returns e_core runtime configuration table.
--- @return table config Current merged `Config` table.
exports("getConfig", function()

    return Config
end)

--- Returns true when item registry load has completed successfully.
--- @return boolean ready True if core is fully ready for consumers.
exports('isReady', function()

    return eCore:isReady() == true
end)