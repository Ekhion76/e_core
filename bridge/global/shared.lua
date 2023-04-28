local hf = hf
-- if you want to rewrite a function, don't do it here!
-- copy it to the standalone/ directory and modify it there!
-- this way, your changes will not be lost in future e_core updates

---Determines the weight of items in the inventory
---@param playerData table
---@return number total weight
function eCore:getInventoryWeight(playerData)

    if playerData.weight then

        return playerData.weight
    end

    local weight, count = 0
    local inventory = self:getInventory(playerData)
    local countIdx, weightIdx = Config.fields.count, Config.fields.weight

    if not hf.isPopulatedTable(inventory) then
        return 0
    end

    for _, item in pairs(inventory) do

        if item[countIdx] > 0 then

            count = Config.totalStackWeight and 1 or item[countIdx]
            weight = weight + item[weightIdx] * count
        end
    end

    return weight
end

---Returns true or false (and reason) depending if the inventory can swapping the specified item
---@param swappingItems table { elements: {name: string, amount: number, metadata: table} } e.g: recipe ingredients
---@param item table {name: string, amount: number, metadata: table}
---@return boolean, string
function eCore:canSwapItems(swappingItems, itemData, playerData)

    local inventory = self:getInventory(playerData)
    local freeSlots = self:countFreeSlots(inventory)
    local requiredSlot = 0
    local capacity = Config.maxInventoryWeight - self:getInventoryWeight(playerData)
    local itemWeight = self:getItemWeight(itemData.name, itemData.metadata) * itemData.amount

    if REGISTERED_ITEMS[itemData.name:lower()].isUnique then

        requiredSlot = itemData.amount
    else

        requiredSlot = self:getFirstSlotByItem(inventory, itemData.name) and 0 or 1
    end

    -- check
    if itemWeight <= capacity and requiredSlot <= freeSlots then

        return true
    end

    -- swapping items calculate
    local amountToRemove, weight = 0, 0
    local nameIdx, countIdx = Config.fields.name, Config.fields.count

    for _, swapItem in pairs(swappingItems) do

        amountToRemove = swapItem.amount
        weight = self:getItemWeight(swapItem.name, swapItem.metadata)

        if REGISTERED_ITEMS[swapItem.name:lower()].isUnique then

            freeSlots = freeSlots + swapItem.amount
            capacity = capacity + (weight * swapItem.amount)
        else

            for _, item in pairs(inventory) do

                if item[nameIdx]:lower() == swapItem.name:lower() and item[countIdx] > 0 then

                    if item[countIdx] >= amountToRemove then

                        item[countIdx] = item[countIdx] - amountToRemove
                        capacity = capacity + (weight * amountToRemove)
                        amountToRemove = 0

                    elseif item[countIdx] < amountToRemove then

                        amountToRemove = amountToRemove - item[countIdx]
                        capacity = capacity + (weight * item[countIdx])
                        item[countIdx] = 0
                    end

                    if item[countIdx] < 1 then

                        freeSlots = freeSlots + 1
                    end

                    if amountToRemove == 0 then

                        break
                    end
                end
            end
        end
    end

    -- check
    if itemWeight > capacity then

        return false, 'too_heavy'
    end

    if requiredSlot > freeSlots then

        return false, 'not_enough_space'
    end

    return true
end

---Returns true or false (and reason) depending if the inventory can carry the specified item
---@param itemData table {name: string, amount: number, metadata: table}
---@return boolean, string
function eCore:canCarryItem(itemData, playerData)

    local inventory = self:getInventory(playerData)
    local requiredSlot = 0

    local capacity = Config.maxInventoryWeight - self:getInventoryWeight(playerData)
    local itemWeight = self:getItemWeight(itemData.name, itemData.metadata) * itemData.amount

    if itemWeight > capacity then

        return false, 'too_heavy'
    end

    if REGISTERED_ITEMS[itemData.name:lower()].isUnique then

        requiredSlot = itemData.amount
    else

        requiredSlot = self:getFirstSlotByItem(inventory, itemData.name) and 0 or 1
    end

    if requiredSlot == 0 then

        return true
    end

    if requiredSlot > self:countFreeSlots(inventory) then

        return false, 'not_enough_space'
    end

    return true
end

---Determines the number of free slots
---@param inventory table
---@return number number of free slots
function eCore:countFreeSlots(inventory)

    local free = Config.maxInventorySlots
    local countIdx = Config.fields.count

    for _, item in pairs(inventory) do

        if item[countIdx] > 0 then

            free = free - 1
        end
    end

    return free < 0 and 0 or free
end

function eCore:getItemWeight(itemName, metadata)

    local item = REGISTERED_ITEMS[itemName:lower()]

    if not item then

        return 0
    end

    local weightIdx = Config.fields.weight
    local weight = item[weightIdx]

    if hf.isPopulatedTable(metadata) then

        -- AMMO
        if item.ammoname and metadata.ammo then

            local ammoWeight = 0

            if REGISTERED_ITEMS[item.ammoname] then

                ammoWeight = REGISTERED_ITEMS[item.ammoname][weightIdx] or 0
            end

            if ammoWeight and ammoWeight > 0 then

                weight = weight + ammoWeight * metadata.ammo
            end
        end

        -- COMPONENTS
        if hf.isPopulatedTable(metadata.components) then

            for i = 1, #metadata.components do

                local component = REGISTERED_ITEMS[metadata.components[i]]

                if component and component[weightIdx] then

                    weight = weight + component[weightIdx]
                end
            end
        end

        -- CUSTOM WEIGHT
        if metadata[weightIdx] then

            weight = weight + metadata[weightIdx]
        end
    end

    return weight
end

---Finds the first occurrence of an object
---@param inventory table
---@param itemName string
---@return nil, number slot index
function eCore:getFirstSlotByItem(inventory, itemName)

    if not hf.isPopulatedTable(inventory) then

        return nil
    end

    local slotIdx, countIdx = Config.fields.slot, Config.fields.count

    for slot, item in pairs(inventory) do

        if item.name:lower() == itemName:lower() and item[countIdx] > 0 then

            return tonumber(item[slotIdx] or slot)
        end
    end

    return nil
end

---Sums up and returns all items in inventory and their quantities
---@param inventory table
---@return table
function eCore:getAmountOfItems(inventory)

    local playerItems = {}
    local nameIdx, countIdx = Config.fields.name, Config.fields.count
    local name, amount

    if not hf.isPopulatedTable(inventory) then

        return playerItems
    end

    for _, item in pairs(inventory) do

        name, amount = item[nameIdx], item[countIdx]

        if not playerItems[name] then

            playerItems[name] = 0
        end

        playerItems[name] = playerItems[name] + amount
    end

    return playerItems
end

function eCore:getRegisteredItem(name)

    return REGISTERED_ITEMS[name]
end

function eCore:isReady()

    return CORE_READY
end


