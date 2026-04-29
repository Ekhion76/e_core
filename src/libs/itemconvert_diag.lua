--- Item-convert diagnostics helper (`convertItems` + normalization fallback visibility).
--- Domain orchestration: run summary + fan-out to console/file sinks.

local hf = lib.require('src/imports/sdk/helper_base/shared')

hf.__itemConvertDiag = hf.__itemConvertDiag or {
    current = {
        runId = nil,
        source = nil,
        startedAt = nil,
        totalRows = 0,
        codes = {},
        samples = {},
    },
    last = nil,
}

local function unixNow()
    if type(os) == 'table' and type(os.time) == 'function' then
        return os.time()
    end
    if type(GetCloudTimeAsInt) == 'function' then
        local cloudTime = tonumber(GetCloudTimeAsInt())
        if cloudTime then
            return cloudTime
        end
    end
    if type(GetGameTimer) == 'function' then
        return math.floor((GetGameTimer() or 0) / 1000)
    end
    return 0
end

local function dayStamp()
    if type(os) == 'table' and type(os.date) == 'function' then
        return os.date('%Y-%m-%d')
    end
    return 'n-a'
end

local function diagIsoNow()
    if type(os) == 'table' and type(os.date) == 'function' then
        return os.date('!%Y-%m-%dT%H:%M:%SZ')
    end
    return ('unix:%s'):format(tostring(unixNow()))
end

local function normalizeSeverity(level)
    local s = tostring(level or 'warning'):lower()
    if s ~= 'error' and s ~= 'warning' and s ~= 'info' then
        return 'warning'
    end
    return s
end

--- Starts a new item-convert diagnostics run.
--- @param sourceTag string
--- @param totalRows number|nil
function hf.itemConvertDiagStartRun(sourceTag, totalRows)
    local st = hf.__itemConvertDiag
    st.current = {
        runId = tostring(sourceTag or 'itemconvert') .. '-' .. tostring(unixNow()),
        source = tostring(sourceTag or 'itemconvert'),
        startedAt = diagIsoNow(),
        totalRows = tonumber(totalRows) or 0,
        codes = {},
        samples = {},
    }
end

--- Records one item-convert diagnostics event.
--- @param evt table
function hf.itemConvertDiagRecord(evt)
    if type(evt) ~= 'table' then
        return
    end
    local st = hf.__itemConvertDiag
    local cur = st.current or {}
    local code = tostring(evt.code or 'unknown')
    local severity = normalizeSeverity(evt.severity)
    local item = tostring(evt.item or '')
    local source = tostring(evt.source or cur.source or 'itemconvert')
    local reason = tostring(evt.reason or '')
    local logFile = (type(hf.fileEventLogger) == 'table' and type(hf.fileEventLogger.buildPath) == 'function')
        and hf.fileEventLogger.buildPath({ baseDir = 'logs', prefix = 'itemconvert', ext = 'jsonl' })
        or ('logs/itemconvert-%s.jsonl'):format(dayStamp())

    cur.codes[code] = (cur.codes[code] or 0) + 1
    if #cur.samples < 30 then
        cur.samples[#cur.samples + 1] = {
            ts = diagIsoNow(),
            code = code,
            severity = severity,
            item = item,
            reason = reason,
            source = source,
        }
    end
    st.current = cur

    local payload = {
        ts = diagIsoNow(),
        subsystem = 'itemconvert',
        severity = severity,
        code = code,
        item = item,
        reason = reason,
        source = source,
        runId = cur.runId,
        logFile = logFile,
    }

    if type(hf.fileEventLogger) == 'table' and type(hf.fileEventLogger.writeJsonLine) == 'function' then
        local _, usedPath = hf.fileEventLogger.writeJsonLine({
            baseDir = 'logs',
            prefix = 'itemconvert',
            ext = 'jsonl',
            fallbackPath = 'itemconvert-fallback.jsonl',
        }, payload)
        if type(usedPath) == 'string' and usedPath ~= '' then
            payload.logFile = usedPath
        end
    end

    if type(hf.itemConvertConsoleSink) == 'table' and type(hf.itemConvertConsoleSink.emit) == 'function' then
        hf.itemConvertConsoleSink.emit(payload, { cooldownMs = 15000 })
    end
end

--- Finishes current run and stores it as last summary.
function hf.itemConvertDiagFinishRun()
    local st = hf.__itemConvertDiag
    st.last = st.current
end

--- Returns latest summary table.
--- @return table|nil
function hf.itemConvertDiagGetSummary()
    local st = hf.__itemConvertDiag
    return st.last or st.current
end

--- Builds compact summary lines for integrity/report.
--- @param maxCodes number|nil
--- @return table
function hf.itemConvertDiagSummaryLines(maxCodes)
    local out = {}
    local sum = hf.itemConvertDiagGetSummary()
    if type(sum) ~= 'table' then
        out[#out + 1] = 'ItemConvert diagnostics: nincs adat.'
        return out
    end
    out[#out + 1] = ('ItemConvert diagnostics run: source=%s started=%s rows=%s'):format(
        tostring(sum.source or 'n/a'),
        tostring(sum.startedAt or 'n/a'),
        tostring(sum.totalRows or 0)
    )
    local n = 0
    maxCodes = tonumber(maxCodes) or 8
    for code, cnt in pairs(sum.codes or {}) do
        out[#out + 1] = ('  - %s: %s'):format(tostring(code), tostring(cnt))
        n = n + 1
        if n >= maxCodes then
            break
        end
    end
    if n == 0 then
        out[#out + 1] = '  - no warnings/errors captured'
    end
    out[#out + 1] = ('ItemConvert log file: logs/itemconvert-%s.jsonl'):format(dayStamp())
    return out
end
