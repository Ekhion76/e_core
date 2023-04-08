local hf = hf

function ESXSharedFunctions()

    local self = {}

    local ox_inventory = false

    if OX_INVENTORY then

        ox_inventory = exports.ox_inventory
    end

    ---Determines the weight of items in the inventory
    ---@param playerData table
    ---@return number total weight
    function self.getInventoryWeight(playerData, multiply)

        local weight, count = 0
        local inventory = eCore.getInventory(playerData)

        if not hf.isPopulatedTable(inventory) then
            return 0
        end

        for _, item in pairs(inventory) do

            count = 1

            if multiply then

                count = item.amount or item.count
            end

            weight = weight + item.weight * count
        end

        return weight
    end

    function self.convertOxItems(items)

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