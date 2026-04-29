--- Generic JSONL file event logger (server-side write, client no-op).
--- Keeps file naming/append concerns reusable across subsystems.

local hf = lib.require('src/imports/sdk/helper_base/shared')

hf.fileEventLogger = hf.fileEventLogger or {}

--- @param dateFmt string|nil
--- @return string
local function buildDateStamp(dateFmt)
    return os.date(dateFmt or '%Y-%m-%d')
end

--- @return boolean
local function isServer()
    return type(IsDuplicityVersion) == 'function' and IsDuplicityVersion()
end

--- @param payload table
--- @return string|nil
local function encodeJson(payload)
    local ok, out = pcall(function()
        return json.encode(payload)
    end)
    if ok and type(out) == 'string' then
        return out
    end
    return nil
end

--- @param path string
--- @param line string
--- @return boolean
local function appendLine(path, line)
    local full = GetResourcePath(GetCurrentResourceName()) .. '/' .. path
    local f = io.open(full, 'a')
    if not f then
        return false
    end
    f:write(line)
    f:write('\n')
    f:close()
    return true
end

--- Builds dated log path using config.
--- @param opts table
--- @return string
function hf.fileEventLogger.buildPath(opts)
    opts = type(opts) == 'table' and opts or {}
    local baseDir = tostring(opts.baseDir or 'logs')
    local prefix = tostring(opts.prefix or 'events')
    local ext = tostring(opts.ext or 'jsonl')
    local dateFmt = tostring(opts.dateFormat or '%Y-%m-%d')
    local stamp = buildDateStamp(dateFmt)
    return ('%s/%s-%s.%s'):format(baseDir, prefix, stamp, ext)
end

--- Writes one JSONL event line to dated file.
--- @param opts table Logger options (`baseDir`, `prefix`, `ext`, `fallbackPath`).
--- @param payload table Event payload.
--- @return boolean ok
--- @return string path Used target file path.
function hf.fileEventLogger.writeJsonLine(opts, payload)
    opts = type(opts) == 'table' and opts or {}
    payload = type(payload) == 'table' and payload or {}

    local path = hf.fileEventLogger.buildPath(opts)
    if not isServer() then
        return true, path
    end

    local line = encodeJson(payload)
    if not line then
        return false, path
    end

    local ok = appendLine(path, line)
    if ok then
        return true, path
    end

    local fallback = tostring(opts.fallbackPath or
    ('%s.%s'):format(tostring(opts.prefix or 'events'), tostring(opts.ext or 'jsonl')))
    local fbOk = appendLine(fallback, line)
    return fbOk, fbOk and fallback or path
end
