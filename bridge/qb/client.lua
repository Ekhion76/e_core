function QBCoreBridge()

    local self = {}

    local ox_inventory = false

    if OX_INVENTORY then

        ox_inventory = exports.ox_inventory
    end

    function self.triggerCallback(name, callback, ...)

        QBCore.Functions.TriggerCallback(name, callback, ...)
    end

    function self.sendMessage(message, mType, mSec, image)

        --TriggerEvent('QBCore:Notify', message, mType, mSec)
        QBCore.Functions.Notify(message, mType, mSec) -- CHANGE ME
    end

    function self.drawText(message, position, mType)

        TriggerEvent('qb-core:client:DrawText', message, position) -- CHANGE ME
    end

    function self.hideText()

        TriggerEvent('qb-core:client:HideText') -- CHANGE ME
    end

    function self.progressbar(params)

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

    function self.cancelProgressbar()

        TriggerEvent("progressbar:client:cancel")
    end

    function self.addTargetEntity(obj, options)

        -- if you use ox_target, don't change it. ox_target recognizes the qb-target export and converts it!
        exports['qb-target']:AddTargetEntity(obj, options)
    end

    function self.addBoxZone(name, center, length, width, options, targetOptions)

        -- if you use ox_target, don't change it. ox_target recognizes the qb-target export and converts it!
        exports['qb-target']:AddBoxZone(name, center, length, width, options, targetOptions)
    end

    function self.removeZone(name)

        -- if you use ox_target, don't change it. ox_target recognizes the qb-target export and converts it!
        exports['qb-target']:RemoveZone(name)
    end

    function self.isLoggedIn()

        return LocalPlayer.state['isLoggedIn']
    end

    ------------------------------------------------------------------------
    --- ITEMS
    ------------------------------------------------------------------------

    --- It returns the entire registered item list, unified and filtering out unnecessary information
    --- @return {label: string, image: string}
    function self.getRegisteredItems()

        local items = {}

        if OX_INVENTORY then

            items = FUNCTIONS.convertOxItems(ox_inventory:Items())
        else

            items = FUNCTIONS.convertQbItems(QBCore.Shared.Items)
        end

        return items
    end

    ------------------------------------------------------------------------
    --- INVENTORY
    ------------------------------------------------------------------------

    function self.getInventoryWeight(playerData)

        if OX_INVENTORY then

            return FUNCTIONS.getInventoryWeight(playerData)
        else

            return FUNCTIONS.getInventoryWeight(playerData, true)
        end
    end

    function self.getInventory(playerData)

        return playerData.items
    end

    ------------------------------------------------------------------------
    --- PLAYER
    ------------------------------------------------------------------------

    function self.getPlayer()

        return FUNCTIONS.convertPlayer(QBCore.Functions.GetPlayerData())
    end

    function self.getAccounts(playerData, account)

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

    function self.canInteract(playerData)

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

    function self.setVehicleProperties(vehicle, props)

        QBCore.Functions.SetVehicleProperties(vehicle, props)
    end

    function self.deleteVehicle(vehicle)

        QBCore.Functions.DeleteVehicle(vehicle)
    end

    function self.getClosestVehicle(coords)

        return QBCore.Functions.GetClosestVehicle(coords)
    end

    return self
end