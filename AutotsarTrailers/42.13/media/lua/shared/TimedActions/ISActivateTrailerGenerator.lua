--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISActivateTrailerGenerator = ISBaseTimedAction:derive("ISActivateTrailerGenerator");

function ISActivateTrailerGenerator:isValid()
    if self.activate == self.generator:isActivated() then return false end
    if self.activate and not self.generator:isConnected() then return false end
    return self.generator:getObjectIndex() ~= -1
end

function ISActivateTrailerGenerator:waitToStart()
	self.character:faceThisObject(self.generator)
	return self.character:shouldBeTurning()
end

function ISActivateTrailerGenerator:update()
	self.character:faceThisObject(self.generator)
end

function ISActivateTrailerGenerator:start()
	self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Low")
end

function ISActivateTrailerGenerator:stop()
    ISBaseTimedAction.stop(self);
end

function ISActivateTrailerGenerator:perform()
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function ISActivateTrailerGenerator:complete()
    local fuelAmount = self.trailer:getPartById("GasTank"):getContainerContentAmount()/self.trailer:getPartById("GasTank"):getContainerCapacity() * 100
    self.generator:setFuel(fuelAmount)
    if self.generator:getCondition() < 1 or self.generator:getFuel() <= 0 or self.activate and self.generator:getCondition() <= 50 and ZombRand(3) == 0 then
        self.generator:failToStart()
    else
        TrailerCommands.startGeneratorEngineServer(self.trailer, self.activate)
    end
    return true
end

function ISActivateTrailerGenerator:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 30
end

function ISActivateTrailerGenerator:new(character, trailer, generator, activate)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.trailer = trailer;
    o.generator = generator;
    o.activate = activate;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.stopOnAim = false;
    o.maxTime = o:getDuration();
    return o;
end
