-- EVENTS:
ESXEvents = sharedEvents

table.insert(ESXEvents, {
    name = 'esx:playerLoaded',
    method = function(playerData, isNew, skin)
        playerData = FUNCTIONS.convertPlayer(playerData)
        TriggerEvent('e_core:onPlayerLoaded', playerData, isNew, skin)
    end
})

table.insert(ESXEvents, {
    name = 'esx:onPlayerLogout',
    method = function(playerId)
        TriggerEvent('e_core:onPlayerUnload', playerId)
    end
})

table.insert(ESXEvents, {
    name = 'esx:setJob',
    method = function(job)
        TriggerEvent('e_core:onJobUpdate', job)
    end
})

