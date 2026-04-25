--- Admin NUI open permission gate (`Config.web` + `hf.webConsoleAccess`).
local hf = hf

RegisterNetEvent('e_core:web:requestOpen', function()
    local src = source
    if not hf.netRateLimit(src, 'e_core:web:requestOpen', 1200) then
        return
    end
    local ok, err = hf.webConsoleAccess(src)
    if ok then
        TriggerClientEvent('e_core:web:open', src)
    else
        TriggerClientEvent('e_core:web:deny', src, err or 'Access denied.')
    end
end)
