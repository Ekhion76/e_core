# e_core

#### Mire való az e_core?
Az e_core egy adapter, mely az ESX és QBCore, QBox keretrendszerekkel való kompatibilitáshoz nyújt támogatást.

##### Célja:
- eco_crafting és a jövöben készülő szkripteknek biztosítani a keretrendszer független működést 
- a felhasználóknak biztosítani a testreszabhatóságot
- **SDK-szerű réteg:** ne csak belső „glue script” legyen – publikus, dokumentált és verzióhoz kötött felület, amire külső resource-ok és az eco szkriptek egyaránt építhetnek (API-szerződés, changelog, támogatott stack, előre jelezhető indulás és hibák)

##### Csatoló felületet biztosít:
- saját inventory exportjainak beillesztésére (addItem, removeItem, stb..) 
- üzenet rendszerek beillesztésére (sendNotify, drawText, hideText, progressbar)
- ezen kívül különféle core funkciók is illeszthetők a szkriptben látható példák segítségével

##### Tartalmaz:
- egy jártasság(xp) és labor(munkaerő) rendszert, mely egy beépített metaadat tárolót használ.
- lua segédfunkciókat
- fiveM segédfunkciókat

Ha alap szervered van, nincs szükség módosításokra.
Ha ox_inventoryt használsz, nincs szükség módosításokra.

Konfig fájlok:
- src/standalone/config/ - globális beállítások
- overrides/custom_inventory/config.lua - Inventory specifikus beállítások

**FONTOS!** Az e_core-t az eco scriptek előtt szükséges indítani a server.cfg fájlban! A **legacy core** (`es_extended` vagy `qb-core`) az e_core előtt legyen `ensure`-elve, különben üres maradhat a registry indulásig.

Ha véletlenül **mindkét** core futna: `setr e_core:framework "esx"` vagy `"qb"` (alap `auto` ilyenkor **hibával** leáll). Részlet: `docs/FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md`.

```
    # ECO SCRIPTS
    ensure e_core
    ensure eco_crafting
```
**FONTOS!** A későbbi frissítések felülírása miatt minden testreszabást az `overrides/` mappában célszerű elvégezni!
Az `overrides/` mappa a felülírási funkciók gyűjteménye. A `src/bridge/` mappában lévő függvények szükség esetén átmásolhatók ide, majd itt felülírhatók.

**FONTOS!** Bridge függvény felülírását csak az `overrides/` mappában végezd.

#### Fejlesztőknek / AI és Cursor kontextus

Új chatben vagy refaktorálásnál érdemes erre hivatkozni:

- [docs/INDEX_HU.md](docs/INDEX_HU.md) – dokumentáció térkép (innen indulj)
- [docs/PROJECT_STRUCTURE.txt](docs/PROJECT_STRUCTURE.txt) – mappák szerepe és fájlfa
- [docs/PUBLIC_API_HU.md](docs/PUBLIC_API_HU.md) – publikus `exports.e_core:*` + `eCore:` szerződés
- [docs/AI_SUPPORT_REFERENCE_HU.txt](docs/AI_SUPPORT_REFERENCE_HU.txt) – mély referencia (magyar) + GYIK
- [docs/SUPPORTED_STACK_MATRIX_HU.md](docs/SUPPORTED_STACK_MATRIX_HU.md) – tier / override mátrix
- [docs/SZERVER_OPERATOR_CHECKLIST_HU.md](docs/SZERVER_OPERATOR_CHECKLIST_HU.md) – szerver üzemeltető: ensure sorrend, kockázatlista, ConVarok
- [docs/DB_MIGRATIONS_HU.md](docs/DB_MIGRATIONS_HU.md) – MySQL migrációk, `e_core_migrations`, `getDbSchemaVersion`
- [docs/LUA_LS_AND_CI_HU.md](docs/LUA_LS_AND_CI_HU.md) – LuaLS, luacheck, GitHub Actions

Példa a testreszabásra:

```lua
    function eCore:sendMessage(message, mType, mSec) -- src/bridge/esx/client.lua

        ESX.ShowNotification(message, mSec, mType)
    end

    --- OVERRIDE a 'overrides/...' mappában:
    
    function eCore:sendMessage(message, mType, mSec) -- overrides/core/client.lua

        PELDA.SajatUzenom(message, mSec, mType)
    end
```
Példa egy inventory funkció felülírásra:
```lua
    function eCore:removeItem(xPlayer, item, count, metadata, slot) -- src/bridge/esx/server.lua
    
        xPlayer.removeInventoryItem(item, count, metadata, slot)
    end

    --- OVERRIDE a 'overrides/...' mappában:
    
    function eCore:removeItem(xPlayer, item, count, metadata, slot) -- overrides/avp_grid_inventory/server.lua
    
        return exports["avp_grid_inventory"]:RemoveItemBy(xPlayer.source, count, item)
    end
```

#### Labor and skill rendszer:

A koncepció az ArcheAge MMORPG mintájára működik. Az egyes feladatok elvégzése munkapontokba kerül, ami növeli a karakter képességeit.

Például, ha az 'eco_collecting' szkripttel betakarítasz egy zöldséget, az 5 laborpontba kerül, és hozzáadódik a betakarítási készséghez. Így a későbbiekben a rangbeállítás szerint kedvezményeket kaphat, például: gyorsabb betakarítás, kevesebb munkapontért.

A crafting rendszerben beállítható, hogy egy tárgyat csak egy bizonyos jártasság elérése után lehessen előállítani, és hány munkapontba kerül az elkészítése.

Az exportok segítségével ezt beépítheti bármelyik saját szkriptbe. Lásd:

- export_examples_server.md
- export_examples_client.md

Az e_core felhasznál ESX és QBCore szkript részleteket is.
