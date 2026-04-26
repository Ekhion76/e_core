if QS_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf
    local qs_inventory = exports['qs-inventory']

    --- It returns the entire registered item list, unified and filtering out unnecessary information
    ---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
    function eCore:getRegisteredItems()
        return self:convertItems(qs_inventory:GetItemList())
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
            hf.itemConvertDiagStartRun('qs.convertItems', rowCount)
        end

        for item, data in pairs(items) do
            local okConv, errConv = pcall(function()
                if type(data) ~= 'table' then
                    if hf.itemConvertDiagRecord then
                        hf.itemConvertDiagRecord({
                            source = 'qs.convertItems',
                            code = 'invalid_item_row',
                            severity = 'warning',
                            item = tostring(item),
                            reason = ('Expected table row, got %s'):format(type(data)),
                        })
                    end
                    return
                end
                local itemKey = type(item) == 'string' and item or tostring(item)
                local image = itemKey .. '.png'

                if QB_CORE then
                    image = self:getQBImage(itemKey)
                end

                local name = itemKey:lower()
                if tmp[name] ~= nil and hf.itemConvertDiagRecord then
                    hf.itemConvertDiagRecord({
                        source = 'qs.convertItems',
                        code = 'duplicate_lower_key',
                        severity = 'warning',
                        item = name,
                        reason = ('Duplicate lower-case key during convert (raw key=%s)'):format(tostring(item)),
                    })
                end
                tmp[name] = data
                tmp[name].isUnique = data.unique == true
                tmp[name].isWeapon = not data.useable and string.find(name, "^weapon_") ~= nil
                tmp[name].image = image
                hf.normalizeRegisteredItemDef(name, tmp[name], { source = 'qs.convertItems' })
            end)
            if not okConv and cLog then
                cLog('eCore:convertItems(qs_inventory)', { err = tostring(errConv), item = tostring(item) }, 1)
                if hf.itemConvertDiagRecord then
                    hf.itemConvertDiagRecord({
                        source = 'qs.convertItems',
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

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param name string
    --- @return any result
    function eCore:getQBImage(name)
        if QBCore and QBCore.Shared.Items[name] then
            return QBCore.Shared.Items[name].image
        end

        return name .. '.png'
    end
end
