local hf = hf
-- if you want to rewrite a function, don't do it here!
-- copy it to the standalone/ directory and modify it there!
-- this way, your changes will not be lost in future e_core updates

---@param itemData any
---@return boolean ok
---@return string|nil reason `eCoreErr` ha nem ok
local function validateCarryItemPayload(itemData)
    if type(itemData) ~= 'table' then
        return false, eCoreErr.invalid_item_data
    end
    local name = itemData.name
    if type(name) ~= 'string' then
        return false, eCoreErr.invalid_item_data
    end
    name = hf.trim(name)
    if type(name) ~= 'string' or name == '' then
        return false, eCoreErr.invalid_item_data
    end
    local amt = tonumber(itemData.amount)
    if not amt or amt ~= amt or amt <= 0 then
        return false, eCoreErr.invalid_item_data
    end
    return true
end

---@param swapItem any
---@return boolean ok
---@return string|nil reason
local function validateSwapIngredientRow(swapItem)
    if type(swapItem) ~= 'table' then
        return false, eCoreErr.invalid_item_data
    end
    if type(swapItem.name) ~= 'string' then
        return false, eCoreErr.invalid_item_data
    end
    local n = hf.trim(swapItem.name)
    if type(n) ~= 'string' or n == '' then
        return false, eCoreErr.invalid_item_data
    end
    local amt = tonumber(swapItem.amount)
    if not amt or amt ~= amt or amt <= 0 then
        return false, eCoreErr.invalid_item_data
    end
    return true
end

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

    if not hf.hasEntries(inventory) then
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
    local okPayload, reasonPayload = validateCarryItemPayload(itemData)
    if not okPayload then
        return false, reasonPayload
    end

    if swappingItems ~= nil and type(swappingItems) ~= 'table' then
        return false, eCoreErr.invalid_item_data
    end

    local itemNameKey = hf.trim(itemData.name):lower()
    local itemReg = REGISTERED_ITEMS[itemNameKey]
    if not itemReg then
        return false, eCoreErr.item_not_registered
    end

    local maxInventoryWeight = self:getPlayerMaxWeight(playerData)
    local inventory = self:getInventory(playerData)
    local freeSlots = self:countFreeSlots(inventory)
    local requiredSlot = 0
    local capacity = maxInventoryWeight - self:getInventoryWeight(playerData)
    local itemWeight = self:getItemWeight(itemData.name, itemData.metadata) * itemData.amount

    cLog('canSwapItems', {
        maxInventoryWeight = maxInventoryWeight,
        freeSlots = freeSlots,
        capacity = capacity,
        itemWeight = itemWeight
    },4)

    if itemReg.isUnique then
        requiredSlot = itemData.amount
    else
        requiredSlot = self:getFirstSlotByItem(inventory, itemData.name) and 0 or 1
    end

    -- check
    if itemWeight <= capacity and requiredSlot <= freeSlots then
        return true
    end

    -- swapping items calculate (capacity / freeSlots szimuláció — nem módosítjuk a játékos inventory táblát)
    local amountToRemove, weight = 0, 0
    local nameIdx, countIdx = Config.fields.name, Config.fields.count

    for _, swapItem in pairs(swappingItems or {}) do
        local okRow, rowReason = validateSwapIngredientRow(swapItem)
        if not okRow then
            return false, rowReason
        end

        amountToRemove = swapItem.amount
        weight = self:getItemWeight(swapItem.name, swapItem.metadata)

        local swapNameLower = hf.trim(swapItem.name):lower()
        local swapReg = REGISTERED_ITEMS[swapNameLower]
        if not swapReg then
            return false, eCoreErr.item_not_registered
        end

        if swapReg.isUnique then
            freeSlots = freeSlots + swapItem.amount
            capacity = capacity + (weight * swapItem.amount)
        else
            for _, item in pairs(inventory) do
                local inName = item[nameIdx]
                if type(inName) == 'string' and inName:lower() == swapNameLower
                    and (item[countIdx] or 0) > 0 then
                    local slotCount = item[countIdx]
                    if slotCount >= amountToRemove then
                        capacity = capacity + (weight * amountToRemove)
                        local newCount = slotCount - amountToRemove
                        if newCount < 1 then
                            freeSlots = freeSlots + 1
                        end
                        amountToRemove = 0
                    else
                        capacity = capacity + (weight * slotCount)
                        freeSlots = freeSlots + 1
                        amountToRemove = amountToRemove - slotCount
                    end

                    if amountToRemove == 0 then break end
                end
            end
        end
    end

    -- check
    if itemWeight > capacity then
        return false, eCoreErr.too_heavy
    end

    if requiredSlot > freeSlots then
        return false, eCoreErr.not_enough_space
    end

    return true
