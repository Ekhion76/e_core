--- Szerver oldali `exports.e_core:*` névsor = ez a fájl (szerződés: `docs/PUBLIC_API_HU.md` §3).
--- Nincs üzleti logika: közvetlen hivatkozás a `server/*.lua` függvényekre; `getConfig` / `isReady` / `getDbSchemaVersion` vékony burkoló.
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


--- @return table returns the e_core config file
exports("getConfig", function()

    return Config
end)

--- @return boolean true only when item registry finished loading successfully
exports('isReady', function()

    return eCore:isReady() == true
end)

--- @return number alkalmazott DB migráció legnagyobb `id` (0 ha még nincs tábla / üres)
exports('getDbSchemaVersion', function()

    return e_core_get_applied_migration_id()
end)