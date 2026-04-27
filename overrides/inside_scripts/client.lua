if not INSIDE_SCRIPTS_UI then return end

-- DOCS: https://inside-scripts.gitbook.io/documentation/paid-scripts/notifications-and-progress/functions
local progressCancelRequired

--- Auto-generated annotation. Refine behavior details if needed.
--- @param params table
--- @return any result
function eCore:progressbar(params)
    progressCancelRequired = false
    local animation, scenario

    if params.animation and params.animation.dict and params.animation.anim then
        animation = {
            dict = params.animation.dict,
            anim = params.animation.anim,
            flag = params.animation.flag or 0,
            blendIn = params.animation.blendIn,
            blendOut = params.animation.blendOut,
            duration = params.animation.duration,
            playbackRate = params.animation.playbackRate,
            lockX = params.animation.lockX,
            lockY = params.animation.lockY,
            lockZ = params.animation.lockZ,
        }
    elseif params.animation and params.animation.scenario then
        scenario = {
            name = params.animation.scenario
        }
    end

    local status = exports["is_ui"]:ProgressBar({
        title = params.label,
        icon = params.icon,
        duration = params.duration,
        useWhileDead = params.useWhileDead,
        canCancel = params.canCancel,
        prop = params.prop,
        animation = animation,
        scenario = scenario,
        disable = params.controlDisables,
    })

    if status == true then
        if params.onFinish then
            params.onFinish()
        end
    elseif status == false then
        if params.onCancel then
            params.onCancel()
        end
    end

end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function eCore:cancelProgressbar()
    progressCancelRequired = true
    exports["is_ui"]:cancelProgressBar()
end


--- Auto-generated annotation. Refine behavior details if needed.
--- @param message any
--- @param mType any
--- @param mSec any
--- @return any result
function eCore:sendMessage(message, mType, mSec) -- mType success or error
    exports["is_ui"]:Notify(nil, message, tonumber(mSec), mType)
end

--     function eCore:drawText(message, position, mType)
    -- No info in docs
--     end

--     function eCore:hideText()
    -- No info in docs
--     end
