if QS_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf
    local qs_inventory = exports['qs-inventory']

    function eCore:removeItem(xPlayer, item, count, metadata, slot)
        return qs_inventory:RemoveItem(xPlayer.source, item, count)
    end

    function eCore:removeItems(xPlayer, items)
        if not hf.isPopulatedTable(items) then
            return false, eCoreErr.there_are_no_items_to_remove
        end

        for _, item in pairs(items) do
            if not qs_inventory:RemoveItem(xPlayer.source, item.name, item.amount) then
                return false, eCoreErr.unknown_error
            end
        end

        return true, eCoreErr.ok
    end

    function eCore:addItem(xPlayer, item, count, slot, metadata)
        local success, response = qs_inventory:AddItem(xPlayer.source, item, count, nil, metadata)
        if not success then
            return false, response
        end

        return true
    end

    function eCore:getPlayerMaxWeight(xPlayer)
        return Config.maxInventoryWeight
    end
end