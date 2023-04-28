fx_version 'cerulean'

game 'gta5'

description 'ECO CORE'

version '0.0.2'

shared_scripts {
    'bridge/**/config.lua',
    'config/main.lua',
    'config/levels.lua',
    'standalone/**/config.lua',

    'libs/functions.lua',
    'libs/helper.lua',

    'libs/meta.lua',
    'locales/*.lua',
}

client_scripts {
    'bridge/global/shared.lua',
    'bridge/global/client.lua',

    'bridge/esx/shared.lua',
    'bridge/qb/shared.lua',

    'bridge/esx/client.lua',
    'bridge/qb/client.lua',

    'standalone/**/shared.lua',
    'standalone/**/client.lua',

    'bridge/global/events/client.lua',
    'bridge/esx/events/client.lua',
    'bridge/qb/events/client.lua',

    'bridge/main.lua',

    'client/main.lua',
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

    'standalone/**/shared.lua',
    'standalone/**/server.lua',

    'bridge/global/events/server.lua',
    'bridge/esx/events/server.lua',
    'bridge/qb/events/server.lua',

    'bridge/main.lua',

    'bridge/global/callbacks/server.lua',

    'server/main.lua',
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