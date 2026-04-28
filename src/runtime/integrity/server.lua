--- Integrity domain module (server): pure module, no side effects.
--- Event registrations are performed from `init.lua`.
local integrity = lib.require('src/runtime/integrity/logic')

local M = {}

--- Registers integrity server net events.
--- @return nil
function M.registerServerEvents()
    RegisterNetEvent('e_core:integrityCheck:request', function(opts)
        integrity.onIntegrityRequest(source, opts)
    end)

    RegisterNetEvent('e_core:integrityCheck:progressResult', function(success)
        integrity.onIntegrityProgressResult(source, success == true)
    end)
end

return M
