local hf = hf

local function coordNum(v)
    local n = tonumber(v)
    if n == nil or n ~= n then
        return nil
    end
    return n
end

function eCore:createVehicle(pos, model, vType, props)
    local owner = -1
    local plate = ''
    local vehicle, netId

    if props ~= nil and not hf.isTable(props) then
        return false, eCoreErr.unknown_error
    end
    props = props or {}

    if not hf.isTable(pos) then
        return false, eCoreErr.unknown_error
    end
    local px, py, pz = coordNum(pos.x), coordNum(pos.y), coordNum(pos.z)
    local pw = coordNum(pos.w) or 0.0
    if not px or not py or not pz then
        return false, eCoreErr.unknown_error
    end

    local modelHash
    if type(model) == 'number' and model ~= 0 then
        modelHash = model
    elseif hf.isPopulatedString(model) then
        modelHash = joaat(model)
    else
        return false, eCoreErr.unknown_error
    end

    if CreateVehicleServerSetter and hf.isPopulatedString(vType) then
        vehicle = CreateVehicleServerSetter(modelHash, vType, px, py, pz, pw)
    else
        vehicle = CreateVehicle(modelHash, px, py, pz, pw, true, true)
    end

    Wait(500)

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return false, eCoreErr.unknown_error
    end

    local try = 1
    repeat
        plate = GetVehicleNumberPlateText(vehicle)
        try = try + 1
        Wait(0)
    until plate ~= '' or try > 200

    if not hf.isPopulatedString(plate) then
        DeleteEntity(vehicle)
        return false, eCoreErr.vehicle_no_plate_data
    end

    try = 1
    repeat
        owner = NetworkGetEntityOwner(vehicle)
        try = try + 1
        Wait(0)
    until owner ~= -1 or try > 200

    if owner == -1 then
        DeleteEntity(vehicle)
        return false, eCoreErr.unknown_error
    end

    local netTries = 0
    repeat
        netId = NetworkGetNetworkIdFromEntity(vehicle)
        netTries = netTries + 1
        if netId and netId ~= 0 then
            break
        end
        Wait(100)
    until netTries >= 50

    if not netId or netId == 0 then
        DeleteEntity(vehicle)
        return false, eCoreErr.unknown_error
    end

    props.plate = props.plate or plate
    TriggerClientEvent('e_core:methodCaller', owner, 'setVehiclePropertiesFromNetId', netId, props)
    return netId, vehicle
end