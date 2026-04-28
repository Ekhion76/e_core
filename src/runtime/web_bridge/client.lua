--- Opens in-game admin NUI (`Config.web`, default command `ecore_admin`).
local hf = hf
local pendingWebOpen = false

RegisterNetEvent('e_core:web:open', function()
    if not eCoreNui.isReady() then
        pendingWebOpen = true
        return
    end
    if eCore and eCore.UI and type(eCore.UI.IsEditMode) == 'function' and eCore.UI.IsEditMode() then
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'WEB_OPEN' })
end)

RegisterNetEvent('e_core:web:nuiReady', function()
    if not pendingWebOpen then
        return
    end
    pendingWebOpen = false
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'WEB_OPEN' })
end)

RegisterNetEvent('e_core:web:deny', function(message)
    local msg = type(message) == 'string' and message or 'Access denied.'
    print(('[e_core] Admin: %s'):format(msg))
end)

RegisterNUICallback('webAdminExit', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'WEB_CLOSE' })
    cb('ok')
end)

--- Registers the local admin command that requests web console open on server.
--- @return nil
local function registerWebCommand()
    --- Command stays registered even when admin UI is disabled to avoid F8 "invalid command".
    --- If disabled (`Config.operator.admin.enabled` -> synthesized `Config.web.enabled`), print clear console guidance.
    local w = type(Config) == 'table' and Config.web or {}
    local cmd = tostring(w.command or 'ecore_admin'):gsub('^%s+', ''):gsub('%s+$', '')
    if cmd == '' then
        cmd = 'ecore_admin'
    end
    RegisterCommand(cmd, function()
        if not Config.web or Config.web.enabled ~= true then
            print(
                '[e_core] Admin console is disabled (Config.operator.admin.enabled = false). Set it to true (src/config/main.lua -> operator.admin, or override), then restart e_core.'
            )
            return
        end
        if not eCore or not eCore.isLoggedIn or not eCore:isLoggedIn() then
            print('[e_core] Admin: join with a character first.')
            return
        end
        TriggerServerEvent('e_core:web:requestOpen')
    end, false)
end

CreateThread(function()
    Wait(500)
    registerWebCommand()
end)
