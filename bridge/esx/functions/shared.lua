local hf = hf

function ESXSharedFunctions()

    local self = sharedGlobalFunctions()

    local ox_inventory = false

    if OX_INVENTORY then

        ox_inventory = exports.ox_inventory
    end

    --- It returns the entire registered item list, unified and filtering out unnecessary information
    ---@return {label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string}
    function self.getRegisteredItems()

        local items = {}

        if OX_INVENTORY then

            items = self.convertOxItems(ox_inventory:Items())
        else

            items = {}
        end

        return items
    end

    function self.convertOxItems(items)

        if not hf.isPopulatedTable(items) then

            return items
        end

        for item, data in pairs(items) do

            items[item:lower()] = {
                label = data.label,
                isUnique = data.stack == false,
                isWeapon = data.weapon == true,
                weight = data.weight,
                image = item .. '.png',
                durability = data.durability,
                ammoname = data.ammoname
            }
        end

        return items
    end

    function self.convertPlayer(playerData)

        if playerData then

            if playerData.firstName then

                playerData.charName = ('%s %s'):format(playerData.firstName, playerData.lastName)
            else

                playerData.charName = playerData.name
            end

            playerData.position = playerData.coords
        end

        return playerData
    end

    return self
end