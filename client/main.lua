ECO = {}
ECO.meta = {}
local hf = hf

CORE_READY, REGISTERED_ITEMS = nil, nil

CreateThread(function()

    cLog('CLIENT REGISTERED_ITEMS', 'Loading', 2)

    while not hf.isPopulatedTable(REGISTERED_ITEMS) do

        cLog('CLIENT REGISTERED_ITEMS', 'Wait', 2)
        REGISTERED_ITEMS = eCore:getRegisteredItems()
        Wait(1000)
    end

    cLog('CLIENT REGISTERED_ITEMS', 'Loaded', 2)
    cLog('CLIENT CORE', 'READY', 2)
    CORE_READY = true
end)

local nuiReady, init

function serverSync()

end


--- @param category string (optional) category eg.: crafting, reputation, harvesting, special, ...
--- @param name string (optional) subcategory eg.: weaponry, cooking, handicraft, chemist, etc.
--- @return number|table proficiency | all category
function ability(category, name)

    if not ECO.meta[category] then

        return false, 'category_does_not_exist'
    end

    if name then

        return ECO.meta[category][name] and ECO.meta[category][name] or false, 'meta_does_not_exist'
    end

    return ECO.meta[category]
end

----------------
--- CRAFTING ---
----------------

--- @param name string (optional) subcategory eg.: weaponry, cooking, handicraft, chemist, etc.
--- @return number|table proficiency | all category
function getCrafting(name)

    return ability('crafting', name)
end

------------------
--- HARVESTING ---
------------------

--- @param name string (optional) subcategory eg.: husbandry, farming, fishing, logging, gathering, mining, etc.
--- @return number|table proficiency | all category
function getHarvesting(name)

    return ability('harvesting', name)
end

------------------
--- REPUTATION ---
------------------

--- @param name string (optional) subcategory eg.: thief, safe_cracker, money_launderer, life_saver etc.
--- @return number|table proficiency | all category
function getReputation(name)

    return ability('reputation', name)
end

------------
--- META ---
------------

--- @return table all metadata
function getMeta()

    return ECO.meta
end

function getLabor()

    if not Config.systemMode.labor then

        return false, 'the_system_is_turned_off'
    end

    return ECO.meta.labor.val
end

function nuiInit()

    cLog('NUI INIT', 'Loading', 1)

    while not nuiReady do

        Wait(1000)

        cLog('NUI INIT', 'Wait', 1)
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

    cLog('NUI INIT', 'Loaded...')

    if eCore:isLoggedIn() then

        if nuiReady and Config.systemMode.labor and Config.displayComponent.laborHud then

            SendNUIMessage({ action = 'OPEN', subject = 'hud' })
        end
    end
end

RegisterNetEvent('e_core:onPlayerLoaded', function()

    if nuiReady and Config.systemMode.labor and Config.displayComponent.laborHud then

        SendNUIMessage({ action = 'OPEN', subject = 'hud' })
    end

    serverSync()
end)

AddEventHandler('onResourceStart', function(resource)

    if resource == GetCurrentResourceName() then

        if eCore:isLoggedIn() then

            TriggerServerEvent('e_core:loadMeta')
            serverSync()
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

RegisterNetEvent('e_core:onPlayerUnload', function()

    ECO.meta = {}

    init = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'CLOSE', subject = 'all' })
end)

RegisterNetEvent('e_core:sync', function(meta)

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

    SendNUIMessage({ action = 'POPUP', data = data })
end)

-- NUI CALLBACKS
RegisterNUICallback('nuiReady', function(data, cb)

    nuiReady = true
    cb('ok')
end)

RegisterNUICallback('exit', function(data, cb)

    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterKeyMapping('openMeta', 'View Skills', 'keyboard', Config.keyBind.openStat)

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

RegisterCommand('openMeta', function()

    if not nuiReady then

        cLog('command openMeta', 'Waiting for NUI load')
        return false
    end

    if not IsNuiFocused() then

        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'OPEN', subject = 'page', metadata = ECO.meta })
    end
end)

