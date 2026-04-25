--- Egy belépési pont: melyik legacy core aktív, ESX_CORE / QB_CORE / FRAMEWORK / eCore / Config.
--- ConVar: e_core:framework = auto | esx | qb (kis/nagybetű mindegy, trimelve).
--- Két core egyszerre + auto → error (állítsd a ConVart).

local function normalize_framework_mode(raw)
    local v = string.lower(tostring(raw or 'auto'):gsub('^%s*(.-)%s*$', '%1'))
    if v == '' then
        v = 'auto'
    end
    if v ~= 'auto' and v ~= 'esx' and v ~= 'qb' then
        print(('[^1e_core^7] Ismeretlen e_core:framework=%s, ^3auto^7 használata.'):format(v))
        v = 'auto'
    end
    return v
end

local esx_started = GetResourceState('es_extended') == 'started'
local qb_started = GetResourceState('qb-core') == 'started'
local mode = normalize_framework_mode(GetConvar('e_core:framework', 'auto'))

local chosen

if esx_started and qb_started then
    if mode == 'auto' then
        error(
            '[e_core] es_extended és qb-core is fut. Csak egy legacy core támogatott. Állítsd például: setr e_core:framework "esx" vagy "qb".'
        )
    end
    chosen = mode
    print(('[^3e_core^7] FIGYELMEZETÉS: mindkét core fut; aktív ág kényszerítve: ^2%s^7.'):format(chosen))
elseif esx_started then
    if mode == 'qb' then
        error('[e_core] e_core:framework=qb, de a qb-core nem fut (vagy nem started).')
    end
    chosen = 'esx'
elseif qb_started then
    if mode == 'esx' then
        error('[e_core] e_core:framework=esx, de az es_extended nem fut (vagy nem started).')
    end
    chosen = 'qb'
else
    if mode ~= 'auto' then
        print(('[^1e_core^7] e_core:framework=%s, de sem es_extended, sem qb-core nem fut ezen a pillanatban.'):format(mode))
    end
    print('[^3e_core^7] Nem fut es_extended és qb-core sem az e_core indulásakor. Ellenőrizd az ensure sorrendet (core előbb).')
    FRAMEWORK = nil
    eCore = {}
    Config = {}
    ESX_CORE = false
    QB_CORE = false
    return
end

if chosen == 'esx' then
    if not esx_started then
        error('[e_core] Az ESX ág választva, de es_extended nem started.')
    end
    e_core_apply_esx_config()
    ESX_CORE = true
    QB_CORE = false
elseif chosen == 'qb' then
    if not qb_started then
        error('[e_core] A QB ág választva, de qb-core nem started.')
    end
    e_core_apply_qb_config()
    ESX_CORE = false
    QB_CORE = true
else
    error('[e_core] Belső hiba: ismeretlen chosen=' .. tostring(chosen))
end
