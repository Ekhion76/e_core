local hf = hf

CORE_READY, REGISTERED_ITEMS = nil, nil

CreateThread(function()
    cLog('REGISTERED ITEMS', 'Loading...', 2)

    if hf.awaitItemRegistryReady('REGISTERED ITEMS') then
        cLog('REGISTERED ITEMS', 'Loaded', 2)
    end

    hf.logEcoreStartupSummary('server')
end)
