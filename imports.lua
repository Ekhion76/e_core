OX_INVENTORY = GetResourceState('ox_inventory') == 'started'

if GetResourceState('qb-core') == 'started' then

    FRAMEWORK = 'qb'
end

if GetResourceState('es_extended') == 'started' then

    FRAMEWORK = 'esx'
end

eCore = exports.e_core:getCore()
META_CONFIG = exports.e_core:getConfig()
