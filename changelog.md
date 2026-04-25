0.0.56
- **Lua annotációs szabvány + teljes sweep:** új guide `docs/LUA_ANNOTATION_STYLE_EN.md`, új backlog `docs/LUA_ANNOTATION_BACKLOG_EN.md`, valamint `.cursor/rules/lua-annotation-style.mdc` szabály. A teljes `e_core` Lua függvénykészletre egységes, angol nyelvű LuaLS annotáció került (`@param`, `@return`, publikus szerződések elsőbbsége; bridge/domain/override/NUI bridge fájlokkal együtt). Eredmény: audit szerint **451/451** függvény annotált (0 hiányzó blokk).

0.0.55
- **imports/discordlog.lua (DiscordLog):** **embed(opts)** – egy táblából embed + opcionális top-level mezők, **newEmbed** flag; **appendFields** tömbös mezőlista; **clearFields**; **alert(opts)** – `level` → szín + rövid mezők. Doksi: `docs/AI_SUPPORT_REFERENCE_HU.txt` §1.1 imports/discordlog.

0.0.54
- **Integritás cooldown egységesítés:** `operator.integrityCheck.cooldownMs` (alap 8000 ms, min. 1500); elírás javítva (`1500` ms helyett értelmes default); szerver merge + `Config.integrityCheck` szinkron (`libs/config_check.lua`, `server/integrity_check.lua`, `standalone/config/main.lua`, `src/web/src/lib/IntegrityPanel.svelte`).
- **Admin Integritás fül:** két oszlop (vezérlők + görgethető napló), integritás lépések soronként külön futtatással (`onlyStep`), pipa / X állapot; a szerver `inlineAdmin` NUI üzenetek a modális `LiveDiagnosticsPanel` helyett az admin panelben jelennek meg (`server/integrity_check.lua`, `client/integrity_check.lua`, `src/web/src/lib/IntegrityPanel.svelte`, `LiveDiagnosticsPanel.svelte`).
- **Admin konzol görgetés:** a fő panel tartalma függőlegesen görgethető (`src/web/src/AdminConsole.svelte`).
- **Doksi / üzenetek:** operátori és net audit szövegek `Config.operator.admin.enabled` szerint (nem a felhasználónak szánt `Config.web.enabled` hangsúly); `src/web/README.md`, `docs/NET_EVENTS_AUDIT_HU.md`, `docs/SZERVER_OPERATOR_CHECKLIST_HU.md`, `standalone/config/main.lua`, `client/web.lua`, `libs/helper_ecore.lua`.

0.0.53
- **Breaking – integritás vs. registry diagnostics:** az inventory/checklist integritás **`Config.integrityCheck`** (forrás: `Config.operator.integrityCheck`, legacy: `operator.diagnostics`). Net események: **`e_core:integrityCheck:request`**, **`e_core:integrityCheck:progressResult`**, kliens: **`e_core:integrityCheck:*`** (régi `e_core:diagnostics:*` eltávolítva). Szerver: **`server/integrity_check.lua`**; a registry admin futások maradnak **`server/diagnostics.lua`**-ban (`diagnosticsAdmin*` exportok változatlan nevek).
- **Breaking – admin NUI:** alap parancs **`ecore_admin`**, ACE alap **`ecore.admin`** (`Config.operator.admin`, legacy: `operator.web` → szintetizált `Config.web`). `client/web.lua` üzenetek: „admin konzol”.
- **Breaking – `Config.operator`:** lapos kulcsok: `admin`, `integrityCheck`, `cleanup`, `registryDiagnostics`, `deniedAudit` (régi `adminApi.*` és `web`/`diagnostics` kulcsok továbbra is olvashatók legacy ágon a `libs/config_check.lua`-ban).

0.0.52
- **Breaking:** `Config.adminHttp` és a **`SetHttpHandler` HTTP admin** (`/admin/professions`, `/admin/level-profiles`, …) **eltávolítva**. Profession / level-profile admin a játékbeli web konzolon **NUI bridge**-en megy: `eCoreAdminApi` → `e_core:nuiAdminRpc` → `hf.webConsoleAccess` + meglévő `professionAdmin*` / `levelProfileAdmin*` függvények (`client/nui_admin_bridge.lua`, `server/nui_admin_bridge.lua`). Böngészős Vite dev: `VITE_USE_MOCK_REGISTRY=true` (lásd `src/web/.env.example`). Doksi: `docs/PUBLIC_API_HU.md` §3.1, `src/web/README.md`.

