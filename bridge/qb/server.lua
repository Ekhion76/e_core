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

        TriggerClientEvent('QBCore:Notify', source, message, mType, mSec) -- CHANGE ME
    end

    function eCore:drawText(source, message, position, mType)

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
            bank = 'bank',
            black_money = 'crypto'
        }

        account = convert[account]

        return xPlayer.Functions.AddMoney(account, amount, reason)
    end

    function eCore:removeMoney(xPlayer, account, amount, reason)

        if type(xPlayer) == 'number' then

            xPlayer = QBCore.Functions.GetPlayer(xPlayer)
        end

        local convert = { -- ESX2QB

            money = 'cash',
            bank = 'bank',
            black_money = 'crypto'
        }

        account = convert[account]

        return xPlayer.Functions.RemoveMoney(account, amount, reason)
    end

    function eCore:getAccounts(xPlayer, account)

        local convert = { -- ESX2QB

            money = 'cash',
            bank = 'bank',
            black_money = 'crypto'
        }

        account = convert[account]

        if not account then

            return 0
        end

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

    function eCore:removeItem(xPlayer, item, count, metadata, slot)

        return xPlayer.Functions.RemoveItem(item, count)
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