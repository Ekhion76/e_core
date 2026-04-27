if not AVP_GRID_INVENTORY then return end

-- these functions override the bridge/global/ and bridge/esx/qb/ functions
-- if you want to rewrite any function, copy it here and modify it here

local hf = hf

--- It returns the entire registered item list, unified and filtering out unnecessary information
---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
function eCore:getRegisteredItems()
    hf.itemConvertWarnCustomConvertItems('avp.override')
    return hf.convertItemsWithProfile(exports["avp_grid_inventory"]:GetRegisteredItems(), 'avp', {
        sourceTag = 'avp.convertItems',
    })
end

--- Determines the weight of items in the inventory
--- @param playerData table
--- @return number total weight in gramm
function eCore:getInventoryWeight(playerData)
    return exports["avp_grid_inventory"]:GetWeight(playerData.source)
end

--- @return table {name|item: string, amount|count|quantity: number} set field names in eCore:getSettings()
function eCore:getInventory(xPlayer)
    return exports["avp_grid_inventory"]:GetInventoryItems(xPlayer.source)
end

--- `GetInventoryItems` + global `getAmountOfItems` keeps the same contract
--- as the bridge `shared` implementation.
function eCore:getItemCount(playerData, itemName)
    if type(itemName) ~= 'string' then return 0 end
    local amounts = self:getAmountOfItems(self:getInventory(playerData))
    return amounts[itemName:lower()] or 0
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param playerData any
--- @param itemName any
--- @param count number
--- @return any result
function eCore:hasItem(playerData, itemName, count)
    return self:getItemCount(playerData, itemName) >= (count or 1)
end
