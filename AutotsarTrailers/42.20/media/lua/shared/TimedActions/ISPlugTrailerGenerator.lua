--***********************************************************
--**                    	 iBrRus                        **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISPlugTrailerGenerator = ISBaseTimedAction:derive("ISPlugTrailerGenerator");

function ISPlugTrailerGenerator:isValid()
	-- Plugging in anchors an IsoGenerator to a fixed world square. A hitched
	-- trailer would then be towed away from it, leaving that generator powering
	-- its old location forever. isValid() is re-evaluated for the whole action,
	-- so hitching the trailer mid-plug aborts it too.
	-- Self-contained on purpose: media/lua/server does not load on MP clients,
	-- so Trailers.* is not reachable from here.
	local trailer = self.trailer
	if not trailer then return false end
	return trailer:getVehicleTowedBy() == nil and trailer:getVehicleTowing() == nil
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
