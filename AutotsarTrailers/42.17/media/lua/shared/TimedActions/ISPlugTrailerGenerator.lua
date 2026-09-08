--***********************************************************
--**                    	 iBrRus                        **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISPlugTrailerGenerator = ISBaseTimedAction:derive("ISPlugTrailerGenerator");

function ISPlugTrailerGenerator:isValid()
	return true
end

function ISPlugTrailerGenerator:waitToStart()
	self.character:faceThisObject(self.trailer)
	return self.character:shouldBeTurning()
end

function ISPlugTrailerGenerator:update()
	self.character:faceThisObject(self.trailer)
end

function ISPlugTrailerGenerator:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
end

function ISPlugTrailerGenerator:serverStart()
    self.trailer:setMass(10000)--?setBrakingForce?
end

function ISPlugTrailerGenerator:serverStop()
    self.trailer:setMass(1000)
end

function ISPlugTrailerGenerator:perform()
    ISBaseTimedAction.perform(self);
end

function ISPlugTrailerGenerator:complete()
    self.trailer:setMass(1000)
    TrailerCommands.createGeneratorServer(self.trailer)
    return true
end

function ISPlugTrailerGenerator:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 300;
end

function ISPlugTrailerGenerator:new(character, trailer)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.trailer = trailer;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.stopOnAim = false;
    o.maxTime = o:getDuration();
    return o
end
