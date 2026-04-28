local hf = hf
local hfe = hfe

--- Returns whether `eCore:isLoggedIn()` can be called (init not aborted and method exists).
---@return boolean
local function eCoreClientReady()
    if _G._ECORE_INIT_FAILED then
        return false
    end
    return type(eCore) == 'table' and type(eCore.isLoggedIn) == 'function'
end

-- `false` = még nem ready vagy timeout/IDLE; csak `true` ha item registry kész (`exports.e_core:isReady()` == true). Korábban `nil` volt, ami félrevezető truthy ellenőrzéseknél.
CORE_READY, REGISTERED_ITEMS = false, nil

CreateThread(function()
    cLog('CLIENT REGISTERED_ITEMS', 'Loading', 2)

    if hfe.awaitItemRegistryReady('CLIENT REGISTERED_ITEMS') then
        cLog('CLIENT REGISTERED_ITEMS', 'Loaded', 2)
        cLog('CLIENT CORE', 'READY', 2)
    end

    hfe.logEcoreStartupSummary('client')
end)

local init

------------
--- META ---
------------

--- @param category string category eg.: crafting, reputation, harvesting, special, ...
--- @param name string|nil (optional) subcategory eg.: weaponry, cooking, handicraft, chemist, etc.
--- @return number|table|boolean proficiency | whole category | false + eCoreErr on failure
function getAbility(category, name)
    if type(category) ~= 'string' then
        return false, eCoreErr.no_valid_meta_name
    end
    local ck = hf.trim(category)
    if ck == '' then
        return false, eCoreErr.no_valid_meta_name
    end

    local meta = ClientMetaStore.getMeta()
    if not meta[ck] then
        return false, eCoreErr.category_does_not_exist
    end

    if name ~= nil then
        if type(name) ~= 'string' then
            return false, eCoreErr.no_valid_meta_name
        end
        local nk = hf.trim(name)
        if nk == '' then
            return false, eCoreErr.no_valid_meta_name
        end
        local slot = meta[ck][nk]
        if slot == nil then
            return false, eCoreErr.meta_does_not_exist
        end
        return slot
    end
    return meta[ck]
end

--- @param meta string|nil optional category key (same trim contract as server-side)
--- @return table|false full meta | one category | false, eCoreErr when key parameter is invalid
function getMeta(meta)
    if meta == nil then
        return ClientMetaStore.getMeta()
    end
    if type(meta) ~= 'string' then
        return false, eCoreErr.no_valid_meta_name
    end
    local mk = hf.trim(meta)
    if mk == '' then
        return false, eCoreErr.no_valid_meta_name
    end
    return ClientMetaStore.getMeta()[mk]
end

--- Returns current client-side labor value if available.
--- @return boolean|number ok, laborValue or false, eCoreErr
function getLabor()
    if not Config.systemMode.labor then
        return false, eCoreErr.feature_disabled
    end
    local m = ClientMetaStore.getMeta()
    if not m or not m.labor then
        return false, eCoreErr.not_found_metadata
    end
    local labor = m.labor
    if type(labor) ~= 'table' then
        return false, eCoreErr.not_found_metadata
    end
    local n = tonumber(labor.val)
    if n == nil or n ~= n then
        return false, eCoreErr.not_found_metadata
    end
    return true, n
end

--- Waits for NUI readiness and sends initial payload.
--- @return nil
function nuiInit()
    cLog('NUI INIT', 'Loading', 2)

    while not eCoreNui.isReady() do
        Wait(1000)
        cLog('NUI INIT', 'Wait', 2)
    end

    local meta = ClientMetaStore.getMeta()
    -- INIT MESSAGE
    SendNUIMessage({ action = 'INIT',
                     metadata = meta,
                     levels = Config.levels,
                     locale = locales[Config.locale],
                     laborLimit = Config.laborLimit,
                     abilityLimit = Config.abilityLimit,
                     displayComponent = Config.displayComponent,
                   })

    cLog('NUI INIT', 'Loaded...', 2)

    if eCoreClientReady() and eCore:isLoggedIn() then
        if eCoreNui.isReady() and Config.systemMode.labor and Config.displayComponent.laborHud then
            SendNUIMessage({ action = 'OPEN', subject = 'hud' })
        end
    end
end

