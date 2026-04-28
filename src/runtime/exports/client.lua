--- Client-side `exports.e_core:*` registry (contract source: `docs/PUBLIC_API_HU.md` §2).
--- This file intentionally contains thin export bindings only.
--- exports ---
exports("getAbility", getAbility)
exports("getMeta", getMeta)

--- Returns current labor points on client cache.
--- @return number labor Current labor points.
exports("getLabor", getLabor)
local hudDragModule = lib.require('src/imports/sdk/hud_drag/client')


--- SHARED exports --

exports('getLevel', getLevel)
exports('getDiscounts', getDiscounts)

--- Returns e_core runtime configuration table.
--- @return table config Current merged `Config` table.
exports("getConfig", function()

    return Config
end)

--- Returns true when item registry load has completed successfully.
--- @return boolean ready True if core is fully ready for consumers.
exports('isReady', function()

    return eCore:isReady()
end)

--- Registers one HUD element for e_core edit-mode synchronization.
--- @param id string
--- @param data table
--- @return boolean success
--- @return table|string posOrErr
exports('registerHudElement', function(id, data)
    if not eCore or not eCore.UI or type(eCore.UI.RegisterHudElement) ~= 'function' then
        return false, 'hud_api_not_ready'
    end
    return eCore.UI.RegisterHudElement(id, data)
end)

--- Unregisters one HUD element from e_core sync/edit flow.
--- @param id string
--- @return nil
exports('unregisterHudElement', function(id)
    if eCore and eCore.UI and type(eCore.UI.UnregisterHudElement) == 'function' then
        eCore.UI.UnregisterHudElement(id)
    end
end)

--- Creates a new pure HUD drag instance.
--- @return table hudDrag
exports('createHudDrag', function()
    return hudDragModule.new()
end)