if QB_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- use `overrides/...` or `src/config/`; do not edit bridge files in place.
    -- this way, your changes will not be lost in future e_core updates

    local hf = lib.require('src/imports/sdk/helper_base/shared')

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param item table
    --- @param cb function
    --- @return any result
    function eCore:createUsableItem(item, cb)
        QBCore.Functions.CreateUseableItem(item, cb)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param source number
    --- @param message any
    --- @param mType any
    --- @param mSec any
    --- @return any result
    function eCore:sendMessage(source, message, mType, mSec)
        if mType == 'info' then mType = 'primary' end
        TriggerClientEvent('QBCore:Notify', source, message, mType, mSec) -- CHANGE ME
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param source number
    --- @param message any
    --- @param position any
    --- @param mType any
    --- @return any result
    function eCore:drawText(source, message, position, mType)
        if mType == 'info' then mType = 'primary' end
        TriggerClientEvent(('%s:client:DrawText'):format(ecore_framework_resource_qb()), source, message, position) -- CHANGE ME if event namespace differs
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param source number
    --- @return any result
    function eCore:hideText(source)
        TriggerClientEvent(('%s:client:HideText'):format(ecore_framework_resource_qb()), source) -- CHANGE ME if event namespace differs
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param account any
    --- @param amount number
    --- @param reason string
    --- @return any result
    function eCore:addMoney(xPlayer, account, amount, reason)
        if type(xPlayer) == 'number' then
            xPlayer = QBCore.Functions.GetPlayer(xPlayer)
        end

        -- Offline / hibás source esetén `GetPlayer` nil; különben `Functions.AddMoney` runtime error (lásd bridge review).
        if not xPlayer then
            return false, eCoreErr.invalid_player
        end

        local convert = { -- ESX2QB
            money = 'cash',
            black_money = 'crypto',
        }

        account = convert[account] and convert[account] or account
        return xPlayer.Functions.AddMoney(account, amount, reason)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param account any
    --- @param amount number
    --- @param reason string
    --- @return any result
    function eCore:removeMoney(xPlayer, account, amount, reason)
        if type(xPlayer) == 'number' then
            xPlayer = QBCore.Functions.GetPlayer(xPlayer)
        end

        -- Ugyanaz a szerződés, mint `addMoney`: nil játékosnél ne hívjunk `Functions.RemoveMoney`-t (runtime error).
        if not xPlayer then
            return false, eCoreErr.invalid_player
        end

        local convert = { -- ESX2QB
            money = 'cash',
            black_money = 'crypto',
        }

        account = convert[account] and convert[account] or account
        return xPlayer.Functions.RemoveMoney(account, amount, reason)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param account any
    --- @return any result
    function eCore:getAccounts(xPlayer, account)
        if type(xPlayer) == 'number' then
            xPlayer = QBCore.Functions.GetPlayer(xPlayer)
        end

        -- ESX ág `getAccounts`-szel összhang: hiányos játékos = nincs számla egyenleg (0), nem error.
        if not xPlayer or type(xPlayer.money) ~= 'table' then
            return 0
        end

        local convert = { -- ESX2QB
            money = 'cash',
            black_money = 'crypto',
        }

        account = convert[account] and convert[account] or account
        return xPlayer.money[account] or 0
    end

    ------------------------------------------------------------------------
    --- INVENTORY
    ------------------------------------------------------------------------

    function eCore:getInventory(xPlayer)
        if type(xPlayer) == 'number' then
            xPlayer = QBCore.Functions.GetPlayer(xPlayer)
        end

        if not xPlayer or type(xPlayer.items) ~= 'table' then
            return {}
        end

        return xPlayer.items
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param item table
    --- @param count number
    --- @param slot number
    --- @param metadata any
    --- @return any result
    function eCore:addItem(xPlayer, item, count, slot, metadata)
        if type(xPlayer) == 'number' then
            xPlayer = QBCore.Functions.GetPlayer(xPlayer)
        end

        if not xPlayer then
            return false, eCoreErr.invalid_player
        end

        if not xPlayer.Functions.AddItem(item, count, slot, metadata) then
            return false, eCoreErr.inventory_full
        end

        return true
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @return any result
    function eCore:getPlayerMaxWeight(xPlayer)
        return Config.maxInventoryWeight
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param itemName any
    --- @param count number
    --- @param metadata any
    --- @param slot number
    --- @return any result
    function eCore:removeItem(xPlayer, itemName, count, metadata, slot)
        if type(xPlayer) == 'number' then
            xPlayer = QBCore.Functions.GetPlayer(xPlayer)
        end

        if not xPlayer then
            return false, eCoreErr.invalid_player
        end

        count = tonumber(count)
        if not hf.hasContent(itemName) or not count or count < 1 then
            return false, eCoreErr.no_items_to_remove
        end

        if count == 1 then
            return xPlayer.Functions.RemoveItem(itemName, count)
        end

        local itemLowerName = itemName:lower()
        local inventory = xPlayer.items

        if hf.isEmptyTable(inventory) then
            return false, eCoreErr.inventory_is_empty
        end

        local totalItemsCount = 0

        for _, inventoryItem in pairs(inventory) do
            if inventoryItem.name:lower() == itemLowerName then
                totalItemsCount = totalItemsCount + inventoryItem.amount
            end
        end

        if totalItemsCount < count then
            return false, eCoreErr.not_enough_items
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
        return true, eCoreErr.ok
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param xPlayer table
    --- @param items table
    --- @return any result
    function eCore:removeItems(xPlayer, items)
        if type(xPlayer) == 'number' then
            xPlayer = QBCore.Functions.GetPlayer(xPlayer)
        end

        if not xPlayer then
            return false, eCoreErr.invalid_player
        end

        if not hf.hasEntries(items) then
            return false, eCoreErr.no_items_to_remove
        end

        for _, item in pairs(items) do
            if type(item) ~= 'table' then
                return false, eCoreErr.invalid_item_data
            end

            if not hf.hasContent(item.name) then
                return false, eCoreErr.invalid_item_data
            end

            local amt = tonumber(item.amount)
            if not amt or amt < 1 or amt ~= amt then
                return false, eCoreErr.invalid_item_data
            end
        end

        local count
        local inventory = xPlayer.items

        if hf.isEmptyTable(inventory) then
            return false, eCoreErr.inventory_is_empty
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
                    return false, eCoreErr.not_enough_items
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
        return true, eCoreErr.ok
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param playerId number
    --- @return any result
    function eCore:getPlayer(playerId)
        return eCore:convertPlayer(QBCore.Functions.GetPlayer(playerId))
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
        QBCore.Commands.Add(name, help, arguments, argsrequired, callback, permission, ...)
    end
end
