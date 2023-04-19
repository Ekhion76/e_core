function QBCoreBridge()

    local self = {}
    local ox_inventory = false

    if OX_INVENTORY then

        ox_inventory = exports.ox_inventory
    end

    function self.createCallback(name, callback)

        QBCore.Functions.CreateCallback(name, callback)
    end

    function self.createUsableItem(item, cb)

        QBCore.Functions.CreateUseableItem(item, cb)
    end

    function self.sendMessage(source, message, mType, mSec)

        TriggerClientEvent('QBCore:Notify', source, message, mType, mSec) -- CHANGE ME
    end

    function self.drawText(source, message, position, mType)

        TriggerClientEvent('qb-core:client:DrawText', source, message, position) -- CHANGE ME
    end

    function self.hideText(source)

        TriggerClientEvent('qb-core:client:HideText', source) -- CHANGE ME
    end

    function self.addMoney(xPlayer, account, amount, reason)

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

    function self.removeMoney(xPlayer, account, amount, reason)

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

    function self.getAccounts(xPlayer, account)

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

    function self.getInventoryConfig()

        return INVENTORY_CONFIG
    end

    function self.getInventory(xPlayer)

        return xPlayer.items
    end

    function self.setInventory(xPlayer, items)

        xPlayer.Functions.SetInventory(items, true)
    end

    function self.getInventoryWeight(xPlayer)

        return FUNCTIONS.getInventoryWeight(xPlayer)
    end

    function self.addItem(xPlayer, item, count, slot, metadata)

        if OX_INVENTORY then

            local success, response = ox_inventory:AddItem(xPlayer.source, item, count, metadata)

            if not success then

                return false, response
            end
        else

            if not xPlayer.Functions.AddItem(item, count, slot, metadata) then

                return false, 'inventory_full'
            end
        end

        return true
    end

    function self.removeItem(xPlayer, item, count, metadata, slot)

        if OX_INVENTORY then

            return ox_inventory:RemoveItem(xPlayer.source, item, count)
        end

        return xPlayer.Functions.RemoveItem(item, count)
    end

    function self.removeItems(xPlayer, itemList)

        if OX_INVENTORY then

            return FUNCTIONS.removeOxItems(xPlayer.source, itemList)
        end

        return FUNCTIONS.removeItems(xPlayer, itemList)
    end

    function self.getPlayer(playerId)

        return FUNCTIONS.convertPlayer(QBCore.Functions.GetPlayer(playerId))
    end

    function self.getRegisteredItems()

        return REGISTERED_ITEMS
    end

    function self.getAmountOfItems(inventory)

        return FUNCTIONS.getAmountOfItems(inventory)
    end

    function self.canSwapItems(swappingItems, itemData, playerData)

        return FUNCTIONS.canSwapItems(swappingItems, itemData, playerData)
    end

    function self.canCarryItem(itemData, playerData)

        return FUNCTIONS.canCarryItem(itemData, playerData)
    end

    function self.itemBox(playerId, productInfo, event, amount)

        TriggerClientEvent('inventory:client:ItemBox', playerId, productInfo, event, amount)
    end

    ------------------------------------------------------------------------
    --- COMMANDS
    ------------------------------------------------------------------------

    function self.addCommands(name, help, arguments, argsrequired, callback, permission, ...)

        QBCore.Commands.Add(name, help, arguments, argsrequired, callback, permission, ...)
    end

    return self
end