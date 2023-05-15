eCore:createUsableItem("labor_enhancer", function(source)

    local _source = source
    local xPlayer = eCore:getPlayer(_source)
    local success, reason = exports.e_core:addLabor(_source, 1000)

    if success then

        eCore:sendMessage(_source, translate('labor_increased'), 'success')
        eCore:removeItem(xPlayer, 'labor_enhancer', 1)
    else

        eCore:sendMessage(_source, translate(reason), 'error')
    end
end)