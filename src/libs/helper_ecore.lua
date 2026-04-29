--- e_core-specific helpers isolated from the base `hf` table.
--- Includes item registry normalization (`normalizeRegisteredItemDef`), startup/registry waiting,
--- MySQL `pcall` wrapper, admin access checks, and currency formatting (`Config.currency`).
--- Load order: `fxmanifest.lua` loads this file immediately after `libs/helper.lua`.
--- Runtime objects:
--- - `hf`: base generic helper table from `libs/helper.lua`
--- - `hfe`: e_core-specific helper table from this file

local hf = lib.require('src/imports/sdk/helper_base/shared')
hfe = hfe or {}

--- Shared weight-key contract for REGISTERED_ITEMS / getItemWeight / canCarryItem
--- (bridge + override convertItems compatibility).
--- @return string wKey
--- @return table weightKeys ordered list (same as normalizeRegisteredItemDef)
function hfe.getRegisteredItemWeightKeyConfig()
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
function hfe.normalizeRegisteredItemDef(nameLower, row, diagCtx)
    if type(row) ~= 'table' or type(nameLower) ~= 'string' or nameLower == '' then
        return row
    end

    local wKey, weightKeys = hfe.getRegisteredItemWeightKeyConfig()
    local sourceTag = type(diagCtx) == 'table' and tostring(diagCtx.source or 'itemconvert') or 'itemconvert'

    local ok, err = pcall(function()
        row.name = nameLower

        -- Resolve weight from multiple known key aliases to keep stack compatibility.
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

        -- Resolve human label from a prioritized alias list.
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
        hf.cLog('eCore:normalizeRegisteredItemDef', { name = nameLower, err = tostring(err) }, 1)
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

--- Formats amount using central currency config.
--- This keeps consumer-facing currency display consistent across resources.
---@param amount number
---@return string formatted
function hfe.moneyFormat(amount)
    local currency = (type(Config) == 'table' and type(Config.currency) == 'table') and Config.currency or {}
    local symbol = tostring(currency.symbol or '')
    if currency.suffix then
        return ('%s%s'):format(hf.formatNumber(amount), symbol)
    else
        return ('%s%s'):format(symbol, hf.formatNumber(amount))
    end
end

--- Admin API policy check (`Config.adminApi[section]`) based on `auth.source`.
--- @param section string For example: `cleanup`, `diagnostics`.
--- @param payload table|nil Optional payload: `{ auth = { source = number } }`.
--- @return boolean ok
--- @return string|nil err
function hfe.adminApiCanAccess(section, payload)
    local adminApi = (type(Config) == 'table' and type(Config.adminApi) == 'table') and Config.adminApi or {}
    local cfg = adminApi[tostring(section or '')] or {}
    local auth = type(payload) == 'table' and payload.auth or nil
    local src = type(auth) == 'table' and tonumber(auth.source) or nil

    if not src then
        if cfg.allowServerWithoutSource == true then
            return true, nil
        end
        return false, eCoreErr.admin_missing_auth_source
    end

    if not hf.isValidPlayerSource(src) then
        return false, eCoreErr.admin_invalid_auth_source
    end

    local acePerm = tostring(cfg.acePermission or '')
    local aceOk = acePerm ~= '' and IsPlayerAceAllowed(src, acePerm)

    local idOk = false
    local list = cfg.allowedIdentifiers
    if hf.hasEntries(list) then
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
    return false, eCoreErr.admin_api_policy_denied
end

--- In-game admin NUI access check (`Config.web`, e.g. `ecore_admin` + `ecore.admin`):
--- Permission field and/or `allowedIdentifiers` (`config_check` szintézis).
--- @param src number
--- @return boolean ok
--- @return string|nil err
function hfe.webConsoleAccess(src)
    if not hf.isValidPlayerSource(src) then
        return false, eCoreErr.admin_invalid_web_player
    end
    local w = type(Config) == 'table' and Config.web or {}
    if w.enabled ~= true then
        return false, eCoreErr.admin_console_disabled
    end
    local acePerm = tostring(w.acePermission or '')
    local aceOk = acePerm ~= '' and IsPlayerAceAllowed(src, acePerm)
    local idOk = false
    local list = w.allowedIdentifiers
    if hf.hasEntries(list) then
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
    if acePerm == '' and not hf.hasEntries(list) then
        return false, eCoreErr.admin_web_unconfigured
    end
    return false, eCoreErr.admin_web_denied
end

--- Permission-denied audit (in-memory ring + optional cLog).
--- @param section string
--- @param action string
--- @param payload table|nil
--- @param reason string|nil
function hfe.auditAdminApiDenied(section, action, payload, reason)
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

    hf.cLog(
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

    -- Server-only persistence: `mysql` (table) or `discord` (webhook); see `Config.adminApi.deniedAudit.storage`.
    if not IsDuplicityVersion() then
        return
    end

    local adminApi = (type(Config) == 'table' and type(Config.adminApi) == 'table') and Config.adminApi or {}
    local da = type(adminApi.deniedAudit) == 'table' and adminApi.deniedAudit or {}
    local storage = tostring(da.storage or 'mysql'):lower()
    if storage ~= 'mysql' and storage ~= 'discord' then
        storage = 'mysql'
    end

    if type(MySQL) == 'table' then
        hfe.mysqlAwait('admin_denied_audit:insert', function()
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
        return
    end

    if storage == 'discord' then
        local url = hf.trim(tostring(da.webhookUrl or ''))
        if url == '' then
            return
        end
        local botName = hf.trim(tostring(da.discordBotName or ''))
        if botName == '' then
            botName = tostring((type(Config) == 'table' and Config.discordBotName) or 'ECOBOT')
        end
        local log = exports.e_core:createDiscordLog(url, botName, {})
        if log then
            log:embed({
                color = 'orange',
                title = 'e_core: admin denied',
                timestamp = true,
                fields = {
                    { name = 'Section', value = entry.section, inline = true },
                    { name = 'Action', value = entry.action, inline = true },
                    { name = 'Source', value = tostring(entry.source), inline = true },
                    { name = 'Requested by', value = tostring(entry.requestedBy or '—'), inline = true },
                    { name = 'Reason', value = entry.reason, inline = false },
                },
            })
            log:send()
        end
    end
end

--- Fills REGISTERED_ITEMS until eCore:getRegisteredItems() is non-empty or timeout.
--- Sets CORE_READY to true on success, false on timeout. Initial state is `false` (client/server `main.lua`); no `nil` „waiting” sentinel.
---@param logTag string cLog key (e.g. 'REGISTERED ITEMS')
---@return boolean success
function hfe.awaitItemRegistryReady(logTag)
    logTag = tostring(logTag or 'REGISTERED ITEMS')
    if _ECORE_INIT_FAILED == true then
        CORE_READY = false
        hf.cLog(logTag, 'Skipped item registry load: e_core is in IDLE state due to framework detect/init failure.', 1)
        return false
    end

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

    -- Poll with bounded timeout to tolerate late inventory startup sequencing.
    while not hf.hasEntries(REGISTERED_ITEMS) do
        attempt = attempt + 1
        local ok, result = pcall(function()
            return eCore:getRegisteredItems()
        end)
        if ok then
            -- `getRegisteredItems` visszadhat `false, eCoreErr.not_ready` (ESX kliens); ne tároljunk nem-tábla értéket, különben a loop és a `hasItem` hívások elromlanak.
            if type(result) == 'table' and hf.hasEntries(result) then
                REGISTERED_ITEMS = result
            else
                REGISTERED_ITEMS = nil
            end
        else
            if attempt == 1 then
                hf.cLog(logTag, ('getRegisteredItems failed: %s'):format(tostring(result)), 1)
            end
            REGISTERED_ITEMS = nil
        end

        local elapsed = GetGameTimer() - start
        if elapsed >= timeout then
            CORE_READY = false
            hf.cLog(logTag,
                ('TIMEOUT after %d ms (%d polls). Item registry still empty; increase convar e_core:items_ready_timeout_ms (max 600000) if inventory starts late.')
                :format(
                    elapsed, attempt), 1)
            return false
        end

        if elapsed >= nextLogAt then
            hf.cLog(logTag,
                ('still waiting for item registry (elapsed %d ms, poll %d, timeout %d ms)'):format(
                    elapsed,
                    attempt,
                    timeout
                ),
                2)
            local step = elapsed < 30000 and 15000 or 45000
            nextLogAt = elapsed + step
        end

        Wait(pollMs)
    end

    CORE_READY = true
    return true
end

--- Builds a future-proof runtime descriptor for inventory integration.
--- Uses generic signals (override mode + capabilities), not hardcoded resource names.
---@return table descriptor
---@return string descriptor.mode `framework` or `override`
---@return string descriptor.profile `framework:auto` or `override:auto`
---@return number descriptor.flagCount Count of enabled `*_INVENTORY` flags in globals.
---@return table descriptor.capabilities Runtime capability booleans.
function hfe.getInventoryRuntimeDescriptor()
    local flagCount = 0
    for key, value in pairs(_G) do
        if type(key) == 'string' and type(value) == 'boolean' and value == true and key:match('_INVENTORY$') then
            flagCount = flagCount + 1
        end
    end

    local mode = flagCount > 0 and 'override' or 'framework'
    local profile = mode .. ':auto'
    local core = type(eCore) == 'table' and eCore or {}

    local capabilities = {
        getInventory = type(core.getInventory) == 'function',
        getInventoryWeight = type(core.getInventoryWeight) == 'function',
        getPlayerMaxWeight = type(core.getPlayerMaxWeight) == 'function',
        canCarryItem = type(core.canCarryItem) == 'function',
        canSwapItems = type(core.canSwapItems) == 'function',
        addItem = type(core.addItem) == 'function',
        removeItem = type(core.removeItem) == 'function',
        removeItems = type(core.removeItems) == 'function',
        getItemCount = type(core.getItemCount) == 'function',
        hasItem = type(core.hasItem) == 'function',
    }

    return {
        mode = mode,
        profile = profile,
        flagCount = flagCount,
        capabilities = capabilities,
    }
end

--- Prints one-line startup summary: version, framework, inventory runtime descriptor, item-registry status.
---@param side string `server` or `client`
function hfe.logEcoreStartupSummary(side)
    if _ECORE_INIT_FAILED == true then
        return
    end

    local ver = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '?'
    local fw = tostring(FRAMEWORK or 'none')
    local inv = hfe.getInventoryRuntimeDescriptor()
    local state = 'ACTIVE'
    local items = 'pending'
    if CORE_READY == true then
        items = 'ready'
    elseif CORE_READY == false then
        items = 'not_ready'
    end
    local caps = inv.capabilities
    local capList = {}
    if caps.getInventory then capList[#capList + 1] = 'getInventory' end
    if caps.getInventoryWeight then capList[#capList + 1] = 'getInventoryWeight' end
    if caps.getPlayerMaxWeight then capList[#capList + 1] = 'getPlayerMaxWeight' end
    if caps.canCarryItem then capList[#capList + 1] = 'canCarryItem' end
    if caps.canSwapItems then capList[#capList + 1] = 'canSwapItems' end
    if caps.addItem then capList[#capList + 1] = 'addItem' end
    if caps.removeItem then capList[#capList + 1] = 'removeItem' end
    if caps.removeItems then capList[#capList + 1] = 'removeItems' end
    if caps.getItemCount then capList[#capList + 1] = 'getItemCount' end
    if caps.hasItem then capList[#capList + 1] = 'hasItem' end
    local capSummary = table.concat(capList, ',')

    print(('[^2e_core^7] [%s] v%s | state=%s | framework=%s | inventory_mode=%s | inventory_profile=%s | inventory_flags=%s | inventory_caps=%s | items=%s')
    :format(
        side, ver, state, fw, inv.mode, inv.profile, tostring(inv.flagCount), capSummary ~= '' and capSummary or 'none',
        items))
end

--- Wraps oxmysql **.await** calls with `pcall` and `cLog` on failure.
--- Call only from server thread (`MySQL` global).
---@param tag string log tag (for example: `loadMeta:identifier`)
---@param fn fun(): any
---@return boolean ok
---@return any resultOrError
function hfe.mysqlAwait(tag, fn)
    tag = tostring(tag or 'mysqlAwait')
    if type(fn) ~= 'function' then
        hf.cLog(('[e_core][MySQL] %s: fn is not a function'):format(tag), 'error', 1)
        return false, 'invalid_function'
    end
    if type(MySQL) ~= 'table' then
        hf.cLog(('[e_core][MySQL] %s: MySQL global is missing (non-server context?)'):format(tag), 'error', 1)
        return false, eCoreErr.mysql_missing
    end
    local ok, res = pcall(fn)
    if not ok then
        hf.cLog(('[e_core][MySQL] %s: %s'):format(tag, tostring(res)), 'error', 1)
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
function hfe.normalizePlayerJobForEcore(job)
    if type(job) ~= 'table' then
        return ecoreDefaultJobRow()
    end
    -- Support both QB nested grade objects and ESX flat grade fields in-place.
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
function hfe.normalizePlayerGangForEcore(gang)
    if type(gang) ~= 'table' then
        return ecoreDefaultGangRow()
    end
    -- Same normalization policy as job to keep consumer access uniform.
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
function hfe.applyEcorePlayerDisplayFields(playerData)
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
