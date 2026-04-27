if not OX_INVENTORY then return end

-- these functions override the bridge/global/ and bridge/esx/qb/ functions
-- if you want to rewrite any function, copy it here and modify it here

local hf = hf
local ox_inventory = exports.ox_inventory

local fallbackGetPlayerMaxWeight = eCore.getPlayerMaxWeight
local fallbackGetInventoryWeight = eCore.getInventoryWeight

--- Client-side, ox exports (when available) provide live max/weight values;
--- otherwise fallback to bridge and `playerData.weight`.
function eCore:getPlayerMaxWeight(playerData)
    local ok, mw = pcall(function()
        return ox_inventory:GetPlayerMaxWeight()
    end)
    if ok and type(mw) == 'number' and mw > 0 then
        return mw
    end
    return fallbackGetPlayerMaxWeight(self, playerData)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param playerData any
--- @return any result
function eCore:getInventoryWeight(playerData)
    local ok, w = pcall(function()
        return ox_inventory:GetPlayerWeight()
    end)
    if ok and type(w) == 'number' then
        return w
    end
    return fallbackGetInventoryWeight(self, playerData)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param playerData any
--- @param itemName any
--- @return any result
function eCore:getItemCount(playerData, itemName)
    if type(itemName) ~= 'string' then return 0 end
    local ok, count = pcall(function()
        return ox_inventory:Search('count', itemName)
    end)
    return (ok and count) or 0
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param playerData any
--- @param itemName any
--- @param count number
--- @return any result
function eCore:hasItem(playerData, itemName, count)
    return eCore:getItemCount(playerData, itemName) >= (count or 1)
end
