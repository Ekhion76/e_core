--- Központi ok / hiba stringek: `return false, eCoreErr.xyz` – az értékek backward compatible-ek maradnak.
--- Consumer resource-ok továbbra is ezekkel a literálokkal összehasonlíthatnak (lásd `docs/PUBLIC_API_HU.md`).
eCoreErr = {
    ok = 'ok',

    too_heavy = 'too_heavy',
    not_enough_space = 'not_enough_space',

    --- `canCarryItem` / `canSwapItems`: `itemData` vagy swap sor nem tábla, hiányzó / üres név (trim után), `amount` nem pozitív szám.
    invalid_item_data = 'invalid_item_data',
    --- `canCarryItem` / `canSwapItems`: az item név nincs a `REGISTERED_ITEMS` listában (a súly/slot logika nem értelmezhető).
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
    --- `removeLabor`: a levonandó mennyiség nagyobb, mint az aktuális egyenleg.
    not_enough_labor = 'not_enough_labor',
    has_already_reached_the_limit = 'has_already_reached_the_limit',

    --- `getDiscounts` / `getLevel`: üres vagy hiányzó `Config.levels` (shared `libs/meta.lua`).
    not_levels_data = 'not_levels_data',

    category_does_not_exist = 'category_does_not_exist',
    meta_does_not_exist = 'meta_does_not_exist',

    -- login / logout / labor: core gyökér; nem registerMeta / setMeta / jártasság export.
    reserved_meta_category = 'reserved_meta_category',
    -- registerMeta 3. param: csak nil vagy tábla.
    meta_default_must_be_table = 'meta_default_must_be_table',
    -- setMeta érték: csak tábla.
    meta_value_must_be_table = 'meta_value_must_be_table',
    -- Meglévő kategória slot nem tábla (sérült adat).
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
