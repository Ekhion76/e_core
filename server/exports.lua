--- exports ---
exports("getLabor", getLabor)
exports("setLabor", setLabor)
exports("removeLabor", removeLabor)
exports("addLabor", addLabor)
exports("registerMeta", registerMeta)
exports("getMeta", getMeta)
exports("setMeta", setMeta)

--- SHARED exports --

exports('getLevel', getLevel)
exports('getDiscounts', getDiscounts)

-------------------
--- PROFICIENCY ---
-------------------

exports("ability", ability)
exports("getCrafting", function(playerId, name)

    return ability(playerId, 'get', 'crafting', name)
end)

exports("addCrafting", function(playerId, name, value)

    return ability(playerId, 'add', 'crafting', name, value)
end)

exports("removeCrafting", function(playerId, name, value)

    return ability(playerId, 'remove', 'crafting', name, value)
end)

exports("setCrafting", function(playerId, name, value)

    return ability(playerId, 'set', 'crafting', name, value)
end)

------------------
--- HARVESTING ---
------------------

exports("getHarvesting", function(playerId, name)

    return ability(playerId, 'get', 'harvesting', name)
end)

exports("addHarvesting", function(playerId, name, value)

    return ability(playerId, 'add', 'harvesting', name, value)
end)

exports("removeHarvesting", function(playerId, name, value)

    return ability(playerId, 'remove', 'harvesting', name, value)
end)

exports("setHarvesting", function(playerId, name, value)

    return ability(playerId, 'set', 'harvesting', name, value)
end)

------------------
--- REPUTATION ---
------------------

exports("getReputation", function(playerId, name)

    return ability(playerId, 'get', 'reputation', name)
end)

exports("addReputation", function(playerId, name, value)

    return ability(playerId, 'add', 'reputation', name, value)
end)

exports("removeReputation", function(playerId, name, value)

    return ability(playerId, 'remove', 'reputation', name, value)
end)

exports("setReputation", function(playerId, name, value)

    return ability(playerId, 'set', 'reputation', name, value)
end)

--- @return table returns the e_core config file
exports("getConfig", function()

    return Config
end)