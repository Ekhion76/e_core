# 🧠 ECO ARCHITECTURE -- TELJES EGYESÍTETT CHEAT SHEET

------------------------------------------------------------------------

## 1. 🔗 PRIORITY CHAIN

**Jelentés:**\
A rendszer több lehetséges implementáció közül hierarchia alapján
választ.

**Sorrend:** - Server override - Resource export - Adapter - Fallback

**Miért fontos:** - szerver mindig kontrollban marad - nincs
ráerőltetett rendszer - automatikus integráció

👉 Ez az egész architektúra lelke.

**GOOD ✅**

``` lua
function LoadModule(name)
    if _G["eco_" .. name] then
        return _G["eco_" .. name]
    end

    if exports[name] then
        return exports[name]
    end

    local ok, mod = pcall(require, "modules." .. name .. ".qb")
    if ok then return mod end

    return require("modules." .. name .. ".fallback")
end
```

**BAD ❌**

``` lua
local Inventory = exports["qb-inventory"]
```

👉 Miért rossz: hard dependency

------------------------------------------------------------------------

## 2. 🧩 ADAPTER PATTERN

**Jelentés:**\
Platform-specifikus logika külön fájlban, egységes interfész mögött.

**Miért fontos:** - framework függetlenség - cserélhető backend -
izolált hibakezelés

------------------------------------------------------------------------

## 3. 📜 CONTRACT FIRST

**Jelentés:**\
Először az interfész (SPEC), utána az implementáció.

**Miért fontos:** - stabil API - több implementáció kompatibilis marad -
escrow mellett is működik

**GOOD ✅**

``` lua
-- spec.lua
return {
    methods = {
        "addItem",
        "removeItem"
    }
}
```

**BAD ❌**

``` lua
function AddItemToInventory(...)
```

👉 Miért rossz: nincs standard

------------------------------------------------------------------------

## 4. 🧠 CAPABILITY DETECTION

**Jelentés:**\
A rendszer futásidőben ellenőrzi, mit tud az adott modul.

**Miért fontos:** - nincs crash hiányzó funkció miatt - graceful
fallback - rugalmas integráció

**GOOD ✅**

``` lua
if Inventory.has("getWeight") then
    Inventory.getWeight(src)
end
```

**BAD ❌**

``` lua
Inventory.getWeight(src)
```

👉 Miért rossz: crash veszély

------------------------------------------------------------------------

## 5. 🔄 GRACEFUL DEGRADATION

**Jelentés:**\
Ha egy feature nem elérhető, a rendszer nem omlik össze, hanem
visszalép.

**Példa:**

``` lua
return false, "feature_not_supported"
```

**Miért fontos:** - stabilitás idegen környezetben - kevesebb support

**BAD ❌**

``` lua
return nil
```

👉 Miért rossz: debugolhatatlan

------------------------------------------------------------------------

## 6. 🔌 OVERRIDE FIRST DESIGN

**Jelentés:**\
A szerver saját implementációja mindig elsőbbséget élvez.

**Miért fontos:** - nincs lock-in - maximális flexibilitás - nagyobb
bizalom a vásárló részéről

**GOOD ✅**

``` lua
eco_logger = {
    log = function(type, data)
        exports.my_logger:send(type, data)
    end
}
```

**BAD ❌**

``` lua
exports["eco_logger"]:log(...)
```

👉 Miért rossz: kényszerített rendszer

------------------------------------------------------------------------

## 7. 📡 EVENT-DRIVEN ARCHITECTURE

**Jelentés:**\
A rendszer eseményeken keresztül kommunikál.

**Miért fontos:** - escrow kompatibilitás - külső rendszerek
beköthetők - lazán csatolt architektúra

**GOOD ✅**

``` lua
TriggerEvent("eco:crafting:afterCraft", {
    player = src,
    item = "knife"
})
```

**BAD ❌**

``` lua
exports["discord_logger"]:send(...)
```

👉 Miért rossz: nincs bővíthetőség

------------------------------------------------------------------------

## 8. 🪝 HOOK SYSTEM

**Jelentés:**\
Publikus események, amikre más rendszerek reagálhatnak.

**Miért fontos:** - testreszabhatóság - plugin-szerű működés -
zero-dependency integráció

------------------------------------------------------------------------

## 9. 🔐 ACCESS GATE

**Jelentés:**\
Központi szabályrendszer hozzáférésekhez (job, item, level stb.)

**Miért fontos:** - egységes jogosultság kezelés - adapter oldja meg a
framework különbségeket

------------------------------------------------------------------------

## 10. 🧱 PURE MODULE

**Jelentés:**\
A modul csak API-t ad vissza, nincs mellékhatása betöltéskor.

**Miért fontos:** - kiszámítható működés - tesztelhetőség - nincs
rejtett bug

**GOOD ✅**

``` lua
return {
    addItem = function() end
}
```

**BAD ❌**

``` lua
RegisterNetEvent("something")
```

👉 Miért rossz: rejtett side-effect

------------------------------------------------------------------------

## 11. 🚫 NO GLOBAL POLLUTION

**Jelentés:**\
Nincs \_G szennyezés (kivéve explicit override).

**Miért fontos:** - konfliktusok elkerülése - nagy szervereken kritikus

**GOOD ✅**

``` lua
local M = {}
return M
```

**BAD ❌**

