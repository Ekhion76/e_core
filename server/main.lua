ECO = {}
ECO.meta = {}
ECO.idsToSync = {}
ECO.syncRequested = false

local hf = hf

CORE_READY, REGISTERED_ITEMS = nil, nil

CreateThread(function()

    while not hf.isPopulatedTable(REGISTERED_ITEMS) do

        REGISTERED_ITEMS = eCore:getRegisteredItems()
        Wait(1000)
    end

    cLog('SERVER CORE', 'READY')
    CORE_READY = true
end)

--eCore:createCallback('e_core:getRegisteredItems', function(source, cb)
--
--    while not hf.isPopulatedTable(REGISTERED_ITEMS) do
--
--        Wait(500)
--    end
--
--    cb(REGISTERED_ITEMS)
--end)