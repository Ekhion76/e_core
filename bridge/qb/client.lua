if QB_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- copy it to the standalone/ directory and modify it there!
    -- this way, your changes will not be lost in future e_core updates

    local hf = hf

    function eCore:triggerCallback(name, callback, ...)

        QBCore.Functions.TriggerCallback(name, callback, ...)
    end

    function eCore:sendMessage(message, mType, mSec, image)

        --TriggerEvent('QBCore:Notify', message, mType, mSec)
        QBCore.Functions.Notify(message, mType, mSec) -- CHANGE ME
    end

    function eCore:drawText(message, position, mType)

        TriggerEvent('qb-core:client:DrawText', message, position) -- CHANGE ME
    end

    function eCore:hideText()

        TriggerEvent('qb-core:client:HideText') -- CHANGE ME
    end

    function eCore:progressbar(params)

        if params.animation then

            params.animation = {
                animDict = params.animation.dict,
                anim = params.animation.anim,
                flags = params.animation.flag,
            }
        end

        exports['progressbar']:Progress(
            {
                name = params.name:lower(),
                duration = params.duration,
                label = params.label,
                useWhileDead = params.useWhileDead,
                canCancel = params.canCancel,
                controlDisables = params.controlDisables,
                animation = params.animation,
                prop = params.prop,
                propTwo = params.propTwo,
            },
            function(cancelled)
                if not cancelled then
                    if params.onFinish then
                        params.onFinish()
                    end
                else
                    if params.onCancel then
                        params.onCancel()
                    end
                end
            end)
    end

    function eCore:cancelProgressbar()

        TriggerEvent("progressbar:client:cancel")
    end

    function eCore:addTargetModel(models, options)

        exports['qb-target']:AddTargetModel(models, options)
    end

    function eCore:removeTargetModel(obj, labels)

        -- if you use ox_target, don't change it. ox_target recognizes the qb-target export and converts it!
        exports['qb-target']:RemoveTargetModel(obj, labels)
    end

    function eCore:addTargetEntity(obj, options)

        -- if you use ox_target, don't change it. ox_target recognizes the qb-target export and converts it!
        exports['qb-target']:AddTargetEntity(obj, options)
    end

    function eCore:removeTargetEntity(obj, labels)

        -- if you use ox_target, don't change it. ox_target recognizes the qb-target export and converts it!
        exports['qb-target']:RemoveTargetEntity(obj, labels)
    end

    function eCore:addBoxZone(name, center, length, width, options, targetOptions)

        -- if you use ox_target, don't change it. ox_target recognizes the qb-target export and converts it!
        exports['qb-target']:AddBoxZone(name, center, length, width, options, targetOptions)
    end

    function eCore:removeZone(name)

        -- if you use ox_target, don't change it. ox_target recognizes the qb-target export and converts it!
        exports['qb-target']:RemoveZone(name)
    end

    function eCore:isLoggedIn()

        return LocalPlayer.state['isLoggedIn']
    end

    ------------------------------------------------------------------------
    --- INVENTORY
    ------------------------------------------------------------------------

    function eCore:getInventory(playerData)

        return playerData.items
    end

    function eCore:getPlayerMaxWeight(playerData)

        return Config.maxInventoryWeight
    end

    ------------------------------------------------------------------------
    --- PLAYER
    ------------------------------------------------------------------------

    function eCore:getPlayer()

        return eCore:convertPlayer(QBCore.Functions.GetPlayerData())
    end

    function eCore:getAccounts(playerData, account)

        local convert = { -- ESX2QB
            money = 'cash',
            bank = 'bank',
            black_money = 'crypto'
        }

        account = convert[account]

        if not account then

            return 0
        end

        return playerData.money[account]
    end

    function eCore:canInteract(playerData)

        _PlayerPedId = PlayerPedId()
        -- isLoaded
        -- invBusy
        -- currentWeapon

        return not IsPedCuffed(_PlayerPedId)
            and not IsPauseMenuActive()
            and not IsPedInAnyVehicle(_PlayerPedId, true)
            and not IsPedSwimming(_PlayerPedId)
            and not playerData.metadata['inlaststand']
            and not playerData.metadata['isdead']
            and IsPedOnFoot(_PlayerPedId)
    end

    function eCore:setVehicleProperties(vehicle, props)

        QBCore.Functions.SetVehicleProperties(vehicle, props)
    end

    function eCore:deleteVehicle(vehicle)

        QBCore.Functions.DeleteVehicle(vehicle)
    end

    function eCore:getClosestVehicle(coords)

        return QBCore.Functions.GetClosestVehicle(coords)
    end

end