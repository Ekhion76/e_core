--- Integrity domain init (server): side-effect registration only.
local integrityServer = lib.require('src/runtime/integrity/server')

integrityServer.registerServerEvents()
