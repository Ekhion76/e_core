QB_CORE = GetResourceState('qb-core') == 'started'

if QB_CORE then
    -- These settings / functions can be overrides in the standalone/ folder!!!
    FRAMEWORK = 'qb'
    QBCore = exports['qb-core']:GetCoreObject()
    eCore = {}
    Config = {}

    Config.maxInventoryWeight = GetConvarInt('inventory:weight', 120000) -- These settings are overridden in the STANDALONE folder!
    Config.maxInventorySlots = GetConvarInt('inventory:slots', 41) -- These settings are overridden in the STANDALONE folder!

    -- See qb-core\shared\items.lua --> ['image'] = 'example.png' or ['image'] = 'images/example.png',
    -- imagePath = "https://cfx-nui-qb-inventory/html/images/"
    -- imagePath = "https://cfx-nui-qb-inventory/html/"
    -- imagePath = "https://cfx-nui-qs-inventory/html/images/"
    -- imagePath = "https://cfx-nui-lj-inventory/html/"
    -- imagePath = "https://cfx-nui-lj-inventory/html/images/"

    Config.imagePath = 'https://cfx-nui-qb-inventory/html/images/'

    -- Inventory itembox message
    -- This box appears when adding or deleting items
    -- In the case of OX inventory, for example, it appears by default, so it can be disabled here
    Config.itemBox = true

    -- Sets how the inventory stores the weight of the stacks.
    -- for example, ox_inventory slot.weight contains the weight of the entire stack. (slot.sumWeight = slot.weight)
    -- other inventories return the weight of 1 item, so it must be multiplied by the number of items (slot.sumWeight = slot.weight * slot.count)
    Config.totalStackWeight = false -- false = (slot.sumWeight = slot.weight * slot.count)

    -- Different inventories index the fields differently.
    -- E.g: ox_inventory: count; qb_inventory: amount, grid inventory: quantity
    -- Use: getInventory() result, set the user inventory fields
    Config.fields = {
        name = 'name',
        count = 'amount',
        slot = 'slot',
        weight = 'weight',

        -- metaData fields
        serial = 'serie' -- metadata.serial
    }
end