--- Client-side mirror of server player meta (single local player): `e_core:sync` cache and revision.
--- Applies payloads: versioned `{ v, kind, rev, data }` envelope or legacy raw meta table.

local SYNC_PAYLOAD_VERSION = 1

local cacheMeta = {}
local lastSyncRev = 0

ClientMetaStore = {}

--- Returns the current client-side meta table (same reference until next sync).
--- @return table
function ClientMetaStore.getMeta()
    return cacheMeta
end

--- Clears cached meta (e.g. on player unload). Does not reset NUI shell readiness (`eCoreNui`).
--- @return nil
function ClientMetaStore.clearOnUnload()
    cacheMeta = {}
    lastSyncRev = 0
end

--- Last applied sync revision from server (`rev` in envelope); legacy full-table payloads use 0.
--- @return number
function ClientMetaStore.getLastSyncRev()
    return lastSyncRev
end

--- Normalizes `e_core:sync` payload: envelope `v=1, kind=full, data=...` or legacy root meta table.
--- @param payload table|nil
--- @return table|nil meta Meta table to store, or nil if invalid.
--- @return number rev Revision number (0 for legacy).
local function normalizeSyncPayload(payload)
    if type(payload) ~= 'table' then
        return nil, 0
    end
    if payload.v == SYNC_PAYLOAD_VERSION and payload.kind == 'full' then
        if type(payload.data) ~= 'table' then
            return nil, 0
        end
        local rev = tonumber(payload.rev)
        if rev == nil or rev ~= rev then
            rev = 0
        end
        return payload.data, rev
    end
    return payload, 0
end

--- Applies server sync: replaces cache and stores `lastSyncRev` from envelope (legacy uses 0).
--- @param payload table|nil Envelope `{ v=1, kind='full', rev=number, data=table }` or legacy root meta table.
--- @return table|nil meta Applied meta table, or nil if payload rejected.
--- @return number rev Applied revision (diagnostics / future delta).
function ClientMetaStore.applyServerSync(payload)
    local meta, rev = normalizeSyncPayload(payload)
    if type(meta) ~= 'table' then
        return nil, lastSyncRev
    end
    cacheMeta = meta
    lastSyncRev = rev
    return cacheMeta, lastSyncRev
end
