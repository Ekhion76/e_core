if AVP_GRID_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf

    --- It returns the entire registered item list, unified and filtering out unnecessary information
    ---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
    function eCore:getRegisteredItems()

        return self:convertItems(exports["avp_grid_inventory"]:GetRegisteredItems())
    end

    ---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
    function eCore:convertItems(items)

        if not hf.isPopulatedTable(items) then

            return items
        end

        local tmp = {}

        for item, data in pairs(items) do
            local okConv, errConv = pcall(function()
                if type(data) ~= 'table' then
                    return
                end
                local itemKey = type(item) == 'string' and item or tostring(item)
                local name = itemKey:lower()
                tmp[name] = {}
                tmp[name].name = name
                tmp[name].label = data.formatName
                tmp[name].isUnique = not data.isStackable
                tmp[name].isWeapon = data.isWeapon == true
                tmp[name].weight = data.weight
                tmp[name].image = itemKey .. '.png'
                tmp[name].ammoname = (type(data.weaponAmmoType) == 'string' and data.weaponAmmoType ~= '')
                    and data.weaponAmmoType
                    or nil
                hf.normalizeRegisteredItemDef(name, tmp[name])
            end)
            if not okConv and cLog then
                cLog('eCore:convertItems(avp_grid_inventory)', { err = tostring(errConv), item = tostring(item) }, 1)
            end
        end

        return tmp
    end

    --- Determines the weight of items in the inventory
    --- @param playerData table
    --- @return number total weight in gramm
    function eCore:getInventoryWeight(playerData)

        return exports["avp_grid_inventory"]:GetWeight(playerData.source)
    end

    --- @return table {name|item: string, amount|count|quantity: number} set field names in eCore:getSettings()
    function eCore:getInventory(xPlayer)

        return exports["avp_grid_inventory"]:GetInventoryItems(xPlayer.source)
    end
end