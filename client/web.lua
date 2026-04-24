--- Játékbeli admin NUI megnyitása (`Config.web`, alap parancs `ecore_admin`).
local hf = hf

RegisterNetEvent('e_core:web:open', function()
    if not ECO or not ECO.nuiReady then
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'WEB_OPEN' })
end)

RegisterNetEvent('e_core:web:deny', function(message)
    local msg = type(message) == 'string' and message or 'Nincs jogosultság.'
    print(('[e_core] Admin: %s'):format(msg))
end)

RegisterNUICallback('webAdminExit', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'WEB_CLOSE' })
    cb('ok')
end)

local function registerWebCommand()
    --- Mindig regisztráljuk a parancsot, különben az F8 „invalid command” (mintha nem létezne).
    --- Ha az admin NUI ki van kapcsolva (`Config.operator.admin.enabled` → szintetizált `Config.web.enabled`), egyértelmű üzenet megy a konzolra.
    local w = type(Config) == 'table' and Config.web or {}
    local cmd = tostring(w.command or 'ecore_admin'):gsub('^%s+', ''):gsub('%s+$', '')
    if cmd == '' then
        cmd = 'ecore_admin'
    end
    RegisterCommand(cmd, function()
        if not Config.web or Config.web.enabled ~= true then
            print(
                '[e_core] Admin konzol ki van kapcsolva (Config.operator.admin.enabled = false). Állítsd true-ra (standalone/config/main.lua → operator.admin, vagy override), majd indítsd újra az e_core-t.'
            )
            return
        end
        if not eCore or not eCore.isLoggedIn or not eCore:isLoggedIn() then
            print('[e_core] Admin: előbb járj be a karakterrel.')
            return
        end
        TriggerServerEvent('e_core:web:requestOpen')
    end, false)
end

CreateThread(function()
    Wait(500)
    registerWebCommand()
end)
