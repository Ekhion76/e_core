AVP_GRID_INVENTORY = GetResourceState('avp_grid_inventory') == 'started'

if AVP_GRID_INVENTORY then

    Config.maxInventoryWeight = 50 -- see source/cfx_based/config.lua CONFIG.PLAYER_INVENTORY_DEFAULTS
    Config.maxInventorySlots = 0

    Config.imagePath = 'https://cfx-nui-avp_grid_inventory/html/items/'

    -- Inventory itembox message
    -- This box appears when adding or deleting items
    -- In the case of OX inventory, for example, it appears by default, so it can be disabled here
    Config.itemBox = false

    -- Sets how the inventory stores the weight of the stacks.
    -- for example, ox_inventory slot.weight contains the weight of the entire stack. (slot.sumWeight = slot.weight)
    -- other inventories return the weight of 1 item, so it must be multiplied by the number of items (slot.sumWeight = slot.weight * slot.count)
    -- Config.totalStackWeight = true -- false = (slot.sumWeight = slot.weight * slot.count), true = (slot.sumWeight = slot.weight)

    -- Different inventories index the fields differently.
    -- E.g: ox_inventory: count; qb_inventory: amount, grid inventory: quantity
    -- Use: getInventory() result, set the user inventory fields
    Config.fields = {
        name = 'item',
        count = 'quantity',
        slot = 'slot',
        weight = 'weight',

        -- metaData fields
        serial = 'serial' -- metadata.serial
    }
end