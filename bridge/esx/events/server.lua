-- SERVER EVENTS:
ESXEvents = sharedEvents

table.insert(ESXEvents, {
    name = 'esx:playerLoaded',
    method = function(playerId, xPlayer, isNew)
        xPlayer = FUNCTIONS.convertPlayer(xPlayer)
        TriggerEvent('e_core:playerLoaded', xPlayer, playerId, isNew)
    end
})

table.insert(ESXEvents, {
    name = 'esx:playerDropped',
    method = function(playerId)
        TriggerEvent('e_core:playerUnload', playerId)
    end
})