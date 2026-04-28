--- Server-side in-memory player metadata (`e_core` runtime row per source) and batched
--- `e_core:sync` delivery. Replaces the former global `ECO` meta/sync fields.
---
--- Payload contract for `e_core:sync` (versioned envelope, `kind = 'full'` today):
--- `{ v = 1, kind = 'full', rev = <uint>, data = <meta table> }`.

local SYNC_PAYLOAD_VERSION = 1

local bySource = {}
local lastSave = {}
local idsToSync = {}
local syncRequested = false
local revBySource = {}

PlayerMetaStore = {}

--- Returns the mutable meta row for a player source, or nil if not loaded.
--- @param playerId number
--- @return table|nil
function PlayerMetaStore.get(playerId)
    if not tonumber(playerId) then
        return nil
    end
    return bySource[playerId]
end

--- Assigns the root meta table reference for a player (caller owns the table; used by `prepareMeta`).
--- @param playerId number
--- @param meta table
--- @return nil
function PlayerMetaStore.setPlayerMeta(playerId, meta)
    if not tonumber(playerId) then
        return
    end
    bySource[playerId] = meta
end

--- Removes runtime meta for a player (e.g. after persist with drop).
--- @param playerId number
--- @return nil
function PlayerMetaStore.clear(playerId)
    if not tonumber(playerId) then
        return
    end
    bySource[playerId] = nil
end

--- Iterates loaded players as `for playerId, meta in PlayerMetaStore.eachLoaded() do`.
--- @return function iterator
--- @return table state
function PlayerMetaStore.eachLoaded()
    return pairs(bySource)
end

--- @param playerId number
--- @return number|nil
function PlayerMetaStore.getLastSave(playerId)
    if not tonumber(playerId) then
        return nil
    end
    return lastSave[playerId]
end

--- @param playerId number
--- @param t number Unix timestamp
--- @return nil
function PlayerMetaStore.setLastSave(playerId, t)
    if not tonumber(playerId) then
        return
    end
    lastSave[playerId] = t
end

--- @param playerId number
--- @return table|nil payload Envelope for `e_core:sync`, or nil if no row.
local function buildFullSyncPayload(playerId)
    local meta = bySource[playerId]
    if type(meta) ~= 'table' then
        return nil
    end
    local prev = revBySource[playerId] or 0
    local rev = prev + 1
    revBySource[playerId] = rev
    return {
        v = SYNC_PAYLOAD_VERSION,
        kind = 'full',
        rev = rev,
        data = meta,
    }
end

--- Sends one immediate full-sync envelope (e.g. after `loadMeta`).
--- @param playerId number
--- @return nil
function PlayerMetaStore.pushFullSync(playerId)
    if not tonumber(playerId) then
        return
    end
    local payload = buildFullSyncPayload(playerId)
    if not payload then
        return
    end
    TriggerClientEvent('e_core:sync', playerId, payload)
end

--- Queues a batched sync for the next tick (`SetTimeout(0)`); multiple writes coalesce to one send per player.
--- @param playerId number
--- @return nil
function PlayerMetaStore.queueSync(playerId)
    if not tonumber(playerId) then
        return
    end
    idsToSync[playerId] = true

    if syncRequested then
        return
    end
    syncRequested = true

    SetTimeout(0, function()
        for id in pairs(idsToSync) do
            local payload = buildFullSyncPayload(id)
            if payload then
                TriggerClientEvent('e_core:sync', id, payload)
            end
        end
        idsToSync = {}
        syncRequested = false
    end)
end
