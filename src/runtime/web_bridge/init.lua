--- Web bridge domain init (server): side-effect registration only.
local webBridgeServer = lib.require('src/runtime/web_bridge/server')

webBridgeServer.registerServerEvents()
