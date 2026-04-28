--- Professions domain (server): side effects only (DB bootstrap).
--- Loads registry defaults and resumes cleanup jobs only when feature is enabled.

local professions = lib.require('src/runtime/professions/logic')

if professions.isEnabled() then
    MySQL.ready(function()
        professions.bootstrapProfessionRegistry()
        professions.bootstrapCleanupJobs()
    end)
end