AddEventHandler('e_core:onPlayerLoaded', function()
    if _G._ECORE_INIT_FAILED then return end
    if eCoreNui.isReady() and Config.systemMode.labor and Config.displayComponent.laborHud then
        SendNUIMessage({ action = 'OPEN', subject = 'hud' })
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if eCoreClientReady() and eCore:isLoggedIn() then
            TriggerServerEvent('e_core:loadMeta')
        end
    end
end)

AddEventHandler('e_core:isPauseMenuActive', function(isPaused)
    if _G._ECORE_INIT_FAILED then return end
    if isPaused then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'CLOSE', subject = 'all' })
    else

        if eCoreClientReady() and eCore:isLoggedIn() and Config.systemMode.labor and Config.displayComponent.laborHud then
            SendNUIMessage({ action = 'OPEN', subject = 'hud' })
        end
    end
end)

AddEventHandler('e_core:onPlayerUnload', function()
    ClientMetaStore.clearOnUnload()

    init = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'CLOSE', subject = 'all' })
end)

RegisterNetEvent('e_core:sync', function(payload)
    if type(payload) ~= 'table' then
        cLog('e_core:sync', 'ignored: payload is not a table', 2)
        return
    end
    local meta = ClientMetaStore.applyServerSync(payload)
    if not meta then
        cLog('e_core:sync', 'ignored: could not apply payload', 2)
        return
    end

    if not init then
        init = true
        nuiInit()
    end

    if eCoreNui.isReady() then
        if IsNuiFocused() then
            SendNUIMessage({ action = 'UPDATE', subject = 'page', metadata = meta })
        else
            SendNUIMessage({ action = 'UPDATE', subject = 'hud', metadata = meta })
        end
    end
end)

RegisterNetEvent('e_core:levelChange', function(data)
    if type(data) ~= 'table' then
        return
    end
    SendNUIMessage({ action = 'POPUP', data = data })
end)

-- NUI CALLBACKS
RegisterNUICallback('nuiReady', function(_, cb)
    eCoreNui.markShellReady()
    TriggerEvent('e_core:web:nuiReady')
    cb('ok')
end)

RegisterNUICallback('exit', function(_, cb)
    if eCore and eCore.UI and type(eCore.UI.IsEditMode) == 'function' and eCore.UI.IsEditMode() then
        eCore.UI.ExitEditMode()
    end
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('hudPreview', function(data, cb)
    if ECoreHudLayout and type(ECoreHudLayout.applyPreview) == 'function' then
        local ok = ECoreHudLayout.applyPreview(data and data.id, data and data.pos)
        cb(ok and 'ok' or 'ignored')
        return
    end
    cb('ignored')
end)

RegisterNUICallback('hudCommit', function(data, cb)
    if ECoreHudLayout and type(ECoreHudLayout.commit) == 'function' then
        ECoreHudLayout.commit(data)
    end
    if eCore and eCore.UI and type(eCore.UI.ExitEditMode) == 'function' then
        eCore.UI.ExitEditMode()
    end
    cb('ok')
end)

RegisterNUICallback('hudEditExit', function(_, cb)
    if eCore and eCore.UI and type(eCore.UI.ExitEditMode) == 'function' then
        eCore.UI.ExitEditMode()
    end
    cb('ok')
end)

if Config.enableStatMenu then
    RegisterKeyMapping('openMeta', 'View Skills', 'keyboard', Config.keyBind.openStat)

    RegisterCommand('openMeta', function()
        if not eCoreNui.isReady() then
            cLog('command openMeta', 'Waiting for NUI load', 2)
            return false
        end
        if eCore and eCore.UI and type(eCore.UI.IsEditMode) == 'function' and eCore.UI.IsEditMode() then
            cLog('command openMeta', 'Blocked while HUD edit mode is active', 2)
            return false
        end

        if not IsNuiFocused() then
            SetNuiFocus(true, true)
            SendNUIMessage({ action = 'OPEN', subject = 'page', metadata = ClientMetaStore.getMeta() })
        end
    end)
end

CreateThread(function()
    local isPaused, _IsPauseMenuActive

    while true do
        _IsPauseMenuActive = IsPauseMenuActive()

        if _IsPauseMenuActive and not isPaused then
            isPaused = true
            TriggerEvent('e_core:isPauseMenuActive', isPaused)
        elseif not _IsPauseMenuActive and isPaused then
            isPaused = false
            TriggerEvent('e_core:isPauseMenuActive', isPaused)
        end
        Wait(1000)
    end
end)
