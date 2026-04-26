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
        local rowCount = 0
        if hf.itemConvertDiagStartRun then
            for _ in pairs(items) do rowCount = rowCount + 1 end
            hf.itemConvertDiagStartRun('qb.convertItems', rowCount)
        end

        for item, data in pairs(items) do
            if hf.isPopulatedTable(data) then
                local okConv, errConv = pcall(function()
                    local name = type(item) == 'string' and item:lower()
                        or (type(data.name) == 'string' and data.name:lower())
                        or tostring(item):lower()
                    if temp[name] ~= nil and hf.itemConvertDiagRecord then
                        hf.itemConvertDiagRecord({
                            source = 'qb.convertItems',
                            code = 'duplicate_lower_key',
                            severity = 'warning',
                            item = name,
                            reason = ('Duplicate lower-case key during convert (raw key=%s)'):format(tostring(item)),
                        })
                    end
                    temp[name] = data
                    if type(data.label) == 'string' then
                        temp[name].label = data.label:gsub("'", "\\'")
                    else
                        temp[name].label = ''
                    end
                    temp[name].isUnique = data.unique == true
                    temp[name].isWeapon = data.type == 'weapon'
                    hf.normalizeRegisteredItemDef(name, temp[name], { source = 'qb.convertItems' })
                end)
                if not okConv and cLog then
                    cLog('eCore:convertItems(QB)', { err = tostring(errConv), item = tostring(item) }, 1)
                    if hf.itemConvertDiagRecord then
                        hf.itemConvertDiagRecord({
                            source = 'qb.convertItems',
                            code = 'convert_row_error',
                            severity = 'error',
                            item = tostring(item),
                            reason = tostring(errConv),
                        })
                    end
                end
            else
                print("^3* Not valid item: *", item)
                print_r(data)
                if hf.itemConvertDiagRecord then
                    hf.itemConvertDiagRecord({
                        source = 'qb.convertItems',
                        code = 'invalid_item_row',
                        severity = 'warning',
                        item = tostring(item),
                        reason = ('Expected table row, got %s'):format(type(data)),
                    })
                end
            end
        end
        if hf.itemConvertDiagFinishRun then
            hf.itemConvertDiagFinishRun()
        end
        return temp
    end

    --- It returns the entire registered item list, unified and filtering out unnecessary information
    --- @return {label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string}
    function eCore:getRegisteredItems()

        return self:convertItems(QBCore.Shared.Items)
    end

    --- Maps QBCore player / PlayerData to the shared e_core facade (`job` / `gang`, names,
    --- `metadata`, `position`). Uses `hf.normalizePlayerJobForEcore` / `normalizePlayerGangForEcore`
    --- so missing or partial job/gang does not error.
    --- @param playerData table|nil Raw `PlayerData` or wrapper with `PlayerData` + `Functions`.
    --- @param newJob table|nil Optional job override.
    --- @param newGang table|nil Optional gang override.
    --- @return table|nil playerData Same reference (unwrapped from QBCore wrapper when used).
    function eCore:convertPlayer(playerData, newJob, newGang)
        if playerData then
            local functions = nil

            if playerData.PlayerData then
                functions = playerData.Functions
                playerData = playerData.PlayerData
            end

            playerData.job = hf.normalizePlayerJobForEcore(newJob or playerData.job)
            playerData.gang = hf.normalizePlayerGangForEcore(newGang or playerData.gang)
            playerData.identifier = playerData.citizenid
            hf.applyEcorePlayerDisplayFields(playerData)
            playerData.Functions = functions
        end

        return playerData
    end
end
