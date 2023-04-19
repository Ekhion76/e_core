locales = locales or {}
locales['hu'] = {
    --Crafting:
    chemist = 'Vegyész',
    cooking = 'Szakács, italkészítő',
    weaponry = 'Fegyverkovács',
    handicraft = 'Kézműves',
    foundry = 'Öntöde',

    machining = 'Gépész',
    metalwork = 'Lakatos',
    printing = 'Nyomdász',
    masonry = 'Kőműves',
    tailoring = 'Szabó',
    leatherwork = 'Bőrös',
    carpentry = 'Ács',

    -- Harvesting
    husbandry = 'Állattenyésztés',
    farming = 'Földművelés',
    fishing = 'Horgászat',
    logging = 'Fakitermelés',
    gathering = 'Gyüjtögetés',
    mining = 'Bányászat',

    -- Special
    driving_distance = 'Levezetett táv',

    -- reputation
    burglar = 'Betörő', -- betörő
    thief = 'Tolvaj', -- tolvaj (betörővel összevonni?) -- Ház rablások
    car_thief = 'Autó tolvaj', -- autó feltörés, beindítás kulcs nélkül (csalással, autócserékkel befolyásolható)
    robber = 'Rabló', -- Kis boltrablások
    safe_cracker = 'Széf törő', -- lock_breaker -- feltört bank és bolt zárak, kifurt trezorok

    hitman = 'Bérgyilkos', -- bérgyilkos (ha van ilyen meló a szerveren)
    killer = 'Gyilkos', -- gyilkos (bérgyilkossal összevonni?) -- kinyirt emberek után trigger
    weapon_nepper = 'Fegyver nepper', -- erre nincs trigger(inkább a készítésre)
    drug_nepper = 'Drog nepper', -- erre csak az npc-s eladások során van trigger (nem hiteles, mert ha játékosnak adsz el, ez nem nő)
    money_launderer = 'Pénzmosó', -- van trigger(pénz berakás mosásra)
    trader = 'Kereskedő',

    life_saver = 'Életmentő', -- mentős újraélesztések
    punityve = 'Bírságoló', -- büntető, megtorló (rendőrségi bírságolások)

    -- category
    crafting = 'Kézművesség',
    harvesting = 'Betakarítás',
    special = 'Speciális',
    reputation = 'Hírnév',

    level_up = 'Szakmai szintlépés!',

    -- Levels
    level0 = '',
    level1 = 'Novice',
    level2 = 'Veteran',
    level3 = 'Expert',
    level4 = 'Master',
    level5 = 'Authority',
    level6 = 'Champion',
    level7 = 'Adept',
    level8 = 'Herald',
    level9 = 'Virtuoso',
    level10 = 'Celebrity',
    level11 = 'Famed',


    not_found_metadata = 'Nincs meta adat',
    not_valid_amount = 'Nincs megadva érték',
    has_already_reached_the_limit = 'Az érték már elérte a határt',
    the_system_is_turned_off = 'A rendszer ki van kapcsolva',
    not_levels_data = 'Nincsenek szintek(rangok) megadva',

    labor_increased = 'Munkapontot kaptál',
    proficiency_added = 'Jártasságot szereztél',


    no_items_to_remove = 'Nincs törölhető tárgy',
    inventory_is_empty = 'A tároló üres'
}
