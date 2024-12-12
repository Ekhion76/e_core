OX_LIB = lib and lib.progressBar

if OX_LIB then
    -- these functions override the bridge/global/ and bridge/esx/qb/ functions
    -- if you want to rewrite any function, copy it here and modify it here

    function eCore:progressbar(params)
        if params.animation then
            params.animation = {
                dict = params.animation.dict,
                clip = params.animation.anim,
                flag = params.animation.flag
            }
        end

        if lib.progressBar({
            name = params.name:lower(),
            duration = params.duration,
            label = params.label,
            useWhileDead = params.useWhileDead,
            canCancel = params.canCancel,
            disable = params.controlDisables or {},
            anim = params.animation,
            prop = params.prop
        }) then
            if params.onFinish then
                params.onFinish()
            end
        else
            if params.onCancel then
                params.onCancel()
            end
        end
    end

    function eCore:cancelProgressbar()
        lib.cancelProgress()
    end
end