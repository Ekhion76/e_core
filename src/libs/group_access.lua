--- Job/gang whitelist-blacklist access evaluator for normalized player snapshots (`eCore:convertPlayer`).
--- Paired JS counterpart: `src/web/copyable/GroupAccess.js` (`class GroupAccess`).
--- Contract: if both `whitelist` and `blacklist` are missing or empty, access is allowed.
--- If `whitelist` is populated, it wins (blacklist ignored). Otherwise `blacklist` applies.
--- List shapes: array-like table of names or map `{ [groupName] = gradeArray|{} }`.
--- Empty grade array `{}` means any grade for that group.
local hf = hf

GroupAccess = GroupAccess or {}

--- Builds ordered group rows from `playerData.job` and optional `playerData.gang`.
--- @param playerData table|nil Normalized player: `job.name`, `job.grade`, optional `gang.name`, `gang.grade`.
--- @return table groups Array of `{ name=string, grade=any }`.
local function collectJobGangGroups(playerData)
    local groups = {}
    if type(playerData) ~= 'table' then
        return groups
    end

    local job = playerData.job
    if type(job) == 'table' then
        local jn = job.name
        if type(jn) == 'string' and hf.trim(jn) ~= '' then
            groups[#groups + 1] = { name = jn, grade = job.grade }
        end
    end

    local gang = playerData.gang
    if type(gang) == 'table' then
        local gn = gang.name
        if type(gn) == 'string' and hf.trim(gn) ~= '' then
            groups[#groups + 1] = { name = gn, grade = gang.grade }
        end
    end

    return groups
end

--- Returns true when one group row matches the provided list.
--- @param group table `{ name=string, grade=any }`.
--- @param list table Whitelist or blacklist definition.
--- @return boolean matched True when this group hits the list.
local function matchGroupOnList(group, list)
    if hf.contains(group.name, list) then
        return true
    end

    local gradeList = list[group.name]
    if gradeList ~= nil then
        return not hf.hasEntries(gradeList) or hf.contains(group.grade, gradeList)
    end

    return false
end

--- Applies whitelist or blacklist semantics to collected group rows.
--- @param groups table Array from `collectJobGangGroups`.
--- @param list table Active whitelist or blacklist table.
--- @param isWhitelist boolean True for whitelist path, false for blacklist path.
--- @return boolean allowed Final decision for this mode.
local function evaluateGroupsAgainstList(groups, list, isWhitelist)
    for _, group in ipairs(groups) do
        if matchGroupOnList(group, list) then
            return isWhitelist
        end
    end

    return not isWhitelist
end

--- Returns true when `playerData` passes `data.whitelist` / `data.blacklist` rules.
--- @param self table GroupAccess class table.
--- @param playerData table|nil Normalized player snapshot (`job` / optional `gang`).
--- @param data table|nil Rule table with optional `whitelist` and `blacklist`.
--- @return boolean allowed True when the player is allowed under the configured rules.
function GroupAccess:check(playerData, data)
    if type(data) ~= 'table' then
        return true
    end

    local hasWhitelist = hf.hasEntries(data.whitelist)
    local hasBlacklist = hf.hasEntries(data.blacklist)
    if not hasWhitelist and not hasBlacklist then
        return true
    end

    local groups = collectJobGangGroups(playerData)
    if hasWhitelist then
        return evaluateGroupsAgainstList(groups, data.whitelist, true)
    end

    return evaluateGroupsAgainstList(groups, data.blacklist, false)
end

eCore.GroupAccess = GroupAccess
