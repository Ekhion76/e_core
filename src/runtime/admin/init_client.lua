--- Admin domain init (client): side-effect registration only.
local adminClientBridge = lib.require('src/runtime/admin/client_nui_bridge')

adminClientBridge.registerClientHandlers()
