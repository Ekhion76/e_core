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
    Config.progression = hf.isPopulatedTable(Config.progression) and Config.progression or {}
    Config.progression.maxByProfession = hf.isPopulatedTable(Config.progression.maxByProfession)
        and Config.progression.maxByProfession
        or {}

    Config.laborIncreaseTime = tonumber(Config.laborIncreaseTime) or 0
    Config.laborIncrease = tonumber(Config.laborIncrease) or 0
    Config.laborIncreaseOffline = tonumber(Config.laborIncreaseOffline) or 0

    Config.keyBind = hf.isPopulatedTable(Config.keyBind) and Config.keyBind or {}

    Config.discordBotName = Config.discordBotName or 'ECOBOT'
    Config.discordWebHook = hf.isPopulatedTable(Config.discordWebHook) and Config.discordWebHook or {}

    Config.diagnostics = hf.isPopulatedTable(Config.diagnostics) and Config.diagnostics or {}
    Config.diagnostics.command = tostring(Config.diagnostics.command or 'ecore_diag'):gsub('^%s+', ''):gsub('%s+$', '')
    if Config.diagnostics.command == '' then
        Config.diagnostics.command = 'ecore_diag'
    end
    Config.diagnostics.acePermission = type(Config.diagnostics.acePermission) == 'string' and Config.diagnostics.acePermission or ''
    Config.diagnostics.allowedIdentifiers = hf.isPopulatedTable(Config.diagnostics.allowedIdentifiers)
        and Config.diagnostics.allowedIdentifiers
        or {}
    Config.diagnostics.cooldownMs = math.max(3000, tonumber(Config.diagnostics.cooldownMs) or 15000)
    Config.diagnostics.testItem = tostring(Config.diagnostics.testItem or 'water'):lower()
    Config.diagnostics.testItemAmount = math.max(1, tonumber(Config.diagnostics.testItemAmount) or 1)
    Config.diagnostics.tryAddRemove = Config.diagnostics.tryAddRemove == true
    Config.diagnostics.progressDurationMs = math.max(1000, math.min(60000, tonumber(Config.diagnostics.progressDurationMs) or 3000))
    Config.diagnostics.enabled = Config.diagnostics.enabled == true
    Config.diagnostics.useNui = Config.diagnostics.useNui ~= false
    Config.diagnostics.printToConsole = Config.diagnostics.printToConsole == true
    Config.diagnostics.uiStepMs = math.max(0, math.min(400, tonumber(Config.diagnostics.uiStepMs) or 55))

    Config.adminHttp = hf.isPopulatedTable(Config.adminHttp) and Config.adminHttp or {}
    Config.adminHttp.enabled = Config.adminHttp.enabled ~= false
    Config.adminHttp.read = hf.isPopulatedTable(Config.adminHttp.read) and Config.adminHttp.read or {}
    Config.adminHttp.read.identifierHeader = tostring(Config.adminHttp.read.identifierHeader or 'x-ecore-identifier')
    Config.adminHttp.read.tokenHeader = tostring(Config.adminHttp.read.tokenHeader or 'x-ecore-token')
    Config.adminHttp.read.allowedIdentifiers = hf.isPopulatedTable(Config.adminHttp.read.allowedIdentifiers)
        and Config.adminHttp.read.allowedIdentifiers
        or {}
    Config.adminHttp.read.token = tostring(Config.adminHttp.read.token or '')
end

configCheck()