require "TimedActions/ISBaseTimedAction"

ISShutOffTrailerHomeEngine = ISBaseTimedAction:derive("ISShutOffTrailerHomeEngine")

function ISShutOffTrailerHomeEngine:isValid()
	local vehicle = self.character:getVehicle()
	local motor = vehicle and vehicle:getPartById("TrailerEngine")
	return motor ~= nil and motor:getModData().tsarEngineRunning == true
end

function ISShutOffTrailerHomeEngine:perform()
	ISBaseTimedAction.perform(self)
	if TrailersEngineSound and TrailersEngineSound.playStop then
		TrailersEngineSound.playStop(self.character:getVehicle())
	end
end

function ISShutOffTrailerHomeEngine:complete()
    local vehicle = self.character:getVehicle()
    TrailerCommands.startGeneratorEngineServer(vehicle, false)
    return true
end

function ISShutOffTrailerHomeEngine:getDuration()
    return 1
end

function ISShutOffTrailerHomeEngine:new(character)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.stopOnAim = false;
    o.maxTime = o:getDuration();
    return o;
end
