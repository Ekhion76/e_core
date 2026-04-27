--- One-line consumer bootstrap: loads canonical import chunks from the **e_core** resource in order.
--- Add to your resource `fxmanifest.lua`: `shared_script '@e_core/src/imports/shared/full_import.lua'`
--- Requires: `ensure e_core` before your resource; resource name must stay `e_core` (or edit `ECORE_RES` below).
-- luacheck: push ignore 131

local ECORE_RES = 'e_core'

--- @param rel string Path relative to e_core resource root.
--- @return nil
local function runEcoreChunk(rel)
    local src = LoadResourceFile(ECORE_RES, rel)
    if type(src) ~= 'string' or src == '' then
        error(('[full_import] missing %s in %s'):format(rel, ECORE_RES), 2)
    end
    local chunk, err = load(src, ('@%s/%s'):format(ECORE_RES, rel), 't', _G)
    if not chunk then
        error(('[full_import] load error %s: %s'):format(rel, tostring(err)), 2)
    end
    chunk()
end

runEcoreChunk('src/imports/shared/core.lua')
runEcoreChunk('src/imports/shared/locale.lua')
runEcoreChunk('src/imports/shared/utils.lua')
-- luacheck: pop