``` lua
Inventory = {}
```

👉 Miért rossz: globál konfliktus

------------------------------------------------------------------------

## 12. 🧪 DEPENDENCY INJECTION

**Jelentés:**\
A modul nem maga keres dependency-t, hanem megkapja.

**Miért fontos:** - tesztelhető - cserélhető - mockolható

**GOOD ✅**

``` lua
return function(ctx)
    return {
        addItem = function(p, item)
            ctx.exports.inv:add(p, item)
        end
    }
end
```

**BAD ❌**

``` lua
exports["qb-inventory"]:AddItem(...)
```

👉 Miért rossz: nem cserélhető

------------------------------------------------------------------------

## 13. 📦 MODULAR PACKAGING

**Jelentés:**\
Csak a szükséges modulok kerülnek szállításra.

**Miért fontos:** - kisebb footprint - gyorsabb load - kevesebb hiba

------------------------------------------------------------------------

## 14. 🏗 BUILD TARGET STRATEGY

**Jelentés:**\
Külön modulpack külön framework-ökre (qb, esx, stb.)

**Miért fontos:** - nincs felesleges kód - tiszta deploy - jobb
performance

------------------------------------------------------------------------

## 15. 🔍 FEATURE GATING

**Jelentés:**\
Feature-ök ki/be kapcsolhatók config alapján.

**Miért fontos:** - testreszabhatóság - nem fut felesleges logika

**GOOD ✅**

``` lua
if not Config.crafting then return end
```

**BAD ❌**

``` lua
RegisterNetEvent("craft")
```

👉 Miért rossz: felesleges futás

------------------------------------------------------------------------

## 16. 📢 NO SILENT FAILURE

**Jelentés:**\
Minden hiba visszatérési értékkel jelezve van.

**Miért fontos:** - debugolhatóság - kiszámítható működés

**GOOD ✅**

``` lua
return false, "inventory_full"
```

**BAD ❌**

``` lua
return false
```

👉 Miért rossz: nincs információ

------------------------------------------------------------------------

## 17. 🧾 ERROR CODE STANDARD

**Jelentés:**\
Egységes string alapú hibakódok.

**Példák:**

``` lua
"inventory_full"
"no_access"
"feature_disabled"
```

**Miért fontos:** - UI / log / API kompatibilitás

**BAD ❌**

``` lua
"Error happened"
```

👉 Miért rossz: nem kezelhető

------------------------------------------------------------------------

## 18. 🔁 FALLBACK STRATEGY

**Jelentés:**\
Van alap implementáció, ha semmi más nincs.

**Miért fontos:** - script mindig működik - plug-and-play élmény

**GOOD ✅**

``` lua
-- fallback.lua
return {
    notify = function(msg)
        print(msg)
    end
}
```

**BAD ❌**

``` lua
error("notify not found")
```

👉 Miért rossz: nem plug-and-play

------------------------------------------------------------------------

## 19. 🔗 LOOSE COUPLING

**Jelentés:**\
A komponensek minimálisan függenek egymástól.

**Miért fontos:** - könnyű csere - stabil rendszer

**GOOD ✅**

``` lua
Inventory.addItem(...)
Notify.send(...)
```

**BAD ❌**

``` lua
exports["qb-core"]:GetPlayer(...)
exports["qb-inventory"]:AddItem(...)
```

👉 Miért rossz: erős kötés

------------------------------------------------------------------------

## 20. 📚 STANDARD LIBRARY CONCEPT

**Jelentés:**\
A modules csomag egy "alap könyvtár".

**Miért fontos:** - újrahasznosíthatóság - egységes működés

------------------------------------------------------------------------

## 21. 🔄 BACKWARD COMPATIBILITY

**Jelentés:**\
Régi verziók tovább működnek.

**Miért fontos:** - frissítések nem törnek - bizalom

------------------------------------------------------------------------

## 22. 🧠 SELF-HEALING INTEGRATION

**Jelentés:**\
A rendszer automatikusan a legjobb elérhető megoldást használja.

**Miért fontos:** - kevesebb manuális setup - jobb UX

**GOOD ✅**

``` lua
LoadModule("inventory")
```

**BAD ❌**

``` lua
Config.Inventory = "qb"
```

👉 Miért rossz: user error

------------------------------------------------------------------------

## 23. 🧭 BYOB (Bring Your Own Backend)

**Jelentés:**\
A szerver saját rendszereit használja.

**Miért fontos:** - nincs vendor lock-in - maximális kompatibilitás

**GOOD ✅**

``` lua
eco_inventory = customInventory
```

**BAD ❌**

``` lua
require("modules.inventory.qb")
```

👉 Miért rossz: nincs flexibilitás

------------------------------------------------------------------------

## 24. 🔥 MENTÁLIS MODELL

Az egész rendszer 3 szabályra redukálható:

1.  Ne erőltess semmit (override first)
2.  Mindig legyen fallback (graceful)
3.  Minden legyen hookolható (event-driven)

------------------------------------------------------------------------

## ✅ GYORS CHECKLIST

✔ Van loader priority chain\
✔ Van event minden fontos actionre\
✔ Van fallback minden modulra\
✔ Nincs hard dependency\
✔ Van error code minden return-ben

------------------------------------------------------------------------

> Ha ezek megvannak → valódi plug-and-play rendszer\
> Ha nem → csak "jobban megírt script"
