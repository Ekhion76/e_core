# Keretrendszer-config refaktor – terv és megvalósítás

A **glob** (`bridge/**/config.lua`) helyett **egy belépési pont** (`bridge/framework_config.lua`) + `bridge/esx/config_defaults.lua` és `bridge/qb/config_defaults.lua` tölti a keretrendszer-specifikus alapokat.

---

## 1. Korábbi helyzet (megoldva)

- Két `config.lua` futhatott egymás után; két core mellett a sorrend döntött.
- Ma: egy resolver dönt; két core + `auto` → **`error`**, üzenet a ConVar beállítására.

---

## 2. Cél (teljesült)

1. **Egy döntési pont:** `bridge/framework_config.lua`.
2. **Explicit hiba** két core + `auto` esetén; kényszerített `esx` / `qb` + figyelmeztetés, ha mindkettő fut.
3. **ConVar:** `e_core:framework` = `auto` | `esx` | `qb` (kis/nagybetű, trim).
4. **Alapértékek:** `e_core_apply_esx_config()` / `e_core_apply_qb_config()` a defaults fájlokban.

---

## 3. Implementációs lépések (állapot)

| Lépés | Teendő | Állapot |
|--------|---------|---------|
| 3.1 | `bridge/framework_config.lua` | Kész |
| 3.2 | `bridge/esx/config_defaults.lua`, `bridge/qb/config_defaults.lua` | Kész |
| 3.3 | `fxmanifest.lua` shared_scripts | Kész |
| 3.4 | README / operátori megjegyzés | Opcionális |
| 3.5 | ESX-only / QB-only regresszió | Szerveren ellenőrizendő |

---

## 4. Nem cél

- Teljes `bridge/` modulrendszer újraírása.
- Inventory override viselkedés megváltoztatása (`overrides/*`).

---

## 5. Kapcsolódó: item registry indulás (kész)

Részletek és ConVarok: ugyanaz a szakasz marad, mint korábban: `e_core:items_ready_timeout_ms`, `e_core:items_ready_poll_ms`; implementáció `libs/helper_ecore.lua` → `hf.awaitItemRegistryReady`.

---

## 6. ConVar: `e_core:framework`

| Érték | Jelentés |
|--------|-----------|
| `auto` (alap) | Ha csak egy core fut, azt választja. Ha **mindkettő** fut → indulás **megáll** (`error`), állíts `esx` vagy `qb`-t. |
| `esx` | ESX ág; ha csak QB fut, **hiba**. Két core mellett csak az ESX bridge aktív (`ESX_CORE=true`, `QB_CORE=false`). |
| `qb` | QB ág; ha csak ESX fut, **hiba**. Két core mellett csak a QB bridge aktív. |

**Megjegyzés:** `ESX_CORE` / `QB_CORE` most a **választott aktív ágat** jelenti (nem pusztán azt, hogy a resource elindult-e). Így a nem választott bridge **guard** ágai nem futnak le, még ha a másik core resource véletlenül fut is.

### 6.1 Legacy core **resource** név (átnevezett fork)

| ConVar | Alapértelmezés | Jelentés |
|--------|----------------|----------|
| `e_core:framework_resource` | *(üres)* | Nem üres és **`e_core:framework`** = `esx` vagy `qb` → ez a string felülírja az adott ág alap resource nevét (`es_extended` illetve `qb-core`). **`auto` mellett nem** alkalmazódik (figyelmeztető log). |

Runtime: `src/bridge/framework_resource_registry.lua` – `ecore_framework_resource_set`, `ecore_framework_resource_esx`, `ecore_framework_resource_qb` (nincs `_G._ECORE_LEGACY_*`). A QB `DrawText` / `HideText` bridge a QB resource névből épít prefixet; más event namespace → `qb/client.lua` / `qb/server.lua` felülírás.

---

## 7. Ellenőrzőlista

- [x] `fxmanifest` egy bridge-config belépő + defaults.
- [x] 0 / 2 core esetén egyértelmű viselkedés (log / `error`).
- [x] `docs/AI_SUPPORT_REFERENCE_HU.txt` frissítve (fő szekciók).
- [x] Keretrendszer doksik: `docs/INDEX_HU.md`.
