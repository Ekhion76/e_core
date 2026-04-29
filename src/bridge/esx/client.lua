if ESX_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- use `overrides/...` or `src/config/`; do not edit bridge files in place.
    -- this way, your changes will not be lost in future e_core updates
    local hf = lib.require('src/imports/sdk/helper_base/shared')

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
            and not IsPedFatallyInjured(_PlayerPedId)     -- ??
            and not IsEntityDead(_PlayerPedId)            -- ??
            and not IsPedInAnyVehicle(_PlayerPedId, true)
            and not IsPedSwimming(_PlayerPedId)
            and IsPedOnFoot(_PlayerPedId)
    end

    --- Sets local fuel level when validation passes (integrate `LegacyFuel` or stack export in overrides if needed).
    --- @param vehicle number Vehicle entity handle.
    --- @param amount any Numeric fuel level (must pass `tonumber`).
    --- @return boolean ok `true` when inputs are valid (fuel export is optional / commented in stock bridge).
    --- @return string|nil reason `eCoreErr.not_valid_amount` or `eCoreErr.invalid_vehicle_entity` on failure.
    function eCore:setFuelLevel(vehicle, amount)
        if not tonumber(amount) then
            return false, eCoreErr.not_valid_amount
        end
        if not DoesEntityExist(vehicle) then
            return false, eCoreErr.invalid_vehicle_entity
        end
        -- exports['LegacyFuel']:SetFuel(vehicle, amount + 0.0)
        return true
    end

    --- Hands off plate to your keys resource (stock bridge leaves the trigger commented).
    --- @param rawPlate any Plate string from props or UI.
    --- @param vehicle any Optional vehicle entity (reserved for stack-specific keys scripts).
    --- @return boolean ok `true` when plate is non-empty after checks.
    --- @return string|nil reason `eCoreErr.invalid_vehicle_plate` when plate is empty.
    function eCore:vehicleKeys(rawPlate, vehicle)
        if not hf.hasContent(rawPlate) then
            return false, eCoreErr.invalid_vehicle_plate
        end
        local plate = hf.alphaNum(rawPlate)
        -- TriggerEvent("vehiclekeys:client:SetOwner", plate)
        return true
    end

    --- Applies ESX vehicle properties to an existing local entity.
    --- @param vehicle number Vehicle entity handle.
    --- @param props table Non-empty property table (`hf.hasEntries`).
    --- @return boolean ok
    --- @return string|nil reason `eCoreErr.invalid_vehicle_props` or `eCoreErr.invalid_vehicle_entity`.
    function eCore:setVehicleProperties(vehicle, props)
        if not hf.hasEntries(props) then
            return false, eCoreErr.invalid_vehicle_props
        end
        if not DoesEntityExist(vehicle) then
            return false, eCoreErr.invalid_vehicle_entity
        end
        ESX.Game.SetVehicleProperties(vehicle, props)
        return true
    end

    --- Waits briefly for `netId` to resolve, then applies ESX vehicle properties (boat anchor optional).
    --- @param netId number Network id from server spawn flow.
    --- @param props table Non-empty property table (`hf.hasEntries`).
    --- @return boolean ok `true` when properties were applied.
    --- @return string|nil reason `eCoreErr.invalid_vehicle_props` or `eCoreErr.vehicle_network_timeout`.
    function eCore:setVehiclePropertiesFromNetId(netId, props)
        if not hf.hasEntries(props) then
            return false, eCoreErr.invalid_vehicle_props
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
                    return true
                end
            end
            Wait(0)
            try = try - 1
        end
        return false, eCoreErr.vehicle_network_timeout
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
