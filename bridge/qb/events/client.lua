if QB_CORE then

    QBEvents = sharedEvents

    table.insert(QBEvents, {
        name = 'QBCore:Client:OnPlayerLoaded',
        method = function()
            TriggerEvent('e_core:onPlayerLoaded')
        end
    })

    table.insert(QBEvents, {
        name = 'QBCore:Client:OnPlayerUnload',
        method = function()
            TriggerEvent('e_core:onPlayerUnload')
        end
    })

    table.insert(QBEvents, {
        name = 'QBCore:Client:OnJobUpdate',
        method = function(job)
            TriggerEvent('e_core:onJobUpdate', job)
        end
    })

    table.insert(QBEvents, {
        name = 'QBCore:Client:OnGangUpdate',
        method = function(gang)
            TriggerEvent('e_core:onGangUpdate', gang)
        end
    })
end
