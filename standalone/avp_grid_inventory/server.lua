if AVP_GRID_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf

    function eCore:removeItem(xPlayer, item, count, metadata, slot)

        cLog('STANDALONE eCore:removeItem', item, 3)
        return exports["avp_grid_inventory"]:RemoveItemBy(xPlayer.source, count, item)
    end

    function eCore:removeItems(xPlayer, items)

        if not hf.isPopulatedTable(items) then
            return false, 'there are no items to remove'
        end

        for _, item in pairs(items) do

            cLog('STANDALONE eCore:removeItems', item, 3)

            local success, reason = exports["avp_grid_inventory"]:RemoveItemBy(xPlayer.source, item.amount, { name = item.name })

            if not success then

                return false, reason
            end
        end

        return true, 'ok'
    end

    function eCore:addItem(xPlayer, item, count, slot, metadata)

        cLog('STANDALONE eCore:addItem', { item = item, count = count, slot = slot, metadata = metadata }, 3)
        return exports["avp_grid_inventory"]:AddItem(xPlayer.source, item, count, metadata)
    end

    function eCore:canSwapItems(swappingItems, itemData, playerData)

        return exports["avp_grid_inventory"]:CanCarryItem(playerData.source, itemData.name, itemData.amount)
    end

    ---Returns true or false (and reason) depending if the inventory can carry the specified item
    ---@param itemData table {name: string, amount: number, metadata: table}
    ---@return boolean, string
    function eCore:canCarryItem(itemData, playerData)

        return exports["avp_grid_inventory"]:CanCarryItem(playerData.source, itemData.name, itemData.amount)
    end
end