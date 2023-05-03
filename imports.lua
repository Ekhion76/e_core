if QB_CORE then

    FRAMEWORK = 'qb'
end

if ESX_CORE then

    FRAMEWORK = 'esx'
end

eCore = exports.e_core:getCore()
eCoreConfig = exports.e_core:getConfig()
