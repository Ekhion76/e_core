--- Kliens oldali `exports.e_core:*` névsor = ez a fájl (szerződés: `docs/PUBLIC_API_HU.md` §2).
--- Nincs üzleti logika: közvetlen hivatkozás a globális implementációkra; `getConfig` és `isReady` vékony burkoló.
--- exports ---
exports("getAbility", getAbility)
exports("getMeta", getMeta)

--- @return number labor points
exports("getLabor", getLabor)


--- SHARED exports --

exports('getLevel', getLevel)
exports('getDiscounts', getDiscounts)

--- @return table returns the e_core config file
exports("getConfig", function()

    return Config
end)

--- @return boolean true only when item registry finished loading successfully
exports('isReady', function()

    return eCore:isReady() == true
end)