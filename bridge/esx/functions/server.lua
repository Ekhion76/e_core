local hf = hf

function ESXFunctions()

    local self = globalFunctions()
    local ESXShared = ESXSharedFunctions()

    for k, v in pairs(ESXShared) do

        self[k] = v
    end

    local ox_inventory = false

    if OX_INVENTORY then

        ox_inventory = exports.ox_inventory
    end

    function self.removeOxItems(playerId, items)

        if not hf.isPopulatedTable(items) then
            return false, 'there are no items to remove'
        end

        for _, item in pairs(items) do

            if not ox_inventory:RemoveItem(playerId, item.name, item.amount) then

                return false, 'unknown_error'
            end
        end

        return true, 'ok'
    end

    function self.removeItems(xPlayer, items)

        if not hf.isPopulatedTable(items) then
            return false, 'there are no items to remove'
        end
    end

    function self.getInventoryLimits()

        -- xPlayer.getMaxWeight() -- lehet működik alap inventoryval is!
        -- ox_inventory:GetInventory(playerId, false) -- needed playerId
        local esMaxWeight = ESX.GetConfig().MaxWeight
        local maxSlots = OX_INVENTORY and 50 or Config.maxInventorySlots
        local maxWeight = esMaxWeight and esMaxWeight * 1000 or Config.maxInventoryWeight

        return {
            slots = GetConvarInt('inventory:slots', maxSlots),
            maxWeight = GetConvarInt('inventory:weight', maxWeight),
        }
    end

    return self
end