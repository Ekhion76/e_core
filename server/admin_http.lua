local json = json

local function responseHeaders()
    return {
        ['Content-Type'] = 'application/json; charset=utf-8',
        ['Access-Control-Allow-Origin'] = '*',
        ['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS',
        ['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, x-ecore-identifier, x-ecore-token',
    }
end

local function writeJson(res, statusCode, payload)
    res.writeHead(statusCode, responseHeaders())
    res.send(json.encode(payload))
end

local function trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function urlDecode(value)
    local s = tostring(value or '')
    s = s:gsub('+', ' ')
    s = s:gsub('%%(%x%x)', function(hex)
        return string.char(tonumber(hex, 16))
    end)
    return s
end

local function splitPathAndQuery(rawPath)
    local path = tostring(rawPath or '')
    local query = ''
    local qIndex = path:find('?', 1, true)
    if qIndex then
        query = path:sub(qIndex + 1)
        path = path:sub(1, qIndex - 1)
    end
    return path, query
end

local function parseQuery(queryString)
    local params = {}
    local raw = tostring(queryString or '')
    if raw == '' then
        return params
    end
    for pair in string.gmatch(raw, '([^&]+)') do
        local eq = pair:find('=', 1, true)
        local key, value
        if eq then
            key = urlDecode(pair:sub(1, eq - 1))
            value = urlDecode(pair:sub(eq + 1))
        else
            key = urlDecode(pair)
            value = ''
        end
        if key ~= '' then
            params[key] = value
        end
    end
    return params
end

local function getHeader(req, headerName)
    local headers = req and req.headers
    if type(headers) ~= 'table' then
        return nil
    end

    local wanted = string.lower(trim(headerName))
    for key, value in pairs(headers) do
        if string.lower(tostring(key)) == wanted then
            return tostring(value)
        end
    end
    return nil
end

local function getHttpReadConfig()
    local cfg = type(Config) == 'table' and Config.adminHttp or {}
    local read = type(cfg) == 'table' and cfg.read or {}
    return {
        enabled = type(cfg) == 'table' and cfg.enabled ~= false,
        identifierHeader = trim(read.identifierHeader ~= '' and read.identifierHeader or 'x-ecore-identifier'),
        tokenHeader = trim(read.tokenHeader ~= '' and read.tokenHeader or 'x-ecore-token'),
        allowedIdentifiers = type(read.allowedIdentifiers) == 'table' and read.allowedIdentifiers or {},
        token = trim(read.token or '')
    }
end

local function httpReadDenied(action, identifier, reason)
    if type(hf) == 'table' and type(hf.auditAdminApiDenied) == 'function' then
        hf.auditAdminApiDenied('http_read', action, {
            requestedBy = identifier or nil
        }, reason or 'access_denied')
    end
end

--- Read és write (CRUD) ugyanazt a `Config.adminHttp.read` policy-t használja.
local function canAccessHttpAdmin(req, action)
    local cfg = getHttpReadConfig()
    if cfg.enabled ~= true then
        return false, 'HTTP admin API letiltva (Config.adminHttp.enabled=false).'
    end

    local identifier = trim(getHeader(req, cfg.identifierHeader))
    local token = trim(getHeader(req, cfg.tokenHeader))

    local identifierOk = false
    if type(cfg.allowedIdentifiers) == 'table' and next(cfg.allowedIdentifiers) ~= nil and identifier ~= '' then
        local low = string.lower(identifier)
        for _, allowed in ipairs(cfg.allowedIdentifiers) do
            if type(allowed) == 'string' and trim(allowed) ~= '' and low == string.lower(trim(allowed)) then
                identifierOk = true
                break
            end
        end
    end

    local tokenOk = cfg.token ~= '' and token ~= '' and token == cfg.token
    if identifierOk or tokenOk then
        return true, nil
    end

    local reason = 'Nincs jogosultság (identifier vagy token).'
    if identifier == '' and token == '' then
        reason = 'Hiányzó auth header (identifier/token).'
    end
    httpReadDenied(action, identifier ~= '' and identifier or nil, reason)
    return false, reason
end

local function notFound(res)
    writeJson(res, 404, {
        ok = false,
        code = 'route_not_found',
        message = 'Admin route not found.'
    })
end

local function methodNotAllowed(res, methodsHint)
    writeJson(res, 405, {
        ok = false,
        code = 'method_not_allowed',
        message = ('Csak: %s.'):format(methodsHint or 'GET, POST, PUT, DELETE, OPTIONS')
    })
end

local function writeJsonBody(res, responseTable)
    writeJson(res, 200, responseTable)
end

local function withJsonBody(req, res, onDecodedTable)
    if type(req) ~= 'table' or type(req.setDataHandler) ~= 'function' then
        writeJson(res, 500, {
            ok = false,
            code = 'http_body_unavailable',
            message = 'A kérés body olvasója nem elérhető (setDataHandler).'
        })
        return
    end
    req.setDataHandler(function(data)
        local bodyStr = tostring(data or '')
        if bodyStr == '' then
            onDecodedTable({})
            return
        end
        local ok, decoded = pcall(json.decode, bodyStr)
        if not ok or type(decoded) ~= 'table' then
            writeJson(res, 400, {
                ok = false,
                code = eCoreErr.invalid_item_data,
                message = 'Érvénytelen JSON a kérés törzsében.'
            })
            return
        end
        onDecodedTable(decoded)
    end)
end

local function handleProfessionList(res)
    local response = professionAdminList()
    writeJsonBody(res, response)
end

local function handleLevelProfileList(res)
    local response = levelProfileAdminList()
    writeJsonBody(res, response)
end

local function handleProfessionDefaults(res, query)
    local category = trim(query.category or '')
    local ok, dataOrErr = getProfessionDefaults(category)
    if not ok then
        writeJsonBody(res, {
            ok = false,
            code = dataOrErr,
            message = 'Profession defaults lekeres sikertelen.'
        })
        return
    end
    writeJsonBody(res, {
        ok = true,
        code = eCoreErr.ok,
        message = 'Profession defaults lekerve.',
        data = {
            category = category,
            defaults = dataOrErr
        }
    })
end

local function handleProfessionValidate(res, query)
    local category = trim(query.category or '')
    local keysRaw = trim(query.keys or '')
    local keys = {}
    if keysRaw ~= '' then
        for chunk in string.gmatch(keysRaw, '([^,]+)') do
            local key = trim(chunk)
            if key ~= '' then
                keys[#keys + 1] = key
            end
        end
    end

    local ok, dataOrErr = validateProfessionKeys(category, keys)
    if not ok then
        writeJsonBody(res, {
            ok = false,
            code = dataOrErr,
            message = 'Profession key validacio sikertelen.'
        })
        return
    end
    writeJsonBody(res, {
        ok = true,
        code = eCoreErr.ok,
        message = 'Profession key validacio kesz.',
        data = dataOrErr
    })
end

local function handleProfessionProfile(res, query)
    local category = trim(query.category or '')
    local name = trim(query.name or '')
    local ok, dataOrErr = getProfessionLevelProfile(category, name)
    if not ok then
        writeJsonBody(res, {
            ok = false,
            code = dataOrErr,
            message = 'Profession profile lekeres sikertelen.'
        })
        return
    end
    writeJsonBody(res, {
        ok = true,
        code = eCoreErr.ok,
        message = 'Profession profile lekerve.',
        data = {
            category = category,
            name = name,
            profile = dataOrErr
        }
    })
end

SetHttpHandler(function(req, res)
    local path, queryString = splitPathAndQuery(req.path)
    local query = parseQuery(queryString)
    local method = string.upper(tostring(req.method or 'GET'))

    if method == 'OPTIONS' then
        writeJson(res, 200, {
            ok = true,
            code = 'ok',
            message = 'preflight'
        })
        return
    end

    if path == '/admin/professions' then
        local accessOk, accessErr = canAccessHttpAdmin(req, ('%s /admin/professions'):format(method))
        if not accessOk then
            writeJson(res, 401, {
                ok = false,
                code = eCoreErr.access_denied,
                message = accessErr or 'Nincs jogosultság.'
            })
            return
        end

        if method == 'GET' then
            handleProfessionList(res)
            return
        end
        if method == 'POST' then
            withJsonBody(req, res, function(body)
                local response = professionAdminCreate(body)
                writeJsonBody(res, response)
            end)
            return
        end
        if method == 'PUT' then
            local category = trim(query.category or '')
            local name = trim(query.name or '')
            withJsonBody(req, res, function(body)
                local response = professionAdminUpdate(category, name, body)
                writeJsonBody(res, response)
            end)
            return
        end
        if method == 'DELETE' then
            local category = trim(query.category or '')
            local name = trim(query.name or '')
            local response = professionAdminDelete(category, name)
            writeJsonBody(res, response)
            return
        end
        methodNotAllowed(res, 'GET, POST, PUT, DELETE')
        return
    end

    if path == '/admin/professions/defaults' then
        if method ~= 'GET' then
            methodNotAllowed(res, 'GET')
            return
        end
        local accessOk, accessErr = canAccessHttpAdmin(req, 'GET /admin/professions/defaults')
        if not accessOk then
            writeJson(res, 401, {
                ok = false,
                code = eCoreErr.access_denied,
                message = accessErr or 'Nincs jogosultsag.'
            })
            return
        end
        handleProfessionDefaults(res, query)
        return
    end

    if path == '/admin/professions/validate' then
        if method ~= 'GET' then
            methodNotAllowed(res, 'GET')
            return
        end
        local accessOk, accessErr = canAccessHttpAdmin(req, 'GET /admin/professions/validate')
        if not accessOk then
            writeJson(res, 401, {
                ok = false,
                code = eCoreErr.access_denied,
                message = accessErr or 'Nincs jogosultsag.'
            })
            return
        end
        handleProfessionValidate(res, query)
        return
    end

    if path == '/admin/professions/profile' then
        if method ~= 'GET' then
            methodNotAllowed(res, 'GET')
            return
        end
        local accessOk, accessErr = canAccessHttpAdmin(req, 'GET /admin/professions/profile')
        if not accessOk then
            writeJson(res, 401, {
                ok = false,
                code = eCoreErr.access_denied,
                message = accessErr or 'Nincs jogosultsag.'
            })
            return
        end
        handleProfessionProfile(res, query)
        return
    end

    if path == '/admin/level-profiles' then
        local accessOk, accessErr = canAccessHttpAdmin(req, ('%s /admin/level-profiles'):format(method))
        if not accessOk then
            writeJson(res, 401, {
                ok = false,
                code = eCoreErr.access_denied,
                message = accessErr or 'Nincs jogosultság.'
            })
            return
        end

        if method == 'GET' then
            handleLevelProfileList(res)
            return
        end
        if method == 'POST' then
            withJsonBody(req, res, function(body)
                local response = levelProfileAdminCreate(body)
                writeJsonBody(res, response)
            end)
            return
        end
        if method == 'PUT' then
            local profileKey = trim(query.profileKey or '')
            withJsonBody(req, res, function(body)
                local response = levelProfileAdminUpdate(profileKey, body)
                writeJsonBody(res, response)
            end)
            return
        end
        if method == 'DELETE' then
            local profileKey = trim(query.profileKey or '')
            local response = levelProfileAdminDelete(profileKey)
            writeJsonBody(res, response)
            return
        end
        methodNotAllowed(res, 'GET, POST, PUT, DELETE')
        return
    end

    notFound(res)
end)
