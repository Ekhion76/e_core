if not OX_INVENTORY then return end

-- these functions override the bridge/global/ and bridge/esx/qb/ functions
-- if you want to rewrite any function, copy it here and modify it here

local hf = hf
local ox_inventory = exports.ox_inventory

--- ox/qs stack-specific second return normalization:
--- if value is not an `eCoreErr` string, map to `unknown_error` and log via `cLog`.
local function asEcoreInventoryReason(reason)
    if type(reason) ~= 'string' or reason == '' then
        return eCoreErr.unknown_error
    end
    for _, v in pairs(eCoreErr) do
        if v == reason then
            return reason
        end
    end
    cLog('ox_inventory: reason is not a valid eCoreErr string', { reason = reason }, 2)
    return eCoreErr.unknown_error
end

local fallbackGetInventoryWeight = eCore.getInventoryWeight
local fallbackGetPlayerMaxWeight = eCore.getPlayerMaxWeight

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @return any result
function eCore:getInventoryWeight(xPlayer)
    local inv = oxPlayerInventory(xPlayer)
    if inv then
        return inv.weight
    end
    return fallbackGetInventoryWeight(self, xPlayer)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @return any result
function eCore:getPlayerMaxWeight(xPlayer)
    local inv = oxPlayerInventory(xPlayer)
    if inv and type(inv.maxWeight) == 'number' and inv.maxWeight > 0 then
        return inv.maxWeight
    end
    return fallbackGetPlayerMaxWeight(self, xPlayer)
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @param items table
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @param item table
--- @param count number
--- @param slot number
--- @param metadata any
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @param itemName any
--- @return any result
function eCore:getItemCount(xPlayer, itemName)
    if type(itemName) ~= 'string' then return 0 end
    local ok, count = pcall(function()
        return ox_inventory:GetItemCount(xPlayer.source, itemName)
    end)
    return (ok and count) or 0
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @param itemName any
--- @param count number
--- @return any result
function eCore:hasItem(xPlayer, itemName, count)
    return eCore:getItemCount(xPlayer, itemName) >= (count or 1)
end
