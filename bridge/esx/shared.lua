if ESX_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- copy it to the standalone/ directory and modify it there!
    -- this way, your changes will not be lost in future e_core updates

    local hf = hf

    function eCore:convertPlayer(playerData, newJob)

        if playerData then

            playerData.job = newJob or playerData.job

            if playerData.firstName then

                playerData.charName = ('%s %s'):format(playerData.firstName, playerData.lastName)
            else

                playerData.charName = playerData.name
            end

            playerData.position = playerData.coords
        end

        return playerData
    end

    ---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
    function eCore:convertItems(items)

        if not hf.isPopulatedTable(items) then

            return items
        end

        local tmp = {}

        for item, data in pairs(items) do

            item = type(item) == 'string' and item or data.name
            local name = item:lower()
            tmp[name] = data
            tmp[name].name = name
            tmp[name].isUnique = false
            tmp[name].isWeapon = false
            tmp[name].image = item .. '.png'
        end

        return tmp
    end
end