-- luacheck: push ignore 131
--- Globális nyelvi táblák: `locales/<kód>.lua` tölti (`locales["en"]` stb.).
locales = {}

local fmt = string.format
local unpack = table.unpack

--- @return table|nil locale A használható fordítótábla, vagy nil ha sem a kért, sem az `en` nincs betöltve.
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

--- Kulcs alapján fordítás. Hiányzó nyelvi fájl esetén `en`-re esik vissza (ha elérhető).
--- `string.format` helykitöltők: csak akkor fut, ha a szöveg tartalmaz `%` mintát és van variadikus argumentum.
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

--- Első karakter nagybetű (ASCII `%l`); UTF-8 több bájtos kezdőbetűt nem normalizál.
function translateU(str, ...)
    local translated = translate(str, ...)
    if translated == "" then
        return translated
    end
    return (translated:gsub("^%l", string.upper))
end
-- luacheck: pop
