--- Professions domain module facade.
--- Pure module contract: no side effects (bootstrap is triggered from init.lua).
--- Delegates to `server.lua` implementation via a returned module table.

local M = {}
local impl = lib.require('src/runtime/professions/server')

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

--- @return boolean ok
--- @return string|nil err
function M.ensureEnabled()
    if not professionsEnabled() then
        return false, eCoreErr.feature_disabled
    end
    return true, nil
end

--- @return boolean
function M.isEnabled()
    return professionsEnabled()
end

--- @return boolean
function M.bootstrapProfessionRegistry()
    if not professionsEnabled() then
        return false
    end
    if type(impl.bootstrapProfessionRegistry) == 'function' then
        return impl.bootstrapProfessionRegistry()
    end
    return false
end

--- @return boolean
function M.bootstrapCleanupJobs()
    if not professionsEnabled() then
        return false
    end
    if type(impl.bootstrapCleanupJobs) == 'function' then
        impl.bootstrapCleanupJobs()
        return true
    end
    return false
end

function M.getProfessionRegistry(...)
    if not professionsEnabled() then
        return disabledBool()
    end
    return impl.getProfessionRegistry(...)
end

function M.isValidProfession(...)
    if not professionsEnabled() then
        return disabledBool()
    end
    return impl.isValidProfession(...)
end

function M.getProfessionDefaults(...)
    if not professionsEnabled() then
        return disabledBool()
    end
    return impl.getProfessionDefaults(...)
end

function M.getProfessionLevelProfile(...)
    if not professionsEnabled() then
        return disabledBool()
    end
    return impl.getProfessionLevelProfile(...)
end

function M.validateProfessionKeys(...)
    if not professionsEnabled() then
        return disabledBool()
    end
    return impl.validateProfessionKeys(...)
end

function M.professionAdminList(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminList(...)
end

function M.professionAdminCreate(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminCreate(...)
end

function M.professionAdminUpdate(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminUpdate(...)
end

function M.professionAdminSetEnabled(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminSetEnabled(...)
end

function M.professionAdminDelete(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminDelete(...)
end

function M.professionAdminDeleteDryRun(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminDeleteDryRun(...)
end

function M.professionAdminDeleteApply(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminDeleteApply(...)
end

function M.professionAdminCleanupJobList(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminCleanupJobList(...)
end

function M.professionAdminCleanupJobGet(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminCleanupJobGet(...)
end

function M.professionAdminCleanupJobAbort(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminCleanupJobAbort(...)
end

function M.professionAdminCleanupJobResume(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminCleanupJobResume(...)
end

function M.professionAdminAuditList(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.professionAdminAuditList(...)
end

function M.levelProfileAdminList(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.levelProfileAdminList(...)
end

function M.levelProfileAdminCreate(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.levelProfileAdminCreate(...)
end

function M.levelProfileAdminUpdate(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.levelProfileAdminUpdate(...)
end

function M.levelProfileAdminDelete(...)
    if not professionsEnabled() then
        return disabledAdminResponse()
    end
    return impl.levelProfileAdminDelete(...)
end

return M
