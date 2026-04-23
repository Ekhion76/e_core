sharedEvents = {}

--- Csak ezek hívhatók `TriggerClientEvent('e_core:methodCaller', …)` útján (kliens).
local methodCallerAllowed = {
    setVehiclePropertiesFromNetId = true,
}

table.insert(sharedEvents, {
    name = 'e_core:methodCaller',
    method = function(method, ...)
        if type(method) ~= 'string' or not methodCallerAllowed[method] then
            print(('^1[e_core]^7 methodCaller: nem engedélyezett metódus: %s (típus: %s)'):format(
                tostring(method),
                type(method)
            ))
            cLog('e_core:methodCaller', ('elutasítva: %s'):format(tostring(method)), 1)
            return
        end

        eCore[method](eCore, table.unpack({...} or {}))
    end
})