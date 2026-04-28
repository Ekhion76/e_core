--- Operator permission-denied audit: config (`Config.adminApi.deniedAudit`), DB ring buffer, optional Discord sink, NUI/export surface.
local hfe = hfe

--- @param ok boolean|any
--- @param code string|any
--- @param message string|nil
--- @param data table|nil
--- @return table
local function admin_response(ok, code, message, data)
    return {
        ok = ok == true,
        code = code or (ok and eCoreErr.ok or eCoreErr.unknown_error),
        message = message or '',
        data = data or {},
    }
end

--- @param payload table|nil
--- @return boolean ok
--- @return string|nil err
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

--- @param action string
--- @param payload table|nil
--- @param reason string|nil
--- @return table
local function denied_audit_access_denied(action, payload, reason)
    if type(hfe.auditAdminApiDenied) == 'function' then
        hfe.auditAdminApiDenied('deniedAudit', action, payload, reason)
    end
    return admin_response(false, eCoreErr.access_denied, reason or 'Nincs jogosultság.')
end

--- @param tag string
--- @param sql string
--- @param params table|nil
--- @return boolean ok
--- @return table|nil rows
local function db_query(tag, sql, params)
    local ok, rows = hfe.mysqlAwait(tag, function()
        return MySQL.query.await(sql, params or {})
    end)
    if not ok then
        return false, nil
    end
    return true, rows or {}
end

--- @param row table
--- @return table
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

--- Effective operator config for denied-audit storage and retention.
--- @return table
local function denied_audit_config()
    local cfg = (((Config or {}).adminApi or {}).deniedAudit or {})
    local enabled = cfg.enabled ~= false
    local storage = tostring(cfg.storage or 'mysql'):lower()
    if storage ~= 'mysql' and storage ~= 'discord' then
        storage = 'mysql'
    end
    local webhookUrl = hf.trim(tostring(cfg.webhookUrl or ''))
    local discordBotName = hf.trim(tostring(cfg.discordBotName or ''))
    local retentionDays = math.floor(tonumber(cfg.retentionDays) or 30)
    retentionDays = math.max(1, math.min(3650, retentionDays))
    local intervalMinutes = math.floor(tonumber(cfg.purgeIntervalMinutes) or 60)
    intervalMinutes = math.max(5, math.min(1440, intervalMinutes))
    local maxDelete = math.floor(tonumber(cfg.maxDeletePerRun) or 2000)
    maxDelete = math.max(100, math.min(50000, maxDelete))
    return {
        enabled = enabled,
        storage = storage,
        webhookUrl = webhookUrl,
        discordBotName = discordBotName ~= '' and discordBotName or nil,
        retentionDays = retentionDays,
        intervalMinutes = intervalMinutes,
        maxDelete = maxDelete,
    }
end

--- @param filters table|nil
--- @return table items, number total
local function list_denied_from_memory(filters)
    local f = type(filters) == 'table' and filters or {}
    local sectionFilter = f.section ~= nil and hf.trim(tostring(f.section)) or ''
    local actionFilter = f.action ~= nil and hf.trim(tostring(f.action)) or ''
    local limit = math.floor(tonumber(f.limit) or 20)
    limit = math.max(1, math.min(200, limit))
    local offset = math.floor(tonumber(f.offset) or 0)
    offset = math.max(0, offset)

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
    local total = #filtered
    local items = {}
    for i = offset + 1, math.min(total, offset + limit) do
        items[#items + 1] = build_denied_audit_item(filtered[i])
    end
    return items, total
end

--- NUI / operator: current storage mode and enabled flag.
--- @return table admin_response
function e_core_get_denied_audit_admin_snapshot()
    local c = denied_audit_config()
    return admin_response(true, eCoreErr.ok, 'Denied audit config.', {
        storage = c.storage,
        enabled = c.enabled,
    })
end

--- Log a permission-denied attempt on the privileged admin surface (cross-resource entry).
--- @param section string Logical area (e.g. `cleanup`, `diagnostics`).
--- @param action string Action name for audit.
--- @param payload table|nil Optional `{ auth = { source = number }, requestedBy? }`.
--- @param reason string|nil Deny reason code or text.
function adminDenied(section, action, payload, reason)
    if type(hfe.auditAdminApiDenied) == 'function' then
        hfe.auditAdminApiDenied(section, action, payload, reason)
    end
end

--- Paginated list of operator permission-denied events. `storage=discord` uses in-memory ring only.
--- @param filters table|nil Optional `section`, `action`, `limit`, `offset`, `auth`.
--- @return table admin_response
function adminDeniedAuditList(filters)
    local f = type(filters) == 'table' and filters or {}
    local accessOk, accessErr = admin_audit_can_access(f)
    if not accessOk then
        return admin_response(false, eCoreErr.access_denied, accessErr or 'Nincs jogosultság.')
    end

    local limit = math.floor(tonumber(f.limit) or 20)
    limit = math.max(1, math.min(200, limit))
    local offset = math.floor(tonumber(f.offset) or 0)
    offset = math.max(0, offset)

    if denied_audit_config().storage == 'discord' then
        local items, total = list_denied_from_memory(f)
        return admin_response(true, eCoreErr.ok, 'Denied audit lista (memória; storage=discord).', {
            items = items,
            total = total,
            limit = limit,
            offset = offset,
            dataSource = 'memory',
        })
    end

    local sectionFilter = f.section ~= nil and hf.trim(tostring(f.section)) or ''
    local actionFilter = f.action ~= nil and hf.trim(tostring(f.action)) or ''

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
    local usedDb = false

    if countOk then
        usedDb = true
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

    if total == 0 and #items == 0 then
        items, total = list_denied_from_memory(f)
        usedDb = false
    end

    return admin_response(true, eCoreErr.ok, 'Admin denied audit lista lekérve.', {
        items = items,
        total = total,
        limit = limit,
        offset = offset,
        dataSource = usedDb and 'mysql' or 'memory',
    })
end

--- @return boolean ok
--- @return number deletedOrZero
function e_core_purge_admin_denied_audit_once()
    local cfg = denied_audit_config()
    if not cfg.enabled or cfg.storage ~= 'mysql' then
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

--- @return boolean ok
--- @return number count
local function e_core_count_admin_denied_audit_candidates()
    local cfg = denied_audit_config()
    if not cfg.enabled or cfg.storage ~= 'mysql' then
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

--- Deletes aged rows when `storage=mysql`; no-op for `storage=discord`.
--- @param payload table|nil Optional `dryRun`, `auth`.
--- @return table admin_response
function adminDeniedAuditPurge(payload)
    local p = type(payload) == 'table' and payload or {}
    local accessOk, accessErr = admin_audit_can_access(p)
    if not accessOk then
        return denied_audit_access_denied('adminDeniedAuditPurge', p, accessErr)
    end

    if denied_audit_config().storage == 'discord' then
        return admin_response(false, eCoreErr.invalid_item_data, 'Purge csak storage=mysql mellett értelmes (discord módban nincs DB retention).')
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

--- Schedules periodic purge when enabled and `storage=mysql`.
function e_core_schedule_admin_denied_audit_purge()
    local cfg = denied_audit_config()
    if not cfg.enabled or cfg.storage ~= 'mysql' then
        return
    end

    local function tick()
        e_core_purge_admin_denied_audit_once()
        SetTimeout(cfg.intervalMinutes * 60000, tick)
    end

    SetTimeout(5000, tick)
end
