if ESX_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- copy it to the standalone/ directory and modify it there!
    -- this way, your changes will not be lost in future e_core updates
    local hf = hf

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param message any
    --- @param mType any
    --- @param mSec any
    --- @return any result
    function eCore:sendMessage(message, mType, mSec)
        ESX.ShowNotification(message, mSec, mType)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param message any
    --- @param position any
    --- @param mType any
    --- @return any result
    function eCore:drawText(message, position, mType)
        ESX.TextUI(message, mType)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @return any result
    function eCore:hideText()
        ESX.HideUI()
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param params table
    --- @return any result
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

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @return any result
    function eCore:cancelProgressbar()
        ExecuteCommand("cancelprog")
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @return any result
    function eCore:isLoggedIn()
        return ESX.PlayerLoaded
    end

    ------------------------------------------------------------------------
    --- INVENTORY
    ------------------------------------------------------------------------

    function eCore:getInventory(playerData)
        return playerData.inventory
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param playerData any
    --- @return any result
    function eCore:getPlayerMaxWeight(playerData)
        return Config.maxInventoryWeight
    end

    --- Returns the merged registered item catalog when `REGISTERED_ITEMS` is populated by the server/registry wait loop.
    --- Never treats player inventory rows as the global item definition list (wrong semantics and corrupts weight/slot logic).
    --- @return table|boolean items Registry table on success, or `false` when not ready.
    --- @return string|nil reason `eCoreErr.not_ready` when `REGISTERED_ITEMS` is still nil.
    function eCore:getRegisteredItems()
        if REGISTERED_ITEMS then
            return REGISTERED_ITEMS
        end

        -- Szerver oldali katalógus (lib callback): ugyanaz a séma, mint `bridge/esx/server.lua` `getRegisteredItems`-nél; a kliens inventory nem item-definíció lista.
        local fromServer = lib.callback.await('e_core:getRegisteredItems', 12000)
        if type(fromServer) == 'table' and hf.hasEntries(fromServer) then
            return fromServer
        end

        return false, eCoreErr.not_ready
    end

    ------------------------------------------------------------------------
    --- PLAYER
    ------------------------------------------------------------------------

    function eCore:getPlayer(newJob)
        return self:convertPlayer(ESX.GetPlayerData(), newJob)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param playerData any
    --- @param account any
    --- @return any result
    function eCore:getAccounts(playerData, account)
        for i = 1, #(playerData.accounts) do
            if playerData.accounts[i].name == account then
                return playerData.accounts[i].money
            end
        end

        return 0
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param playerData any
    --- @return any result
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

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param vehicle any
    --- @param amount number
    --- @return any result
    function eCore:setFuelLevel(vehicle, amount)
        if not tonumber(amount) or not DoesEntityExist(vehicle) then
            return false
        end
        -- exports['LegacyFuel']:SetFuel(vehicle, amount + 0.0)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param rawPlate any
    --- @param vehicle any
    --- @return any result
    function eCore:vehicleKeys(rawPlate, vehicle)
        if not hf.hasContent(rawPlate) then
            return false
        end
        local plate = hf.alphaNum(rawPlate)
        -- TriggerEvent("vehiclekeys:client:SetOwner", plate)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param vehicle any
    --- @param props table
    --- @return any result
    function eCore:setVehicleProperties(vehicle, props)
        if not hf.hasEntries(props) or not DoesEntityExist(vehicle) then
            return
        end
        ESX.Game.SetVehicleProperties(vehicle, props)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param netId number
    --- @param props table
    --- @return any result
    function eCore:setVehiclePropertiesFromNetId(netId, props)
        if not hf.hasEntries(props) then
            return
        end
        local try = 300
        while try > 0 do
            if NetworkDoesEntityExistWithNetworkId(netId) then
                local vehicle = NetToVeh(netId)
                if DoesEntityExist(vehicle) then
                    if props.anchor ~= nil then
                        SetBoatAnchor(vehicle, props.anchor)
                        SetBoatFrozenWhenAnchored(vehicle, props.anchor)
                    end

                    ESX.Game.SetVehicleProperties(vehicle, props)
                    break
                end
            end
            Wait(0)
            try = try - 1
        end
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param vehicle any
    --- @return any result
    function eCore:deleteVehicle(vehicle)
        ESX.Game.DeleteVehicle(vehicle)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param coords any
    --- @return any result
    function eCore:getClosestVehicle(coords)
        return ESX.Game.GetClosestVehicle(coords)
    end
end
