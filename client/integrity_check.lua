--- Integritás NUI / progress (`Config.integrityCheck`); net: `e_core:integrityCheck:*` (futtatás: admin Integritás fül → `integrityDiagnosticsRun`).
local hf = hf

local function integrityUseNui()
    return Config.integrityCheck and Config.integrityCheck.useNui ~= false
end

local function integrityPrintConsole(lines)
    if not Config.integrityCheck then
        return
    end
    if integrityUseNui() and Config.integrityCheck.printToConsole ~= true then
        return
    end
    if not hf.isPopulatedTable(lines) then
        return
    end
    for _, line in ipairs(lines) do
        print(('[e_core] %s'):format(tostring(line)))
    end
end

RegisterNetEvent('e_core:integrityCheck:consoleOnly', function(lines)
    integrityPrintConsole(lines)
end)

RegisterNetEvent('e_core:integrityCheck:nuiPush', function(data)
    if type(data) ~= 'table' or data.adminInline ~= true then
        return
    end
    if not integrityUseNui() or not ECO or not ECO.nuiReady then
        return
    end
    SendNUIMessage(data)
end)

RegisterNetEvent('e_core:integrityCheck:clientPrint', function(lines, section, meta)
    section = type(section) == 'string' and section or 'server'
    meta = type(meta) == 'table' and meta or {}

    integrityPrintConsole(lines)

    if not hf.isPopulatedTable(lines) then
        return
    end

    if meta.adminInline == true and ECO and ECO.nuiReady then
        if section == 'progress' then
            SendNUIMessage({
                action = 'DIAGNOSTICS_APPEND',
                lines = lines,
                adminInline = true,
            })
        else
            SendNUIMessage({
                action = 'DIAGNOSTICS_INLINE_LOG',
                lines = lines,
                section = section,
                adminInline = true,
            })
        end
        return
    end

    --- Standalone NUI modál nincs: nem inline futás (pl. régi trigger) → F8.
    for _, line in ipairs(lines) do
        print(('[e_core] %s'):format(tostring(line)))
    end
end)

RegisterNetEvent('e_core:integrityCheck:progressTest', function(opts)
    opts = type(opts) == 'table' and opts or {}
    local duration = math.max(1000, math.min(60000, tonumber(opts.duration) or 3000))
    local adminInline = opts.adminInline == true

    if integrityUseNui() and ECO and ECO.nuiReady then
        SendNUIMessage({
            action = 'DIAGNOSTICS_CHECKLIST_SET',
            id = 'progress',
            status = 'running',
            detail = 'Nézd a játék UI-t (ox / qs / egyéb progress)',
            adminInline = adminInline or nil,
        })
        SendNUIMessage({
            action = 'DIAGNOSTICS_LIVE_HINT',
            text = adminInline and 'Fut: kliens progress sáv (az admin Integritás fülön követhető).'
                or 'Fut: kliens progress sáv (állapot: F8 konzol).',
            adminInline = adminInline or nil,
        })
    end

    eCore:progressbar({
        name = 'ecore_integrity_check',
        label = opts.label or 'e_core – integritás (progress)',
        duration = duration,
        useWhileDead = false,
        canCancel = true,
        onFinish = function()
            if integrityUseNui() and ECO and ECO.nuiReady then
                SendNUIMessage({
                    action = 'DIAGNOSTICS_CHECKLIST_SET',
                    id = 'progress',
                    status = 'ok',
                    detail = 'onFinish',
                    adminInline = adminInline or nil,
                })
                SendNUIMessage({
                    action = 'DIAGNOSTICS_LIVE_HINT',
                    text = 'Progress: kész (sikeres onFinish).',
                    adminInline = adminInline or nil,
                })
            end
            TriggerServerEvent('e_core:integrityCheck:progressResult', true)
        end,
        onCancel = function()
            if integrityUseNui() and ECO and ECO.nuiReady then
                SendNUIMessage({
                    action = 'DIAGNOSTICS_CHECKLIST_SET',
                    id = 'progress',
                    status = 'cancelled',
                    detail = 'onCancel',
                    adminInline = adminInline or nil,
                })
                SendNUIMessage({
                    action = 'DIAGNOSTICS_LIVE_HINT',
                    text = 'Progress: megszakítva (onCancel) – narancs a checklisten.',
                    adminInline = adminInline or nil,
                })
            end
            TriggerServerEvent('e_core:integrityCheck:progressResult', false)
        end,
    })
end)

RegisterNUICallback('diagnosticsExit', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'DIAGNOSTICS_CLOSE' })
    cb('ok')
end)

RegisterNUICallback('integrityDiagnosticsRun', function(data, cb)
    data = type(data) == 'table' and data or {}
    local opts = data.opts
    if opts ~= nil and type(opts) ~= 'table' then
        opts = nil
    end
    TriggerServerEvent('e_core:integrityCheck:request', opts)
    cb({ ok = true })
end)
