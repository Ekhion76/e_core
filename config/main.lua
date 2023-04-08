-- Documentation:
-- readme.md file or https://github.com/Ekhion76/e_core
Config = Config or {}
Config.locale = 'hu'

Config.maxInventoryWeight = 30000 -- IMPORTANT! Used only above the 1.0.0 qb-inventory version, remember to upgrade to current value e.g:(see qb-inventory/config.lua)
Config.maxInventorySlots = 41 -- IMPORTANT! Used only above the 1.0.0 qb-inventory version, remember to upgrade to current value e.g:(see qb-inventory/config.lua)

Config.versionCheck = true
Config.consoleReport = true -- turn on/of nui loaded, dropped recipes, no configure levels, offline labor message

Config.systemMode = {
    profession = true, -- proficiency system on/off
    labor = true, -- if you turn off the lab, the profession system will automatically turn off.
}

-- Display components in user interface(nui)
Config.displayComponent = {
    statisticsPage = { 'crafting', 'harvesting', 'special', 'reputation' }, -- metadata categories
    icon = false, -- show profession icon in STATISTICS panel. (Add professionName.png to html/img folder e.g weaponry.png, cooking.png)
    laborHud = true
}

Config.currency = {
    symbol = '$',
    suffix = false -- false: $10 true: 10$
}

Config.defaultLabor = 1000 -- Default labor for new players
Config.laborLimit = 5000 -- Max labor points
Config.abilityLimit = 120000 -- if the not set levels (eg.: Max proficiency points)


Config.laborIncreaseTime = 5 -- Default 5 (min), if 0 then turn off automatic labor
Config.laborIncrease = 10 -- Every increaseTime minutes grow so much
Config.laborIncreaseOffline = 10 -- Every increaseTime minutes grow so much, if 0 then turn off automatic OFFLINE labor

Config.keyBind = { -- Default RegisterKeyMapping (if useTarget = false)
    openStat = 'i', -- Open Skill page
}

-- ECO LOGGER
Config.discordBotName = 'ECOBOT'
Config.discordWebHook = {
    -- labor = 'https://discord.com/api/webhooks/...', -- Bigger increase or labor_enhancer item
    --labor = 'https://discord.com/api/webhooks/...',
}
