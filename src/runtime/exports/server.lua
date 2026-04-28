--- Server-side `exports.e_core:*` registry (contract source: `docs/PUBLIC_API_HU.md` §3).
--- This file is intentionally thin: direct bindings to implementation functions.
--- No business logic should be added here.
--- exports ---
local labor = lib.require('src/runtime/labor/logic')
local quote = lib.require('src/runtime/quote/logic')
local meta = lib.require('src/runtime/meta/logic')
local professions = lib.require('src/runtime/professions/logic')
local diagnostics = lib.require('src/runtime/diagnostics/logic')
local discordLogModule = lib.require('src/imports/sdk/discord_log/server')
exports("getAbility", meta.getAbility)
exports("setAbility", meta.setAbility)
exports("addAbility", meta.addAbility)
exports("removeAbility", meta.removeAbility)

exports("getLabor", labor.getLabor)
exports("setLabor", labor.setLabor)
exports("addLabor", labor.addLabor)
exports("removeLabor", labor.removeLabor)
exports("getLaborQuote", quote.getLaborQuote)

exports("registerMeta", meta.registerMeta)
exports("getProfessionRegistry", professions.getProfessionRegistry)
exports("isValidProfession", professions.isValidProfession)
exports("getProfessionDefaults", professions.getProfessionDefaults)
exports("getProfessionLevelProfile", professions.getProfessionLevelProfile)
exports("validateProfessionKeys", professions.validateProfessionKeys)
exports("professionAdminList", professions.professionAdminList)
exports("professionAdminCreate", professions.professionAdminCreate)
exports("professionAdminUpdate", professions.professionAdminUpdate)
exports("professionAdminSetEnabled", professions.professionAdminSetEnabled)
exports("professionAdminDelete", professions.professionAdminDelete)
exports("professionAdminDeleteDryRun", professions.professionAdminDeleteDryRun)
exports("professionAdminDeleteApply", professions.professionAdminDeleteApply)
exports("professionAdminCleanupJobList", professions.professionAdminCleanupJobList)
exports("professionAdminCleanupJobGet", professions.professionAdminCleanupJobGet)
exports("professionAdminCleanupJobAbort", professions.professionAdminCleanupJobAbort)
exports("professionAdminCleanupJobResume", professions.professionAdminCleanupJobResume)
exports("professionAdminAuditList", professions.professionAdminAuditList)
exports("adminDenied", adminDenied)
exports("adminDeniedAuditList", adminDeniedAuditList)
exports("adminDeniedAuditPurge", adminDeniedAuditPurge)
exports("levelProfileAdminList", professions.levelProfileAdminList)
exports("levelProfileAdminCreate", professions.levelProfileAdminCreate)
exports("levelProfileAdminUpdate", professions.levelProfileAdminUpdate)
exports("levelProfileAdminDelete", professions.levelProfileAdminDelete)
exports("diagnosticsAdminListTests", diagnostics.diagnosticsAdminListTests)
exports("diagnosticsAdminListRuns", diagnostics.diagnosticsAdminListRuns)
exports("diagnosticsAdminRun", diagnostics.diagnosticsAdminRun)
exports("diagnosticsAdminGetRun", diagnostics.diagnosticsAdminGetRun)
exports("diagnosticsAdminCancelRun", diagnostics.diagnosticsAdminCancelRun)

exports("getMeta", meta.getMeta)
exports("setMeta", meta.setMeta)

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

--- Creates a new Discord log builder instance.
--- @param webhook string
--- @param botName string|nil
--- @param opts table|nil
--- @return table|false
exports('createDiscordLog', function(webhook, botName, opts)
    return discordLogModule.createDiscordLog(webhook, botName, opts)
end)