--- Szerver oldali integritás-ellenőrzés: súly, max súly, canCarry, opc. add/remove; kliens progress teszt.
--- NUI: lépésenkénti checklist (kis szünetekkel, hogy látszódjon a futás).
local hf = hf

local lastRun = {}
local awaitingProgress = {}
local awaitingClearToken = {}

local function diagnosticsAllowedIdentifiers(src)
    local list = Config.diagnostics.allowedIdentifiers
    if not hf.isPopulatedTable(list) then
        return false
    end
    local ids = GetPlayerIdentifiers(src)
    for _, pid in ipairs(ids) do
        local low = pid:lower()
        for _, allow in ipairs(list) do
            if type(allow) == 'string' and allow ~= '' and low == allow:lower() then
                return true
            end
        end
    end
    return false
end

local function diagnosticsCanRun(src)
    if not hf.isValidPlayerSource(src) then
        return false, 'Érvénytelen játékos.'
    end
    if not Config.diagnostics or not Config.diagnostics.enabled then
        return false, 'A diagnosztika ki van kapcsolva (Config.diagnostics.enabled).'
    end

    local acePerm = Config.diagnostics.acePermission or ''
    local aceOk = acePerm ~= '' and IsPlayerAceAllowed(src, acePerm)
    local idOk = diagnosticsAllowedIdentifiers(src)

    if not aceOk and not idOk then
        if acePerm == '' and not hf.isPopulatedTable(Config.diagnostics.allowedIdentifiers) then
            return false,
                'Nincs jogosultság: állíts `acePermission`-t (pl. ecore.diagnostics) és add_ace-et, vagy töltsd az `allowedIdentifiers` listát.'
        end
        return false, 'Nincs jogosultság (ACE vagy azonosító lista).'
    end

    local cd = Config.diagnostics.cooldownMs or 15000
    local now = GetGameTimer()
    if lastRun[src] and (now - lastRun[src]) < cd then
        return false, 'Várj a következő futtatás előtt (cooldown).'
    end

    if awaitingProgress[src] then
        return false, 'Még fut (vagy elakadt) egy progress teszt – várj, vagy próbáld újra később.'
    end

    return true, nil
end

