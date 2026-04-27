--- Internal bootstrap: `_eCoreInternal`, explicit extension registration, PURE public API slice.
--- Contract: do not read `_eCoreInternal` from consumer code; use `exports.e_core:getCore()` only.
--- @module 'src.bridge.ecore_lifecycle'

--- Bump when `eCore.bridgeContract` shape or semantics change (independent of `ecoreVersion` / fxmanifest semver).
local ECORE_BRIDGE_CONTRACT_SCHEMA_VERSION = 1

--- Runtime-only internal table (global by Lua limitation; not exported to consumers).
--- @class ECoreInternal
--- @field helpers table `{ base = hf, ecore = hfe }`
--- @field services table Reserved for internal domain services.
--- @field extensions table Optional feature modules (discord, …).
--- @field runtime table `{ frameworkKey = string|nil, config = table }` snapshot refs for facade.
--- @field facadeBindings table|nil `{ i18n = table, util = table }` function refs bound during register phase.

--- Initializes `_eCoreInternal` shell and helper wiring. Idempotent.
--- Does not register extensions (that runs from `registerExtensions()`).
--- @return nil
function eCoreLifecycle_initInternal()
    if type(_eCoreInternal) ~= 'table' then
        --- @type ECoreInternal
        _eCoreInternal = {
            helpers = {},
            services = {},
            extensions = {},
            runtime = {
                frameworkKey = nil,
                config = nil,
            },
            facadeBindings = nil,
        }
    end
    _eCoreInternal.helpers.base = hf
    _eCoreInternal.helpers.ecore = hfe
end

--- Registers Discord extension on server when `createDiscordLog` global exists.
--- @return nil
function eCoreLifecycle_registerDiscordExtension()
    if not IsDuplicityVersion() then
        return
    end
    if type(createDiscordLog) ~= 'function' then
        return
    end
    _eCoreInternal.extensions.discordLog = {
        --- @param webhook string
        --- @param botName string|nil
        --- @param opts table|nil
        --- @return table|false
        create = createDiscordLog,
    }
end

--- Reserved hook for bundled HUD extension surface (optional `hud_drag` remains consumer opt-in).
--- @return nil
function eCoreLifecycle_registerHudExtension()
    -- Intentionally empty: no mandatory HUD extension object in core v1.
end

--- Binds facade function refs and snapshots runtime keys; then runs explicit extension hooks.
--- Mutates `_eCoreInternal` only (not the public `eCore` table).
--- @return nil
function eCoreLifecycle_registerExtensions()
    eCoreLifecycle_initInternal()
    _eCoreInternal.facadeBindings = {
        i18n = {
            translate = translate,
            translateU = translateU,
        },
        util = {
            cLog = cLog,
            print_r = print_r,
            createBlip = createBlip,
            animDictLoader = animDictLoader,
            modelLoader = modelLoader,
            fxLoader = fxLoader,
        },
    }
    _eCoreInternal.runtime.frameworkKey = FRAMEWORK
    _eCoreInternal.runtime.config = Config
    eCoreLifecycle_registerDiscordExtension()
    eCoreLifecycle_registerHudExtension()
end

--- Second-phase init for extension cross-deps (`ext.init(ctx)` optional contract).
--- @param ctx table Same as `_eCoreInternal`.
--- @return nil
function eCoreLifecycle_initExtensions(ctx)
    ctx = ctx or _eCoreInternal
    if type(ctx.extensions) ~= 'table' then
        return
    end
    for _, ext in pairs(ctx.extensions) do
        if type(ext) == 'table' and type(ext.init) == 'function' then
            ext.init(ctx)
        end
    end
end

--- PURE: reads `_eCoreInternal` only; returns a **new** table for one-shot merge into `eCore`.
--- @return table api Top-level keys: `ecoreVersion`, `bridgeContract`, `framework`, `config`, `i18n`, `util`, optional `log`.
function eCoreLifecycle_buildPublicAPI()
    local out = {}
    local res = GetCurrentResourceName()
    local ver = GetResourceMetadata(res, 'version', 0)
    if type(ver) ~= 'string' or ver == '' then
        ver = '0.0.0'
    end
    out.ecoreVersion = ver
    -- `log` is merged only on server when Discord extension registered; key still listed for stable discovery.
    out.bridgeContract = {
        schemaVersion = ECORE_BRIDGE_CONTRACT_SCHEMA_VERSION,
        resource = res,
        lifecycleMergedKeys = { 'framework', 'config', 'i18n', 'util', 'log' },
    }
    local int = _eCoreInternal
    if type(int) ~= 'table' then
        return out
    end
    local rt = int.runtime
    if type(rt) == 'table' then
        out.framework = rt.frameworkKey
        out.config = rt.config
    end
    local fb = int.facadeBindings
    if type(fb) == 'table' then
        if type(fb.i18n) == 'table' then
            out.i18n = fb.i18n
        end
        if type(fb.util) == 'table' then
            out.util = fb.util
        end
    end
    local ext = int.extensions
    if type(ext) == 'table' and type(ext.discordLog) == 'table' and type(ext.discordLog.create) == 'function' then
        out.log = {
            discord = {
                --- @param webhook string
                --- @param botName string|nil
                --- @param opts table|nil
                --- @return table|false
                create = function(...)
                    return ext.discordLog.create(...)
                end,
            },
        }
    end
    return out
end

--- Merges shallow keys from `src` into `dest` (overwrites same keys).
--- @param dest table
--- @param src table
--- @return nil
function eCoreLifecycle_mergeShallow(dest, src)
    if type(dest) ~= 'table' or type(src) ~= 'table' then
        return
    end
    for k, v in pairs(src) do
        dest[k] = v
    end
end

eCoreLifecycle_initInternal()
