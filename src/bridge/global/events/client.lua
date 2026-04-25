sharedEvents = {}

--- Only these methods are callable through `TriggerClientEvent('e_core:methodCaller', ...)` (client side).
local methodCallerAllowed = {
    setVehiclePropertiesFromNetId = true,
}

table.insert(sharedEvents, {
    name = 'e_core:methodCaller',
    method = function(method, ...)
        if type(method) ~= 'string' or not methodCallerAllowed[method] then
            print(('^1[e_core]^7 methodCaller: method not allowed: %s (type: %s)'):format(
                tostring(method),
                type(method)
            ))
            cLog('e_core:methodCaller', ('rejected: %s'):format(tostring(method)), 1)
            return
        end

        eCore[method](eCore, table.unpack({...} or {}))
    end
})