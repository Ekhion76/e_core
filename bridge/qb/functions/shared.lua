local hf = hf

function QBCoreSharedFunctions()

    local self = sharedGlobalFunctions()

    local ox_inventory = false

    if OX_INVENTORY then

        ox_inventory = exports.ox_inventory
    end

    ---@return table {name, image, label, isUnique, isWeapon, weight}
    function self.convertOxItems(items)

        if not hf.isPopulatedTable(items) then

            return items
        end

        local QBItems = QBCore.Shared.Items
        local QBItem, temp = {}, {}
        local image

        for item, data in pairs(items) do

            local name = item:lower()
            QBItem = QBItems[name]

            if QBItem and QBItem.image then

                image = QBItem.image
            else

                image = item .. '.png'
            end

            temp[name] = data
            temp[name].name = name
            temp[name].image = image
            temp[name].isUnique = data.stack == false
            temp[name].isWeapon = data.weapon == true
        end

        QBItem, items = nil, nil
        return temp
    end

    ---@return table {name, image, label, isUnique, isWeapon, weight}
    function self.convertQbItems(items)

        if not hf.isPopulatedTable(items) then

            return items
        end

        local temp = {}

        for item, data in pairs(items) do

            local name = item:lower()
            temp[name] = data
            temp[name].label = data.label:gsub("'", "\\'")
            temp[name].isUnique = data.unique == true
            temp[name].isWeapon = data.type == 'weapon'
        end

        return temp
    end

    --- It returns the entire registered item list, unified and filtering out unnecessary information
    --- @return {label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string}
    function self.getRegisteredItems()

        local items = {}

        if OX_INVENTORY then

            items = self.convertOxItems(ox_inventory:Items())
        else

            items = self.convertQbItems(QBCore.Shared.Items)
        end

        return items
    end

    function self.convertPlayer(playerData)

        if playerData then

            local functions = nil

            if playerData.PlayerData then

                functions = playerData.Functions
                playerData = playerData.PlayerData
            end

            local job = playerData.job
            local gang = playerData.gang

            job.grade_name = job.grade.name
            job.grade_label = job.grade.name
            job.grade_salary = job.payment
            job.grade = job.grade.level

            gang.grade_name = gang.grade.name
            gang.grade_label = gang.grade.name
            gang.grade_salary = gang.payment
            gang.grade = gang.grade.level

            playerData.identifier = playerData.citizenid
            playerData.charName = ('%s %s'):format(playerData.charinfo.firstname, playerData.charinfo.lastname)
            playerData.job = job
            playerData.gang = gang
            playerData.Functions = functions
        end

        return playerData
    end

    return self
end