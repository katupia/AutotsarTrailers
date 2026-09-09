require "TimedActions/ISBaseTimedAction"

ISHotwireTrailerHome = ISBaseTimedAction:derive("ISHotwireTrailerHome")

function ISHotwireTrailerHome:isValid()
	local vehicle = self.character:getVehicle()
	if not vehicle then return false end
	-- Nothing to hotwire on a TrailerEngine trailer: the motor is a pull-start
	-- power plant with no ignition. isEngineRunning()/isEngineStarted() are also
	-- permanently false there, which would have made this action always valid.
	if vehicle:getPartById("TrailerEngine") then return false end
	return not vehicle:isEngineRunning() and not vehicle:isEngineStarted()
end

function ISHotwireTrailerHome:update()
    self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function ISHotwireTrailerHome:start()
end

function ISHotwireTrailerHome:stop()
	ISBaseTimedAction.stop(self)
end

function ISHotwireTrailerHome:perform()
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISHotwireTrailerHome:complete()
    local character = self.character
    local vehicle = character and character:getVehicle()
    if vehicle then
        vehicle:tryHotwire(character:getPerkLevel(Perks.Electricity));--hotwireTrailerHomeEngine
    end
    return true
end

function ISHotwireTrailerHome:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 200 - (self.character:getPerkLevel(Perks.Electricity) * 3);
end

function ISHotwireTrailerHome:new(character)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.stopOnAim = false;
    o.maxTime = o:getDuration();
    return o
end
