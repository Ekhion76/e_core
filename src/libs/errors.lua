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

    inventory_full = 'inventory_full',
    no_items_to_remove = 'no_items_to_remove',
    inventory_is_empty = 'inventory_is_empty',
    not_enough_items = 'not_enough_items',

    there_are_no_items_to_remove = 'there are no items to remove',

    unknown_error = 'unknown_error',

    vehicle_no_plate_data = 'Failed: No data can be retrieved from the vehicle.',

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
    cleanup_job_not_found = 'cleanup_job_not_found',
    cleanup_job_not_resumable = 'cleanup_job_not_resumable',
    cleanup_job_already_running = 'cleanup_job_already_running',
    access_denied = 'access_denied',
}
