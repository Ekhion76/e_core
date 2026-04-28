--- Bootstrap domain (server): side-effect bootstrap only.
--- Thread registration stays here, wait/log behavior lives in `logic.lua`.
local bootstrap = lib.require('src/runtime/bootstrap/server/logic')

CreateThread(function()
    bootstrap.runServerBootstrap()
end)
