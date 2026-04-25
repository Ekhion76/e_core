--- Server-side registry diagnostics admin (`diagnosticsAdmin*`, queued runs).
--- Integrity checklist lives in `server/integrity_check.lua` (`e_core:integrityCheck:*`).
local hf = hf

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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param ok any
--- @param code any
--- @param message any
--- @param data table
--- @return any result
local function diagnostics_admin_response(ok, code, message, data)
    return {
        ok = ok == true,
        code = code or (ok and eCoreErr.ok or eCoreErr.unknown_error),
        message = message or '',
        data = data or {},
    }
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param hints any
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param payload table
--- @return any result
local function diagnostics_admin_can_access(payload)
    return hf.adminApiCanAccess('diagnostics', payload)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param action any
--- @param payload table
--- @param reason string
--- @return any result
local function diagnostics_access_denied(action, payload, reason)
    if type(hf.auditAdminApiDenied) == 'function' then
        hf.auditAdminApiDenied('diagnostics', action, payload, reason)
    end
    return diagnostics_admin_response(false, eCoreErr.access_denied, reason or 'Nincs jogosultság.')
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param lines any
--- @param text any
--- @return any result
local function appendLine(lines, text)
    lines[#lines + 1] = text
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param run any
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param run any
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param run any
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param payload table
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param payload table
--- @return any result
function diagnosticsAdminListRuns(payload)
    local accessOk, accessErr = diagnostics_admin_can_access(payload)
    if not accessOk then
        return diagnostics_access_denied('diagnosticsAdminListRuns', payload, accessErr)
    end

    local items = {}
    for _, run in pairs(diagnosticsRuns) do
        items[#items + 1] = serialize_run_view(run)
    end
    table.sort(items, function(a, b)
        return (tonumber(a.createdAt) or 0) > (tonumber(b.createdAt) or 0)
    end)

    return diagnostics_admin_response(true, eCoreErr.ok, 'Diagnostics futások listája.', { items = items })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param payload table
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param runId number
--- @param payload table
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param runId number
--- @param payload table
--- @return any result
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
