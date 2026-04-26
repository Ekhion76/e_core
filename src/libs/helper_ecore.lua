--- e_core-specific extensions on the same `hf` table as `libs/helper.lua`.
--- Includes item registry normalization (`normalizeRegisteredItemDef`), startup/registry waiting,
--- MySQL `pcall` wrapper, net rate limiting, and currency formatting (`Config.currency`).
--- Load order: `fxmanifest.lua` loads this file immediately after `libs/helper.lua`.
--- External resources still consume the merged table through `eCore.helper` (`bridge/main.lua`).

--- Shared weight-key contract for REGISTERED_ITEMS / getItemWeight / canCarryItem
--- (bridge + override convertItems compatibility).
--- @return string wKey
--- @return table weightKeys ordered list (same as normalizeRegisteredItemDef)
function hf.getRegisteredItemWeightKeyConfig()
    local wKey = 'weight'
    if type(Config) == 'table' and type(Config.fields) == 'table' and type(Config.fields.weight) == 'string' then
        wKey = Config.fields.weight
    end
    return wKey, { wKey, 'weight', 'Weight', 'itemWeight', 'item_weight', 'totalWeight' }
end

--- @param nameLower string Pre-lowercased key (for example: ox item key).
--- @param row table Source item row (mutated in place).
--- @param diagCtx table|nil Optional diagnostics context (`{ source = string }`).
--- @return table row
function hf.normalizeRegisteredItemDef(nameLower, row, diagCtx)
    if type(row) ~= 'table' or type(nameLower) ~= 'string' or nameLower == '' then
        return row
    end

    local wKey, weightKeys = hf.getRegisteredItemWeightKeyConfig()
    local sourceTag = type(diagCtx) == 'table' and tostring(diagCtx.source or 'itemconvert') or 'itemconvert'

    local ok, err = pcall(function()
        row.name = nameLower

        local wNum
        local hadWeightField = false
        local hadInvalidWeight = false
        for _, k in ipairs(weightKeys) do
            if row[k] ~= nil then
                hadWeightField = true
                local probe = tonumber(row[k])
                if not probe or probe < 0 then
                    hadInvalidWeight = true
                end
            end
            local n = tonumber(row[k])
            if n and n >= 0 then
                wNum = n
                break
            end
        end
        if not wNum and hf.itemConvertDiagRecord then
            hf.itemConvertDiagRecord({
                source = sourceTag,
                code = hadWeightField and 'invalid_weight' or 'missing_weight',
                severity = 'warning',
                item = nameLower,
                reason = hadWeightField and 'No usable non-negative numeric weight found.' or 'No weight field found.',
            })
        end
        row[wKey] = wNum or 0

        local lab
        for _, k in ipairs({ 'label', 'formatName', 'title', 'Label', 'description' }) do
            local v = row[k]
            if type(v) == 'string' and v ~= '' then
                lab = v
                break
            end
            if type(v) == 'number' then
                lab = tostring(v)
                break
            end
        end
        row.label = (type(lab) == 'string' and lab ~= '') and lab or nameLower

        row.isUnique = row.isUnique == true
        row.isWeapon = row.isWeapon == true

        if type(row.image) ~= 'string' or row.image == '' then
            row.image = nameLower .. '.png'
            if hf.itemConvertDiagRecord then
                hf.itemConvertDiagRecord({
                    source = sourceTag,
                    code = 'fallback_image',
                    severity = 'info',
                    item = nameLower,
                    reason = 'Image missing, fallback to <name>.png',
                })
            end
        end

        local ammoStr
        for _, k in ipairs({
            'ammoname', 'ammoName', 'ammotype', 'ammoType', 'ammunition',
        }) do
            local v = row[k]
            if type(v) == 'string' and v ~= '' then
                ammoStr = v:lower()
                break
            end
        end
        row.ammoname = ammoStr
    end)

    if not ok then
        if cLog then
            cLog('eCore:normalizeRegisteredItemDef', { name = nameLower, err = tostring(err) }, 1)
        end
        if hf.itemConvertDiagRecord then
            hf.itemConvertDiagRecord({
                source = sourceTag,
                code = 'normalization_error',
                severity = 'error',
                item = nameLower,
                reason = tostring(err),
            })
        end
        row.name = nameLower
        row[wKey] = tonumber(row[wKey]) or tonumber(row.weight) or 0
        row.label = (type(row.label) == 'string' and row.label ~= '') and row.label or nameLower
        row.isUnique = row.isUnique == true
        row.isWeapon = row.isWeapon == true
        row.image = (type(row.image) == 'string' and row.image ~= '') and row.image or (nameLower .. '.png')
        row.ammoname = (type(row.ammoname) == 'string' and row.ammoname ~= '') and row.ammoname:lower() or nil
    end

    return row
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param amount number
--- @return any result
function hf.moneyFormat(amount)
    if Config.currency.suffix then
        return ('%s%s'):format(hf.numberFormat(amount), Config.currency.symbol)
    else
        return ('%s%s'):format(Config.currency.symbol, hf.numberFormat(amount))
    end
