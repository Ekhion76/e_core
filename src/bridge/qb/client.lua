if QB_CORE then
    -- if you want to rewrite a function, don't do it here!
    -- use `overrides/...` or `src/config/`; do not edit bridge files in place.
    -- this way, your changes will not be lost in future e_core updates
    local hf = lib.require('src/imports/sdk/helper_base/shared')

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param message any
    --- @param mType any
    --- @param mSec any
    --- @param image any
    --- @return any result
    function eCore:sendMessage(message, mType, mSec, image)
        --TriggerEvent('QBCore:Notify', message, mType, mSec)
        if mType == 'info' then mType = 'primary' end
        QBCore.Functions.Notify(message, mType, mSec) -- CHANGE ME
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param message any
    --- @param position any
    --- @param mType any
    --- @return any result
    function eCore:drawText(message, position, mType)
        if mType == 'info' then mType = 'primary' end
        TriggerEvent(('%s:client:DrawText'):format(ecore_framework_resource_qb()), message, position) -- CHANGE ME if event namespace differs
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @return any result
    function eCore:hideText()
        TriggerEvent(('%s:client:HideText'):format(ecore_framework_resource_qb())) -- CHANGE ME if event namespace differs
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param params table
    --- @return any result
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
                controlDisables = params.controlDisables or {},
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

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @return any result
    function eCore:cancelProgressbar()
        TriggerEvent("progressbar:client:cancel")
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @return any result
    function eCore:isLoggedIn()
        return LocalPlayer.state['isLoggedIn']
    end

    ------------------------------------------------------------------------
    --- INVENTORY
    ------------------------------------------------------------------------

    function eCore:getInventory(playerData)
        return playerData.items
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param playerData any
    --- @return any result
    function eCore:getPlayerMaxWeight(playerData)
        return Config.maxInventoryWeight
    end

    ------------------------------------------------------------------------
    --- PLAYER
    ------------------------------------------------------------------------

    function eCore:getPlayer(newJob, newGang)
        return eCore:convertPlayer(QBCore.Functions.GetPlayerData(), newJob, newGang)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param playerData any
    --- @param account any
    --- @return any result
    function eCore:getAccounts(playerData, account)
        local convert = { -- ESX2QB
            money = 'cash',
            black_money = 'crypto'
        }

        account = convert[account] and convert[account] or account
        return playerData.money[account]
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
            and not IsPedInAnyVehicle(_PlayerPedId, true)
            and not IsPedSwimming(_PlayerPedId)
            and not playerData.metadata['inlaststand']
            and not playerData.metadata['isdead']
            and IsPedOnFoot(_PlayerPedId)
    end

    --- Sets local fuel via `qb-fuel` when validation passes.
    --- @param vehicle number Vehicle entity handle.
    --- @param amount any Numeric fuel level (must pass `tonumber`).
    --- @return boolean ok `true` when fuel was set.
    --- @return string|nil reason `eCoreErr.not_valid_amount` or `eCoreErr.invalid_vehicle_entity` on failure.
    function eCore:setFuelLevel(vehicle, amount)
        if not tonumber(amount) then
            return false, eCoreErr.not_valid_amount
        end
        if not DoesEntityExist(vehicle) then
            return false, eCoreErr.invalid_vehicle_entity
        end
        exports['qb-fuel']:SetFuel(vehicle, amount + 0.0)
        return true
    end

    --- Triggers QB-style client keys ownership for the normalized plate.
    --- @param rawPlate any Plate string from props or UI.
    --- @param vehicle any Optional vehicle entity (reserved for stack-specific keys scripts).
    --- @return boolean ok `true` when plate is non-empty after checks.
    --- @return string|nil reason `eCoreErr.invalid_vehicle_plate` when plate is empty.
    function eCore:vehicleKeys(rawPlate, vehicle)
        if not hf.hasContent(rawPlate) then
            return false, eCoreErr.invalid_vehicle_plate
        end
        local plate = hf.alphaNum(rawPlate)
        TriggerEvent("vehiclekeys:client:SetOwner", plate)
        return true
    end

    --- Applies QBCore vehicle properties to an existing local entity.
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
        QBCore.Functions.SetVehicleProperties(vehicle, props)
        return true
    end

    --- Waits briefly for `netId` to resolve, then applies QBCore vehicle properties and optional fuel.
    --- @param netId number Network id from server spawn flow.
    --- @param props table Non-empty property table (`hf.hasEntries`).
    --- @return boolean ok `true` when properties were applied (fuel errors are swallowed; see `setFuelLevel`).
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

                    QBCore.Functions.SetVehicleProperties(vehicle, props)

                    if props.fuelLevel ~= nil then
                        eCore:setFuelLevel(vehicle, props.fuelLevel)
                    end
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
        QBCore.Functions.DeleteVehicle(vehicle)
    end

    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param coords any
    --- @return any result
    function eCore:getClosestVehicle(coords)
        return QBCore.Functions.GetClosestVehicle(coords)
    end
end
