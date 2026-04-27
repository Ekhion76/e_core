if not QS_INVENTORY then return end

-- these functions override the bridge/global/ and bridge/esx/qb/ functions
-- if you want to rewrite any function, copy it here and modify it here

local hf = hf
local qs_inventory = exports['qs-inventory']

--- Auto-generated annotation. Refine behavior details if needed.
--- @param reason string
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @param item table
--- @param count number
--- @param metadata any
--- @param slot number
--- @return any result
function eCore:removeItem(xPlayer, item, count, metadata, slot)
    if not xPlayer or not hf.isValidPlayerSource(xPlayer.source) then
        return false, eCoreErr.invalid_player
    end
    local okCall, rmRes = pcall(function()
        return qs_inventory:RemoveItem(xPlayer.source, item, count)
    end)
    if not okCall then
        cLog('eCore:removeItem:qs', { err = tostring(rmRes) }, 1)
        return false, eCoreErr.inventory_export_exception
    end
    if not rmRes then
        return false, eCoreErr.inventory_operation_failed
    end
    return true
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @param items table
--- @return any result
function eCore:removeItems(xPlayer, items)
    if not xPlayer or not hf.isValidPlayerSource(xPlayer.source) then
        return false, eCoreErr.invalid_player
    end

    if not hf.hasEntries(items) then
        return false, eCoreErr.there_are_no_items_to_remove
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

    for _, item in pairs(items) do
        local okCall, rmRes = pcall(function()
            return qs_inventory:RemoveItem(xPlayer.source, item.name, item.amount)
        end)
        if not okCall then
            cLog('eCore:removeItems:qs', { item = item.name, err = tostring(rmRes) }, 1)
            return false, eCoreErr.inventory_export_exception
        end
        if not rmRes then
            return false, eCoreErr.inventory_operation_failed
        end
    end

    return true, eCoreErr.ok
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @param item table
--- @param count number
--- @param slot number
--- @param metadata any
--- @return any result
function eCore:addItem(xPlayer, item, count, slot, metadata)
    if not xPlayer or not hf.isValidPlayerSource(xPlayer.source) then
        return false, eCoreErr.invalid_player
    end
    local okCall, success, response = pcall(function()
        return qs_inventory:AddItem(xPlayer.source, item, count, nil, metadata)
    end)
    if not okCall then
        cLog('eCore:addItem:qs', { err = tostring(success) }, 1)
        return false, eCoreErr.inventory_export_exception
    end
    if not success then
        return false, asEcoreInventoryReason(response)
    end

    return true
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @return any result
function eCore:getPlayerMaxWeight(xPlayer)
    return Config.maxInventoryWeight
end

--- qs-inventory: `GetItemTotalAmount(source, itemName)` (Quasar API).
function eCore:getItemCount(xPlayer, itemName)
    if type(itemName) ~= 'string' then return 0 end
    if not xPlayer or not hf.isValidPlayerSource(xPlayer.source) then return 0 end
    local okCall, n = pcall(function()
        return qs_inventory:GetItemTotalAmount(xPlayer.source, itemName)
    end)
    if not okCall then
        cLog('eCore:getItemCount:qs', { err = tostring(n) }, 1)
        return 0
    end
    if type(n) ~= 'number' or n ~= n then return 0 end
    return n
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @param itemName any
--- @param count number
--- @return any result
function eCore:hasItem(xPlayer, itemName, count)
    return eCore:getItemCount(xPlayer, itemName) >= (count or 1)
end
