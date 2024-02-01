if OX_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf
    local ox_inventory = exports.ox_inventory

    function eCore:getPlayerMaxWeight(playerData)

        return Config.maxInventoryWeight
        --return ox_inventory:GetPlayerMaxWeight() -- error: no such export. Maybe version problem
    end
end