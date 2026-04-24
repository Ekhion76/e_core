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

                if type(data.client) == 'table' and type(data.client.image) == 'string' then
                    local m = string.match(data.client.image, "([^/]+%.[%w]+)")
                    if m then
                        image = m
                    end
                end

                local name = itemKey:lower()
                tmp[name] = data
                tmp[name].isUnique = data.stack == false
                tmp[name].isWeapon = data.weapon == true
                tmp[name].image = image
                hf.normalizeRegisteredItemDef(name, tmp[name])
            end)
            if not okConv and cLog then
                cLog('eCore:convertItems(ox_inventory)', { err = tostring(errConv), item = tostring(item) }, 1)
            end
        end

        return tmp
    end

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
