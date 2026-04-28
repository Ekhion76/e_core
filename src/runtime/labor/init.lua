--- Labor domain (server): side effects only (timers / periodic ticks).
--- Requires `logic.lua` and schedules auto labor increase if enabled.

local labor = lib.require('src/runtime/labor/logic')

local function canScheduleAutoLabor()
    if not Config.systemMode.labor then
        return false
    end
    local t = tonumber(Config.laborIncreaseTime)
    local step = tonumber(Config.laborIncrease)
    return t and t > 0 and step and step > 0
end

local function scheduleNextTick()
    SetTimeout(Config.laborIncreaseTime * 60000, function()
        if not canScheduleAutoLabor() then
            scheduleNextTick()
            return
        end

        local timeStamp = os.time()
        local chunkSize = GetConvarInt('e_core:labor_tick_chunk', 0)
        if chunkSize < 0 then
            chunkSize = 0
        end

        local ids = labor.collectOnlineTargets()
        if #ids == 0 then
            scheduleNextTick()
            return
        end

        labor.applyIncreaseChunks(ids, timeStamp, 1, chunkSize, scheduleNextTick)
    end)
end

if canScheduleAutoLabor() then
    scheduleNextTick()
end

