function QBCoreFunctions()

    local self = globalFunctions()
    local QBCoreShared = QBCoreSharedFunctions()

    for k, v in pairs(QBCoreShared) do

        self[k] = v
    end

    return self
end