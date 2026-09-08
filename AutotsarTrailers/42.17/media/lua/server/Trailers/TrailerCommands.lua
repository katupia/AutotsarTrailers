
TrailerCommands = TrailerCommands or {}

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

function TrailerCommands.startGeneratorEngineServer(trailer, activate)
    if trailer then
        if activate then
            trailer:tryStartEngine(true)
        else
            trailer:shutOff()
        end
    else
        noise('trailer no found for startGeneratorEngineServer')
    end
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
        local earthing = trailer:getPartById("EarthingOn")
        local sqr = trailer:getSquare()
        if trailer and earthing then
            local generator = IsoGenerator.new(instanceItem("Autotsar.InvisibleGenerator"), sqr:getCell(), sqr)
            generator:setFuel(trailer:getPartById("GasTank"):getContainerContentAmount()/trailer:getPartById("GasTank"):getContainerCapacity() * 100)
            generator:setCondition(trailer:getPartById("Engine"):getCondition())
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