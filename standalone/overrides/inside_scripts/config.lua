-- Bővítési pont: `is_ui` + `inside_scripts` kliens (`client.lua`) ehhez a globális névhez köt.
-- Ide csak ehhez a réteghez tartozó `Config.*` kerüljön; inventory / `Config.web` / diagnostics → más override vagy `main.lua`.
INSIDE_SCRIPTS_UI = GetResourceState('is_ui') == 'started'
if INSIDE_SCRIPTS_UI then
    -- példa: Config.valami = true
end