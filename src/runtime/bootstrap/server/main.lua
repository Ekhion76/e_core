local hf = hf
local hfe = hfe

-- `false` indulásig / hiba után; `true` csak sikeres registry után (lásd kliens `main.lua` ugyanilyen komment).
CORE_READY, REGISTERED_ITEMS = false, nil

CreateThread(function()
    cLog('REGISTERED ITEMS', 'Loading...', 2)

    if hfe.awaitItemRegistryReady('REGISTERED ITEMS') then
        cLog('REGISTERED ITEMS', 'Loaded', 2)
    end

    hfe.logEcoreStartupSummary('server')
end)
