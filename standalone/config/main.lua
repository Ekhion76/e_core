-- Documentation:
-- readme.md file or https://github.com/Ekhion76/e_core
Config.locale = 'en'

Config.debugLevel = false -- 0-4, false or 0 = off

Config.maxInventoryWeight = 24000 -- bridge/esx|qb/config_defaults.lua + framework_config.lua, vagy standalone/overrides/.../config.lua
Config.maxInventorySlots = 41 -- ugyanaz

Config.versionCheck = true

--- Integritás / integráció teszt (parancs). **Alapból ki** – engedélyezéshez `enabled = true` + ACE és/vagy azonosítók.
--- Szerver.cfg példa ACE-hez: `add_ace group.admin ecore.diagnostics allow` majd `add_principal identifier.steam:xxxxx group.admin` vagy használd az `allowedIdentifiers` listát.
Config.diagnostics = {
    enabled = true,
    command = 'ecore_diag',
    --- Üres string = ACE ellenőrzés kikapcsolva (csak azonosító lista vagy konzol). Nem üres = `IsPlayerAceAllowed(source, acePermission)` is elég az engedélyhez.
    acePermission = 'ecore.diagnostics',
    --- `GetPlayerIdentifiers` értékek (kisbetű ajánlott), pl. `steam:...`, `license:...`, `fivem:...`, `discord:...`
    allowedIdentifiers = {},
    cooldownMs = 15000,
    --- `canCarryItem` / opcionális add-remove teszthez (regisztrált item név).
    testItem = 'water',
    testItemAmount = 1,
    --- Ha true: megpróbál +1 itemet adni, majd levonni (élesen óvatosan).
    tryAddRemove = true,
    progressDurationMs = 3000,
    --- Grafikus NUI modál (képernyő közepe). Ha false, csak konzol / notify marad.
    useNui = true,
    --- Ha useNui true: F8 print is (fejlesztőknek). Ha useNui false: mindig printel.
    printToConsole = false,
    --- Checklist lépések közti szünet (ms), hogy a NUI közben újrarajzoljon (0–400).
    uiStepMs = 55,
}

Config.systemMode = {
    profession = true, -- proficiency system on/off
    labor = true, -- if you turn off the lab, the profession system will automatically turn off.
}

-- Display components in user interface(nui)
Config.displayComponent = {
    statisticsPage = { 'crafting', 'harvesting', 'reputation' }, -- display metadata categories in STATISTICS panel
    icon = false, -- show profession icon in STATISTICS panel. (Add professionName.png to html/img folder e.g weaponry.png, cooking.png)
    laborHud = false
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

-- Optional profession-specific progression caps (fallback: Config.abilityLimit)
-- Example:
-- Config.progression = {
--     maxByProfession = {
--         harvesting = {
--             gathering = 80000
--         },
--         crafting = {
--             weaponry = 100000
--         }
--     }
-- }
Config.progression = Config.progression or {
    maxByProfession = {}
}


Config.laborIncreaseTime = 5 -- Default 5 (min), if 0 then turn off automatic labor
Config.laborIncrease = 10 -- Every increaseTime minutes grow so much
Config.laborIncreaseOffline = 10 -- Every increaseTime minutes grow so much, if 0 then turn off automatic OFFLINE labor

Config.enableStatMenu = true -- enable skill page keyBind(openStat)
Config.keyBind = { -- Default RegisterKeyMapping (if useTarget = false)
    openStat = 'o', -- Open Skill page
}

-- ECO LOGGER
Config.discordBotName = 'ECOBOT'
Config.discordWebHook = {
    -- labor = 'https://discord.com/api/webhooks/...', -- Bigger increase or labor_enhancer item
}
