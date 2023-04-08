function print_r(data)

    print(json.encode(data, { indent = true }))
end

function translate(str, ...)

    if locales[Config.locale] then

        return locales[Config.locale][str] and string.format(locales[Config.locale][str], ...) or str
    end

    return 'locale [' .. Config.locale .. '] does not exist'
end

function settingLimits(v, max)

    return v < 0 and 0 or v > max and max or v
end
