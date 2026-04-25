--- Server-side `exports.e_core:*` registry (contract source: `docs/PUBLIC_API_HU.md` §3).
--- This file is intentionally thin: direct bindings to implementation functions.
--- No business logic should be added here.
--- exports ---
exports("getAbility", getAbility)
exports("setAbility", setAbility)
exports("addAbility", addAbility)
exports("removeAbility", removeAbility)

exports("getLabor", getLabor)
exports("setLabor", setLabor)
exports("addLabor", addLabor)
exports("removeLabor", removeLabor)
exports("getLaborQuote", getLaborQuote)

exports("registerMeta", registerMeta)
exports("getProfessionRegistry", getProfessionRegistry)
exports("isValidProfession", isValidProfession)
exports("getProfessionDefaults", getProfessionDefaults)
exports("getProfessionLevelProfile", getProfessionLevelProfile)
exports("validateProfessionKeys", validateProfessionKeys)
exports("professionAdminList", professionAdminList)
exports("professionAdminCreate", professionAdminCreate)
exports("professionAdminUpdate", professionAdminUpdate)
exports("professionAdminSetEnabled", professionAdminSetEnabled)
exports("professionAdminDelete", professionAdminDelete)
exports("professionAdminDeleteDryRun", professionAdminDeleteDryRun)
exports("professionAdminDeleteApply", professionAdminDeleteApply)
exports("professionAdminCleanupJobList", professionAdminCleanupJobList)
exports("professionAdminCleanupJobGet", professionAdminCleanupJobGet)
exports("professionAdminCleanupJobAbort", professionAdminCleanupJobAbort)
exports("professionAdminCleanupJobResume", professionAdminCleanupJobResume)
exports("professionAdminAuditList", professionAdminAuditList)
exports("adminApiDeniedAuditList", adminApiDeniedAuditList)
exports("adminApiDeniedAuditPurge", adminApiDeniedAuditPurge)
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

    return eCore:isReady() == true
end)

--- Returns the highest applied DB migration id.
--- @return number migrationId Highest applied migration id (0 when table is empty/missing).
exports('getDbSchemaVersion', function()

    return e_core_get_applied_migration_id()
end)