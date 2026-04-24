--- Mindkét kontextusban (kliens + szerver): `getFrameWork` / `getCore` exportok; `eCore.helper` = `hf` (`libs/helper.lua` + `libs/helper_ecore.lua`), `eCore.Err` = `eCoreErr`.
--- A QB/ESX ciklusok csak netesemény-regisztrációt végeznek, nem váltanak export ágat.
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
eCore.Err = eCoreErr

exports("getFrameWork", function()

    return FRAMEWORK
end)

exports("getCore", function()

    return eCore
end)