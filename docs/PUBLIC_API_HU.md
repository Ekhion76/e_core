# e_core – publikus API (szerződés v0.3)

Ez a fájl a **külső hívható** `exports.e_core:*` felületet és az **`eCore:`** facade **névsorát** rögzíti (forrásfájl szerint). Viselkedés-részletek, paraméterek, GYIK: **`docs/AI_SUPPORT_REFERENCE_HU.txt`**. Gyors minták: **`export_examples_client.md`**, **`export_examples_server.md`**.

| Meta | Érték |
|------|--------|
| **Resource verzió** | `fxmanifest.lua` → `version` |
| **Változások** | `changelog.md` – breaking változás = changelogban kiemelve |
| **Indulás** | `exports.e_core:isReady()` – item registry kész-e (client + server) |

**Override:** ugyanazon `eCore:` név felülírható `standalone/overrides/<mappa>/` alatt; a betöltési sorrend a mappanevek lexikografikus `**/shared.lua` / `client.lua` / `server.lua` globja szerint dől el.

---

## 1. Mindkét oldalon (client + server)

Forrás: `bridge/main.lua`.

| Export | Visszatérés | Megjegyzés |
|--------|-------------|------------|
| `getFrameWork` | `string` \| `nil` | `'esx'`, `'qb'`. Nincs core induláskor: `nil`. |
| `getCore` | `table` | `eCore` facade (lásd §6–§10). |

---

## 2. Csak kliens (`client/exports.lua`)

| Export | Paraméterek | Megjegyzés |
|--------|-------------|------------|
| `getAbility` | `category`, `name?` | Saját játékos cache. |
| `getMeta` | `meta?` | |
| `getLabor` | – | Sync előtt / üres meta: `false`, `not_found_metadata`. |
| `getLevel` | `value` | |
| `getDiscounts` | `value` | |
| `getConfig` | – | |
| `isReady` | – | `true` csak ha item registry kész. |

---

## 3. Csak szerver (`server/exports.lua`)

| Export | Paraméterek |
|--------|-------------|
| `getAbility` | `playerId`, `category`, `name` |
| `setAbility` | `playerId`, `category`, `name`, `value` |
| `addAbility` | `playerId`, `category`, `name`, `value` |
| `removeAbility` | `playerId`, `category`, `name`, `value` |
| `getLabor` | `playerId` |
| `setLabor` | `playerId`, `amount` |
| `addLabor` | `playerId`, `amount` |
| `removeLabor` | `playerId`, `amount` |
| `registerMeta` | `playerId`, `category`, `defaultValue` |
| `getMeta` | `playerId`, `meta?` |
| `setMeta` | `playerId`, `meta`, `value` |
| `getLevel` | `value` |
| `getDiscounts` | `value` |
| `getConfig` | – |
| `isReady` | – |
| `getDbSchemaVersion` | – (visszaadás: max. migráció `id` az `e_core_migrations` táblából; **0** ha üres / hiba) |

---

## 4. Nem export – ajánlott belépés

```lua
FRAMEWORK = exports.e_core:getFrameWork()
eCore = exports.e_core:getCore()
eCoreConfig = exports.e_core:getConfig()
```

`imports/core.lua`. **`eCore.helper`** = `libs/helper.lua` → **`hf`**. **`eCore.Err`** = `libs/errors.lua` → **`eCoreErr`** (azonos kulcsok / string értékek); külső resource összehasonlíthat: `reason == exports.e_core:getCore().Err.inventory_full`.

---

## 5. Gyakori `false, ok` stringek (`eCoreErr` / `eCore.Err`)

Forrás: **`libs/errors.lua`**. Az e_core belső kódja **`eCoreErr.xyz`** formát használ; a **visszaadott string** változatlan maradt (backward compatible).

| Kulcs (`eCoreErr.*`) | Példa string érték | Hol (tipikus) |
|----------------------|-------------------|---------------|
| `category_does_not_exist` | ugyanaz | kliens `getAbility` |
| `meta_does_not_exist` | ugyanaz | kliens `getAbility` (név megadva) |
| `the_system_is_turned_off` | ugyanaz | labor / kliens olvasók |
| `not_found_metadata` | ugyanaz | szerver meta / labor |
| `no_valid_meta_name` | ugyanaz | szerver meta |
| `not_valid_amount` | ugyanaz | szerver labor |
| `has_already_reached_the_limit` | ugyanaz | szerver meta / labor |
| `too_heavy`, `not_enough_space` | ugyanaz | `canSwapItems` / `canCarryItem` (global shared) |
| `inventory_full`, `no_items_to_remove`, `inventory_is_empty`, `not_enough_items` | ugyanaz | QB bridge inventory |
| `there_are_no_items_to_remove` | `'there are no items to remove'` | ESX / ox / qs `removeItems` üres lista |
| `unknown_error` | ugyanaz | ox / qs removeItems hibaág |
| `ok` | `'ok'` | sikeres többes remove végén |
| `vehicle_no_plate_data` | hosszú angol szöveg | `createVehicle` (global server) |

