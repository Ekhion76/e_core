--- Legacy-compatible locale helpers exposed as shared chunk.
--- `Lang` must be present from e_core locale bootstrap.

local function _normalizeArgs(key, ...)
    local t = { ... }
    if #t == 1 and type(t[1]) == 'table' then
        return t[1]
    end
    return t
end

function translate(key, ...)
    if type(Lang) ~= 'function' then
        return tostring(key or '')
    end
    local args = _normalizeArgs(key, ...)
    return Lang(key, table.unpack(args))
end

function translateU(key, ...)
    return translate(key, ...):upper()
end
