# Net események és callback audit (G pont)

Cél: **kisebb abuse felület**, dokumentált **szerver** határok. Frissítés: változáskor `changelog.md` + `docs/AI_SUPPORT_REFERENCE_HU.txt`.

## 1. Kliens → szerver (RegisterServerEvent)

| Esemény | Szerep | Védelem |
|---------|---------|---------|
| `e_core:loadMeta` | Meta betöltés kérés spawn után | `hf.isValidPlayerSource(source)`; `hf.netRateLimit(source, 'e_core:loadMeta', cooldown)`; `eCore:getPlayer` kötelező; ConVar: `e_core:loadmeta_rate_ms` (alap 2500, min 500). |
| `e_core:web:requestOpen` | Admin NUI megnyitás (`Config.web.command`, alap `ecore_admin`) | `Config.operator.admin.enabled` (runtime: szintetizált `Config.web.enabled`); `hf.webConsoleAccess(source)`; `hf.netRateLimit`. |
| `e_core:integrityCheck:request` | Integritás checklist indul (`Config.integrityCheck.command`, alap `ecore_diag`) | `Config.integrityCheck.enabled`; ha `Config.operator.admin.enabled` → `hf.webConsoleAccess`, különben `integrityCheck` ACE + `allowedIdentifiers`; opc. `opts.inlineAdmin` / `opts.onlyStep` (admin Integritás fül); `hf.netRateLimit` burst; cooldown; `eCore:getPlayer` + read-only / opc. add-remove. |
| `e_core:integrityCheck:progressResult` | Progress teszt befejezés jelzése | Csak ha `awaitingProgress[source]` aktív (`server/integrity_check.lua`); `hf.netRateLimit`. |

## 2. Csak szerver belső (AddEventHandler)

| Esemény | Szerep | Megjegyzés |
|---------|--------|------------|
| `e_core:playerLoaded` | Bridge hívja `TriggerEvent`-tel (`esx:playerLoaded` / QB betöltés után) | **Nem** `RegisterServerEvent` – így a kliens **nem** küldhet hamis `xPlayer` táblát ugyanazon néven. |

## 3. Eltávolítva / nem nyitott NetEvent

| Név | Ok |
|-----|-----|
| `e_core:createVehicle` (sharedEvents → RegisterNetEvent) | Duplikálta a callbacket; globális `createVehicle` kötés hibás volt; **kliensről járműspawn** kockázat. Csak: `e_core:createCallback('e_core:createVehicle', …)` (`bridge/global/callbacks/server.lua`) + forrás ellenőrzés. |

## 4. Callbackok (ESX / QB)

| Név | Védelem |
|-----|----------|
| `e_core:createVehicle` | `hf.isValidPlayerSource(source)` hamis esetén `cb(nil, nil)`. |
| `e_core:getCanSwap` / `e_core:getCanCarry` (avp override) | Ugyanígy forrás ellenőrzés. |

## 5. Bridge: regisztrált keretrendszer NetEventek (`bridge/main.lua`)

A kiválasztott ág (`ESX_CORE` / `QB_CORE`) eseménylistájára `RegisterNetEvent(event.name, event.method)` fut. A **forrás** a keretrendszer szerver–kliens protokollja; az e_core handler csak **lokális** `e_core:*` alias eseményeket gyújt (`TriggerEvent`).

### 5.1 Kliens (`bridge/global/events/client.lua` + esx|qb `events/client.lua`)

| Regisztrált név | Handler röviden | Megjegyzés |
|-----------------|-----------------|------------|
| `e_core:methodCaller` | `eCore[method](eCore, …)` dinamikus hívás | Lásd §7. |
| `esx:playerLoaded` | `TriggerEvent('e_core:onPlayerLoaded', …)` | ESX ág. |
| `esx:onPlayerLogout` | `TriggerEvent('e_core:onPlayerUnload', …)` | ESX ág. |
| `esx:setJob` | `TriggerEvent('e_core:onJobUpdate', job)` | ESX ág. |
| `QBCore:Client:OnPlayerLoaded` | `TriggerEvent('e_core:onPlayerLoaded')` | QB ág. |
| `QBCore:Client:OnPlayerUnload` | `TriggerEvent('e_core:onPlayerUnload')` | QB ág. |
| `QBCore:Client:OnJobUpdate` | `TriggerEvent('e_core:onJobUpdate', job)` | QB ág. |
| `QBCore:Client:OnGangUpdate` | `TriggerEvent('e_core:onGangUpdate', gang)` | QB ág. |