end

--- Checks whether player source currently exists (server-side).
---@param src number
---@return boolean
function hf.isValidPlayerSource(src)
    if type(src) ~= 'number' or src < 1 then
        return false
    end
    local name = GetPlayerName(src)
    return name ~= nil and name ~= ''
end

--- Admin API policy check (`Config.adminApi[section]`) based on `auth.source`.
--- @param section string For example: `cleanup`, `diagnostics`.
--- @param payload table|nil Optional payload: `{ auth = { source = number } }`.
--- @return boolean
--- @return string|nil
function hf.adminApiCanAccess(section, payload)
    local adminApi = (type(Config) == 'table' and type(Config.adminApi) == 'table') and Config.adminApi or {}
    local cfg = adminApi[tostring(section or '')] or {}
    local auth = type(payload) == 'table' and payload.auth or nil
    local src = type(auth) == 'table' and tonumber(auth.source) or nil

    if not src then
        if cfg.allowServerWithoutSource == true then
            return true, nil
        end
        return false, 'Missing auth.source for admin API call.'
    end

    if not hf.isValidPlayerSource(src) then
        return false, 'Invalid auth.source.'
    end

    local acePerm = tostring(cfg.acePermission or '')
    local aceOk = acePerm ~= '' and IsPlayerAceAllowed(src, acePerm)

    local idOk = false
    local list = cfg.allowedIdentifiers
    if hf.isPopulatedTable(list) then
        local ids = GetPlayerIdentifiers(src)
        for _, pid in ipairs(ids) do
            local low = tostring(pid):lower()
            for _, allow in ipairs(list) do
                if type(allow) == 'string' and allow ~= '' and low == allow:lower() then
                    idOk = true
                    break
                end
            end
            if idOk then
                break
            end
        end
    end

    if aceOk or idOk then
        return true, nil
    end
    return false, 'No permission (ACE or allowedIdentifiers).'
end

--- In-game admin NUI access check (`Config.web`, e.g. `ecore_admin` + `ecore.admin`):
--- ACE and/or `allowedIdentifiers`.
--- @param src number
--- @return boolean ok
--- @return string|nil err
function hf.webConsoleAccess(src)
    if not hf.isValidPlayerSource(src) then
        return false, 'Invalid player.'
    end
    local w = type(Config) == 'table' and Config.web or {}
    if w.enabled ~= true then
        return false, 'Admin console is disabled (Config.operator.admin.enabled = false).'
    end
    local acePerm = tostring(w.acePermission or '')
    local aceOk = acePerm ~= '' and IsPlayerAceAllowed(src, acePerm)
    local idOk = false
    local list = w.allowedIdentifiers
    if hf.isPopulatedTable(list) then
        local ids = GetPlayerIdentifiers(src)
        for _, pid in ipairs(ids) do
            local low = tostring(pid):lower()
            for _, allow in ipairs(list) do
                if type(allow) == 'string' and allow ~= '' and low == allow:lower() then
                    idOk = true
                    break
                end
            end
            if idOk then
                break
            end
        end
    end
    if aceOk or idOk then
        return true, nil
    end
    if acePerm == '' and not hf.isPopulatedTable(list) then
        return false,
            'No permission: set `Config.web.acePermission` with add_ace, or populate `Config.web.allowedIdentifiers`.'
    end
    return false, 'No permission for admin console (ACE or identifier list).'
