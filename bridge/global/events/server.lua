sharedEvents = {}

--- Note: `e_core:createVehicle` is intentionally not registered here.
--- Use `e_core:createCallback` only (`bridge/global/callbacks/server.lua`) to avoid
--- exposing an open RegisterNetEvent vehicle-spawn entry from client (net audit G).
