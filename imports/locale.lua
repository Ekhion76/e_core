-- luacheck: push ignore 131
--- Global locale tables loaded by `locales/<code>.lua` files (`locales["en"]`, etc.).
locales = {}

local fmt = string.format
local unpack = table.unpack

--- @return table|nil locale Resolved translation table, or nil if neither selected locale nor `en` is loaded.
local function resolveLocale()
    local cfg = Config
    local code = (cfg and type(cfg.locale) == "string" and cfg.locale ~= "") and cfg.locale or "en"
    local pack = locales[code]
    if pack then
        return pack
    end
    if code ~= "en" then
        return locales["en"]
    end
    return nil
end

--- Translates by key. Falls back to `en` when selected locale is missing (if available).
--- `string.format` placeholders are applied only when text contains `%` and variadic arguments are provided.
function translate(str, ...)
    if str == nil then
        return ""
    end
    if type(str) ~= "string" then
        return tostring(str)
    end

    local locale = resolveLocale()
    if not locale then
        local cfg = Config
        local code = (cfg and type(cfg.locale) == "string" and cfg.locale ~= "") and cfg.locale or "en"
        return ("locale [%s] does not exist"):format(code)
    end

    local translation = locale[str]
    if translation == nil then
        return str
    end

    if type(translation) ~= "string" then
        return str
    end

    local args = { ... }
    if translation:find("%%") and #args > 0 then
        local ok, formatted = pcall(fmt, translation, unpack(args))
        if ok then
            return formatted
        end
        return translation .. " (format error)"
    end

    return translation
end

--- Uppercases first character (ASCII `%l`); does not normalize multi-byte UTF-8 initials.
function translateU(str, ...)
    local translated = translate(str, ...)
    if translated == "" then
        return translated
    end
    return (translated:gsub("^%l", string.upper))
end
-- luacheck: pop
