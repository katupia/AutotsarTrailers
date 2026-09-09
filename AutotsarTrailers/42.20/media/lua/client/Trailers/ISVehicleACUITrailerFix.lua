-- The heater / AC panel enables its OK button on isEngineRunning() or
-- isKeysInIgnition(). Both are permanently false on a trailer whose "Engine"
-- part was renamed to "TrailerEngine" for the pivot fix, so the panel opened
-- but could never be applied. Re-enable it while the trailer motor runs --
-- Trailers.Update.TrailerHeater already drives the heater from that same flag.

local function motorRunning(vehicle)
    local motor = vehicle and vehicle:getPartById("TrailerEngine")
    return motor ~= nil and motor:getModData().tsarEngineRunning == true
end

local oldUpdateButtons = ISVehicleACUI.updateButtons

function ISVehicleACUI:updateButtons()
    oldUpdateButtons(self)
    if motorRunning(self.vehicle) then
        self.ok:setEnable(true)
        self.ok:setTooltip(nil)
    end
end