0.0.51
- **Egyesített Svelte NUI (`web`):** az `ui_page` most a `src/web/dist` Vite build; a régi jQuery `html/ui.html` + `html/js/*` és az `html/admin` iframe build eltávolítva. Skills / labor HUD + integritás live panel + admin konzol ugyanabban az alkalmazásban (`src/web/src/NuiApp.svelte`, `AdminConsole.svelte`, `LiveDiagnosticsPanel.svelte`).
- **`Config.web`:** játékbeli web konzol (`enabled`, `command` alapértelmezés `ecore_web`, `acePermission`, `allowedIdentifiers`). Szerver: `hf.webConsoleAccess`, `e_core:web:requestOpen` → `e_core:web:open` / `deny` (`server/web.lua`, `client/web.lua`). NUI callback: `webAdminExit`.
- **Integritás jogosultság:** ha `Config.web.enabled`, a `diagnosticsCanRun` a `hf.webConsoleAccess`-t használja; különben a korábbi `Config.diagnostics` ACE + `allowedIdentifiers` (`server/diagnostics.lua`).

0.0.50
- **Profession registry alap (Sprint 1, e_core only):** új DB-first bootstrap és read-only API réteg. Új server exportok: `getProfessionRegistry`, `isValidProfession`, `getProfessionDefaults`, `getProfessionLevelProfile` (`server/professions.lua`, `server/exports.lua`). Új hibaokok: `profession_registry_unavailable`, `profession_category_not_found`, `profession_not_found`, `profession_profile_not_found` (`libs/errors.lua`).
- **DB bootstrap:** induláskor migráció után automatikus default profile/profession seed (`default_global`, crafting + harvesting minimum készlet), idempotens beszúrással (`INSERT IGNORE` / `ON DUPLICATE KEY`) (`server/db.lua`, `server/professions.lua`).
- **Diagnostics bővítés:** `ecore_diag` szerver ellenőrzés már külön profession registry konzisztencia blokkot futtat (registry elérhetőség, profile referencia, levels ellenőrzés), NUI checklist és console-only ág bővítve (`server/diagnostics.lua`).
- **Doksi szinkron:** server export példák és API táblázat frissítve a profession registry exportokkal (`export_examples_server.md`, `docs/PUBLIC_API_HU.md`, `docs/AI_SUPPORT_REFERENCE_HU.txt`).
- **Fázis 2 kezdő backend API (`F2-T1`, `F2-T2`):** új admin profession CRUD exportok standard válasz szerződéssel: `professionAdminList`, `professionAdminCreate`, `professionAdminUpdate`, `professionAdminSetEnabled`, `professionAdminDelete`; cache invalidálás CRUD után és profile-key referencia validáció (`server/professions.lua`, `server/exports.lua`). Új hibaok: `profession_already_exists` (`libs/errors.lua`).
- **Fázis 3 e_core-only előkészítés (`F3-E2`):** új recipe-validációs backend export `validateProfessionKeys(category, keys)` a profession kulcsok központi ellenőrzéséhez; strukturált lista kimenet: `valid`, `invalid`, `missingProfile` (`server/professions.lua`, `server/exports.lua`, `docs/PUBLIC_API_HU.md`, `export_examples_server.md`).
- **Diagnostics consumer-ready bővítés (`F3-E3`):** új admin diagnostics tesztkulcs `profession-key-validation`, amely a `validateProfessionKeys` service-re építve futtat kategória/kulcs ellenőrzést; payload alapú célzott mód (`professionKeysByCategory`) és fail docHint mapping finomítás (`server/diagnostics.lua`, `docs/PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU.md`).
- **Audit shape egységesítés (`F3-E4`):** cleanup és denied audit események egységes event contractot adnak (`eventType`, `actor`, `target`, `outcome`), UI/reporting-fókuszú feldolgozáshoz. A `adminApiDeniedAuditList` DB+fallback kimenet konzisztens shape-re normalizálva, legacy mezőkkel együtt (`server/professions.lua`, `libs/helper_ecore.lua`).
- **Doksi zárás (`F3-E5`):** `PUBLIC_API_HU` és `export_examples_server` F3 contract szinkron (diagnostics célzott kulcsvalidáció payload + audit event shape példák), valamint a Sprint terv Fázis 3 e_core-only blokkjának teljesítési frissítése (`docs/PROFESSION_REGISTRY_IMPLEMENTACIOS_TERV_SPRINT1_HU.md`).

