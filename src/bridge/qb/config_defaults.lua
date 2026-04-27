--- QB bridge alap config – csak `e_core_apply_qb_config()` hívja a `bridge/framework_config.lua`.
function e_core_apply_qb_config()
    FRAMEWORK = 'qb'
    local qb_resource = ecore_framework_resource_qb()
    QBCore = exports[qb_resource]:GetCoreObject()
    eCore = {}
    Config = {}

    Config.maxInventoryWeight = GetConvarInt('inventory:weight', 120000)
    Config.maxInventorySlots = GetConvarInt('inventory:slots', 41)

    Config.imagePath = 'https://cfx-nui-qb-inventory/html/images/'

    Config.itemBox = true

    Config.totalStackWeight = false

    Config.fields = {
        name = 'name',
        count = 'amount',
        slot = 'slot',
        weight = 'weight',
        serial = 'serie'
    }
end
