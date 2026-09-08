require "TimedActions/ISBaseTimedAction"

ISStartTrailerHomeEngine = ISBaseTimedAction:derive("ISStartTrailerHomeEngine")

function ISStartTrailerHomeEngine:isValid()
	local vehicle = self.character:getVehicle()
	return vehicle ~= nil and
		not vehicle:isEngineRunning() and 
		not vehicle:isEngineStarted()
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

