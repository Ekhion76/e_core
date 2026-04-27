local HUD_LAYOUT_META_KEY = 'hudLayout'

local ALLOWED_ANCHORS = {
    ['top-left'] = true,
    ['top-right'] = true,
    ['bottom-left'] = true,
    ['bottom-right'] = true,
    ['center'] = true,
}

local registry = {}
local previewById = {}
local committedById = {}
local editMode = false

ECoreHudLayout = {}
eCore.UI = eCore.UI or {}

--- @param n any
--- @param min number
--- @param max number
--- @return number|nil
local function toFiniteRange(n, min, max)
    local v = tonumber(n)
    if v == nil or v ~= v then
        return nil
    end
    if v < min then
        return min
    end
    if v > max then
        return max
    end
    return v
end

--- @param raw table|nil
--- @param fallback table|nil
--- @return table|nil
local function sanitizePosition(raw, fallback)
    if type(raw) ~= 'table' then
        raw = fallback
    end
    if type(raw) ~= 'table' then
        return nil
    end

    local x = toFiniteRange(raw.x, 0.0, 1.0)
    local y = toFiniteRange(raw.y, 0.0, 1.0)
    if x == nil or y == nil then
        return nil
    end
    local w = toFiniteRange(raw.w, 0.01, 1.0) or (type(fallback) == 'table' and toFiniteRange(fallback.w, 0.01, 1.0)) or 0.2
    local h = toFiniteRange(raw.h, 0.01, 1.0) or (type(fallback) == 'table' and toFiniteRange(fallback.h, 0.01, 1.0)) or 0.1

    local anchor = type(raw.anchor) == 'string' and hf.trim(raw.anchor) or ''
    if anchor == '' then
        anchor = (type(fallback) == 'table' and type(fallback.anchor) == 'string') and fallback.anchor or 'top-left'
    end
    if not ALLOWED_ANCHORS[anchor] then
        anchor = 'top-left'
    end

    return {
        x = x,
        y = y,
        w = w,
        h = h,
        anchor = anchor,
    }
end

--- @param payload table|nil
--- @return nil
local function applyCommittedLayout(payload)
    committedById = {}
    local elements = type(payload) == 'table' and payload.elements or nil
    if type(elements) ~= 'table' then
        return
    end
    for elementId, raw in pairs(elements) do
        if type(elementId) == 'string' then
            local pos = sanitizePosition(raw, nil)
            if pos then
                committedById[elementId] = pos
            end
        end
    end
end

--- @param elementId string
--- @return table|nil
local function resolvePosition(elementId)
    if previewById[elementId] then
        return previewById[elementId]
    end
    if committedById[elementId] then
        return committedById[elementId]
    end
    local entry = registry[elementId]
    if not entry then
        return nil
    end
    return entry.defaultPos
end

--- @return table
local function buildNuiElements()
    local out = {}
    for elementId, entry in pairs(registry) do
        out[#out + 1] = {
            id = elementId,
            label = entry.label,
            pos = resolvePosition(elementId),
        }
    end
    return out
end

--- @return nil
local function emitNuiState()
    if not eCoreNui or not eCoreNui.isReady or not eCoreNui.isReady() then
        return
    end
    SendNUIMessage({
        action = 'HUD_EDIT_STATE',
        active = editMode,
        elements = buildNuiElements(),
    })
end

--- @param elementId string
--- @return nil
local function notifyConsumer(elementId)
    local pos = resolvePosition(elementId)
    if not pos then
        return
    end
    TriggerEvent('e_core:hud:clientPreview', elementId, pos)
end

--- @return nil
local function notifyConsumerAll()
    for elementId in pairs(registry) do
        notifyConsumer(elementId)
    end
end

--- @return table
local function extractCommittedFromMeta()
    local meta = ClientMetaStore.getMeta()
    if type(meta) ~= 'table' then
        return {}
    end
    local layout = meta[HUD_LAYOUT_META_KEY]
    if type(layout) ~= 'table' then
        return {}
    end
    return layout
end

