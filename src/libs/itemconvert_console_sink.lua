--- Itemconvert console sink with cLog formatting and rate limit.

local hf = lib.require('src/imports/sdk/helper_base/shared')

hf.itemConvertConsoleSink = hf.itemConvertConsoleSink or {}
hf.__itemConvertConsoleRate = hf.__itemConvertConsoleRate or {}

--- @param severity string|nil
--- @return string
local function normalizeSeverity(severity)
    local s = tostring(severity or 'warning'):lower()
    if s ~= 'error' and s ~= 'warning' and s ~= 'info' then
        return 'warning'
    end
    return s
end

--- @param key string
--- @param cooldownMs number
--- @return boolean
local function rateAllowed(key, cooldownMs)
    local now = type(GetGameTimer) == 'function' and GetGameTimer() or 0
    local last = hf.__itemConvertConsoleRate[key] or 0
    if now - last < cooldownMs then
        return false
    end
    hf.__itemConvertConsoleRate[key] = now
    return true
end

--- Emits one console line for itemconvert event (warning/error preferred).
--- @param evt table
--- @param opts table|nil (`cooldownMs`)
function hf.itemConvertConsoleSink.emit(evt, opts)
    if type(evt) ~= 'table' then
        return
    end
    opts = type(opts) == 'table' and opts or {}

    local severity = normalizeSeverity(evt.severity)
    if severity ~= 'warning' and severity ~= 'error' then
        return
    end

    local code = tostring(evt.code or 'unknown')
    local item = tostring(evt.item or '')
    local reason = tostring(evt.reason or '')
    local source = tostring(evt.source or 'itemconvert')
    local logFile = tostring(evt.logFile or '-')
    local key = code .. '|' .. item
    local cooldownMs = tonumber(opts.cooldownMs) or 15000

    if not rateAllowed(key, cooldownMs) then
        return
    end

    local msg = ('[e_core][itemconvert][%s] code=%s item=%s reason=%s source=%s file=%s')
        :format(string.upper(severity), code, item ~= '' and item or '-', reason ~= '' and reason or '-', source, logFile)

    hf.cLog(msg, severity, severity == 'error' and 1 or 2)
end
