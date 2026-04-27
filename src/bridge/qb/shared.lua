if QB_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- copy it to the standalone/ directory and modify it there!
    -- this way, your changes will not be lost in future e_core updates

    local hf = hf
    local hfe = hfe

---@return table<string, {name: string, originalName: string, label: string, weight: number, isUnique: boolean, isWeapon: boolean, image: string, ammoname: string|nil, _source: string}>
    function eCore:convertItems(items)
        return hf.convertItemsWithProfile(items, 'qb', {
            sourceTag = 'qb.convertItems',
        })
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

            playerData.job = hfe.normalizePlayerJobForEcore(newJob or playerData.job)
            playerData.gang = hfe.normalizePlayerGangForEcore(newGang or playerData.gang)
            playerData.identifier = playerData.citizenid
            hfe.applyEcorePlayerDisplayFields(playerData)
            playerData.Functions = functions
        end

        return playerData
    end
end
