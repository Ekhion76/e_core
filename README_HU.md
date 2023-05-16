# e_core

#### Mire való az e_core?
Az e_core egy adapter, mely az ESX és QBCore, QBox keretrendszerekkel való kompatibilitáshoz nyújt támogatást.

##### Célja:
- eco_crafting és a jövöben készülő szkripteknek biztosítani a keretrendszer független működést 
- a felhasználóknak biztosítani a testreszabhatóságot

##### Csatoló felületet biztosít:
- saját inventory exportjainak beillesztésére (addItem, removeItem, stb..) 
- üzenet rendszerek beillesztésére (sendNotify, drawText, hideText, progressbar)
- ezen kívül különféle core funkciók is illeszthetők a szkriptben látható példák segítségével

##### Tartalmaz:
- egy jártasság(xp) és labor(munkaerő) rendszert, mely egy beépített metaadat tárolót használ.
- lua segédfunkciókat
- fiveM segédfunkciókat

Ha alap szervered van, nincs szükség módosításokra.
Ha ox_inventoryt használsz, nincs szükség módosításokra.

Konfig fájlok:
- standalone/config/ - globális beállítások
- standalone/overrides/custom_inventory/config.lua - Inventory specifikus beállítások

**FONTOS!** Az e_core-t az eco scriptek előtt szükséges indítani a server.cfg fájlban!

```
    # ECO SCRIPTS
    ensure e_core
    ensure eco_crafting
```
**FONTOS!** A későbbi frissítések felülírása miatt minden változtatást a 'standalone' mappában célszerű elvégezni!
A 'standalone' mappa nem más, mint felülírási funkciók gyűjteménye. A bridge mappában lévő összes funkció átmásolható a 'standalone' mappába, és ott felülírható.

**FONTOS!** Másold át a bridge függvényeket a 'standalone' mappába és írd felül! (persze csak szükség esetén)

Példa a testreszabásra:

```lua
    function eCore:sendMessage(message, mType, mSec) -- bridge/esx/client.lua

        ESX.ShowNotification(message, mSec, mType)
    end

    --- OVERRIDE a 'standalone/overrides/...' mappában:
    
    function eCore:sendMessage(message, mType, mSec) -- standalone/overrides/core/client.lua

        PELDA.SajatUzenom(message, mSec, mType)
    end
```
Példa egy inventory funkció felülírásra:
```lua
    function eCore:removeItem(xPlayer, item, count, metadata, slot) -- bridge/esx/server.lua
    
        xPlayer.removeInventoryItem(item, count, metadata, slot)
    end

    --- OVERRIDE a 'standalone/overrides/...' mappában:
    
    function eCore:removeItem(xPlayer, item, count, metadata, slot) -- standalone/overrides/avp_grid_inventory/server.lua
    
        return exports["avp_grid_inventory"]:RemoveItemBy(xPlayer.source, count, item)
    end
```

#### Labor and skill rendszer:

A koncepció az ArcheAge MMORPG mintájára működik. Az egyes feladatok elvégzése munkapontokba kerül, ami növeli a karakter képességeit.

Például, ha az 'eco_collecting' szkripttel betakarítasz egy zöldséget, az 5 laborpontba kerül, és hozzáadódik a betakarítási készséghez. Így a későbbiekben a rangbeállítás szerint kedvezményeket kaphat, például: gyorsabb betakarítás, kevesebb munkapontért.

A crafting rendszerben beállítható, hogy egy tárgyat csak egy bizonyos jártasság elérése után lehessen előállítani, és hány munkapontba kerül az elkészítése.

Az exportok segítségével ezt beépítheti bármelyik saját szkriptbe. Lásd:

- export_examples_server.md
- export_examples_client.md

Az e_core felhasznál ESX és QBCore szkript részleteket is.
