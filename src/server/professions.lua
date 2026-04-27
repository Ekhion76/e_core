local DEFAULT_PROFILE_KEY = 'default_global'
local DEFAULT_PROFILE_NAME = 'Default Progression'
local DEFAULT_PROFILE_MODE = 'advanced'
local DEFAULT_PROFILE_AUTHOR = 'system:bootstrap'
local PROFESSION_CACHE_TTL_SEC = 30

local DEFAULT_PROFESSIONS = {
    { category = 'crafting', name = 'weaponry', displayName = 'Weaponry' },
    { category = 'crafting', name = 'chemist', displayName = 'Chemist' },
    { category = 'crafting', name = 'cooking', displayName = 'Cooking' },
    { category = 'crafting', name = 'foundry', displayName = 'Foundry' },
    { category = 'crafting', name = 'handicraft', displayName = 'Handicraft' },
    { category = 'harvesting', name = 'gathering', displayName = 'Gathering' },
}

local PROFESSION_REGISTRY_CACHE = {
    data = nil,
    loadedAt = 0,
}
local CLEANUP_JOB_SEQ = 0
local CLEANUP_JOBS = {}
local CLEANUP_AUDIT_LOG = {}
local CLEANUP_AUDIT_LIMIT = 100
local CLEANUP_MAX_CONCURRENT = 1
local CLEANUP_ACTIVE_RUNS = 0
local hfe = hfe
local db_execute
local db_single
local db_query
local cleanup_job_persist

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function invalidate_profession_registry_cache()
    PROFESSION_REGISTRY_CACHE.data = nil
    PROFESSION_REGISTRY_CACHE.loadedAt = 0
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param ok any
--- @param code any
--- @param message any
--- @param data table
--- @return any result
local function admin_response(ok, code, message, data)
    return {
        ok = ok == true,
        code = code or (ok and eCoreErr.ok or eCoreErr.unknown_error),
        message = message or '',
        data = data or {},
    }
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param eventType any
--- @param actor any
--- @param target any
--- @param outcome any
--- @param details any
--- @return any result
local function append_cleanup_audit(eventType, actor, target, outcome, details)
    CLEANUP_AUDIT_LOG[#CLEANUP_AUDIT_LOG + 1] = {
        ts = os.time(),
        eventType = eventType,
        actor = actor or {},
        target = target or {},
        outcome = outcome or {},
        details = details or {},
        payload = details or {}, -- legacy alias
    }
    while #CLEANUP_AUDIT_LOG > CLEANUP_AUDIT_LIMIT do
        table.remove(CLEANUP_AUDIT_LOG, 1)
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param payload table
--- @return any result
local function cleanup_admin_can_access(payload)
    return hfe.adminApiCanAccess('cleanup', payload)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param payload table
--- @return any result
local function admin_audit_can_access(payload)
    local okCleanup = hfe.adminApiCanAccess('cleanup', payload)
    if okCleanup then
        return true, nil
    end
    local okDiagnostics = hfe.adminApiCanAccess('diagnostics', payload)
    if okDiagnostics then
        return true, nil
    end
    return false, eCoreErr.admin_audit_dual_policy_denied
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param action any
--- @param payload table
--- @param reason string
--- @return any result
local function cleanup_access_denied(action, payload, reason)
    if type(hfe.auditAdminApiDenied) == 'function' then
        hfe.auditAdminApiDenied('cleanup', action, payload, reason)
    end
    append_cleanup_audit(
        'access_denied',
        {
            source = type(payload) == 'table' and type(payload.auth) == 'table' and tonumber(payload.auth.source) or nil,
            requestedBy = type(payload) == 'table' and payload.requestedBy or nil,
        },
        {
            scope = 'cleanup',
            action = action,
        },
        {
            status = 'denied',
            reason = reason or 'access_denied',
        }
    )
    return admin_response(false, eCoreErr.access_denied, reason or 'Nincs jogosultság.')
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function cleanup_meta_storage()
    if QB_CORE then
        return {
            tableName = 'players',
            idColumn = 'citizenid',
        }
    end
    return {
        tableName = 'users',
        idColumn = 'identifier',
    }
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function cleanup_next_job_id()
    CLEANUP_JOB_SEQ = CLEANUP_JOB_SEQ + 1
    return ('cleanup-%08d'):format(CLEANUP_JOB_SEQ)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param job string
--- @return any result
local function cleanup_serialize_job(job)
    return {
        jobId = job.jobId,
        status = job.status,
        mode = job.mode,
        category = job.category,
        name = job.name,
        requestedBy = job.requestedBy,
        batchSize = job.batchSize,
        createdAt = job.createdAt,
        updatedAt = job.updatedAt,
        startedAt = job.startedAt,
        finishedAt = job.finishedAt,
        lastCursor = job.lastCursor,
        cancelRequested = job.cancelRequested == true,
        stats = {
            processed = job.stats.processed,
            changed = job.stats.changed,
            removedKeys = job.stats.removedKeys,
            failed = job.stats.failed,
            invalidJson = job.stats.invalidJson,
        },
        errors = job.errors,
    }
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param errorsJson any
--- @return any result
local function cleanup_decode_errors(errorsJson)
    if type(errorsJson) ~= 'string' or errorsJson == '' then
        return {}
    end
    local ok, decoded = pcall(json.decode, errorsJson)
    if not ok or type(decoded) ~= 'table' then
        return {}
    end
    return decoded
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param errors any
--- @return any result
local function cleanup_encode_errors(errors)
    if type(errors) ~= 'table' then
        return '[]'
    end
    local encoded = json.encode(errors)
    if type(encoded) ~= 'string' or encoded == '' then
        return '[]'
    end
    return encoded
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param raw any
--- @return any result
local function cleanup_parse_timestamp(raw)
    if type(raw) ~= 'string' or raw == '' then
        return nil
    end
    local y, m, d, hh, mm, ss = raw:match('^(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)$')
    if not y then
        return nil
    end
    return os.time({
        year = tonumber(y),
        month = tonumber(m),
        day = tonumber(d),
        hour = tonumber(hh),
        min = tonumber(mm),
        sec = tonumber(ss),
    })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param row any
