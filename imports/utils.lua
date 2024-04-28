--function print_r(data)
--    print(json.encode(data, { indent = true }))
--end

function print_r(t)
    local print_r_cache = {}
    local function sub_print_r(t, indent)
        if (print_r_cache[tostring(t)]) then
            print(indent .. "*" .. tostring(t))
        else
            print_r_cache[tostring(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] => " .. tostring(t) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
                        print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    else
                        print(indent .. "[" .. pos .. "] => " .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(t))
            end
        end
    end

    sub_print_r(t, "  ")
end

function createBlip(coords, sprite, color, scale, name)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

function animDictLoader(dict)
    if not dict or not DoesAnimDictExist(dict) then
        print('Animation dictionary does not exist!', dict)
        return false
    end

    if HasAnimDictLoaded(dict) then
        return dict
    end

    local attempts, maxAttempts = 0, 20
    while attempts < maxAttempts do
        if not HasAnimDictLoaded(dict) then
            RequestAnimDict(dict)
            Wait(100)
        else
            return dict
        end
        attempts = attempts + 1
    end

    print('Failed to load the animation dictionary!', dict)
    return false
end

function modelLoader(model)
    if not model or not IsModelValid(model) then
        print('Model it does not exist!', model)
        return false
    end

    if HasModelLoaded(model) then
        return model
    end

    local attempts, maxAttempts = 0, 20
    while attempts < maxAttempts do
        if not HasModelLoaded(model) then
            RequestModel(model)
            Wait(100)
        else
            return model
        end
        attempts = attempts + 1
    end

    print('The model failed to load!', model)
    return false
end

function fxLoader(dict)
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(10)
    end
end

function cLog(k, v, level)
    -- console log for debug
    if not Config.debugLevel or Config.debugLevel < 1 then
        return
    end

    if level and level > Config.debugLevel then
        return
    end

    local vType = type(v)

    if vType == 'table' or vType == 'function' then
        print('^3DEBUG', k, '^4')
        print_r(v)
        print('^7')
    else
        if vType == 'boolean' then
            v = v and 'true' or 'false'
        end

        if v == nil then
            v = 'nil'
        end

        print('^3DEBUG', k, '->^4', v, '^7')
    end
end