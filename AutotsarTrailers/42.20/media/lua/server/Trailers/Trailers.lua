require "CommonTemplates/CommonTemplates"

Trailers = {}
Trailers.CheckEngine = {}
Trailers.CheckOperate = {}
Trailers.ContainerAccess = {}
Trailers.Create = {}
Trailers.Init = {}
Trailers.InstallComplete = {}
Trailers.InstallTest = {}
Trailers.UninstallComplete = {}
Trailers.UninstallTest = {}
Trailers.Update = {}
Trailers.Use = {}
Trailers.Generators = {}

function Trailers.getGenerator(earthing)
    if earthing then
        local genKey = earthing:getModData().generatorID
        local generator = genKey ~= nil and Trailers.Generators[genKey]
        if genKey and not generator then
            Trailers.Generators[genKey] = Trailers.SearchGenerator(earthing)
            generator = Trailers.Generators[genKey]
        end
        return generator
    end
    return nil
end

function Trailers.Update.GeneratorEngine(vehicle, part, elapsedMinutes)
    -- print("Trailers.Update.GeneratorEngine")
    -- Was Vehicles.Update.Engine + isEngineRunning(). The trailer no longer has
    -- a part named "Engine" (see part TrailerEngine in trailer_generator.txt),
    -- so both are dead here; the motor state now lives in the TrailerEngine
    -- part's modData. Fuel burn stays on the GasTank hook below.
    Trailers.Update.TrailerEngineTemperature(vehicle, part, elapsedMinutes)
    Trailers.wearTrailerEngine(vehicle, part)
    -- There is no VehicleEngine left to stall on an empty tank, so the motor
    -- would have kept "running" at zero fuel forever (menu stuck on Turn Off,
    -- loop sound still playing). Stop it explicitly, the way the vanilla engine
    -- did; the branch below then deactivates the generator on the same tick.
    if Trailers.isTrailerEngineRunning(vehicle) then
        local gasTank = vehicle:getPartById("GasTank")
        local amount = gasTank and gasTank:getContainerContentAmount() or 0
        if amount <= 0 or part:getCondition() < 1 then
            Trailers.setTrailerEngineRunning(vehicle, false)
        end
    end
    local earthing = vehicle:getPartById("EarthingOn")
    if earthing then
        local generator = Trailers.getGenerator(earthing)
        if generator then
            if Trailers.isTrailerEngineRunning(vehicle) then
                generator:setActivated(true)
                generator:getModData().generatorTimer = 5
                vehicle:updateParts();
            else
                generator:setActivated(false)
                if generator:getModData().generatorTimer and generator:getModData().generatorTimer > 0 then
                    generator:getModData().generatorTimer = generator:getModData().generatorTimer - 1
                    vehicle:updateParts();
                end
            end
        end
    end
end

function Trailers.SearchGenerator(earthing)
    if earthing and earthing:getModData().generatorID then
        local strCoord = string.match(earthing:getModData().generatorID, '%d*[-]%d*[-]%d*')
        if strCoord then
            local i = string.find(strCoord, "-")
            local x = tonumber(string.sub(strCoord, 1, i-1))
            strCoord = string.sub(strCoord, i+1)
            i = string.find(strCoord, "-")
            local y = tonumber(string.sub(strCoord, 1, i-1))
            local z = tonumber(string.sub(strCoord, i+1))
            local sqr = getSquare(x, y, z)
            if sqr then
                for i=1,sqr:getObjects():size() do
                    local generator = sqr:getObjects():get(i-1)
                    if instanceof( generator, "IsoGenerator") then
                        return generator
                    end
                end
            end
        end
    end
    return nil
end

function Trailers.Update.GasTankFix(trailer, part, elapsedMinutes)
    local invItem = part:getInventoryItem();
    if not invItem then return; end
    local amount = part:getContainerContentAmount()
    if elapsedMinutes > 0 and amount > 0 and Trailers.isTrailerEngineRunning(trailer) then
        local amountOld = amount
        local gasMultiplier = 90000;
        -- trailer:getEngineQuality() reads the VehicleEngine, which no longer
        -- exists without an "Engine" part (it returns 0 and silently inflates
        -- consumption). The script value is the same number the engine was
        -- seeded from, so read it straight off the script instead.
        local qualityMultiplier = ((100 - trailer:getScript():getEngineQuality()) / 200) + 1;
        local speedMultiplier = 800;
        gasMultiplier = (gasMultiplier / qualityMultiplier) * 3;
        local newAmount = (speedMultiplier / gasMultiplier) * SandboxVars.CarGasConsumption;
        newAmount =  newAmount * (1000/2500.0);
        amount = amount - elapsedMinutes * newAmount;
        if part:getCondition() < 70 then
            if ZombRand(part:getCondition() * 2) == 0 then
                amount = amount - 0.01;
            end
        end
        part:setContainerContentAmount(amount, false, true);
        amount = part:getContainerContentAmount();
        local precision = (amount < 0.5) and 2 or 1
        if VehicleUtils.compareFloats(amountOld, amount, precision) then
            trailer:transmitPartModData(part)
        end
    end
