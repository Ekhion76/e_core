Config = Config or {}

if QB_CORE then

    for _, event in ipairs(QBEvents) do
        RegisterNetEvent(event.name, event.method)
    end
end

if ESX_CORE then

    for _, event in ipairs(ESXEvents) do

        RegisterNetEvent(event.name, event.method)
    end
end

--for k, v in pairs(eCore:getSettings()) do
--    -- inventory fields, itembox, imagePath, etc..
--    Config[k] = v
--end

eCore.helper = hf

exports("getCore", function()

    return eCore
end)