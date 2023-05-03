ECO = {}
ECO.meta = {}
ECO.lastSave = {}
ECO.idsToSync = {}
ECO.syncRequested = false

local hf = hf

CORE_READY, REGISTERED_ITEMS = nil, nil

CreateThread(function()

    cLog('REGISTERED ITEMS', 'Loading...', 2)

    while not hf.isPopulatedTable(REGISTERED_ITEMS) do

        REGISTERED_ITEMS = eCore:getRegisteredItems()
        Wait(1000)
    end

    cLog('REGISTERED ITEMS', 'Loaded', 2)
    CORE_READY = true
end)
