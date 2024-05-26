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
            local image = item .. '.png'

            if QB_CORE then
                image = self:getQBImage(item)
            end

            if data.client and data.client.image then
                image = string.match(data.client.image, "([^/]+%.[%w]+)")
            end

            local name = item:lower()
            tmp[name] = data
            tmp[name].name = name
            tmp[name].isUnique = data.stack == false
            tmp[name].isWeapon = data.weapon == true
            tmp[name].image = image
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