--- @return any result
local function cleanup_job_from_row(row)
    local createdAt = cleanup_parse_timestamp(row.created_at) or os.time()
    local updatedAt = cleanup_parse_timestamp(row.updated_at) or createdAt

    local job = {
        jobId = tostring(row.job_id),
        status = tostring(row.status or 'failed'),
        mode = tostring(row.mode or 'dry_run'),
        category = tostring(row.category or ''),
        name = tostring(row.name or ''),
        requestedBy = tostring(row.requested_by or 'unknown'),
        batchSize = math.max(100, math.min(2000, math.floor(tonumber(row.batch_size) or 500))),
        createdAt = createdAt,
        updatedAt = updatedAt,
        startedAt = cleanup_parse_timestamp(row.started_at),
        finishedAt = cleanup_parse_timestamp(row.finished_at),
        lastCursor = tostring(row.last_cursor or ''),
        cancelRequested = tonumber(row.cancel_requested) == 1,
        stats = {
            processed = math.max(0, math.floor(tonumber(row.processed) or 0)),
            changed = math.max(0, math.floor(tonumber(row.changed_rows) or 0)),
            removedKeys = math.max(0, math.floor(tonumber(row.removed_keys) or 0)),
            failed = math.max(0, math.floor(tonumber(row.failed) or 0)),
            invalidJson = math.max(0, math.floor(tonumber(row.invalid_json) or 0)),
        },
        errors = cleanup_decode_errors(row.errors_json),
    }
    return job
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param meta table
--- @param category any
--- @param name string
--- @return any result
local function cleanup_remove_profession_key(meta, category, name)
    if type(meta) ~= 'table' then
        return false, 0
    end
    local slot = meta[category]
    if type(slot) ~= 'table' then
        return false, 0
    end
    if rawget(slot, name) == nil then
        return false, 0
    end
    slot[name] = nil
    if next(slot) == nil then
        meta[category] = nil
    end
    return true, 1
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param job string
--- @return any result
local function cleanup_job_step(job)
    local storage = cleanup_meta_storage()
    local rowsOk, rows = db_query(
        ('professions:cleanup:scan:%s'):format(job.jobId),
        ([[SELECT `%s` AS `playerKey`, `e_core` FROM `%s` WHERE `%s` > ? AND `e_core` IS NOT NULL AND `e_core` <> '' ORDER BY `%s` ASC LIMIT ?]]):format(
            storage.idColumn,
            storage.tableName,
            storage.idColumn,
            storage.idColumn
        ),
        { job.lastCursor or '', job.batchSize }
    )
    if not rowsOk then
        return false, eCoreErr.cleanup_scan_failed
    end
    if #rows == 0 then
        return true, true
    end

    for _, row in ipairs(rows) do
        if job.cancelRequested then
            return true, false
        end

        local playerKey = tostring(row.playerKey or '')
        job.lastCursor = playerKey
        job.stats.processed = job.stats.processed + 1

        local decodeOk, decoded = pcall(json.decode, row.e_core)
        if not decodeOk or type(decoded) ~= 'table' then
            job.stats.failed = job.stats.failed + 1
            job.stats.invalidJson = job.stats.invalidJson + 1
            if #job.errors < 10 then
                job.errors[#job.errors + 1] = ('invalid_json:%s'):format(playerKey)
            end
        else
            local changed, removed = cleanup_remove_profession_key(decoded, job.category, job.name)
            if changed then
                job.stats.changed = job.stats.changed + 1
                job.stats.removedKeys = job.stats.removedKeys + removed
                if job.mode == 'apply' then
                    local updateOk = db_execute(
                        ('professions:cleanup:update:%s:%s'):format(job.jobId, playerKey),
                        ([[UPDATE `%s` SET `e_core` = ? WHERE `%s` = ? LIMIT 1]]):format(storage.tableName, storage.idColumn),
                        { json.encode(decoded), playerKey }
                    )
                    if not updateOk then
                        job.stats.failed = job.stats.failed + 1
                        if #job.errors < 10 then
                            job.errors[#job.errors + 1] = ('update_failed:%s'):format(playerKey)
                        end
                    end
                end
            end
        end
    end

    return true, false
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param job string
--- @return any result
local function cleanup_job_execute(job)
    job.status = 'running'
    if not job.startedAt then
        job.startedAt = os.time()
    end
    job.updatedAt = job.startedAt
    cleanup_job_persist(job)
    append_cleanup_audit(
        'cleanup_job_started',
        {
            requestedBy = job.requestedBy,
        },
        {
            jobId = job.jobId,
            mode = job.mode,
            profession = ('%s.%s'):format(job.category, job.name),
        },
        {
            status = 'started',
        }
    )

    while true do
        if job.cancelRequested then
            job.status = 'cancelled'
            break
        end

        local ok, finishedOrErr = cleanup_job_step(job)
        job.updatedAt = os.time()
        cleanup_job_persist(job)
        if not ok then
            job.status = 'failed'
            job.errors[#job.errors + 1] = tostring(finishedOrErr)
            break
        end
        if finishedOrErr == true then
            job.status = 'passed'
            break
        end
        Wait(0)
    end

    job.finishedAt = os.time()
    job.updatedAt = job.finishedAt

    if job.status == 'passed' and job.mode == 'apply' and job.deleteProfession == true then
        local deleteRes = professionAdminDelete(job.category, job.name)
        if deleteRes and deleteRes.ok then
            append_cleanup_audit(
                'profession_deleted_after_cleanup',
                {
                    requestedBy = job.requestedBy,
                },
                {
                    jobId = job.jobId,
                    profession = ('%s.%s'):format(job.category, job.name),
                },
                {
                    status = 'success',
                }
            )
        else
            job.status = 'failed'
            job.errors[#job.errors + 1] = 'post_cleanup_delete_failed'
        end
    end

    cleanup_job_persist(job)
    append_cleanup_audit(
        'cleanup_job_finished',
        {
            requestedBy = job.requestedBy,
        },
        {
            jobId = job.jobId,
            mode = job.mode,
            profession = ('%s.%s'):format(job.category, job.name),
        },
        {
            status = job.status,
        },
        {
            stats = job.stats,
        }
    )
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function cleanup_job_schedule()
    if CLEANUP_ACTIVE_RUNS >= CLEANUP_MAX_CONCURRENT then
        return
    end

    local nextJob = nil
    for _, job in pairs(CLEANUP_JOBS) do
        if job.status == 'queued' then
            if not nextJob or job.createdAt < nextJob.createdAt then
                nextJob = job
            end
        end
    end
    if not nextJob then
        return
    end

    CLEANUP_ACTIVE_RUNS = CLEANUP_ACTIVE_RUNS + 1
    CreateThread(function()
        cleanup_job_execute(nextJob)
        CLEANUP_ACTIVE_RUNS = math.max(0, CLEANUP_ACTIVE_RUNS - 1)
        cleanup_job_schedule()
    end)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param mode any
--- @param category any
--- @param name string
--- @param payload table
--- @return any result
local function cleanup_job_create(mode, category, name, payload)
    local batchSize = math.floor(tonumber((payload or {}).batchSize) or 500)
    batchSize = math.max(100, math.min(2000, batchSize))

    local job = {
        jobId = cleanup_next_job_id(),
        status = 'queued',
        mode = mode,
        category = category,
        name = name,
        requestedBy = tostring((payload or {}).requestedBy or 'unknown'),
        batchSize = batchSize,
        createdAt = os.time(),
        updatedAt = os.time(),
        startedAt = nil,
        finishedAt = nil,
        lastCursor = '',
        cancelRequested = false,
        stats = {
            processed = 0,
            changed = 0,
            removedKeys = 0,
            failed = 0,
            invalidJson = 0,
        },
        errors = {},
    }
    CLEANUP_JOBS[job.jobId] = job
    cleanup_job_persist(job)
    return job
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function e_core_bootstrap_cleanup_jobs()
    local ok, rows = db_query(
        'professions:cleanup:bootstrap',
        [[
            SELECT
                `job_id`, `status`, `mode`, `category`, `name`, `requested_by`, `batch_size`, `last_cursor`,
                `processed`, `changed_rows`, `removed_keys`, `failed`, `invalid_json`,
                `cancel_requested`, `errors_json`, `created_at`, `updated_at`, `started_at`, `finished_at`
            FROM `e_core_cleanup_jobs`
            ORDER BY `created_at` DESC
            LIMIT 200
        ]]
    )
    if not ok then
        cLog('[e_core] cleanup bootstrap: e_core_cleanup_jobs nem olvasható', 'warning', 2)
        return
    end

    local recoveredRunning = 0
    for _, row in ipairs(rows) do
        local job = cleanup_job_from_row(row)
        local numericPart = tonumber(string.match(job.jobId, '^cleanup%-(%d+)$') or '0') or 0
        if numericPart > CLEANUP_JOB_SEQ then
            CLEANUP_JOB_SEQ = numericPart
        end

        if job.status == 'running' or job.status == 'queued' then
            job.status = 'failed'
            job.cancelRequested = false
            job.updatedAt = os.time()
            job.errors[#job.errors + 1] = 'recovered_after_restart'
            recoveredRunning = recoveredRunning + 1
            cleanup_job_persist(job)
        end

        CLEANUP_JOBS[job.jobId] = job
    end

    if recoveredRunning > 0 then
        cLog(('[e_core] cleanup bootstrap: %s megszakadt job fail állapotba állítva (restart recovery)'):format(recoveredRunning), 'warning', 1)
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param jobId number
--- @return any result
local function cleanup_job_resolve(jobId)
    local job = CLEANUP_JOBS[jobId]
    if job then
        return job
    end

    local ok, row = db_single(
        ('professions:cleanup:get:%s'):format(jobId),
        [[
            SELECT
                `job_id`, `status`, `mode`, `category`, `name`, `requested_by`, `batch_size`, `last_cursor`,
                `processed`, `changed_rows`, `removed_keys`, `failed`, `invalid_json`,
                `cancel_requested`, `errors_json`, `created_at`, `updated_at`, `started_at`, `finished_at`
            FROM `e_core_cleanup_jobs`
            WHERE `job_id` = ?
            LIMIT 1
        ]],
        { jobId }
    )
    if not ok or not row then
        return nil
    end
    job = cleanup_job_from_row(row)
    CLEANUP_JOBS[job.jobId] = job
    return job
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param value any
--- @return any result
local function normalize_registry_key(value)
    if type(value) ~= 'string' then
        return nil, eCoreErr.no_valid_meta_name
    end
    local key = hf.trim(value)
    if key == '' then
        return nil, eCoreErr.no_valid_meta_name
    end
    return key, nil
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param value any
--- @return any result
local function deep_copy(value)
    if type(value) ~= 'table' then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = deep_copy(v)
    end
    return out
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function get_registry_counts()
    local ok, rows = hfe.mysqlAwait('professions:bootstrap:counts', function()
        return MySQL.query.await([[
            SELECT
                (SELECT COUNT(*) FROM `e_core_level_profiles`) AS `profilesCount`,
                (SELECT COUNT(*) FROM `e_core_professions`) AS `professionsCount`
        ]])
    end)

    if not ok then
        cLog('[e_core] profession bootstrap: nem sikerült lekérdezni a registry táblák állapotát', 'warning', 2)
        return nil, nil
    end

    if not rows or not rows[1] then
        return 0, 0
    end

    return tonumber(rows[1].profilesCount) or 0, tonumber(rows[1].professionsCount) or 0
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param levelsJson any
--- @return any result
local function ensure_default_profile(levelsJson)
    local okInsert = hfe.mysqlAwait('professions:bootstrap:profile:insert', function()
        MySQL.query.await(
            [[
                INSERT INTO `e_core_level_profiles` (`profile_key`, `display_name`, `mode`, `levels_json`, `created_by`)
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    `display_name` = VALUES(`display_name`),
                    `mode` = VALUES(`mode`),
                    `levels_json` = VALUES(`levels_json`),
                    `updated_at` = CURRENT_TIMESTAMP
            ]],
            { DEFAULT_PROFILE_KEY, DEFAULT_PROFILE_NAME, DEFAULT_PROFILE_MODE, levelsJson, DEFAULT_PROFILE_AUTHOR }
        )
    end)

    if not okInsert then
        cLog('[e_core] profession bootstrap: default level profile mentése sikertelen', 'warning', 2)
        return nil
    end

    local okId, row = hfe.mysqlAwait('professions:bootstrap:profile:id', function()
        return MySQL.single.await(
            'SELECT `id` FROM `e_core_level_profiles` WHERE `profile_key` = ? LIMIT 1',
            { DEFAULT_PROFILE_KEY }
        )
    end)

    if not okId or not row or not row.id then
        cLog('[e_core] profession bootstrap: default level profile ID lekérése sikertelen', 'warning', 2)
        return nil
    end

    return tonumber(row.id)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param profileId number
--- @return any result
local function seed_default_professions(profileId)
    for _, profession in ipairs(DEFAULT_PROFESSIONS) do
        local ok = hfe.mysqlAwait(
            ('professions:bootstrap:seed:%s.%s'):format(profession.category, profession.name),
            function()
                MySQL.query.await(
                    [[
                        INSERT IGNORE INTO `e_core_professions` (`category`, `name`, `display_name`, `enabled`, `level_profile_id`)
                        VALUES (?, ?, ?, 1, ?)
                    ]],
                    { profession.category, profession.name, profession.displayName, profileId }
                )
            end
        )
        if not ok then
            cLog(
                ('[e_core] profession bootstrap: profession seed sikertelen (%s.%s)'):format(
                    profession.category,
                    profession.name
                ),
                'warning',
                2
            )
            return false
        end
    end

    return true
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function e_core_bootstrap_profession_registry()
    local profilesCount, professionsCount = get_registry_counts()
    if profilesCount == nil or professionsCount == nil then
        return false
    end

    if profilesCount > 0 and professionsCount > 0 then
        return true
    end

    local levelsJson = json.encode(Config.levels or {})
    if type(levelsJson) ~= 'string' or levelsJson == '' then
        levelsJson = '[]'
    end

    local profileId = ensure_default_profile(levelsJson)
    if not profileId then
        return false
    end

    if professionsCount == 0 then
        local seeded = seed_default_professions(profileId)
        if not seeded then
            return false
        end
        cLog('[e_core] profession bootstrap: default profession registry létrehozva', 'info', 1)
    else
        cLog('[e_core] profession bootstrap: profession rekordok már léteznek, csak default profile biztosítva', 'info', 2)
    end

    return true
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param rows any
--- @return any result
local function build_registry_read_model(rows)
    local data = {
        byCategory = {},
    }

    for _, row in ipairs(rows or {}) do
        local category = row.category
        local name = row.name
        if type(category) == 'string' and category ~= '' and type(name) == 'string' and name ~= '' then
            data.byCategory[category] = data.byCategory[category] or {}

            local levels = {}
            if row.levels_json and row.levels_json ~= '' then
                local decodeOk, decoded = pcall(json.decode, row.levels_json)
                if decodeOk and type(decoded) == 'table' then
                    levels = decoded
                end
            end

            data.byCategory[category][name] = {
                enabled = tonumber(row.enabled) == 1,
                displayName = row.display_name or name,
                levelProfileKey = row.profile_key,
                maxProficiency = tonumber(row.max_proficiency),
                profile = {
                    profileKey = row.profile_key,
                    displayName = row.profile_display_name or row.profile_key,
                    mode = row.profile_mode or 'advanced',
                    levels = levels,
                },
            }
        end
    end

    return data
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function load_profession_registry_from_db()
    local ok, rows = hfe.mysqlAwait('professions:registry:load', function()
        return MySQL.query.await([[
            SELECT
                p.`category`,
                p.`name`,
                p.`display_name`,
                p.`enabled`,
                p.`max_proficiency`,
                lp.`profile_key`,
                lp.`display_name` AS `profile_display_name`,
                lp.`mode` AS `profile_mode`,
                lp.`levels_json`
            FROM `e_core_professions` p
            LEFT JOIN `e_core_level_profiles` lp ON lp.`id` = p.`level_profile_id`
        ]])
    end)

    if not ok then
        return false, eCoreErr.profession_registry_unavailable
    end

    PROFESSION_REGISTRY_CACHE.data = build_registry_read_model(rows)
    PROFESSION_REGISTRY_CACHE.loadedAt = os.time()

    return true, PROFESSION_REGISTRY_CACHE.data
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param forceRefresh any
--- @return any result
local function get_cached_registry(forceRefresh)
    local now = os.time()
    local cacheAge = now - (PROFESSION_REGISTRY_CACHE.loadedAt or 0)

    if not forceRefresh and PROFESSION_REGISTRY_CACHE.data ~= nil and cacheAge >= 0 and cacheAge < PROFESSION_CACHE_TTL_SEC then
        return true, PROFESSION_REGISTRY_CACHE.data
    end

    return load_profession_registry_from_db()
end

db_execute = function(tag, sql, params)
    local ok = hfe.mysqlAwait(tag, function()
        MySQL.query.await(sql, params or {})
    end)
    if not ok then
        return false
    end
    return true
end

db_single = function(tag, sql, params)
    local ok, row = hfe.mysqlAwait(tag, function()
        return MySQL.single.await(sql, params or {})
    end)
    if not ok then
        return false, nil
    end
    return true, row
end

db_query = function(tag, sql, params)
    local ok, rows = hfe.mysqlAwait(tag, function()
        return MySQL.query.await(sql, params or {})
    end)
    if not ok then
        return false, nil
    end
    return true, rows or {}
end

cleanup_job_persist = function(job)
    local createdAt = os.date('!%Y-%m-%d %H:%M:%S', tonumber(job.createdAt) or os.time())
    local updatedAt = os.date('!%Y-%m-%d %H:%M:%S', tonumber(job.updatedAt) or os.time())
    local startedAt = job.startedAt and os.date('!%Y-%m-%d %H:%M:%S', tonumber(job.startedAt)) or nil
    local finishedAt = job.finishedAt and os.date('!%Y-%m-%d %H:%M:%S', tonumber(job.finishedAt)) or nil

    return db_execute(
        ('professions:cleanup:persist:%s'):format(job.jobId),
        [[
            INSERT INTO `e_core_cleanup_jobs`
                (`job_id`, `status`, `mode`, `category`, `name`, `requested_by`, `batch_size`, `last_cursor`,
                 `processed`, `changed_rows`, `removed_keys`, `failed`, `invalid_json`, `cancel_requested`,
                 `errors_json`, `created_at`, `updated_at`, `started_at`, `finished_at`)
            VALUES
                (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                `status` = VALUES(`status`),
                `requested_by` = VALUES(`requested_by`),
                `batch_size` = VALUES(`batch_size`),
                `last_cursor` = VALUES(`last_cursor`),
                `processed` = VALUES(`processed`),
                `changed_rows` = VALUES(`changed_rows`),
                `removed_keys` = VALUES(`removed_keys`),
                `failed` = VALUES(`failed`),
                `invalid_json` = VALUES(`invalid_json`),
                `cancel_requested` = VALUES(`cancel_requested`),
                `errors_json` = VALUES(`errors_json`),
                `updated_at` = VALUES(`updated_at`),
                `started_at` = VALUES(`started_at`),
                `finished_at` = VALUES(`finished_at`)
        ]],
        {
            job.jobId, job.status, job.mode, job.category, job.name, job.requestedBy, job.batchSize, job.lastCursor,
            job.stats.processed, job.stats.changed, job.stats.removedKeys, job.stats.failed, job.stats.invalidJson,
            job.cancelRequested and 1 or 0,
            cleanup_encode_errors(job.errors),
            createdAt, updatedAt, startedAt, finishedAt,
        }
    )
end

--- @return boolean, table|string
function getProfessionRegistry()
    local ok, registryOrErr = get_cached_registry(false)
    if not ok then
        return false, registryOrErr
    end

    return true, deep_copy(registryOrErr.byCategory)
end

--- @param category string
--- @param name string
--- @return boolean, boolean|string
function isValidProfession(category, name)
    local ck, err1 = normalize_registry_key(category)
    if not ck then
        return false, err1
    end

    local nk, err2 = normalize_registry_key(name)
    if not nk then
        return false, err2
    end

    local ok, registryOrErr = get_cached_registry(false)
    if not ok then
        return false, registryOrErr
    end

    local byCategory = registryOrErr.byCategory[ck]
    local profession = byCategory and byCategory[nk]
    local valid = profession ~= nil and profession.enabled == true

    return true, valid
end

--- @param category string
--- @return boolean, table|string
function getProfessionDefaults(category)
    local ck, err = normalize_registry_key(category)
    if not ck then
        return false, err
    end

    local ok, registryOrErr = get_cached_registry(false)
    if not ok then
        return false, registryOrErr
    end

    local byCategory = registryOrErr.byCategory[ck]
    if type(byCategory) ~= 'table' then
        return false, eCoreErr.profession_category_not_found
    end

    local defaults = {}
    for professionName, row in pairs(byCategory) do
        if row.enabled then
            defaults[professionName] = 0
        end
    end

    return true, defaults
end

--- @param category string
--- @param name string
--- @return boolean, table|string
function getProfessionLevelProfile(category, name)
    local ck, err1 = normalize_registry_key(category)
    if not ck then
        return false, err1
    end

    local nk, err2 = normalize_registry_key(name)
    if not nk then
        return false, err2
    end

    local ok, registryOrErr = get_cached_registry(false)
    if not ok then
        return false, registryOrErr
    end

    local byCategory = registryOrErr.byCategory[ck]
    local profession = byCategory and byCategory[nk]
    if type(profession) ~= 'table' then
        return false, eCoreErr.profession_not_found
    end

    if type(profession.profile) ~= 'table' then
        return false, eCoreErr.profession_profile_not_found
    end

    return true, deep_copy(profession.profile)
end

--- @param category string
--- @param keys table
--- @return boolean, table|string
function validateProfessionKeys(category, keys)
    local ck, err = normalize_registry_key(category)
    if not ck then
        return false, err
    end
    if type(keys) ~= 'table' then
        return false, eCoreErr.invalid_item_data
    end

    local ok, registryOrErr = get_cached_registry(false)
    if not ok then
        return false, registryOrErr
    end

    local byCategory = registryOrErr.byCategory[ck]
    if type(byCategory) ~= 'table' then
        return false, eCoreErr.profession_category_not_found
    end

    local seen = {}
    local valid = {}
    local invalid = {}
    local missingProfile = {}
    local missingProfileSeen = {}

    for _, rawKey in ipairs(keys) do
        local nk, keyErr = normalize_registry_key(rawKey)
        if not nk then
            local fallback = hf.trim(tostring(rawKey or ''))
            if fallback == '' then
                fallback = tostring(rawKey)
            end
            if not seen[fallback] then
                seen[fallback] = true
                invalid[#invalid + 1] = fallback
            end
        elseif not seen[nk] then
            seen[nk] = true
            local profession = byCategory[nk]
            if type(profession) ~= 'table' or profession.enabled ~= true then
                invalid[#invalid + 1] = nk
            else
                valid[#valid + 1] = nk
                if type(profession.levelProfileKey) ~= 'string' or hf.trim(profession.levelProfileKey) == '' then
                    if not missingProfileSeen[nk] then
                        missingProfileSeen[nk] = true
                        missingProfile[#missingProfile + 1] = nk
                    end
                end
            end
        end
    end

    return true, {
        category = ck,
        valid = valid,
        invalid = invalid,
        missingProfile = missingProfile,
    }
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param value any
--- @return any result
local function normalize_enabled_flag(value)
    if type(value) == 'boolean' then
        return value
    end
    local num = tonumber(value)
    if num == 1 then
        return true
    end
    if num == 0 then
        return false
    end
    return nil
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param profileKey any
--- @return any result
local function resolve_profile_id(profileKey)
    local pk, err = normalize_registry_key(profileKey)
    if not pk then
        return false, err
    end

    local ok, row = db_single(
        ('professions:admin:profileByKey:%s'):format(pk),
        'SELECT `id`, `profile_key`, `display_name`, `mode` FROM `e_core_level_profiles` WHERE `profile_key` = ? LIMIT 1',
        { pk }
    )
    if not ok then
        return false, eCoreErr.profession_registry_unavailable
    end
    if not row or not row.id then
        return false, eCoreErr.profession_profile_not_found
    end

    return true, tonumber(row.id), {
        profileKey = row.profile_key,
        displayName = row.display_name,
        mode = row.mode,
    }
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param category any
--- @param name string
--- @return any result
local function fetch_profession_admin_row(category, name)
    local ok, row = db_single(
        ('professions:admin:get:%s.%s'):format(category, name),
        [[
            SELECT
                p.`category`,
                p.`name`,
                p.`display_name`,
                p.`enabled`,
                p.`max_proficiency`,
                lp.`profile_key`,
                lp.`display_name` AS `profile_display_name`,
                lp.`mode` AS `profile_mode`
            FROM `e_core_professions` p
            LEFT JOIN `e_core_level_profiles` lp ON lp.`id` = p.`level_profile_id`
            WHERE p.`category` = ? AND p.`name` = ?
            LIMIT 1
        ]],
        { category, name }
    )
    if not ok then
        return false, eCoreErr.profession_registry_unavailable
    end
    if not row then
        return false, eCoreErr.profession_not_found
    end
    return true, {
        category = row.category,
        name = row.name,
        displayName = row.display_name,
        enabled = tonumber(row.enabled) == 1,
        maxProficiency = tonumber(row.max_proficiency),
        profile = {
            profileKey = row.profile_key,
            displayName = row.profile_display_name,
            mode = row.profile_mode,
        },
    }
end

--- Admin/read API: profession list in compact shape.
--- @return table { ok, code, message, data = { items = {...} } }
function professionAdminList()
    local ok, registryOrErr = getProfessionRegistry()
    if not ok then
        return admin_response(false, registryOrErr, 'Profession registry nem elérhető.')
    end

    local items = {}
    for category, byName in pairs(registryOrErr) do
        if type(byName) == 'table' then
            for name, row in pairs(byName) do
                items[#items + 1] = {
                    category = category,
                    name = name,
                    displayName = row.displayName or name,
                    enabled = row.enabled == true,
                    levelProfileKey = row.levelProfileKey,
                    maxProficiency = row.maxProficiency,
                }
            end
        end
    end

    table.sort(items, function(a, b)
        local aKey = ('%s.%s'):format(a.category, a.name)
        local bKey = ('%s.%s'):format(b.category, b.name)
        return aKey < bKey
    end)

    return admin_response(true, eCoreErr.ok, 'Profession lista lekérve.', { items = items })
end

--- Admin/create API.
--- @param payload table { category, name, displayName?, enabled?, profileKey, maxProficiency? }
--- @return table { ok, code, message, data }
function professionAdminCreate(payload)
    if type(payload) ~= 'table' then
        return admin_response(false, eCoreErr.invalid_item_data, 'Érvénytelen payload.')
    end

    local category, err1 = normalize_registry_key(payload.category)
    if not category then
        return admin_response(false, err1, 'Érvénytelen category.')
    end

    local name, err2 = normalize_registry_key(payload.name)
    if not name then
        return admin_response(false, err2, 'Érvénytelen profession név.')
    end

    local displayName = hf.trim(tostring(payload.displayName or name))
    if displayName == '' then
        displayName = name
    end

    local enabled = normalize_enabled_flag(payload.enabled)
    if enabled == nil then
        enabled = true
    end

    local maxProficiency = nil
    if payload.maxProficiency ~= nil then
        maxProficiency = tonumber(payload.maxProficiency)
        if not maxProficiency or maxProficiency < 0 then
            return admin_response(false, eCoreErr.not_valid_amount, 'Érvénytelen maxProficiency.')
        end
        maxProficiency = math.floor(maxProficiency)
    end

    local okProfile, profileIdOrErr = resolve_profile_id(payload.profileKey)
    if not okProfile then
        return admin_response(false, profileIdOrErr, 'Nem található a megadott profile.')
    end

    local okInsert = db_execute(
        ('professions:admin:create:%s.%s'):format(category, name),
        [[
            INSERT INTO `e_core_professions`
                (`category`, `name`, `display_name`, `enabled`, `level_profile_id`, `max_proficiency`)
            VALUES (?, ?, ?, ?, ?, ?)
        ]],
        { category, name, displayName, enabled and 1 or 0, profileIdOrErr, maxProficiency }
    )

    if not okInsert then
        return admin_response(false, eCoreErr.profession_already_exists, 'Profession létrehozása sikertelen (létezhet már).')
    end

    invalidate_profession_registry_cache()

    local okFetch, dataOrErr = fetch_profession_admin_row(category, name)
    if not okFetch then
        return admin_response(false, dataOrErr, 'Profession létrejött, de a visszaolvasás sikertelen.')
    end

    return admin_response(true, eCoreErr.ok, 'Profession létrehozva.', { profession = dataOrErr })
end

--- Admin/update API.
--- @param category string
--- @param name string
--- @param payload table { displayName?, enabled?, profileKey?, maxProficiency? }
--- @return table
function professionAdminUpdate(category, name, payload)
    if type(payload) ~= 'table' then
        return admin_response(false, eCoreErr.invalid_item_data, 'Érvénytelen payload.')
    end

    local ck, err1 = normalize_registry_key(category)
    if not ck then
        return admin_response(false, err1, 'Érvénytelen category.')
    end
    local nk, err2 = normalize_registry_key(name)
    if not nk then
        return admin_response(false, err2, 'Érvénytelen profession név.')
    end

    local okExisting, existingOrErr = fetch_profession_admin_row(ck, nk)
    if not okExisting then
        return admin_response(false, existingOrErr, 'A profession nem található.')
    end

    local nextDisplayName = existingOrErr.displayName
    if payload.displayName ~= nil then
        nextDisplayName = hf.trim(tostring(payload.displayName))
        if nextDisplayName == '' then
            return admin_response(false, eCoreErr.no_valid_meta_name, 'Üres displayName nem megengedett.')
        end
    end

    local nextEnabled = existingOrErr.enabled
    if payload.enabled ~= nil then
        local normalized = normalize_enabled_flag(payload.enabled)
        if normalized == nil then
            return admin_response(false, eCoreErr.invalid_item_data, 'Érvénytelen enabled flag.')
        end
        nextEnabled = normalized
    end

    local nextMaxProficiency = existingOrErr.maxProficiency
    if payload.maxProficiency ~= nil then
        if payload.maxProficiency == false then
            nextMaxProficiency = nil
        else
            local parsed = tonumber(payload.maxProficiency)
            if not parsed or parsed < 0 then
                return admin_response(false, eCoreErr.not_valid_amount, 'Érvénytelen maxProficiency.')
            end
            nextMaxProficiency = math.floor(parsed)
        end
    end

    local profileId = nil
    if payload.profileKey ~= nil then
        local okProfile, profileIdOrErr = resolve_profile_id(payload.profileKey)
        if not okProfile then
            return admin_response(false, profileIdOrErr, 'Nem található a megadott profile.')
        end
        profileId = profileIdOrErr
    else
        local okProfile, currentProfile = db_single(
            ('professions:admin:currentProfileId:%s.%s'):format(ck, nk),
            'SELECT `level_profile_id` FROM `e_core_professions` WHERE `category` = ? AND `name` = ? LIMIT 1',
            { ck, nk }
        )
        if not okProfile or not currentProfile then
            return admin_response(false, eCoreErr.profession_registry_unavailable, 'A jelenlegi profile azonosító nem olvasható.')
        end
        profileId = tonumber(currentProfile.level_profile_id)
    end

    local okUpdate = db_execute(
        ('professions:admin:update:%s.%s'):format(ck, nk),
        [[
            UPDATE `e_core_professions`
            SET `display_name` = ?, `enabled` = ?, `level_profile_id` = ?, `max_proficiency` = ?, `updated_at` = CURRENT_TIMESTAMP
            WHERE `category` = ? AND `name` = ?
            LIMIT 1
        ]],
        { nextDisplayName, nextEnabled and 1 or 0, profileId, nextMaxProficiency, ck, nk }
    )
    if not okUpdate then
        return admin_response(false, eCoreErr.profession_registry_unavailable, 'Profession frissítése sikertelen.')
    end

    invalidate_profession_registry_cache()

    local okFetch, dataOrErr = fetch_profession_admin_row(ck, nk)
    if not okFetch then
        return admin_response(false, dataOrErr, 'Frissítés megtörtént, de a visszaolvasás sikertelen.')
    end

    return admin_response(true, eCoreErr.ok, 'Profession frissítve.', { profession = dataOrErr })
end

--- Admin flag API.
--- @param category string
--- @param name string
--- @param enabled boolean|number
--- @return table
function professionAdminSetEnabled(category, name, enabled)
    return professionAdminUpdate(category, name, { enabled = enabled })
end

--- Admin delete API.
--- @param category string
--- @param name string
--- @return table
function professionAdminDelete(category, name)
    local ck, err1 = normalize_registry_key(category)
    if not ck then
        return admin_response(false, err1, 'Érvénytelen category.')
    end
    local nk, err2 = normalize_registry_key(name)
    if not nk then
        return admin_response(false, err2, 'Érvénytelen profession név.')
    end

    local okExisting = fetch_profession_admin_row(ck, nk)
    if not okExisting then
        return admin_response(false, eCoreErr.profession_not_found, 'A profession nem található.')
    end

    local okDelete = db_execute(
        ('professions:admin:delete:%s.%s'):format(ck, nk),
        'DELETE FROM `e_core_professions` WHERE `category` = ? AND `name` = ? LIMIT 1',
        { ck, nk }
    )
    if not okDelete then
        return admin_response(false, eCoreErr.profession_registry_unavailable, 'Profession törlése sikertelen.')
    end

    invalidate_profession_registry_cache()

    return admin_response(true, eCoreErr.ok, 'Profession törölve.', { category = ck, name = nk })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param mode any
--- @param category any
--- @param name string
--- @param payload table
--- @return any result
local function profession_admin_cleanup_start(mode, category, name, payload)
    local accessOk, accessErr = cleanup_admin_can_access(payload)
    if not accessOk then
        return cleanup_access_denied('profession_admin_cleanup_start', payload, accessErr)
    end

    local ck, err1 = normalize_registry_key(category)
    if not ck then
        return admin_response(false, err1, 'Érvénytelen category.')
    end
    local nk, err2 = normalize_registry_key(name)
    if not nk then
        return admin_response(false, err2, 'Érvénytelen profession név.')
    end

    local okExisting = fetch_profession_admin_row(ck, nk)
    if not okExisting then
        return admin_response(false, eCoreErr.profession_not_found, 'A profession nem található.')
    end

    if mode == 'apply' then
        local required = ('%s.%s DELETE'):format(ck, nk)
        local confirmText = hf.trim(tostring((payload or {}).confirmText or ''))
        if confirmText ~= required then
            return admin_response(false, eCoreErr.invalid_item_data, ('Hiányzó megerősítés. Várt: "%s"'):format(required))
        end
    end

    local job = cleanup_job_create(mode, ck, nk, payload)
    job.deleteProfession = mode == 'apply' and (payload or {}).deleteProfession == true

    cleanup_job_schedule()

    return admin_response(true, eCoreErr.ok, 'Cleanup job sorba állítva.', { job = cleanup_serialize_job(job) })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param category any
--- @param name string
--- @param payload table
--- @return any result
function professionAdminDeleteDryRun(category, name, payload)
    return profession_admin_cleanup_start('dry_run', category, name, payload)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param category any
--- @param name string
--- @param payload table
--- @return any result
function professionAdminDeleteApply(category, name, payload)
    return profession_admin_cleanup_start('apply', category, name, payload)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param jobId number
--- @param payload table
--- @return any result
function professionAdminCleanupJobGet(jobId, payload)
    local accessOk, accessErr = cleanup_admin_can_access(payload)
    if not accessOk then
        return cleanup_access_denied('professionAdminCleanupJobGet', payload, accessErr)
    end

    local key = hf.trim(tostring(jobId or ''))
    if key == '' then
        return admin_response(false, eCoreErr.invalid_item_data, 'Hiányzó jobId.')
    end
    local job = cleanup_job_resolve(key)
    if not job then
        return admin_response(false, eCoreErr.cleanup_job_not_found, 'Cleanup job nem található.')
    end

    return admin_response(true, eCoreErr.ok, 'Cleanup job lekérve.', { job = cleanup_serialize_job(job) })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param filters any
--- @return any result
function professionAdminCleanupJobList(filters)
    local accessOk, accessErr = cleanup_admin_can_access(filters)
    if not accessOk then
        return cleanup_access_denied('professionAdminCleanupJobList', filters, accessErr)
    end

    local f = type(filters) == 'table' and filters or {}
    local whereParts = {}
    local params = {}

    local status = f.status ~= nil and hf.trim(tostring(f.status)) or ''
    if status ~= '' then
        whereParts[#whereParts + 1] = '`status` = ?'
        params[#params + 1] = status
    end

    local mode = f.mode ~= nil and hf.trim(tostring(f.mode)) or ''
    if mode ~= '' then
        whereParts[#whereParts + 1] = '`mode` = ?'
        params[#params + 1] = mode
    end

    local category = f.category ~= nil and hf.trim(tostring(f.category)) or ''
    if category ~= '' then
        whereParts[#whereParts + 1] = '`category` = ?'
        params[#params + 1] = category
    end

    local name = f.name ~= nil and hf.trim(tostring(f.name)) or ''
    if name ~= '' then
        whereParts[#whereParts + 1] = '`name` = ?'
        params[#params + 1] = name
    end

    local whereSql = ''
    if #whereParts > 0 then
        whereSql = ' WHERE ' .. table.concat(whereParts, ' AND ')
    end

    local limit = math.floor(tonumber(f.limit) or 20)
    limit = math.max(1, math.min(100, limit))
    local offset = math.floor(tonumber(f.offset) or 0)
    offset = math.max(0, offset)

    local countSql = 'SELECT COUNT(*) AS `count` FROM `e_core_cleanup_jobs`' .. whereSql
    local rowsSql = [[
        SELECT
            `job_id`, `status`, `mode`, `category`, `name`, `requested_by`, `batch_size`, `last_cursor`,
            `processed`, `changed_rows`, `removed_keys`, `failed`, `invalid_json`,
            `cancel_requested`, `errors_json`, `created_at`, `updated_at`, `started_at`, `finished_at`
        FROM `e_core_cleanup_jobs`
    ]] .. whereSql .. ' ORDER BY `created_at` DESC LIMIT ? OFFSET ?'

    local countOk, countRows = db_query('professions:cleanup:list:count', countSql, params)
    if not countOk then
        return admin_response(false, eCoreErr.profession_registry_unavailable, 'Cleanup job count lekérés sikertelen.')
    end
    local total = tonumber((countRows[1] or {}).count) or 0

    local rowsParams = {}
    for i = 1, #params do
        rowsParams[i] = params[i]
    end
    rowsParams[#rowsParams + 1] = limit
    rowsParams[#rowsParams + 1] = offset

    local rowsOk, rows = db_query('professions:cleanup:list:rows', rowsSql, rowsParams)
    if not rowsOk then
        return admin_response(false, eCoreErr.profession_registry_unavailable, 'Cleanup job lista lekérés sikertelen.')
    end

    local items = {}
    for _, row in ipairs(rows) do
        local job = cleanup_job_from_row(row)
        CLEANUP_JOBS[job.jobId] = job
        items[#items + 1] = cleanup_serialize_job(job)
    end

    return admin_response(true, eCoreErr.ok, 'Cleanup job lista lekérve.', {
        items = items,
        total = total,
        limit = limit,
        offset = offset,
    })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param jobId number
--- @param payload table
--- @return any result
function professionAdminCleanupJobAbort(jobId, payload)
    local accessOk, accessErr = cleanup_admin_can_access(payload)
    if not accessOk then
        return cleanup_access_denied('professionAdminCleanupJobAbort', payload, accessErr)
    end

    local key = hf.trim(tostring(jobId or ''))
    if key == '' then
        return admin_response(false, eCoreErr.invalid_item_data, 'Hiányzó jobId.')
    end
    local job = cleanup_job_resolve(key)
    if not job then
        return admin_response(false, eCoreErr.cleanup_job_not_found, 'Cleanup job nem található.')
    end
    if job.status ~= 'running' and job.status ~= 'queued' then
        return admin_response(false, eCoreErr.cleanup_job_not_resumable, 'A cleanup job nem megszakítható ebben az állapotban.')
    end
    job.cancelRequested = true
    job.updatedAt = os.time()
    cleanup_job_persist(job)
    append_cleanup_audit(
        'cleanup_job_abort_requested',
        {
            requestedBy = tostring((payload or {}).requestedBy or 'unknown'),
            source = type(payload) == 'table' and type(payload.auth) == 'table' and tonumber(payload.auth.source) or nil,
        },
        {
            jobId = job.jobId,
        },
        {
            status = 'requested',
        }
    )
    return admin_response(true, eCoreErr.ok, 'Cleanup job megszakításra jelölve.', {
        job = cleanup_serialize_job(job),
    })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param jobId number
--- @param payload table
--- @return any result
function professionAdminCleanupJobResume(jobId, payload)
    local accessOk, accessErr = cleanup_admin_can_access(payload)
    if not accessOk then
        return cleanup_access_denied('professionAdminCleanupJobResume', payload, accessErr)
    end

    local key = hf.trim(tostring(jobId or ''))
    if key == '' then
        return admin_response(false, eCoreErr.invalid_item_data, 'Hiányzó jobId.')
    end
    local job = cleanup_job_resolve(key)
    if not job then
        return admin_response(false, eCoreErr.cleanup_job_not_found, 'Cleanup job nem található.')
    end
    if job.status == 'running' then
        return admin_response(false, eCoreErr.cleanup_job_already_running, 'A cleanup job már fut.')
    end
    if job.status ~= 'failed' and job.status ~= 'cancelled' then
        return admin_response(false, eCoreErr.cleanup_job_not_resumable, 'A cleanup job nem resume-olható ebben az állapotban.')
    end

    job.cancelRequested = false
    job.status = 'queued'
    job.finishedAt = nil
    job.requestedBy = tostring((payload or {}).requestedBy or job.requestedBy)
    job.updatedAt = os.time()
    cleanup_job_persist(job)
    cleanup_job_schedule()

    return admin_response(true, eCoreErr.ok, 'Cleanup job resume sorba állítva.', {
        job = cleanup_serialize_job(job),
    })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param limit number
--- @param payload table
--- @return any result
function professionAdminAuditList(limit, payload)
    local accessOk, accessErr = cleanup_admin_can_access(payload)
    if not accessOk then
        return cleanup_access_denied('professionAdminAuditList', payload, accessErr)
    end

    local take = math.floor(tonumber(limit) or 20)
    take = math.max(1, math.min(100, take))
    local items = {}
    for i = #CLEANUP_AUDIT_LOG, math.max(1, #CLEANUP_AUDIT_LOG - take + 1), -1 do
        items[#items + 1] = CLEANUP_AUDIT_LOG[i]
    end
    return admin_response(true, eCoreErr.ok, 'Admin audit lista lekérve.', { items = items })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param row any
--- @return any result
local function build_denied_audit_item(row)
    local section = tostring(row.section or ((type(row.target) == 'table' and row.target.scope) or 'unknown'))
    local action = tostring(row.action or ((type(row.target) == 'table' and row.target.action) or 'unknown'))
    local source = row.source
    if source ~= nil then
        source = tonumber(source)
    end
    local requestedBy = row.requestedBy or row.requested_by
    local reason = tostring(row.reason or ((type(row.outcome) == 'table' and row.outcome.reason) or 'access_denied'))

    return {
        id = row.id ~= nil and tonumber(row.id) or nil,
        ts = row.ts,
        eventType = row.eventType or 'admin_api_denied',
        actor = type(row.actor) == 'table' and row.actor or {
            source = source,
            requestedBy = requestedBy,
        },
        target = type(row.target) == 'table' and row.target or {
            scope = section,
            action = action,
        },
        outcome = type(row.outcome) == 'table' and row.outcome or {
            status = 'denied',
            reason = reason,
        },
        section = section,
        action = action,
        source = source,
        requestedBy = requestedBy,
        reason = reason,
    }
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param filters any
--- @return any result
function adminApiDeniedAuditList(filters)
    local f = type(filters) == 'table' and filters or {}
    local accessOk, accessErr = admin_audit_can_access(f)
    if not accessOk then
        return admin_response(false, eCoreErr.access_denied, accessErr or 'Nincs jogosultság.')
    end

    local sectionFilter = f.section ~= nil and hf.trim(tostring(f.section)) or ''
    local actionFilter = f.action ~= nil and hf.trim(tostring(f.action)) or ''
    local limit = math.floor(tonumber(f.limit) or 20)
    limit = math.max(1, math.min(200, limit))
    local offset = math.floor(tonumber(f.offset) or 0)
    offset = math.max(0, offset)

    local whereParts = {}
    local params = {}
    if sectionFilter ~= '' then
        whereParts[#whereParts + 1] = '`section` = ?'
        params[#params + 1] = sectionFilter
    end
    if actionFilter ~= '' then
        whereParts[#whereParts + 1] = '`action` = ?'
        params[#params + 1] = actionFilter
    end
    local whereSql = ''
    if #whereParts > 0 then
        whereSql = ' WHERE ' .. table.concat(whereParts, ' AND ')
    end

    local countSql = 'SELECT COUNT(*) AS `count` FROM `e_core_admin_denied_audit`' .. whereSql
    local rowsSql = [[
        SELECT `id`, `ts`, `section`, `action`, `source`, `requested_by`, `reason`
        FROM `e_core_admin_denied_audit`
    ]] .. whereSql .. ' ORDER BY `id` DESC LIMIT ? OFFSET ?'

    local countOk, countRows = db_query('admin_denied_audit:list:count', countSql, params)
    local items = {}
    local total = 0

    if countOk then
        total = tonumber((countRows[1] or {}).count) or 0
        local rowsParams = {}
        for i = 1, #params do
            rowsParams[i] = params[i]
        end
        rowsParams[#rowsParams + 1] = limit
        rowsParams[#rowsParams + 1] = offset

        local rowsOk, rows = db_query('admin_denied_audit:list:rows', rowsSql, rowsParams)
        if rowsOk then
            for _, row in ipairs(rows) do
                items[#items + 1] = build_denied_audit_item(row)
            end
        else
            total = 0
        end
    end

    -- Fallback: in-memory audit ring if DB table not yet available.
    if total == 0 and #items == 0 then
        local source = hf.__adminApiDeniedAudit or {}
        local filtered = {}
        for i = #source, 1, -1 do
            local row = source[i]
            if type(row) == 'table' then
                local sectionOk = sectionFilter == '' or tostring(row.section) == sectionFilter
                local actionOk = actionFilter == '' or tostring(row.action) == actionFilter
                if sectionOk and actionOk then
                    filtered[#filtered + 1] = row
                end
            end
        end
        total = #filtered
        for i = offset + 1, math.min(total, offset + limit) do
            items[#items + 1] = build_denied_audit_item(filtered[i])
        end
    end

    return admin_response(true, eCoreErr.ok, 'Admin denied audit lista lekérve.', {
        items = items,
        total = total,
        limit = limit,
        offset = offset,
    })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param action any
--- @param payload table
--- @param reason string
--- @return any result
local function denied_audit_access_denied(action, payload, reason)
    if type(hf.auditAdminApiDenied) == 'function' then
        hfe.auditAdminApiDenied('deniedAudit', action, payload, reason)
    end
    return admin_response(false, eCoreErr.access_denied, reason or 'Nincs jogosultság.')
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function denied_audit_config()
    local cfg = (((Config or {}).adminApi or {}).deniedAudit or {})
    local enabled = cfg.enabled ~= false
    local retentionDays = math.floor(tonumber(cfg.retentionDays) or 30)
    retentionDays = math.max(1, math.min(3650, retentionDays))
    local intervalMinutes = math.floor(tonumber(cfg.purgeIntervalMinutes) or 60)
    intervalMinutes = math.max(5, math.min(1440, intervalMinutes))
    local maxDelete = math.floor(tonumber(cfg.maxDeletePerRun) or 2000)
    maxDelete = math.max(100, math.min(50000, maxDelete))
    return {
        enabled = enabled,
        retentionDays = retentionDays,
        intervalMinutes = intervalMinutes,
        maxDelete = maxDelete,
    }
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function e_core_purge_admin_denied_audit_once()
    local cfg = denied_audit_config()
    if not cfg.enabled then
        return true, 0
    end

    local ok, affected = hfe.mysqlAwait('admin_denied_audit:purge', function()
        return MySQL.update.await(
            [[
                DELETE FROM `e_core_admin_denied_audit`
                WHERE `ts` < DATE_SUB(NOW(), INTERVAL ? DAY)
                LIMIT ?
            ]],
            { cfg.retentionDays, cfg.maxDelete }
        )
    end)
    if not ok then
        cLog('[e_core] admin denied audit purge sikertelen', 'warning', 2)
        return false, 0
    end

    local deleted = tonumber(affected) or 0
    if deleted > 0 then
        cLog(
            ('[e_core] admin denied audit purge: %s sor törölve (retentionDays=%s, limit=%s)'):format(
                deleted,
                cfg.retentionDays,
                cfg.maxDelete
            ),
            'info',
            2
        )
    end
    return true, deleted
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function e_core_count_admin_denied_audit_candidates()
    local cfg = denied_audit_config()
    if not cfg.enabled then
        return true, 0
    end

    local ok, rows = hfe.mysqlAwait('admin_denied_audit:purge_count', function()
        return MySQL.query.await(
            [[
                SELECT COUNT(*) AS `count`
                FROM `e_core_admin_denied_audit`
                WHERE `ts` < DATE_SUB(NOW(), INTERVAL ? DAY)
            ]],
            { cfg.retentionDays }
        )
    end)
    if not ok then
        return false, 0
    end
    return true, tonumber((rows and rows[1] or {}).count) or 0
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param payload table
--- @return any result
function adminApiDeniedAuditPurge(payload)
    local p = type(payload) == 'table' and payload or {}
    local accessOk, accessErr = admin_audit_can_access(p)
    if not accessOk then
        return denied_audit_access_denied('adminApiDeniedAuditPurge', p, accessErr)
    end

    local dryRun = p.dryRun == true
    if dryRun then
        local okCount, candidates = e_core_count_admin_denied_audit_candidates()
        if not okCount then
            return admin_response(false, eCoreErr.profession_registry_unavailable, 'Admin denied audit dry-run count sikertelen.')
        end
        return admin_response(true, eCoreErr.ok, 'Admin denied audit purge dry-run lefutott.', {
            dryRun = true,
            wouldDelete = candidates,
            retentionDays = denied_audit_config().retentionDays,
        })
    end

    local ok, deleted = e_core_purge_admin_denied_audit_once()
    if not ok then
        return admin_response(false, eCoreErr.profession_registry_unavailable, 'Admin denied audit purge sikertelen.')
    end

    return admin_response(true, eCoreErr.ok, 'Admin denied audit purge lefutott.', {
        dryRun = false,
        deleted = deleted,
    })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function e_core_schedule_admin_denied_audit_purge()
    local cfg = denied_audit_config()
    if not cfg.enabled then
        return
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @return any result
    local function tick()
        e_core_purge_admin_denied_audit_once()
        SetTimeout(cfg.intervalMinutes * 60000, tick)
    end

    SetTimeout(5000, tick)
end

local LEVEL_MODIFIERS = { 'labor', 'time', 'price', 'chance', 'speed' }

--- Auto-generated annotation. Refine behavior details if needed.
--- @param value any
--- @param minValue any
--- @param maxValue any
--- @return any result
local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param index number
--- @param total any
--- @param curveType any
--- @return any result
local function easing_factor(index, total, curveType)
    if total <= 1 then
        return 1
    end

    local t = (index - 1) / (total - 1)
    if curveType == 'aggressive' then
        return t * t
    end
    if curveType == 'soft' then
        return math.sqrt(t)
    end
    return t
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param settings any
--- @return any result
local function generate_easy_levels(settings)
    if type(settings) ~= 'table' then
        return false, eCoreErr.invalid_item_data
    end

    local milestones = math.floor(tonumber(settings.milestones) or 0)
    local maxPoints = math.floor(tonumber(settings.maxPoints) or 0)
    if milestones < 2 or maxPoints <= 0 then
        return false, eCoreErr.invalid_item_data
    end

    local curveType = tostring(settings.curveType or 'linear')
    if curveType ~= 'linear' and curveType ~= 'soft' and curveType ~= 'aggressive' then
        return false, eCoreErr.invalid_item_data
    end

    local max = {}
    for _, key in ipairs(LEVEL_MODIFIERS) do
        local parsed = tonumber((settings.max or {})[key] or 0)
        if parsed == nil then
            return false, eCoreErr.not_valid_amount
        end
        max[key] = clamp(math.floor(parsed), 0, 100)
    end

    local levels = {}
    for i = 1, milestones do
        local f = easing_factor(i, milestones, curveType)
        local row = {
            limit = math.floor((maxPoints * i) / milestones),
        }
        for _, key in ipairs(LEVEL_MODIFIERS) do
            row[key] = math.floor(max[key] * f)
        end
        levels[#levels + 1] = row
    end

    return true, levels
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param levels any
--- @return any result
local function normalize_levels_table(levels)
    if type(levels) ~= 'table' or #levels == 0 then
        return false, eCoreErr.not_levels_data
    end

    local normalized = {}
    local previousLimit = -1
    for idx, row in ipairs(levels) do
        if type(row) ~= 'table' then
            return false, eCoreErr.invalid_item_data
        end

        local limit = row.limit
        if limit == nil and idx == #levels then
            limit = previousLimit + 1
        end
        limit = tonumber(limit)
        if not limit then
            return false, eCoreErr.not_valid_amount
        end
        limit = math.floor(limit)
        if limit <= previousLimit then
            return false, eCoreErr.not_levels_data
        end
        previousLimit = limit

        local normalizedRow = { limit = limit }
        for _, key in ipairs(LEVEL_MODIFIERS) do
            local value = tonumber(row[key] or 0)
            if value == nil then
                return false, eCoreErr.not_valid_amount
            end
            value = math.floor(value)
            if value < 0 or value > 100 then
                return false, eCoreErr.not_valid_amount
            end
            normalizedRow[key] = value
        end
        normalized[#normalized + 1] = normalizedRow
    end

    return true, normalized
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param payload table
--- @param fallbackLevels any
--- @return any result
local function resolve_profile_levels_from_payload(payload, fallbackLevels)
    if payload.easyGenerator ~= nil then
        return generate_easy_levels(payload.easyGenerator)
    end

    if payload.levels ~= nil then
        return normalize_levels_table(payload.levels)
    end

    if fallbackLevels ~= nil then
        return normalize_levels_table(fallbackLevels)
    end

    return false, eCoreErr.not_levels_data
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param levelsJson any
--- @return any result
local function decode_levels_json(levelsJson)
    if type(levelsJson) ~= 'string' or levelsJson == '' then
        return {}
    end
    local ok, decoded = pcall(json.decode, levelsJson)
    if not ok or type(decoded) ~= 'table' then
        return {}
    end
    return decoded
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param profileKey any
--- @return any result
local function fetch_level_profile_row(profileKey)
    local ok, row = db_single(
        ('profiles:admin:get:%s'):format(profileKey),
        [[
            SELECT `id`, `profile_key`, `display_name`, `mode`, `levels_json`
            FROM `e_core_level_profiles`
            WHERE `profile_key` = ?
            LIMIT 1
        ]],
        { profileKey }
    )
    if not ok then
        return false, eCoreErr.profession_registry_unavailable
    end
    if not row then
        return false, eCoreErr.profession_profile_not_found
    end

    local levels = decode_levels_json(row.levels_json)
    local okLevels, normalizedOrErr = normalize_levels_table(levels)
    if not okLevels then
        return false, normalizedOrErr
    end

    return true, {
        id = tonumber(row.id),
        profileKey = row.profile_key,
        displayName = row.display_name,
        mode = row.mode,
        levels = normalizedOrErr,
    }
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param mode any
--- @return any result
local function normalize_profile_mode(mode)
    if mode == nil then
        return nil
    end
    local m = tostring(mode)
    if m ~= 'easy' and m ~= 'advanced' then
        return nil
    end
    return m
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function levelProfileAdminList()
    local ok, rows = db_query(
        'profiles:admin:list',
        [[
            SELECT
                lp.`profile_key`,
                lp.`display_name`,
                lp.`mode`,
                lp.`levels_json`,
                COUNT(p.`id`) AS `profession_count`
            FROM `e_core_level_profiles` lp
            LEFT JOIN `e_core_professions` p ON p.`level_profile_id` = lp.`id`
            GROUP BY lp.`id`, lp.`profile_key`, lp.`display_name`, lp.`mode`, lp.`levels_json`
            ORDER BY lp.`profile_key` ASC
        ]]
    )
    if not ok then
        return admin_response(false, eCoreErr.profession_registry_unavailable, 'Level profile lista nem elérhető.')
    end

    local items = {}
    for _, row in ipairs(rows) do
        local levels = decode_levels_json(row.levels_json)
        local okLevels, normalizedOrErr = normalize_levels_table(levels)
        if not okLevels then
            return admin_response(false, normalizedOrErr, 'Sérült levels_json található a DB-ben.')
        end

        items[#items + 1] = {
            profileKey = row.profile_key,
            displayName = row.display_name,
            mode = row.mode,
            levels = normalizedOrErr,
            professionCount = tonumber(row.profession_count) or 0,
        }
    end

    return admin_response(true, eCoreErr.ok, 'Level profile lista lekérve.', { items = items })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param payload table
--- @return any result
function levelProfileAdminCreate(payload)
    if type(payload) ~= 'table' then
        return admin_response(false, eCoreErr.invalid_item_data, 'Érvénytelen payload.')
    end

    local profileKey, keyErr = normalize_registry_key(payload.profileKey)
    if not profileKey then
        return admin_response(false, keyErr, 'Érvénytelen profileKey.')
    end

    local displayName = hf.trim(tostring(payload.displayName or profileKey))
    if displayName == '' then
        displayName = profileKey
    end

    local mode = 'advanced'
    if payload.mode ~= nil then
        mode = normalize_profile_mode(payload.mode)
        if not mode then
            return admin_response(false, eCoreErr.invalid_item_data, 'Érvénytelen profile mode.')
        end
    end
    local okLevels, levelsOrErr = resolve_profile_levels_from_payload(payload)
    if not okLevels then
        return admin_response(false, levelsOrErr, 'Érvénytelen levels payload.')
    end

    local okInsert = db_execute(
        ('profiles:admin:create:%s'):format(profileKey),
        [[
            INSERT INTO `e_core_level_profiles`
                (`profile_key`, `display_name`, `mode`, `levels_json`, `created_by`)
            VALUES (?, ?, ?, ?, ?)
        ]],
        { profileKey, displayName, mode, json.encode(levelsOrErr), DEFAULT_PROFILE_AUTHOR }
    )
    if not okInsert then
        return admin_response(false, eCoreErr.profession_already_exists, 'Profile létrehozása sikertelen (létezhet már).')
    end

    invalidate_profession_registry_cache()

    local okFetch, profileOrErr = fetch_level_profile_row(profileKey)
    if not okFetch then
        return admin_response(false, profileOrErr, 'Profile létrejött, de a visszaolvasás sikertelen.')
    end

    return admin_response(true, eCoreErr.ok, 'Level profile létrehozva.', { profile = profileOrErr })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param profileKey any
--- @param payload table
--- @return any result
function levelProfileAdminUpdate(profileKey, payload)
    if type(payload) ~= 'table' then
        return admin_response(false, eCoreErr.invalid_item_data, 'Érvénytelen payload.')
    end

    local pk, err = normalize_registry_key(profileKey)
    if not pk then
        return admin_response(false, err, 'Érvénytelen profileKey.')
    end

    local okExisting, existingOrErr = fetch_level_profile_row(pk)
    if not okExisting then
        return admin_response(false, existingOrErr, 'A profile nem található.')
    end

    local nextDisplayName = existingOrErr.displayName
    if payload.displayName ~= nil then
        nextDisplayName = hf.trim(tostring(payload.displayName))
        if nextDisplayName == '' then
            return admin_response(false, eCoreErr.no_valid_meta_name, 'Üres displayName nem megengedett.')
        end
    end

    local nextMode = existingOrErr.mode
    if payload.mode ~= nil then
        nextMode = normalize_profile_mode(payload.mode)
        if not nextMode then
            return admin_response(false, eCoreErr.invalid_item_data, 'Érvénytelen profile mode.')
        end
    end
    local okLevels, levelsOrErr = resolve_profile_levels_from_payload(payload, existingOrErr.levels)
    if not okLevels then
        return admin_response(false, levelsOrErr, 'Érvénytelen levels payload.')
    end

    local okUpdate = db_execute(
        ('profiles:admin:update:%s'):format(pk),
        [[
            UPDATE `e_core_level_profiles`
            SET `display_name` = ?, `mode` = ?, `levels_json` = ?, `updated_at` = CURRENT_TIMESTAMP
            WHERE `profile_key` = ?
            LIMIT 1
        ]],
        { nextDisplayName, nextMode, json.encode(levelsOrErr), pk }
    )
    if not okUpdate then
        return admin_response(false, eCoreErr.profession_registry_unavailable, 'Profile frissítése sikertelen.')
    end

    invalidate_profession_registry_cache()

    local okFetch, profileOrErr = fetch_level_profile_row(pk)
    if not okFetch then
        return admin_response(false, profileOrErr, 'Profile frissítve, de a visszaolvasás sikertelen.')
    end

    return admin_response(true, eCoreErr.ok, 'Level profile frissítve.', { profile = profileOrErr })
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param profileKey any
--- @return any result
function levelProfileAdminDelete(profileKey)
    local pk, err = normalize_registry_key(profileKey)
    if not pk then
        return admin_response(false, err, 'Érvénytelen profileKey.')
    end
    if pk == DEFAULT_PROFILE_KEY then
        return admin_response(false, eCoreErr.invalid_item_data, 'A default profile nem törölhető.')
    end

    local okExisting, existingOrErr = fetch_level_profile_row(pk)
    if not okExisting then
        return admin_response(false, existingOrErr, 'A profile nem található.')
    end

    local okUsage, usageRows = db_query(
        ('profiles:admin:usage:%s'):format(pk),
        [[
            SELECT COUNT(*) AS `count`
            FROM `e_core_professions` p
            INNER JOIN `e_core_level_profiles` lp ON lp.`id` = p.`level_profile_id`
            WHERE lp.`profile_key` = ?
        ]],
        { pk }
    )
    if not okUsage then
        return admin_response(false, eCoreErr.profession_registry_unavailable, 'Profile használat ellenőrzése sikertelen.')
    end
    local usageCount = tonumber((usageRows[1] or {}).count) or 0
    if usageCount > 0 then
        return admin_response(false, eCoreErr.invalid_item_data, 'A profile használatban van, törlés előtt le kell választani a professionökről.')
    end

    local okDelete = db_execute(
        ('profiles:admin:delete:%s'):format(pk),
        'DELETE FROM `e_core_level_profiles` WHERE `profile_key` = ? LIMIT 1',
        { pk }
    )
    if not okDelete then
        return admin_response(false, eCoreErr.profession_registry_unavailable, 'Profile törlése sikertelen.')
    end

    invalidate_profession_registry_cache()

    return admin_response(true, eCoreErr.ok, 'Level profile törölve.', {
        profile = existingOrErr,
        deletedProfileKey = pk,
    })
end
