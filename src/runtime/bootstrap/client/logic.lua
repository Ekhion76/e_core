local hf = hf
local hfe = hfe
local localeSdk = lib.require('src/imports/sdk/locale/shared')

--- Returns whether `eCore:isLoggedIn()` can be called (init not aborted and method exists).
---@return boolean
local function eCoreClientReady()
    if _ECORE_INIT_FAILED then
        return false
    end
    return type(eCore) == 'table' and type(eCore.isLoggedIn) == 'function'
end

-- `false` = még nem ready vagy timeout/IDLE; csak `true` ha item registry kész (`exports.e_core:isReady()` == true). Korábban `nil` volt, ami félrevezető truthy ellenőrzéseknél.
CORE_READY, REGISTERED_ITEMS = false, nil

--- Runs client startup wait/log flow.
--- @return nil
local function runClientBootstrap()
    hf.cLog('CLIENT REGISTERED_ITEMS', 'Loading', 2)

    if hfe.awaitItemRegistryReady('CLIENT REGISTERED_ITEMS') then
        hf.cLog('CLIENT REGISTERED_ITEMS', 'Loaded', 2)
        hf.cLog('CLIENT CORE', 'READY', 2)
    end

    hfe.logEcoreStartupSummary('client')
end

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
    hf.cLog('NUI INIT', 'Loading', 2)

    while not eCoreNui.isReady() do
        Wait(1000)
        hf.cLog('NUI INIT', 'Wait', 2)
    end

    local meta = ClientMetaStore.getMeta()
    -- INIT MESSAGE
    SendNUIMessage({ action = 'INIT',
                     metadata = meta,
                     levels = Config.levels,
                     locale = localeSdk.locales[Config.locale],
                     laborLimit = Config.laborLimit,
                     abilityLimit = Config.abilityLimit,
                     displayComponent = Config.displayComponent,
                   })

    hf.cLog('NUI INIT', 'Loaded...', 2)

    if eCoreClientReady() and eCore:isLoggedIn() then
        if eCoreNui.isReady() and Config.systemMode.labor and Config.displayComponent.laborHud then
            SendNUIMessage({ action = 'OPEN', subject = 'hud' })
        end
    end
end

--- Handles player loaded event on client.
--- @return nil
local function onPlayerLoaded()
    if _ECORE_INIT_FAILED then return end
    if eCoreNui.isReady() and Config.systemMode.labor and Config.displayComponent.laborHud then
        SendNUIMessage({ action = 'OPEN', subject = 'hud' })
    end
end

--- Handles resource start event for this resource.
--- @param resource string
--- @return nil
local function onResourceStart(resource)
    if resource == GetCurrentResourceName() then
        if eCoreClientReady() and eCore:isLoggedIn() then
            TriggerServerEvent('e_core:loadMeta')
        end
    end
end

--- Handles pause menu state changes.
--- @param isPaused boolean
--- @return nil
local function onPauseMenuActive(isPaused)
    if _ECORE_INIT_FAILED then return end
    if isPaused then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'CLOSE', subject = 'all' })
    else

        if eCoreClientReady() and eCore:isLoggedIn() and Config.systemMode.labor and Config.displayComponent.laborHud then
            SendNUIMessage({ action = 'OPEN', subject = 'hud' })
        end
    end
end

--- Handles player unload cleanup on client.
--- @return nil
local function onPlayerUnload()
    ClientMetaStore.clearOnUnload()

    init = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'CLOSE', subject = 'all' })
end

--- Handles server sync payload updates.
--- @param payload table|nil
--- @return nil
local function onSync(payload)
    if type(payload) ~= 'table' then
        hf.cLog('e_core:sync', 'ignored: payload is not a table', 2)
        return
    end
    local meta = ClientMetaStore.applyServerSync(payload)
    if not meta then
        hf.cLog('e_core:sync', 'ignored: could not apply payload', 2)
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
end

--- Handles level change popup event.
--- @param data table|nil
--- @return nil
local function onLevelChange(data)
    if type(data) ~= 'table' then
        return
    end
    SendNUIMessage({ action = 'POPUP', data = data })
end

-- NUI CALLBACKS
--- Handles NUI ready callback.
--- @param cb function
--- @return nil
local function onNuiReady(cb)
    eCoreNui.markShellReady()
    TriggerEvent('e_core:web:nuiReady')
    cb('ok')
end

--- Handles NUI exit callback.
--- @param cb function
--- @return nil
local function onNuiExit(cb)
    if eCore and eCore.UI and type(eCore.UI.IsEditMode) == 'function' and eCore.UI.IsEditMode() then
        eCore.UI.ExitEditMode()
    end
    SetNuiFocus(false, false)
    cb('ok')
end

--- Handles HUD preview callback.
--- @param data table|nil
--- @param cb function
--- @return nil
local function onHudPreview(data, cb)
    if ECoreHudLayout and type(ECoreHudLayout.applyPreview) == 'function' then
        local ok = ECoreHudLayout.applyPreview(data and data.id, data and data.pos)
        cb(ok and 'ok' or 'ignored')
        return
    end
    cb('ignored')
end

--- Handles HUD commit callback.
--- @param data table|nil
--- @param cb function
--- @return nil
local function onHudCommit(data, cb)
    if ECoreHudLayout and type(ECoreHudLayout.commit) == 'function' then
        ECoreHudLayout.commit(data)
    end
    if eCore and eCore.UI and type(eCore.UI.ExitEditMode) == 'function' then
        eCore.UI.ExitEditMode()
    end
    cb('ok')
end

--- Handles HUD edit exit callback.
--- @param cb function
--- @return nil
local function onHudEditExit(cb)
    if eCore and eCore.UI and type(eCore.UI.ExitEditMode) == 'function' then
        eCore.UI.ExitEditMode()
    end
    cb('ok')
end

--- Registers optional stat menu key mapping + command.
--- @return nil
local function registerStatMenuCommand()
    if not Config.enableStatMenu then
        return
    end
    RegisterKeyMapping('openMeta', 'View Skills', 'keyboard', Config.keyBind.openStat)

    RegisterCommand('openMeta', function()
        if not eCoreNui.isReady() then
            hf.cLog('command openMeta', 'Waiting for NUI load', 2)
            return false
        end
        if eCore and eCore.UI and type(eCore.UI.IsEditMode) == 'function' and eCore.UI.IsEditMode() then
            hf.cLog('command openMeta', 'Blocked while HUD edit mode is active', 2)
            return false
        end

        if not IsNuiFocused() then
            SetNuiFocus(true, true)
            SendNUIMessage({ action = 'OPEN', subject = 'page', metadata = ClientMetaStore.getMeta() })
        end
    end)
end

--- Runs pause-menu watcher loop and emits state events.
--- @return nil
local function runPauseWatcherLoop()
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
end

return {
    runClientBootstrap = runClientBootstrap,
    onPlayerLoaded = onPlayerLoaded,
    onResourceStart = onResourceStart,
    onPauseMenuActive = onPauseMenuActive,
    onPlayerUnload = onPlayerUnload,
    onSync = onSync,
    onLevelChange = onLevelChange,
    onNuiReady = onNuiReady,
    onNuiExit = onNuiExit,
    onHudPreview = onHudPreview,
    onHudCommit = onHudCommit,
    onHudEditExit = onHudEditExit,
    registerStatMenuCommand = registerStatMenuCommand,
    runPauseWatcherLoop = runPauseWatcherLoop,
}
