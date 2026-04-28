--- Integrity domain (server): side-effect bootstrap only.
--- Event registrations are kept here; domain behavior lives in `logic.lua`.
local integrity = lib.require('src/runtime/integrity/logic')

RegisterNetEvent('e_core:integrityCheck:request', function(opts)
    integrity.onIntegrityRequest(source, opts)
end)

RegisterNetEvent('e_core:integrityCheck:progressResult', function(success)
    integrity.onIntegrityProgressResult(source, success == true)
end)
