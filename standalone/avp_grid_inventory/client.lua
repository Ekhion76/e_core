if AVP_GRID_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf

    function eCore:canSwapItems(swappingItems, itemData, playerData)

        -- only weight check
        return eCore:canCarryItem(itemData, playerData)
    end

    ---Returns true or false (and reason) depending if the inventory can carry the specified item
    ---@param itemData table {name: string, amount: number, metadata: table}
    ---@return boolean, string
    function eCore:canCarryItem(itemData, playerData)

        -- only weight check
        --local inventory = self:getInventory(playerData)

        local capacity = Config.maxInventoryWeight - self:getInventoryWeight(playerData)
        local itemWeight = self:getItemWeight(itemData.name, itemData.metadata) * itemData.amount

        cLog('STANDALONE eCore:canCarryItem', { capacity = capacity, itemWeight = itemWeight }, 3)

        if itemWeight > capacity then

            return false, 'too_heavy'
        end

        return true
    end
end