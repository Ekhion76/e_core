function ESXFunctions()

    local self = globalFunctions()
    local ESXShared = ESXSharedFunctions()

    for k, v in pairs(ESXShared) do

        self[k] = v
    end



    return self
end