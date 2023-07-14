if ESX_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- copy it to the standalone/ directory and modify it there!
    -- this way, your changes will not be lost in future e_core updates

    local hf = hf

    function eCore:createCallback(name, callback)

        ESX.RegisterServerCallback(name, callback)
    end

    function eCore:createUsableItem(item, cb)

        ESX.RegisterUsableItem(item, cb)
    end

    function eCore:sendMessage(source, message, mType, mSec)

        TriggerClientEvent("esx:showNotification", source, message, mType, mSec)
    end

    function eCore:drawText(source, message, position, mType)

        TriggerClientEvent("ESX:TextUI", source, message, mType)
    end

    function eCore:hideText(source)

        TriggerClientEvent("ESX:HideUI", source)
    end

    function eCore:addMoney(xPlayer, account, amount, reason)

        if type(xPlayer) == 'number' then

            xPlayer = ESX.GetPlayerFromId(xPlayer)
        end

        if xPlayer then

            xPlayer.addAccountMoney(account, amount, reason)
            return true
        end

        return false
    end

    function eCore:removeMoney(xPlayer, accountName, amount, reason)

        if type(xPlayer) == 'number' then

            xPlayer = ESX.GetPlayerFromId(xPlayer)
        end

        if xPlayer then

            xPlayer.removeAccountMoney(accountName, amount, reason)
            return true -- no removeAccountMoney return :(
        end

        return false
    end

    function eCore:getAccounts(xPlayer, account)

        for i = 1, #(xPlayer.accounts) do

            if xPlayer.accounts[i].name == account then

                return xPlayer.accounts[i].money
            end
        end

        return 0
    end

    ------------------------------------------------------------------------
    --- INVENTORY
    ------------------------------------------------------------------------

    function eCore:getInventory(xPlayer)

        return xPlayer.getInventory()
    end

    function eCore:getInventoryWeight(xPlayer)

        return xPlayer.getWeight()
    end

    function eCore:getPlayerMaxWeight(xPlayer)

        return Config.maxInventoryWeight
    end

    function eCore:addItem(xPlayer, item, count, slot, metadata)

        xPlayer.addInventoryItem(item, count)
        return true
    end

    function eCore:removeItem(xPlayer, item, count, metadata, slot)

        cLog('eCore:removeItem', {item = item, count = count}, 4)
        xPlayer.removeInventoryItem(item, count, metadata, slot)
        return true
    end

    function eCore:removeItems(xPlayer, items)

        if not hf.isPopulatedTable(items) then
            return false, 'there are no items to remove'
        end

        cLog('eCore:removeItems', items, 4)

        for _, item in pairs(items) do

            xPlayer.removeInventoryItem(item.name, item.amount)
        end

        return true, 'ok'
    end

    --- It returns the entire registered item list, unified and filtering out unnecessary information
    ---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
    function eCore:getRegisteredItems()

        if hf.isPopulatedTable(REGISTERED_ITEMS) then

            return REGISTERED_ITEMS
        end

        ESX = exports['es_extended']:getSharedObject()
        return self:convertItems(ESX.Items)
    end

    function eCore:getPlayer(playerId)

        return self:convertPlayer(ESX.GetPlayerFromId(playerId))
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

        ESX.RegisterCommand(name, permission, callback, false, arguments)
    end

end
