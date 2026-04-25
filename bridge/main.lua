--- Shared bootstrap for both client and server contexts.
--- Exposes `getFrameWork` and `getCore` exports and binds helper/error tables.
--- QB/ESX loops below only register framework events and do not alter export contracts.
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

--- Returns detected framework key (`esx`, `qb`, ...).
--- @return string framework Active framework identifier.
exports("getFrameWork", function()

    return FRAMEWORK
end)

--- Returns the runtime core facade table.
--- @return table core eCore facade object.
exports("getCore", function()

    return eCore
end)