if HUD17 then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here
    local progressCancelRequired

    function eCore:progressbar(params)
        progressCancelRequired = false

        if not params.animation then
            params.animation = {}
        end

        TriggerEvent("17mov_Hud:StartProgress", {
            duration = params.duration,
            label = params.label,
            useWhileDead = params.useWhileDead,
            canCancel = params.canCancel,
            controlDisables = params.controlDisables,
            animation = {
                animDict = params.animation.dict,
                anim = params.animation.anim,
                flags = params.animation.flag or 0,
                task = params.animation.scenario
            },
            prop = params.prop,
            propTwo = params.propTwo,
        }, nil, nil, function(canceled)
            if canceled or progressCancelRequired then
                if params.onCancel then
                    params.onCancel()
                end
            else
                if params.onFinish then
                    params.onFinish()
                end
            end
        end)
    end

    function eCore:cancelProgressbar()
        progressCancelRequired = true
        TriggerEvent("17mov_Hud:StopProgress")
    end

    function eCore:sendMessage(message, mType, mSec)
        TriggerEvent("17mov_Hud:ShowNotification", message, mType, '', mSec)
    end

    function eCore:drawText(message, position, mType)
		TriggerEvent("17mov_Hud:ShowHelpNotification", message)
    end

    function eCore:hideText()
        TriggerEvent("17mov_Hud:HideHelpNotification")
    end
end