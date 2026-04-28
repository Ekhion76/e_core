-- luacheck: push ignore 131
local M = {}

--- Recursively prints table/function values to console for debug sessions.
--- @param t table|function|any Value to dump.
--- @return nil
function M.print_r(t)
    local print_r_cache = {}
    --- Internal recursive walker with cycle protection.
    --- @param tbl table|any Current node.
    --- @param indent string Current indentation prefix.
    --- @return nil
    local function sub_print_r(tbl, indent)
        if (print_r_cache[tostring(tbl)]) then
            print(indent .. "*" .. tostring(tbl))
        else
            print_r_cache[tostring(tbl)] = true
            if (type(tbl) == "table") then
                for pos, val in pairs(tbl) do
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] => " .. tostring(tbl) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
                        print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    else
                        print(indent .. "[" .. pos .. "] => " .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(tbl))
            end
        end
    end

    sub_print_r(t, "  ")
end

--- Creates a map blip and returns the created handle.
--- @param coords table Vector-like table with x, y, z.
--- @param sprite number Blip sprite ID.
--- @param color number Blip color ID.
--- @param scale number Blip scale.
--- @param name string Blip display name.
--- @return number blip Created blip handle.
function M.createBlip(coords, sprite, color, scale, name)
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

--- Loads an animation dictionary with bounded retries.
--- @param dict string Animation dictionary name.
--- @return string|false loadedDict Dictionary name when loaded, otherwise false.
function M.animDictLoader(dict)
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

--- Loads a model with bounded retries.
--- @param model number|string Model hash or model name.
--- @return number|string|false loadedModel Model identifier when loaded, otherwise false.
function M.modelLoader(model)
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

--- Requests and waits until a particle FX dictionary is loaded.
--- @param dict string Particle FX dictionary name.
--- @return nil
function M.fxLoader(dict)
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(10)
    end
end

return M
-- luacheck: pop