Új inventory ok: először **`eCoreErr`**-be kulcs + érték, majd hivatkozás a bridge / override fájlokban.

---

## 6. `eCore:` – közös (shared), `bridge/global/shared.lua`

| Metódus |
|---------|
| `getInventoryWeight` |
| `canSwapItems` |
| `canCarryItem` |
| `countFreeSlots` |
| `getItemWeight` |
| `getFirstSlotByItem` |
| `getAmountOfItems` |
| `getRegisteredItem` |
| `isReady` |

---

## 7. `eCore:` – kliens (globális), `bridge/global/client.lua`

ox_target jellegű globális opciók / zónák: `disableTargeting`, `addGlobalOption`, `removeGlobalOption`, `addGlobalObject`, `removeGlobalObject`, `addGlobalPed`, `removeGlobalPed`, `addGlobalPlayer`, `removeGlobalPlayer`, `addGlobalVehicle`, `removeGlobalVehicle`, `addModel`, `removeModel`, `addEntity`, `removeEntity`, `addLocalEntity`, `removeLocalEntity`, `addSphereZone`, `addBoxZone`, `addPolyZone`, `removeZone`.

---

## 8. `eCore:` – szerver (globális), `bridge/global/server.lua`

| Metódus |
|---------|
| `createVehicle` |

---

## 9. `eCore:` – ESX ág (`ESX_CORE`)

**Shared (`bridge/esx/shared.lua`):** `convertPlayer`, `convertItems`.

**Client (`bridge/esx/client.lua`):** `triggerCallback`, `sendMessage`, `drawText`, `hideText`, `progressbar`, `cancelProgressbar`, `isLoggedIn`, `getInventory`, `getPlayerMaxWeight`, `getRegisteredItems`, `getPlayer`, `getAccounts`, `canInteract`, `setFuelLevel`, `vehicleKeys`, `setVehicleProperties`, `setVehiclePropertiesFromNetId`, `deleteVehicle`, `getClosestVehicle`.

**Server (`bridge/esx/server.lua`):** `createCallback`, `createUsableItem`, `sendMessage`, `drawText`, `hideText`, `addMoney`, `removeMoney`, `getAccounts`, `getInventory`, `getInventoryWeight`, `getPlayerMaxWeight`, `addItem`, `removeItem`, `removeItems`, `getRegisteredItems`, `getPlayer`, `itemBox`, `addCommands`.

---

## 10. `eCore:` – QB ág (`QB_CORE`)

**Shared (`bridge/qb/shared.lua`):** `convertItems`, `getRegisteredItems`, `convertPlayer`.

**Client (`bridge/qb/client.lua`):** ESX-hez hasonló készlet; eltérések: `sendMessage` opcionális `image`; `getPlayer(newJob, newGang)`; további metódusok mint ESX kliensnél (`triggerCallback`, `progressbar`, `getInventory`, jármű, stb.).

**Server (`bridge/qb/server.lua`):** ESX-hez hasonló készlet (`createCallback`, `createUsableItem`, üzenetek, pénz, inventory, `getPlayer`, `itemBox`, `addCommands`). **Megjegyzés:** `removeMoney` aláírása / viselkedése eltérhet az ESX ágtól – részletek az AI_SUPPORT_REFERENCE QB szekcióban.

---

## 11. Deprecálási szabály (e_core repó)

1. **Előjelzés:** changelog „Deprecated” szekció + legalább egy minor verzió.
2. **Futás közben:** régi név maradhat **alias** (thin wrapper), opcionális `print` / `cLog` figyelmeztetés.
3. **Eltávolítás:** következő major vagy kijelentett breaking minor; **`PUBLIC_API_HU.md`**, **`export_examples_*`**, **`AI_SUPPORT_REFERENCE_HU.txt`** egy PR-ben frissül.

Új export vagy szemantika változás: lásd `.cursor/rules/e_core-ai-collaboration.mdc`.

---

## 12. Még opcionális

- [ ] `PUBLIC_API.json` gépi fogyasztásra.
- [ ] További return literálok átvezetése `eCoreErr`-re (pl. egyedi override-ok, bridge edge case-ek).

---

## 13. Támogatott stack (összefoglaló)

Részletes mátrix: **`docs/SUPPORTED_STACK_MATRIX_HU.md`**.
