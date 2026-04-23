if OX_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf
    local ox_inventory = exports.ox_inventory

    local fallbackGetInventoryWeight = eCore.getInventoryWeight
    local fallbackGetPlayerMaxWeight = eCore.getPlayerMaxWeight

    local function oxPlayerInventory(xPlayer)
        if not xPlayer or not xPlayer.source then
            return nil
        end
        local ok, inv = pcall(function()
            return ox_inventory:GetInventory(xPlayer.source)
        end)
        if ok and type(inv) == 'table' and type(inv.weight) == 'number' then
            return inv
        end
        return nil
    end

    function eCore:getInventoryWeight(xPlayer)
        local inv = oxPlayerInventory(xPlayer)
        if inv then
            return inv.weight
        end
        return fallbackGetInventoryWeight(self, xPlayer)
    end

    function eCore:getPlayerMaxWeight(xPlayer)
        local inv = oxPlayerInventory(xPlayer)
        if inv and type(inv.maxWeight) == 'number' and inv.maxWeight > 0 then
            return inv.maxWeight
        end
        return fallbackGetPlayerMaxWeight(self, xPlayer)
    end

    function eCore:removeItem(xPlayer, item, count, metadata, slot)
        return ox_inventory:RemoveItem(xPlayer.source, item, count)
    end

    function eCore:removeItems(xPlayer, items)
        if not hf.isPopulatedTable(items) then
            return false, eCoreErr.there_are_no_items_to_remove
        end

        for _, item in pairs(items) do
            if not ox_inventory:RemoveItem(xPlayer.source, item.name, item.amount) then
                return false, eCoreErr.unknown_error
            end
        end

        return true, eCoreErr.ok
    end

    function eCore:addItem(xPlayer, item, count, slot, metadata)
        local success, response = ox_inventory:AddItem(xPlayer.source, item, count, metadata, slot)
        if not success then
            return false, response
        end

        return true
    end
end