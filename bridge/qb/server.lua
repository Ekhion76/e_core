if QB_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- copy it to the standalone/ directory and modify it there!
    -- this way, your changes will not be lost in future e_core updates

    local hf = hf

    function eCore:createCallback(name, callback)
        QBCore.Functions.CreateCallback(name, callback)
    end

    function eCore:createUsableItem(item, cb)
        QBCore.Functions.CreateUseableItem(item, cb)
    end

    function eCore:sendMessage(source, message, mType, mSec)
        if mType == 'info' then mType = 'primary' end
        TriggerClientEvent('QBCore:Notify', source, message, mType, mSec) -- CHANGE ME
    end

    function eCore:drawText(source, message, position, mType)
        if mType == 'info' then mType = 'primary' end
        TriggerClientEvent('qb-core:client:DrawText', source, message, position) -- CHANGE ME
    end

    function eCore:hideText(source)
        TriggerClientEvent('qb-core:client:HideText', source) -- CHANGE ME
    end

    function eCore:addMoney(xPlayer, account, amount, reason)
        if type(xPlayer) == 'number' then
            xPlayer = QBCore.Functions.GetPlayer(xPlayer)
        end

        local convert = { -- ESX2QB
            money = 'cash',
            black_money = 'crypto',
        }

        account = convert[account] and convert[account] or account
        return xPlayer.Functions.AddMoney(account, amount, reason)
    end

    function eCore:removeMoney(xPlayer, account, amount, reason)
        if type(xPlayer) == 'number' then
            xPlayer = QBCore.Functions.GetPlayer(xPlayer)
        end

        local convert = { -- ESX2QB
            money = 'cash',
            black_money = 'crypto',
        }

        account = convert[account] and convert[account] or account
        return xPlayer.Functions.RemoveMoney(account, amount, reason)
    end

    function eCore:getAccounts(xPlayer, account)
        local convert = { -- ESX2QB
            money = 'cash',
            black_money = 'crypto',
        }

        account = convert[account] and convert[account] or account
        return xPlayer.money[account]
    end

    ------------------------------------------------------------------------
    --- INVENTORY
    ------------------------------------------------------------------------

    function eCore:getInventory(xPlayer)
        return xPlayer.items
    end

    function eCore:addItem(xPlayer, item, count, slot, metadata)
        if not xPlayer.Functions.AddItem(item, count, slot, metadata) then
            return false, 'inventory_full'
        end

        return true
    end

    function eCore:getPlayerMaxWeight(xPlayer)
        return Config.maxInventoryWeight
    end

    function eCore:removeItem(xPlayer, itemName, count, metadata, slot)
        count = tonumber(count)
        if not hf.isPopulatedString(itemName) or not count or count < 1 then
            return false, 'no_items_to_remove'
        end

        if count == 1 then
            return xPlayer.Functions.RemoveItem(itemName, count)
        end

        local itemLowerName = itemName:lower()
        local inventory = xPlayer.items

        if hf.isEmpty(inventory) then
            return false, 'inventory_is_empty'
        end

        local totalItemsCount = 0

        for _, inventoryItem in pairs(inventory) do
            if inventoryItem.name:lower() == itemLowerName then
                totalItemsCount = totalItemsCount + inventoryItem.amount
            end
        end

        if totalItemsCount < count then
            return false, 'not_enough_items'
        end

        for _, item in pairs(inventory) do
            if item.name:lower() == itemLowerName then
                if item.amount >= count then
                    item.amount = item.amount - count
                    count = 0
                elseif item.amount < count then
                    count = count - item.amount
                    item.amount = 0
                end

                if count == 0 then
                    break
                end
            end
        end

        -- save inventory
        local temp = {}

        for inventorySlot, item in pairs(inventory) do
            if item.amount > 0 then
                temp[inventorySlot] = item
            end
        end

        xPlayer.Functions.SetInventory(temp, true)
        return true, 'ok'
    end

    function eCore:removeItems(xPlayer, items)
        if not hf.isPopulatedTable(items) then
            return false, 'no_items_to_remove'
        end

        local count
        local inventory = xPlayer.items

        if hf.isEmpty(inventory) then
            return false, 'inventory_is_empty'
        end

        -- check all item exists:
        for _, itemToRemove in pairs(items) do
            count = 0
            if itemToRemove.amount > 0 then
                for _, item in pairs(inventory) do
                    if item.name:lower() == itemToRemove.name:lower() then
                        count = count + item.amount
                    end
                end

                if count < itemToRemove.amount then
                    return false, 'not_enough_items'
                end
            end
        end

        -- item remove
        for _, itemToRemove in pairs(items) do
            local amountToRemove = itemToRemove.amount

            if amountToRemove > 0 then
                for _, item in pairs(inventory) do
                    if item.name:lower() == itemToRemove.name:lower() then
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

        xPlayer.Functions.SetInventory(temp, true)
        return true, 'ok'
    end

    function eCore:getPlayer(playerId)
        return eCore:convertPlayer(QBCore.Functions.GetPlayer(playerId))
    end

    function eCore:itemBox(playerId, productInfo, event, amount)
        if Config.itemBox then
            TriggerClientEvent('inventory:client:ItemBox', playerId, productInfo, event, amount)
        end
    end

    ------------------------------------------------------------------------
    --- COMMANDS
    ------------------------------------------------------------------------

    function eCore:addCommands(name, help, arguments, argsrequired, callback, permission, ...)
        QBCore.Commands.Add(name, help, arguments, argsrequired, callback, permission, ...)
    end
end