--- Admin NUI open permission gate (`Config.web` + `hf.webConsoleAccess`).
local hf = hf
local hfe = hfe

--- Handles web admin open requests and emits allow/deny events.
--- @param src number Player source requesting web admin open.
--- @return nil
local function onWebRequestOpen(src)
    if not hf.netRateLimit(src, 'e_core:web:requestOpen', 1200) then
        return
    end
    local ok, err = hfe.webConsoleAccess(src)
    if ok then
        TriggerClientEvent('e_core:web:open', src)
    else
        TriggerClientEvent('e_core:web:deny', src, err or 'Access denied.')
    end
end

return {
    onWebRequestOpen = onWebRequestOpen,
}
