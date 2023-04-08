local hf = hf

function QBCoreFunctions()

    local self = QBCoreSharedFunctions()

    local ox_inventory = false

    if OX_INVENTORY then

        ox_inventory = exports.ox_inventory
    end

    function self.removeOxItems(playerId, items)

        if not hf.isPopulatedTable(items) then
            return false, 'there are no items to remove'
        end

        for item, amount in pairs(items) do

            if not ox_inventory:RemoveItem(playerId, item, amount) then

                return false, 'unknown_error'
            end
        end

        return true, 'ok'
    end

    function self.removeItems(xPlayer, items)

        if not hf.isPopulatedTable(items) then
            return false, 'there are no items to remove'
        end

        local count
        local inventory = xPlayer.items

        if hf.isEmpty(inventory) then

            return false, 'inventory_is_empty'
        end
        print_r(items)
        -- check all item exists:
        for itemToRemove, amountToRemove in pairs(items) do

            count = 0

            if amountToRemove > 0 then

                for _, item in pairs(inventory) do

                    if item.name:lower() == itemToRemove:lower() then
                        count = count + item.amount
                    end
                end

                if count < amountToRemove then
                    return false, 'not_enough_items'
                end
            end
        end


        -- item remove
        for itemToRemove, amountToRemove in pairs(items) do

            if amountToRemove > 0  then

                for _, item in pairs(inventory) do

                    if item.name:lower() == itemToRemove:lower() then

                        if item.amount >= amountToRemove then

                            item.amount = item.amount - amountToRemove
                            amountToRemove = 0

                        elseif item.amount < amountToRemove then

                            amountToRemove = amountToRemove - item.amount
                            item.amount = 0
                        end

                        if amountToRemove == 0 then
                            break
                        end
                    end
                end
            end
        end

        -- save inventory
        local temp = {}

        for slot, item in pairs(inventory) do

            if item.amount > 0 then

                temp[slot] = item
            end
        end

        eCore.setInventory(xPlayer, temp)
        return true, 'ok'
    end

    return self
end