if ESX_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- copy it to the standalone/ directory and modify it there!
    -- this way, your changes will not be lost in future e_core updates

    local hf = hf

    function eCore:triggerCallback(name, callback, ...)

        ESX.TriggerServerCallback(name, callback, ...)
    end

    function eCore:sendMessage(message, mType, mSec)

        ESX.ShowNotification(message, mSec, mType)
    end

    function eCore:drawText(message, position, mType)

        ESX.TextUI(message, mType)
    end

    function eCore:hideText()

        ESX.HideUI()
    end

    function eCore:progressbar(params)

        if params.animation then

            params.animation = {
                dict = params.animation.dict,
                lib = params.animation.anim,
                type = "anim"
            }
        end

        ESX.Progressbar(params.label, params.duration, {
            animation = params.animation,
            onFinish = params.onFinish,
            onCancel = params.onCancel,
        })
    end

    function eCore:cancelProgressbar()

        ExecuteCommand("cancelprog")
    end

    function eCore:addTargetEntity(obj, options)

        -- if you use ox_target, don't change it. ox_target recognizes the qtarget export and converts it!
        exports['qtarget']:AddTargetEntity(obj, options)
    end

    function eCore:addBoxZone(name, center, length, width, options, targetOptions)

        -- if you use ox_target, don't change it. ox_target recognizes the qtarget export and converts it!
        exports['qtarget']:AddBoxZone(name, center, length, width, options, targetOptions)
    end

    function eCore:removeZone(name)

        -- if you use ox_target, don't change it. ox_target recognizes the qtarget export and converts it!
        exports['qtarget']:RemoveZone(name)
    end

    function eCore:isLoggedIn()

        return ESX.PlayerLoaded
    end

    ------------------------------------------------------------------------
    --- INVENTORY
    ------------------------------------------------------------------------

    function eCore:getInventory(playerData)

        return playerData.inventory
    end

    --- It returns the entire registered item list
    ---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
    function eCore:getRegisteredItems()

        if REGISTERED_ITEMS then

            return REGISTERED_ITEMS
        end

        return self:convertItems(ESX.GetPlayerData().inventory)
    end

    ------------------------------------------------------------------------
    --- PLAYER
    ------------------------------------------------------------------------

    function eCore:getPlayer()

        return self:convertPlayer(ESX.GetPlayerData())
    end

    function eCore:getAccounts(playerData, account)

        for i = 1, #(playerData.accounts) do

            if playerData.accounts[i].name == account then

                return playerData.accounts[i].money
            end
        end

        return 0
    end

    function eCore:canInteract(playerData)

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

    function eCore:setVehicleProperties(vehicle, props)

        ESX.Game.SetVehicleProperties(vehicle, props)
    end

    function eCore:deleteVehicle(vehicle)

        ESX.Game.DeleteVehicle(vehicle)
    end

    function eCore:getClosestVehicle(coords)

        return ESX.Game.GetClosestVehicle(coords)
    end
end
