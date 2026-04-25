---@meta
--- e_core resource global runtime state for LuaLS.
--- Values are populated at runtime by bridge/server/client modules.

---@type table
ECO = {}

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
