-- require('TowingCar/TowingUI')

local old_ISVehicleMenu_showRadialMenu = ISVehicleMenu.showRadialMenu

function ISVehicleMenu.showRadialMenu(playerObj)
	old_ISVehicleMenu_showRadialMenu(playerObj)
	local vehicle = playerObj:getVehicle()
	if vehicle ~= nil then
		local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
		
		if menu:isReallyVisible() then
			if menu.joyfocus then
				setJoypadFocus(playerObj:getPlayerNum(), nil)
			end
			menu:undisplay()
			return
		end
		
		-- The motor is no longer a vanilla Engine (see part TrailerEngine): it is
		-- a pull-start power plant for the trailer's own appliances. So there is
		-- no ignition, no key and no hotwire -- and no driver seat either, which
		-- is why the old `seat == 1` gate mostly kept this menu from appearing.
		if string.match(vehicle:getScript():getName(), "TrailerHome") then
			local motor = vehicle:getPartById("TrailerEngine")
			if motor then
				if motor:getModData().tsarEngineRunning == true then
					menu:addSlice(getText("ContextMenu_VehicleShutOff"), getTexture("media/ui/vehicles/vehicle_ignitionOFF.png"), ISVehicleMenu.onShutOffTrailerHomeEngine, playerObj)
				else
					menu:addSlice(getText("ContextMenu_VehicleStartEngine"), getTexture("media/ui/vehicles/vehicle_ignitionON.png"), ISVehicleMenu.onStartTrailerHomeEngine, playerObj)
				end
			end

			if vehicle:isTrunkLocked() then
				menu:addSlice(getText("ContextMenu_Open_trunk"), getTexture("media/ui/vehicles/vehicle_open_home_trunk.png"), ISVehicleMenu.onToggleTrunkLocked, playerObj)
			else
				menu:addSlice(getText("ContextMenu_Close_trunk"), getTexture("media/ui/vehicles/vehicle_open_home_trunk.png"), ISVehicleMenu.onToggleTrunkLocked, playerObj)
			end
		end
		menu:addToUIManager()
	end
end

function ISVehicleMenu.onStartTrailerHomeEngine(playerObj)
	ISTimedActionQueue.add(ISStartTrailerHomeEngine:new(playerObj))
end

function ISVehicleMenu.onShutOffTrailerHomeEngine(playerObj)
	ISTimedActionQueue.add(ISShutOffTrailerHomeEngine:new(playerObj))
end

function ISVehicleMenu.onHotwireTrailerHome(playerObj)
	ISTimedActionQueue.add(ISHotwireTrailerHome:new(playerObj))
end

