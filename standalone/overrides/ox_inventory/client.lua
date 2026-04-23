if OX_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf
    local ox_inventory = exports.ox_inventory

    local fallbackGetPlayerMaxWeight = eCore.getPlayerMaxWeight
    local fallbackGetInventoryWeight = eCore.getInventoryWeight

    --- Kliensen az ox exportjai (ha vannak) adnak élő max / súly értéket; különben bridge + `playerData.weight`.
    function eCore:getPlayerMaxWeight(playerData)
        local ok, mw = pcall(function()
            return ox_inventory:GetPlayerMaxWeight()
        end)
        if ok and type(mw) == 'number' and mw > 0 then
            return mw
        end
        return fallbackGetPlayerMaxWeight(self, playerData)
    end

    function eCore:getInventoryWeight(playerData)
        local ok, w = pcall(function()
            return ox_inventory:GetPlayerWeight()
        end)
        if ok and type(w) == 'number' then
            return w
        end
        return fallbackGetInventoryWeight(self, playerData)
    end
end