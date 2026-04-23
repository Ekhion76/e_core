--- Központi ok / hiba stringek: `return false, eCoreErr.xyz` – az értékek backward compatible-ek maradnak.
--- Consumer resource-ok továbbra is ezekkel a literálokkal összehasonlíthatnak (lásd `docs/PUBLIC_API_HU.md`).
eCoreErr = {
    ok = 'ok',

    too_heavy = 'too_heavy',
    not_enough_space = 'not_enough_space',

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
    has_already_reached_the_limit = 'has_already_reached_the_limit',

    category_does_not_exist = 'category_does_not_exist',
    meta_does_not_exist = 'meta_does_not_exist',
}
