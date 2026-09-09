require "TimedActions/ISBaseTimedAction"

ISStartTrailerHomeEngine = ISBaseTimedAction:derive("ISStartTrailerHomeEngine")

-- isEngineRunning()/isEngineStarted() read the VehicleEngine, which these
-- trailers no longer have (see part TrailerEngine). The motor state is a
-- modData flag; the motor may be started while hitched (the server refuses it
-- for the generator trailer only).
function ISStartTrailerHomeEngine:isValid()
	local vehicle = self.character:getVehicle()
	if not vehicle then return false end
	local motor = vehicle:getPartById("TrailerEngine")
	return motor ~= nil and motor:getModData().tsarEngineRunning ~= true
end

function ISStartTrailerHomeEngine:perform()
	ISBaseTimedAction.perform(self)
	-- Client-side ignition one-shot; the authoritative state is set in complete().
	if TrailersEngineSound and TrailersEngineSound.playStart then
		TrailersEngineSound.playStart(self.character:getVehicle())
	end
end

function ISStartTrailerHomeEngine:complete()
    local vehicle = self.character:getVehicle()
    TrailerCommands.startGeneratorEngineServer(vehicle, true)
    return true
end

function ISStartTrailerHomeEngine:getDuration()
    return 1
end

function ISStartTrailerHomeEngine:new(character)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.stopOnAim = false;
    o.maxTime = o:getDuration();
    return o;
end

