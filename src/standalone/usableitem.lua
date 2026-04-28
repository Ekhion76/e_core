if _ECORE_INIT_FAILED then return end
local localeSdk = lib.require('src/imports/sdk/locale/shared')

eCore:createUsableItem("labor_enhancer", function(source)
    local _source = source
    local xPlayer = eCore:getPlayer(_source)
    local success, reason = exports.e_core:addLabor(_source, 1000)

    if success then
        eCore:sendMessage(_source, localeSdk.translate('labor_increased'), 'success')
        eCore:removeItem(xPlayer, 'labor_enhancer', 1)
    else
        eCore:sendMessage(_source, localeSdk.translate(reason), 'error')
    end
end)