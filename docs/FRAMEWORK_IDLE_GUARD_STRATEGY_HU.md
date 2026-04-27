# Framework detect hibaegyesites es idle guard strategia

## Kontextus

Az e_core indulasakor tobb hibaforras ugyanarra a vegallapotra vezethet:

1. `auto` detect nem talalja a vart default framework resource-t.
2. ConVar-ban ervenytelen framework ertek szerepel.
3. Egyedi framework resource nevet hasznal a szerver, de nincs megadva ConVar-ban.

Ezeket kulon-kulon kezelni zajos, nehezen uzemeltetheto konzol viselkedest adhat.

## Cel

- Egyetlen, ertelmezheto startup hibaegyesites.
- Nincs szerver-crash (`error`/stop helyett kontrollalt fallback).
- e_core `idle` allapotban marad, amiben nem floodolja a konzolt.
- Kiszamithato guard viselkedes a tovabbi modulokban.

## Javasolt allapotmodell

Bevezetheto egy kozponti runtime allapotgep:

- `BOOTING`: kezdeti init, detect fut.
- `READY`: framework detect sikeres, normal uzem.
- `IDLE`: detect sikertelen vagy konfiguracios hiba, core degradalt uzemmodban.

Opcionisan belso hibakoveteshez:

- `DEGRADED`: framework megvan, de egyes opcionals integraciok (pl. inventory) nem allnak keszen.

## Egyesitett framework detect hiba

A 3 felsorolt eset ugyanarra az aggregator kodra fusson (pl. `framework_detect_unresolved`), es pontosan egyszer logoljon startupkor:

- Miert nem tudott frameworket valasztani.
- Mely ConVarok relevansak egyedi nevek eseten.
- Hogy e_core `IDLE` allapotba kerul.
- Hogy mely szolgaltatasok lesznek limitaltak.

Peldauzenet tartalom:

- `e_core:framework` helyes ertekei.
- `e_core:framework_resource` hasznalata custom resource nev eseten.
- `status=IDLE`, `actions=check_convars_and_resource_names`.

## Log-flood elleni guard szabalyok

Az `IDLE` allapotban minden framework-fuggo kodut egy kozponti guardon menjen at:

- Az elso hivasnal logol (warn/error szint a policy szerint).
- Ugyanarra a hibakulcsra rate-limit vagy one-shot log (pl. kulcs: `idle_framework_access:<caller>`).
- A tovabbi hivasok mar csendesek vagy debug szintu mintavetelezettek.

Ez megakadalyozza, hogy az `idle` allapot ezrevel termeljen hibat.

## Funkcios ready-state: meddig erdemes elmenni?

A felvetes helyes: erdemes szukulni arra, ami tenyleg ellenorizheto.

### 1) Framework readiness (kotelezo)

- Binarias allapot: van-e ervenyes, aktiv framework kotes.
- Ha nincs, az egesz runtime `IDLE`.

### 2) Inventory readiness (opcionalis, de indokolt)

- Csak akkor legyen kulon ready, ha tenylegesen lehet megbizhatoan ellenorizni az aktiv inventory bridge/override oldalon.
- Ez lehet `PENDING`/`READY`/`TIMEOUT` jellegu allapot.

### 3) Mas szolgaltatasok

- Ne legyen altalanos ready allapot mindenre.
- Ami nem verifikalhato determinisztikusan, arra a ready flag inkabb hamis biztonsagerzetet adna.

## Consumer-varakozas: "ne hibazzon, varjon" dilemmma

Az irany jo, de korlatokkal:

- A vegtelen varakozas szinten problema (csendes deadlock).
- Javasolt: bounded wait (timeout), visszateresi koddal.

Minta szerzodes:

- `awaitInventoryReady(timeoutMs)` -> `true` vagy `false, "inventory_not_ready_timeout"`.
- Consumer oldalon dontheto: retry, fallback UX, vagy funkcio tiltasa.

Igy nincs azonnali hiba, de nincs vegtelen blokkolas sem.

## Consumer minta: timeout + reason (configChecked nelkul)

A consumer oldalon ne legyen vegtelen:

- `while not eCore:isReady() do Wait(...) end` — **0.1.7+** az `isReady()` **mindig boolean** (`false` töltés alatt is), ezért a ciklus technikailag elindulhat, de **véletlenül sem** jó végtelen várakozás (IDLE / timeout esetén örökké `false`).

Helyette legyen idokorlatos helper, ami visszaadja az okot is:

```lua
local function waitForEcoreReady(timeoutMs, pollMs)
    local timeout = timeoutMs or 15000
    local poll = pollMs or 100
    local deadline = GetGameTimer() + timeout

    while GetGameTimer() < deadline do
        if eCore:isReady() then
            return true
        end
        Wait(poll)
    end

    local stateOk, state = pcall(function()
        return eCore:getSystemState()
    end)

    if stateOk and type(state) == "table" then
        if state.mode == "IDLE" then
            return false, "ecore_idle", state
        end
        if state.inventory == "TIMEOUT" then
            return false, "inventory_not_ready_timeout", state
        end
    end

    return false, "ecore_not_ready_timeout"
end

local ok, reason, details = waitForEcoreReady(15000, 100)
if not ok then
    print(("[eco_crafting] e_core not ready: %s"):format(reason))
    -- itt consumer dontes:
    -- 1) feature disable (return)
    -- 2) kesobbi retry (backoff)
    -- 3) fallback UX
    return
end
```

Miert jo ez a minta:

- Nincs csendes deadlock.
- A `reason` alapjan determinisztikus a consumer reakcio.
- A `details` debug celra megmarad, de nem kotelezo uzleti logikahoz.

## Minimalis implementacios elvek

1. Egy kozponti allapotforras (`eCore:getSystemState()` vagy belso state tabla).
2. Framework detect finalizalas utan egyszeri statusz-log.
3. Guard helper:
   - `requireFrameworkReady(opName)`
   - `requireInventoryReady(opName, opts)`
4. Guard return szerzodes legyen kovetkezetes (`ok, reason`), ne vegyes nil/print/error.
5. `IDLE` modban csak a biztonsagos, framework-fuggetlen reszek maradjanak elerhetok.

## Donto ajanlas

Igen, a gondolatmenet jo:

- A 3 detect hibaforras kezelese legyen egyesitett.
- e_core ne alljon le hard errorral, hanem lepjen `IDLE` allapotba.
- Az `IDLE` kovetkezmenyeit guardokkal es log-throttle-lel kell kordaban tartani.
- Funkcios ready-state-et csak ott erdemes bevezetni, ahol objektiven merheto (framework + inventory).
- Consumer oldalon varakozas csak timeouttal elfogadhato.

Ez uzemeltetesi szempontbol stabilabb, es fejlesztoi oldalrol egyertelmubb hibamodellt ad.
