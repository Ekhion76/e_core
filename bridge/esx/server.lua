function ESXBridge()

    -- ESX.Items[v.name] = {label = v.label, weight = v.weight, rare = v.rare, canRemove = v.can_remove}

    local self = {}
    local ox_inventory = false

    if OX_INVENTORY then

        ox_inventory = exports.ox_inventory
    end

    function self.createCallback(name, callback)

        ESX.RegisterServerCallback(name, callback)
    end

    function self.createUsableItem(item, cb)

        ESX.RegisterUsableItem(item, cb)
    end

    function self.sendMessage(source, message, mType, mSec)

        TriggerClientEvent("ESX:Notify", source, mType, mSec, message)
    end

    function self.drawText(source, message, position, mType)

        TriggerClientEvent("ESX:TextUI", source, message, mType)
    end

    function self.hideText()

        TriggerClientEvent("ESX:HideUI", source)
    end

    function self.addMoney(xPlayer, account, amount, reason)

        if type(xPlayer) == 'number' then

            xPlayer = ESX.GetPlayerFromId(xPlayer)
        end

        if xPlayer then

            xPlayer.addAccountMoney(account, amount, reason)
            return true
        end

        return false
    end

    function self.removeMoney(xPlayer, accountName, amount, reason)

        if type(xPlayer) == 'number' then

            xPlayer = ESX.GetPlayerFromId(xPlayer)
        end

        if xPlayer then

            xPlayer.removeAccountMoney(accountName, amount, reason)
            return true -- no removeAccountMoney return :(
        end

        return false
    end

    function self.getAccounts(xPlayer, account)

        for i = 1, #(xPlayer.accounts) do

            if xPlayer.accounts[i].name == account then

                return xPlayer.accounts[i].money
            end
        end

        return 0
    end

    --- It returns the entire registered item list, unified and filtering out unnecessary information
    ---@return {label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string}
    function self.getRegisteredItems()

        local items = {}

        if OX_INVENTORY then

            items = FUNCTIONS.convertOxItems(ox_inventory:Items())
        end

        return items
    end

    ------------------------------------------------------------------------
    --- INVENTORY
    ------------------------------------------------------------------------

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

    function self.getInventory(xPlayer)

        return xPlayer.getInventory()
    end

    function self.setInventory(xPlayer, items)


    end

    function self.getInventoryWeight(xPlayer)

        if OX_INVENTORY then

            return xPlayer.weight
        else

            return FUNCTIONS.getInventoryWeight(xPlayer)
        end
    end

    function self.addItem(xPlayer, item, count, slot, metadata)

        if OX_INVENTORY then

            local success, response = ox_inventory:AddItem(xPlayer.source, item, count, metadata)

            if not success then

                return false, response
            end
        else

            if not xPlayer.addItem(item, count, metadata, slot) then

                return false, 'inventory_full'
            end
        end

        return true
    end

    function self.removeItem(xPlayer, item, count, metadata, slot)

        if OX_INVENTORY then

            return ox_inventory:RemoveItem(xPlayer.source, item, count)
        end

        return xPlayer.removeInventoryItem(item, count, metadata, slot)
    end

    function self.removeItems(xPlayer, itemList)

        if OX_INVENTORY then

            return FUNCTIONS.removeOxItems(xPlayer.source, itemList)
        end

        return FUNCTIONS.removeItems(xPlayer, itemList)
    end

    function self.getPlayer(playerId)

        return FUNCTIONS.convertPlayer(ESX.GetPlayerFromId(playerId))
    end

    ------------------------------------------------------------------------
    --- COMMANDS
    ------------------------------------------------------------------------

    function self.addCommands(name, help, arguments, argsrequired, callback, permission, ...)

        ESX.RegisterCommand(name, permission, callback, false, arguments)
    end

    return self
end