--- Szerver oldali integritás-ellenőrzés: súly, max súly, canCarry, opc. add/remove; kliens progress teszt.
--- NUI: lépésenkénti checklist (kis szünetekkel, hogy látszódjon a futás).
local hf = hf

local lastRun = {}
local awaitingProgress = {}
local awaitingClearToken = {}
local diagnosticsRuns = {}
local diagnosticsRunSeq = 0
local diagnosticsActiveRuns = 0
local DIAGNOSTICS_MAX_CONCURRENT = 2

local DIAGNOSTICS_ADMIN_TESTS = {
    registry_integrity = {
        key = 'registry_integrity',
        label = 'Profession registry konzisztencia',
        severity = 'high',
        estimatedCost = 'low',
        docHints = {
            { docId = 'PROFESSION_REGISTRY_IMPLEMENTACIOS_TERV_SPRINT1_HU', sectionKey = 'task-6-minimal-diagnostics-es-dokumentacio', confidence = 0.95 },
            { docId = 'PUBLIC_API_HU', sectionKey = 'server-exportok', confidence = 0.75 },
        },
    },
    ['profession-key-validation'] = {
        key = 'profession-key-validation',
        label = 'Profession kulcs validacio',
        severity = 'high',
        estimatedCost = 'low',
        docHints = {
            { docId = 'PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU', sectionKey = 'fazis-3-e_core-only-elokeszites-consumer-hid', confidence = 0.98 },
            { docId = 'PROFESSION_REGISTRY_IMPLEMENTACIOS_TERV_SPRINT1_HU', sectionKey = 'fazis-3-e_core-only-elokeszites-belepo-blokk', confidence = 0.95 },
            { docId = 'PUBLIC_API_HU', sectionKey = 'server-exportok', confidence = 0.8 },
        },
    },
}

local function diagnostics_admin_response(ok, code, message, data)
    return {
        ok = ok == true,
        code = code or (ok and eCoreErr.ok or eCoreErr.unknown_error),
        message = message or '',
        data = data or {},
    }
end

local function clone_doc_hints(hints)
    local out = {}
    for _, hint in ipairs(hints or {}) do
        if type(hint) == 'table' then
            out[#out + 1] = {
                docId = hint.docId,
                sectionKey = hint.sectionKey,
                confidence = hint.confidence,
            }
        end
    end
    return out
end

local function diagnostics_admin_can_access(payload)
    return hf.adminApiCanAccess('diagnostics', payload)
end

local function diagnostics_access_denied(action, payload, reason)
    if type(hf.auditAdminApiDenied) == 'function' then
        hf.auditAdminApiDenied('diagnostics', action, payload, reason)
    end
    return diagnostics_admin_response(false, eCoreErr.access_denied, reason or 'Nincs jogosultság.')
end

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

local function runProfessionRegistryAudit()
    local lines = {}
    appendLine(lines, '--- Profession registry ellenőrzés ---')

    local okRegistry, registryOrErr = getProfessionRegistry()
    if not okRegistry then
        appendLine(lines, ('getProfessionRegistry: HIBA (%s)'):format(tostring(registryOrErr)))
        return {
            key = 'registry_integrity',
            passed = false,
            code = tostring(registryOrErr),
            summary = 'A profession registry nem érhető el.',
            lines = lines,
            issueCount = 1,
        }
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
        return {
            key = 'registry_integrity',
            passed = false,
            code = eCoreErr.profession_registry_unavailable,
            summary = 'Nincs profession rekord a registryben.',
            lines = lines,
            issueCount = 1,
        }
    end

    if missingProfile > 0 or profileIssues > 0 then
        appendLine(lines, ('Registry státusz: HIBA (missingProfile=%s, profileIssues=%s)'):format(
            tostring(missingProfile),
            tostring(profileIssues)
        ))
        return {
            key = 'registry_integrity',
            passed = false,
            code = eCoreErr.profession_profile_not_found,
            summary = 'A registry profile referenciái sérültek vagy hiányosak.',
            lines = lines,
            issueCount = missingProfile + profileIssues,
        }
    end

    appendLine(lines, 'Registry státusz: OK')
    return {
        key = 'registry_integrity',
        passed = true,
        code = eCoreErr.ok,
        summary = 'A profession registry konzisztens.',
        lines = lines,
        issueCount = 0,
    }
