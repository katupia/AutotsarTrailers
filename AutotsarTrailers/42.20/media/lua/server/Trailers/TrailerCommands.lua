
TrailerCommands = TrailerCommands or {}

-- There is no global `noise` in B42.20 -- vanilla only ever declares it as a
-- file-local. Every error branch below used to throw "attempt to call nil".
local function noise(message)
    print('[AutotsarTrailers] ' .. tostring(message))
end

function TrailerCommands.setHeadlightsOnServer(trailer, isOn)
    if trailer then trailer:setHeadlightsOn(isOn) end
    local part = trailer and trailer:getPartById("HeadlightLeft")
    if part then part:setLightActive(isOn) end
end
function TrailerCommands.setHeadlightsOn(playerObj, args)
    --print("Commands.setHeadlightsOn")
    local trailer = getVehicleById(args.trailer)
    TrailerCommands.setHeadlightsOnServer(trailer, args.on)
end

-- Start/stop the trailer motor. tryStartEngine()/shutOff() drive the vanilla
-- VehicleEngine, which no longer exists on these trailers (see part
-- TrailerEngine); the state is a modData flag now.
function TrailerCommands.startGeneratorEngineServer(trailer, activate)
    if not trailer then
        noise('trailer no found for startGeneratorEngineServer')
        return
    end
    local motor = trailer:getPartById("TrailerEngine")
    if not motor then
        noise('trailer engine missing')
        return
    end
    if activate then
        -- Only the generator trailer is blocked while hitched: it anchors an
        -- IsoGenerator to a world square. The home trailer's motor feeds its own
        -- appliances only and is allowed to run while towed.
        if trailer:getPartById("EarthingOn") and Trailers.isHitched(trailer) then
            noise('refusing to start the generator while the trailer is hitched')
            return
        end
        local batteryPart = trailer:getPartById("Battery")
        local batteryItem = batteryPart and batteryPart:getInventoryItem()
        if not batteryItem then
            noise('trailer battery is missing')
            return
        end
        if batteryItem:getCurrentUsesFloat() > 0.001 then
            batteryItem:setUsedDelta(math.max(0, batteryItem:getCurrentUsesFloat() - 0.02))
        end
        Trailers.setTrailerEngineRunning(trailer, true)
    else
        Trailers.setTrailerEngineRunning(trailer, false)
        -- Trailers.Update.GeneratorEngine only reaches its deactivate branch
        -- while the part is still updating, so cut the IsoGenerator here
        -- directly rather than relying on the next tick.
        local earthing = trailer:getPartById("EarthingOn")
        local generator = earthing and Trailers.getGenerator(earthing)
        if generator then
            generator:setActivated(false)
        end
    end
    trailer:updateParts()
end
function TrailerCommands.startGeneratorEngine(player, args)
-- print("TrailerCommands.startGeneratorEngine")
    local trailer = getVehicleById(args.trailer)
    local activate = args.activate
    TrailerCommands.startGeneratorEngineServer(trailer, activate)
end

local function hideItem(isoObject)
    if isoObject then
        isoObject:setSprite('')
    end
end

function TrailerCommands.createGeneratorServer(trailer)
    if trailer then
        -- Authoritative half of the plug guard: this is the mod's own command
        -- handler, so it holds even if a client reaches it with a stale view.
        if Trailers.isHitched(trailer) then
            noise('refusing to connect the generator while the trailer is hitched')
            return
        end
        local earthing = trailer:getPartById("EarthingOn")
        local sqr = trailer:getSquare()
        if trailer and earthing then
            local generator = IsoGenerator.new(instanceItem("Autotsar.InvisibleGenerator"), sqr:getCell(), sqr)
            generator:setFuel(trailer:getPartById("GasTank"):getContainerContentAmount()/trailer:getPartById("GasTank"):getContainerCapacity() * 100)
            -- getPartById("Engine") is nil since the pivot fix renamed the part.
            local motor = trailer:getPartById("TrailerEngine")
            generator:setCondition(motor and motor:getCondition() or 80)
            generator:setConnected(true)
            generator:getModData().trailerId = trailer:getId()
            --hideItem(generator)
            -- print("Generator created")
            earthing:getModData().generatorID = 
                    "#" .. sqr:getX() .. "-" .. sqr:getY() .. "-" .. sqr:getZ()
            earthing:setInventoryItem(instanceItem("Autotsar.TsarEarthing"))
            -- print("ID SAVED")
            trailer:transmitPartModData(earthing);
            trailer:transmitPartItem(earthing);
            trailer:updateParts();
            if isServer() then
                generator:transmitCompleteItemToClients(); 
                generator:transmitModData();
                generator:transmitUpdatedSpriteToClients()
            end
        end
    else
        noise('trailer no found for createGeneratorServer')
    end
end
function TrailerCommands.createGenerator(playerObj, args)
	-- print("TrailerCommands.createGenerator")
	local trailer = getVehicleById(args.trailer)
    TrailerCommands.createGeneratorServer(trailer)
end

function TrailerCommands.deleteGeneratorServer(trailer)
    if trailer then
        -- Unplugging must also stop the motor, otherwise the running flag
        -- survives on a trailer with no generator to drive.
        Trailers.setTrailerEngineRunning(trailer, false)
        local earthing = trailer:getPartById("EarthingOn")
        if earthing and earthing:getModData().generatorID then
            local sqr = trailer:getSquare()
            local strCoord = string.match(earthing:getModData().generatorID, '%d*[-]%d*[-]%d*')
            if strCoord then
                local i = string.find(strCoord, "-")
                local x = tonumber(string.sub(strCoord, 1, i-1))
                strCoord = string.sub(strCoord, i+1)
                i = string.find(strCoord, "-")
                local y = tonumber(string.sub(strCoord, 1, i-1))
                local z = tonumber(string.sub(strCoord, i+1))
                local sqr = getSquare(x, y, z)
                for i=1,sqr:getObjects():size() do
                    local generator = sqr:getObjects():get(i-1)
                    if instanceof( generator, "IsoGenerator") then--check invisible too ?
                        generator:setConnected(false);
                        generator:remove()
                        sqr:transmitRemoveItemFromSquare(generator)
                        break
                    end
                end
            end
            earthing:getModData().generatorID = nil
            earthing:setInventoryItem(nil)
            trailer:transmitPartModData(earthing);
            trailer:transmitPartItem(earthing);
        else
            noise('earthing no found for createGeneratorServer')
        end
    else
        noise('trailer no found for createGeneratorServer')
    end
end

function TrailerCommands.deleteGenerator(playerObj, args)
    local trailer = getVehicleById(args.trailer)
    TrailerCommands.deleteGeneratorServer(trailer)

end

TrailerCommands.OnClientCommand = function(module, command, playerObj, args)
	--print("TrailerCommands.OnClientCommand")
	if module == 'trailer' and TrailerCommands[command] then
		--print("trailer")
		local argStr = ''
		args = args or {}
		for k,v in pairs(args) do
			argStr = argStr..' '..k..'='..tostring(v)
		end
		--noise('received '..module..' '..command..' '..tostring(trailer)..argStr)
		TrailerCommands[command](playerObj, args)
	end
end

Events.OnClientCommand.Add(TrailerCommands.OnClientCommand)