end

--- Permission-denied audit (in-memory ring + optional cLog).
--- @param section string
--- @param action string
--- @param payload table|nil
--- @param reason string|nil
function hf.auditAdminApiDenied(section, action, payload, reason)
    hf.__adminApiDeniedAudit = hf.__adminApiDeniedAudit or {}

    local auth = type(payload) == 'table' and payload.auth or nil
    local src = type(auth) == 'table' and tonumber(auth.source) or nil
    local requestedBy = type(payload) == 'table' and tostring(payload.requestedBy or '') or ''

    local entry = {
        ts = os.time(),
        eventType = 'admin_api_denied',
        actor = {
            source = src,
            requestedBy = requestedBy ~= '' and requestedBy or nil,
        },
        target = {
            scope = tostring(section or 'unknown'),
            action = tostring(action or 'unknown'),
        },
        outcome = {
            status = 'denied',
            reason = tostring(reason or 'access_denied'),
        },
        section = tostring(section or 'unknown'),
        action = tostring(action or 'unknown'),
        source = src,
        requestedBy = requestedBy ~= '' and requestedBy or nil,
        reason = tostring(reason or 'access_denied'),
    }

    hf.__adminApiDeniedAudit[#hf.__adminApiDeniedAudit + 1] = entry
    while #hf.__adminApiDeniedAudit > 200 do
        table.remove(hf.__adminApiDeniedAudit, 1)
    end

    if type(cLog) == 'function' then
        cLog(
            ('[e_core] admin API denied: section=%s action=%s src=%s requestedBy=%s reason=%s'):format(
                entry.section,
                entry.action,
                tostring(entry.source),
                tostring(entry.requestedBy),
                entry.reason
            ),
            'warning',
            2
        )
    end

    -- Best-effort DB persistence (server only).
    if rawget(_G, 'MySQL') ~= nil then
        hf.mysqlAwait('admin_denied_audit:insert', function()
            MySQL.query.await(
                [[
                    INSERT INTO `e_core_admin_denied_audit`
                        (`section`, `action`, `source`, `requested_by`, `reason`)
                    VALUES (?, ?, ?, ?, ?)
                ]],
                {
                    entry.section,
                    entry.action,
                    entry.source,
                    entry.requestedBy,
                    entry.reason,
                }
            )
        end)
    end
end

--- Simple player+key rate limit (server net-event guard).
---@param src number player source
---@param name string unique key, e.g. event name
---@param cooldownMs number
---@return boolean true when call is allowed
function hf.netRateLimit(src, name, cooldownMs)
    if not hf.isValidPlayerSource(src) then
        return false
    end
    hf.__netRate = hf.__netRate or {}
    local k = tostring(src) .. '|' .. tostring(name)
    local now = GetGameTimer()
    local last = hf.__netRate[k] or 0
    if now - last < cooldownMs then
        return false
    end
    hf.__netRate[k] = now
    return true
end

--- Fills REGISTERED_ITEMS until eCore:getRegisteredItems() is non-empty or timeout.
--- Sets CORE_READY to true on success, false on timeout (nil while still waiting).
---@param logTag string cLog key (e.g. 'REGISTERED ITEMS')
---@return boolean success
function hf.awaitItemRegistryReady(logTag)
    local start = GetGameTimer()
    local timeout = GetConvarInt('e_core:items_ready_timeout_ms', 120000)
    if timeout < 30000 then
        timeout = 30000
    end
    if timeout > 600000 then
        timeout = 600000
    end
    local pollMs = GetConvarInt('e_core:items_ready_poll_ms', 1000)
    if pollMs < 200 then
        pollMs = 200
    end
    if pollMs > 5000 then
        pollMs = 5000
    end

    local nextLogAt = 15000
    local attempt = 0

    while not hf.isPopulatedTable(REGISTERED_ITEMS) do
        attempt = attempt + 1
        REGISTERED_ITEMS = eCore:getRegisteredItems()

        local elapsed = GetGameTimer() - start
        if elapsed >= timeout then
            CORE_READY = false
            cLog(logTag,
                ('TIMEOUT after %d ms (%d polls). Item registry still empty; increase convar e_core:items_ready_timeout_ms (max 600000) if inventory starts late.'):format(
                    elapsed, attempt), 1)
            return false
        end

        if elapsed >= nextLogAt then
            cLog(logTag,
                ('still waiting for item registry (elapsed %d ms, poll %d, timeout %d ms)'):format(elapsed, attempt, timeout),
                2)
            local step = elapsed < 30000 and 15000 or 45000
            nextLogAt = elapsed + step
        end

        Wait(pollMs)
    end

    CORE_READY = true
    return true
end

--- Returns active inventory override label (shared override config.lua flags).
---@return string
function hf.inventoryIntegrationLabel()
    local parts = {}
    if rawget(_G, 'OX_INVENTORY') == true then
        parts[#parts + 1] = 'ox_inventory'
    end
    if rawget(_G, 'QS_INVENTORY') == true then
        parts[#parts + 1] = 'qs-inventory'
    end
    if rawget(_G, 'AVP_GRID_INVENTORY') == true then
        parts[#parts + 1] = 'avp_grid_inventory'
    end
    if #parts == 0 then
        return 'framework'
    end
    return table.concat(parts, '+')
end

--- Prints one-line startup summary: version, framework, inventory layer, item-registry status.
---@param side string `server` or `client`
function hf.logEcoreStartupSummary(side)
    local ver = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '?'
    local fw = tostring(FRAMEWORK or 'none')
    local inv = hf.inventoryIntegrationLabel()
    local items = CORE_READY == true and 'ready' or (CORE_READY == false and 'timeout' or 'pending')
    print(('[^2e_core^7] [%s] v%s | framework=%s | inventory=%s | items=%s'):format(side, ver, fw, inv, items))
end

--- Wraps oxmysql **.await** calls with `pcall` and `cLog` on failure.
--- Call only from server thread (`MySQL` global).
---@param tag string log tag (for example: `loadMeta:identifier`)
---@param fn fun(): any
---@return boolean ok
---@return any result on success; error payload otherwise
function hf.mysqlAwait(tag, fn)
    if rawget(_G, 'MySQL') == nil then
        cLog(('[e_core][MySQL] %s: MySQL global is missing (non-server context?)'):format(tag), 'error', 1)
        return false, 'mysql_missing'
    end
    local ok, res = pcall(fn)
    if not ok then
        cLog(('[e_core][MySQL] %s: %s'):format(tag, tostring(res)), 'error', 1)
        return false, res
    end
    return true, res
end

--- Default job row when the framework did not supply a usable `job` table.
--- @return table
local function ecoreDefaultJobRow()
    return {
        name = 'unemployed',
        label = 'Unemployed',
        grade = 0,
        grade_name = 'unemployed',
        grade_label = 'Unemployed',
        grade_salary = 0,
        onduty = true,
        isboss = false,
    }
end

--- Default gang row for consumers that always read `gang` (ESX has no gang; QB may omit).
--- @return table
local function ecoreDefaultGangRow()
    return {
        name = 'none',
        label = 'No Gang',
        grade = 0,
        grade_name = 'none',
        grade_label = 'None',
        grade_salary = 0,
        isboss = false,
    }
end

--- Normalizes `job` to a single e_core consumer shape: flat numeric `grade`, `grade_name`,
--- `grade_label`, `grade_salary`, optional `isboss`. Supports QB nested `job.grade` and
--- ESX-style flat jobs. Mutates the input table **in place** when `job` is a table (keeps
--- QBCore / ESX live references); nil input returns a new unemployed-shaped table.
--- @param job table|nil
--- @return table
function hf.normalizePlayerJobForEcore(job)
    if type(job) ~= 'table' then
        return ecoreDefaultJobRow()
    end
    local gradeRaw = job.grade
    if type(gradeRaw) == 'table' then
        job.grade_name = gradeRaw.name
        job.grade_label = (type(gradeRaw.name) == 'string' and gradeRaw.name ~= '') and gradeRaw.name
            or (type(job.label) == 'string' and job.label or '')
        job.grade_salary = tonumber(job.payment) or tonumber(gradeRaw.payment) or 0
        job.grade = tonumber(gradeRaw.level) or 0
        job.isboss = gradeRaw.isboss == true
    elseif type(gradeRaw) == 'number' then
        job.grade = tonumber(gradeRaw) or 0
        job.grade_name = job.grade_name or job.name or 'unemployed'
        job.grade_label = job.grade_label or job.grade_name
            or (type(job.label) == 'string' and job.label or '')
        job.grade_salary = tonumber(job.grade_salary) or tonumber(job.payment) or 0
    else
        job.grade = tonumber(job.grade) or 0
        job.grade_name = job.grade_name or job.name or 'unemployed'
        job.grade_label = job.grade_label or job.grade_name
            or (type(job.label) == 'string' and job.label or '')
        job.grade_salary = tonumber(job.grade_salary) or tonumber(job.payment) or 0
    end
    return job
end

--- Same contract as `hf.normalizePlayerJobForEcore` for gang data (QB-Core nested `grade`).
--- Mutates `gang` in place when it is a table; nil returns a new neutral gang row.
--- @param gang table|nil
--- @return table
function hf.normalizePlayerGangForEcore(gang)
    if type(gang) ~= 'table' then
        return ecoreDefaultGangRow()
    end
    local gradeRaw = gang.grade
    if type(gradeRaw) == 'table' then
        gang.grade_name = gradeRaw.name
        gang.grade_label = (type(gradeRaw.name) == 'string' and gradeRaw.name ~= '') and gradeRaw.name
            or (type(gang.label) == 'string' and gang.label or 'None')
        gang.grade_salary = tonumber(gang.payment) or tonumber(gradeRaw.payment) or 0
        gang.grade = tonumber(gradeRaw.level) or 0
        gang.isboss = gradeRaw.isboss == true
    elseif type(gradeRaw) == 'number' then
        gang.grade = tonumber(gradeRaw) or 0
        gang.grade_name = gang.grade_name or gang.name or 'none'
        gang.grade_label = gang.grade_label or gang.grade_name
            or (type(gang.label) == 'string' and gang.label or 'None')
        gang.grade_salary = tonumber(gang.grade_salary) or tonumber(gang.payment) or 0
    else
        gang.grade = tonumber(gang.grade) or 0
        gang.grade_name = gang.grade_name or gang.name or 'none'
        gang.grade_label = gang.grade_label or gang.grade_name
            or (type(gang.label) == 'string' and gang.label or 'None')
        gang.grade_salary = tonumber(gang.grade_salary) or tonumber(gang.payment) or 0
    end
    return gang
end

--- Fills cross-framework display fields on the player table in place: `metadata` (empty table if
--- missing), `position` from `coords` when present, `firstName` / `lastName` / `charName`
--- (QB `charinfo` first, otherwise ESX-style fields / `variables` / `name`).
--- @param playerData table
--- @return nil
function hf.applyEcorePlayerDisplayFields(playerData)
    if type(playerData) ~= 'table' then
        return
    end
    if type(playerData.metadata) ~= 'table' then
        playerData.metadata = {}
    end
    local coords = playerData.coords or playerData.position
    if type(coords) == 'table' then
        playerData.position = coords
    end

    local ci = playerData.charinfo
    if type(ci) == 'table' then
        local fn = ci.firstname or ci.firstName
        local ln = ci.lastname or ci.lastName
        if type(fn) == 'string' and fn ~= '' and type(ln) == 'string' and ln ~= '' then
            playerData.firstName = fn
            playerData.lastName = ln
            playerData.charName = ('%s %s'):format(fn, ln)
            return
        end
    end

    local v = playerData.variables
    local first = playerData.firstName or playerData.firstname
    local last = playerData.lastName or playerData.lastname
    if (type(first) ~= 'string' or first == '') and type(v) == 'table' then
        first = v.firstName or v.firstname
        last = v.lastName or v.lastname
    end
    if type(first) == 'string' and first ~= '' and type(last) == 'string' and last ~= '' then
        playerData.firstName = first
        playerData.lastName = last
        playerData.charName = ('%s %s'):format(first, last)
        return
    end

    local n = playerData.name
    playerData.charName = (type(n) == 'string' and n ~= '') and n or ''
end
