--- e_core belső kiterjesztések ugyanarra a `hf` táblára, mint a `libs/helper.lua`.
--- Item registry normalizálás (`normalizeRegisteredItemDef`), indulás / registry várakozás,
--- MySQL `pcall` wrapper, net rate limit, pénzformátum (`Config.currency`) – ezek e_core környezetet feltételeznek.
--- Betöltés: `fxmanifest.lua` közvetlenül a `libs/helper.lua` után. Külső resource továbbra is `eCore.helper`-t kap (`bridge/main.lua`).

--- REGISTERED_ITEMS / getItemWeight / canCarryItem egyeztetett mezői (bridge + override convertItems).
--- @return string wKey
--- @return table weightKeys ordered list (same as normalizeRegisteredItemDef)
function hf.getRegisteredItemWeightKeyConfig()
    local wKey = 'weight'
    if type(Config) == 'table' and type(Config.fields) == 'table' and type(Config.fields.weight) == 'string' then
        wKey = Config.fields.weight
    end
    return wKey, { wKey, 'weight', 'Weight', 'itemWeight', 'item_weight', 'totalWeight' }
end

--- @param nameLower string már kisbetűs kulcs (pl. ox item kulcs)
--- @param row table a forrás item tábla (helyben módosul)
--- @return table row
function hf.normalizeRegisteredItemDef(nameLower, row)
    if type(row) ~= 'table' or type(nameLower) ~= 'string' or nameLower == '' then
        return row
    end

    local wKey, weightKeys = hf.getRegisteredItemWeightKeyConfig()

    local ok, err = pcall(function()
        row.name = nameLower

        local wNum
        for _, k in ipairs(weightKeys) do
            local n = tonumber(row[k])
            if n and n >= 0 then
                wNum = n
                break
            end
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

function hf.moneyFormat(amount)
    if Config.currency.suffix then
        return ('%s%s'):format(hf.numberFormat(amount), Config.currency.symbol)
    else
        return ('%s%s'):format(Config.currency.symbol, hf.numberFormat(amount))
    end
end

--- Létező játékos forrás-e (szerver).
---@param src number
---@return boolean
function hf.isValidPlayerSource(src)
    if type(src) ~= 'number' or src < 1 then
        return false
    end
    local name = GetPlayerName(src)
    return name ~= nil and name ~= ''
end

--- Admin API policy check (`Config.adminApi[section]`) `auth.source` alapján.
--- @param section string pl. `cleanup`, `diagnostics`
--- @param payload table|nil (opcionális: `{ auth = { source = number } }`)
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
        return false, 'Hiányzó auth.source az admin API híváshoz.'
    end

    if not hf.isValidPlayerSource(src) then
        return false, 'Érvénytelen auth.source.'
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
    return false, 'Nincs jogosultság (ACE vagy allowedIdentifiers).'
end

--- Játékbeli admin NUI (`Config.web`, pl. `ecore_admin` + `ecore.admin`): ACE és/vagy `allowedIdentifiers`.
--- @param src number
--- @return boolean ok
--- @return string|nil err
function hf.webConsoleAccess(src)
    if not hf.isValidPlayerSource(src) then
        return false, 'Érvénytelen játékos.'
    end
    local w = type(Config) == 'table' and Config.web or {}
    if w.enabled ~= true then
        return false, 'Az admin konzol ki van kapcsolva (Config.operator.admin.enabled = false).'
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
            'Nincs jogosultság: állíts `Config.web.acePermission`-t és add_ace-et, vagy töltsd a `Config.web.allowedIdentifiers` listát.'
    end
    return false, 'Nincs jogosultság az admin konzolhoz (ACE vagy azonosító lista).'
end

--- Jogosultság-elutasítás audit (in-memory ring + opcionális cLog).
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

--- Egyszerű rate limit játékos + kulcs szerint (szerver net eseményekhez).
---@param src number player source
---@param name string egyedi kulcs pl. eseménynév
---@param cooldownMs number
---@return boolean true ha mehet a hívás
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

--- Melyik inventory override aktív (shared override config.lua flagok).
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

--- Egy soros indulási összegzés: verzió, keretrendszer, inventory réteg, item registry állapot.
---@param side string `server` vagy `client`
function hf.logEcoreStartupSummary(side)
    local ver = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '?'
    local fw = tostring(FRAMEWORK or 'none')
    local inv = hf.inventoryIntegrationLabel()
    local items = CORE_READY == true and 'ready' or (CORE_READY == false and 'timeout' or 'pending')
    print(('[^2e_core^7] [%s] v%s | framework=%s | inventory=%s | items=%s'):format(side, ver, fw, inv, items))
end

--- oxmysql **.await** hívások: `pcall` + `cLog` hiba esetén. Csak **szerver** szálon hívd (`MySQL` globál).
---@param tag string napló címke (pl. `loadMeta:identifier`)
---@param fn fun(): any
---@return boolean ok
---@return any result ha ok; hibaérték ha nem ok
function hf.mysqlAwait(tag, fn)
    if rawget(_G, 'MySQL') == nil then
        cLog(('[e_core][MySQL] %s: MySQL globális hiányzik (nem szerver szál?)'):format(tag), 'error', 1)
        return false, 'mysql_missing'
    end
    local ok, res = pcall(fn)
    if not ok then
        cLog(('[e_core][MySQL] %s: %s'):format(tag, tostring(res)), 'error', 1)
        return false, res
    end
    return true, res
end
