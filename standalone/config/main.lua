-- Documentation:
-- readme.md file or https://github.com/Ekhion76/e_core
Config.locale = 'en'

Config.debugLevel = false -- 0-4, false or 0 = off

Config.maxInventoryWeight = 24000 -- See the bridge/esx|qb/config.lua or standalone/overrides/inventory name/config.lua
Config.maxInventorySlots = 41 -- See the bridge/esx|qb/config.lua or standalone/overrides/inventory name/config.lua

Config.versionCheck = true

Config.systemMode = {
    profession = true, -- proficiency system on/off
    labor = true, -- if you turn off the lab, the profession system will automatically turn off.
}

-- Display components in user interface(nui)
Config.displayComponent = {
    statisticsPage = { 'crafting', 'harvesting', 'reputation' }, -- display metadata categories in STATISTICS panel
    icon = false, -- show profession icon in STATISTICS panel. (Add professionName.png to html/img folder e.g weaponry.png, cooking.png)
    laborHud = true
}

Config.currency = {
    symbol = '$',
    suffix = false -- false: $10 true: 10$
}

-- the labor points is registered by default
-- each script can register its own category using the registerMeta export e.g: exports.e_core:registerMeta(playerId, 'harvesting', {})
-- add default registered meta fields:
Config.metaFields = {
    --crafting = {},
    --harvesting = {},
    --reputation = {},
    --guidebook = {},
    --achievement = {},
}

Config.defaultLabor = 1000 -- Default labor for new players
Config.laborLimit = 5000 -- Max labor points
Config.abilityLimit = 120000 -- if the not set levels (eg.: Max proficiency points)


Config.laborIncreaseTime = 5 -- Default 5 (min), if 0 then turn off automatic labor
Config.laborIncrease = 10 -- Every increaseTime minutes grow so much
Config.laborIncreaseOffline = 10 -- Every increaseTime minutes grow so much, if 0 then turn off automatic OFFLINE labor

Config.keyBind = { -- Default RegisterKeyMapping (if useTarget = false)
    openStat = 'o', -- Open Skill page
}

-- ECO LOGGER
Config.discordBotName = 'ECOBOT'
Config.discordWebHook = {
    -- labor = 'https://discord.com/api/webhooks/...', -- Bigger increase or labor_enhancer item
}
