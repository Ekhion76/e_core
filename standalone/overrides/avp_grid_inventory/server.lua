if AVP_GRID_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf

    function eCore:removeItem(xPlayer, item, count, metadata, slot)

        cLog('STANDALONE eCore:removeItem', item, 4)
        return exports["avp_grid_inventory"]:RemoveItemBy(xPlayer.source, count, item)
    end

    function eCore:removeItems(xPlayer, items)

        if not hf.isPopulatedTable(items) then
            return false, 'there are no items to remove'
        end

        for _, item in pairs(items) do

            cLog('STANDALONE eCore:removeItems', item, 4)

            local success, reason = exports["avp_grid_inventory"]:RemoveItemBy(xPlayer.source, item.amount, { name = item.name })
            if not success then

                return false, reason
            end
        end

        return true, 'ok'
    end

    function eCore:addItem(xPlayer, item, count, slot, metadata)

        cLog('STANDALONE eCore:addItem', { item = item, count = count, slot = slot, metadata = metadata }, 4)
        return exports["avp_grid_inventory"]:AddItem(xPlayer.source, item, count, metadata)
    end

    function eCore:canSwapItems(swappingItems, itemData, playerData)

        --not exists canSwap inventory function
        return exports["avp_grid_inventory"]:CanCarryItem(playerData.source, itemData.name, itemData.amount) == true
    end

    ---Returns true or false (and reason) depending if the inventory can carry the specified item
    ---@param itemData table {name: string, amount: number, metadata: table}
    ---@return boolean, string
    function eCore:canCarryItem(itemData, playerData)

        return exports["avp_grid_inventory"]:CanCarryItem(playerData.source, itemData.name, itemData.amount) == true
    end

    eCore:createCallback('e_core:getCanSwap', function(source, cb, swappingItems, itemData)

        cb(exports["avp_grid_inventory"]:CanCarryItem(source, itemData.name, itemData.amount) == true)
    end)

    eCore:createCallback('e_core:getCanCarry', function(source, cb, itemData)

        cb(exports["avp_grid_inventory"]:CanCarryItem(source, itemData.name, itemData.amount) == true)
    end)
end