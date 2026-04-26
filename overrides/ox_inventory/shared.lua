if OX_INVENTORY then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    local hf = hf
    local ox_inventory = exports.ox_inventory

    --- It returns the entire registered item list, unified and filtering out unnecessary information
    ---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
    function eCore:getRegisteredItems()
        return self:convertItems(ox_inventory:Items())
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
            hf.itemConvertDiagStartRun('ox.convertItems', rowCount)
        end

        for item, data in pairs(items) do
            local okConv, errConv = pcall(function()
                if type(data) ~= 'table' then
                    if hf.itemConvertDiagRecord then
                        hf.itemConvertDiagRecord({
                            source = 'ox.convertItems',
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

                if type(data.client) == 'table' and type(data.client.image) == 'string' then
                    local m = string.match(data.client.image, "([^/]+%.[%w]+)")
                    if m then
                        image = m
                    end
                end

                local name = itemKey:lower()
                if tmp[name] ~= nil and hf.itemConvertDiagRecord then
                    hf.itemConvertDiagRecord({
                        source = 'ox.convertItems',
                        code = 'duplicate_lower_key',
                        severity = 'warning',
                        item = name,
                        reason = ('Duplicate lower-case key during convert (raw key=%s)'):format(tostring(item)),
                    })
                end
                tmp[name] = data
                tmp[name].isUnique = data.stack == false
                tmp[name].isWeapon = data.weapon == true
                tmp[name].image = image
                hf.normalizeRegisteredItemDef(name, tmp[name], { source = 'ox.convertItems' })
            end)
            if not okConv and cLog then
                cLog('eCore:convertItems(ox_inventory)', { err = tostring(errConv), item = tostring(item) }, 1)
                if hf.itemConvertDiagRecord then
                    hf.itemConvertDiagRecord({
                        source = 'ox.convertItems',
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
        if QBCore and QBCore.Shared and QBCore.Shared.Items and QBCore.Shared.Items[name] then
            local image = QBCore.Shared.Items[name].image
            if image and image:match('^.+%.%w+$') then
                return image
            end
        end

        return name .. '.png'
    end
end
