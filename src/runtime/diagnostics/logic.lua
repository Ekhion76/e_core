--- Diagnostics domain facade (server).
--- Pure module contract: no side effects (bootstrap/init belongs to init.lua).

local M = {}
local impl = lib.require('src/runtime/diagnostics/server')

--- @param payload table
--- @return table
function M.diagnosticsAdminListTests(payload)
    return impl.diagnosticsAdminListTests(payload)
end

--- @param payload table
--- @return table
function M.diagnosticsAdminListRuns(payload)
    return impl.diagnosticsAdminListRuns(payload)
end

--- @param payload table
--- @return table
function M.diagnosticsAdminRun(payload)
    return impl.diagnosticsAdminRun(payload)
end

--- @param runId string|number
--- @param payload table
--- @return table
function M.diagnosticsAdminGetRun(runId, payload)
    return impl.diagnosticsAdminGetRun(runId, payload)
end

--- @param runId string|number
--- @param payload table
--- @return table
function M.diagnosticsAdminCancelRun(runId, payload)
    return impl.diagnosticsAdminCancelRun(runId, payload)
end

return M
