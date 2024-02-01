sharedEvents = {}

table.insert(sharedEvents, {
    name = 'e_core:methodCaller',
    method = function(method, ...)
        eCore[method](eCore, table.unpack({...} or {}))
    end
})