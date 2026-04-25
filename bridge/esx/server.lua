if ESX_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- copy it to the standalone/ directory and modify it there!
    -- this way, your changes will not be lost in future e_core updates

    local hf = hf

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param item table
    --- @param cb function
    --- @return any result
    function eCore:createUsableItem(item, cb)
        ESX.RegisterUsableItem(item, cb)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param source number
    --- @param message any
    --- @param mType any
    --- @param mSec any
    --- @return any result
    function eCore:sendMessage(source, message, mType, mSec)
        TriggerClientEvent("esx:showNotification", source, message, mType, mSec)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param source number
    --- @param message any
    --- @param position any
    --- @param mType any
    --- @return any result
    function eCore:drawText(source, message, position, mType)
        TriggerClientEvent("ESX:TextUI", source, message, mType)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param source number
    --- @return any result
    function eCore:hideText(source)
        TriggerClientEvent("ESX:HideUI", source)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param account any
    --- @param amount number
    --- @param reason string
    --- @return any result
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

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param accountName any
    --- @param amount number
    --- @param reason string
    --- @return any result
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

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param account any
    --- @return any result
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

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @return any result
    function eCore:getInventoryWeight(xPlayer)
        return xPlayer.getWeight()
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @return any result
    function eCore:getPlayerMaxWeight(xPlayer)
        return Config.maxInventoryWeight
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param item table
    --- @param count number
    --- @param slot number
    --- @param metadata any
    --- @return any result
    function eCore:addItem(xPlayer, item, count, slot, metadata)
        xPlayer.addInventoryItem(item, count)
        return true
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param item table
    --- @param count number
    --- @param metadata any
    --- @param slot number
    --- @return any result
    function eCore:removeItem(xPlayer, item, count, metadata, slot)
        cLog('eCore:removeItem', {item = item, count = count}, 4)
        xPlayer.removeInventoryItem(item, count, metadata, slot)
        return true
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param items table
    --- @return any result
    function eCore:removeItems(xPlayer, items)
        if not xPlayer then
            return false, eCoreErr.unknown_error
        end

        if not hf.isPopulatedTable(items) then
            return false, eCoreErr.there_are_no_items_to_remove
        end

        for _, item in pairs(items) do
            if type(item) ~= 'table' then
                return false, eCoreErr.invalid_item_data
            end

            if not hf.isPopulatedString(item.name) then
                return false, eCoreErr.invalid_item_data
            end

            local amt = tonumber(item.amount)
            if not amt or amt < 1 or amt ~= amt then
                return false, eCoreErr.invalid_item_data
            end
        end

        cLog('eCore:removeItems', items, 4)

        for _, item in pairs(items) do
            local okRm, errRm = pcall(function()
                xPlayer.removeInventoryItem(item.name, item.amount)
            end)

            if not okRm then
                cLog('eCore:removeItems:pcall', { item = item.name, err = tostring(errRm) }, 1)
                return false, eCoreErr.unknown_error
            end
        end

        return true, eCoreErr.ok
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

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param playerId number
    --- @return any result
    function eCore:getPlayer(playerId)
        return self:convertPlayer(ESX.GetPlayerFromId(playerId))
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param playerId number
    --- @param productInfo any
    --- @param event string
    --- @param amount number
    --- @return any result
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
