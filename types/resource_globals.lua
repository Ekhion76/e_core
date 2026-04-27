---@meta
--luacheck: push ignore 111
--- e_core resource global runtime state for LuaLS.
--- Values are populated at runtime by bridge/server/client modules.

---@type table
PlayerMetaStore = {}

---@type table
ClientMetaStore = {}

---@type table
eCoreNui = {}

---@type table
ECoreHudLayout = {}

---@type boolean|nil
CORE_READY = nil

---@type table|nil
REGISTERED_ITEMS = nil

---@type table[]
ECORE_DB_MIGRATIONS = {}

---@type integer
ECORE_DB_SCHEMA_TARGET = 1

---@type table|nil
sharedEvents = nil

---@type table|nil
ESXEvents = nil

---@type table|nil
QBEvents = nil

---@type table|nil
locales = nil

---@type boolean|nil
_ECORE_INIT_FAILED = nil

--- Bridge: `src/bridge/framework_resource_registry.lua` (set induláskor a `framework_config`-ból).
---@param esx string
---@param qb string
---@return nil
function ecore_framework_resource_set(esx, qb) end

---@return string
function ecore_framework_resource_esx() end

---@return string
function ecore_framework_resource_qb() end

--luacheck: pop
