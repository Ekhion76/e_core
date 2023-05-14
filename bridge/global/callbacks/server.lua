local hf = hf

eCore:createCallback('e_core:createVehicle', function(source, cb, pos, model, vType)

    model = GetHashKey(model)
    local vehicle, netId = false, false

    --Vehicle types
    --automobile
    --bike
    --boat
    --heli
    --plane
    --submarine
    --trailer
    --train

    if CreateVehicleServerSetter and hf.isPopulatedString(vType) then

        vehicle = CreateVehicleServerSetter(model, vType, pos.x, pos.y, pos.z, pos.w)
    else

        local createAutomobile = GetHashKey('CREATE_AUTOMOBILE')
        vehicle = Citizen.InvokeNative(createAutomobile, model, pos.xyz, pos.w, true, true)
    end

    Wait(500) -- DoesEntityExist always 1!

    if DoesEntityExist(vehicle) then

        netId = NetworkGetNetworkIdFromEntity(vehicle)
        while not netId do Wait(100) end
    end

    cb(netId)
end)