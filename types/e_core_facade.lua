---@meta
--- e_core facade LuaLS stub.
--- Canonical method list: `docs/PUBLIC_API_HU.md` §6-10.
--- Available keys can differ by framework (ESX/QB) and side (client/server).

---@class eCoreBridgeContract
---@field schemaVersion number Contract table shape / semantics version (bump when fields change).
---@field resource string Resource name used for metadata (`GetCurrentResourceName()`).
---@field lifecycleMergedKeys string[] Keys merged from `eCoreLifecycle_buildPublicAPI` onto the facade (`log` optional at runtime).

---@class eCore
---@field ecoreVersion string Resource semver from manifest (`GetResourceMetadata`, fallback `0.0.0`).
---@field bridgeContract eCoreBridgeContract Machine-readable lifecycle merge contract.
---@field framework string|nil Same as `getFrameWork()` (merged 0.1.3+).
---@field config table Live `Config` reference (merged 0.1.3+).
---@field i18n table|nil `{ translate, translateU }` (merged 0.1.3+).
---@field util table|nil Shared debug / loader helpers (merged 0.1.3+).
---@field log table|nil Server-only when Discord module active: `{ discord = { create = fun(...) } }`.
---@field helper table
---@field GroupAccess table|nil Class-like helper: `GroupAccess` with `check(playerData, data)`.
---@field Err table<string, string>
---@field isReady fun(self: eCore): boolean
---@field getInventoryWeight fun(self: eCore, playerData: table): number
---@field canSwapItems fun(self: eCore, swappingItems: table, itemData: table, playerData: table): boolean|nil, string|nil
---@field canCarryItem fun(self: eCore, itemData: table, playerData: table): boolean|nil, string|nil
---@field getAmountOfItems fun(self: eCore, inventory: table): table
---@field getRegisteredItem fun(self: eCore, name: string): table|nil
---@field getRegisteredItems fun(self: eCore): table|false|nil, string|nil
---@field convertItems fun(self: eCore, items: table): table
---@field convertPlayer fun(self: eCore, playerData: table, newJob?: table, newGang?: table): table
---@field triggerCallback fun(self: eCore, name: string, cb: fun(...), ...): nil
---@field createCallback fun(self: eCore, name: string, fn: fun(source: number, cb: function, ...)): nil
---@field getPlayer fun(self: eCore, id: number|table?, ...): table|nil
---@field addItem fun(self: eCore, xPlayer: table, item: string, count: number, metadata?: table, slot?: number): boolean|nil, string|nil
---@field removeItem fun(self: eCore, xPlayer: table, item: string, count: number, metadata?: table, slot?: number): boolean|nil, string|nil
---@field removeItems fun(self: eCore, xPlayer: table, items: table): boolean|nil, string|nil
---@field getInventory fun(self: eCore, player: table): table
---@field sendMessage fun(self: eCore, target: number|table, message: any, ...): nil
eCore = {}

---@type string|nil
FRAMEWORK = nil

---@type boolean
ESX_CORE = false

---@type boolean
QB_CORE = false

---@type table
Config = {}

---@type table<string, string>
eCoreErr = {}

---@type table
hf = {}
