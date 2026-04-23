# e_core – adatbázis migrációk és séma verzió (Fázis 3)

## Cél

- Az **`e_core`** oszlop és későbbi séma-változások **verziózott**, **ismételhető** lépésekben fussanak induláskor.
- A szerver **MySQL.ready** után fut a futtató: `server/db_migrations.lua` → `e_core_run_db_migrations()` (meghívja a `server/db.lua`).

## Migrációs tábla

| Tábla | Szerep |
|--------|--------|
| `e_core_migrations` | Alkalmazott migrációk: `id` (egész, PK), `name`, `applied_at`. |

Új telepítés: a tábla létrejön, majd az **1**–es migráció lefut (ha még nincs sor `id=1`).

## Jelenlegi migrációk

| `id` | `name` | Leírás |
|------|--------|--------|
| 1 | `add_e_core_longtext_column` | `ALTER TABLE … ADD COLUMN IF NOT EXISTS e_core LONGTEXT` – ESX: `users`, QB: `players`. |

A cél séma verzió (kód): globális **`ECORE_DB_SCHEMA_TARGET`** a `server/db_migrations.lua` fájlban – új migráció után **egyezzen** a legmagasabb `id`-vel.

## Új migráció hozzáadása (fejlesztő)

1. Írj egy `run()` függvényt (vagy használj helyben `MySQL.query.await` / `MySQL.update.await` hívásokat).
2. Add hozzá az **`ECORE_DB_MIGRATIONS`** tömb végéhez: `{ id = N, name = 'egyedi_snake', run = ... }`.
3. Növeld **`ECORE_DB_SCHEMA_TARGET`** = `N`-re.
4. Frissítsd ezt a doksit, a **`changelog.md`**-t és szükség szerint **`docs/PUBLIC_API_HU.md`** / **`export_examples_server.md`**-t.

**Megjegyzés:** `ADD COLUMN IF NOT EXISTS` a meglévő MySQL / MariaDB verziótól függ; a repó ezt már korábban is használta az `e_core` oszlophoz.

## Export (ellenőrzés / monitoring)

| Export | Oldal | Visszatérés |
|--------|--------|-------------|
| `exports.e_core:getDbSchemaVersion()` | szerver | Alkalmazott migrációk közül a legnagyobb `id`, vagy **0** (üres tábla / lekérdezés hiba). |

## MySQL hívások (3E)

- Közös segéd: **`hf.mysqlAwait(tag, fn)`** (`libs/helper.lua`) – `fn` belül csak **oxmysql `.await`** hívások; hiba → `cLog` + `false` visszatérés (nem dob mindenhol).
- `server/db.lua`: `saveMeta` / `saveAllMeta` / `loadMeta` erre épül; régi callback-alapú `scalar` / `update` helyett **await**.

## Kapcsolódó

- `server/db.lua` – `saveMeta` / `loadMeta` / `saveAllMeta` (UPDATE / SELECT).
- `docs/MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md` → 3E, Fázis 3.
