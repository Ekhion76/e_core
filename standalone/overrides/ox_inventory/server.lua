if OX_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf
    local ox_inventory = exports.ox_inventory

    --- ox / qs stack-specifikus második érték → ha nem `eCoreErr` string, `unknown_error` + `cLog`
    local function asEcoreInventoryReason(reason)
        if type(reason) ~= 'string' or reason == '' then
            return eCoreErr.unknown_error
        end
        for _, v in pairs(eCoreErr) do
            if v == reason then
                return reason
            end
        end
        cLog('ox_inventory: nem eCoreErr ok-string', { reason = reason }, 2)
        return eCoreErr.unknown_error
    end

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
        if not xPlayer or not hf.isValidPlayerSource(xPlayer.source) then
            return false, eCoreErr.unknown_error
        end
        local okCall, rmRes = pcall(function()
            return ox_inventory:RemoveItem(xPlayer.source, item, count)
        end)
        if not okCall then
            cLog('eCore:removeItem:ox', { err = tostring(rmRes) }, 1)
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
                return ox_inventory:RemoveItem(xPlayer.source, item.name, item.amount)
            end)
            if not okCall then
                cLog('eCore:removeItems:ox', { item = item.name, err = tostring(rmRes) }, 1)
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
            return ox_inventory:AddItem(xPlayer.source, item, count, metadata, slot)
        end)
        if not okCall then
            cLog('eCore:addItem:ox', { err = tostring(success) }, 1)
            return false, eCoreErr.unknown_error
        end
        if not success then
            return false, asEcoreInventoryReason(response)
        end

        return true
    end
end