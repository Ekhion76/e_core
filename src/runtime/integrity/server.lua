--- Server-side integrity checklist (weight, registry, canCarry, optional add/remove) with client progress/NUI steps.
--- Net scope: `e_core:integrityCheck:*` — keep separate from registry admin diagnostics exports (`server/diagnostics.lua`).
local hf = hf
local hfe = hfe

local lastRun = {}
local awaitingProgress = {}
local awaitingClearToken = {}
--- Progress phase inline-admin mode (`opts` can already be nil for `progressResult`).
local integrityAwaitingInline = {}

--- Cooldown between two **full** runs (without `onlyStep`); NUI opts can override, min is `INTEGRITY_COOLDOWN_MIN_MS`.
local INTEGRITY_COOLDOWN_MIN_MS = 1500
--- Fallback when `Config.integrityCheck.cooldownMs` is missing (aligned with config_check defaults).
local INTEGRITY_COOLDOWN_DEFAULT_MS = 1500
--- Net burst guard for step-by-step (`onlyStep`) requests: prevents loops without slowing down admin flow.
local INTEGRITY_STEP_BURST_MS = 320

local INTEGRITY_FIELD_DEFAULTS = {
    testItem = 'water',
    testItemAmount = 1,
    tryAddRemove = true,
    progressDurationMs = 3000,
    useNui = true,
    printToConsole = false,
    uiStepMs = 55,
    inlineAdmin = false,
    onlyStep = nil,
}

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function integrityCooldownFromConfig()
    local ic = type(Config) == 'table' and Config.integrityCheck or {}
    local v = tonumber(ic.cooldownMs)
    if v == nil then
        return INTEGRITY_COOLDOWN_DEFAULT_MS
    end
    return math.max(INTEGRITY_COOLDOWN_MIN_MS, v)
end

local integrityOptsBySrc = {}

