--- Professions domain (server): side effects only (DB bootstrap).
--- Loads registry defaults and resumes cleanup jobs only when feature is enabled.

local function professionsEnabled()
    return Config.systemMode.profession == true and Config.systemMode.labor == true
end

if professionsEnabled() then
    MySQL.ready(function()
        -- Registry seed / ensure defaults.
        if type(e_core_bootstrap_profession_registry) == 'function' then
            e_core_bootstrap_profession_registry()
        end

        -- Resume persisted cleanup jobs (optional).
        if type(e_core_bootstrap_cleanup_jobs) == 'function' then
            e_core_bootstrap_cleanup_jobs()
        end
    end)
end

