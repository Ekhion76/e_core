if QS_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf
    local qs_inventory = exports['qs-inventory']

    local function asEcoreInventoryReason(reason)
        if type(reason) ~= 'string' or reason == '' then
            return eCoreErr.unknown_error
        end
        for _, v in pairs(eCoreErr) do
            if v == reason then
                return reason
            end
        end
        cLog('qs-inventory: nem eCoreErr ok-string', { reason = reason }, 2)
        return eCoreErr.unknown_error
    end

    function eCore:removeItem(xPlayer, item, count, metadata, slot)
        if not xPlayer or not hf.isValidPlayerSource(xPlayer.source) then
            return false, eCoreErr.unknown_error
        end
        local okCall, rmRes = pcall(function()
            return qs_inventory:RemoveItem(xPlayer.source, item, count)
        end)
        if not okCall then
            cLog('eCore:removeItem:qs', { err = tostring(rmRes) }, 1)
            return false, eCoreErr.unknown_error
        end
        if not rmRes then
            return false, eCoreErr.unknown_error
        end
        return true
    end

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

        for _, item in pairs(items) do
            local okCall, rmRes = pcall(function()
                return qs_inventory:RemoveItem(xPlayer.source, item.name, item.amount)
            end)
            if not okCall then
                cLog('eCore:removeItems:qs', { item = item.name, err = tostring(rmRes) }, 1)
                return false, eCoreErr.unknown_error
            end
            if not rmRes then
                return false, eCoreErr.unknown_error
            end
        end

        return true, eCoreErr.ok
    end

    function eCore:addItem(xPlayer, item, count, slot, metadata)
        if not xPlayer or not hf.isValidPlayerSource(xPlayer.source) then
            return false, eCoreErr.unknown_error
        end
        local okCall, success, response = pcall(function()
            return qs_inventory:AddItem(xPlayer.source, item, count, nil, metadata)
        end)
        if not okCall then
            cLog('eCore:addItem:qs', { err = tostring(success) }, 1)
            return false, eCoreErr.unknown_error
        end
        if not success then
            return false, asEcoreInventoryReason(response)
        end

        return true
    end

    function eCore:getPlayerMaxWeight(xPlayer)
        return Config.maxInventoryWeight
    end
end