--- Adds latest item-convert diagnostics summary lines to integrity output.
--- @param lines table
--- @return nil
local function appendItemConvertDiagnostics(lines)
    if type(lines) ~= 'table' then
        return
    end
    local function add(text)
        lines[#lines + 1] = tostring(text)
    end
    add('--- ItemConvert diagnostics ---')
    if type(hf.itemConvertDiagSummaryLines) ~= 'function' then
        add('ItemConvert diagnostics: helper not available.')
        return
    end
    local parts = hf.itemConvertDiagSummaryLines(10)
    if type(parts) ~= 'table' or #parts == 0 then
        add('ItemConvert diagnostics: no lines.')
        return
    end
    for i = 1, #parts do
        add(parts[i])
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param opts table
--- @return any result
local function mergeIntegrityOptsFromPayload(opts)
    opts = type(opts) == 'table' and opts or {}
    local ic = type(Config) == 'table' and Config.integrityCheck or {}
    local o = {}
    for k, v in pairs(INTEGRITY_FIELD_DEFAULTS) do
        o[k] = v
    end
    o.cooldownMs = integrityCooldownFromConfig()
    o.testItem = hf.trim(tostring(ic.testItem or INTEGRITY_FIELD_DEFAULTS.testItem))
    o.testItemAmount = math.max(1, tonumber(ic.testItemAmount) or INTEGRITY_FIELD_DEFAULTS.testItemAmount)
    o.tryAddRemove = ic.tryAddRemove == true
    o.progressDurationMs = math.max(
        1000,
        math.min(60000, tonumber(ic.progressDurationMs) or INTEGRITY_FIELD_DEFAULTS.progressDurationMs)
    )
    o.useNui = ic.useNui ~= false
    o.printToConsole = ic.printToConsole == true
    o.uiStepMs = math.max(0, math.min(400, tonumber(ic.uiStepMs) or INTEGRITY_FIELD_DEFAULTS.uiStepMs))
    if opts.cooldownMs ~= nil then
        o.cooldownMs = math.max(INTEGRITY_COOLDOWN_MIN_MS, tonumber(opts.cooldownMs) or o.cooldownMs)
    end
    if opts.testItem ~= nil then
        local t = hf.trim(tostring(opts.testItem))
        o.testItem = (t ~= '' and t or INTEGRITY_FIELD_DEFAULTS.testItem)
    end
    if opts.testItemAmount ~= nil then
        o.testItemAmount = math.max(1, tonumber(opts.testItemAmount) or o.testItemAmount)
    end
    if opts.tryAddRemove ~= nil then
        o.tryAddRemove = opts.tryAddRemove == true
    end
    if opts.progressDurationMs ~= nil then
        o.progressDurationMs = math.max(1000, math.min(60000, tonumber(opts.progressDurationMs) or o.progressDurationMs))
    end
    if opts.useNui ~= nil then
        o.useNui = opts.useNui == true
    end
    if opts.printToConsole ~= nil then
        o.printToConsole = opts.printToConsole == true
    end
    if opts.uiStepMs ~= nil then
        o.uiStepMs = math.max(0, math.min(400, tonumber(opts.uiStepMs) or o.uiStepMs))
    end
    if opts.inlineAdmin ~= nil then
        o.inlineAdmin = opts.inlineAdmin == true
    end
    if opts.onlyStep ~= nil then
        local s = hf.trim(tostring(opts.onlyStep))
        o.onlyStep = s ~= '' and s:lower() or nil
    end
    return o
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param src any
--- @return any result
local function activeIntegrityOpts(src)
    if type(src) == 'number' and integrityOptsBySrc[src] then
        return integrityOptsBySrc[src]
    end
    local ic = type(Config) == 'table' and Config.integrityCheck or {}
    return {
        cooldownMs = integrityCooldownFromConfig(),
        testItem = hf.trim(tostring(ic.testItem or INTEGRITY_FIELD_DEFAULTS.testItem)),
        testItemAmount = math.max(1, tonumber(ic.testItemAmount) or INTEGRITY_FIELD_DEFAULTS.testItemAmount),
        tryAddRemove = ic.tryAddRemove == true,
        progressDurationMs = math.max(
            1000,
            math.min(60000, tonumber(ic.progressDurationMs) or INTEGRITY_FIELD_DEFAULTS.progressDurationMs)
        ),
        useNui = ic.useNui ~= false,
        printToConsole = ic.printToConsole == true,
        uiStepMs = math.max(0, math.min(400, tonumber(ic.uiStepMs) or INTEGRITY_FIELD_DEFAULTS.uiStepMs)),
    }
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param src any
--- @return any result
local function integrityAllowedIdentifiers(src)
    local list = Config.integrityCheck and Config.integrityCheck.allowedIdentifiers
    if not hf.hasEntries(list) then
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param src any
--- @return any result
local function integrityPolicyAccess(src)
    --- Nyilvános kapcsoló: `Config.operator.admin.enabled` → `Config.web.enabled` (`libs/config_check.lua`).
    local w = type(Config) == 'table' and Config.web or {}
    if w.enabled == true then
        return hfe.webConsoleAccess(src)
    end

    local ic = Config.integrityCheck or {}
    local acePerm = ic.acePermission or ''
    local aceOk = acePerm ~= '' and IsPlayerAceAllowed(src, acePerm)
    local idOk = integrityAllowedIdentifiers(src)

    if not aceOk and not idOk then
        if acePerm == '' and not hf.hasEntries(ic.allowedIdentifiers) then
            return false, eCoreErr.integrity_policy_misconfigured
        end
        return false, eCoreErr.integrity_policy_denied
    end
    return true, nil
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param src any
--- @return any result
local function integrityCanRun(src)
    if not hf.isValidPlayerSource(src) then
        return false, eCoreErr.integrity_invalid_player
    end
    if not Config.integrityCheck or not Config.integrityCheck.enabled then
        return false, eCoreErr.integrity_check_disabled
    end

    local policyOk, policyErr = integrityPolicyAccess(src)
    if not policyOk then
        return false, policyErr
    end

    local io = activeIntegrityOpts(src)
    local stepOnly = type(io.onlyStep) == 'string' and hf.trim(io.onlyStep) ~= ''
    --- Egy lépésre kattintva ne érezze a teljes futás cooldownját; burst külön (RegisterNetEvent).
    if not stepOnly then
        local cd = io.cooldownMs
        local now = GetGameTimer()
        if lastRun[src] and (now - lastRun[src]) < cd then
            return false, eCoreErr.integrity_cooldown_active
        end
    end

    if awaitingProgress[src] then
        return false, eCoreErr.integrity_progress_busy
    end

    return true, nil
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param lines any
--- @param text any
--- @return any result
local function appendLine(lines, text)
    lines[#lines + 1] = text
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param lines any
--- @return any result
local function runProfessionRegistryChecks(lines)
    appendLine(lines, '--- Profession registry ellenőrzés ---')

    local okRegistry, registryOrErr = getProfessionRegistry()
    if not okRegistry then
        appendLine(lines, ('getProfessionRegistry: HIBA (%s)'):format(tostring(registryOrErr)))
        return false
    end

    local categories = 0
    local professions = 0
    local enabledProfessions = 0
    local missingProfile = 0

    for _, byName in pairs(registryOrErr) do
        if type(byName) == 'table' then
            categories = categories + 1
            for professionName, row in pairs(byName) do
                professions = professions + 1
                if row and row.enabled == true then
                    enabledProfessions = enabledProfessions + 1
                end

                local profileKey = row and row.levelProfileKey
                if type(profileKey) ~= 'string' or hf.trim(profileKey) == '' then
                    missingProfile = missingProfile + 1
                    appendLine(lines, ('Hiányzó profile referencia: %s'):format(tostring(professionName)))
                end
            end
        end
    end

    appendLine(lines, ('Registry összesítés: kategória=%s, profession=%s, engedélyezett=%s'):format(
        tostring(categories),
        tostring(professions),
        tostring(enabledProfessions)
    ))

    local profileIssues = 0
    for category, byName in pairs(registryOrErr) do
        if type(byName) == 'table' then
            for professionName in pairs(byName) do
                local okProfile, profileOrErr = getProfessionLevelProfile(category, professionName)
                if not okProfile then
                    profileIssues = profileIssues + 1
                    appendLine(
                        lines,
                        ('Profile lekérés hiba: %s.%s -> %s'):format(category, professionName, tostring(profileOrErr))
                    )
                elseif type(profileOrErr.levels) ~= 'table' or next(profileOrErr.levels) == nil then
                    profileIssues = profileIssues + 1
                    appendLine(lines, ('Profile levels üres: %s.%s'):format(category, professionName))
                end
            end
        end
    end

    if professions == 0 then
        appendLine(lines, 'Registry státusz: HIBA (nincs profession rekord).')
        return false
    end

    if missingProfile > 0 or profileIssues > 0 then
        appendLine(lines, ('Registry státusz: HIBA (missingProfile=%s, profileIssues=%s)'):format(
            tostring(missingProfile),
            tostring(profileIssues)
        ))
        return false
    end

    appendLine(lines, 'Registry státusz: OK')
    return true
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @param lines any
--- @param io any
--- @return any result
local function runInventoryChecks(xPlayer, lines, io)
    io = io or activeIntegrityOpts(nil)
    local testItem = io.testItem
    local testAmt = io.testItemAmount

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

    if io.tryAddRemove then
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
        appendLine(lines, 'addItem/removeItem: kihagyva (tryAddRemove = false).')
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param io any
--- @return any result
local function diagUiPause(io)
    local ms = tonumber(io and io.uiStepMs) or 55
    ms = math.max(0, math.min(400, ms))
    if ms > 0 then
        Wait(ms)
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param src any
--- @param data table
--- @param io any
--- @return any result
local function diagNuiPush(src, data, io)
    io = io or activeIntegrityOpts(src)
    if io.useNui == false then
        return
    end
    if hf.isValidPlayerSource(src) and type(data) == 'table' then
        if io.inlineAdmin then
            data.adminInline = true
        end
        TriggerClientEvent('e_core:integrityCheck:nuiPush', src, data)
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param io any
--- @return any result
local function buildIntegrityChecklistItems(io)
    io = io or activeIntegrityOpts(nil)
    local testItem = io.testItem
    local testAmt = io.testItemAmount
    local items = {
        { id = 'env', label = 'Környezet (resource, framework, isReady)' },
        { id = 'registry', label = 'Profession registry konzisztencia' },
        { id = 'weight', label = 'Aktuális súly (getInventoryWeight)' },
        { id = 'maxw', label = 'Max súly (getPlayerMaxWeight / Config)' },
        { id = 'carry', label = ('canCarryItem (%s x%s)'):format(testItem, testAmt) },
    }
    if io.tryAddRemove then
        items[#items + 1] = { id = 'mutate', label = 'addItem → removeItem teszt' }
    end
    items[#items + 1] = { id = 'progress', label = 'Kliens progress sáv (a játékban megjelenő sáv)' }
    return items
end

--- Executes one checklist step (admin Integrity tab, `onlyStep` option).
local function runIntegrityOnlyStep(runSrc, xPlayer, io)
    local testItem = io.testItem
    local testAmt = io.testItemAmount
    local only = io.onlyStep
    local lines = {}
    local ready = eCore:isReady() == true

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param data table
    --- @return any result
    local function push(data)
        diagNuiPush(runSrc, data, io)
    end
    --- Auto-generated annotation. Refine behavior details if needed.
    --- @return any result
    local function pause()
        diagUiPause(io)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param errLines any
    --- @param section any
    --- @return any result
    local function startClientPrint(errLines, section)
        section = type(section) == 'string' and section or 'error'
        local meta = io.inlineAdmin and { adminInline = true } or nil
        TriggerClientEvent('e_core:integrityCheck:clientPrint', runSrc, errLines, section, meta)
    end

    push({ action = 'DIAGNOSTICS_RUN_START', progressPending = only ~= 'progress' })
    pause()
    push({ action = 'DIAGNOSTICS_CHECKLIST_INIT', items = buildIntegrityChecklistItems(io) })
    pause()

    if only == 'env' then
        push({ action = 'DIAGNOSTICS_LIVE_HINT', text = 'Környezet ellenőrzése…' })
        push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'env', status = 'running' })
        pause()
        appendLine(lines, ('Resource: %s'):format(GetCurrentResourceName()))
        local fw = exports[GetCurrentResourceName()]:getFrameWork()
        appendLine(lines, ('Framework: %s'):format(tostring(fw)))
        appendLine(lines, ('isReady (szerver): %s'):format(tostring(ready)))
        appendItemConvertDiagnostics(lines)
        push({
            action = 'DIAGNOSTICS_CHECKLIST_SET',
            id = 'env',
            status = 'ok',
            detail = ('%s · %s'):format(tostring(fw), ready and 'ready' or 'nem ready'),
        })
        pause()
    elseif only == 'registry' then
        push({ action = 'DIAGNOSTICS_LIVE_HINT', text = 'Profession registry ellenőrzése…' })
        push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'registry', status = 'running' })
        pause()
        local registryOk = runProfessionRegistryChecks(lines)
        push({
            action = 'DIAGNOSTICS_CHECKLIST_SET',
            id = 'registry',
            status = registryOk and 'ok' or 'fail',
            detail = registryOk and 'OK' or 'hibák a részletes logban',
        })
        pause()
    elseif only == 'weight' then
        push({ action = 'DIAGNOSTICS_LIVE_HINT', text = 'Súly lekérése (aktuális)…' })
        push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'weight', status = 'running' })
        pause()
        local wOk, curW = pcall(function()
            return eCore:getInventoryWeight(xPlayer)
        end)
        if not wOk then
            appendLine(lines, ('Súly olvasás: HIBA (%s)'):format(tostring(curW)))
            push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'weight', status = 'fail', detail = tostring(curW) })
        else
            appendLine(lines, ('Aktuális súly (getInventoryWeight): %s'):format(tostring(curW)))
            push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'weight', status = 'ok', detail = tostring(curW) })
        end
        pause()
    elseif only == 'maxw' then
        push({ action = 'DIAGNOSTICS_LIVE_HINT', text = 'Max súly lekérése…' })
        push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'maxw', status = 'running' })
        pause()
        local mOk, maxW = pcall(function()
            return eCore:getPlayerMaxWeight(xPlayer)
        end)
        if not mOk then
            appendLine(lines, ('Max súly olvasás: HIBA (%s)'):format(tostring(maxW)))
            push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'maxw', status = 'fail', detail = tostring(maxW) })
        else
            appendLine(lines, ('Max súly (getPlayerMaxWeight / Config): %s'):format(tostring(maxW)))
            push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'maxw', status = 'ok', detail = tostring(maxW) })
        end
        pause()
    elseif only == 'carry' then
        push({ action = 'DIAGNOSTICS_LIVE_HINT', text = 'canCarryItem szimuláció…' })
        push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'carry', status = 'running' })
        pause()
        if not ready then
            appendLine(lines, 'canCarry: kihagyva (item registry még nem ready).')
            push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'carry', status = 'skipped', detail = 'registry nem ready' })
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
                push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'carry', status = 'fail', detail = tostring(cRes) })
            elseif cRes then
                appendLine(lines, ('canCarryItem(%s x%s): OK'):format(testItem, testAmt))
                push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'carry', status = 'ok', detail = 'OK' })
            else
                appendLine(lines, ('canCarryItem(%s x%s): NEM, ok=%s'):format(testItem, testAmt, tostring(cReason)))
                push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'carry', status = 'fail', detail = tostring(cReason) })
            end
        end
        pause()
    elseif only == 'mutate' then
        if not io.tryAddRemove then
            appendLine(lines, 'addItem/removeItem: kihagyva (tryAddRemove = false).')
            push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'mutate', status = 'skipped', detail = 'tryAddRemove ki' })
            pause()
        else
            push({ action = 'DIAGNOSTICS_LIVE_HINT', text = 'addItem / removeItem…' })
            push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'mutate', status = 'running' })
            pause()
            if not ready then
                appendLine(lines, 'addItem/removeItem: kihagyva (item registry még nem ready).')
                push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'mutate', status = 'skipped', detail = 'registry nem ready' })
            else
                local addRes, addReason = eCore:addItem(xPlayer, testItem, testAmt, nil, nil)
                if addRes then
                    appendLine(lines, ('addItem(%s x%s): OK'):format(testItem, testAmt))
                    local remRes, remReason = eCore:removeItem(xPlayer, testItem, testAmt, nil, nil)
                    if remRes then
                        appendLine(lines, ('removeItem(%s x%s): OK'):format(testItem, testAmt))
                        push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'mutate', status = 'ok', detail = 'OK' })
                    else
                        appendLine(lines, ('removeItem: HIBA %s (nézd kézzel az inventoryt)'):format(tostring(remReason)))
                        push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'mutate', status = 'fail', detail = tostring(remReason) })
                    end
                else
                    appendLine(lines, ('addItem(%s x%s): NEM, ok=%s'):format(testItem, testAmt, tostring(addReason)))
                    push({ action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'mutate', status = 'fail', detail = tostring(addReason) })
                end
            end
            pause()
        end
    elseif only == 'progress' then
        push({ action = 'DIAGNOSTICS_LIVE_HINT', text = 'Kliens progress sáv indul…' })
        push({
            action = 'DIAGNOSTICS_CHECKLIST_SET',
            id = 'progress',
            status = 'running',
            detail = 'Nézd a játék UI-t (ox / qs / egyéb progress)',
        })
        pause()
        table.insert(lines, 1, ('--- e_core integritás (egyetlen lépés: %s) ---'):format(tostring(only)))
        push({ action = 'DIAGNOSTICS_LOG_SET', lines = lines })
        TriggerClientEvent('e_core:integrityCheck:consoleOnly', runSrc, lines)
        if type(eCore.sendMessage) == 'function' then
            eCore:sendMessage(runSrc, '[e_core] Integritás: progress teszt indul.', 'info', 6000)
        end
        awaitingProgress[runSrc] = GetGameTimer()
        integrityAwaitingInline[runSrc] = io.inlineAdmin == true
        awaitingClearToken[runSrc] = (awaitingClearToken[runSrc] or 0) + 1
        local token = awaitingClearToken[runSrc]
        SetTimeout(120000, function()
            if awaitingClearToken[runSrc] == token and awaitingProgress[runSrc] then
                awaitingProgress[runSrc] = nil
            end
        end)
        if hf.isValidPlayerSource(runSrc) then
            TriggerClientEvent('e_core:integrityCheck:progressTest', runSrc, {
                duration = io.progressDurationMs,
                adminInline = io.inlineAdmin == true,
            })
        end
        integrityOptsBySrc[runSrc] = nil
        return
    else
        startClientPrint({ ('[e_core] Ismeretlen onlyStep: %s'):format(tostring(only)) }, 'error')
        integrityOptsBySrc[runSrc] = nil
        return
    end

    if not hf.isValidPlayerSource(runSrc) then
        integrityOptsBySrc[runSrc] = nil
        return
    end

    table.insert(lines, 1, ('--- e_core integritás (egyetlen lépés: %s) ---'):format(tostring(only)))
    push({ action = 'DIAGNOSTICS_LOG_SET', lines = lines })
    TriggerClientEvent('e_core:integrityCheck:consoleOnly', runSrc, lines)
    integrityOptsBySrc[runSrc] = nil
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param src any
--- @param xPlayer table
--- @return any result
local function runIntegrityServerSequence(src, xPlayer)
    CreateThread(function()
        local runSrc = src
        local io = activeIntegrityOpts(runSrc)
        if type(io.onlyStep) == 'string' and hf.trim(io.onlyStep) ~= '' then
            runIntegrityOnlyStep(runSrc, xPlayer, io)
            return
        end

        local testItem = io.testItem
        local testAmt = io.testItemAmount
        local lines = {}
        appendLine(lines, '--- e_core integritás (szerver) ---')

        --- Auto-generated annotation. Refine behavior details if needed.
        --- @param data table
        --- @return any result
        local function push(data)
            diagNuiPush(runSrc, data, io)
        end
        --- Auto-generated annotation. Refine behavior details if needed.
        --- @return any result
        local function pause()
            diagUiPause(io)
        end

        push({ action = 'DIAGNOSTICS_RUN_START', progressPending = true })
        pause()

        push({ action = 'DIAGNOSTICS_CHECKLIST_INIT', items = buildIntegrityChecklistItems(io) })
        pause()

        if not hf.isValidPlayerSource(runSrc) then
            integrityOptsBySrc[runSrc] = nil
            return
        end

        push( { action = 'DIAGNOSTICS_LIVE_HINT', text = 'Környezet ellenőrzése…' })
        push( { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'env', status = 'running' })
        pause()

        appendLine(lines, ('Resource: %s'):format(GetCurrentResourceName()))
        local fw = exports[GetCurrentResourceName()]:getFrameWork()
        appendLine(lines, ('Framework: %s'):format(tostring(fw)))
        local ready = eCore:isReady() == true
        appendLine(lines, ('isReady (szerver): %s'):format(tostring(ready)))
        appendItemConvertDiagnostics(lines)
        push( {
            action = 'DIAGNOSTICS_CHECKLIST_SET',
            id = 'env',
            status = 'ok',
            detail = ('%s · %s'):format(tostring(fw), ready and 'ready' or 'nem ready'),
        })
        pause()

        push( { action = 'DIAGNOSTICS_LIVE_HINT', text = 'Profession registry ellenőrzése…' })
        push( { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'registry', status = 'running' })
        pause()

        local registryOk = runProfessionRegistryChecks(lines)
        push( {
            action = 'DIAGNOSTICS_CHECKLIST_SET',
            id = 'registry',
            status = registryOk and 'ok' or 'fail',
            detail = registryOk and 'OK' or 'hibák a részletes logban',
        })
        pause()

        push( { action = 'DIAGNOSTICS_LIVE_HINT', text = 'Súly lekérése (aktuális)…' })
        push( { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'weight', status = 'running' })
        pause()

        local wOk, curW = pcall(function()
            return eCore:getInventoryWeight(xPlayer)
        end)
        if not wOk then
            appendLine(lines, ('Súly olvasás: HIBA (%s)'):format(tostring(curW)))
            push( {
                action = 'DIAGNOSTICS_CHECKLIST_SET',
                id = 'weight',
                status = 'fail',
                detail = tostring(curW),
            })
        else
            appendLine(lines, ('Aktuális súly (getInventoryWeight): %s'):format(tostring(curW)))
            push( {
                action = 'DIAGNOSTICS_CHECKLIST_SET',
                id = 'weight',
                status = 'ok',
                detail = tostring(curW),
            })
        end
        pause()

        if not hf.isValidPlayerSource(runSrc) then
            integrityOptsBySrc[runSrc] = nil
            return
        end

        push( { action = 'DIAGNOSTICS_LIVE_HINT', text = 'Max súly lekérése…' })
        push( { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'maxw', status = 'running' })
        pause()

        local mOk, maxW = pcall(function()
            return eCore:getPlayerMaxWeight(xPlayer)
        end)
        if not mOk then
            appendLine(lines, ('Max súly olvasás: HIBA (%s)'):format(tostring(maxW)))
            push( {
                action = 'DIAGNOSTICS_CHECKLIST_SET',
                id = 'maxw',
                status = 'fail',
                detail = tostring(maxW),
            })
        else
            appendLine(lines, ('Max súly (getPlayerMaxWeight / Config): %s'):format(tostring(maxW)))
            push( {
                action = 'DIAGNOSTICS_CHECKLIST_SET',
                id = 'maxw',
                status = 'ok',
                detail = tostring(maxW),
            })
        end
        pause()

        if not hf.isValidPlayerSource(runSrc) then
            integrityOptsBySrc[runSrc] = nil
            return
        end

        push( { action = 'DIAGNOSTICS_LIVE_HINT', text = 'canCarryItem szimuláció…' })
        push( { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'carry', status = 'running' })
        pause()

        if not ready then
            appendLine(lines, 'canCarry: kihagyva (item registry még nem ready).')
            push( {
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
                push( {
                    action = 'DIAGNOSTICS_CHECKLIST_SET',
                    id = 'carry',
                    status = 'fail',
                    detail = tostring(cRes),
                })
            elseif cRes then
                appendLine(lines, ('canCarryItem(%s x%s): OK'):format(testItem, testAmt))
                push( {
                    action = 'DIAGNOSTICS_CHECKLIST_SET',
                    id = 'carry',
                    status = 'ok',
                    detail = 'OK',
                })
            else
                appendLine(lines, ('canCarryItem(%s x%s): NEM, ok=%s'):format(testItem, testAmt, tostring(cReason)))
                push( {
                    action = 'DIAGNOSTICS_CHECKLIST_SET',
                    id = 'carry',
                    status = 'fail',
                    detail = tostring(cReason),
                })
            end
        end
        pause()

        if not hf.isValidPlayerSource(runSrc) then
            integrityOptsBySrc[runSrc] = nil
            return
        end

        if io.tryAddRemove then
            push( { action = 'DIAGNOSTICS_LIVE_HINT', text = 'addItem / removeItem…' })
            push( { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'mutate', status = 'running' })
            pause()

            if not ready then
                appendLine(lines, 'addItem/removeItem: kihagyva (item registry még nem ready).')
                push( {
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
                        push( {
                            action = 'DIAGNOSTICS_CHECKLIST_SET',
                            id = 'mutate',
                            status = 'ok',
                            detail = 'OK',
                        })
                    else
                        appendLine(lines, ('removeItem: HIBA %s (nézd kézzel az inventoryt)'):format(tostring(remReason)))
                        push( {
                            action = 'DIAGNOSTICS_CHECKLIST_SET',
                            id = 'mutate',
                            status = 'fail',
                            detail = tostring(remReason),
                        })
                    end
                else
                    appendLine(lines, ('addItem(%s x%s): NEM, ok=%s'):format(testItem, testAmt, tostring(addReason)))
                    push( {
                        action = 'DIAGNOSTICS_CHECKLIST_SET',
                        id = 'mutate',
                        status = 'fail',
                        detail = tostring(addReason),
                    })
                end
            end
            pause()
        end

        if not hf.isValidPlayerSource(runSrc) then
            integrityOptsBySrc[runSrc] = nil
            return
        end

        push( { action = 'DIAGNOSTICS_LOG_SET', lines = lines })
        push( {
            action = 'DIAGNOSTICS_LIVE_HINT',
            text = 'Szerver kész – nézd a játékot: megjelenik a progress sáv (vagy szakítsd meg).',
        })
        pause()

        TriggerClientEvent('e_core:integrityCheck:consoleOnly', runSrc, lines)

        if type(eCore.sendMessage) == 'function' then
            eCore:sendMessage(
                runSrc,
                io.inlineAdmin
                    and '[e_core] Integritás: részletek az admin Integritás fülön. A progress sáv a játék UI-ban indul.'
                    or '[e_core] Integritás: checklist a modálban. A progress sáv a játék UI-ban indul.',
                'info',
                7000
            )
        end

        awaitingProgress[runSrc] = GetGameTimer()
        integrityAwaitingInline[runSrc] = io.inlineAdmin == true
        awaitingClearToken[runSrc] = (awaitingClearToken[runSrc] or 0) + 1
        local token = awaitingClearToken[runSrc]
        SetTimeout(120000, function()
            if awaitingClearToken[runSrc] == token and awaitingProgress[runSrc] then
                awaitingProgress[runSrc] = nil
            end
        end)

        if hf.isValidPlayerSource(runSrc) then
            TriggerClientEvent('e_core:integrityCheck:progressTest', runSrc, {
                duration = io.progressDurationMs,
                adminInline = io.inlineAdmin == true,
            })
        end

        integrityOptsBySrc[runSrc] = nil
    end)
end

RegisterNetEvent('e_core:integrityCheck:request', function(opts)
    local src = source

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @return any result
    local function clearOpts()
        integrityOptsBySrc[src] = nil
    end

    integrityOptsBySrc[src] = mergeIntegrityOptsFromPayload(opts)

    local io0 = integrityOptsBySrc[src]
    local stepOnly = type(io0.onlyStep) == 'string' and hf.trim(io0.onlyStep) ~= ''
    local burstKey = stepOnly and 'e_core:integrityCheck:burst_step' or 'e_core:integrityCheck:burst'
    local burstMs = stepOnly and INTEGRITY_STEP_BURST_MS or 1500
    if not hf.netRateLimit(src, burstKey, burstMs) then
        clearOpts()
        return
    end
    local ok, err = integrityCanRun(src)
    if not ok then
        local wasInline = integrityOptsBySrc[src] and integrityOptsBySrc[src].inlineAdmin == true
        clearOpts()
        if hf.hasContent(err) then
            TriggerClientEvent(
                'e_core:integrityCheck:clientPrint',
                src,
                { '[e_core] ' .. err },
                'error',
                wasInline and { adminInline = true } or nil
            )
        end
        return
    end

    lastRun[src] = GetGameTimer()

    local xPlayer = eCore:getPlayer(src)
    if not xPlayer then
        local wasInline = integrityOptsBySrc[src] and integrityOptsBySrc[src].inlineAdmin == true
        clearOpts()
        TriggerClientEvent(
            'e_core:integrityCheck:clientPrint',
            src,
            { '[e_core] Nem található játékos (getPlayer).' },
            'error',
            wasInline and { adminInline = true } or nil
        )
        return
    end

    local ioReq = activeIntegrityOpts(src)
    if ioReq.useNui == false then
        local lines = {}
        appendLine(lines, '--- e_core integritás (szerver) ---')
        appendLine(lines, ('Resource: %s'):format(GetCurrentResourceName()))
        local fw = exports[GetCurrentResourceName()]:getFrameWork()
        appendLine(lines, ('Framework: %s'):format(tostring(fw)))
        appendLine(lines, ('isReady (szerver): %s'):format(tostring(eCore:isReady() == true)))
        appendItemConvertDiagnostics(lines)
        runProfessionRegistryChecks(lines)
        runInventoryChecks(xPlayer, lines, ioReq)
        TriggerClientEvent(
            'e_core:integrityCheck:clientPrint',
            src,
            lines,
            'server',
            ioReq.inlineAdmin and { adminInline = true } or nil
        )
        if type(eCore.sendMessage) == 'function' then
            eCore:sendMessage(
                src,
                '[e_core] Integritás: sorok a F8 konzolon. Indul a progress teszt…',
                'info',
                6000
            )
        end
        awaitingProgress[src] = GetGameTimer()
        integrityAwaitingInline[src] = ioReq.inlineAdmin == true
        awaitingClearToken[src] = (awaitingClearToken[src] or 0) + 1
        local token = awaitingClearToken[src]
        SetTimeout(120000, function()
            if awaitingClearToken[src] == token and awaitingProgress[src] then
                awaitingProgress[src] = nil
            end
        end)
        TriggerClientEvent('e_core:integrityCheck:progressTest', src, {
            duration = ioReq.progressDurationMs,
            adminInline = ioReq.inlineAdmin == true,
        })
        clearOpts()
        return
    end

    runIntegrityServerSequence(src, xPlayer)
end)

RegisterNetEvent('e_core:integrityCheck:progressResult', function(success)
    local src = source
    if not hf.netRateLimit(src, 'e_core:integrityCheck:progressResult', 500) then
        return
    end
    if not hf.isValidPlayerSource(src) then
        return
    end
    if not awaitingProgress[src] then
        return
    end
    awaitingProgress[src] = nil
    local inlineWas = integrityAwaitingInline[src] == true
    integrityAwaitingInline[src] = nil

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
    TriggerClientEvent(
        'e_core:integrityCheck:clientPrint',
        src,
        lines,
        'progress',
        inlineWas and { adminInline = true } or nil
    )
    diagNuiPush(src, {
        action = 'DIAGNOSTICS_LIVE_HINT',
        text = success and 'Progress: sikeres lefutás (onFinish).' or 'Progress: megszakítva vagy hiba (onCancel).',
    }, { useNui = true, inlineAdmin = inlineWas })
end)
