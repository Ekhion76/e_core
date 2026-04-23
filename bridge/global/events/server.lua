sharedEvents = {}

--- Megjegyzés: `e_core:createVehicle` **nem** kerül ide – csak `e_core:createCallback`
--- (`bridge/global/callbacks/server.lua`), hogy ne legyen nyitott RegisterNetEvent
--- kliensről járműspawnra (G – net audit).
