--- Bootstrap domain (client): side-effect registration only.
--- Runtime behavior lives in `logic.lua`.
local bootstrap = lib.require('src/runtime/bootstrap/client/logic')

CreateThread(function()
    bootstrap.runClientBootstrap()
end)

AddEventHandler('e_core:onPlayerLoaded', function()
    bootstrap.onPlayerLoaded()
end)

AddEventHandler('onResourceStart', function(resource)
    bootstrap.onResourceStart(resource)
end)

AddEventHandler('e_core:isPauseMenuActive', function(isPaused)
    bootstrap.onPauseMenuActive(isPaused)
end)

AddEventHandler('e_core:onPlayerUnload', function()
    bootstrap.onPlayerUnload()
end)

RegisterNetEvent('e_core:sync', function(payload)
    bootstrap.onSync(payload)
end)

RegisterNetEvent('e_core:levelChange', function(data)
    bootstrap.onLevelChange(data)
end)

RegisterNUICallback('nuiReady', function(_, cb)
    bootstrap.onNuiReady(cb)
end)

RegisterNUICallback('exit', function(_, cb)
    bootstrap.onNuiExit(cb)
end)

RegisterNUICallback('hudPreview', function(data, cb)
    bootstrap.onHudPreview(data, cb)
end)

RegisterNUICallback('hudCommit', function(data, cb)
    bootstrap.onHudCommit(data, cb)
end)

RegisterNUICallback('hudEditExit', function(_, cb)
    bootstrap.onHudEditExit(cb)
end)

bootstrap.registerStatMenuCommand()

CreateThread(function()
    bootstrap.runPauseWatcherLoop()
end)
