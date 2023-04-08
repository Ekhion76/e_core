-- SERVER EVENTS:

QBEvents = sharedEvents

table.insert(QBEvents, {
    name = 'QBCore:Server:PlayerLoaded',
    method = function(xPlayer)
        xPlayer = FUNCTIONS.convertPlayer(xPlayer)
        TriggerEvent('e_core:playerLoaded', xPlayer)
    end
})

table.insert(QBEvents, {
    name = 'QBCore:Server:OnPlayerUnload',
    method = function(playerId)
        TriggerEvent('e_core:onPlayerUnload', playerId)
    end
})
