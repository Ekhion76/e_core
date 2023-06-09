if QB_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- copy it to the standalone/ directory and modify it there!
    -- this way, your changes will not be lost in future e_core updates

    local hf = hf

    ---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
    function eCore:convertItems(items)

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
    function eCore:getRegisteredItems()

        return self:convertItems(QBCore.Shared.Items)
    end

    function eCore:convertPlayer(playerData)

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
end