-- Extension point: `is_ui` + `inside_scripts` client (`client.lua`) bind to this global.
-- Keep only layer-specific `Config.*` values here; inventory / `Config.web` / diagnostics
-- belong to another override or `standalone/config/main.lua`.
INSIDE_SCRIPTS_UI = GetResourceState('is_ui') == 'started'
if INSIDE_SCRIPTS_UI then
    -- example: Config.something = true
end