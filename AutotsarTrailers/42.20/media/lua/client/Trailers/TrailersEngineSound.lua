-- Client-side sound for the trailer motor.
--
-- The vanilla engine audio loop is driven by the VehicleEngine, which these
-- trailers no longer have since the pivot fix renamed their "Engine" part to
-- "TrailerEngine". Without this the motor would run completely silently.
-- Mirrored with the generator sound events the trailers already declare in
-- their script `sound` block:
--     GeneratorStarting / GeneratorLoop / GeneratorStopping
--
-- The motor state lives in the TrailerEngine part's modData (tsarEngineRunning),
-- which is transmitted to clients. Start/stop one-shots are fired from the
-- TimedAction perform() hooks; the loop is reconciled on a throttled tick so it
-- also stops when the motor stalls on its own (out of fuel, dead part).
--
-- State is kept in file-locals rather than on the global `Trailers` table: the
-- server-side Lua owns `Trailers` and re-creates it (`Trailers = {}`) on mode
-- transitions, which would wipe anything parked there.

local loopPlaying = {}   -- vehicleId -> true while GeneratorLoop is running
local soundTick = 0

TrailersEngineSound = TrailersEngineSound or {}

local function isMotorRunning(vehicle)
    local motor = vehicle and vehicle:getPartById("TrailerEngine")
    return motor ~= nil and motor:getModData().tsarEngineRunning == true
end

function TrailersEngineSound.playStart(vehicle)
    local emitter = vehicle and vehicle:getEmitter()
    if emitter then emitter:playSound("GeneratorStarting") end
end

function TrailersEngineSound.playStop(vehicle)
    local emitter = vehicle and vehicle:getEmitter()
    if emitter then emitter:stopSoundByName("GeneratorLoop") end
    if emitter then emitter:playSound("GeneratorStopping") end
    if vehicle then loopPlaying[vehicle:getId()] = nil end
end

local function syncLoop(vehicle)
    local id = vehicle:getId()
    local emitter = vehicle:getEmitter()
    if isMotorRunning(vehicle) then
        if not loopPlaying[id] then
            if emitter then emitter:playSoundLooped("GeneratorLoop") end
            loopPlaying[id] = true
        end
    elseif loopPlaying[id] then
        if emitter then emitter:stopSoundByName("GeneratorLoop") end
        loopPlaying[id] = nil
    end
end

local function pollEngineSounds()
    soundTick = soundTick + 1
    if soundTick % 60 ~= 0 then return end
    local cell = getCell()
    if not cell or not cell.getVehicles then return end
    local vehicles = cell:getVehicles()
    if not vehicles or not vehicles.iterator then return end
    local iter = vehicles:iterator()
    if not iter then return end
    local seen = {}
    while iter:hasNext() do
        local v = iter:next()
        if v and not (v.isRemovedFromWorld and v:isRemovedFromWorld())
            and v:getPartById("TrailerEngine") then
            seen[v:getId()] = true
            syncLoop(v)
        end
    end
    -- Forget vehicles that are gone; their emitter died with them, so any
    -- dangling loop is already silent.
    for id in pairs(loopPlaying) do
        if not seen[id] then loopPlaying[id] = nil end
    end
end

Events.OnTick.Remove(pollEngineSounds)
Events.OnTick.Add(pollEngineSounds)
