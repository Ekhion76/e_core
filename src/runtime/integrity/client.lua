--- Integrity domain module (client): pure module, no side effects.
--- Event/NUI registrations are performed from `init_client.lua`.
local integrity = lib.require('src/runtime/integrity/client_logic')

local M = {}

--- Registers integrity client handlers.
--- @return nil
function M.registerClientHandlers()
    RegisterNetEvent('e_core:integrityCheck:consoleOnly', function(lines)
        integrity.onIntegrityConsoleOnly(lines)
    end)

    RegisterNetEvent('e_core:integrityCheck:nuiPush', function(data)
        integrity.onIntegrityNuiPush(data)
    end)

    RegisterNetEvent('e_core:integrityCheck:clientPrint', function(lines, section, meta)
        integrity.onIntegrityClientPrint(lines, section, meta)
    end)

    RegisterNetEvent('e_core:integrityCheck:progressTest', function(opts)
        integrity.onIntegrityProgressTest(opts)
    end)

    RegisterNUICallback('diagnosticsExit', function(_, cb)
        integrity.onDiagnosticsExit(cb)
    end)

    RegisterNUICallback('integrityDiagnosticsRun', function(data, cb)
        integrity.onIntegrityDiagnosticsRun(data, cb)
    end)
end

return M