end

---Returns true or false (and reason) depending if the inventory can carry the specified item
---@param itemData table {name: string, amount: number, metadata: table}
---@return boolean, string
function eCore:canCarryItem(itemData, playerData)
    local okPayload, reasonPayload = validateCarryItemPayload(itemData)
    if not okPayload then
        return false, reasonPayload
    end

    local itemNameKey = hf.trim(itemData.name):lower()
    local itemReg = REGISTERED_ITEMS[itemNameKey]
    if not itemReg then
        return false, eCoreErr.item_not_registered
    end

    local maxInventoryWeight = self:getPlayerMaxWeight(playerData)
    local inventory = self:getInventory(playerData)
    local requiredSlot = 0

    local capacity = maxInventoryWeight - self:getInventoryWeight(playerData)
    local itemWeight = self:getItemWeight(itemData.name, itemData.metadata) * itemData.amount

    if itemWeight > capacity then
        return false, eCoreErr.too_heavy
    end

    if itemReg.isUnique then
        requiredSlot = itemData.amount
    else
        requiredSlot = self:getFirstSlotByItem(inventory, itemData.name) and 0 or 1
    end

    if requiredSlot == 0 then
        return true
    end

    if requiredSlot > self:countFreeSlots(inventory) then
        return false, eCoreErr.not_enough_space
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @param itemName any
--- @param metadata any
--- @return any result
function eCore:getItemWeight(itemName, metadata)
    if type(itemName) ~= 'string' then
        return 0
    end

    local item = REGISTERED_ITEMS[itemName:lower()]

    if not item then
        return 0
    end

    local weightIdx = Config.fields.weight
    local weight = item[weightIdx]

    if hf.hasEntries(metadata) then
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
        if hf.hasEntries(metadata.components) then
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
    if type(itemName) ~= 'string' then
        return nil
    end

    if not hf.hasEntries(inventory) then
        return nil
    end

    local slotIdx, countIdx = Config.fields.slot, Config.fields.count

    for slot, item in pairs(inventory) do
        local rowName = item.name
        if type(rowName) == 'string' and rowName:lower() == itemName:lower() and item[countIdx] > 0 then
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

    if not hf.hasEntries(inventory) then
        return playerItems
    end

    for _, item in pairs(inventory) do
        name, amount = item[nameIdx]:lower(), item[countIdx]

        if not playerItems[name] then
            playerItems[name] = 0
        end

        playerItems[name] = playerItems[name] + amount
    end

    return playerItems
end

--- Returns whether the resolved inventory contains at least `count` of `itemName`.
--- @param playerData table xPlayer or client `playerData` passed to `getInventory`.
--- @param itemName string Item name (must be a Lua string).
--- @param count number|nil Required amount (default **1**).
--- @return boolean ok
--- @return string|nil reason `eCoreErr.invalid_item_name` when `itemName` is not a string.
function eCore:hasItem(playerData, itemName, count)
    if type(itemName) ~= 'string' then
        return false, eCoreErr.invalid_item_name
    end
    local amounts = self:getAmountOfItems(self:getInventory(playerData))
    return (amounts[itemName:lower()] or 0) >= (count or 1)
end

--- Visszaadja a játékos inventoryjában lévő tárgy teljes mennyiségét.
--- Több slotban lévő azonos tárgyak összege.
--- @param playerData table xPlayer objektum vagy playerData
--- @param itemName string tárgy neve
--- @return number mennyiség (0 ha nincs)
function eCore:getItemCount(playerData, itemName)
    if type(itemName) ~= 'string' then return 0 end
    local amounts = self:getAmountOfItems(self:getInventory(playerData))
    return amounts[itemName:lower()] or 0
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @return any result
function eCore:getRegisteredItem(name)
    return REGISTERED_ITEMS[name]
end

--- Item registry + core bootstrap finished successfully (see `hfe.awaitItemRegistryReady`).
--- @return boolean ready `true` only when registry is populated; `false` while waiting, on timeout, or when idle/init failed.
function eCore:isReady()
    return CORE_READY == true
end
