if not AVP_GRID_INVENTORY then return end

-- these functions override the bridge/global/ and bridge/esx/qb/ functions
-- if you want to rewrite any function, copy it here and modify it here

local hf = hf

--- AVP may return custom reason strings; if not an `eCoreErr` value,
--- normalize to `unknown_error` and log via `cLog`.
local function asEcoreInventoryReason(reason)
    if type(reason) ~= 'string' or reason == '' then
        return eCoreErr.unknown_error
    end
    for _, v in pairs(eCoreErr) do
        if v == reason then
            return reason
        end
    end
    cLog('avp_grid_inventory: reason is not a valid eCoreErr string', { reason = reason }, 2)
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
        return false, eCoreErr.unknown_error
    end
    if type(item) ~= 'string' or not hf.isPopulatedString(item) then
        return false, eCoreErr.invalid_item_data
    end
    local c = tonumber(count)
    if not c or c < 1 or c ~= c then
        return false, eCoreErr.invalid_item_data
    end

    cLog('STANDALONE eCore:removeItem', item, 4)
    local okCall, okRm, reason = pcall(function()
        return exports['avp_grid_inventory']:RemoveItemBy(xPlayer.source, c, item)
    end)
    if not okCall then
        cLog('eCore:removeItem:avp', { err = tostring(okRm) }, 1)
        return false, eCoreErr.unknown_error
    end
    if not okRm then
        return false, asEcoreInventoryReason(reason)
    end
    return true
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @param items table
--- @return any result
function eCore:removeItems(xPlayer, items)
    if not xPlayer or not hf.isValidPlayerSource(xPlayer.source) then
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
        cLog('STANDALONE eCore:removeItems', item, 4)

        local okCall, okRm, reason = pcall(function()
            return exports['avp_grid_inventory']:RemoveItemBy(xPlayer.source, item.amount, { name = item.name })
        end)
        if not okCall then
            cLog('eCore:removeItems:avp', { item = item.name, err = tostring(okRm) }, 1)
            return false, eCoreErr.unknown_error
        end
        if not okRm then
            return false, asEcoreInventoryReason(reason)
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
    if type(item) ~= 'string' or not hf.isPopulatedString(item) then
        return false, eCoreErr.invalid_item_data
    end
    local c = tonumber(count)
    if not c or c < 1 or c ~= c then
        return false, eCoreErr.invalid_item_data
    end

    cLog('STANDALONE eCore:addItem', { item = item, count = count, slot = slot, metadata = metadata }, 4)
    local okCall, okAdd, reason = pcall(function()
        return exports['avp_grid_inventory']:AddItem(xPlayer.source, item, c, metadata)
    end)
    if not okCall then
        cLog('eCore:addItem:avp', { err = tostring(okAdd) }, 1)
        return false, eCoreErr.unknown_error
    end
    if not okAdd then
        return false, asEcoreInventoryReason(reason)
    end
    return true
end

--- AVP does not provide detailed reason here (boolean only).
--- Map the "cannot carry" branch to `too_heavy` (same as client override).
function eCore:canSwapItems(swappingItems, itemData, playerData)
    if swappingItems ~= nil and type(swappingItems) ~= 'table' then
        return false, eCoreErr.invalid_item_data
    end
    return self:canCarryItem(itemData, playerData)
end

---Returns true or false (and reason) depending if the inventory can carry the specified item
---@param itemData table {name: string, amount: number, metadata: table}
---@return boolean, string
function eCore:canCarryItem(itemData, playerData)
    if type(itemData) ~= 'table' then
        return false, eCoreErr.invalid_item_data
    end
    if not hf.isPopulatedString(itemData.name) then
        return false, eCoreErr.invalid_item_data
    end
    local amt = tonumber(itemData.amount)
    if not amt or amt < 1 or amt ~= amt then
        return false, eCoreErr.invalid_item_data
    end
    if type(playerData) ~= 'table' or not hf.isValidPlayerSource(playerData.source) then
        return false, eCoreErr.unknown_error
    end

    local okCall, can = pcall(function()
        return exports['avp_grid_inventory']:CanCarryItem(playerData.source, itemData.name, itemData.amount) == true
    end)
    if not okCall then
        cLog('eCore:canCarryItem:avp', { err = tostring(can) }, 1)
        return false, eCoreErr.unknown_error
    end
    if can then
        return true
    end
    return false, eCoreErr.too_heavy
end

eCore:createCallback('e_core:getCanSwap', function(source, cb, swappingItems, itemData)
    if not hf.isValidPlayerSource(source) then
        cb(false)
        return
    end
    if swappingItems ~= nil and type(swappingItems) ~= 'table' then
        cb(false)
        return
    end
    if type(itemData) ~= 'table' or not hf.isPopulatedString(itemData.name) then
        cb(false)
        return
    end
    local amt = tonumber(itemData.amount)
    if not amt or amt < 1 or amt ~= amt then
        cb(false)
        return
    end
    local okCall, can = pcall(function()
        return exports['avp_grid_inventory']:CanCarryItem(source, itemData.name, itemData.amount) == true
    end)
    if not okCall then
        cLog('e_core:getCanSwap:avp', { err = tostring(can) }, 1)
        cb(false)
        return
    end
    cb(can)
end)

eCore:createCallback('e_core:getCanCarry', function(source, cb, itemData)
    if not hf.isValidPlayerSource(source) then
        cb(false)
        return
    end
    if type(itemData) ~= 'table' or not hf.isPopulatedString(itemData.name) then
        cb(false)
        return
    end
    local amt = tonumber(itemData.amount)
    if not amt or amt < 1 or amt ~= amt then
        cb(false)
        return
    end
    local okCall, can = pcall(function()
        return exports['avp_grid_inventory']:CanCarryItem(source, itemData.name, itemData.amount) == true
    end)
    if not okCall then
        cLog('e_core:getCanCarry:avp', { err = tostring(can) }, 1)
        cb(false)
        return
    end
    cb(can)
end)
