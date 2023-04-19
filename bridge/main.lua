eCore = {}

if GetResourceState('qb-core') == 'started' then

    QBCore = exports['qb-core']:GetCoreObject()
    FUNCTIONS = QBCoreFunctions()
    eCore = QBCoreBridge()
    FRAMEWORK = 'qb'

    for i = 1, #QBEvents do

        local event = QBEvents[i]
        RegisterNetEvent(event.name, event.method)
    end
end

if GetResourceState('es_extended') == 'started' then

    ESX = exports['es_extended']:getSharedObject()
    FUNCTIONS = ESXFunctions()
    eCore = ESXBridge()
    FRAMEWORK = 'esx'

    for i = 1, #ESXEvents do

        local event = ESXEvents[i]
        RegisterNetEvent(event.name, event.method)
    end

    if not IsDuplicityVersion() then

        RegisterNetEvent('esx:playerLoaded', function()
            ESX.PlayerLoaded = true
        end)

        RegisterNetEvent('esx:onPlayerLogout', function()
            ESX.PlayerLoaded = false
        end)
    end
end

eCore.helper = hf


exports("getCore", function()

    return eCore
end)