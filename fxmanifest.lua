fx_version 'cerulean'
game 'gta5'
description 'ECO CORE'
version '0.1.13'

shared_scripts {
    '@ox_lib/init.lua',
    'src/imports/shared/locale.lua',

    'src/bridge/esx/config_defaults.lua',
    'src/bridge/qb/config_defaults.lua',
    'src/bridge/framework_resource_registry.lua',
    'src/bridge/framework_config.lua',
    'src/standalone/config/main.lua',
    'src/standalone/config/levels.lua',
    'overrides/**/config.lua',

    'src/imports/shared/utils.lua',
    'src/libs/helper.lua',
    'src/libs/helper_ecore.lua',
    'src/libs/file_event_logger.lua',
    'src/libs/itemconvert_console_sink.lua',
    'src/libs/itemconvert_diag.lua',
    'src/libs/itemconvert_pipeline.lua',
    'src/libs/GroupAccess.lua',
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

    'src/client/ecore_nui.lua',
    'src/client/client_meta_store.lua',
    'src/client/hud_layout_registry.lua',
    'src/client/main.lua',
    'src/client/integrity_check.lua',
    'src/client/web.lua',
    'src/client/nui_admin_bridge.lua',
    'src/client/nui_diagnostics_bridge.lua',
    'src/client/exports.lua',
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

    'src/imports/server/discord_log.lua',

    'src/bridge/main.lua',

    'src/bridge/global/callbacks/server.lua',

    'src/server/player_meta_store.lua',
    'src/server/main.lua',
    'src/server/meta.lua',
    'src/server/hud_layout.lua',
    'src/server/labor.lua',
    'src/server/quote.lua',
    'src/server/db_migrations.lua',
    'src/libs/profession_levels.lua',
    'src/server/admin_denied_audit.lua',
    'src/server/professions.lua',
    'src/server/db.lua',
    'src/server/exports.lua',
    'src/server/integrity_check.lua',
    'src/server/diagnostics.lua',
    'src/server/web.lua',
    'src/server/admin_inventory_sample.lua',
    'src/server/nui_admin_bridge.lua',
    'src/server/nui_diagnostics_bridge.lua',
    'src/standalone/usableitem.lua',
}

-- NUI dev: Vite (`npm run dev` a `src/web` mappában). Éles szerveren állíts vissza: `ui_page 'src/web/dist/index.html'` + `npm run build`.
ui_page 'http://127.0.0.1:5173/'

files {
    'src/imports/shared/core.lua',
    'src/imports/shared/full_import.lua',
    'src/imports/shared/locale.lua',
    'src/imports/shared/utils.lua',
    'src/imports/shared/helper_base.lua',
    'src/imports/client/hud_drag.lua',
    'src/imports/server/discord_log.lua',
    'src/web/dist/**'
}

lua54 'yes'

dependencies {
    'ox_lib',
    'oxmysql'
}
