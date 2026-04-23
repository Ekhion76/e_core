-- luacheck: push ignore 131
---@meta
--- FiveM + oxmysql + ox_lib minimális globálok – csak LuaLS / IDE; nem fut runtime-on.
--- Bővítsd, ha új natív / export jelenik meg és zajt okoz a diagnosztika.

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

function CreateThread(fn) end
function Wait(ms) end
function SetTimeout(ms, fn) end
function RegisterNetEvent(name, fn) end
function AddEventHandler(name, fn) end
function RegisterServerEvent(name, fn) end
function TriggerClientEvent(name, target, ...) end
function TriggerServerEvent(name, ...) end
function TriggerEvent(name, ...) end
function GetCurrentResourceName() return "" end
function GetResourceState(name) return "" end
function GetConvar(name, default) return "" end
function GetConvarInt(name, default) return 0 end
function GetPlayerName(playerId) return "" end
function error(message, level) end
function pcall(f, ...) end
function tonumber(e, base) end
function type(v) return "" end
function pairs(t) end
function ipairs(t) end
function print(...) end
function SetEntityCoords(entity, x, y, z, ...) end
function DoesEntityExist(entity) return false end
function DeleteEntity(entity) end
function PlayerPedId() return 0 end
function PlayerId() return 0 end
function GetPlayerServerId(player) return 0 end
function SendNUIMessage(payload) end
function RegisterNUICallback(name, fn) end
function SetNuiFocus(hasFocus, hasCursor) end
function IsNuiFocused() return false end
function RegisterKeyMapping(commandName, description, defaultMapper, defaultParameter) end
function RegisterCommand(name, fn, restricted) end

---@type number|nil
source = nil
-- luacheck: pop
