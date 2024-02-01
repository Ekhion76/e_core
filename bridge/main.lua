if QB_CORE then

    for _, event in ipairs(QBEvents) do

        cLog('REGISTER EVENT:', event.name, 2)
        RegisterNetEvent(event.name, event.method)
    end
end

if ESX_CORE then

    for _, event in ipairs(ESXEvents) do

        RegisterNetEvent(event.name, event.method)
    end
end

eCore.helper = hf

exports("getFrameWork", function()

    return FRAMEWORK
end)

exports("getCore", function()

    return eCore
end)