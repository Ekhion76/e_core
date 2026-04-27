if not HUD17 then return end

-- these functions override the bridge/global/ and bridge/esx/qb/ functions
-- if you want to rewrite any function, copy it here and modify it here
local progressCancelRequired

--- Auto-generated annotation. Refine behavior details if needed.
--- @param params table
--- @return any result
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

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function eCore:cancelProgressbar()
    progressCancelRequired = true
    TriggerEvent("17mov_Hud:StopProgress")
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param message any
--- @param mType any
--- @param mSec any
--- @return any result
function eCore:sendMessage(message, mType, mSec)
    TriggerEvent("17mov_Hud:ShowNotification", message, mType, '', mSec)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param message any
--- @param position any
--- @param mType any
--- @return any result
function eCore:drawText(message, position, mType)
		TriggerEvent("17mov_Hud:ShowHelpNotification", message)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function eCore:hideText()
    TriggerEvent("17mov_Hud:HideHelpNotification")
end
