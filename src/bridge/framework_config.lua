--- Legacy core választás: `FRAMEWORK`, `ESX` / `QBCore`, `ESX_CORE` / `QB_CORE`, `eCore` / `Config` alapok.
--- ConVar: `e_core:framework` = auto | esx | qb (trim, kisbetű).
--- ConVar: `e_core:framework_resource` – nem üres és **kényszerített** esx|qb mellett felülírja az alap resource nevet (`es_extended` / `qb-core`). `auto` mellett figyelmen kívül hagyva (log).
--- Hiba esetén: kontrollált `IDLE` állapot (nincs `error()`/resource stop), hogy a szerver indulása ne sérüljön.
_G._ECORE_INIT_FAILED = false

local ESX_DEFAULT = 'es_extended'
local QB_DEFAULT = 'qb-core'

---@param s string|nil
---@return string
local function trim(s)
    return tostring(s or ''):gsub('^%s*(.-)%s*$', '%1')
end

--- Stub globals, print, then keep resource alive in controlled idle mode.
---@param msg string
---@return nil
local function enterIdle(msg)
    _G._ECORE_INIT_FAILED = true
    FRAMEWORK = nil
    ESX_CORE = false
    QB_CORE = false
    Config = {}
    eCore = {}
    print(('^1%s^7'):format(msg .. ' [e_core state=IDLE]'))
    return
end

local fw = string.lower(trim(GetConvar('e_core:framework', 'auto')))
if fw == '' then
    fw = 'auto'
end
if fw ~= 'auto' and fw ~= 'esx' and fw ~= 'qb' then
    print(('[^1e_core^7] Ismeretlen e_core:framework=%s, ^3auto^7 használata.'):format(fw))
    fw = 'auto'
end

local res = trim(GetConvar('e_core:framework_resource', ''))
if res ~= '' and fw == 'auto' then
    print(
        ('[^1e_core^7] e_core:framework_resource be van állítva, de e_core:framework=auto: az override-re nem alkalmazható. '
            .. 'Használj setr e_core:framework "esx" vagy "qb"-ot, vagy töröld a e_core:framework_resource-ot.')
    )
    res = ''
end

---@param default string
---@return string
local function resolveResource(default)
    if res ~= '' then
        return res
    end
    return default
end

-- Resource nevek a GetResourceState ellenőrzéshez (auto: mindig alap; esx|qb: override csak a kért ágra)
local scan_esx, scan_qb = ESX_DEFAULT, QB_DEFAULT
if fw == 'esx' then
    scan_esx = resolveResource(ESX_DEFAULT)
elseif fw == 'qb' then
    scan_qb = resolveResource(QB_DEFAULT)
end

local esx_started = GetResourceState(scan_esx) == 'started'
local qb_started = GetResourceState(scan_qb) == 'started'

local hint = ' Ha egyedi legacy core resource nevet használsz: setr e_core:framework "esx"|"qb" és setr e_core:framework_resource "<név>".'

-- Két core + auto → fatális
if esx_started and qb_started then
    if fw == 'auto' then
        enterIdle(
            ('[e_core] %s és %s is fut. Csak egy legacy core. Állítsd: setr e_core:framework "esx" vagy "qb".%s'):format(scan_esx, scan_qb, hint)
        )
        return
    end
    print(('[^3e_core^7] FIGYELMEZETÉS: mindkét core fut; aktív ág kényszerítve: ^2%s^7.'):format(fw))
    ecore_framework_resource_set(scan_esx, scan_qb)
    if fw == 'esx' then
        e_core_apply_esx_config()
        ESX_CORE = true
        QB_CORE = false
        return
    end
    if fw == 'qb' then
        e_core_apply_qb_config()
        ESX_CORE = false
        QB_CORE = true
        return
    end
    enterIdle('[e_core] Belső hiba: két core mellett ismeretlen e_core:framework=' .. tostring(fw))
    return
end

if esx_started then
    if fw == 'qb' then
        enterIdle(('[e_core] e_core:framework=qb, de %s nem fut (vagy nem started).%s'):format(scan_qb, hint))
        return
    end
    if fw == 'auto' or fw == 'esx' then
        ecore_framework_resource_set(scan_esx, scan_qb)
        e_core_apply_esx_config()
        ESX_CORE = true
        QB_CORE = false
        return
    end
end

if qb_started then
    if fw == 'esx' then
        enterIdle(('[e_core] e_core:framework=esx, de %s nem fut (vagy nem started).%s'):format(scan_esx, hint))
        return
    end
    if fw == 'auto' or fw == 'qb' then
        ecore_framework_resource_set(scan_esx, scan_qb)
        e_core_apply_qb_config()
        ESX_CORE = false
        QB_CORE = true
        return
    end
end

-- Nincs started core
if fw == 'esx' and not esx_started then
    enterIdle(('[e_core] e_core:framework=esx, de %s nem fut (vagy nem started).%s'):format(scan_esx, hint))
    return
end
if fw == 'qb' and not qb_started then
    enterIdle(('[e_core] e_core:framework=qb, de %s nem fut (vagy nem started).%s'):format(scan_qb, hint))
    return
end

if fw ~= 'auto' then
    print(('[^1e_core^7] e_core:framework=%s, de sem %s, sem %s nem fut (started).'):format(fw, scan_esx, scan_qb))
end
print(
    ('[^3e_core^7] Nem fut %s és %s sem az e_core indulásakor. Ellenőrizd az ensure sorrendet (core előbb).'):format(scan_esx, scan_qb)
)
-- Ugyanaz a szemantika, mint `enterIdle`-nál: a consumer `isReady` / `_ECORE_INIT_FAILED` guardok ne azt higgyék, „minden rendben, csak késik a core”.
-- Korábban `_ECORE_INIT_FAILED` false maradt, így a hívók összekeverhették a „késő induló legacy core” és a „hibás ensure” esetét (lásd docs/BRIDGE_LAYER_QUALITY_REVIEW_HU.md).
_G._ECORE_INIT_FAILED = true
FRAMEWORK = nil
eCore = {}
Config = {}
ESX_CORE = false
QB_CORE = false
