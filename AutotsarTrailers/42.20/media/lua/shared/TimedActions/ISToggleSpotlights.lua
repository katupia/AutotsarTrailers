require "TimedActions/ISBaseTimedAction"

ISToggleSpotlights = ISBaseTimedAction:derive("ISToggleSpotlights");

function ISToggleSpotlights:isValid()
    return true;
end

function ISToggleSpotlights:start()
end

function ISToggleSpotlights:stop()
    ISBaseTimedAction.stop(self);
end

function ISToggleSpotlights:perform()
    self.trailer:getSquare():playSound("LightSwitch")
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function ISToggleSpotlights:complete()
    TrailerCommands.setHeadlightsOnServer(self.trailer, not self.trailer:getHeadlightsOn())
    return true
end

function ISToggleSpotlights:getDuration()
    return 1
end

function ISToggleSpotlights:new(character, trailer)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.trailer = trailer;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.stopOnAim = false;
    o.maxTime = o:getDuration();
    return o;
end
