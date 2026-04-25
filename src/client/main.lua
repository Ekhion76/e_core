ECO = {}
ECO.meta = {}
ECO.nuiReady = false
local hf = hf

CORE_READY, REGISTERED_ITEMS = nil, nil

CreateThread(function()
    cLog('CLIENT REGISTERED_ITEMS', 'Loading', 2)

    if hf.awaitItemRegistryReady('CLIENT REGISTERED_ITEMS') then
        cLog('CLIENT REGISTERED_ITEMS', 'Loaded', 2)
        cLog('CLIENT CORE', 'READY', 2)
    end

    hf.logEcoreStartupSummary('client')
end)

local nuiReady, init

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

    if not ECO.meta[ck] then
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
        local slot = ECO.meta[ck][nk]
        if slot == nil then
            return false, eCoreErr.meta_does_not_exist
        end
        return slot
    end
    return ECO.meta[ck]
end

--- @param meta string|nil optional category key (same trim contract as server-side)
--- @return table|false full meta | one category | false, eCoreErr when key parameter is invalid
function getMeta(meta)
    if meta == nil then
        return ECO.meta
    end
    if type(meta) ~= 'string' then
        return false, eCoreErr.no_valid_meta_name
    end
    local mk = hf.trim(meta)
    if mk == '' then
        return false, eCoreErr.no_valid_meta_name
    end
    return ECO.meta[mk]
end

--- Returns current client-side labor value if available.
--- @return boolean|number ok, laborValue or false, eCoreErr
function getLabor()
    if not Config.systemMode.labor then
        return false, eCoreErr.the_system_is_turned_off
    end
    if not ECO.meta or not ECO.meta.labor then
        return false, eCoreErr.not_found_metadata
    end
    local labor = ECO.meta.labor
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

    while not nuiReady do
        Wait(1000)
        cLog('NUI INIT', 'Wait', 2)
    end

    -- INIT MESSAGE
    SendNUIMessage({ action = 'INIT',
                     metadata = ECO.meta,
                     levels = Config.levels,
                     locale = locales[Config.locale],
                     laborLimit = Config.laborLimit,
                     abilityLimit = Config.abilityLimit,
                     displayComponent = Config.displayComponent,
                   })

    cLog('NUI INIT', 'Loaded...', 2)

    if eCore:isLoggedIn() then
        if nuiReady and Config.systemMode.labor and Config.displayComponent.laborHud then
            SendNUIMessage({ action = 'OPEN', subject = 'hud' })
        end
    end
end

AddEventHandler('e_core:onPlayerLoaded', function()
    if nuiReady and Config.systemMode.labor and Config.displayComponent.laborHud then
        SendNUIMessage({ action = 'OPEN', subject = 'hud' })
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if eCore:isLoggedIn() then
            TriggerServerEvent('e_core:loadMeta')
        end
    end
end)

AddEventHandler('e_core:isPauseMenuActive', function(isPaused)
    if isPaused then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'CLOSE', subject = 'all' })
    else

        if eCore:isLoggedIn() and Config.systemMode.labor and Config.displayComponent.laborHud then
            SendNUIMessage({ action = 'OPEN', subject = 'hud' })
        end
    end
end)

AddEventHandler('e_core:onPlayerUnload', function()
    ECO.meta = {}

    init = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'CLOSE', subject = 'all' })
end)

RegisterNetEvent('e_core:sync', function(meta)
    if type(meta) ~= 'table' then
        cLog('e_core:sync', 'ignored: payload is not a table', 2)
        return
    end
    ECO.meta = meta

    if not init then
        init = true
        nuiInit()
    end

    if nuiReady then
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
    nuiReady = true
    ECO.nuiReady = true
    cb('ok')
end)

RegisterNUICallback('exit', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

if Config.enableStatMenu then
    RegisterKeyMapping('openMeta', 'View Skills', 'keyboard', Config.keyBind.openStat)

    RegisterCommand('openMeta', function()
        if not nuiReady then
            cLog('command openMeta', 'Waiting for NUI load', 2)
            return false
        end

        if not IsNuiFocused() then
            SetNuiFocus(true, true)
            SendNUIMessage({ action = 'OPEN', subject = 'page', metadata = ECO.meta })
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
