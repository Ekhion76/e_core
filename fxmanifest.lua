fx_version 'cerulean'
game 'gta5'
description 'ECO CORE'
version '0.1.14'

shared_scripts {
    '@ox_lib/init.lua',
    'src/imports/sdk/shared/locale.lua',

    'src/bridge/esx/config_defaults.lua',
    'src/bridge/qb/config_defaults.lua',
    'src/bridge/framework_resource_registry.lua',
    'src/bridge/framework_config.lua',
    'src/config/main.lua',
    'src/config/levels.lua',
    'overrides/**/config.lua',

    'src/imports/sdk/shared/utils.lua',
    'src/libs/helper.lua',
    'src/libs/helper_ecore.lua',
    'src/libs/file_event_logger.lua',
    'src/libs/itemconvert_console_sink.lua',
    'src/libs/itemconvert_diag.lua',
    'src/libs/itemconvert_pipeline.lua',
    'src/libs/group_access.lua',
    'src/libs/errors.lua',

    'src/libs/meta.lua',
    'src/locales/*.lua',
    'src/libs/config_check.lua',

    'src/bridge/ecore_lifecycle.lua'
}

client_scripts {
    'src/bridge/global/shared.lua',
    'src/bridge/global/client.lua',

    'src/bridge/esx/shared.lua',
    'src/bridge/qb/shared.lua',

    'src/bridge/esx/client.lua',
    'src/bridge/qb/client.lua',

    'overrides/**/shared.lua',
    'overrides/**/client.lua',

    'src/bridge/global/events/client.lua',
    'src/bridge/esx/events/client.lua',
    'src/bridge/qb/events/client.lua',

    'src/bridge/main.lua',

    'src/runtime/web_bridge/ecore_nui.lua',
    'src/runtime/meta/client.lua',
    'src/runtime/hud/client/registry.lua',
    'src/runtime/bootstrap/client/main.lua',
    'src/runtime/integrity/client_logic.lua',
    'src/runtime/integrity/client.lua',
    'src/runtime/web_bridge/client.lua',
    'src/runtime/admin/client_nui_logic.lua',
    'src/runtime/admin/client_nui_bridge.lua',
    'src/runtime/diagnostics/client_nui_logic.lua',
    'src/runtime/diagnostics/client_nui_bridge.lua',
    'src/runtime/exports/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'src/bridge/global/shared.lua',
    'src/bridge/global/server.lua',

    'src/bridge/esx/shared.lua',
    'src/bridge/qb/shared.lua',

    'src/bridge/esx/server.lua',
    'src/bridge/qb/server.lua',

    'overrides/**/shared.lua',
    'overrides/**/server.lua',

    'src/bridge/global/events/server.lua',
    'src/bridge/esx/events/server.lua',
    'src/bridge/qb/events/server.lua',

    'src/imports/sdk/server/discord_log.lua',

    'src/bridge/main.lua',

    'src/bridge/global/callbacks/server.lua',

    'src/runtime/meta/player_meta_store.lua',
    'src/runtime/bootstrap/server/main.lua',
    'src/runtime/meta/server.lua',
    'src/runtime/meta/logic.lua',
    'src/runtime/meta/init.lua',
    'src/runtime/hud/server/layout.lua',
    'src/runtime/hud/server/logic.lua',
    'src/runtime/hud/server/init.lua',
    'src/runtime/labor/init.lua',
    'src/runtime/quote/server.lua',
    'src/runtime/quote/logic.lua',
    'src/runtime/quote/init.lua',
    'src/runtime/db/migrations.lua',
    'src/runtime/db/server.lua',
    'src/runtime/db/logic.lua',
    'src/runtime/db/init.lua',
    'src/libs/profession_levels.lua',
    'src/runtime/admin/server_denied_audit.lua',
    'src/runtime/professions/server.lua',
    'src/runtime/professions/init.lua',
    'src/runtime/exports/server.lua',
    'src/runtime/integrity/server.lua',
    'src/runtime/diagnostics/server.lua',
    'src/runtime/diagnostics/logic.lua',
    'src/runtime/diagnostics/init.lua',
    'src/runtime/web_bridge/server.lua',
    'src/runtime/admin/server_inventory_sample.lua',
    'src/runtime/admin/server_nui_bridge.lua',
    'src/runtime/diagnostics/server_nui_bridge.lua',
    'src/standalone/usableitem.lua',
}

-- NUI dev: Vite (`npm run dev` a `src/web` mappában). Éles szerveren állíts vissza: `ui_page 'src/web/dist/index.html'` + `npm run build`.
ui_page 'http://127.0.0.1:5173/'

files {
    'src/imports/sdk/shared/core.lua',
    'src/imports/sdk/shared/full_import.lua',
    'src/imports/sdk/shared/locale.lua',
    'src/imports/sdk/shared/utils.lua',
    'src/imports/sdk/shared/helper_base.lua',
    'src/imports/sdk/client/hud_drag.lua',
    'src/imports/sdk/server/discord_log.lua',
    'src/web/dist/**'
}

lua54 'yes'

dependencies {
    'ox_lib',
    'oxmysql'
}
