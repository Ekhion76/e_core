locales = {}

function translate(str, ...)
    local locale = locales[Config.locale]
    if not locale then
        return 'locale [' .. Config.locale .. '] does not exist'
    end

    local translation = locale[str]
    if not translation then
        return str
    end

    local args = { ... }

    if translation:find("%%") and #args > 0 then
        local ok, formatted = pcall(string.format, translation, table.unpack(args))
        if ok then
            return formatted
        else
            return translation .. ' (format error)'
        end
    else
        return translation
    end
end

function translateU(str, ...)
    local translated = translate(str, ...)
    return translated:gsub("^%l", string.upper)
end