end

function Trailers.Update.GeneratorGasTank(trailer, part, elapsedMinutes)
    -- print("Trailers.Update.GeneratorGasTank")
    Trailers.Update.GasTankFix(trailer, part, elapsedMinutes)
    local earthing = trailer:getPartById("EarthingOn")
    if earthing then
        local generator = Trailers.getGenerator(earthing)
        if generator then
            local amount = part:getContainerContentAmount()
            if elapsedMinutes > 0 and amount > 0 and Trailers.isTrailerEngineRunning(trailer) then
                generator:setFuel(amount/part:getContainerCapacity() * 100)
            end
            -- getPartById("Engine") is nil since the pivot fix renamed the part;
            -- indexing it threw every tick. Guarded and repointed.
            local enginePart = trailer:getPartById("TrailerEngine")
            local enginePartCondition = enginePart and enginePart:getCondition() or 0
            generator:setCondition(enginePartCondition)
            if enginePartCondition < 1 then
                generator:setActivated(false)
            end
        end
    end
end

function Trailers.UninstallComplete.GeneratorGasTank(trailer, part, item)
    local earthing = trailer:getPartById("EarthingOn")
    if earthing then
        local generator = Trailers.getGenerator(earthing)
        if generator then
            generator:setFuel(0.0)
            generator:setActivated(false)
        end
    end
end

function Trailers.Init.EarthingOn(trailer, earthing)
    local item = earthing:getInventoryItem()
    if item then
        local gen = Trailers.SearchGenerator(earthing)
        if gen == nil then
            local part = trailer:getPartById("EarthingOn")
            part:setInventoryItem(nil)
            trailer:transmitPartItem(part)
        end
    end
end

function Trailers.Update.EarthingOn (trailer, part, elapsedMinutes)
    -- print("Trailers.Update.EarthingOn")
    -- if trailer:getModData()["generatorObject"] then
        -- print(trailer:getMass())
        -- if trailer:getMass() < 9000 then
            -- trailer:setMass(10000)
            -- part:setLightActive(true)
        -- end
    -- end
end

function Trailers.Create.EarthingOn(trailer, part)
    -- print("Trailers.Create.EarthingOn")
    -- local item = VehicleUtils.createPartInventoryItem(part);
    -- CommonTemplates.createActivePart(part)
    part:setInventoryItem(nil)
    trailer:transmitPartItem(part)
end

--=============================================================================
-- TrailerEngine
--
-- The home and generator trailers used to carry a vanilla "Engine" part so
-- their appliances/generator could run off normal engine mechanics. The side
-- effect: CarController.updateTrailer() gates steerInDirectionOfTowing() on
-- getPartById("Engine") ~= nil, so the game steered them like an articulated
-- vehicle and their front wheels visibly pivoted toward the tow vehicle.
--
-- The part is now called "TrailerEngine", which leaves that branch unentered
-- (wheels stay straight). Everything the Engine part used to give us is
-- reimplemented below, keyed on a modData flag instead of isEngineRunning():
--   * running state          -> tsarEngineRunning on the part's modData
--   * temperature            -> Trailers.Update.TrailerEngineTemperature
--   * fuel burn (home)       -> Trailers.Update.TrailerEngine
--   * fuel burn (generator)  -> Trailers.Update.GeneratorGasTank (unchanged hook)
--   * battery charge         -> Vehicles.Update.Battery wrapper
--   * cabin heater/AC        -> Vehicles.Update.Heater wrapper
--=============================================================================

function Trailers.isTrailerEngineRunning(trailer)
    local motor = trailer and trailer:getPartById("TrailerEngine")
    return motor ~= nil and motor:getModData().tsarEngineRunning == true
end

function Trailers.setTrailerEngineRunning(trailer, running)
    if not trailer then return end
    local motor = trailer:getPartById("TrailerEngine")
    if not motor then return end
    if running then
        motor:getModData().tsarEngineRunning = true
    else
        motor:getModData().tsarEngineRunning = nil
    end
    trailer:transmitPartModData(motor)
end

-- Mirrors Vehicles.Create.Engine's condition roll so a wrecked trailer still
-- gets a wrecked motor, without the setEngineFeature/VehicleEngine plumbing
-- that no longer applies.
function Trailers.Create.TrailerEngine(trailer, part)
    part:setRandomCondition(nil)
