--- Overrides bridge functions
--- Do not overwrite the bridge files.
--- Copy the function you want to modify here

-- messages
-- function eCore:hideText() end
-- function eCore:drawText(message, position, mType) end
-- function eCore:sendMessage(message, mType, mSec) end
-- function eCore:progressbar(params)
-- function eCore:cancelProgressbar()

-- function eCore:isLoggedIn()
-- function eCore:triggerCallback(name, callback, ...)

-- function eCore:addTargetEntity(obj, options)
-- function eCore:addBoxZone(name, center, length, width, options, targetOptions)
-- function eCore:removeZone(name)

-- function eCore:getPlayer()
-- function eCore:getAccounts(playerData, account)
-- function eCore:canInteract(playerData)

-- function eCore:setVehicleProperties(vehicle, props)
-- function eCore:deleteVehicle(vehicle)
-- function eCore:getClosestVehicle(coords)

--function eCore:progressbar(params)
--    if params.animation then
--        params.animation = {
--            dict = params.animation.dict,
--            clip = params.animation.anim,
--        }
--    end
--
--    if lib.progressBar({
--        label = params.label,
--        duration = params.duration,
--        position = 'bottom',
--        useWhileDead = params.useWhileDead,
--        canCancel = params.canCancel,
--        disable = { car = true, move = true },
--        anim = params.animation,
--        prop = params.prop,
--    }) then
--        params.onFinish()
--    else
--        params.onCancel()
--    end
--end
--
--function eCore:cancelProgressbar()
--    lib.cancelProgress()
--end