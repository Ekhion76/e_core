-- Check setting values
-- `Config.operator` -> synthesized `Config.web` (admin NUI),
-- `Config.integrityCheck` (integrity/admin Integrity tab), and `Config.adminApi`.

--- Cooldown between two **full** integrity runs (without `onlyStep`);
--- can be overridden by `operator.integrityCheck.cooldownMs`.
local INTEGRITY_COOLDOWN_MIN_MS = 1500
local INTEGRITY_COOLDOWN_DEFAULT_MS = 1500

--- Auto-generated annotation. Refine behavior details if needed.
--- @param list any
--- @return any result
local function copyIdList(list)
    if not hf.isPopulatedTable(list) then
        return {}
    end
    local out = {}
    for _, v in ipairs(list) do
        if type(v) == 'string' and hf.trim(v) ~= '' then
            out[#out + 1] = hf.trim(v)
        end
    end
    return out
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function applyOperatorConfig()
    local op = hf.isPopulatedTable(Config.operator) and Config.operator or nil
    if not op then
        return false
    end

    local ids = copyIdList(op.identifiers)
    --- Admin NUI (`ecore_admin`): new `operator.admin`, legacy `operator.web`.
    local admin = hf.isPopulatedTable(op.admin) and op.admin or hf.isPopulatedTable(op.web) and op.web or nil
    if not hf.isPopulatedTable(admin) then
        admin = { enabled = true, command = 'ecore_admin', acePermission = 'ecore.admin' }
    end
    --- Integrity: new `operator.integrityCheck`, legacy `operator.diagnostics`.
    local integ = hf.isPopulatedTable(op.integrityCheck) and op.integrityCheck
        or hf.isPopulatedTable(op.diagnostics) and op.diagnostics
        or nil
    if not hf.isPopulatedTable(integ) then
        integ = { enabled = true, acePermission = 'ecore.diagnostics' }
    end

    Config.web = {
        enabled = admin.enabled == true,
        command = tostring(admin.command or 'ecore_admin'):gsub('^%s+', ''):gsub('%s+$', ''),
        acePermission = type(admin.acePermission) == 'string' and admin.acePermission or '',
        allowedIdentifiers = ids,
    }
    if Config.web.command == '' then
        Config.web.command = 'ecore_admin'
    end
    if Config.web.acePermission == '' then
        Config.web.acePermission = 'ecore.admin'
    end

    Config.integrityCheck = {
        enabled = integ.enabled == true,
        acePermission = type(integ.acePermission) == 'string' and integ.acePermission or '',
        allowedIdentifiers = ids,
        cooldownMs = tonumber(integ.cooldownMs),
    }

    local api = hf.isPopulatedTable(op.adminApi) and op.adminApi or {}
    local cleanup = hf.isPopulatedTable(op.cleanup) and op.cleanup or hf.isPopulatedTable(api.cleanup) and api.cleanup or {}
    local diagApi = hf.isPopulatedTable(op.registryDiagnostics) and op.registryDiagnostics
        or hf.isPopulatedTable(api.diagnostics) and api.diagnostics
        or {}
    local denied = hf.isPopulatedTable(op.deniedAudit) and op.deniedAudit or hf.isPopulatedTable(api.deniedAudit) and api.deniedAudit or {}

    Config.adminApi = {
        cleanup = {
            acePermission = tostring(cleanup.acePermission or 'ecore.admin.cleanup'),
            allowedIdentifiers = hf.isPopulatedTable(cleanup.allowedIdentifiers) and copyIdList(cleanup.allowedIdentifiers)
                or copyIdList(ids),
            allowServerWithoutSource = cleanup.allowServerWithoutSource ~= false,
        },
        diagnostics = {
            acePermission = tostring(diagApi.acePermission or 'ecore.admin.diagnostics'),
            allowedIdentifiers = hf.isPopulatedTable(diagApi.allowedIdentifiers) and copyIdList(diagApi.allowedIdentifiers)
                or copyIdList(ids),
            allowServerWithoutSource = diagApi.allowServerWithoutSource ~= false,
        },
        deniedAudit = {
            enabled = denied.enabled ~= false,
            retentionDays = tonumber(denied.retentionDays) or 30,
            purgeIntervalMinutes = tonumber(denied.purgeIntervalMinutes) or 60,
            maxDeletePerRun = tonumber(denied.maxDeletePerRun) or 2000,
        },
    }

    return true
end

--- Client/server shared fixed defaults for integrity runs
--- (`Config.integrityCheck`, with NUI-overridable runtime fields).
local function applyIntegrityCheckFixedDefaults()
    local cd = tonumber(Config.integrityCheck.cooldownMs)
    if cd == nil then
        Config.integrityCheck.cooldownMs = INTEGRITY_COOLDOWN_DEFAULT_MS
    else
        Config.integrityCheck.cooldownMs = math.max(INTEGRITY_COOLDOWN_MIN_MS, cd)
    end
    Config.integrityCheck.testItem = 'water'
    Config.integrityCheck.testItemAmount = 1
    Config.integrityCheck.tryAddRemove = true
    Config.integrityCheck.progressDurationMs = 3000
    Config.integrityCheck.useNui = true
    Config.integrityCheck.printToConsole = false
    Config.integrityCheck.uiStepMs = 55
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
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

    if not applyOperatorConfig() then
        --- Legacy mapping: `Config.diagnostics` -> `Config.integrityCheck`
        --- (temporary breaking transition for one override cycle).
        local legacyDiag = hf.isPopulatedTable(Config.diagnostics) and Config.diagnostics or {}
        Config.integrityCheck = hf.isPopulatedTable(Config.integrityCheck) and Config.integrityCheck or {}
        for k, v in pairs(legacyDiag) do
            if Config.integrityCheck[k] == nil then
                Config.integrityCheck[k] = v
            end
        end
        --- Legacy `command` (e.g. ecore_diag) no longer registers a command;
        --- execution moved to admin NUI Integrity tab.
        Config.integrityCheck.command = nil
        Config.integrityCheck.acePermission = type(Config.integrityCheck.acePermission) == 'string' and Config.integrityCheck.acePermission or ''
        Config.integrityCheck.allowedIdentifiers = hf.isPopulatedTable(Config.integrityCheck.allowedIdentifiers)
                and Config.integrityCheck.allowedIdentifiers
            or {}
        Config.integrityCheck.enabled = Config.integrityCheck.enabled == true

        Config.web = hf.isPopulatedTable(Config.web) and Config.web or {}
        Config.web.enabled = Config.web.enabled == true
        Config.web.command = tostring(Config.web.command or 'ecore_admin'):gsub('^%s+', ''):gsub('%s+$', '')
        if Config.web.command == '' then
            Config.web.command = 'ecore_admin'
        end
        Config.web.acePermission = type(Config.web.acePermission) == 'string' and Config.web.acePermission or ''
        if Config.web.acePermission == '' then
            Config.web.acePermission = 'ecore.admin'
        end
        Config.web.allowedIdentifiers = hf.isPopulatedTable(Config.web.allowedIdentifiers) and Config.web.allowedIdentifiers
            or {}

        Config.adminApi = hf.isPopulatedTable(Config.adminApi) and Config.adminApi or {}
        Config.adminApi.cleanup = hf.isPopulatedTable(Config.adminApi.cleanup) and Config.adminApi.cleanup or {}
        Config.adminApi.diagnostics = hf.isPopulatedTable(Config.adminApi.diagnostics) and Config.adminApi.diagnostics or {}
        Config.adminApi.deniedAudit = hf.isPopulatedTable(Config.adminApi.deniedAudit) and Config.adminApi.deniedAudit or {}
    end

    applyIntegrityCheckFixedDefaults()
end

configCheck()
