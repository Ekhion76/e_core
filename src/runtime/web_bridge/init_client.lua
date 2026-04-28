--- Web bridge domain init (client): side-effect registration only.
local webBridgeClient = lib.require('src/runtime/web_bridge/client')

webBridgeClient.registerClientHandlers()
