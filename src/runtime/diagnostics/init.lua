--- Diagnostics domain init (server): side-effect registration only.
local diagnosticsServerBridge = lib.require('src/runtime/diagnostics/server_nui_bridge')

diagnosticsServerBridge.registerServerEvents()

