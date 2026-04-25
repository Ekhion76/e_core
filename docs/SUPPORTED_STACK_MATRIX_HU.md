# Támogatott / ismert stack mátrix (D pont – v0.1)

Cél: egy helyen látszódjon, **milyen kombinációk** vannak a repóban példával / override mappával dokumentálva. Ez **nem** teljes piaci mátrix; szerverenként validálni kell.

| Szint | Leírás | Példa | Megjegyzés |
|--------|--------|-------|------------|
| **Tier 0** | Csak legacy core inventory API (`xPlayer` / `Player.Functions`), nincs (vagy nem használt) külön ox override | Alap ESX / QB | Kevesebb illesztő; súly/slot a core szerint. |
| **Tier 1** | **ox_inventory** – repóban: `overrides/ox_inventory/` | ESX + ox vagy QB + ox | Tipikus éles; `getRegisteredItems` / add/remove gyakran override. |
| **Tier 2** | Egyéb inventory override a repóban | `qs_inventory`, `avp_grid_inventory`, `example_custom_inventory` | Mappa szerinti glob sorrend = utolsó nyer ugyanarra az `eCore:` névre. |
| **Progress / UI** | Nem inventory | `ox_progressbar`, `17_movement`, `inside_scripts` | `eCore:progressbar`, `sendMessage`, stb. |

## Operátori ellenőrzőlista

- [ ] `server.cfg`: **egy** legacy core (`es_extended` **vagy** `qb-core`); kivétel: tudatos teszt + `e_core:framework` kényszer.
- [ ] Core resource **előbb** induljon, mint `e_core` (framework + item lista).
- [ ] Ha **két** inventory-szerű override ütközik: egy mappa maradjon „nyerő”, vagy egyesített custom override.

## Hibakódok (D – kész)

Közös tábla: **`src/libs/errors.lua`** → globális **`eCoreErr`**, valamint **`eCore.Err`** a `getCore()` eredményén (`src/bridge/main.lua`). Inventory / meta / labor return okok innen hivatkozandók új kódban.

## Kapcsolódó

- `docs/SZERVER_OPERATOR_CHECKLIST_HU.md` → Fázis 0: ensure, függőségek, indulási log, kockázatlista.
- `docs/MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md` → 3D (inventory stratégia).
- `docs/PUBLIC_API_HU.md` → `eCore:` névsor + `eCoreErr` táblázat.