local function appendLine(lines, text)
    lines[#lines + 1] = text
end

--- Szerver napló sorok (NUI nélküli futáshoz vagy összegzéshez).
local function runInventoryChecks(xPlayer, lines)
    local testItem = Config.diagnostics.testItem or 'water'
    local testAmt = Config.diagnostics.testItemAmount or 1

    local wOk, curW = pcall(function()
        return eCore:getInventoryWeight(xPlayer)
    end)
    if not wOk then
        appendLine(lines, ('Súly olvasás: HIBA (%s)'):format(tostring(curW)))
    else
        appendLine(lines, ('Aktuális súly (getInventoryWeight): %s'):format(tostring(curW)))
    end

    local mOk, maxW = pcall(function()
        return eCore:getPlayerMaxWeight(xPlayer)
    end)
    if not mOk then
        appendLine(lines, ('Max súly olvasás: HIBA (%s)'):format(tostring(maxW)))
    else
        appendLine(lines, ('Max súly (getPlayerMaxWeight / Config): %s'):format(tostring(maxW)))
    end

    if not eCore:isReady() then
        appendLine(lines, 'canCarry: kihagyva (item registry még nem ready).')
        return
    end

    local cOk, cRes, cReason = pcall(function()
        return eCore:canCarryItem({
            name = testItem,
            amount = testAmt,
            metadata = {},
        }, xPlayer)
    end)
    if not cOk then
        appendLine(lines, ('canCarryItem(%s x%s): HIBA %s'):format(testItem, testAmt, tostring(cRes)))
    elseif cRes then
        appendLine(lines, ('canCarryItem(%s x%s): OK'):format(testItem, testAmt))
    else
        appendLine(lines, ('canCarryItem(%s x%s): NEM, ok=%s'):format(testItem, testAmt, tostring(cReason)))
    end

    if Config.diagnostics.tryAddRemove then
        local addRes, addReason = eCore:addItem(xPlayer, testItem, testAmt, nil, nil)
        if addRes then
            appendLine(lines, ('addItem(%s x%s): OK'):format(testItem, testAmt))
            local remRes, remReason = eCore:removeItem(xPlayer, testItem, testAmt, nil, nil)
            if remRes then
                appendLine(lines, ('removeItem(%s x%s): OK'):format(testItem, testAmt))
            else
                appendLine(lines, ('removeItem: HIBA %s (nézd kézzel az inventoryt)'):format(tostring(remReason)))
            end
        else
            appendLine(lines, ('addItem(%s x%s): NEM, ok=%s'):format(testItem, testAmt, tostring(addReason)))
        end
    else
        appendLine(lines, 'addItem/removeItem: kihagyva (Config.diagnostics.tryAddRemove = false).')
    end
end

local function diagUiPause()
    local ms = (Config.diagnostics and tonumber(Config.diagnostics.uiStepMs)) or 55
    ms = math.max(0, math.min(400, ms))
    if ms > 0 then
        Wait(ms)
    end
end

local function diagNuiPush(src, data)
    if Config.diagnostics and Config.diagnostics.useNui == false then
        return
    end
    if hf.isValidPlayerSource(src) and type(data) == 'table' then
        TriggerClientEvent('e_core:diagnostics:nuiPush', src, data)
    end
end

--- Szerver ellenőrzések + NUI checklist + végén kliens progress hívás (ugyanabban a szálon).
local function runDiagnosticsServerSequence(src, xPlayer)
    CreateThread(function()
        local runSrc = src
        local testItem = Config.diagnostics.testItem or 'water'
        local testAmt = Config.diagnostics.testItemAmount or 1
        local lines = {}
        appendLine(lines, '--- e_core integritás (szerver) ---')

        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_RUN_START', progressPending = true })
        diagUiPause()

        local items = {
            { id = 'env', label = 'Környezet (resource, framework, isReady)' },
            { id = 'weight', label = 'Aktuális súly (getInventoryWeight)' },
            { id = 'maxw', label = 'Max súly (getPlayerMaxWeight / Config)' },
            { id = 'carry', label = ('canCarryItem (%s x%s)'):format(testItem, testAmt) },
        }
        if Config.diagnostics.tryAddRemove then
            items[#items + 1] = { id = 'mutate', label = 'addItem → removeItem teszt' }
        end
        items[#items + 1] = { id = 'progress', label = 'Kliens progress sáv (a játékban megjelenő sáv)' }

        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_CHECKLIST_INIT', items = items })
        diagUiPause()

        if not hf.isValidPlayerSource(runSrc) then
            return
        end

        -- env
        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_LIVE_HINT', text = 'Környezet ellenőrzése…' })
        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'env', status = 'running' })
        diagUiPause()

        appendLine(lines, ('Resource: %s'):format(GetCurrentResourceName()))
        local fw = exports[GetCurrentResourceName()]:getFrameWork()
        appendLine(lines, ('Framework: %s'):format(tostring(fw)))
        local ready = eCore:isReady() == true
        appendLine(lines, ('isReady (szerver): %s'):format(tostring(ready)))
        diagNuiPush(runSrc, {
            action = 'DIAGNOSTICS_CHECKLIST_SET',
            id = 'env',
            status = 'ok',
            detail = ('%s · %s'):format(tostring(fw), ready and 'ready' or 'nem ready'),
        })
        diagUiPause()

        -- weight
        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_LIVE_HINT', text = 'Súly lekérése (aktuális)…' })
        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'weight', status = 'running' })
        diagUiPause()

        local wOk, curW = pcall(function()
            return eCore:getInventoryWeight(xPlayer)
        end)
        if not wOk then
            appendLine(lines, ('Súly olvasás: HIBA (%s)'):format(tostring(curW)))
            diagNuiPush(runSrc, {
                action = 'DIAGNOSTICS_CHECKLIST_SET',
                id = 'weight',
                status = 'fail',
                detail = tostring(curW),
            })
        else
            appendLine(lines, ('Aktuális súly (getInventoryWeight): %s'):format(tostring(curW)))
            diagNuiPush(runSrc, {
                action = 'DIAGNOSTICS_CHECKLIST_SET',
                id = 'weight',
                status = 'ok',
                detail = tostring(curW),
            })
        end
        diagUiPause()

        if not hf.isValidPlayerSource(runSrc) then
            return
        end

        -- max weight
        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_LIVE_HINT', text = 'Max súly lekérése…' })
        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'maxw', status = 'running' })
        diagUiPause()

        local mOk, maxW = pcall(function()
            return eCore:getPlayerMaxWeight(xPlayer)
        end)
        if not mOk then
            appendLine(lines, ('Max súly olvasás: HIBA (%s)'):format(tostring(maxW)))
            diagNuiPush(runSrc, {
                action = 'DIAGNOSTICS_CHECKLIST_SET',
                id = 'maxw',
                status = 'fail',
                detail = tostring(maxW),
            })
        else
            appendLine(lines, ('Max súly (getPlayerMaxWeight / Config): %s'):format(tostring(maxW)))
            diagNuiPush(runSrc, {
                action = 'DIAGNOSTICS_CHECKLIST_SET',
                id = 'maxw',
                status = 'ok',
                detail = tostring(maxW),
            })
        end
        diagUiPause()

        if not hf.isValidPlayerSource(runSrc) then
            return
        end

        -- canCarry
        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_LIVE_HINT', text = 'canCarryItem szimuláció…' })
        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'carry', status = 'running' })
        diagUiPause()

        if not ready then
            appendLine(lines, 'canCarry: kihagyva (item registry még nem ready).')
            diagNuiPush(runSrc, {
                action = 'DIAGNOSTICS_CHECKLIST_SET',
                id = 'carry',
                status = 'skipped',
                detail = 'registry nem ready',
            })
        else
            local cOk, cRes, cReason = pcall(function()
                return eCore:canCarryItem({
                    name = testItem,
                    amount = testAmt,
                    metadata = {},
                }, xPlayer)
            end)
            if not cOk then
                appendLine(lines, ('canCarryItem(%s x%s): HIBA %s'):format(testItem, testAmt, tostring(cRes)))
                diagNuiPush(runSrc, {
                    action = 'DIAGNOSTICS_CHECKLIST_SET',
                    id = 'carry',
                    status = 'fail',
                    detail = tostring(cRes),
                })
            elseif cRes then
                appendLine(lines, ('canCarryItem(%s x%s): OK'):format(testItem, testAmt))
                diagNuiPush(runSrc, {
                    action = 'DIAGNOSTICS_CHECKLIST_SET',
                    id = 'carry',
                    status = 'ok',
                    detail = 'OK',
                })
            else
                appendLine(lines, ('canCarryItem(%s x%s): NEM, ok=%s'):format(testItem, testAmt, tostring(cReason)))
                diagNuiPush(runSrc, {
                    action = 'DIAGNOSTICS_CHECKLIST_SET',
                    id = 'carry',
                    status = 'fail',
                    detail = tostring(cReason),
                })
            end
        end
        diagUiPause()

        if not hf.isValidPlayerSource(runSrc) then
            return
        end

        -- add/remove
        if Config.diagnostics.tryAddRemove then
            diagNuiPush(runSrc, { action = 'DIAGNOSTICS_LIVE_HINT', text = 'addItem / removeItem…' })
            diagNuiPush(runSrc, { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'mutate', status = 'running' })
            diagUiPause()

            if not ready then
                appendLine(lines, 'addItem/removeItem: kihagyva (item registry még nem ready).')
                diagNuiPush(runSrc, {
                    action = 'DIAGNOSTICS_CHECKLIST_SET',
                    id = 'mutate',
                    status = 'skipped',
                    detail = 'registry nem ready',
                })
            else
                local addRes, addReason = eCore:addItem(xPlayer, testItem, testAmt, nil, nil)
                if addRes then
                    appendLine(lines, ('addItem(%s x%s): OK'):format(testItem, testAmt))
                    local remRes, remReason = eCore:removeItem(xPlayer, testItem, testAmt, nil, nil)
                    if remRes then
                        appendLine(lines, ('removeItem(%s x%s): OK'):format(testItem, testAmt))
                        diagNuiPush(runSrc, {
                            action = 'DIAGNOSTICS_CHECKLIST_SET',
                            id = 'mutate',
                            status = 'ok',
                            detail = 'OK',
                        })
                    else
                        appendLine(lines, ('removeItem: HIBA %s (nézd kézzel az inventoryt)'):format(tostring(remReason)))
                        diagNuiPush(runSrc, {
                            action = 'DIAGNOSTICS_CHECKLIST_SET',
                            id = 'mutate',
                            status = 'fail',
                            detail = tostring(remReason),
                        })
                    end
                else
                    appendLine(lines, ('addItem(%s x%s): NEM, ok=%s'):format(testItem, testAmt, tostring(addReason)))
                    diagNuiPush(runSrc, {
                        action = 'DIAGNOSTICS_CHECKLIST_SET',
                        id = 'mutate',
                        status = 'fail',
                        detail = tostring(addReason),
                    })
                end
            end
            diagUiPause()
        end

        if not hf.isValidPlayerSource(runSrc) then
            return
        end

        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_LOG_SET', lines = lines })
        diagNuiPush(runSrc, {
            action = 'DIAGNOSTICS_LIVE_HINT',
            text = 'Szerver kész – nézd a játékot: megjelenik a progress sáv (vagy szakítsd meg).',
        })
        diagUiPause()

        TriggerClientEvent('e_core:diagnostics:consoleOnly', runSrc, lines)

        if type(eCore.sendMessage) == 'function' then
            eCore:sendMessage(
                runSrc,
                '[e_core] Integritás: checklist a modálban. A progress sáv a játék UI-ban indul.',
                'info',
                7000
            )
        end

        awaitingProgress[runSrc] = GetGameTimer()
        awaitingClearToken[runSrc] = (awaitingClearToken[runSrc] or 0) + 1
        local token = awaitingClearToken[runSrc]
        SetTimeout(120000, function()
            if awaitingClearToken[runSrc] == token and awaitingProgress[runSrc] then
                awaitingProgress[runSrc] = nil
            end
        end)

        if hf.isValidPlayerSource(runSrc) then
            TriggerClientEvent('e_core:diagnostics:progressTest', runSrc, {
                duration = Config.diagnostics.progressDurationMs or 3000,
            })
        end
    end)
