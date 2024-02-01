-- Check setting values
function configCheck()
    Config.debugLevel = tonumber(Config.debugLevel) or false
    Config.maxInventoryWeight = tonumber(Config.maxInventoryWeight) or 24000
    Config.maxInventorySlots = tonumber(Config.maxInventorySlots) or 41

    Config.systemMode = hf.isPopulatedTable(Config.systemMode) and Config.systemMode or {}
    Config.displayComponent = hf.isPopulatedTable(Config.displayComponent) and Config.displayComponent or {}
    Config.currency = hf.isPopulatedTable(Config.currency) and Config.currency or {}
    Config.metaFields = hf.isPopulatedTable(Config.metaFields) and Config.metaFields or {}

    Config.defaultLabor = tonumber(Config.defaultLabor) or 0
    Config.laborLimit = tonumber(Config.laborLimit) or 0
    Config.abilityLimit = tonumber(Config.abilityLimit) or 0

    Config.laborIncreaseTime = tonumber(Config.laborIncreaseTime) or 0
    Config.laborIncrease = tonumber(Config.laborIncrease) or 0
    Config.laborIncreaseOffline = tonumber(Config.laborIncreaseOffline) or 0

    Config.keyBind = hf.isPopulatedTable(Config.keyBind) and Config.keyBind or {}

    Config.discordBotName = Config.discordBotName or 'ECOBOT'
    Config.discordWebHook = hf.isPopulatedTable(Config.discordWebHook) and Config.discordWebHook or {}
end

configCheck()