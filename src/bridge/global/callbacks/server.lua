local hf = lib.require('src/imports/sdk/helper_base/shared')

--- ESX kliens item bootstrap: a szerveren már megbízható `eCore:getRegisteredItems()` (ESX.Items / cache); a kliens nem használhat játékos inventoryt katalógusként.
--- @param source number
--- @return table|nil items Non-empty registry table, or `nil` if unavailable / invalid source.
lib.callback.register('e_core:getRegisteredItems', function(source)
    if not hf.isValidPlayerSource(source) then
        return nil
    end
    local ok, res = pcall(function()
        return eCore:getRegisteredItems()
    end)
    if not ok or type(res) ~= 'table' or not hf.hasEntries(res) then
        return nil
    end
    return res
end)

eCore:createCallback('e_core:createVehicle', function(source, cb, pos, model, vType, props)
    if not hf.isValidPlayerSource(source) then
        cb(nil, nil)
        return
    end
    local netId, serverId = eCore:createVehicle(pos, model, vType, props)
    cb(netId, serverId)
end)
