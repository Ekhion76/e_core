local hf = hf

eCore:createCallback('e_core:createVehicle', function(source, cb, pos, model, vType, props)
    if not hf.isValidPlayerSource(source) then
        cb(nil, nil)
        return
    end
    local netId, serverId = eCore:createVehicle(pos, model, vType, props)
    cb(netId, serverId)
end)