--- Registers a consumer HUD element and starts local sync updates for this id.
--- @param id string Unique namespaced element id (`resource:key` recommended).
--- @param data table Registration payload (`label`, `defaultPos` with normalized `x,y,w,h,anchor`).
--- @return boolean success
--- @return table|string posOrErr Effective current position when success, otherwise reason.
function eCore.UI.RegisterHudElement(id, data)
    if type(id) ~= 'string' then
        return false, eCoreErr.no_valid_meta_name
    end
    local key = hf.trim(id)
    if key == '' then
        return false, eCoreErr.no_valid_meta_name
    end
    if type(data) ~= 'table' then
        return false, eCoreErr.meta_value_must_be_table
    end
    local defaultPos = sanitizePosition(data.defaultPos, nil)
    if not defaultPos then
        return false, eCoreErr.not_valid_amount
    end
    registry[key] = {
        label = type(data.label) == 'string' and data.label or key,
        defaultPos = defaultPos,
    }
    emitNuiState()
    notifyConsumer(key)
    return true, resolvePosition(key)
end

--- Unregisters one previously tracked HUD element.
--- @param id string
--- @return nil
function eCore.UI.UnregisterHudElement(id)
    if type(id) ~= 'string' then
        return
    end
    local key = hf.trim(id)
    if key == '' then
        return
    end
    registry[key] = nil
    previewById[key] = nil
    committedById[key] = nil
    emitNuiState()
end

--- Returns whether HUD edit mode is currently active on this client.
--- @return boolean
function eCore.UI.IsEditMode()
    return editMode == true
end

--- Enables HUD edit mode (focus + edit layer open).
--- @return nil
function eCore.UI.EnterEditMode()
    editMode = true
    SendNUIMessage({ action = 'CLOSE', subject = 'all' })
    SetNuiFocus(true, true)
    emitNuiState()
    TriggerEvent('e_core:hud:editMode', true)
end

--- Disables HUD edit mode (focus release + edit layer close).
--- @return nil
function eCore.UI.ExitEditMode()
    editMode = false
    SetNuiFocus(false, false)
    if eCore and type(eCore.isLoggedIn) == 'function' and eCore:isLoggedIn() then
        if Config and Config.systemMode and Config.systemMode.labor and Config.displayComponent and Config.displayComponent.laborHud then
            SendNUIMessage({ action = 'OPEN', subject = 'hud' })
        end
    end
    emitNuiState()
    TriggerEvent('e_core:hud:editMode', false)
end

--- Applies one local preview update from NUI drag interactions.
--- @param id string
--- @param rawPos table
--- @return boolean
function ECoreHudLayout.applyPreview(id, rawPos)
    if type(id) ~= 'string' then
        return false
    end
    local key = hf.trim(id)
    if key == '' or not registry[key] then
        return false
    end
    local fallback = resolvePosition(key) or registry[key].defaultPos
    local pos = sanitizePosition(rawPos, fallback)
    if not pos then
        return false
    end
    previewById[key] = pos
    notifyConsumer(key)
    emitNuiState()
    return true
end

--- Commits current preview (or explicit payload) to server persistence.
--- @param payload table|nil Optional full layout payload (`elements` map).
--- @return nil
function ECoreHudLayout.commit(payload)
    local elements = {}
    if type(payload) == 'table' and type(payload.elements) == 'table' then
        for elementId, rawPos in pairs(payload.elements) do
            if type(elementId) == 'string' and registry[elementId] then
                local pos = sanitizePosition(rawPos, resolvePosition(elementId) or registry[elementId].defaultPos)
                if pos then
                    elements[elementId] = pos
                end
            end
        end
    else
        for elementId in pairs(registry) do
            local pos = sanitizePosition(resolvePosition(elementId), registry[elementId].defaultPos)
            if pos then
                elements[elementId] = pos
            end
        end
    end
    TriggerServerEvent('e_core:hud:commit', { v = 1, elements = elements })
end

RegisterNetEvent('e_core:hud:applied', function(layout)
    applyCommittedLayout(layout)
    previewById = {}
    notifyConsumerAll()
    emitNuiState()
end)

RegisterNetEvent('e_core:sync', function(payload)
    if type(payload) ~= 'table' then
        return
    end
    local data = payload
    if payload.v == 1 and payload.kind == 'full' and type(payload.data) == 'table' then
        data = payload.data
    end
    if type(data) ~= 'table' then
        return
    end
    applyCommittedLayout(data[HUD_LAYOUT_META_KEY])
    if not editMode then
        previewById = {}
    end
    notifyConsumerAll()
    emitNuiState()
end)

RegisterCommand('ecore_hud_edit', function()
    if eCore.UI.IsEditMode() then
        eCore.UI.ExitEditMode()
    else
        eCore.UI.EnterEditMode()
    end
end, false)

