---@class ns
local ns = select(2, ...)

local Aura = ns.Utils.Aura
local Cmd = ns.Cmd
local Logging = ns.Logging
local Vault = ns.Vault
local libs = ns.Libs

local Constants = ns.Constants
local AceConsole = ns.Libs.AceConsole
local Dropdown = ns.UI.Dropdown

local cmd, cmdWithDotCheck = Cmd.cmd, Cmd.cmdWithDotCheck
local runMacroText = Cmd.runMacroText
local cprint = Logging.cprint
local eprint = Logging.eprint
local isNotDefined = ns.Utils.Data.isNotDefined
local parseStringToArgs = ns.Utils.Data.parseStringToArgs

local getPlayerPositionData = C_Epsilon.GetPosition or function() return UnitPosition("player") end

local next = next
local tinsert = tinsert
local tremove = tremove
local lower = string.lower or strlower

local toBoolean = function(input)
	if not input then return false end
	return ns.Utils.Data.toBoolean(input)
end

local function cError(name, reason)
	return error("Arc Conditions - " .. name .. " - " .. reason)
end

local lastCreatureDisplayID = 0
do
	if EpsilonLib then
		-- using newer EpsilonLib, coo
		EpsilonLib.Server.server.receive("DSPLY", function(message, channel, sender)
			local Epsilon = EpsilonLib
			local records = { string.split(Epsilon.record, message) }
			for _, record in pairs(records) do
				local displayid = string.split(Epsilon.field, record)
				if displayid ~= "" then
					lastCreatureDisplayID = tonumber(displayid)
					--print(lastCreatureDisplayID)
				end
			end
		end)

		-- Create a watcher for the PLAYER_TARGET_CHANGED event if not already hooked by EpsilonLib (At this time of writing EpsilonLib did not have this implemented yet)
		if not EpsilonLib.Server.Events.registered["PLAYER_TARGET_CHANGED"] then
			EpsilonLib.Server.Events.on("PLAYER_TARGET_CHANGED", function(self, event, message)
				if event == "PLAYER_TARGET_CHANGED" then
					EpsilonLib.Server.server.send("P_DSPLY", "CLIENT_READY")
				end
			end)
		end
	elseif Epsilon then
		-- using older Epsilon addon library
		Epsilon.utils.server.receive("DSPLY", function(message, channel, sender)
			local records = { string.split(Epsilon.record, message) }
			for _, record in pairs(records) do
				local displayid = string.split(Epsilon.field, record)
				if displayid ~= "" then
					lastCreatureDisplayID = tonumber(displayid)
					--print(lastCreatureDisplayID)
				end
			end
		end)
	end
end

------------------------------------------
-- Input Links

local InputHelper = ns.Utils.InputHelper
local input = InputHelper.input

------------------------------------------
-- Conditions Data Structures & Creation

---@class ConditionKey: string
---@class ConditionIndex: integer

---@class ConditionTypeData
---@field key ConditionKey
---@field name string
---@field description string
---@field script function
---@field inputs InputsContainer|boolean|nil Ordered Array of Inputs and their types, used for Input Helper Tool later.. Can be `true` for now, but if false/nil then it will disable the input editbox. See inputs module (TODO) for input generator func
---@field inputDesc? string Description of the Inputs
---@field inputExample? string Example Input
---@field doNotTestEval? boolean Default to disabling the Condition Status preview evaluation. Useful in things like Macro Script & Random Roll which are irrelevant to test now.

---@class ConditionTypeCat
---@field catName string
---@field catItems ConditionTypeData[]

---@class ConditionTypeHead
---@field header string

local raceList = {}
for i = 1, 90 do
	local raceInfo = C_CreatureInfo.GetRaceInfo(i)
	if raceInfo then
		tinsert(raceList, string.format("%s. %s", raceInfo.raceID, raceInfo.raceName))
	end
end
local classList = {}
for i = 1, 20 do
	local classInfo = { GetClassInfo(i) }
	if #classInfo > 0 then
		tinsert(classList, string.format("%s. %s", classInfo[3], classInfo[1]))
	end
end

