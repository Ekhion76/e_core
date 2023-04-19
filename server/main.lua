ECO = {}
ECO.meta = {}
ECO.idsToSync = {}
ECO.syncRequested = false

local hf = hf

REGISTERED_ITEMS, INVENTORY_CONFIG = nil, nil

CreateThread(function()

    while not hf.isPopulatedTable(REGISTERED_ITEMS) do

        REGISTERED_ITEMS = FUNCTIONS.getRegisteredItems()
        Wait(1000)
    end
end)

local inventoryLimits = FUNCTIONS.getInventoryLimits()

INVENTORY_CONFIG = {
    SLOTS = inventoryLimits.slots,
    MAX_WEIGHT = inventoryLimits.maxWeight
}

eCore.createCallback('e_core:serverSync', function(source, cb)

    cb(inventoryLimits)
end)