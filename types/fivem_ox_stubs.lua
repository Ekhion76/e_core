-- luacheck: push ignore 131
---@meta
--- Minimal FiveM + oxmysql + ox_lib globals for LuaLS / IDE only (not runtime).
--- Extend this file when new natives/exports appear and diagnostics become noisy.

---@class MySQL
---@field ready fun(callback: fun())
---@field query fun(query: string, parameters?: table, cb?: fun(result: any))
---@field query.await fun(query: string, parameters?: table): any
---@field update fun(query: string, parameters?: table, cb?: fun(affectedRows: number))
---@field update.await fun(query: string, parameters?: table): number
---@field scalar fun(query: string, parameters?: table, cb?: fun(result: any))
---@field scalar.await fun(query: string, parameters?: table): any
---@field prepare fun(query: string, parameters: table[])
---@field prepare.await fun(query: string, parameters: table[]): any
---@field insert fun(query: string, parameters?: table, cb?: fun(insertId: number))
MySQL = {}

---@type table
json = {}

---@type table|nil
lib = {}

---@param name string
---@param entrypoint function
function exports(name, entrypoint) end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param fn function
--- @return any result
function CreateThread(fn) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param ms any
--- @return any result
function Wait(ms) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param ms any
--- @param fn function
--- @return any result
function SetTimeout(ms, fn) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param fn function
--- @return any result
function RegisterNetEvent(name, fn) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param fn function
--- @return any result
function AddEventHandler(name, fn) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param fn function
--- @return any result
function RegisterServerEvent(name, fn) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param target any
--- @param ... any
--- @return any result
function TriggerClientEvent(name, target, ...) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param ... any
--- @return any result
function TriggerServerEvent(name, ...) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param ... any
--- @return any result
function TriggerEvent(name, ...) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function GetCurrentResourceName() return "" end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @return any result
function GetResourceState(name) return "" end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param default any
--- @return any result
function GetConvar(name, default) return "" end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param default any
--- @return any result
function GetConvarInt(name, default) return 0 end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param playerId number
--- @return any result
function GetPlayerName(playerId) return "" end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param message any
--- @param level number
--- @return any result
function error(message, level) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param f any
--- @param ... any
--- @return any result
function pcall(f, ...) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param e any
--- @param base any
--- @return any result
function tonumber(e, base) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param v any
--- @return any result
function type(v) return "" end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param t any
--- @return any result
function pairs(t) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param t any
--- @return any result
function ipairs(t) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param ... any
--- @return any result
function print(...) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param entity any
--- @param x any
--- @param y any
--- @param z any
--- @param ... any
--- @return any result
function SetEntityCoords(entity, x, y, z, ...) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param entity any
--- @return any result
function DoesEntityExist(entity) return false end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param entity any
--- @return any result
function DeleteEntity(entity) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function PlayerPedId() return 0 end
--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function PlayerId() return 0 end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param player table
--- @return any result
function GetPlayerServerId(player) return 0 end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param payload table
--- @return any result
function SendNUIMessage(payload) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param fn function
--- @return any result
function RegisterNUICallback(name, fn) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param hasFocus boolean
--- @param hasCursor boolean
--- @return any result
function SetNuiFocus(hasFocus, hasCursor) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function IsNuiFocused() return false end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param commandName any
--- @param description string
--- @param defaultMapper any
--- @param defaultParameter any
--- @return any result
function RegisterKeyMapping(commandName, description, defaultMapper, defaultParameter) end
--- Auto-generated annotation. Refine behavior details if needed.
--- @param name string
--- @param fn function
--- @param restricted any
--- @return any result
function RegisterCommand(name, fn, restricted) end

---@type number|nil
source = nil
-- luacheck: pop
