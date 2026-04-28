--- Central reason/error string table: `return false, eCoreErr.xyz`.
--- Keep values backward-compatible so consumer resources can keep literal comparisons
--- (see `docs/PUBLIC_API_HU.md`).
eCoreErr = {
    ok = 'ok',

    too_heavy = 'too_heavy',
    not_enough_space = 'not_enough_space',

    --- `canCarryItem` / `canSwapItems`: `itemData` or swap row is not table,
    --- missing/empty name (after trim), or `amount` is not a positive number.
    invalid_item_data = 'invalid_item_data',
    --- `canCarryItem` / `canSwapItems`: item name is not present in `REGISTERED_ITEMS`
    --- (weight/slot logic cannot be resolved).
    item_not_registered = 'item_not_registered',

    --- `eCore:hasItem` (global shared): `itemName` is not a `string` Lua type.
    invalid_item_name = 'invalid_item_name',

    --- ESX `removeItems` `pcall` or inventory override: the stack export raised a Lua error (see server `cLog`).
    inventory_export_exception = 'inventory_export_exception',
    --- ox_inventory / qs_inventory: export returned **false** / falsy without a mapped `eCoreErr` reason string.
    inventory_operation_failed = 'inventory_operation_failed',

    inventory_full = 'inventory_full',
    no_items_to_remove = 'no_items_to_remove',
    inventory_is_empty = 'inventory_is_empty',
    not_enough_items = 'not_enough_items',

    there_are_no_items_to_remove = 'there are no items to remove',

    unknown_error = 'unknown_error',

    --- ESX client `getRegisteredItems`: `REGISTERED_ITEMS` not yet filled (server/registry pipeline); do not use player inventory as item catalog.
    not_ready = 'not_ready',
    --- ESX/QB bridge: no resolved player after `ESX.GetPlayerFromId` / `QBCore.Functions.GetPlayer` (offline id, wrong source, etc.).
    --- Money / inventory: `addMoney`, `removeMoney`, `addItem`, `removeItem`, `removeItems`. Not used where numeric `0` / `{}` contract applies (`getAccounts`, ESX `getInventory` nil, `getInventoryWeight` nil).
    --- Inventory overrides (`ox_inventory` / `qs_inventory` / `avp_grid_inventory` server): missing or invalid `xPlayer.source` (`hf.isValidPlayerSource`).
    invalid_player = 'invalid_player',

    vehicle_no_plate_data = 'Failed: No data can be retrieved from the vehicle.',

    --- Client bridge (`setFuelLevel`): vehicle entity handle does not exist or is not spawned.
    invalid_vehicle_entity = 'invalid_vehicle_entity',
    --- Client bridge (`vehicleKeys`): plate string empty / missing after content checks.
    invalid_vehicle_plate = 'invalid_vehicle_plate',
    --- Client bridge (`setVehicleProperties` / `setVehiclePropertiesFromNetId`): `props` is not a non-empty table.
    --- Server `createVehicle`: `props` was provided but is not a table (must be `nil` or `table`).
    invalid_vehicle_props = 'invalid_vehicle_props',
    --- Client bridge (`setVehiclePropertiesFromNetId`): `netId` did not resolve to an entity within the wait budget.
    vehicle_network_timeout = 'vehicle_network_timeout',

    the_system_is_turned_off = 'the_system_is_turned_off',
    not_found_metadata = 'not_found_metadata',
    no_valid_meta_name = 'no_valid_meta_name',
    not_valid_amount = 'not_valid_amount',
    --- `removeLabor`: requested deduction is greater than current balance.
    not_enough_labor = 'not_enough_labor',
    has_already_reached_the_limit = 'has_already_reached_the_limit',

    --- `getDiscounts` / `getLevel`: empty or missing `Config.levels` (shared `libs/meta.lua`).
    not_levels_data = 'not_levels_data',

    category_does_not_exist = 'category_does_not_exist',
    meta_does_not_exist = 'meta_does_not_exist',

    -- login / logout / labor: core root keys; not writable via registerMeta / setMeta / ability exports.
    reserved_meta_category = 'reserved_meta_category',
    -- registerMeta 3rd param must be nil or table.
    meta_default_must_be_table = 'meta_default_must_be_table',
    -- setMeta value must be table.
    meta_value_must_be_table = 'meta_value_must_be_table',
    -- Existing category slot is not table (corrupted payload).
    meta_category_not_table = 'meta_category_not_table',

    profession_registry_unavailable = 'profession_registry_unavailable',
    profession_category_not_found = 'profession_category_not_found',
    profession_not_found = 'profession_not_found',
    profession_profile_not_found = 'profession_profile_not_found',
    profession_already_exists = 'profession_already_exists',
    --- Embedded in admin diagnostics run results for test `profession-key-validation` when invalid/missing keys were found (not a missing profession row in DB).
    profession_key_validation_failed = 'profession_key_validation_failed',
    cleanup_job_not_found = 'cleanup_job_not_found',
    cleanup_job_not_resumable = 'cleanup_job_not_resumable',
    cleanup_job_already_running = 'cleanup_job_already_running',
    --- `diagnosticsAdminGetRun` / `diagnosticsAdminCancelRun`: no in-memory run for the given `runId`.
    diagnostics_run_not_found = 'diagnostics_run_not_found',
    access_denied = 'access_denied',

    --- Internal cleanup job scan (`cleanup_job_step`): DB scan failed.
    cleanup_scan_failed = 'scan_failed',
    --- `hf.mysqlAwait` / DB init: oxmysql not available.
    mysql_missing = 'mysql_missing',

    --- `hf.adminApiCanAccess`: no `auth.source` when required.
    admin_missing_auth_source = 'Missing auth.source for admin API call.',
    --- `hf.adminApiCanAccess`: invalid or offline `auth.source`.
    admin_invalid_auth_source = 'Invalid auth.source.',
    --- `hf.adminApiCanAccess`: neither configured permission path matched.
    admin_api_policy_denied = 'No permission (admin policy).',
    --- `hf.webConsoleAccess`: invalid or offline player source.
    admin_invalid_web_player = 'Invalid player.',
    --- `hf.webConsoleAccess`: admin NUI disabled in config.
    admin_console_disabled = 'Admin console is disabled (Config.operator.admin.enabled = false).',
    --- `hf.webConsoleAccess`: neither permission field nor allowlist configured.
    admin_web_unconfigured = 'No permission: configure Config.web permission fields or allowedIdentifiers.',
    --- `hf.webConsoleAccess`: configured policy did not allow this player.
    admin_web_denied = 'No permission for admin console (policy or identifier list).',
    --- `adminDeniedAuditList` gate: neither cleanup nor diagnostics admin policy matched.
    admin_audit_dual_policy_denied = 'Nincs jogosultság (cleanup/diagnostics admin policy).',

    --- Integrity checklist (`integrityCanRun` / policy): invalid source.
    integrity_invalid_player = 'Érvénytelen játékos.',
    integrity_check_disabled = 'Az integritás ellenőrzés ki van kapcsolva (Config.integrityCheck.enabled).',
    integrity_cooldown_active = 'Várj a következő futtatás előtt (cooldown).',
    integrity_progress_busy = 'Még fut (vagy elakadt) egy progress teszt – várj, vagy próbáld újra később.',
    integrity_policy_misconfigured = 'Nincs jogosultság: állíts `integrityCheck.acePermission`-t (pl. ecore.diagnostics) és add_ace-et, vagy töltsd az `allowedIdentifiers` listát.',
    integrity_policy_denied = 'Nincs jogosultság (policy vagy azonosító lista).',
}
