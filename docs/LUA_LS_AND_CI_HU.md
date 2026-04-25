# LuaLS és CI (Fázis 4)

## LuaLS (VS Code / Cursor)

- **Konfig:** gyökér `.luarc.json` – Lua **5.4** (`fxmanifest.lua` `lua54`), `html` / `.cursor` kihagyva a workspace-ből.
- **Típus stubok (nem futnak):** `types/` mappa – `fivem_ox_stubs.lua` (MySQL, `exports`, gyakori natívok), `e_core_facade.lua` (`eCore` fő mezők), `resource_globals.lua` (`ECO`, `CORE_READY`, stb.).
- A teljes `eCore` névsor továbbra is: **`docs/PUBLIC_API_HU.md`**; új metódusnál bővítsd a stubot, ha az IDE autocomplete / diagnosztika fontos.

## Luacheck (lokálisan)

```bash
luacheck .
```

### Windows 11 (ajánlott: előre fordított `.exe`)

A `luarocks install luacheck` gyakran **C fordítót** kér (`luafilesystem` miatt; pl. MinGW `gcc` hiánya).

1. Töltsd le a hivatalos binárist: [lunarmodules/luacheck releases](https://github.com/lunarmodules/luacheck/releases) → **`luacheck.exe`** (pl. v1.2.0).
2. Másold pl. ide: `%LOCALAPPDATA%\Programs\luacheck\luacheck.exe`.
3. Add hozzá ezt a mappát a **felhasználói PATH**-hoz (Beállítások → Rendszer → Névjegy → speciális rendszerbeállítások → Környezeti változók), majd nyiss új terminált.
4. Ellenőrzés: `luacheck --version`.

*(Ehhez a gépen telepítettük a **Lua 5.4**-et `winget install DEVCOM.Lua` paranccsal is; a `luacheck.exe` önállóan fut, nem kötelező a Lua a PATH-on a luacheckhez.)*

**Alternatíva:** `luarocks install luacheck` – csak ha van **MinGW-w64** vagy **MSVC** toolchain a `luafilesystem` fordításához.

Telepítés Linuxon / CI-n: `luarocks install luacheck` vagy csomagkezelő (`apt install luarocks` + `luarocks install luacheck`).

**Tiszta futás:** a `.luacheckrc` **több mintával** próbálja kizárni a `fxmanifest.lua`-t és a `types/**` stubokat; ha mégis bekerülnek az ellenőrzésbe, a manifest kulcsszavak a globális `read_globals` stringlistában vannak. **`_PlayerPedId`** írható **globals**. A **131** (lunarmodules 1.2.x CLI: „unused global variable …”) **nem** a 2xx `unused` család; a `.luacheckrc` **`files[…].ignore`** Windows / path illesztés miatt kihagyható. Megoldás: a stub / könyvtári chunk elején **`-- luacheck: push ignore 131`**, végén **`-- luacheck: pop`** (ne csak `ignore 131` egy sorban – 022 „unpaired push”). A `libs/meta.lua` kedvezménysor másolása: **`hf.shallowCopy`** (`libs/helper.lua`). Cél: **`luacheck .` → 0 warning**.

- **Szabályok:** `.luacheckrc` – `std = "lua54"`, `html/**` kizárva, `read_globals` + `globals` az e_core / FiveM környezethez.
- **Jelenleg:** `unused` / `unused_args` + szelektív **131** ignore; később szigorítható.

## GitHub Actions

- **Workflow:** `.github/workflows/lua_ci.yml` – push/PR ágak: `main`, `master`, `develop`; Ubuntu + **`python3 scripts/validate_fxmanifest.py`** (lokális fájlok / `*` glob: létező fájlok, `@ox_lib` stb. kihagyva; a `files` blokkban az **`src/web/public/img/*.png`** üres találatlistát enged – opcionális NUI ikonok) + `luarocks install luacheck` + `luacheck .`.
- **Lokálisan:** a repó gyökeréből `python scripts/validate_fxmanifest.py` (Windows/Linux).
- Ha a forkban más az alap ág neve, bővítsd az `on.push.branches` listát.

## Kapcsolódó

- `docs/MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md` → 3F, Fázis 4.
- `docs/LUA_ANNOTATION_STYLE_EN.md` – kötelező angol LuaLS annotációs stílus (`@param`, `@return`, options shape).
- `docs/LUA_ANNOTATION_BACKLOG_EN.md` – aktuális annotációs backlog és fázisbontás.
- `.cursor/rules/lua-annotation-style.mdc` – AI szabály a következetes annotációs enforce-hoz.
