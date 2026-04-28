--- Admin domain init (server): side-effect registration only.
local adminServerBridge = lib.require('src/runtime/admin/server_nui_bridge')

adminServerBridge.registerServerEvents()
