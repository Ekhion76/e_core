if ESX_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- copy it to the standalone/ directory and modify it there!
    -- this way, your changes will not be lost in future e_core updates

    local hf = hf

    --- Maps ESX player / xPlayer tables to the same e_core facade fields as QB (`job` / `gang`
    --- shape, `charName`, `firstName` / `lastName`, `position`, `metadata`, `citizenid` alias).
    --- @param playerData table|nil Client `GetPlayerData()` or server `xPlayer` table.
    --- @param newJob table|nil Optional job override before normalization.
    --- @return table|nil playerData The same table reference, or `nil` if input was `nil`.
    function eCore:convertPlayer(playerData, newJob)
        if playerData then
            playerData.job = hf.normalizePlayerJobForEcore(newJob or playerData.job)
            playerData.gang = hf.normalizePlayerGangForEcore(nil)
            hf.applyEcorePlayerDisplayFields(playerData)
            if type(playerData.identifier) == 'string' and playerData.identifier ~= ''
                and (playerData.citizenid == nil or playerData.citizenid == '') then
                playerData.citizenid = playerData.identifier
            end
        end

        return playerData
    end

    ---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
    function eCore:convertItems(items)
        if not hf.isPopulatedTable(items) then
            return items
        end

        local tmp = {}
        local rowCount = 0
        if hf.itemConvertDiagStartRun then
            for _ in pairs(items) do rowCount = rowCount + 1 end
            hf.itemConvertDiagStartRun('esx.convertItems', rowCount)
        end

        for item, data in pairs(items) do
            local okConv, errConv = pcall(function()
                if type(data) ~= 'table' then
                    if hf.itemConvertDiagRecord then
                        hf.itemConvertDiagRecord({
                            source = 'esx.convertItems',
                            code = 'invalid_item_row',
                            severity = 'warning',
                            item = tostring(item),
                            reason = ('Expected table row, got %s'):format(type(data)),
                        })
                    end
                    return
                end
                local raw = type(item) == 'string' and item or data.name
                if raw == nil or raw == '' then
                    if hf.itemConvertDiagRecord then
                        hf.itemConvertDiagRecord({
                            source = 'esx.convertItems',
                            code = 'invalid_item_key',
                            severity = 'warning',
                            item = tostring(item),
                            reason = 'Missing item key and data.name',
                        })
                    end
                    return
                end
                raw = type(raw) == 'string' and raw or tostring(raw)
                local name = raw:lower()
                if tmp[name] ~= nil and hf.itemConvertDiagRecord then
                    hf.itemConvertDiagRecord({
                        source = 'esx.convertItems',
                        code = 'duplicate_lower_key',
                        severity = 'warning',
                        item = name,
                        reason = ('Duplicate lower-case key during convert (raw key=%s)'):format(tostring(item)),
                    })
                end
                tmp[name] = data
                tmp[name].isUnique = false
                tmp[name].isWeapon = false
                hf.normalizeRegisteredItemDef(name, tmp[name], { source = 'esx.convertItems' })
            end)
            if not okConv and cLog then
                cLog('eCore:convertItems(ESX)', { err = tostring(errConv), item = tostring(item) }, 1)
                if hf.itemConvertDiagRecord then
                    hf.itemConvertDiagRecord({
                        source = 'esx.convertItems',
                        code = 'convert_row_error',
                        severity = 'error',
                        item = tostring(item),
                        reason = tostring(errConv),
                    })
                end
            end
        end
        if hf.itemConvertDiagFinishRun then
            hf.itemConvertDiagFinishRun()
        end

        return tmp
    end
end
