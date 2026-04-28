--- Server-side `exports.e_core:*` registry (contract source: `docs/PUBLIC_API_HU.md` §3).
--- This file is intentionally thin: direct bindings to implementation functions.
--- No business logic should be added here.
--- exports ---
local labor = lib.require('src/runtime/labor/logic')
local function professionsEnabled()
    return Config.systemMode.profession == true and Config.systemMode.labor == true
end

local function disabledBool()
    return false, eCoreErr.feature_disabled
end

local function disabledAdminResponse()
    return {
        ok = false,
        code = eCoreErr.feature_disabled,
        message = 'Feature disabled.',
        data = {},
    }
end
exports("getAbility", getAbility)
exports("setAbility", setAbility)
exports("addAbility", addAbility)
exports("removeAbility", removeAbility)

exports("getLabor", labor.getLabor)
exports("setLabor", labor.setLabor)
exports("addLabor", labor.addLabor)
exports("removeLabor", labor.removeLabor)
exports("getLaborQuote", getLaborQuote)

exports("registerMeta", registerMeta)
exports("getProfessionRegistry", function(...)
    if not professionsEnabled() then return disabledBool() end
    return getProfessionRegistry(...)
end)
exports("isValidProfession", function(...)
    if not professionsEnabled() then return disabledBool() end
    return isValidProfession(...)
end)
exports("getProfessionDefaults", function(...)
    if not professionsEnabled() then return disabledBool() end
    return getProfessionDefaults(...)
end)
exports("getProfessionLevelProfile", function(...)
    if not professionsEnabled() then return disabledBool() end
    return getProfessionLevelProfile(...)
end)
exports("validateProfessionKeys", function(...)
    if not professionsEnabled() then return disabledBool() end
    return validateProfessionKeys(...)
end)
exports("professionAdminList", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminList(...)
end)
exports("professionAdminCreate", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminCreate(...)
end)
exports("professionAdminUpdate", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminUpdate(...)
end)
exports("professionAdminSetEnabled", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminSetEnabled(...)
end)
exports("professionAdminDelete", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminDelete(...)
end)
exports("professionAdminDeleteDryRun", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminDeleteDryRun(...)
end)
exports("professionAdminDeleteApply", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminDeleteApply(...)
end)
exports("professionAdminCleanupJobList", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminCleanupJobList(...)
end)
exports("professionAdminCleanupJobGet", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminCleanupJobGet(...)
end)
exports("professionAdminCleanupJobAbort", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminCleanupJobAbort(...)
end)
exports("professionAdminCleanupJobResume", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminCleanupJobResume(...)
end)
exports("professionAdminAuditList", function(...)
    if not professionsEnabled() then return disabledAdminResponse() end
    return professionAdminAuditList(...)
end)
exports("adminDenied", adminDenied)
exports("adminDeniedAuditList", adminDeniedAuditList)
exports("adminDeniedAuditPurge", adminDeniedAuditPurge)
exports("levelProfileAdminList", levelProfileAdminList)
exports("levelProfileAdminCreate", levelProfileAdminCreate)
exports("levelProfileAdminUpdate", levelProfileAdminUpdate)
exports("levelProfileAdminDelete", levelProfileAdminDelete)
exports("diagnosticsAdminListTests", diagnosticsAdminListTests)
exports("diagnosticsAdminListRuns", diagnosticsAdminListRuns)
exports("diagnosticsAdminRun", diagnosticsAdminRun)
exports("diagnosticsAdminGetRun", diagnosticsAdminGetRun)
exports("diagnosticsAdminCancelRun", diagnosticsAdminCancelRun)

exports("getMeta", getMeta)
exports("setMeta", setMeta)

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

    return eCore:isReady()
end)

--- Returns the highest applied DB migration id.
--- @return number migrationId Highest applied migration id (0 when table is empty/missing).
exports('getDbSchemaVersion', function()

    return e_core_get_applied_migration_id()
end)