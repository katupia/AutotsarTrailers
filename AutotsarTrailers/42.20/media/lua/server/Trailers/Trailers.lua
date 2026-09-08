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
    Vehicles.Update.Engine(vehicle, part, elapsedMinutes)
    local earthing = vehicle:getPartById("EarthingOn")
    if earthing then
        local generator = Trailers.getGenerator(earthing)
        if generator then
            if vehicle:isEngineRunning() then
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
    if elapsedMinutes > 0 and amount > 0 and trailer:isEngineRunning() then
        local amountOld = amount
        local gasMultiplier = 90000;
        local qualityMultiplier = ((100 - trailer:getEngineQuality()) / 200) + 1;
        speedMultiplier = 800;
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
            if elapsedMinutes > 0 and amount > 0 and trailer:isEngineRunning() then
                generator:setFuel(amount/part:getContainerCapacity() * 100)
            end
            local enginePartCondition = trailer:getPartById("Engine"):getCondition()
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
