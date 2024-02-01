if AVP_GRID_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf

    function eCore:canSwapItems(swappingItems, itemData, playerData)

        -- only canCarry check
        local p = promise.new()

        eCore:triggerCallback('e_core:getCanSwap', function(result)

            p:resolve(result)
        end, swappingItems, itemData)

        local result = Citizen.Await(p)
        return result, (result and '' or 'too_heavy')
    end

    ---Returns true or false (and reason) depending if the inventory can carry the specified item
    ---@param itemData table {name: string, amount: number, metadata: table}
    ---@return boolean, string
    function eCore:canCarryItem(itemData, playerData)

        local p = promise.new()

        eCore:triggerCallback('e_core:getCanCarry', function(result)

            p:resolve(result)
        end, itemData)

        local result = Citizen.Await(p)
        return result, (result and '' or 'too_heavy')
    end
end