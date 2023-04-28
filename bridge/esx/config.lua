ESX_CORE = GetResourceState('es_extended') == 'started'

if ESX_CORE then
    -- These settings / functions can be overrides in the standalone/ folder!!!

    ESX = exports['es_extended']:getSharedObject()
    eCore = {}
    Config = {}

    Config.maxInventoryWeight = GetConvarInt('inventory:weight', ESX.GetConfig().MaxWeight * 1000)
    Config.maxInventorySlots = GetConvarInt('inventory:slots', 50)

    Config.imagePath = '/'

    -- Inventory itembox message
    -- This box appears when adding or deleting items
    -- In the case of OX inventory, for example, it appears by default, so it can be disabled here
    Config.itemBox = false

    -- Sets how the inventory stores the weight of the stacks.
    -- for example, ox_inventory slot.weight contains the weight of the entire stack. (slot.sumWeight = slot.weight)
    -- other inventories return the weight of 1 item, so it must be multiplied by the number of items (slot.sumWeight = slot.weight * slot.count)
    Config.totalStackWeight = false -- false = (slot.sumWeight = slot.weight * slot.count)

    -- Different inventories index the fields differently.
    -- E.g: ox_inventory: count; qb_inventory: amount, grid inventory: quantity
    -- Use: getInventory() result, set the user inventory fields
    Config.fields = {
        name = 'name',
        count = 'count',
        slot = 'slot',
        weight = 'weight',

        -- metaData fields
        serial = 'serial' -- metadata.serial
    }
end