0.0.49
- **`hf.shallowCopy`:** központi sekély táblamásolat `libs/helper.lua`-ban; `hf.copy` erre delegál. `libs/meta.lua` (`getDiscounts`) és `server/meta.lua` (meta merge) a helyi `shallow_copy` / `meta_shallow_copy` helyett ezt hívja.
- **Segédek:** `libs/helper.lua` = általános `hf` (consumer / közös util); e_core-specifikus kiterjesztés **`libs/helper_ecore.lua`** (item `normalizeRegisteredItemDef`, registry várakozás, MySQL `mysqlAwait`, indulási összegzés, net rate limit, `moneyFormat`). **`hf.itemDefinitionWeightGate` / `hf.hasResolvableStandardWeight` eltávolítva** – a convertItems ágak nem szűrnek többé „elírásos súlykulcs” alapján; a normalizálás továbbra is a szabványos aliasokból olvas / hiány esetén 0. Kontextus: `.cursor/rules/e_core-context.mdc` (Segédek).
- **imports/discordlog.lua:** webhook URL **https + /api/webhooks/** ellenőrzés; érvénytelen URL → **false** + `cLog`; Discord **mezőhossz** csonkolás; **opts** (`defaultColor`, `avatar_url`, `onError`); **send(doneCb)**; üres üzenet kihagyása; kiegészítő embed API (`url`, `timestamp`, `author`, `thumbnail`, `image`, `username`, `avatarUrl`); **putField** 4. paraméter `codeBlock`; több **név szerinti szín** + `#RRGGBB`; **putEmbed nélküli** mező hívásoknál automatikus embed. **imports/utils.lua:** **cLog** – ha `v` pontosan `error` / `warning` / `info` / `debug` és `level` szám → egy soros színezett `[SEVERITY]` sor. Doksi: **`docs/AI_SUPPORT_REFERENCE_HU.txt`** (1.1 imports: `cLog`, `createDiscordLog`, consumer ötletek szekció).

0.0.48
- **Export vékony réteg (`server/exports.lua`, `client/exports.lua`, `bridge/main.lua`):** audit (terület sor 9) – névsor egyezik a `docs/PUBLIC_API_HU.md` §2–§3 táblákkal; fájlfejlécek rögzítik, hogy csak kötés / vékony burkoló van, üzleti logika és rejtett export-elágazás nincs; `bridge/main.lua` QB/ESX része kizárólag netesemény. Doksi: `docs/PUBLIC_API_HU.md` §1–§3, `docs/ECORE_ERR_HIBA_NYOMON_HU.md` §3 bevezető, `docs/TERULET_AUDIT_SORREND_HU.md` sor 9.

0.0.47
- **Override inventory (`standalone/overrides/ox_inventory|qs_inventory|avp_grid_inventory/server.lua`):** `removeItems` – **ugyanaz a sor-szerződés**, mint a keretrendszer bridge-nél (nem tábla sor / üres név / nem pozitív `amount` → **`invalid_item_data`**); üres lista → **`there_are_no_items_to_remove`**; hiányos **`xPlayer`** / hívás kivétel (`pcall`) / stack sikertelen törlés → **`unknown_error`** + `cLog`. **ox / qs `addItem`:** hiányos forrás vagy kivétel → **`unknown_error`**; stack által visszaadott, nem `eCoreErr` string → **`unknown_error`** + `cLog` (egyértelmű összehasonlíthatóság). **avp:** `removeItem` / `addItem` bemenet guard; `canCarryItem` **`false`, ok** (`invalid_item_data` / `too_heavy` / `unknown_error`); `canSwapItems` – `swappingItems` nem tábla → **`invalid_item_data`**, egyébként megegyezik a `canCarryItem` szerződéssel; `RemoveItemBy` egyedi `reason` → fenti normalizálás. Doksi: `docs/PUBLIC_API_HU.md` §5, `docs/ECORE_ERR_HIBA_NYOMON_HU.md` §3 / §4.3, `docs/TERULET_AUDIT_SORREND_HU.md` sor 8.

0.0.46
- **Keretrendszer inventory (`bridge/esx/server.lua`, `bridge/qb/server.lua`):** `removeItems` – **sor szerződés:** minden elem **tábla**, **`name`** nem üres string (trim), **`amount`** pozitív szám (`tonumber`, NaN elutasítva); különben **`false`, `invalid_item_data`** (korábban a QB ág **`nil:lower()`** miatt összeomlhatott, illetve csak **0** / hiányos mennyiség mellett **hamis siker** jöhetett). **ESX:** hiányzó **`xPlayer`** vagy **`removeInventoryItem`** hiba (`pcall`) → **`unknown_error`** + `cLog`. Sikertelen törlés után **nem** adunk **`ok`**-ot. Doksi: `docs/PUBLIC_API_HU.md` §5, `docs/ECORE_ERR_HIBA_NYOMON_HU.md` §3 / §4.3, `docs/TERULET_AUDIT_SORREND_HU.md` sor 7.

0.0.45
- **Globál szerver (`bridge/global/server.lua`):** `eCore:createVehicle` – **bemenet:** `pos` nem tábla vagy hiányos / nem szám koordináta, `model` nem nemnulla szám és nem nemüres string, `props` megadva de nem tábla → **`false`, `unknown_error`**. **Entitás:** nem jött létre jármű / nincs entitás → ugyanígy. **Rendszám:** továbbra is **`vehicle_no_plate_data`**, sikertelen olvasás után **`DeleteEntity`** (árva jármű nélkül). **Hálózat:** `NetworkGetNetworkIdFromEntity` **0** / `nil` esetén a korábbi `while not netId` **végtelen ciklus** helyett legfeljebb ~5 s várakozás, majd **`unknown_error`** + törlés; **tulajdonos -1** maradása után is **`unknown_error`** + törlés. Doksi: `docs/PUBLIC_API_HU.md` §5 / §8, `docs/ECORE_ERR_HIBA_NYOMON_HU.md` §3, `docs/TERULET_AUDIT_SORREND_HU.md` sor 6.

0.0.44
- **Globál shared inventory (`bridge/global/shared.lua`):** `canSwapItems` – a nem egyedi alapanyag-ág **nem módosítja** többé a játékos `inventory` sorait (korábban a „mi lenne, ha levonnánk” szimuláció **mellékhatásként** írta a stack mennyiségeket). `canCarryItem` / `canSwapItems` – **explicit** `eCoreErr.invalid_item_data` (rossz tábla / név / mennyiség, nem tábla `swappingItems`), **`item_not_registered`** (nincs a registry-ben). `getItemWeight` / `getFirstSlotByItem` – típusvédelem üres vagy nem string item névnél. Új kulcsok: `libs/errors.lua` → `docs/PUBLIC_API_HU.md` §5, `docs/ECORE_ERR_HIBA_NYOMON_HU.md` §3 / §4.3, `docs/TERULET_AUDIT_SORREND_HU.md` sor 5.

0.0.43
- **Kliens meta / NUI (`client/main.lua`):** `getAbility` – **trim**elt kategória / név, érvénytelen param → **`false`, `no_valid_meta_name`**; hiányzó jártasság mező **`== nil`** ellenőrzés (a tárolt **`false`** érték nem esik össze a „nincs mező” hibával). `getMeta` – opcionális kulcsnál ugyanilyen **string + trim** szerződés; hibás param **`false`, `no_valid_meta_name`**. `getLabor` – `labor` **tábla** és **`val`** `tonumber` + NaN ellen; sérült cache → **`not_found_metadata`**. **`e_core:sync`:** nem tábla payload → **`cLog`**, cache nem íródik felül. Doksi: `docs/PUBLIC_API_HU.md` §2 / §5, `docs/ECORE_ERR_HIBA_NYOMON_HU.md` §4.4, `export_examples_client.md`, `docs/TERULET_AUDIT_SORREND_HU.md` sor 4.

0.0.42
- **Meta perzisztencia (`server/db.lua`, `server/db_migrations.lua`):** `loadMeta` – üres / `nil` oszlop → üres meta; nem tábla vagy hibás JSON → **nem** `prepareMeta` (elkerüli az üres memória + későbbi mentés miatti **adatvesztést**); DB hiba → figyelmeztető `cLog`. `saveMeta` / `saveAllMeta` – sikertelen `mysqlAwait` után **explicit** `cLog` (a részletes SQL hiba továbbra is a helper szinten). **Migráció:** `migration_applied` SELECT hibánál **error** (nem „nincs alkalmazva” ág), hogy ne fusson újra bizonytalan állapotban. Doksi: `docs/TERULET_AUDIT_SORREND_HU.md` sor 3, `docs/ECORE_ERR_HIBA_NYOMON_HU.md` §4.5, `docs/PUBLIC_API_HU.md` (`getDbSchemaVersion` megjegyzés), `export_examples_server.md`.

0.0.41
- **Labor (`server/labor.lua`, kliens `getLabor` a `client/main.lua`-ban):** sikeres olvasás **`true`, egyenleg** (a **0** labor nem „hamis” hiba többé). **`addLabor` / `removeLabor`:** csak **pozitív** mennyiség (`not_valid_amount` egyébként); **`removeLabor`:** ha az egyenleg kisebb a levonásnál → **`not_enough_labor`** (új kulcs: `libs/errors.lua`). **`setLabor`:** nem negatív szám kötelező (`not_valid_amount`). **`addOfflineLabor`:** nincs `return 0` / végponti `nil` keverék — **`true`** / **`false`**; sikeres jóváírás végén explicit **`return true`**. Doksi: `docs/PUBLIC_API_HU.md` §5, `docs/ECORE_ERR_HIBA_NYOMON_HU.md`, `export_examples_client.md` / `export_examples_server.md`. **Breaking (külső hívók):** `getLabor` / `exports.e_core:getLabor` első visszaadott érték korábban lehetett szám; most mindig **`ok, második`** páros.

0.0.40
- **Meta / jártasság (`server/meta.lua`):** `addAbility`, `removeAbility`, `setAbility` – ha a `value` nem szám (`tonumber` szerint), **`false`, `not_valid_amount`** (korábban `setAbility` nem szám értéket is tárolhatott; `add`/`remove` csendben `true` volt). **`libs/meta.lua` `getDiscounts`:** hibánál **`eCoreErr.not_levels_data`** (string változatlan: `not_levels_data`). Új kulcs: `libs/errors.lua` → `docs/PUBLIC_API_HU.md` §5, `docs/ECORE_ERR_HIBA_NYOMON_HU.md`, `export_examples_server.md`.

0.0.39
- **Doksi:** `docs/TERULET_AUDIT_SORREND_HU.md` – területenkénti audit **sorrend** (meta kész, labor, db, kliens, bridge…), **egy beszélgetés = egy sor** / hatókör; másolható AI üzenet sablon; checklist. Hivatkozás: `docs/ECORE_ERR_HIBA_NYOMON_HU.md`, `.cursor/rules/e_core-context.mdc`.

0.0.38
- **Doksi:** `docs/ECORE_ERR_HIBA_NYOMON_HU.md` – `eCoreErr` kulcsok, visszaadott stringek, fő forrásfájlok, **általános ellenőrzési sorrend** (indulás → isReady → oldal → játékos → config → override), meta / labor / inventory / kliens csoportok; opcionális audit checklist. Hivatkozás: `docs/PUBLIC_API_HU.md` bevezető, `.cursor/rules/e_core-context.mdc`.

0.0.37
- **`messageIfLevelChange` / `checkLevelChange` (`libs/meta.lua`):** tisztább szerződés (explicit `tonumber`, kommentek); shared fájl miatt **csak szerveren** fut a net hívás (`IsDuplicityVersion`), előtte **`hf.isValidPlayerSource`** + **category/name** típusellenőrzés. Kliens: `e_core:levelChange` csak **tábla** payload esetén küld NUI-t.

0.0.36
- **Szerver meta API (`server/meta.lua`):** egységes **játékos sor** ellenőrzés, **trim**elt kategória / jártasság név, **tiltott gyökér kulcsok** (`login`, `logout`, `labor`) – `registerMeta` / `setMeta` / `getAbility` / `addAbility` / `setAbility` / `removeAbility` konzisztensen `eCoreErr.reserved_meta_category` (korábban a labor jártasság-szerű hívás csendben működhetett). **`registerMeta`:** `nil` default → `{}`, nem tábla → `meta_default_must_be_table`, merge csak **hiányzó string kulcsok** (`rawget`), sérült slot → `meta_category_not_table`, új kategória **másolattal** tárolva; egy **sync** csak változáskor. **`setMeta`:** csak **tábla** érték (`meta_value_must_be_table`), másolat tárolás. **`getMeta`:** opcionális kulcs trim (rendszer mezők **olvashatók**). Új okok: `libs/errors.lua` → `docs/PUBLIC_API_HU.md` §5, `export_examples_server.md`.

0.0.35
- **Diagnosztika UX:** szinte átlátszó háttér + üveg modál (látszik a játék, progress, notify). **Élő sáv** (`diag_live_strip`): épp futó lépés szövege. **Checklist** lépésről lépésre (szerver `CreateThread` + `Config.diagnostics.uiStepMs`); státusz: fut / OK / hiba / kihagyva / **megszakítva** (progress `onCancel` narancs). Technikai napló továbbra lent. Új események: `e_core:diagnostics:nuiPush`, `consoleOnly`.

0.0.34
- **Diagnosztika NUI:** `/ecore_diag` eredménye középre zárt, modern modálban (blur, szekciók, színkódolt sorok, **másolás** a NUI-ból `clipboard` / `execCommand`, **Esc** bezár). `Config.diagnostics.useNui` / `printToConsole`. Szerver: `clientPrint` szekció (`server` / `progress` / `error`). `html/js/diagnostics.js`, `fxmanifest` JS felsorolás betöltési sorrendhez.

0.0.33
- **convertItems / elírásos súlykulcs:** `hf.itemDefinitionWeightGate` + `hf.hasResolvableStandardWeight` / `hf.getRegisteredItemWeightKeyConfig` (`libs/helper.lua`). Ha **nincs** érvényes szabványos súly (`Config.fields.weight`, `weight`, `Weight`, `itemWeight`…), de az item sorban ismert **hibás kulcs** van (pl. `weigt`, `weigth`…), az item **nem kerül** a `REGISTERED_ITEMS` listába; `cLog('eCore:convertItems:skip', { framework, item, reason })`. Ha egyáltalán nincs súlymező és nincs ilyen elírás → változatlan: **0 súly** + normalize. A korábbi alias / pcall / típusvédelem megmaradt.

0.0.32
- **convertItems / normalize:** `hf.normalizeRegisteredItemDef` – több **súly** kulcs (`weight`, `Weight`, `itemWeight`…), **label** aliasok, **lőszer** mezők (`ammotype`, `ammoType`…), belső **pcall** + hiba esetén `cLog` + minimális fallback. **convertItems** hurkok (ESX, QB, ox, qs, avp): **itemenkénti pcall** + típusellenőrzés; QB `label` csak stringre `gsub`; ox `client.image` csak stringre `string.match`; nem tábla sor = kihagyás (nem állítja meg a teljes listát).

0.0.31
- **REGISTERED_ITEMS / convertItems:** `hf.normalizeRegisteredItemDef` (`libs/helper.lua`) – egységes mezők minden ágon (`name`, `label`, súly kulcs `Config.fields.weight`, `isUnique`, `isWeapon`, `image`, `ammoname` kisbetű vagy nil). Hívva: `bridge/esx|qb/shared.lua`, `standalone/overrides/ox_inventory|qs_inventory|avp_grid_inventory/shared.lua`. QB: robosztusabb kulcsnév (`item` / `data.name`).

0.0.30
- **ox_inventory súly / limit:** `standalone/overrides/ox_inventory/server.lua` – `eCore:getInventoryWeight` és `getPlayerMaxWeight` az ox **`GetInventory(source)`** `weight` / `maxWeight` mezőiből olvas (pcall + fallback: ESX `getWeight` / shared számítás, ill. `Config.maxInventoryWeight`). Kliens override: opcionális **`GetPlayerWeight` / `GetPlayerMaxWeight`** export pcall, majd bridge fallback. Így a `canCarryItem` / diagnosztika ugyanazt a súlyt látja, mint az ox.

0.0.29
- **Integritás parancs:** `Config.diagnostics` (`standalone/config/main.lua`) – `/ecore_diag` (név változtatható). Engedély: **ACE** (`acePermission`, pl. `ecore.diagnostics`) **vagy** `allowedIdentifiers` lista (`GetPlayerIdentifiers` egyezés). Szerver: aktuális / max súly (`getInventoryWeight`, `getPlayerMaxWeight`), `canCarryItem` + opc. `tryAddRemove`; kliens: **progressbar** onFinish/onCancel riport. Alapból `enabled = false`. Operátor: `docs/SZERVER_OPERATOR_CHECKLIST_HU.md`.

0.0.28
- Labor auto tick (`server/labor.lua` → `laborIncrease`): céljátékosok **`GetPlayers()`** + `hf.isValidPlayerSource` + betöltött `ECO.meta[id].labor` alapján (nem a teljes `ECO.meta` bejárása). Opcionális szerver ConVar: **`e_core:labor_tick_chunk`** (alap **0** = egy hullámban mind; **>0** = legfeljebb ennyi fő / `SetTimeout(0)` hullám nagy online létszámnál). Doksi: `docs/LABOR_KEZELES_MUNKAFIL_HU.md`, `docs/SZERVER_OPERATOR_CHECKLIST_HU.md`.

0.0.27
- Luacheck 1.2.0: a **131** figyelmeztetéshez **`-- luacheck: push ignore 131`** / **`pop`** az `imports/*.lua` (4) + `types/fivem_ox_stubs.lua` fájlokban; a `.luacheckrc` `files[…].ignore` + globális `ignore` nem mindig illeszkedik. Megjegyzés: önmagában `-- luacheck: ignore 131` üres sorban 022 „unpaired push”-ot okozhat.

0.0.26
- Luacheck: `.luacheckrc` – a maradék 11× „unused global” valójában **131** (*Unused implicitly defined global*); `unused` / `unused_globals` **nem** kapcsolja ki. Megoldás: `imports/core|discordlog|locale|utils.lua` + `types/fivem_ox_stubs.lua` → **`files[…].ignore = { "131" }`**. Eltávolítva a hatástalan `unused_globals = false`.

0.0.25
- Luacheck: `.luacheckrc` – globális **`unused_globals = false`** (a `unused = false` önmagában nem mindig szünteti a 13x globál „unused” zajt). `libs/meta.lua`: **`table.clone` → helyi `shallow_copy`** (fájl-specifikus `read_globals` merge helyett, 0 warning stabilan).

0.0.24
- Luacheck: `.luacheckrc` – a `table.clone` leírást **nem** a globális `read_globals` tömbbe tesszük (régebbi luacheck: „string expected … got table”); vissza: `files['libs/meta.lua']` táblás `read_globals` + `clone = {}`.

0.0.23
- Luacheck: `.luacheckrc` – `table.clone` a globális `read_globals`-ben; `_PlayerPedId` **globals** (írható); Cfx manifest kulcsszavak `read_globals`; `fxmanifest` / `types` **exclude** minták bővítve (`**/…`); könyvtári + stub fájlok `unused_globals = false`. Példa override: `_ = CUSTOM_INVENTORY` helyett no-op `(function(_inv) end)(CUSTOM_INVENTORY)` (3 fájl). Cél: **`luacheck .` → 0 warning**.

0.0.22
- Luacheck: `.luacheckrc` – `libs/meta.lua` `read_globals.table.fields.clone` leíró **tábla** (`{}`), nem boolean; különben a config betöltése elhasal („field description table expected”).

0.0.21
- Biztonság: `e_core:methodCaller` kliens **whitelist** (`methodCallerAllowed` a `bridge/global/events/client.lua`-ban). Nem engedélyezett `method` esetén nincs dinamikus hívás; **mindig** `print` a kliens konzolra, opcionálisan `cLog` (debug).

0.0.20
- Bridge / net audit: `docs/NET_EVENTS_AUDIT_HU.md` – §5–§7 táblázatok (keretrendszer NetEvent regisztrációk, `e_core:sync` / `levelChange`, `e_core:methodCaller` kockázat és mitigáció javaslat). Kliens: `e_core:onPlayerLoaded` / `e_core:onPlayerUnload` **`AddEventHandler`** (a bridge lokális `TriggerEvent`-et használ; korábbi `RegisterNetEvent` miatt a labor HUD nem futott a bridge útvonalon).

0.0.19
- Luacheck: `.luacheckrc` – `fxmanifest.lua` és `types/**` kizárva; `ESX`/`QBCore` írható **globals**; FiveM natív `read_globals` bővítés; `libs/meta.lua` `table.clone`; `example_custom_inventory` üres `if` zaj; `imports/utils.lua` `print_r` árnyékolt változó átnevezve. Cél: **0 warning** `luacheck .`-nál.
- 3E MySQL: `hf.mysqlAwait(tag, fn)` (`libs/helper.lua`) – `pcall` + `cLog`. `server/db.lua`: `MySQL.update.await` / `prepare.await` / `scalar.await` + hibánál korai return; `server/db_migrations.lua`: minden `query.await` ugyanígy; `getDbSchemaVersion` figyelmeztet ha `alkalmazott_max < ECORE_DB_SCHEMA_TARGET`. Doksi: `DB_MIGRATIONS_HU.md`, `MODERNIZACIOS_…` 3E.

0.0.18
- DX (Fázis 4): LuaLS `.luarc.json`; típus stubok `types/` (`fivem_ox_stubs.lua`, `e_core_facade.lua`, `resource_globals.lua`). Luacheck `.luacheckrc` (lua54, html kizárva, FiveM + e_core globálok; `unused` zaj egyelőre ki). GitHub Actions `lua_ci.yml` – `luacheck .`. Doksi: `docs/LUA_LS_AND_CI_HU.md`; terv: `MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md` Fázis 4 / 3F frissítve.

0.0.17
- DB (Fázis 3): `server/db_migrations.lua` – `e_core_migrations` tábla, soronkénti migrációk; `#1` = `users` / `players` `e_core` LONGTEXT oszlop (korábbi `db.lua` ALTER átkerült ide). `MySQL.ready` először `e_core_run_db_migrations()`, majd a megszokott meta CRUD. Új szerver export: `exports.e_core:getDbSchemaVersion()`. Doksi: `docs/DB_MIGRATIONS_HU.md`; terv: `MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md` Fázis 3 pipa.

0.0.16
- Docs: Fázis 2 – `docs/AI_SUPPORT_REFERENCE_HU.txt` teljes audit: fejléc + kapcsolódó linkek (operátor checklist, NET_EVENTS), globális `events/server` leírás javítva (createVehicle csak callback), kliens indulás = `awaitItemRegistryReady`, **2. export** szekció bővítve (`isReady`, kliens `getLabor` + `not_found_metadata`), **3. eCore** szekció: PUBLIC_API mint névsor-forrás, **5. GYIK** kitöltve; szerver `getAbility` név kötelező megjegyzés. `docs/PUBLIC_API_HU.md`: szerver `getAbility` paraméter `name` kötelező. `MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md` Fázis 2 AI_SUPPORT pipa.

0.0.15
- Docs: Fázis 0 lezárás – `docs/SZERVER_OPERATOR_CHECKLIST_HU.md` (kockázatlista + egy oldalas szerver operátori checklist, ensure példa, ConVarok). `MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md` Fázis 0 jelölések frissítve; hivatkozások: `README_HU.md`, `SUPPORTED_STACK_MATRIX_HU.md`, `PROJECT_STRUCTURE.txt`, `e_core-context.mdc`.

0.0.14
- Net security (G): `hf.isValidPlayerSource` + `hf.netRateLimit`; `e_core:loadMeta` validates source, rate limit via ConVar `e_core:loadmeta_rate_ms` (default 2500, min 500). `e_core:playerLoaded` switched to `AddEventHandler` (server-only; not client-triggerable). Removed duplicate `e_core:createVehicle` RegisterNetEvent entry; vehicle spawn only via `e_core:createVehicle` callback with source check. AVP inventory callbacks validate source. See `docs/NET_EVENTS_AUDIT_HU.md`.
- **Breaking (ritka):** ha külső script kliensről `TriggerServerEvent('e_core:playerLoaded', …)`-t használt, az **nem** fut tovább – a betöltést a keretrendszer + `TriggerEvent` szerver oldalon kezeli.

0.0.13
- Unified startup log line: `hf.logEcoreStartupSummary('server'|'client')` after item registry wait — prints resource version, `FRAMEWORK`, active inventory override label (`ox_inventory`, `qs-inventory`, `avp_grid_inventory`, combinations, or `framework`), and `items=ready|timeout|pending`.

0.0.12
- Labor refactor (`server/labor.lua`): shared guards `laborRequireSystem` / `laborPlayerRow`; auto `laborIncrease` uses `syncRequest` instead of direct `TriggerClientEvent`; skips tick when labor system disabled; `addOfflineLabor` validates meta/labor row. Client `getLabor` returns `false, not_found_metadata` if labor block not synced yet.

0.0.11
- Central reason codes: `libs/errors.lua` (`eCoreErr` global); `eCore.Err` attached in `bridge/main.lua`. Wired through `bridge/global/shared.lua`, `bridge/global/server.lua`, ESX/QB server inventory paths, `ox_inventory` / `qs_inventory` / `avp_grid_inventory` server overrides, `server/meta.lua`, `server/labor.lua`, `client/main.lua`. String values unchanged for consumers. Docs: `docs/PUBLIC_API_HU.md` v0.3, `docs/SUPPORTED_STACK_MATRIX_HU.md`, `docs/REFAKTOR_PRIORITAS_UZEMTERV_HU.md` (D done).

0.0.10
- Framework selection: single shared entry `bridge/framework_config.lua` plus `bridge/esx/config_defaults.lua` and `bridge/qb/config_defaults.lua` (removed `bridge/esx/config.lua`, `bridge/qb/config.lua`). ConVar `e_core:framework` (`auto`|`esx`|`qb`): if both `es_extended` and `qb-core` are started and mode is `auto`, resource fails fast with an error; forced `esx`/`qb` activates only one bridge branch (`ESX_CORE` / `QB_CORE`). Roadmap: `docs/REFAKTOR_PRIORITAS_UZEMTERV_HU.md`.
- Public API contract (initial): `docs/PUBLIC_API_HU.md` – table of all `exports.e_core:*` (client/server/bridge); deep `eCore:` behavior remains in `docs/AI_SUPPORT_REFERENCE_HU.txt` until further merged.
- Public API v0.2: `eCore:` method inventory by bridge file, common `(false, reason)` strings, deprecation policy; new `docs/SUPPORTED_STACK_MATRIX_HU.md` (Tier 0–2 stack outline).

0.0.9
- Item registry boot: `hf.awaitItemRegistryReady` – timeout (`e_core:items_ready_timeout_ms`, default 120s, clamp 30s–600s), throttled wait logs, optional `e_core:items_ready_poll_ms`. On timeout `CORE_READY = false` instead of hanging forever. New `exports.e_core:isReady()` on client and server. See `docs/FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md` (section 5) for ConVars and stream vs server start note.
- Quick patch for incorrectly registered item images caused by QBox (QBCore.Shared.Items may contain image = '.png' with missing filenames).
- The translate script received additional validations to handle invalid input values more safely.
- Refactored helper functions.
- Added progress bar handling to scripts_ui.


0.0.8
- Transition to exclusive support for ox_target. If you use a target system, ox_target must be installed.

#### Why is this happening?
Ox_target has discontinued compatibility with qb_target. This currently only affects qb_core and ox_target users.

This means the module responsible for converting options and other parameters has been removed from ox_target. I decided not to integrate this into e_core because the qb_target system is outdated. Moving forward, I have chosen to support the modern ox_target natively.

#### What has changed:
e_core/bridge/global/client.lua: Adds ox exports.

e_core/bridge/esx/client.lua: Removal of qtarget-related functions

e_core/bridge/qb/client.lua: Removal of qb-target-related functions

0.0.7
- extends qb-core item remove function
- small bugfix
0.0.6
- Error: SEND_NUI_MESSAGE: invalid JSON passed in frame (rapidjson error code 3)
- The initial labor value could have been NaN, so the Nui interface did not open, only the cursor was visible.
  The change affects the:
- [lib/config_check.lua] -- added
- [fxmanifest.lua]
- [server/meta.lua] (prepareMeta)

0.0.5
- [e_core/server/labor.lua] (addOfflineLabor) Add offline labor timestamp. When logging in, the player receives the lab points collected during the offline time, with the current time stamp attached.
- [e_core/bridge/qb/shared.lua] (convertItems) Ignore non valid items and non-existent labels

0.0.4
- The getPlayer() function has been extended. It is given two optional parameters.
The change affects the:
- [bridge/esx/client.lua] (getPlayer)
- [bridge/esx/shared.lua] (convertPlayer)

- [bridge/qb/client.lua] (getPlayer)
- [bridge/qb/shared.lua] (convertPlayer)
The changes do not affect the standalone folder. Always copy and overwrite (if necessary) the functions of eCore there!
