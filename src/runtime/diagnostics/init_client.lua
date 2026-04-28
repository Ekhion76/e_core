--- Diagnostics domain init (client): side-effect registration only.
local diagnosticsClientBridge = lib.require('src/runtime/diagnostics/client_nui_bridge')

diagnosticsClientBridge.registerClientHandlers()
