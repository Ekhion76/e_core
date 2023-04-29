ECO = {}
ECO.meta = {}
ECO.idsToSync = {}
ECO.syncRequested = false

local hf = hf

CORE_READY, REGISTERED_ITEMS = nil, nil

CreateThread(function()

    cLog('SERVER CORE', 'Load registered items', 2)
    while not hf.isPopulatedTable(REGISTERED_ITEMS) do

        REGISTERED_ITEMS = eCore:getRegisteredItems()
        Wait(1000)
    end

    cLog('SERVER CORE', 'Registered items loaded', 2)
    CORE_READY = true
end)
