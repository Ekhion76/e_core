-- Documentation:
-- readme.md file or https://github.com/Ekhion76/e_core
Config.locale = 'en'

Config.debugLevel = false -- 0-4, false or 0 = off

Config.maxInventoryWeight = 24000 -- src/bridge/esx|qb/config_defaults.lua + framework_config.lua, or overrides/.../config.lua
Config.maxInventorySlots = 41 -- same source as above

Config.versionCheck = true

--[[
  Operator settings (`Config.operator`):

  • `identifiers` - shared identifier list (`GetPlayerIdentifiers`), e.g. `'fivem:…'`, `'license:…'`.
  • `admin` - in-game admin NUI (default command `ecore_admin`, ACE `ecore.admin`). Legacy key: `web`.
  • `integrityCheck` - integrity checklist + progress (run from admin NUI -> Integrity tab);
    if `admin.enabled`, uses same access as admin NUI (`hf.webConsoleAccess`), otherwise ACE + list.
    Legacy key: `diagnostics`. Optional: `cooldownMs` (between two **full** runs, min 1500 ms, default 1500;
    step-by-step run does not wait for this cooldown).
  • `cleanup` - server admin cleanup policy (`Config.adminApi.cleanup`).
  • `registryDiagnostics` - profession registry admin runs (`Config.adminApi.diagnostics`). Legacy: `adminApi.diagnostics`.
  • `deniedAudit` - denied audit storage. Legacy: `adminApi.deniedAudit`.

  Technical details (cooldown, test item, NUI checklist timing) are fixed in code,
  while interactive test-item values can be changed in the admin Integrity tab.
]]
Config.operator = {
    identifiers = {
        'fivem:754961'
    },
    admin = {
        enabled = true,
        command = 'ecore_admin',
        acePermission = 'ecore.admin',
    },
    integrityCheck = {
        enabled = true,
        acePermission = 'ecore.diagnostics',
        --- Time between two **full** integrity runs (ms). Server enforces min 1500; default 1500.
        --- Single-step (`onlyStep`) runs do not use this cooldown.
        cooldownMs = 1500,
    },
    cleanup = {
        acePermission = 'ecore.admin.cleanup',
        allowServerWithoutSource = true,
    },
    registryDiagnostics = {
        acePermission = 'ecore.admin.diagnostics',
        allowServerWithoutSource = true,
    },
    deniedAudit = {
        enabled = true,
        retentionDays = 30,
        purgeIntervalMinutes = 60,
        maxDeletePerRun = 2000,
    },
}

Config.systemMode = {
    profession = true, -- proficiency system on/off
    labor = true, -- if you turn off the lab, the profession system will automatically turn off.
}

-- Display components in user interface(nui)
Config.displayComponent = {
    statisticsPage = { 'crafting', 'harvesting', 'reputation' }, -- display metadata categories in STATISTICS panel
    icon = false, -- show profession icon in STATISTICS panel. (Add professionName.png to src/web/public/img folder e.g weaponry.png, cooking.png)
    laborHud = false
}

Config.currency = {
    symbol = '$',
    suffix = false -- false: $10 true: 10$
}

-- the labor points is registered by default
-- each script can register its own category using the registerMeta export e.g exports.e_core:registerMeta(playerId, 'harvesting', {})
-- Add default registered meta fields:
Config.metaFields = {
    --crafting = {},
    --harvesting = {},
    --reputation = {},
    --guidebook = {},
    --achievement = {},
}

Config.defaultLabor = 1000 -- Default labor for new players
Config.laborLimit = 5000 -- Max labor points
Config.abilityLimit = 120000 -- Max if the not set levels (eg.: Max proficiency points)

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

Config.enableStatMenu = true -- skill page keyBind(openStat)
Config.keyBind = {
    openStat = 'o', -- Open Skill page
}

-- ECO LOGGER
Config.discordBotName = 'ECOBOT'
Config.discordWebHook = {
    -- labor = 'https://discord.com/api/webhooks/...', -- Bigger increase or labor_enhancer item
}
