if QS_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf
    local qs_inventory = exports['qs-inventory']

    local fallbackGetItemCount = eCore.getItemCount

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param playerData any
    --- @return any result
    function eCore:getPlayerMaxWeight(playerData)
        return Config.maxInventoryWeight
    end

--- Client-side: use qs export when available, otherwise fallback to bridge/global aggregator.
    function eCore:getItemCount(playerData, itemName)
        if type(itemName) ~= 'string' then return 0 end
        if type(playerData) == 'table' and hf.isValidPlayerSource(playerData.source) then
            local okCall, n = pcall(function()
                return qs_inventory:GetItemTotalAmount(playerData.source, itemName)
            end)
            if okCall and type(n) == 'number' and n == n then
                return n
            end
        end
        return fallbackGetItemCount(self, playerData, itemName)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param playerData any
    --- @param itemName any
    --- @param count number
    --- @return any result
    function eCore:hasItem(playerData, itemName, count)
        return self:getItemCount(playerData, itemName) >= (count or 1)
    end
end
