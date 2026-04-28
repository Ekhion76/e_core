if ESX_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- use `overrides/...` or `src/config/`; do not edit bridge files in place.
    -- this way, your changes will not be lost in future e_core updates

    local hf = hf
    local hfe = hfe

    --- Maps ESX player / xPlayer tables to the same e_core facade fields as QB (`job` / `gang`
    --- shape, `charName`, `firstName` / `lastName`, `position`, `metadata`, `citizenid` alias).
    --- @param playerData table|nil Client `GetPlayerData()` or server `xPlayer` table.
    --- @param newJob table|nil Optional job override before normalization.
    --- @return table|nil playerData The same table reference, or `nil` if input was `nil`.
    function eCore:convertPlayer(playerData, newJob)
        if playerData then
            playerData.job = hfe.normalizePlayerJobForEcore(newJob or playerData.job)
            playerData.gang = hfe.normalizePlayerGangForEcore(nil)
            hfe.applyEcorePlayerDisplayFields(playerData)
            if type(playerData.identifier) == 'string' and playerData.identifier ~= ''
                and (playerData.citizenid == nil or playerData.citizenid == '') then
                playerData.citizenid = playerData.identifier
            end
        end

        return playerData
    end

---@return table<string, {name: string, originalName: string, label: string, weight: number, isUnique: boolean, isWeapon: boolean, image: string, ammoname: string|nil, _source: string}>
    function eCore:convertItems(items)
        return hf.convertItemsWithProfile(items, 'esx', {
            sourceTag = 'esx.convertItems',
        })
    end
end
