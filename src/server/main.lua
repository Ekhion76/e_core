local hf = hf
local hfe = hfe

CORE_READY, REGISTERED_ITEMS = nil, nil

CreateThread(function()
    cLog('REGISTERED ITEMS', 'Loading...', 2)

    if hfe.awaitItemRegistryReady('REGISTERED ITEMS') then
        cLog('REGISTERED ITEMS', 'Loaded', 2)
    end

    hfe.logEcoreStartupSummary('server')
end)
