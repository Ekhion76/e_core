fx_version 'cerulean'
game 'gta5'
description 'ECO CORE'
version '0.0.56'

shared_scripts {
    '@ox_lib/init.lua',
    'src/imports/locale.lua',

    'src/bridge/esx/config_defaults.lua',
    'src/bridge/qb/config_defaults.lua',
    'src/bridge/framework_config.lua',
    'src/standalone/config/main.lua',
    'src/standalone/config/levels.lua',
    'overrides/**/config.lua',

    'src/imports/utils.lua',
    'src/libs/helper.lua',
    'src/libs/helper_ecore.lua',
    'src/libs/errors.lua',

    'src/libs/meta.lua',
    'src/locales/*.lua',
    'src/libs/config_check.lua'
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

    'src/bridge/main.lua',

    'src/imports/discordlog.lua',

    'src/bridge/global/callbacks/server.lua',

    'src/server/main.lua',
    'src/server/meta.lua',
    'src/server/labor.lua',
    'src/server/quote.lua',
    'src/server/db_migrations.lua',
    'src/server/professions.lua',
    'src/server/db.lua',
    'src/server/exports.lua',
    'src/server/integrity_check.lua',
    'src/server/diagnostics.lua',
    'src/server/web.lua',
    'src/server/nui_admin_bridge.lua',
    'src/server/nui_diagnostics_bridge.lua',
    'src/standalone/usableitem.lua',
}

ui_page 'src/web/dist/index.html'

files {
    'src/imports/core.lua',
    'src/web/dist/**'
}

lua54 'yes'

dependencies {
    'ox_lib',
    'oxmysql'
}