--- Integrity domain (client): side-effect bootstrap only.
--- Event/NUI callback registrations stay here, behavior lives in `client_logic.lua`.
local integrity = lib.require('src/runtime/integrity/client_logic')

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
