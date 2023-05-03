--- exports ---
exports("getAbility", getAbility)
exports("setAbility", setAbility)
exports("addAbility", addAbility)
exports("removeAbility", removeAbility)

exports("getLabor", getLabor)
exports("setLabor", setLabor)
exports("addLabor", addLabor)
exports("removeLabor", removeLabor)

exports("registerMeta", registerMeta)

exports("getMeta", getMeta)
exports("setMeta", setMeta)

--- SHARED exports --
exports('getLevel', getLevel)
exports('getDiscounts', getDiscounts)


--- @return table returns the e_core config file
exports("getConfig", function()

    return Config
end)