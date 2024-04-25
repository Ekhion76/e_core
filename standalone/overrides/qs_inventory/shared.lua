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
            local image = item .. '.png'

            if QB_CORE then
                image = self:getQBImage(item)
            end

            local name = item:lower()
            tmp[name] = data
            tmp[name].name = name
            tmp[name].isUnique = data.unique == true
            tmp[name].isWeapon = not data.useable and string.find(name, "^weapon_") ~= nil
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