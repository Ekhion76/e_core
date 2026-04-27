--- Runtime legacy core **resource** names for `exports[...]` and QB DrawText event prefix.
--- Written once from `framework_config.lua` after framework resolution; read via getters (no `_G._ECORE_LEGACY_*`).

local state = {
    esx = 'es_extended',
    qb = 'qb-core',
}

---@param esx string FiveM resource name for ESX legacy core
---@param qb string FiveM resource name for QB legacy core
---@return nil
function ecore_framework_resource_set(esx, qb)
    state.esx = esx
    state.qb = qb
end

---@return string
function ecore_framework_resource_esx()
    return state.esx
end

---@return string
function ecore_framework_resource_qb()
    return state.qb
end