end

-- Mirrors Vehicles.Update.Engine. Deliberately does NOT call
-- setNeedPartsUpdate(false): that vanilla optimisation keys off
-- isEngineRunning(), which is permanently false here, and would risk parking
-- the part updates while the motor is meant to be running.
function Trailers.Update.TrailerEngineTemperature(vehicle, part, elapsedMinutes)
    if not Vehicles.elaspedMinutesForEngine[vehicle:getId()] then
        Vehicles.elaspedMinutesForEngine[vehicle:getId()] = 0
    end
    local partData = part:getModData()
    if not tonumber(partData.temperature) then
        partData.temperature = 0
    end
    local previousTemp = partData.temperature
    if Trailers.isTrailerEngineRunning(vehicle) then
        local max = 100
        local engineDoor = vehicle:getPartById("EngineDoor")
        -- The generator trailer has no EngineDoor at all; treat that as a
        -- sealed housing (vanilla cap) rather than the missing-hood penalty.
        if engineDoor then
            if not engineDoor:getInventoryItem() then
                max = 200
            else
                max = 100 + ((100 - engineDoor:getCondition()) / 3)
            end
        end
        partData.temperature = math.min(partData.temperature + ZombRand(0, 3) * elapsedMinutes, max)
    elseif partData.temperature > 0 then
        partData.temperature = math.max(partData.temperature - 2 * elapsedMinutes, 0)
    end
    Vehicles.elaspedMinutesForEngine[vehicle:getId()] =
        Vehicles.elaspedMinutesForEngine[vehicle:getId()] + elapsedMinutes
    if isServer() and VehicleUtils.compareFloats(previousTemp, partData.temperature, 2)
        and Vehicles.elaspedMinutesForEngine[vehicle:getId()] > 2 then
        Vehicles.elaspedMinutesForEngine[vehicle:getId()] = 0
        vehicle:transmitPartModData(part)
    end
end

-- Same wear roll the vanilla engine gets through Vehicles.LowerCondition.
function Trailers.wearTrailerEngine(vehicle, part)
    if not Trailers.isTrailerEngineRunning(vehicle) then return end
    if part:getCondition() < 70 and ZombRand(part:getCondition() * 2) == 0 then
        part:setCondition(part:getCondition() - 1)
    end
end

-- Home trailer motor. Vehicles.Update.GasTank is gated on isEngineRunning(),
-- so the home trailer would otherwise burn no fuel at all; the burn is folded
-- in here. The generator trailer keeps its own GasTank hook instead.
function Trailers.Update.TrailerEngine(vehicle, part, elapsedMinutes)
    Trailers.Update.TrailerEngineTemperature(vehicle, part, elapsedMinutes)
    if not Trailers.isTrailerEngineRunning(vehicle) then return end

    local gasTank = vehicle:getPartById("GasTank")
    local amount = gasTank and gasTank:getContainerContentAmount() or 0
    if amount <= 0 or part:getCondition() < 1 then
        Trailers.setTrailerEngineRunning(vehicle, false)
        vehicle:updateParts()
        return
    end

    if elapsedMinutes > 0 then
        local gasMultiplier = 90000
        local heater = vehicle:getHeater()
        if heater and heater:getModData().active then
            gasMultiplier = gasMultiplier - 5000
        end
        local qualityMultiplier = ((100 - vehicle:getScript():getEngineQuality()) / 200) + 1
        gasMultiplier = (gasMultiplier / qualityMultiplier) * 3
        local newAmount = (800 / gasMultiplier) * SandboxVars.CarGasConsumption
        newAmount = newAmount * (1000 / 2500.0)
        gasTank:setContainerContentAmount(math.max(0, amount - elapsedMinutes * newAmount), false, true)
    end

    Trailers.wearTrailerEngine(vehicle, part)
    vehicle:updateParts()
end

--- Battery ------------------------------------------------------------------
-- Vehicles.Update.Battery only charges while isEngineRunning(). Route trailers
-- carrying a TrailerEngine through the modData flag at the same vanilla rate.
local oldUpdateBattery = Vehicles.Update.Battery
function Vehicles.Update.Battery(vehicle, part, elapsedMinutes)
    if not (vehicle and vehicle:getPartById("TrailerEngine")) then
        return oldUpdateBattery(vehicle, part, elapsedMinutes)
    end
    local item = part:getInventoryItem()
    if item then
        local chargeOld = item:getCurrentUsesFloat()
        local charge = chargeOld
        if elapsedMinutes > 0 and Trailers.isTrailerEngineRunning(vehicle) then
            charge = math.min(charge + elapsedMinutes * 0.001, 1.0)
        end
        if charge ~= chargeOld then
            item:setUsedDelta(charge)
            if VehicleUtils.compareFloats(chargeOld, charge, 2) then
                vehicle:transmitPartUsedDelta(part)
            end
        end
    end
    Vehicles.Update.Lightbar(vehicle, part, elapsedMinutes)
