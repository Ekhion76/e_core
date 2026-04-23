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

        for item, data in pairs(items) do
            local okConv, errConv = pcall(function()
                if type(data) ~= 'table' then
                    return
                end
                local itemKey = type(item) == 'string' and item or tostring(item)
                local image = itemKey .. '.png'

                if QB_CORE then
                    image = self:getQBImage(itemKey)
                end

                local name = itemKey:lower()
                local allowW, skipW = hf.itemDefinitionWeightGate(data)
                if not allowW then
                    if cLog then
                        cLog('eCore:convertItems:skip', { framework = 'qs_inventory', item = name, reason = skipW }, 1)
                    end
                    return
                end
                tmp[name] = data
                tmp[name].isUnique = data.unique == true
                tmp[name].isWeapon = not data.useable and string.find(name, "^weapon_") ~= nil
                tmp[name].image = image
                hf.normalizeRegisteredItemDef(name, tmp[name])
            end)
            if not okConv and cLog then
                cLog('eCore:convertItems(qs_inventory)', { err = tostring(errConv), item = tostring(item) }, 1)
            end
        end

        return tmp
    end

    function eCore:getQBImage(name)
        if QBCore and QBCore.Shared.Items[name] then
            return QBCore.Shared.Items[name].image
        end

        return name .. '.png'
    end
end