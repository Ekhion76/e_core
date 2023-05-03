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