### 5.2 Szerver (`bridge/global/events/server.lua` kezdete üres; esx|qb `events/server.lua`)

| Regisztrált név | Handler röviden |
|-----------------|-----------------|
| `esx:playerLoaded` | `TriggerEvent('e_core:playerLoaded', xPlayer, …)` |
| `esx:playerDropped` | `TriggerEvent('e_core:playerUnload', playerId)` |
| `QBCore:Server:PlayerLoaded` | `TriggerEvent('e_core:playerLoaded', xPlayer)` |
| `QBCore:Server:OnPlayerUnload` | `TriggerEvent('e_core:playerUnload', playerId)` |

A szerver **nem** regisztrálja a `e_core:methodCaller` NetEventet (a `sharedEvents` szerver oldali kezdő táblája üres; csak a framework sorok kerülnek be).

## 6. Kliens: további `e_core:*` NetEventek (`client/main.lua`)

Csak **szerver** `TriggerClientEvent`-tel érkeznek (kliens–kliens spoof nem cél).

| Név | Forrás (e_core) | Tartalom / kockázat |
|-----|-----------------|---------------------|
| `e_core:sync` | `server/meta.lua` (`syncRequest`), `server/db.lua` | Teljes meta pillanatkép; megbízhatóság = szerver logika. |
| `e_core:levelChange` | `libs/meta.lua` | Popup adat; csak szerver küldi. |
| `e_core:integrityCheck:nuiPush` / `consoleOnly` / `clientPrint` / `progressTest` | `server/integrity_check.lua` | Integritás NUI / konzol / progress; csak érvényes futásból. |

**Labor HUD (`OPEN` subject `hud`):** a bridge `TriggerEvent('e_core:onPlayerLoaded'|'e_core:onPlayerUnload')` **lokális** eseményeket használ; a `client/main.lua` ezekre **`AddEventHandler`**-t használ (korábban `RegisterNetEvent` volt – a bridge nem küldött hálózati eseményt ugyanezen a néven, így a labor HUD nyitás nem futott a bridge útvonalon).

## 7. `e_core:methodCaller` (kliens)

- **Regisztráció:** `bridge/global/events/client.lua` → `bridge/main.lua`.
- **Whitelist:** a `methodCallerAllowed` táblában szereplő nevek futnak; egyébként **nincs** `eCore` hívás. Nem engedélyezett névnél: **`print`** a kliens konzolra (`[e_core] methodCaller: nem engedélyezett metódus: …`), valamint **`cLog`** szint 1 (ha `Config.debugLevel` engedi).
- **Szerver hívás:** `bridge/global/server.lua` – `TriggerClientEvent('e_core:methodCaller', owner, 'setVehiclePropertiesFromNetId', netId, props)` (jármű tulaj tulajdonságai).
- **Új metódus:** vedd fel a `methodCallerAllowed` táblába (`bridge/global/events/client.lua`), és csak megbízható szerver oldali `TriggerClientEvent`-tel hívd.

## 8. Segédek (`libs/helper.lua`, `libs/helper_ecore.lua`)

- `hf.isValidPlayerSource(src)` – `GetPlayerName(src)` alapú.
- `hf.netRateLimit(src, key, cooldownMs)` – játékos + kulcs szerinti egyszerű ablak.

## 9. További ötletek (nem kötelező)

- ACE jogosultság jármű / admin műveletekre.
- További `RegisterNetEvent` audit a consumer resource-okban (eco_*).
- Részletes rate limit táblázat eseményenként.
