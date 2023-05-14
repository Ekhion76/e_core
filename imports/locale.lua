locales = {}

function translate(str, ...)

    if locales[Config.locale] then

        return locales[Config.locale][str] and string.format(locales[Config.locale][str], ...) or str
    end

    return 'locale [' .. Config.locale .. '] does not exist'
end

function translateU(str, ...)
    return _(str, ...):gsub("^%l", string.upper)
end