end

RegisterNetEvent('e_core:diagnostics:request', function()
    local src = source
    if not hf.netRateLimit(src, 'e_core:diagnostics:burst', 1500) then
        return
    end
    local ok, err = diagnosticsCanRun(src)
    if not ok then
        if hf.isPopulatedString(err) then
            TriggerClientEvent('e_core:diagnostics:clientPrint', src, { '[e_core] ' .. err }, 'error')
        end
        return
    end

    lastRun[src] = GetGameTimer()

    local xPlayer = eCore:getPlayer(src)
    if not xPlayer then
        TriggerClientEvent('e_core:diagnostics:clientPrint', src, { '[e_core] Nem található játékos (getPlayer).' }, 'error')
        return
    end

    if Config.diagnostics and Config.diagnostics.useNui == false then
        local lines = {}
        appendLine(lines, '--- e_core integritás (szerver) ---')
        appendLine(lines, ('Resource: %s'):format(GetCurrentResourceName()))
        local fw = exports[GetCurrentResourceName()]:getFrameWork()
        appendLine(lines, ('Framework: %s'):format(tostring(fw)))
        appendLine(lines, ('isReady (szerver): %s'):format(tostring(eCore:isReady() == true)))
        runInventoryChecks(xPlayer, lines)
        TriggerClientEvent('e_core:diagnostics:clientPrint', src, lines, 'server')
        if type(eCore.sendMessage) == 'function' then
            eCore:sendMessage(
                src,
                '[e_core] Integritás: sorok a F8 konzolon. Indul a progress teszt…',
                'info',
                6000
            )
        end
        awaitingProgress[src] = GetGameTimer()
        awaitingClearToken[src] = (awaitingClearToken[src] or 0) + 1
        local token = awaitingClearToken[src]
        SetTimeout(120000, function()
            if awaitingClearToken[src] == token and awaitingProgress[src] then
                awaitingProgress[src] = nil
            end
        end)
        TriggerClientEvent('e_core:diagnostics:progressTest', src, {
            duration = Config.diagnostics.progressDurationMs or 3000,
        })
        return
    end

    runDiagnosticsServerSequence(src, xPlayer)
end)

