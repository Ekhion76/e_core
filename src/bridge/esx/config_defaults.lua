--- ESX bridge alap config – csak `e_core_apply_esx_config()` hívja a `bridge/framework_config.lua`.
function e_core_apply_esx_config()
    FRAMEWORK = 'esx'
    local esx_resource = ecore_framework_resource_esx()
    ESX = exports[esx_resource]:getSharedObject()
    eCore = {}
    Config = {}

    Config.maxInventoryWeight = GetConvarInt('inventory:weight', ESX.GetConfig().MaxWeight * 1000)
    Config.maxInventorySlots = GetConvarInt('inventory:slots', 50)

    Config.imagePath = '/'

    Config.itemBox = false

    Config.totalStackWeight = false

    Config.fields = {
        name = 'name',
        count = 'count',
        slot = 'slot',
        weight = 'weight',
        serial = 'serial'
    }
end