end

local function runProfessionKeyValidationAudit(run)
    local lines = {}
    appendLine(lines, '--- Profession kulcs validacio ---')

    local okRegistry, registryOrErr = getProfessionRegistry()
    if not okRegistry then
        appendLine(lines, ('getProfessionRegistry: HIBA (%s)'):format(tostring(registryOrErr)))
        return {
            key = 'profession-key-validation',
            passed = false,
            code = tostring(registryOrErr),
            summary = 'A profession registry nem érhető el kulcsvalidációhoz.',
            lines = lines,
            issueCount = 1,
        }
    end

    local payload = type(run) == 'table' and type(run.requestPayload) == 'table' and run.requestPayload or {}
    local keysByCategory = type(payload.professionKeysByCategory) == 'table' and payload.professionKeysByCategory or nil

    local categoriesToValidate = {}
    if keysByCategory ~= nil then
        for category, rawKeys in pairs(keysByCategory) do
            if type(rawKeys) == 'table' then
                categoriesToValidate[#categoriesToValidate + 1] = {
                    category = category,
                    keys = rawKeys,
                }
            end
        end
    else
        for category, byName in pairs(registryOrErr) do
            if type(byName) == 'table' then
                local keys = {}
                for professionName in pairs(byName) do
                    keys[#keys + 1] = professionName
                end
                categoriesToValidate[#categoriesToValidate + 1] = {
                    category = category,
                    keys = keys,
                }
            end
        end
    end

    table.sort(categoriesToValidate, function(a, b)
        return tostring(a.category) < tostring(b.category)
    end)

    local issueCount = 0
    local checkedCategories = 0

    for _, entry in ipairs(categoriesToValidate) do
        local okValidate, validationOrErr = validateProfessionKeys(entry.category, entry.keys)
        if not okValidate then
            issueCount = issueCount + 1
            appendLine(
                lines,
                ('validateProfessionKeys hiba: %s -> %s'):format(tostring(entry.category), tostring(validationOrErr))
            )
        else
            checkedCategories = checkedCategories + 1
            local invalidCount = #(validationOrErr.invalid or {})
            local missingProfileCount = #(validationOrErr.missingProfile or {})
            issueCount = issueCount + invalidCount + missingProfileCount
            appendLine(lines, ('%s: valid=%s invalid=%s missingProfile=%s'):format(
                tostring(validationOrErr.category),
                tostring(#(validationOrErr.valid or {})),
                tostring(invalidCount),
                tostring(missingProfileCount)
            ))
        end
    end

    if checkedCategories == 0 then
        appendLine(lines, 'Nincs validalhato kategória a futáshoz.')
        return {
            key = 'profession-key-validation',
            passed = false,
            code = eCoreErr.invalid_item_data,
            summary = 'Nincs validálható profession kategória.',
            lines = lines,
            issueCount = 1,
        }
    end

    local passed = issueCount == 0
    if passed then
        appendLine(lines, 'Profession kulcs validáció státusz: OK')
    else
        appendLine(lines, ('Profession kulcs validáció státusz: HIBA (issues=%s)'):format(tostring(issueCount)))
    end

    return {
        key = 'profession-key-validation',
        passed = passed,
        code = passed and eCoreErr.ok or eCoreErr.profession_not_found,
        summary = passed and 'A profession kulcsvalidáció sikeres.' or 'A profession kulcsvalidáció hibákat talált.',
        lines = lines,
        issueCount = issueCount,
    }
end

local function serialize_run_view(run)
    return {
        runId = run.runId,
        status = run.status,
        createdAt = run.createdAt,
        updatedAt = run.updatedAt,
        requestedBy = run.requestedBy,
        requestedTests = run.requestedTests,
        tests = run.tests,
        startedAt = run.startedAt,
        finishedAt = run.finishedAt,
        cancelRequested = run.cancelRequested == true,
        summary = run.summary,
        results = run.results,
    }
end

local function diagnostics_execute_run(run)
    run.status = 'running'
    run.startedAt = os.time()
    run.updatedAt = run.startedAt
    run.results = {}

    for _, testKey in ipairs(run.tests) do
        if run.cancelRequested then
            run.status = 'cancelled'
            run.updatedAt = os.time()
            run.finishedAt = run.updatedAt
            run.summary = {
                passed = 0,
                failed = 0,
                cancelled = true,
            }
            return
        end

        local testDef = DIAGNOSTICS_ADMIN_TESTS[testKey]
        if testKey == 'registry_integrity' then
            local result = runProfessionRegistryAudit()
            result.docHints = (not result.passed) and clone_doc_hints(testDef.docHints) or {}
            run.results[#run.results + 1] = result
        elseif testKey == 'profession-key-validation' then
            local result = runProfessionKeyValidationAudit(run)
            result.docHints = (not result.passed) and clone_doc_hints(testDef.docHints) or {}
            run.results[#run.results + 1] = result
        end
    end

    local passed = 0
    local failed = 0
    for _, result in ipairs(run.results) do
        if result.passed then
            passed = passed + 1
        else
            failed = failed + 1
        end
    end

    run.finishedAt = os.time()
    run.updatedAt = run.finishedAt
    run.status = failed > 0 and 'failed' or 'passed'
    run.summary = {
        passed = passed,
        failed = failed,
        cancelled = false,
    }
end

local function diagnostics_schedule_queued_runs()
    if diagnosticsActiveRuns >= DIAGNOSTICS_MAX_CONCURRENT then
        return
    end

    local nextRun = nil
    for _, run in pairs(diagnosticsRuns) do
        if run.status == 'queued' then
            if not nextRun or run.createdAt < nextRun.createdAt then
                nextRun = run
            end
        end
    end

    if not nextRun then
        return
    end

    diagnosticsActiveRuns = diagnosticsActiveRuns + 1
    CreateThread(function()
        diagnostics_execute_run(nextRun)
        diagnosticsActiveRuns = math.max(0, diagnosticsActiveRuns - 1)
        diagnostics_schedule_queued_runs()
    end)
end

function diagnosticsAdminListTests(payload)
    local accessOk, accessErr = diagnostics_admin_can_access(payload)
    if not accessOk then
        return diagnostics_access_denied('diagnosticsAdminListTests', payload, accessErr)
    end

    local items = {}
    for _, test in pairs(DIAGNOSTICS_ADMIN_TESTS) do
        items[#items + 1] = {
            key = test.key,
            label = test.label,
            severity = test.severity,
            estimatedCost = test.estimatedCost,
            docHints = clone_doc_hints(test.docHints),
        }
    end
    table.sort(items, function(a, b)
        return tostring(a.key) < tostring(b.key)
    end)

    return diagnostics_admin_response(true, eCoreErr.ok, 'Diagnostics tesztlista lekérve.', { items = items })
end

function diagnosticsAdminRun(payload)
    if type(payload) ~= 'table' then
        return diagnostics_admin_response(false, eCoreErr.invalid_item_data, 'Érvénytelen payload.')
    end
    local accessOk, accessErr = diagnostics_admin_can_access(payload)
    if not accessOk then
        return diagnostics_access_denied('diagnosticsAdminRun', payload, accessErr)
    end

    local requested = payload.tests
    if type(requested) ~= 'table' or #requested == 0 then
        return diagnostics_admin_response(false, eCoreErr.invalid_item_data, 'Legalább egy diagnostics test kulcs szükséges.')
    end

    local seen = {}
    local tests = {}
    for _, key in ipairs(requested) do
        local testKey = tostring(key)
        if DIAGNOSTICS_ADMIN_TESTS[testKey] == nil then
            return diagnostics_admin_response(false, eCoreErr.invalid_item_data, ('Ismeretlen diagnostics test: %s'):format(testKey))
        end
        if not seen[testKey] then
            seen[testKey] = true
            tests[#tests + 1] = testKey
        end
    end

    diagnosticsRunSeq = diagnosticsRunSeq + 1
    local runId = ('diag-%08d'):format(diagnosticsRunSeq)
    local now = os.time()
    local run = {
        runId = runId,
        status = 'queued',
        createdAt = now,
        updatedAt = now,
        requestedBy = tostring(payload.requestedBy or 'unknown'),
        requestPayload = payload,
        requestedTests = requested,
        tests = tests,
        cancelRequested = false,
        summary = { passed = 0, failed = 0, cancelled = false },
        results = {},
    }
    diagnosticsRuns[runId] = run

    diagnostics_schedule_queued_runs()

    return diagnostics_admin_response(true, eCoreErr.ok, 'Diagnostics futás sorba állítva.', {
        run = serialize_run_view(run),
    })
end

function diagnosticsAdminGetRun(runId, payload)
    local accessOk, accessErr = diagnostics_admin_can_access(payload)
    if not accessOk then
        return diagnostics_access_denied('diagnosticsAdminGetRun', payload, accessErr)
    end

    local key = hf.trim(tostring(runId or ''))
    if key == '' then
        return diagnostics_admin_response(false, eCoreErr.invalid_item_data, 'Hiányzó runId.')
    end

    local run = diagnosticsRuns[key]
    if not run then
        return diagnostics_admin_response(false, eCoreErr.profession_not_found, 'Diagnostics run nem található.')
    end

    return diagnostics_admin_response(true, eCoreErr.ok, 'Diagnostics futás lekérve.', {
        run = serialize_run_view(run),
    })
end

function diagnosticsAdminCancelRun(runId, payload)
    local accessOk, accessErr = diagnostics_admin_can_access(payload)
    if not accessOk then
        return diagnostics_access_denied('diagnosticsAdminCancelRun', payload, accessErr)
    end

    local key = hf.trim(tostring(runId or ''))
    if key == '' then
        return diagnostics_admin_response(false, eCoreErr.invalid_item_data, 'Hiányzó runId.')
    end

    local run = diagnosticsRuns[key]
    if not run then
        return diagnostics_admin_response(false, eCoreErr.profession_not_found, 'Diagnostics run nem található.')
    end
    if run.status == 'passed' or run.status == 'failed' or run.status == 'cancelled' then
        return diagnostics_admin_response(false, eCoreErr.invalid_item_data, 'A futás már lezárult, nem megszakítható.')
    end

    run.cancelRequested = true
    run.updatedAt = os.time()

    return diagnostics_admin_response(true, eCoreErr.ok, 'Diagnostics futás megszakításra jelölve.', {
        run = serialize_run_view(run),
    })
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
            { id = 'registry', label = 'Profession registry konzisztencia' },
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
        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_LIVE_HINT', text = 'Profession registry ellenőrzése…' })
        diagNuiPush(runSrc, { action = 'DIAGNOSTICS_CHECKLIST_SET', id = 'registry', status = 'running' })
        diagUiPause()

        local registryOk = runProfessionRegistryChecks(lines)
        diagNuiPush(runSrc, {
            action = 'DIAGNOSTICS_CHECKLIST_SET',
            id = 'registry',
            status = registryOk and 'ok' or 'fail',
            detail = registryOk and 'OK' or 'hibák a részletes logban',
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
        runProfessionRegistryChecks(lines)
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