RegisterNetEvent('e_core:diagnostics:progressResult', function(success)
    local src = source
    if not hf.netRateLimit(src, 'e_core:diagnostics:progressResult', 500) then
        return
    end
    if not hf.isValidPlayerSource(src) then
        return
    end
    if not awaitingProgress[src] then
        return
    end
    awaitingProgress[src] = nil

    local lines = { '--- e_core integritás (kliens progress) ---' }
    if success then
        appendLine(lines, 'progressbar onFinish: OK (onFinish / sikeres lefutás).')
        if type(eCore.sendMessage) == 'function' then
            eCore:sendMessage(src, '[e_core] Progress teszt: OK.', 'success', 5000)
        end
    else
        appendLine(lines, 'progressbar: MEGSZAKÍTVA vagy hiba (onCancel / nem sikerült).')
        if type(eCore.sendMessage) == 'function' then
            eCore:sendMessage(src, '[e_core] Progress teszt: sikertelen vagy megszakítva.', 'error', 6000)
        end
    end
    TriggerClientEvent('e_core:diagnostics:clientPrint', src, lines, 'progress')
    diagNuiPush(src, {
        action = 'DIAGNOSTICS_LIVE_HINT',
        text = success and 'Progress: sikeres lefutás (onFinish).' or 'Progress: megszakítva vagy hiba (onCancel).',
    })
end)