end

--- Cabin heater / AC ---------------------------------------------------------
-- Vehicles.Update.Heater bails out on `not engine` and gates on
-- isEngineRunning(), so the home trailer's heater would never run. Mirrors the
-- vanilla body with the motor part and flag substituted. Keep in sync with
-- Vehicles.Update.Heater if TIS changes it.
function Trailers.Update.TrailerHeater(vehicle, part, elapsedMinutes)
    if not Vehicles.elaspedMinutesForHeater[vehicle:getId()] then
        Vehicles.elaspedMinutesForHeater[vehicle:getId()] = 0
    end
    local pc = vehicle:getPartById("PassengerCompartment")
    local motor = vehicle:getPartById("TrailerEngine")
    if not pc or not motor then return end
    local pcData = pc:getModData()
    if not tonumber(pcData.temperature) then
        pcData.temperature = 0.0
    end
    local partData = part:getModData()
    if not tonumber(partData.temperature) then
        partData.temperature = 0
    end
    local motorTemp = tonumber(motor:getModData().temperature) or 0
    local running = Trailers.isTrailerEngineRunning(vehicle)
    local tempInc = 0.5 + (math.min(motorTemp / 100, 0.7))
    local previousTemp = pcData.temperature
    if partData.active and running and motorTemp > 30
        and ((partData.temperature > 0 and pcData.temperature <= partData.temperature)
            or (partData.temperature < 0 and pcData.temperature >= partData.temperature)) then
        if partData.temperature > 0 then
            pcData.temperature = math.min(pcData.temperature + tempInc * elapsedMinutes, partData.temperature)
        else
            pcData.temperature = math.max(pcData.temperature - tempInc * elapsedMinutes, partData.temperature)
        end
        if partData.temperature > 0 and pcData.temperature > partData.temperature then
            pcData.temperature = partData.temperature
        end
        if partData.temperature < 0 and pcData.temperature < partData.temperature then
            pcData.temperature = partData.temperature
        end
    else
        if pcData.temperature > 0 then
            pcData.temperature = math.max(pcData.temperature - 0.1 * elapsedMinutes, 0)
        else
            pcData.temperature = math.min(pcData.temperature + 0.1 * elapsedMinutes, 0)
        end
    end
    if partData.active and running then
        VehicleUtils.chargeBattery(vehicle, -0.000035 * elapsedMinutes)
    end
    Vehicles.elaspedMinutesForHeater[vehicle:getId()] =
        Vehicles.elaspedMinutesForHeater[vehicle:getId()] + elapsedMinutes
    if isServer() and VehicleUtils.compareFloats(previousTemp, pcData.temperature, 2)
        and Vehicles.elaspedMinutesForHeater[vehicle:getId()] > 2 then
        Vehicles.elaspedMinutesForHeater[vehicle:getId()] = 0
        vehicle:transmitPartModData(pc)
    end
end

local oldUpdateHeater = Vehicles.Update.Heater
function Vehicles.Update.Heater(vehicle, part, elapsedMinutes)
    if vehicle and vehicle:getPartById("TrailerEngine") then
        return Trailers.Update.TrailerHeater(vehicle, part, elapsedMinutes)
    end
    return oldUpdateHeater(vehicle, part, elapsedMinutes)
end

--=============================================================================
-- Hitch guard
--
-- A generator trailer that is plugged in anchors an IsoGenerator to a fixed
-- world square; Trailers.getGenerator() resolves it from the coordinates in
-- EarthingOn's modData. Tow the trailer away and that generator keeps powering
-- its old location forever -- persistent world-state corruption.
--
-- Both transitions into that state are refused at their entry point rather than
-- policed afterwards:
--   * attach a connected trailer -> ISAttachTrailerToVehicle:isValid()
--                                   (TrailersAttachGuard.lua, client)
--   * connect a hitched trailer  -> ISPlugTrailerGenerator:isValid() (shared)
--                                   + TrailerCommands.createGeneratorServer below
-- Both are timed actions, so isValid() is re-evaluated for their whole duration
-- and the state cannot go bad mid-action either.
--
-- The HOME trailer is intentionally NOT covered: its motor only feeds the
-- trailer's own appliances and has no world anchor, so it may run while towed.
--=============================================================================

function Trailers.isHitched(trailer)
    if not trailer then return false end
    return (trailer.getVehicleTowedBy and trailer:getVehicleTowedBy() ~= nil)
        or (trailer.getVehicleTowing and trailer:getVehicleTowing() ~= nil)
end
