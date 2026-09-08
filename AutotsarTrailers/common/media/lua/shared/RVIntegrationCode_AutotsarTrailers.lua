---- Integration block for PROJECT RV Interior
---- By placing this code in your mod you can add interiors to your vehicles.
---- Place this file in media\lua\shared
---- Replace "Base.Example.." with your vehicle ID. Uncomment the code to add more.
---- Uncomment the code you are going to use
--
-- Function to remove a vehicle from all type lists
local function removeFromAllLists(VehicleTypes, vehicleName)
   for _, data in pairs(VehicleTypes) do
       if data and data.scripts then
           for i = #data.scripts, 1, -1 do
               if data.scripts[i] == vehicleName then
                   table.remove(data.scripts, i)
               end
           end
       end
   end
end

local function alreadyExists(VehicleTypes, vehicleName)
   for interiorModelType, data in pairs(VehicleTypes) do
       if data and data.scripts then
           for i = #data.scripts, 1, -1 do
               if data.scripts[i] == vehicleName then
                   print("AutotsarTrailers RVInterior integration "..tostring(interiorModelType).." already includes "..tostring(vehicleName))
                   return true
               end
           end
       end
   end
   return false
end

-- Function to insert a vehicle into a specific type (cleaning first)
local function insertUnique(VehicleTypes, typeKey, vehicleName)
   local data = VehicleTypes[typeKey]
   if not data or not data.scripts then return false end
   
   -- Clear the vehicle from all lists before adding it
   removeFromAllLists(vehicleName)
   table.insert(data.scripts, vehicleName)
   return true
end

-- Function to insert a vehicle into a specific type (cleaning first)
local function insertIfNotExists(VehicleTypes, typeKey, vehicleName)
   if alreadyExists(VehicleTypes, vehicleName) then return false end
   local data = VehicleTypes[typeKey]
   if not data or not data.scripts then return false end
   
   table.insert(data.scripts, vehicleName)
   return true
end

--------------------------------------------------------------------------------------------------------------------------------------------
--HERE YOU CAN ADD INTERIORS TO ANY VEHICLE
--Types: "normal" / "bus" / "small" / "3x2caravan" / "3x6caravan" / "3x7empty" / "4x12colossal"
local function AddVehiclesToRVInterior()
   -- Get the global VehicleTypes table from the PROJECT RV Interior mod
   local ok, RV = pcall(require, "RVVehicleTypes")
   if not ok or not RV then return end-- Exit silently if the mod isn't present
   local VehicleTypes = RV.VehicleTypes
   if not VehicleTypes then
       print("AddVehiclesToRVInterior missing VehicleTypes")
       return
   end
   
   insertIfNotExists(VehicleTypes, "3x2caravan", "Base.TrailerHome")
   insertIfNotExists(VehicleTypes, "3x2caravan", "Base.TrailerHomeHartman")
   insertIfNotExists(VehicleTypes, "3x2caravan", "Base.TrailerHomeExplorer")
end

-- Run when the game world loads (not required, already done by RVInterior)
--Events.OnInitWorld.Add(AddVehiclesToRVInterior)

--------------------------------------------------------------------------------------------------------------------------------------------
--HERE YOU CAN ADD NEW TYPES OF INTERIORS
local function AddTypeToRVInterior()
   -- Get the global VehicleTypes table from the PROJECT RV Interior mod
   local ok, RV = pcall(require, "RVVehicleTypes")
   if not ok or not RV then
       return -- Exit silently if the mod isn't present
   end
   local VehicleTypes = RV.VehicleTypes

   local newTypeVehicles = {-- This is where you declare the vehicles (IDs) that will have the new type of interior
       "Base.exampleNewVehicle",
       "Base.anotherExample"
   }

   -- Remove new-type vehicles from all existing lists (uncomment the function removeFromAllLists)
   for _, vehicleName in ipairs(newTypeVehicles) do
       removeFromAllLists(vehicleName)
   end

   local celX = 80  -- The cell (X) you are using in your map
   local celY = 45  -- The cell (Y) you are using in your map

   -- Add a new type of Interior
   VehicleTypes["exampleNewType"] = {-- The name of the new type
       scripts = newTypeVehicles,
       rooms = {-- Here you place the coordinates of all the rooms
           { x = 60 + 300 * celX + 0 * 60, y = 60 + 300 * celY + 0 * 60, z = 0 },
           { x = 60 + 300 * celX + 0 * 60, y = 60 + 300 * celY + 1 * 60, z = 0 },
           { x = 60 + 300 * celX + 0 * 60, y = 60 + 300 * celY + 2 * 60, z = 0 },
           { x = 60 + 300 * celX + 1 * 60, y = 60 + 300 * celY + 0 * 60, z = 0 },
           { x = 60 + 300 * celX + 1 * 60, y = 60 + 300 * celY + 1 * 60, z = 0 },
           { x = 60 + 300 * celX + 1 * 60, y = 60 + 300 * celY + 2 * 60, z = 0 },
           { x = 60 + 300 * celX + 2 * 60, y = 60 + 300 * celY + 0 * 60, z = 0 },
           { x = 60 + 300 * celX + 2 * 60, y = 60 + 300 * celY + 1 * 60, z = 0 },
           { x = 60 + 300 * celX + 2 * 60, y = 60 + 300 * celY + 2 * 60, z = 0 }
       },

       offset = { x = 1, y = 1 }, -- The square where the player will appear inside the room
       requiresSeat = false,
       requiresTrunk = true,
       trunkParts = {
           TrunkDoor = true, DoorRear = true, DoorRearLeft = true, DoorRearRight = true
       },
		genX = 0, -- Generator position X [this number refers to the X position relative to the room from its point (0,0,0)(first square top left), not to X on the map]
		genY = 0, -- Generator position Y [this number refers to the Y position relative to the room from its point (0,0,0)(first square top left), not to Y on the map]
		genFloor = 1, -- Generator position Z [this number refers to the Z position relative to the room from its point (0,0,0)(first square top left), not to Z on the map]
		roomWidth = 2, -- The width in squares of the interior
		roomHeight = 3 -- The height in squares of the interior
   }
end
--
---- Run when the game world loads
--Events.OnInitWorld.Add(AddTypeToRVInterior)
--