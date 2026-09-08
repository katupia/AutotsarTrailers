--***********************************************************
--**                    	 iBrRus                        **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISUnplugTrailerGenerator = ISBaseTimedAction:derive("ISUnplugTrailerGenerator");

function ISUnplugTrailerGenerator:isValid()
	return true
end

function ISUnplugTrailerGenerator:waitToStart()
	self.character:faceThisObject(self.trailer)
	return self.character:shouldBeTurning()
end

function ISUnplugTrailerGenerator:update()
	self.character:faceThisObject(self.trailer)
end

function ISUnplugTrailerGenerator:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
end

function ISUnplugTrailerGenerator:stop()
    ISBaseTimedAction.stop(self);
end

function ISUnplugTrailerGenerator:perform()
    ISBaseTimedAction.perform(self);
end

function ISUnplugTrailerGenerator:complete()
    TrailerCommands.deleteGeneratorServer(self.trailer)
    return true
end

function ISUnplugTrailerGenerator:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 300;
end

function ISUnplugTrailerGenerator:new(character, trailer)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.trailer = trailer;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.stopOnAim = false;
    o.maxTime = o:getDuration();
    return o;
end
