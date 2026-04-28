--- Shared bootstrap for both client and server contexts.
--- Exposes `getFrameWork` and `getCore` exports and binds helper/error tables.
--- QB/ESX loops below only register framework events and do not alter export contracts.
if QB_CORE then
    for _, event in ipairs(QBEvents) do
        hf.cLog('REGISTER EVENT:', event.name, 2)
        RegisterNetEvent(event.name, event.method)
    end
end

if ESX_CORE then
    for _, event in ipairs(ESXEvents) do
        RegisterNetEvent(event.name, event.method)
    end
end

eCore.Err = eCoreErr

eCoreLifecycle_registerExtensions()
eCoreLifecycle_initExtensions(_eCoreInternal)
eCoreLifecycle_mergeShallow(eCore, eCoreLifecycle_buildPublicAPI())

if GetConvar('e_core_dev', 'false') == 'true' then
    --- Dev-only: internal table for debugging. Never rely on this in production consumers.
    --- @return table|nil
    exports('getInternal', function()
        return _eCoreInternal
    end)
end

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

--- Returns base generic helper table (`libs/helper.lua`).
--- @return table helper
exports("getHelperBase", function()
    return hf
end)

--- Returns e_core-specific helper table (`libs/helper_ecore.lua`).
--- @return table helperEcore
exports("getHelperEcore", function()
    return hfe
end)