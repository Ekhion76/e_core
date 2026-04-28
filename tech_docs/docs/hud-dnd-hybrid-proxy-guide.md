---
id: hud-dnd-hybrid-proxy-guide
title: DnD HUD rendszer - kezeloi utmutato
sidebar_position: 10
---

# DnD HUD rendszer (hibrid proxy) - emberbarat hasznalati utasitas

Ez az oldal szervertulajdonosoknak es script-fejlesztoknek szol.  
Celjunk, hogy gyorsan, biztonsagosan es atlathatoan tudd bekotni a HUD elemek drag-and-drop pozicionalasat e_core alapon.

## Mire jo ez?

- A HUD elemet a **consumer resource** rajzolja (pl. `e_petrol_station`).
- A mozgatast (DnD edit mode), szinkront es mentest az **e_core** intezi.
- A jatekos egyedi HUD pozicioja elmentodik a metadata-ba (`hudLayout`), igy reconnect utan is visszajon.

## Alap otlet egy mondatban

A consumer csak regisztral egy elemet es renderel, az e_core pedig edit modban ghost dobozzal mozgatja, preview es commit eventekkel szinkronizal.

---

## 1) Elokeszites szervertulajdonoskent

1. Ellenorizd az `ensure` sorrendet: `e_core` induljon a consumer(ek) elott.
2. Frissitsd az e_core resource-t olyan verziora, ahol mar elerheto:
   - `exports.e_core:registerHudElement(...)`
   - `exports.e_core:unregisterHudElement(...)`
3. Inditsd ujra a szervert vagy legalabb az erintett resource-okat.

Hasznos parancs edit modhoz:

```text
/ecore_hud_edit
```

Ez ki-be kapcsolja a HUD szerkesztoi modot.

---

## 2) Consumer oldali Lua bekotes (minimum)

Az alabbi minta mutatja a legkisebb hasznalhato integraciot.

```lua
-- client.lua (consumer resource)
local HUD_ID = 'e_petrol_station:price_panel'
RegisteredElements = RegisteredElements or {}

local function registerHud()
    local ok, posOrReason = exports.e_core:registerHudElement(HUD_ID, {
        label = 'Benzinkut',
        defaultPos = {
            x = 0.12,      -- normalizalt 0..1
            y = 0.30,      -- normalizalt 0..1
            w = 0.20,      -- normalizalt 0..1
            h = 0.10,      -- normalizalt 0..1
            anchor = 'top-left'
        }
    })

    if ok then
        -- Ezt az import-helper hasznalja: csak a regisztralt elemek kapnak preview sync-et.
        RegisteredElements[HUD_ID] = true

        -- Opcionális: kezdo pozicio azonnali tovabbitasa a sajat NUI fele
        SendNUIMessage({
            action = 'ECORE_HUD_SYNC',
            id = HUD_ID,
            pos = posOrReason
        })
    else
        print(('[e_petrol_station] HUD register hiba: %s'):format(tostring(posOrReason)))
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        registerHud()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        exports.e_core:unregisterHudElement(HUD_ID)
        RegisteredElements[HUD_ID] = nil
    end
end)
```

### Mi tortenik a hatterben?

- Szerkesztes kozben az e_core `e_core:hud:clientPreview` eventet kuld.
- Az import helper (`src/imports/sdk/client/hud_drag.lua`) ezt automatikusan NUI uzenette alakitja:
  - `action = 'ECORE_HUD_SYNC'`
  - `id`, `pos`
- A consumer NUI ezt olvassa, es runes state-be irja.

---

## 3) Consumer NUI (Svelte 5 runes) - ajanlott minta

### 3.1 Kozponti state `.svelte.ts` fajlban

```ts
// src/lib/hudState.svelte.ts
export type HudAnchor = 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' | 'center'

export const hudState = $state({
  pos: { x: 0.12, y: 0.30, w: 0.20, h: 0.10, anchor: 'top-left' as HudAnchor },
  isEditing: false,
  label: 'Benzinkut'
})
```

### 3.2 NUI message listener csak ezt a state-et irja

```ts
// pl. App.svelte vagy listener modul
import { hudState } from './lib/hudState.svelte'

const HUD_ID = 'e_petrol_station:price_panel'

window.addEventListener('message', (event) => {
  const item = event.data
  if (!item || typeof item !== 'object') return

  if (item.action === 'ECORE_HUD_SYNC' && item.id === HUD_ID && item.pos) {
    hudState.pos = item.pos
  }
})
```

### 3.3 Komponensek csak olvassak a state-et

```svelte
<script lang="ts">
  import { hudState } from './lib/hudState.svelte'

  function styleFromPos() {
    const p = hudState.pos
    return `left:${p.x * 100}%;top:${p.y * 100}%;width:${p.w * 100}%;height:${p.h * 100}%;`
  }
</script>

<div class="price-panel" style={styleFromPos()}>
  {hudState.label}
</div>
```

---

## 4) Anchor rendszer - hogyan gondolkodj rola?

Az `x` es `y` nem nyers pixel, hanem normalizalt arany (`0.0..1.0`), plusz anchor.

- `top-left`: bal felso sarokhoz kepest
- `top-right`: jobb felso sarokhoz kepest
- `bottom-left`: bal also sarokhoz kepest
- `bottom-right`: jobb also sarokhoz kepest
- `center`: kep kozephez kepest

Miert jo ez?

- 1080p -> 4K valtaskor nem "maszik el" a panel.
- Ugyanaz a layout kulonbozo monitorokon is konzisztens marad.

Gyakorlati tipp:

- Clampeld a poziciot (`0..1`) minden frissiteskor.
- Ha animalsz, akkor is a runes state legyen a source of truth.

---

## 5) Edit mode es pointer-trap (fontos)

Edit modban az e_core ghost layer viselkedese:

- ghost layer: `pointer-events: all`
- hatter retegek: `pointer-events: none`

Ez azt eredmenyezi, hogy:

- a HUD dobozt tudod huzni egérrel,
- de nem "fojtod meg" az egesz UI-t es jatekinterakciot.

Ha a te consumer NUI-dban van extra kattinthato UI, edit mod alatt erdemes azt is passzivra tenni.

---

## 6) Uzemeltetoi hibakereses (gyors checklist)

### Nem mozog a HUD

- Ellenorizd, hogy az elem regisztralva lett (`registerHudElement` sikeres volt).
- Ellenorizd a `RegisteredElements[HUD_ID] = true` beallitast.
- Ellenorizd, hogy az `ECORE_HUD_SYNC` uzenet megjon a NUI-ba.

### Nem mentodik el a pozicio

- Ellenorizd, hogy edit modban volt commit (Mentés gomb / `hudCommit` callback).
- Ellenorizd a szerver oldali rate limitet (`e_core:hud:commit`).
- Ellenorizd, hogy a player metadata rendben toltodik/mentodik (`e_core` oszlop).

### Felbontasvaltasnal rossz helyre kerul

- Ellenorizd, hogy a `pos` tartalmaz `anchor` mezot is.
- Ellenorizd, hogy a render logika tenyleg anchor szerint szamol.

---

## 7) Mit csinaljon egy server owner, ha tobb scriptet hasznal?

- Adj minden HUD elemnek egyedi, namespaced id-t:
  - jo: `e_petrol_station:price_panel`
  - jo: `my_hud:phone_widget`
- Ne hasznalj ugyanazt az id-t ket kulonbozo panelhez.
- Kerd a script fejlesztot, hogy minden HUD komponens kozos rune-state-bol dolgozzon.

Igy hosszabb tavon sokkal konnyebben kezelheto marad a teljes HUD ecosystem.