---@type (ConditionTypeData|ConditionTypeCat|ConditionTypeHead)[]
local conditions = {
	{ header = "Spells, Items, and Stuff" },
	-- Spells & Effects
	---- Has Aura (Self)
	---- Has Number of Aura (Self)
	---- Is Spell on Cooldown

	{
		catName = "Spells & Effects",
		catItems = {
			{
				key = "hasAura",
				name = "Has Aura (Self)",
				description = "If your character currently has the specified aura active",
				inputs = { input("Aura ID", "number"), },
				script = function(auraID) return (auraID and ns.Utils.Aura.checkPlayerAuraID(tonumber(auraID)) or false) end,
			},
			{
				key = "hasAuraNum",
				name = "Has Number of Aura (Self)",
				description =
				"If your character currently has X number of stacks of the specified aura. May specify 'true' as the 3rd input to change it to a 'Greater Than or Equal To' check (use 'not' on the condition for Less Than).",
				inputExample = "<296289, 6, true> - Checks if your character has the 'Rage Stacking' aura applied 6 or more times.",
				inputs = { input("Aura ID", "number"), input("Stacks", "number"), input("Or Greater Than", "boolean?"), },
				script = function(auraID, stacks, greaterThan)
					if not auraID or not stacks then return end
					local spell = { ns.Utils.Aura.checkPlayerAuraID(tonumber(auraID)) }
					if #spell == 0 then return false end                        -- no spell, fail
					local spellStacks = spell[3]; if spellStacks == 0 then spellStacks = 1 end -- Convert 0 to 1, since that just means we have one stack and it's not stackable.
					if greaterThan and toBoolean(greaterThan) then              -- greaterThan was real & also was true bool
						return spellStacks >= tonumber(stacks)
					else
						return spellStacks == tonumber(stacks)
					end
				end,
			},
			{
				key = "isSpellOnCooldown",
				name = "Is Spell on Cooldown",
				description = "If the Spell ID given is currently on Cooldown.",
				inputDesc = "To check the Global Cooldown, you can use the dummy GCD spell ID 61304.",
				inputs = { input("Spell ID", "number"), },
				script = function(spellID) return select(2, GetSpellCooldown(spellID)) ~= 0 end,
			},
		}
	},

	-- Items / Inventory
	---- Has Item
	---- Has X Number of Items
	---- Has More than X Items
	---- Has Less than X Items
	---- Has Item Equipped
	---- Has Slot Equipped

	{
		catName = "Items / Inventory",
		catItems = {
			{
				key = "hasItem",
				name = "Has Item",
				description = "If your character currently has at least one of this item.",
				inputs = { input("Item ID", "number"), },
				script = function(itemID) return GetItemCount(itemID, false, false) > 0 end,
			},
			{
				key = "hasNumItems",
				name = "Has X Number of Items",
				description = "If your character currently has exactly X number of this item.",
				inputs = { input("Item ID", "number"), input("Number", "number") },
				script = function(itemID, number) return GetItemCount(itemID, false, false) == tonumber(number) end,
			},
			{
				key = "hasMoreThanItems",
				name = "Has More than X Items",
				description = "If your character currently has more than X number of this item.",
				inputs = { input("Item ID", "number"), },
				script = function(itemID, number) return GetItemCount(itemID, false, false) > tonumber(number) end,
			},
			{
				key = "hasLessThanItems",
				name = "Has Less than X Items",
				description = "If your character currently has less than X number of this item.",
				inputs = { input("Item ID", "number"), },
				script = function(itemID, number) return GetItemCount(itemID, false, false) < tonumber(number) end,
			},
			{
				key = "hasItemEquipped",
				name = "Has Item Equipped",
				description = "If your character currently has a specific item equipped.",
				script = function(itemID) return IsEquippedItem(itemID) end,
				inputs = { input("Item ID", "number") },
			},
			{
				key = "hasSlotEquipped",
				name = "Has Item Equipped in Slot",
				description = "If your character currently has any item equipped in a specific slot.",
				inputs = { input("Slot Name", "string", "Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands", "Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "Mainhand", "Secondaryhand", "Ranged", "Tabard") },
				inputDesc = nil,
				script = function(invSlotId)
					if not invSlotId then return false end
					if type(invSlotId) == "string" then                      -- if it's a string..
						-- convert to ID
						invSlotId = strupper(invSlotId)                      -- Convert to uppercase to match global names
						if not invSlotId:find("SLOT") then invSlotId = invSlotId .. "SLOT" end -- ensure it has the slot label
						invSlotId = GetInventorySlotInfo(invSlotId)
						if not invSlotId then return false end               -- Well, if it's not a valid slot.. they don't have anything equipped in it! FAIL!
					end
					return GetInventoryItemID("player", invSlotId)
				end,
			},
		}
	},

	-- Player or Target
	---- Is Flying
	---- Is Falling
	---- Is Swimming
	---- Is Submerged
	---- Is Indoors
	---- Is Outdoors
	---- Is Mounted
	---- Is Stealthed
	---- Is Race
	---- Is Class
	---- Is Gender
	---- Is In Combat
	---- Is In Instance
	---- Is in Party (Self)
	---- Is in Raid (Self)
	---- Has Reputation Level with Faction
	{ header = "Unit" },
	{
		catName = "Player or Target .. ",
		catItems = {
			{
				key = "isFlying",
				name = "Is Flying",
				description = "Continues only if the specified unit is currently flying. This includes flying mounts, spell effects, and `.cheat fly`.",
				inputDesc = "Defaults to player if no input is given.",
				inputs = { input("Unit", "unit?"), },
				script = function(unit) return IsFlying(unit and lower(unit) or "player") end,
			},
			{
				key = "isFalling",
				name = "Is Falling",
				description = "Returns true if the specified unit is currently falling.",
				inputDesc = "Defaults to player if no input is given.",
				inputs = { input("Unit", "unit?"), },
				script = function(unit) return IsFalling(unit and lower(unit) or "player") end,
			},
			{
				key = "isSwimming",
				name = "Is Swimming",
				description = "Returns true if the character is currently swimming. This only applies if you are in water & in the swimming animation.",
				inputDesc = "Defaults to player if no input is given.",
				inputs = { input("Unit", "unit?"), },
				script = function(unit) return IsSwimming(unit and lower(unit) or "player") end,
			},
			{
				key = "isSubmerged",
				name = "Is Submerged",
				description =
				"Returns true if the character is currently underwater. This applies any time you are in water, even if running at the bottom of a surface of water, unless the water is too shallow to swim in.",
				inputDesc = "Defaults to player if no input is given.",
				inputs = { input("Unit", "unit?"), },
				script = function(unit) return IsSubmerged(unit and lower(unit) or "player") end,
			},
			{
				key = "isRace",
				name = "Is Race",
				description = "If the specified unit is the specified race.",
				inputDesc = "Defaults to player if only 'race' is given. Race can be given as name or ID.",
				inputs = { input("Unit", "unit?"), input("Race", "string", unpack(raceList)), },
				script = function(unit, race)
					if not unit then return false end
					if not race then
						race = unit; unit = "player"
					end     -- no unit given, only race - move data from unit to race and then default unit to player

					if tonumber(race) then -- it's a race ID, compensate
						return select(3, UnitRace(unit and unit or "player")) == tonumber(race)
					else
						return (lower(UnitRace(unit and lower(unit) or "player")) == lower(race))
					end
				end,
			},
			{
				key = "isClass",
				name = "Is Class",
				description = "If the specified unit is the specified class.",
				inputDesc = "Defaults to player if only 'class' is given. Class can be given as name or ID.",
				inputs = { input("Unit", "unit?"), input("Class", "string|number", unpack(classList)), },
				script = function(unit, class)
					if not unit then return false end
					if not class then
						class = unit; unit = "player"
					end      -- no unit given, only class - move data from unit to class and then default unit to player

					if tonumber(class) then -- it's a class ID, compensate
						return select(3, UnitClass(unit and unit or "player")) == tonumber(class)
					else
						return (lower(UnitClass(unit and lower(unit) or "player")) == lower(class))
					end
				end,
			},
			{
				key = "isGender",
				name = "Is Gender",
				description = "If the specified unit is the specified sex/gender. Sex can be given as a word or ID.",
				inputDesc = "Defaults to player if only 'sex' is given.",
				inputs = { input("Unit", "unit?"), input("Sex", "string", "1. unknown", "2. male", "3. female"), },
				script = function(unit, sex)
					if not unit then return false end
					if not sex then
						sex = unit; unit = "player"
					end -- no unit given, only sex - move data from unit to sex and then default unit to player

					if tonumber(sex) then
						-- already a valid number, use it
						sex = tonumber(sex)
					else
						-- need to convert to ID instead of string
						local genders = { unknown = 1, male = 2, female = 3 }
						sex = genders[lower(sex)]
					end
					if not sex then return false end -- failsafe, no gender avail

					return (UnitSex(unit and lower(unit) or "player") == sex)
				end,
			},
		}
	},
	{
		catName = "Player Character",
		catItems = {
			{
				key = "hasTarget",
				name = "Has Target",
				description = "Returns true if you currently have anything targeted.",
				script = function() return UnitExists("target") end,
			},
			{
				key = "isIndoors",
				name = "Is Indoors",
				description = "Returns true if the player character is currently indoors.",
				script = function() return IsIndoors() end,
			},
			{
				key = "isOutdoors",
				name = "Is Outdoors",
				description = "Returns true if the player character is currently outdoors.",
				script = function() return IsOutdoors() end,
			},
			{
				key = "isMounted",
				name = "Is Mounted",
				description = "Returns true if the player character is mounted.",
				script = function() return IsMounted() end,
			},
			{
				key = "isStealth",
				name = "Is Stealthed",
				description = "Returns true if the player character is currently stealthed.",
				script = function() return IsStealthed() end,
			},
			--[[ -- Instances are all flagged as normal world IIRC, so this kinda fails, always..
			{
				key = "isInInstance",
				name = "Is In Instance",
				description = "Returns true the if player character is inside an instance (battleground, arena, dungeon, raid, etc).",
				script = function() return IsInInstance() end,
			},
			--]]
			{
				key = "isInParty",
				name = "Is in Party (Self)",
				description = "Returns true if the player character is in a party.",
				inputs = {},
				script = function() return UnitInParty("player") end,
			},
			{
				key = "isInRaid",
				name = "Is in Raid (Self)",
				description = "Returns true if the player character is part of a raid. You can stack this as 'not' on top of a 'Is In Party (Self)' to check if in a party, but not a raid.",
				inputs = {},
				script = function() return IsInRaid() end,
			},
			{
				key = "facStanding",
				name = "Has Standing with Faction",
				description = "Returns true if the player has a standing equal to (or 'greater than / equal to' if enabled) with the specified faction.",
				inputDesc = "Faction Standing IDs range from 0 (Unknown) to 4 (Neutral) to 8 (Exalted).\nWhen using '.look faction', use the ID in the actual faction name.",
				inputExample = "<1228, 5, true> - Checks if your current standing with faction 1228 (Forest Hozen) is rank 5 (Friendly), or higher.",
				inputs = { input("Faction ID", "number"), input("Standing ID", "number"), input("Or Greater Than", "boolean?"), },
				script = function(factionID, standingID, greaterThan)
					local currentStanding = select(3, GetFactionInfoByID(tonumber(factionID)))
					if greaterThan and toBoolean(greaterThan) then -- greaterThan was real & also was true bool
						return (currentStanding >= tonumber(standingID))
					else
						return (currentStanding == tonumber(standingID))
					end
				end,
			},
		}
	},

	-- Target
	---- Has Target
	---- Target Name Equals...
	---- Target is in Spell Range
	---- Target Has Aura
	---- Target is Friend
	---- Target is Enemy
	---- Target is Player
	---- Target is Visible
	---- Target has Display ID
	{
		catName = "Target",
		catItems = {
			{
				key = "tarHasTar",
				name = "Has Target",
				description = "Returns true if your target currently has anything targeted. Target-ception.",
				script = function() return UnitExists("targettarget") end,
			},
			{
				key = "tarInParty",
				name = "Target is in my Party",
				description = "Returns true if the target is in your party. Cannot check if a target is just in any party.",
				script = function() return UnitInParty("target") end,
			},
			{
				key = "tarNameIs",
				name = "Target Name Equals...",
				description = "Returns true if the specified unit's current target is equal to the specified string. Case sensitive.",
				inputDesc = "Name is case sensitive.",
				inputs = { input("Name", "string"), },
				script = function(name) return UnitName("target") == name end,
			},
			--[[ -- Disabled until we have a proper way to get target position
			{
				key = "tarPosRange",
				name = "Target in X Range",
				description =
				"Checks if your target is within the number of meters from you. Limited to only working outdoors & not in an instance (dungeon/raid/bg/arena). Only checks XY distance on a 2D plane, does not consider Z / height.",
				inputs = { input("Range", "number"), },
				script = function(range)
					range = tonumber(range)
					if not range then return false, error("Arcanum Condition - tarPosRange - Invalid Range for Target Position Range Condition (Arcanum)") end
					local posY, posX, posZ = UnitPosition("target")
					if not posY or not posX then return false, error("Arcanum Condition - tarPosRange - Failed to gather UnitPosition for Target") end
					local myY, myX, myZ = C_Epsilon.GetPosition()
					return (ns.Utils.Data.getDistanceBetweenPoints(posX, posY, myX, myY) <= range)
				end,
			},
			--]]
			{
				key = "tarInterRange",
				name = "Target in Interact Range",
				description = "Checks if your target is within the given interaction range. Factors in height.",
				inputDesc = "Available Interaction Index IDs: 1 = 28 yards, 2 = 8 yards, 3 = 7 yards.",
				inputs = { input("Interact Index", "number", "1", "2", "3"), },
				script = function(interactIndex)
					if not tonumber(interactIndex) then return false, cError("tarInterRange", "Invalid Interact Distance, could not resolve to number") end
					return CheckInteractDistance("target", tonumber(interactIndex))
				end,
			},
			{
				key = "tarAura",
				name = "Target has Aura",
				description = "If the target has a specific aura applied.",
				inputs = { input("Aura ID", "number"), },
				script = function(auraID) return ns.Utils.Aura.checkTargetAuraID(tonumber(auraID)) end,
			},
			{
				key = "tarAuraNum",
				name = "Target has Number of Aura",
				description = "If the target currently has X number of stacks of the specified aura.",
				inputDesc = "May specify 'true' as the 3rd input to change it to a 'Greater Than or Equal To' check (use 'not' on the condition for Less Than).",
				inputExample = "<296289, 6, true> - Checks if the target has the 'Rage Stacking' aura applied 6 or more times.",
				inputs = { input("Aura ID", "number"), input("Stacks", "number"), input("Or Greater Than", "boolean?"), },
				script = function(auraID, stacks, greaterThan)
					local spell = { ns.Utils.Aura.checkTargetAuraID(tonumber(auraID)) }
					if #spell == 0 then return false end                                -- no spell, fail
					local spellStacks = select(3, spell); if spellStacks == 0 then spellStacks = 1 end -- Convert 0 to 1, since that just means we have one stack and it's not stackable.
					if greaterThan and toBoolean(greaterThan) then                      -- greaterThan was real & also was true bool
						return spellStacks >= tonumber(stacks)
					else
						return spellStacks == tonumber(stacks)
					end
				end
			},
			{
				key = "tarIsFriend",
				name = "Target is Friend",
				description = "Returns true if the target is friendly to the player.",
				script = function() return UnitIsFriend("target", "player") end,
			},
			{
				key = "tarIsEnemy",
				name = "Target is Enemy",
				description = "Returns true if the target is hostile to the player.",
				script = function() return UnitIsEnemy("target", "player") end,
			},
			{
				key = "tarIsPlayer",
				name = "Target is Player",
				description = "Returns true if the target is a real player character.",
				script = function() return UnitIsPlayer("target") end,
			},
			{
				key = "tarType",
				name = "Target is NPC Type",
				description = "Returns true if the target's type (humanoid, beast, undead, etc) matches the type specified.",
				inputDesc = "See https://warcraft.wiki.gg/wiki/API_UnitCreatureType for type options.",
				inputs = { input("Unit Type", "string"), },
				script = function(unitType)
					if not unitType then return cError("tarType", "Invalid NPC Type Given") end
					local tarType = UnitCreatureType("target")
					if not tarType then return false end -- no target
					return string.lower(tarType) == string.lower(unitType)
				end,
			},
			{
				key = "tarFamily",
				name = "Target is NPC Family",
				description =
				"Returns true if the target's family (Fox, Crab, Bear, etc) matches the family specified. Does not work on all creatures, but works on almost all beasts. Will return false for anything it doesn't work on.",
				inputDesc = "See https://warcraft.wiki.gg/wiki/API_UnitCreatureFamily for family options.",
				inputs = { input("Unit Family", "string"), },
				script = function(unitFamily)
					if not unitFamily then return cError("tarType", "Invalid NPC Family Given") end
					local tarType = UnitCreatureFamily("target")
					if not tarType then return false end -- no target or no family
					return string.lower(tarType) == string.lower(unitFamily)
				end,
			},
			{
				key = "tarDisplay",
				name = "Target has Display ID",
				description =
				"Checks if your target has the given Display ID. Note that this relies on the Epsilon AddOn, and that Display ID sync is not instant and may have a very small delay from when you target the NPC until that data is available.",
				inputs = { input("Display ID", "number") },
				script = function(displayID)
					if not tonumber(displayID) then return false, cError("tarDisplay", "Invalid Display ID, could not resolve to number.") end
					if not tonumber(lastCreatureDisplayID) then return false end
					return tonumber(lastCreatureDisplayID) == tonumber(displayID)
				end,
			},

		}
	},

	-- Map / Zone / Location
	---- Zone Name
	---- Subzone Name
	---- Map ID
	---- Within Range of Coordinates
	{
		catName = "Map / Zone / Location",
		catItems = {
			{
				key = "zoneName",
				name = "Zone Name",
				description = "Returns true if the name of the zone you are currently in is the same as the name provided.",
				inputs = { input("Zone Name", "string"), },
				script = function(zoneName) return lower(GetRealZoneText()) == lower(zoneName) end,
			},
			{
				key = "subZoneName",
				name = "Subzone Name",
				description = "Returns true if the name of the sub-zone you are currently in is the same as the name provided.",
				inputs = { input("Subzone Name", "string"), },
				script = function(subzoneName) return lower(GetSubZoneText()) == lower(subzoneName) end,
			},
			{
				key = "mmZoneName",
				name = "Minimap Zone Name",
				description =
				"Returns true if the name of the zone name shown on your mini-map you are currently in is the same as the name provided. Zone name on Mini-Map is dynamic between Zone, Sub-Zone, and WMO Areas.",
				inputs = { input("Subzone Name", "string"), },
				script = function(subzoneName) return lower(GetMinimapZoneText()) == lower(subzoneName) end,
			},
			{
				key = "mapID",
				name = "Map ID",
				description = "Returns true if the map you are currently on is the same ID as the ID provided.",
				inputs = { input("Map ID", "number"), },
				script = function(mapID) return select(4, UnitPosition("player")) == tonumber(mapID) end,
			},
			{
				key = "inRangeXYZ",
				name = "Within Range of Coordinates",
				description = "Checks if you are within the given range (distance / radius) of specific X Y Z coordinates on the given map ID.",
				inputDesc =
					"Range is calculated as radial distance from the point. Z Coord (Height) is optional; if given, height is included in distance check, if not, distance is calculated on a 2D plane excluding height." ..
					"\nMap ID is required and will fail range checks if you are on a different map; You may set Map ID as 0 however to skip map ID checks and only look at XY(Z) Range.",
				inputExample = "<2932, 6175.5, 123.5, 1737, 15> - Checks if player is within 15 yards of the given coordinates in Dranosh Valley (which in this case, is the '.tele start' portal).",
				inputs = { input("X Coordinate", "number"), input("Y Coordinate", "number"), input("Z Coordinate", "number?"), input("Map ID", "number"), input("Range (Distance)", "number"), },
				script = function(x, y, z, mapID, range)
					x = tonumber(x)
					y = tonumber(y)
					z = tonumber(z)
					mapID = tonumber(mapID)
					range = tonumber(range)
					if not x or not y then return end
					if not mapID or not range then return end

					local getDistanceBetweenPoints = ns.Utils.Data.getDistanceBetweenPoints
					local x2, y2, z2, mapID2 = getPlayerPositionData()

					if mapID ~= 0 then         -- Map ID 0 = bypass map check
						if mapID ~= mapID2 then return false end -- On the wrong map
					end
					if getDistanceBetweenPoints(x, y, x2, y2) < range then
						if z and getDistanceBetweenPoints(z, z2) > range then return false end -- If Z and if distance greater than range allowed then fail
						return true                                          -- everything semes good, continue
					end
					return false                                             -- if you made it here, then something failed
				end,
			},
		}
	},

	-- Phase
	---- Is Member
	---- Is Officer
	---- Is Owner
	---- Is in Phase ID
	---- DM Mode Enabled
	---- Current Time (Phase)
	{
		catName = "Phase",
		catItems = {
			{
				key = "phIsMember",
				name = "Is Member",
				description = "If your character is a member of the phase.",
				script = function() return ARC.XAPI.Phase.IsMember() end,
			},
			{
				key = "phIsOfficer",
				name = "Is Officer",
				description = "If your character is an officer of the phase.",
				script = function() return ARC.XAPI.Phase.IsOfficer() end,
			},
			{
				key = "phIsOwner",
				name = "Is Owner",
				description = "If your character is the owner of the phase.",
				script = function() return ARC.XAPI.Phase.IsOwner() end,
			},
			{
				key = "phDMOn",
				name = "DM Mode Enabled",
				description = "If phase DM mode is currently enabled.",
				script = function() return ARC.XAPI.Phase.IsDM() end,
			},
			{
				key = "phIDIs",
				name = "Is in Phase ID",
				description = "If you are in a specific phase number / ID.",
				inputs = { input("Phase ID", "number"), },
				script = function(phaseID) return ARC.XAPI.Phase.GetPhaseId() == phaseID end,
			},
			{
				key = "phTime",
				name = "Current Time (Phase)",
				description = "If the Phase Time is a certain time. Can provide a second input to check if within X minutes of that time.",
				inputDesc = "If modifier input is a number, checks if you are within that many minutes of the given time, otherwise checks if it's exactly that time.",
				inputs = { input("Time", "string<hour:minute>"), input("Mod", "number?"), },
				inputExample = "<13:30, 30> - Check's if it's within 30 minutes from 1:30pm - AKA: Check's if it's 1pm-2pm at all.",
				script = function(time, mod)
					return ns.Utils.Data.getNormalizedGameTimeDiff(time, mod)
				end,
			},
			{
				key = "phTimeAft",
				name = "Current Time is After",
				description = "If the Phase Time is after (later than) a certain time.",
				inputs = { input("Time", "string<hour:minute>"), },
				script = function(time) return ns.Utils.Data.getNormalizedGameTimeDiff(time, ">") end,
			},
			{
				key = "phTimeBef",
				name = "Current Time is Before",
				description = "If the Phase Time is before (earlier than) a certain time.",
				inputs = { input("Time", "string<hour:minute>"), },
				script = function(time) return ns.Utils.Data.getNormalizedGameTimeDiff(time, "<") end,
			},
		}
	},

	-- Arcanum
	---- ArcSpell Exists (CommID) (input = commID, phaseBoolean)
	---- ArcSpell is on Cooldown (input = commID, phaseBoolean)
	---- ArcVar is True (input = ArcVar, isPhase)
	---- ArcVar equals... (input = ArcVar, Value, isPhase)
	{ header = "Advanced" },
	{
		catName = "Arcanum",
		catItems = {
			{
				key = "arcSpellExists",
				name = "ArcSpell Exists (CommID)",
				description = "Returns true if an ArcSpell exists. Can use this in a Cast ArcSpell action for example to make sure that spell exists first before attempting to cast it.",
				inputs = { input("ArcSpell CommID", "string<commID>"), input("Phase?", "boolean?"), },
				script = function(arcspellCommid, phase)
					if not arcspellCommid then return false end
					if phase and toBoolean(phase) then
						return Vault.phase.findSpellByID(arcspellCommid) and true or false
					else
						return Vault.personal.findSpellByID(arcspellCommid) and true or false
					end
				end,
			},
			{
				key = "arcSpellOnCd",
				name = "ArcSpell is on Cooldown",
				description = "Returns true if the ArcSpell is on cooldown. Use a 'Not' condition if you want to ensure the spell is .. NOT.. on cooldown.",
				inputs = { input("ArcSpell CommID", "string<commID>"), input("Phase?", "boolean?"), },
				script = function(arcspellCommid, phase)
					if not arcspellCommid then return false end
					return ns.Actions.Cooldowns.isSpellOnCooldown(arcspellCommid, toBoolean(phase))
				end,
			},
			{
				key = "arcVarIsTrue",
				name = "ArcVar is True",
				description =
				"Returns true if the ArcVar tested is true / truthy. Note that any value that's NOT 'false' or 'nil' is considered truthy, so if the ArcVar = 'Tacos', then this would still succeed.",
				inputs = { input("ArcVar", "string"), input("Phase?", "boolean?"), },
				script = function(arcvar, phase)
					if not arcvar then return false end
					if phase and toBoolean(phase) then
						return ns.API.safeGetPhaseVar(arcvar)
					else
						return ARC.VAR[arcvar]
					end
				end,
			},
			{
				key = "arcVarEquals",
				name = "ArcVar Equals",
				description = "Returns true if the ArcVar equals the given string directly.",
				inputs = { input("ArcVar", "string"), input("Value", "string"), input("Phase?", "boolean?"), },
				script = function(arcvar, value, phase)
					if not arcvar then return false end
					if not value then return false end

					-- convert bools directly
					if lower(value) == "true" then
						value = true
					elseif lower(value) == "false" then
						value = false
					elseif lower(value) == "nil" then
						value = nil
					end

					local actualVal
					if phase and toBoolean(phase) then
						actualVal = ns.API.safeGetPhaseVar(arcvar)
					else
						actualVal = ARC.VAR[arcvar]
					end
					if not actualVal then -- ArcVar did not exist, special case handler to check if nil was the value, otherwise return false
						if value == nil then
							return true
						else
							return false
						end
					end

					if lower(actualVal) == "true" then
						actualVal = true
					elseif lower(actualVal) == "false" then
						actualVal = false
					elseif lower(actualVal) == "nil" then
						actualVal = nil
					end

					return (value == actualVal)
				end,
			},
		}
	},

	-- Random Roll
	-- Macro Script
	{
		key = "roll",
		name = "Random Roll",
		description =
		"Rolls a random number between the given min & max, and returns true only if the required number is Greater Than or Equal to the roll. If only min is given, it is treated as the max from 1 to #max.",
		inputDesc = "Because sometimes life needs to be unpredictable.",
		inputExample = "<15, 1, 20> to only succeed if a 15 or higher is rolled, out of a roll between 1 and 20.",
		inputs = { input("Required Roll", "number"), input("Min Number", "number"), input("Max Number", "number"), },
		doNotTestEval = true,
		script = function(reqRoll, minNumber, maxNumber)
			if not minNumber or not tonumber(minNumber) then return false end
			local rolledNumber = maxNumber and (random(tonumber(minNumber), tonumber(maxNumber))) or random(tonumber(minNumber))
			return (rolledNumber >= tonumber(reqRoll))
		end,
	},
	{
		key = "script",
		name = "Macro Script",
		description = "Perform a specified macro script.",
		inputDesc =
		[[A macro script must include an explicit return, or otherwise be a simple script that is a return value in itself. For example, `6 > 5` is a valid script here, but `if 6 > 5 then print("hey") end` will always fail the test as it does not return any truthy statement.]],
		inputs = { input("Macro or Lua Script", "string"), },
		doNotTestEval = true,
		script = function(macroOrLuaScript)
			if not macroOrLuaScript then return false end
			local script = macroOrLuaScript
			if not script:match("return") then
				script = "return " .. script
			end
			if ns.Cmd.runMacroText(script) then
				return true
			end
			return false
		end,
	},
}

---@type ConditionRow
local lastSelectedConditionRow

local getLastSelectedRow = function() return lastSelectedConditionRow end
local setLastSelectedRow = function(row) lastSelectedConditionRow = row end

---@type table<ConditionKey, ConditionTypeData>
local conditionKeysMap = {}

local function genConditionsKeyMap(table)
	if not table then -- not an interation, default table & clear map as this is a fresh regen
		table = conditions
		conditionKeysMap = {}
	end

	for k, v in ipairs(table) do
		if v.key then
			conditionKeysMap[v.key] = v --[[@as ConditionData]]
		elseif v.catName then
			genConditionsKeyMap(v.catItems)
		end
	end
end

local CONDITION_DATA_KEY = Constants.CONDITION_DATA_KEY

---@param row ConditionRow
---@param key ConditionDataTypes
---@param value any
local function setDataByName(row, key, value)
	local data = row:GetUserData(CONDITION_DATA_KEY)
	data[key] = value
end

local function genCondRadio(key)
	local conditionData = conditionKeysMap[key] --[[@as ConditionTypeData]]
	local options = {
		get = function()
			return lastSelectedConditionRow:GetUserData(CONDITION_DATA_KEY).Type == conditionData.key
		end,
		set = function(self, val)
			lastSelectedConditionRow:GetUserData("dropdown"):SetText(conditionData.name)
			setDataByName(lastSelectedConditionRow, "Type", conditionData.key)
			lastSelectedConditionRow:GetUserData("update")()
		end,
		tooltipTitle = conditionData.name,
		tooltipText = conditionData.description,
	} --[[@as DropdownToggleCreationOptions]]
	return Dropdown.radio(conditionData.name, options)
end

local menuList = {}
local menuCats = {}
local function genConditionsMenuList()
	for index, condition in ipairs(conditions) do
		if condition.header then -- this is a header-only row, only process it as a header
			tinsert(menuList, Dropdown.header(condition.header))
		elseif condition.catName then -- it's a category
			local catItems = {}
			for k, v in ipairs(condition.catItems) do
				tinsert(catItems, genCondRadio(v.key))
			end
			tinsert(menuList, Dropdown.selectmenu(condition.catName, catItems))
		elseif condition.key then -- It's a standalone condition entry
			tinsert(menuList, genCondRadio(condition.key))
		end
	end
	return menuList
end

local function getConditionsMenuList()
	return menuList
end

local function getConditionDataByKey(key)
	return conditionKeysMap[key]
end

local function getConditionsData()
	return conditions
end

local function registerNewCondition(key, data)
	if (not key) or (not data) or (type(data) ~= "table") then return end
	data.key = key
	tinsert(conditions, data)
	genConditionsKeyMap()
	genConditionsMenuList()
end

----------
-- Init

genConditionsKeyMap()
genConditionsMenuList()

local copiedConditionsData
local function saveCopyOfConditions(data)
	copiedConditionsData = data
end
local function getCopiedConditions()
	return copiedConditionsData
end

---@class Action_ConditionsData
ns.Actions.ConditionsData = {
	getByKey = getConditionDataByKey,
	getAll = getConditionsData,
	new = registerNewCondition,

	setLastSelectedRow = setLastSelectedRow,
	getLastSelectedRow = getLastSelectedRow,

	genMenuList = genConditionsMenuList,
	getMenuList = getConditionsMenuList,

	selected = lastSelectedConditionRow,

	copySave = saveCopyOfConditions,
	copyGet = getCopiedConditions,
}
