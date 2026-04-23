--- Integritás parancs + progress teszt (szerver által engedélyezve); eredmény NUI modál + opc. F8.
local hf = hf

local function diagnosticsUseNui()
    return Config.diagnostics and Config.diagnostics.useNui ~= false
end

local function diagnosticsPrintConsole(lines)
    if not Config.diagnostics then
        return
    end
    if diagnosticsUseNui() and Config.diagnostics.printToConsole ~= true then
        return
    end
    if not hf.isPopulatedTable(lines) then
        return
    end
    for _, line in ipairs(lines) do
        print(('[e_core] %s'):format(tostring(line)))
    end
end

local function diagnosticsPushNui(action, payload)
    if not diagnosticsUseNui() then
        return false
    end
    if not ECO or not ECO.nuiReady then
        return false
    end
    payload = type(payload) == 'table' and payload or {}
    payload.action = action
    SendNUIMessage(payload)
    return true
end

--- Csak F8 / konzol (NUI checklist szekvencia után).
RegisterNetEvent('e_core:diagnostics:consoleOnly', function(lines)
    diagnosticsPrintConsole(lines)
end)

--- Szerver → kliens NUI (checklist lépések, napló, élő szöveg).
RegisterNetEvent('e_core:diagnostics:nuiPush', function(data)
    if type(data) ~= 'table' then
        return
    end
    if not diagnosticsUseNui() or not ECO or not ECO.nuiReady then
        return
    end
    if data.action == 'DIAGNOSTICS_RUN_START' then
        SetNuiFocus(true, true)
    end
    SendNUIMessage(data)
end)

--- @param lines string[]
--- @param section? string server | progress | error
RegisterNetEvent('e_core:diagnostics:clientPrint', function(lines, section)
    section = type(section) == 'string' and section or 'server'

    diagnosticsPrintConsole(lines)

    if not hf.isPopulatedTable(lines) then
        return
    end

    if section == 'progress' then
        if diagnosticsUseNui() and ECO and ECO.nuiReady then
            SendNUIMessage({
                action = 'DIAGNOSTICS_APPEND',
                lines = lines,
            })
        end
        return
    end

    if not diagnosticsPushNui('DIAGNOSTICS_OPEN', {
        lines = lines,
        section = section,
        progressPending = section == 'server',
    }) then
        return
    end

    SetNuiFocus(true, true)
end)

RegisterNetEvent('e_core:diagnostics:progressTest', function(opts)
    opts = type(opts) == 'table' and opts or {}
    local duration = math.max(1000, math.min(60000, tonumber(opts.duration) or 3000))

    if diagnosticsUseNui() and ECO and ECO.nuiReady then
        SendNUIMessage({
            action = 'DIAGNOSTICS_CHECKLIST_SET',
            id = 'progress',
            status = 'running',
            detail = 'Nézd a játék UI-t (ox / qs / egyéb progress)',
        })
        SendNUIMessage({
            action = 'DIAGNOSTICS_LIVE_HINT',
            text = 'Fut: kliens progress sáv – a modál átlátszó, mögötte a progress és az üzenetek.',
        })
    end

    eCore:progressbar({
        name = 'ecore_diagnostics',
        label = opts.label or 'e_core – integritás (progress)',
        duration = duration,
        useWhileDead = false,
        canCancel = true,
        onFinish = function()
            if diagnosticsUseNui() and ECO and ECO.nuiReady then
                SendNUIMessage({
                    action = 'DIAGNOSTICS_CHECKLIST_SET',
                    id = 'progress',
                    status = 'ok',
                    detail = 'onFinish',
                })
                SendNUIMessage({
                    action = 'DIAGNOSTICS_LIVE_HINT',
                    text = 'Progress: kész (sikeres onFinish).',
                })
            end
            TriggerServerEvent('e_core:diagnostics:progressResult', true)
        end,
        onCancel = function()
            if diagnosticsUseNui() and ECO and ECO.nuiReady then
                SendNUIMessage({
                    action = 'DIAGNOSTICS_CHECKLIST_SET',
                    id = 'progress',
                    status = 'cancelled',
                    detail = 'onCancel',
                })
                SendNUIMessage({
                    action = 'DIAGNOSTICS_LIVE_HINT',
                    text = 'Progress: megszakítva (onCancel) – narancs a checklisten.',
                })
            end
            TriggerServerEvent('e_core:diagnostics:progressResult', false)
        end,
    })
end)

RegisterNUICallback('diagnosticsExit', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'DIAGNOSTICS_CLOSE' })
    cb('ok')
end)

local function registerDiagCommand()
    if not Config.diagnostics or not Config.diagnostics.enabled then
        return
    end
    local cmd = Config.diagnostics.command or 'ecore_diag'
    RegisterCommand(cmd, function()
        if not eCore or not eCore.isLoggedIn or not eCore:isLoggedIn() then
            print('[e_core] Előbb járj be a karakterrel.')
            return
        end
        TriggerServerEvent('e_core:diagnostics:request')
    end, false)
end

CreateThread(function()
    Wait(500)
    registerDiagCommand()
end)
