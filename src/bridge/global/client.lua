--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param cb function
--- @return any result
function eCore:createCallback(name, cb)
    lib.callback.register(name, cb)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param timeout number
--- @param cb function
--- @param ... any
--- @return any result
function eCore:triggerCallback(name, timeout, cb, ...)
    lib.callback(name, timeout, cb, ...)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param timeout number
--- @param ... any
--- @return any result
function eCore:triggerCallbackAwait(name, timeout, ...)
    return lib.callback.await(name, timeout, ...)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param state table
--- @return any result
function eCore:disableTargeting(state)
    exports.ox_target:disableTargeting(state)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param options any
--- @return any result
function eCore:addGlobalOption(options)
    exports.ox_target:addGlobalOption(options)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param optionNames any
--- @return any result
function eCore:removeGlobalOption(optionNames)
    exports.ox_target:removeGlobalOption(optionNames)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param options any
--- @return any result
function eCore:addGlobalObject(options)
    exports.ox_target:addGlobalObject(options)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param optionNames any
--- @return any result
function eCore:removeGlobalObject(optionNames)
    exports.ox_target:removeGlobalObject(optionNames)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param options any
--- @return any result
function eCore:addGlobalPed(options)
    exports.ox_target:addGlobalPed(options)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param optionNames any
--- @return any result
function eCore:removeGlobalPed(optionNames)
    exports.ox_target:removeGlobalPed(optionNames)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param options any
--- @return any result
function eCore:addGlobalPlayer(options)
    exports.ox_target:addGlobalPlayer(options)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param optionNames any
--- @return any result
function eCore:removeGlobalPlayer(optionNames)
    exports.ox_target:removeGlobalPlayer(optionNames)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param options any
--- @return any result
function eCore:addGlobalVehicle(options)
    exports.ox_target:addGlobalVehicle(options)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param optionNames any
--- @return any result
function eCore:removeGlobalVehicle(optionNames)
    exports.ox_target:removeGlobalVehicle(optionNames)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param models any
--- @param options any
--- @return any result
function eCore:addModel(models, options)
    exports.ox_target:addModel(models, options)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param models any
--- @param optionNames any
--- @return any result
function eCore:removeModel(models, optionNames)
    exports.ox_target:removeModel(models, optionNames)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param netIds any
--- @param options any
--- @return any result
function eCore:addEntity(netIds, options)
    exports.ox_target:addEntity(netIds, options)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param netIds any
--- @param optionNames any
--- @return any result
function eCore:removeEntity(netIds, optionNames)
    exports.ox_target:removeEntity(netIds, optionNames)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param entities any
--- @param options any
--- @return any result
function eCore:addLocalEntity(entities, options)
    exports.ox_target:addLocalEntity(entities, options)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param entities any
--- @param optionNames any
--- @return any result
function eCore:removeLocalEntity(entities, optionNames)
    exports.ox_target:removeLocalEntity(entities, optionNames)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param parameters any
--- @return any result
function eCore:addSphereZone(parameters)
    exports.ox_target:addSphereZone(parameters)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param parameters any
--- @return any result
function eCore:addBoxZone(parameters)
    exports.ox_target:addBoxZone(parameters)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param parameters any
--- @return any result
function eCore:addPolyZone(parameters)
    exports.ox_target:addPolyZone(parameters)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param id number
--- @return any result
function eCore:removeZone(id)
    exports.ox_target:removeZone(id)
end
