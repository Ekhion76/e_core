OX_INVENTORY = GetResourceState('ox_inventory') == 'started'

if OX_INVENTORY then

    Config.maxInventoryWeight = GetConvarInt('inventory:weight', 24000)
    Config.maxInventorySlots = GetConvarInt('inventory:slots', 50)

    Config.imagePath = 'https://cfx-nui-ox_inventory/web/images/'

    -- Inventory itembox message
    -- This box appears when adding or deleting items
    -- In the case of OX inventory, for example, it appears by default, so it can be disabled here
    Config.itemBox = false

    -- Sets how the inventory stores the weight of the stacks.
    -- for example, ox_inventory slot.weight contains the weight of the entire stack. (slot.sumWeight = slot.weight)
    -- other inventories return the weight of 1 item, so it must be multiplied by the number of items (slot.sumWeight = slot.weight * slot.count)
    Config.totalStackWeight = true -- false = (slot.sumWeight = slot.weight * slot.count), true = (slot.sumWeight = slot.weight)

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