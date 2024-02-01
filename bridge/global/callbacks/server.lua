local hf = hf

eCore:createCallback('e_core:createVehicle', function(source, cb, pos, model, vType, props)

    local playerId = source
    local netId, serverId = eCore:createVehicle(pos, model, vType, props)
    cb( netId, serverId )
end)