function ESXBridge()

    local self = {}

    local ox_inventory = false

    if OX_INVENTORY then

        ox_inventory = exports.ox_inventory
    end

    function self.triggerCallback(name, callback, ...)

        ESX.TriggerServerCallback(name, callback, ...)
    end

    function self.sendMessage(message, mType, mSec)

        exports.esx_notify:Notify(mType, mSec, message)
    end

    function self.drawText(message, position, mType)

        exports.esx_textui:TextUI(message, mType)
    end

    function self.hideText()

        exports.esx_textui:HideUI()
    end

    function self.progressbar(params)

        if params.animation then

            params.animation = {
                dict = params.animation.dict,
                lib = params.animation.anim,
                type = "anim"
            }
        end

        exports.esx_progressbar:Progressbar(
            params.label,
            params.duration,
            {
                animation = params.animation,
                onFinish = params.onFinish,
                onCancel = params.onCancel,
            }
        )
    end

    function self.cancelProgressbar()

        ExecuteCommand("cancelprog")
    end

    function self.addTargetEntity(obj, options)

        -- if you use ox_target, don't change it. ox_target recognizes the qtarget export and converts it!
        exports['qtarget']:AddTargetEntity(obj, options)
    end

    function self.addBoxZone(name, center, length, width, options, targetOptions)

        -- if you use ox_target, don't change it. ox_target recognizes the qtarget export and converts it!
        exports['qtarget']:AddBoxZone(name, center, length, width, options, targetOptions)
    end

    function self.removeZone(name)

        -- if you use ox_target, don't change it. ox_target recognizes the qtarget export and converts it!
        exports['qtarget']:RemoveZone(name)
    end

    function self.isLoggedIn()

        return ESX.PlayerLoaded
    end

    ------------------------------------------------------------------------
    --- INVENTORY
    ------------------------------------------------------------------------

    function self.getInventoryConfig()

        return INVENTORY_CONFIG
    end

    function self.getInventoryWeight(playerData)

        return FUNCTIONS.getInventoryWeight(playerData)
    end

    function self.getInventory(playerData)

        return playerData.inventory
    end

    function self.getRegisteredItems()

        return REGISTERED_ITEMS
    end

    function self.getAmountOfItems(inventory)

        return FUNCTIONS.getAmountOfItems(inventory)
    end

    function self.canSwapItems(swappingItems, itemData, playerData)

        return FUNCTIONS.canSwapItems(swappingItems, itemData, playerData)
    end

    function self.canCarryItem(itemData, playerData)

        return FUNCTIONS.canCarryItem(itemData, playerData)
    end

    ------------------------------------------------------------------------
    --- PLAYER
    ------------------------------------------------------------------------

    function self.getPlayer()

        return FUNCTIONS.convertPlayer(ESX.GetPlayerData())
    end

    function self.getAccounts(playerData, account)

        for i = 1, #(playerData.accounts) do

            if playerData.accounts[i].name == account then

                return playerData.accounts[i].money
            end
        end

        return 0
    end

    function self.canInteract(playerData)

        _PlayerPedId = PlayerPedId()
        -- isLoaded
        -- invBusy
        -- currentWeapon

        return not IsPedCuffed(_PlayerPedId)
            and not IsPauseMenuActive()
            and not IsPedFatallyInjured(_PlayerPedId) -- ??
            and not IsEntityDead(_PlayerPedId) -- ??
            and not IsPedInAnyVehicle(_PlayerPedId, true)
            and not IsPedSwimming(_PlayerPedId)
            and IsPedOnFoot(_PlayerPedId)
    end

    function self.setVehicleProperties(vehicle, props)

        ESX.Game.SetVehicleProperties(vehicle, props)
    end

    function self.deleteVehicle(vehicle)

        ESX.Game.DeleteVehicle(vehicle)
    end

    function self.getClosestVehicle(coords)

        return ESX.Game.GetClosestVehicle(coords)
    end

    return self
end