fx_version 'cerulean'
game 'gta5'
description 'ECO CORE'
version '0.0.49'

shared_scripts {
    '@ox_lib/init.lua',
    'imports/locale.lua',

    'bridge/esx/config_defaults.lua',
    'bridge/qb/config_defaults.lua',
    'bridge/framework_config.lua',
    'standalone/config/main.lua',
    'standalone/config/levels.lua',
    'standalone/overrides/**/config.lua',

    'imports/utils.lua',
    'libs/helper.lua',
    'libs/helper_ecore.lua',
    'libs/errors.lua',

    'libs/meta.lua',
    'locales/*.lua',
    'libs/config_check.lua'
}

client_scripts {
    'bridge/global/shared.lua',
    'bridge/global/client.lua',

    'bridge/esx/shared.lua',
    'bridge/qb/shared.lua',

    'bridge/esx/client.lua',
    'bridge/qb/client.lua',

    'standalone/overrides/**/shared.lua',
    'standalone/overrides/**/client.lua',

    'bridge/global/events/client.lua',
    'bridge/esx/events/client.lua',
    'bridge/qb/events/client.lua',

    'bridge/main.lua',

    'client/main.lua',
    'client/diagnostics.lua',
    'client/exports.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'bridge/global/shared.lua',
    'bridge/global/server.lua',

    'bridge/esx/shared.lua',
    'bridge/qb/shared.lua',

    'bridge/esx/server.lua',
    'bridge/qb/server.lua',

    'standalone/overrides/**/shared.lua',
    'standalone/overrides/**/server.lua',

    'bridge/global/events/server.lua',
    'bridge/esx/events/server.lua',
    'bridge/qb/events/server.lua',

    'bridge/main.lua',

    'imports/discordlog.lua',

    'bridge/global/callbacks/server.lua',

    'server/main.lua',
    'server/meta.lua',
    'server/labor.lua',
    'server/quote.lua',
    'server/db_migrations.lua',
    'server/db.lua',
    'server/exports.lua',
    'server/diagnostics.lua',
    'standalone/usableitem.lua',
}

ui_page 'html/ui.html'

files {
    'imports/core.lua',
    'html/ui.html',
    'html/main.css',
    'html/js/model.js',
    'html/js/view.js',
    'html/js/diagnostics.js',
    'html/js/app.js',
    'html/img/*.png'
}

lua54 'yes'

dependencies {
    'oxmysql'
}