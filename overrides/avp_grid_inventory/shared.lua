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
        local rowCount = 0
        if hf.itemConvertDiagStartRun then
            for _ in pairs(items) do rowCount = rowCount + 1 end
            hf.itemConvertDiagStartRun('avp.convertItems', rowCount)
        end

        for item, data in pairs(items) do
            local okConv, errConv = pcall(function()
                if type(data) ~= 'table' then
                    if hf.itemConvertDiagRecord then
                        hf.itemConvertDiagRecord({
                            source = 'avp.convertItems',
                            code = 'invalid_item_row',
                            severity = 'warning',
                            item = tostring(item),
                            reason = ('Expected table row, got %s'):format(type(data)),
                        })
                    end
                    return
                end
                local itemKey = type(item) == 'string' and item or tostring(item)
                local name = itemKey:lower()
                if tmp[name] ~= nil and hf.itemConvertDiagRecord then
                    hf.itemConvertDiagRecord({
                        source = 'avp.convertItems',
                        code = 'duplicate_lower_key',
                        severity = 'warning',
                        item = name,
                        reason = ('Duplicate lower-case key during convert (raw key=%s)'):format(tostring(item)),
                    })
                end
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
                hf.normalizeRegisteredItemDef(name, tmp[name], { source = 'avp.convertItems' })
            end)
            if not okConv and cLog then
                cLog('eCore:convertItems(avp_grid_inventory)', { err = tostring(errConv), item = tostring(item) }, 1)
                if hf.itemConvertDiagRecord then
                    hf.itemConvertDiagRecord({
                        source = 'avp.convertItems',
                        code = 'convert_row_error',
                        severity = 'error',
                        item = tostring(item),
                        reason = tostring(errConv),
                    })
                end
            end
        end
        if hf.itemConvertDiagFinishRun then
            hf.itemConvertDiagFinishRun()
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

--- `GetInventoryItems` + global `getAmountOfItems` keeps the same contract
--- as the bridge `shared` implementation.
    function eCore:getItemCount(playerData, itemName)
        if type(itemName) ~= 'string' then return 0 end
        local amounts = self:getAmountOfItems(self:getInventory(playerData))
        return amounts[itemName:lower()] or 0
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
