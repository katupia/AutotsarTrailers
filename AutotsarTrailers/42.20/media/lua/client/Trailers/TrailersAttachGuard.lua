-- Hitch guard, client half.
--
-- A deployed generator trailer (plugged in, or motor running) anchors an
-- IsoGenerator to a fixed world square. Towing it away leaves that generator
-- powering its old location forever. Rather than a compound timed action --
-- which stalls in MP because the client cannot observe the server-side state
-- change -- the conflicting option is simply never offered: the "attach
-- trailer" slices are withheld while the trailer involved is deployed.
--
-- The server-side backstop lives in Trailers.lua (enforceNoHitchWhileDeployed).
--
-- The HOME trailer is intentionally not covered: its motor only feeds the
-- trailer's own appliances and has no world anchor, so it may be towed running.

local function isGeneratorDeployed(trailer)
    if not trailer then return false end
    local earthing = trailer:getPartById("EarthingOn")
    if not earthing then return false end            -- not the generator trailer
    if earthing:getModData().generatorID ~= nil then return true end
    local motor = trailer:getPartById("TrailerEngine")
    return motor ~= nil and motor:getModData().tsarEngineRunning == true
end

-- The attachment pairs ISVehicleMenu.doTowingMenu itself tries, in its order.
local COMBOS = {
    { "trailer",      "trailer" },
    { "trailer",      "trailerfront" },
    { "trailerfront", "trailer" },
    { "trailerfront", "trailerfront" },
}

local function getTowableTrailerNear(vehicle)
    local square = vehicle and vehicle:getSquare()
    if not square then return nil end
    for _, combo in ipairs(COMBOS) do
        local other = ISVehicleTrailerUtils.getTowableVehicleNear(square, vehicle, combo[1], combo[2])
        if other then return other end
    end
    return nil
end

local originalDoTowingMenu = ISVehicleMenu.doTowingMenu

function ISVehicleMenu.doTowingMenu(playerObj, vehicle, menu)
    -- Only suppress the ATTACH case. Detach slices (already towing / towed by)
    -- must stay available, otherwise a trailer could get stuck hitched.
    if vehicle and not vehicle:getVehicleTowing() and not vehicle:getVehicleTowedBy() then
        if isGeneratorDeployed(vehicle) then return end
        local trailer = getTowableTrailerNear(vehicle)
        if trailer and isGeneratorDeployed(trailer) then return end
    end
    if originalDoTowingMenu then
        originalDoTowingMenu(playerObj, vehicle, menu)
    end
end

-- The strongest of the three guards: ISAttachTrailerToVehicle:isValid() is
-- re-evaluated for the entire walk-to-hitch + attach animation, so a generator
-- that gets plugged in WHILE the player is walking over aborts the attach
-- instead of completing it. It also runs before the action's own
-- sendClientCommand, so nothing ever reaches the server.
local originalAttachIsValid = ISAttachTrailerToVehicle.isValid

function ISAttachTrailerToVehicle:isValid()
    if isGeneratorDeployed(self.vehicleA) or isGeneratorDeployed(self.vehicleB) then
        return false
    end
    return originalAttachIsValid(self)
end

-- Also refuse a direct call, in case another mod or a keybind reaches it
-- without going through the radial menu.
local originalOnAttachTrailer = ISVehicleMenu.onAttachTrailer

function ISVehicleMenu.onAttachTrailer(playerObj, vehicle, attachmentA, attachmentB)
    local square = vehicle and vehicle:getCurrentSquare()
    local trailer = square and ISVehicleTrailerUtils.getTowableVehicleNear(square, vehicle, attachmentA, attachmentB)
    if isGeneratorDeployed(vehicle) or isGeneratorDeployed(trailer) then return end
    if originalOnAttachTrailer then
        originalOnAttachTrailer(playerObj, vehicle, attachmentA, attachmentB)
    end
end
