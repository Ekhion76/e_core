local hf = hf

function eCore:createVehicle(pos, model, vType, props)
    model = joaat(model)
    local owner = -1
    local plate = ''
    local vehicle, netId
    props = props or {}

    if CreateVehicleServerSetter and hf.isPopulatedString(vType) then
        vehicle = CreateVehicleServerSetter(model, vType, pos.x, pos.y, pos.z, pos.w)
    else
        local createAutomobile = GetHashKey('CREATE_AUTOMOBILE')
        vehicle = Citizen.InvokeNative(createAutomobile, model, pos.xyz, pos.w, true, true)
    end

    Wait(500)

    local try = 1
    repeat
        plate = GetVehicleNumberPlateText(vehicle)
        try = try + 1
        Wait(0)
    until plate ~= '' or try > 200

    if not hf.isPopulatedString(plate) then
        return false, 'Failed: No data can be retrieved from the vehicle.'
    end

    try = 1
    repeat
        owner = NetworkGetEntityOwner(vehicle)
        try = try + 1
        Wait(0)
    until owner ~= -1 or try > 200

    netId = NetworkGetNetworkIdFromEntity(vehicle)
    while not netId do
        Wait(100)
    end

    props.plate = props.plate or plate
    TriggerClientEvent('e_core:methodCaller', owner, 'setVehiclePropertiesFromNetId', netId, props)
    return netId, vehicle
end
