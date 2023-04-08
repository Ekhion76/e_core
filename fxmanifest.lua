fx_version 'cerulean'

game 'gta5'

description 'ECO CORE'

version '0.0.1'

shared_scripts {
    'bridge/config.lua',
    'libs/helper.lua',
    'bridge/esx/functions/shared.lua',
    'bridge/qb/functions/shared.lua',

    'config/main.lua',
    'config/levels.lua',

    'libs/functions.lua',
    'libs/meta.lua',
    'locales/*.lua',
}

client_scripts {
    -- eCore
    'bridge/shared/events/client.lua',
    'bridge/esx/functions/client.lua',
    'bridge/qb/functions/client.lua',

    'bridge/esx/client.lua',
    'bridge/qb/client.lua',

    'bridge/esx/events/client.lua',
    'bridge/qb/events/client.lua',
    'bridge/shared/functions/client.lua',
    'bridge/main.lua',

    'client/main.lua',
    'client/exports.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    -- eCore
    'bridge/shared/events/server.lua',
    'bridge/esx/functions/server.lua',
    'bridge/qb/functions/server.lua',

    'bridge/esx/server.lua',
    'bridge/qb/server.lua',

    'bridge/esx/events/server.lua',
    'bridge/qb/events/server.lua',

    'bridge/shared/functions/server.lua',
    'bridge/main.lua',
    'bridge/shared/callbacks/server.lua',

    'server/meta.lua',
    'server/basemetadata.lua',
    'server/labor.lua',
    'server/db.lua',
    'server/exports.lua',
    'server/usableitem.lua',
}

ui_page 'html/ui.html'

files {
    'imports.lua',
    'html/ui.html',
    'html/main.css',
    'html/js/*.js',
    'html/img/*.png'
}

lua54 'yes'

dependencies {
    'oxmysql'
}