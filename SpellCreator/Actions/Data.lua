---@class ns
local ns = select(2, ...)

local Aura = ns.Utils.Aura
local Cmd = ns.Cmd
local Logging = ns.Logging
local Vault = ns.Vault
local Utils = ns.Utils

local Constants = ns.Constants
local AceConsole = ns.Libs.AceConsole

local cmd, cmdWithDotCheck = Cmd.cmd, Cmd.cmdWithDotCheck
local runMacroText = Cmd.runMacroText
local cprint = Logging.cprint
local Tooltip = ns.Utils.Tooltip

local toBoolean = Utils.Data.toBoolean
local function onToBoolean(val)
	if strtrim(string.lower(val)) == "on" then return true else return false end
end

local maxBackupsPerChar = 3

local Scripts = ns.Actions.Data_Scripts
local revertHoldingVars = {}

---@enum ActionType
local ACTION_TYPE = {
	MacroText = "MacroText",
	SecureMacro = "SecureMacro",
	Command = "Command",
	ArcSpell = "ArcSpell",
	ArcSpellPhase = "ArcSpellPhase",
	ArcSaveFromPhase = "ArcSaveFromPhase",
	ArcCastbar = "ArcCastbar",
	ArcStopSpells = "ArcStopSpells",
	ArcStopThisSpell = "ArcStopThisSpell",
	ArcStopSpellByName = "ArcStopSpellByName",
	ArcTrigCooldown = "ArcTrigCooldown",

	Anim = "Anim",
	Standstate = "Standstate",
	ResetAnim = "ResetAnim",
	ResetStandstate = "ResetStandstate",
	ToggleSheath = "ToggleSheath",

	SpellAura = "SpellAura",
	ToggleAura = "ToggleAura",
	ToggleAuraSelf = "ToggleAuraSelf",
	RemoveAura = "RemoveAura",
	RemoveAllAuras = "RemoveAllAuras",
	PhaseAura = "PhaseAura",
	PhaseUnaura = "PhaseUnaura",
	GroupAura = "GroupAura",
	GroupUnaura = "GroupUnaura",

	SpellCast = "SpellCast",
	SpellTrig = "SpellTrig",

	Equip = "Equip",
	EquipSet = "EquipSet",
	MogitEquip = "MogitEquip",
	Unequip = "Unequip",
	AddItem = "AddItem",
	RemoveItem = "RemoveItem",
	AddRandomItem = "AddRandomItem",

	-- Camera Actions
	RotateCameraLeftStart = "RotateCameraLeftStart",
	RotateCameraRightStart = "RotateCameraRightStart",
	RotateCameraUpStart = "RotateCameraUpStart",
	RotateCameraDownStart = "RotateCameraDownStart",
	ZoomCameraOutStart = "ZoomCameraOutStart",
	ZoomCameraInStart = "ZoomCameraInStart",
	ZoomCameraSet = "ZoomCameraSet",
	ZoomCameraOutBy = "ZoomCameraOutBy",
	ZoomCameraInBy = "ZoomCameraInBy",
	ZoomCameraSaveCurrent = "ZoomCameraSaveCurrent",
	ZoomCameraLoadSaved = "ZoomCameraLoadSaved",
	MouselookModeStart = "MouselookModeStart",
	RotateCameraStop = "RotateCameraStop",
	SetViewSmooth = "SetViewSmooth",
	SetViewSnap = "SetViewSnap",

	Scale = "Scale",

	Speed = "Speed",
	SpeedWalk = "SpeedWalk",
	SpeedBackwalk = "SpeedBackwalk",
	SpeedFly = "SpeedFly",
	SpeedSwim = "SpeedSwim",

	TRP3Profile = "TRP3Profile",
	TRP3StatusToggle = "TRP3StatusToggle",
	TRP3StatusIC = "TRP3StatusIC",
	TRP3StatusOOC = "TRP3StatusOOC",

	Morph = "Morph",
	Native = "Native",
	Unmorph = "Unmorph",

	PlayLocalSoundKit = "PlayLocalSoundKit",
	PlayLocalSoundFile = "PlayLocalSoundFile",
	--StopLocalSound = "StopLocalSound",
	PlayPhaseSound = "PlayPhaseSound",

	CheatOn = "CheatOn",
	CheatOff = "CheatOff",

	ARCSet = "ARCSet",
	ARCTog = "ARCTog",
	ARCCopy = "ARCCopy",

	ARCPhaseSet = "ARCPhaseSet",
	ARCPhaseTog = "ARCPhaseTog",

	-- UI, Prompt & Message Actions
	PrintMsg = "PrintMsg",
	RaidMsg = "RaidMsg",
	ErrorMsg = "ErrorMsg",
	BoxMsg = "BoxMsg",
	BoxPromptCommand = "BoxPromptCommand",
	BoxPromptScript = "BoxPromptScript",
	BoxPromptScriptNoInput = "BoxPromptScriptNoInput",
	BoxPromptCommandNoInput = "BoxPromptCommandNoInput",

	HideMostUI = "HideMostUI",
	UnhideMostUI = "UnhideMostUI",
	FadeOutMainUI = "FadeOutMainUI",
	FadeInMainUI = "FadeInMainUI",

	-- Location Actions
	SaveARCLocation = "SaveARCLocation",
	GotoARCLocation = "GotoARCLocation",
	WorldportCommand = "WorldportCommand",
	TeleCommand = "TeleCommand",
	PhaseTeleCommand = "PhaseTeleCommand",

	-- Spawn Actions
	SpawnBlueprint = "SpawnBlueprint",

	-- QC Actions
	QCBookToggle = "QCBookToggle",
	QCBookStyle = "QCBookStyle",
	QCBookSwitchPage = "QCBookSwitchPage",

	-- Kinesis Integration
	Kinesis_FlyEnable = "Kinesis_FlyEnable",
	Kinesis_EFDEnable = "Kinesis_EFDEnable",
	Kinesis_FlyShift = "Kinesis_FlyShift",
	Kinesis_FlyTripleJump = "Kinesis_FlyTripleJump",
	Kinesis_LandJumpSet = "Kinesis_LandJumpSet",
	Kinesis_AutoLandDelay = "Kinesis_AutoLandDelay",

	Kinesis_ToggleFlightSpells = "Kinesis_ToggleFlightSpells",
	Kinesis_FlightArcEnabled = "Kinesis_FlightArcEnabled",
	Kinesis_FlightArcStart = "Kinesis_FlightArcStart",
	Kinesis_FlightArcStop = "Kinesis_FlightArcStop",
	Kinesis_FlightSetSpells = "Kinesis_FlightSetSpells",
	Kinesis_FlightLoadSpellSet = "Kinesis_FlightLoadSpellSet",

	Kinesis_SprintEnabled = "Kinesis_SprintEnabled",
	Kinesis_SprintGround = "Kinesis_SprintGround",
	Kinesis_SprintFly = "Kinesis_SprintFly",
	Kinesis_SprintSwim = "Kinesis_SprintSwim",
	Kinesis_SprintReturnOrig = "Kinesis_SprintReturnOrig",

	Kinesis_SprintEmoteAll = "Kinesis_SprintEmoteAll",
	--Kinesis_SprintEmoteWalk = "Kinesis_SprintEmoteWalk",
	--Kinesis_SprintEmoteFly = "Kinesis_SprintEmoteFly",
	--Kinesis_SprintEmoteSwim = "Kinesis_SprintEmoteSwim",
	Kinesis_SprintEmoteText = "Kinesis_SprintEmoteText",
	Kinesis_SprintEmoteRate = "Kinesis_SprintEmoteRate",

	Kinesis_SprintSpellAll = "Kinesis_SprintSpellAll",
	--Kinesis_SprintSpellWalk = "Kinesis_SprintSpellWalk",
	--Kinesis_SprintSpellFly = "Kinesis_SprintSpellFly",
	--Kinesis_SprintSpellSwim = "Kinesis_SprintSpellSwim",

	Kinesis_SprintArcEnabled = "Kinesis_SprintArcEnabled",
	Kinesis_SprintArcStart = "Kinesis_SprintArcStart",
	Kinesis_SprintArcStop = "Kinesis_SprintArcStop",

	Kinesis_SprintSetSpells = "Kinesis_SprintSetSpells",
	Kinesis_SprintLoadSpellSet = "Kinesis_SprintLoadSpellSet",
}

---@param name string
---@param data ServerActionTypeData
---@return ServerActionTypeData
local function serverAction(name, data)
	data.name = name
	data.comTarget = "server"

	return data
end

---@param name string
---@param data FunctionActionTypeData
---@return FunctionActionTypeData
local function scriptAction(name, data)
	data.name = name
	data.comTarget = "func"

	return data
end

---@type table<ActionType, FunctionActionTypeData | ServerActionTypeData>
local actionTypeData = {
	[ACTION_TYPE.SpellCast] = serverAction("Cast Spell", {
		command = "cast @N@",                                                                                                                                            -- The chat command, or Lua function to process
		description = "Cast a spell using a Spell ID, to selected target, or self if no target.",                                                                        -- Description for on-mouse-over
		dataName = "Spell ID(s)",                                                                                                                                        -- Label for the ID Box, nil to disable the ID box
		inputDescription = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\rUse " .. Tooltip.genContrastText('.look spell') .. " to find IDs.", -- Description of the input for GameTooltip
		revert = "unaura @N@",                                                                                                                                           -- The command that reverts it, i.e, 'unaura' for 'aura'
		revertDesc = "unaura",
		selfAble = true,                                                                                                                                                 -- True/False - if able to use the self-toggle checkbox
	}),
	[ACTION_TYPE.SpellTrig] = serverAction("Cast Spell (Trig)", {
		command = "cast @N@ trig",
		description = "Cast a spell using a Spell ID, to selected target, or self if no target, using the triggered flag.",
		dataName = "Spell ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\rUse " .. Tooltip.genContrastText('.look spell') .. " to find IDs.",
		revert = "unaura @N@",
		revertDesc = "unaura",
		selfAble = true,
	}),
	[ACTION_TYPE.SpellAura] = serverAction("Apply Aura", {
		command = "aura @N@",
		description = "Applies an Aura from a Spell ID on your target if able, or yourself otherwise.",
		dataName = "Spell ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to apply multiple auras at once.\n\rUse " .. Tooltip.genContrastText('.look spell') .. " to find IDs.",
		revert = "unaura @N@",
		revertDesc = "unaura",
		selfAble = true,
	}),
	[ACTION_TYPE.PhaseAura] = serverAction("Phase Aura", {
		command = "phase aura @N@",
		description = "Applies an Aura to everyone in the phase.",
		dataName = "Spell ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to apply multiple auras at once.\n\rUse " .. Tooltip.genContrastText('.look spell') .. " to find IDs.",
		revert = "phase unaura @N@",
		revertDesc = "phase unaura",
		selfAble = false,
	}),
	[ACTION_TYPE.PhaseUnaura] = serverAction("Phase Unaura", {
		command = "phase unaura @N@",
		description = "Removes an Aura from everyone in the phase.",
		dataName = "Spell ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to remove multiple auras at once.\n\rUse " .. Tooltip.genContrastText('.look spell') .. " to find IDs.",
		revert = "phase aura @N@",
		revertDesc = "phase aura",
		selfAble = false,
	}),
	[ACTION_TYPE.GroupAura] = serverAction("Group Aura", {
		command = "group aura @N@",
		description = "Applies an Aura to everyone in the group.",
		dataName = "Spell ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to apply multiple auras at once.\n\rUse " .. Tooltip.genContrastText('.look spell') .. " to find IDs.",
		revert = "group unaura @N@",
		revertDesc = "group unaura",
		selfAble = false,
	}),
	[ACTION_TYPE.GroupUnaura] = serverAction("Group Unaura", {
		command = "group unaura @N@",
		description = "Removes an Aura from everyone in the group.",
		dataName = "Spell ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to remove multiple auras at once.\n\rUse " .. Tooltip.genContrastText('.look spell') .. " to find IDs.",
		revert = "group aura @N@",
		revertDesc = "group aura",
		selfAble = false,
	}),
	[ACTION_TYPE.ToggleAura] = scriptAction("Toggle Aura", {
		command = function(spellID)
			if Aura.checkForAuraID(tonumber(spellID)) then
				cmd("unaura " .. spellID)
			else
				cmd("aura "
					.. spellID)
			end
		end,
		description = "Toggles an Aura on / off.\n\rApplies to your target if you have Phase DM on & Officer+",
		dataName = "Spell ID",
		inputDescription = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\rUse " .. Tooltip.genContrastText('.look spell') .. " to find IDs.",
		revert = function(spellID)
			if Aura.checkForAuraID(tonumber(spellID)) then
				cmd("unaura " .. spellID)
			else
				cmd("aura "
					.. spellID)
			end
		end,
		revertDesc = "Toggles the Aura again",
	}),
	[ACTION_TYPE.ToggleAuraSelf] = scriptAction("Toggle Aura (Self)", {
		command = function(spellID)
			if Aura.checkForAuraID(tonumber(spellID)) then
				cmd("unaura " .. spellID .. " self")
			else
				cmd("aura "
					.. spellID .. " self")
			end
		end,
		description = "Toggles an Aura on / off.\n\rAlways applies on yourself.",
		dataName = "Spell ID",
		inputDescription = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\rUse" .. Tooltip.genContrastText('.look spell') .. " to find IDs.",
		revert = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID .. " self") else cmd("aura " .. spellID .. " self") end end,
		revertDesc = "Toggles the Aura again",
	}),
	[ACTION_TYPE.Anim] = serverAction("Emote/Anim", {
		command = "mod anim @N@",
		description = "Modifies target's current animation using 'mod anim'.\n\rUse " .. Tooltip.genContrastText('.look emote') .. " to find IDs.",
		dataName = "Emote ID",
		inputDescription = "Accepts multiple IDs, separated by commas, to do multiple anims at once -- but the second usually over-rides the first anyways.\n\rUse " ..
			Tooltip.genContrastText('.look emote') .. " to find IDs.",
		revert = "mod stand 30",
		revertDesc = "Reset to Standstate 30 (none)",
		selfAble = false,
	}),
	[ACTION_TYPE.ResetAnim] = serverAction("Reset Emote/Anim", {
		command = "mod stand 30",
		description = "Reset target's current animation to Standstate 30 (none).",
		dataName = nil,
		revert = nil,
		revertAlternative = "another emote action",
	}),
	[ACTION_TYPE.ResetStandstate] = serverAction("Reset Standstate", {
		command = "mod stand 0",
		description = "Reset the Standstate of your character to 0 (none).",
		dataName = nil,
		revert = nil,
		revertAlternative = "another emote action",
	}),
	[ACTION_TYPE.Morph] = serverAction("Morph", {
		command = "morph @N@",
		description = "Morph into a Display ID.",
		dataName = "Display ID",
		inputDescription = "No, you can't put multiple to become a hybrid monster..\n\rUse " .. Tooltip.genContrastText('.look displayid') .. " to find IDs.",
		revert = "demorph",
		revertDesc = "demorph",
		selfAble = false,
	}),
	[ACTION_TYPE.Native] = serverAction("Native", {
		command = "mod native @N@",
		description = "Modifies your Native to specified Display ID.",
		dataName = "Display ID",
		inputDescription = "Use " .. Tooltip.genContrastText('.look displayid') .. " to find IDs.",
		revert = "demorph",
		revertDesc = "demorph",
		selfAble = false,
	}),
	[ACTION_TYPE.Standstate] = serverAction("Standstate", {
		command = "mod standstate @N@",
		description = "Change the emote of your character while standing to an Emote ID.",
		dataName = "Standstate ID",
		inputDescription = "Accepts multiple IDs, separated by commas, to set multiple standstates at once.. but you can't have two, so probably don't try it.\n\rUse " ..
			Tooltip.genContrastText('.look emote') .. " to find IDs.",
		revert = "mod stand 0",
		revertDesc = "Set Standstate to 0 (none)",
		selfAble = false,
	}),
	[ACTION_TYPE.ToggleSheath] = scriptAction("Sheath/Unsheath Weapon", {
		command = function() ToggleSheath() end,
		description = "Sheath or unsheath your weapon.",
	}),
	[ACTION_TYPE.Equip] = scriptAction("Equip Item", {
		command = function(vars) EquipItemByName(vars) end,
		description = "Equip an Item by name or ID. Item must be in your inventory.\n\rName is a search in your inventory by keyword - using ID is recommended.",
		dataName = "Item ID or Name(s)",
		inputDescription = "Accepts multiple IDs/Names, separated by commas, to equip multiple items at once.\n\rUse " ..
			Tooltip.genContrastText('.look item') .. ", or mouse-over an item in your inventory for IDs.",
		example =
		"You want to equip 'Violet Guardian's Helm', ID: 141357, but have 'Guardian's Leather Belt', ID: 35156 in your inventory also, using 'Guardian' as the text will equip the belt, so you'll want to use the full name, or better off just use the actual item ID.",
		revert = nil,
		revertAlternative = "a separate unequip item action",
		selfAble = false,
	}),
	[ACTION_TYPE.AddItem] = serverAction("Add Item", {
		command = "additem @N@",
		description = "Add an item to your inventory.\n\rYou may specify multiple items separated by commas, and may specify item count & bonusID per item as well.",
		dataName = "Item ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to add multiple items at once.\n\rUse " ..
			Tooltip.genContrastText('.look item') .. ", or mouse-over an item in your inventory for IDs.",
		example = Tooltip.genContrastText("125775 1 449, 125192 1 449") .. " will add 1 of each item with Heroic (449) tier",
		revert = nil,
		revertAlternative = "a separate remove item action",
		selfAble = false,
	}),
	[ACTION_TYPE.RemoveItem] = serverAction("Remove Item", {
		command = "additem @N@ -1",
		description =
		"Remove an item from your inventory.\n\rYou may specify multiple items separated by commas, and may optionally specify item count as a negative number to remove that many of the item.",
		dataName = "Item ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to remove multiple items at once.\n\rUse " ..
			Tooltip.genContrastText('.look item') .. ", or mouse-over an item in your inventory for IDs.",
		example = Tooltip.genContrastText("125775 -10") .. " to remove 10 of that item.",
		revert = nil,
		revertAlternative = "a separate add item action",
		selfAble = false,
	}),
	[ACTION_TYPE.AddRandomItem] = scriptAction("Add Random Item", {
		command = function(vars)
			--[[
			-- Item Format Method (space delimit): itemID:bonusIDs+amount,weight
			local itemsTable = { strsplit(" ", vars) }
			local finalItems = {}
			for i = 1, #itemsTable do
				local v = itemsTable[i]
				local item = {}
				local weight
				item.entry, item.bonus, item.amount, weight = v:match("(%d*)%:?(%d*)%+?(%d*)%,?(%d*)")
				if not weight or weight == "" then weight = 1 end
				table.insert(finalItems, { tonumber(weight), item })
			end
			local randomItem = ns.Utils.Data.getRandomWeightedArg(finalItems)
			cmd(("additem %s %s %s"):format(randomItem.entry, randomItem.amount and randomItem.amount or "1", randomItem.bonus and randomItem.bonus or ""))
			--]]
			-- Item Format Method (comma delimit): itemID amount bonusIDs+weight
			local itemsTable = { strsplit(",", vars) }
			local finalItems = {}
			for i = 1, #itemsTable do
				local v = itemsTable[i]
				local item, weight = strsplit("+", v)
				if not weight or weight == "" then weight = 1 end
				table.insert(finalItems, { tonumber(strtrim(weight)), strtrim(item) })
			end
			local randomItem = ns.Utils.Data.getRandomWeightedArg(finalItems)
			cmd("additem " .. randomItem)
		end,
		description = "Add a random item to your inventory from the given list.\n\rItems may be weighted to modify their chance at being chosen.",
		dataName = "Item Pool",
		inputDescription = "Items should be separated by commas, and formatted as " ..
			Tooltip.genContrastText("itemID amount bonusIDs+weight") ..
			". Amount & BonusIDs are optional, but amount must be given is bonusIDs is given also. Weight is optional and defaults to 1 if not given.\n\rWeights are normalized, so if they're all the same value they have equal chance of being used. (Example: 1 + 1 = 2. Each is 1/2 (50%) chance. 1 + 2 + 1 = 4. Each is 1/4 (25%), 2/4 (50%), 1/4 (25%) chance.)",
		example = Tooltip.genContrastText("125775 1 449+99, 125192 2+1") .. " will randomly choose between a 99% chance to add 1 copy of 125775 (Heroic), or 1% chance for 2 copies of 125192 (Normal)",
		revert = nil,
		revertAlternative = "a separate remove item action",
		selfAble = false,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.RemoveAura] = serverAction("Remove Aura", {
		command = "unaura @N@",
		description = "Remove an Aura by Spell ID.",
		dataName = "Spell ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to remove multiple auras at once.",
		revert = "aura",
		revertDesc = "Reapplies the same aura",
		selfAble = true,
	}),
	[ACTION_TYPE.RemoveAllAuras] = serverAction("Remove All Auras", {
		command = "unaura all",
		description = "Remove all Auras.",
		dataName = nil,
		revert = nil,
		revertAlternative = "another aura/cast action",
		selfAble = true,
	}),
	[ACTION_TYPE.Unmorph] = serverAction("Remove Morph", {
		command = "demorph",
		description = "Remove all morphs, including natives.",
		dataName = nil,
		revert = nil,
		revertAlternative = "another morph/native action",
	}),
	[ACTION_TYPE.Unequip] = scriptAction("Unequip Item", {
		command = function(slotID)
			PickupInventoryItem(slotID); PutItemInBackpack();
		end,
		description =
		"Unequips an item by item slot.\n\rCommon IDs:\rHead: 1          Shoulders: 3\rShirt: 4          Chest: 5\rWaist: 6         Legs: 7\rFeet: 8           Wrist: 9\rHands: 10       Back: 15\rTabard: 19\rMain-hand: 16\rOff-hand: 17",
		dataName = "Item Slot ID(s)",
		inputDescription =
		"Common IDs:\rHead: 1          Shoulders: 3\rShirt: 4           Chest: 5\rWaist: 6         Legs: 6\rFeet: 8            Wrist: 9\rHands: 10       Back: 15\rTabard: 19\rMain-hand: 16\rOff-hand: 17\n\rAccepts multiple slot ID's, separated by commas, to remove multiple slots at the same time.",
		revert = nil,
		revertAlternative = "a separate Equip Item action",
	}),
	[ACTION_TYPE.TRP3Profile] = scriptAction("TRP3 Profile", {
		command = function(profile) SlashCmdList.TOTALRP3("profile " .. profile) end,
		description = "Change the active Total RP profile to the profile with the specified name.",
		dataName = "Profile name",
		inputDescription = "The name of the profile as it appears in Total RP's profile list.",
		revert = nil,
		selfAble = false,
		dependency = "totalRP3",
	}),
	[ACTION_TYPE.TRP3StatusToggle] = scriptAction("TRP3: IC/OOC", {
		command = function() SlashCmdList.TOTALRP3("status toggle") end,
		description = "Switch your Total RP 3 status to the opposite state.",
		dataName = nil,
		revert = nil,
		selfAble = false,
		dependency = "totalRP3",
	}),
	[ACTION_TYPE.TRP3StatusIC] = scriptAction("TRP3: IC", {
		command = function() SlashCmdList.TOTALRP3("status ic") end,
		description = "Set your Total RP 3 status to IC.",
		dataName = nil,
		revert = nil,
		selfAble = false,
		dependency = "totalRP3",
	}),
	[ACTION_TYPE.TRP3StatusOOC] = scriptAction("TRP3: OOC", {
		command = function() SlashCmdList.TOTALRP3("status ooc") end,
		description = "Set your Total RP 3 status to OOC.",
		dataName = nil,
		revert = nil,
		selfAble = false,
		dependency = "totalRP3",
	}),
	[ACTION_TYPE.Scale] = serverAction("Scale", {
		command = "mod scale @N@",
		description = "Modifies your targets size using 'mod scale'.\n\rApplies to self if no target is selected and/or not in DM mode.",
		dataName = "Scale",
		inputDescription = "Value may range from 0.1 to 10.",
		revert = "mod scale 1",
		revertDesc = "Reset to scale 1",
		selfAble = false,
	}),
	[ACTION_TYPE.Speed] = serverAction("Speed", {
		command = "mod speed @N@",
		description = "Modifies movement speed using 'mod speed'.",
		dataName = "Speed",
		inputDescription = "Value may range from 0.1 to 50.",
		revert = "mod speed 1",
		revertDesc = "Reset to speed 1",
		selfAble = false,
	}),
	[ACTION_TYPE.SpeedBackwalk] = serverAction("Walk Speed (Back)", {
		command = "mod speed backwalk @N@",
		description = "Modifies speed of walking backwards.",
		dataName = "Speed",
		inputDescription = "Value may range from 0.1 to 50.",
		revert = "mod speed backwalk 1",
		revertDesc = "Reset to backwalk speed 1",
		selfAble = false,
	}),
	[ACTION_TYPE.SpeedFly] = serverAction("Fly Speed", {
		command = "mod speed fly @N@",
		description = "Modifies flying speed.",
		dataName = "Speed",
		inputDescription = "Value may range from 0.1 to 50.",
		revert = "mod speed fly 1",
		revertDesc = "Reset to fly speed 1",
		selfAble = false,
	}),
	[ACTION_TYPE.SpeedWalk] = serverAction("Walk Speed", {
		command = "mod speed walk @N@",
		description = "Modifies walking speed.",
		dataName = "Speed",
		inputDescription = "Value may range from 0.1 to 50.",
		revert = "mod speed walk 1",
		revertDesc = "Reset to walk speed 1",
		selfAble = false,
	}),
	[ACTION_TYPE.SpeedSwim] = serverAction("Swim Speed", {
		command = "mod speed swim @N@",
		description = "Modifies swimming speed.",
		dataName = "Speed",
		inputDescription = "Value may range from 0.1 to 50.",
		revert = "mod speed swim 1",
		revertDesc = "Reset to swim speed 1",
		selfAble = false,
	}),
	-- [ACTION_TYPE.DefaultEmote] = scriptAction("Default Emote", {
	-- 	["command"] = function(emoteID) DoEmote(string.upper(emoteID)); end,
	-- 	["description"] = "Any default emote.\n\rMust be a valid emote 'token', i.e., 'WAVE'\n\rGoogle 'Wowpedia DoEmote' for a full list - most match their /command, but some don't.",
	-- 	["dataName"] = "Emote Token",
	-- 	["inputDescription"] = "Usually just the text from the /command, i.e., /wave = wave.\n\rIf not working: Search Google for 'Wowpedia DoEmote', and go to the Wowpedia page, and find the table of tokens - some don't exactly match their command.",
	-- 	["revert"] = nil,
	-- }),

	[ACTION_TYPE.CheatOn] = serverAction("Enable Cheat", {
		command = "cheat @N@ on",
		description = "Enables the specified cheat.\n\rUse " .. Tooltip.genContrastText('.cheat') .. " to view available cheats.",
		dataName = "Cheat",
		inputDescription = "The cheat command to enable.\n\rCommon Cheats:\r" ..
			Tooltip.genContrastText({ "casttime", "cooldown", "god", "waterwalk", "duration", "slowcast" }) .. "\n\rUse " .. Tooltip.genContrastText(".cheat") .. " to view all available cheats.",
		example = "\r" .. Tooltip.genContrastText("cast") .. " will enable instant cast cheat\r" .. Tooltip.genContrastText("cool") .. " will enable no cooldowns cheat",
		revert = "cheat @N@ off",
		revertDesc = "Disable the cheat",
		selfAble = false,
	}),
	[ACTION_TYPE.CheatOff] = serverAction("Disable Cheat", {
		command = "cheat @N@ off",
		description = "Disables the specified cheat.\n\rUse " .. Tooltip.genContrastText('.cheat') .. " to view available cheats.",
		dataName = "Cheat",
		inputDescription = "The cheat command to disable.\n\rUse " .. Tooltip.genContrastText('.cheat') .. " to view available cheats.",
		example = "\r" .. Tooltip.genContrastText("cast") .. " will disable instant cast cheat\r" .. Tooltip.genContrastText("cool") .. " will disable no cooldowns cheat",
		revert = "cheat @N@ on",
		revertDesc = "Enable the cheat",
		selfAble = false,
	}),
	[ACTION_TYPE.PlayLocalSoundKit] = scriptAction("Local Sound (Kit)", {
		command = function(vars) if tonumber(vars) then PlaySound(vars) else PlaySound(SOUNDKIT[vars]) end end,
		description = "Play a sound locally (to yourself only), by SoundKit/Sound ID or SoundKit Constant.",
		dataName = "SoundKit ID / Name",
		inputDescription = "Accepts multiple IDs/Names, separated by commas, to play multiple sounds at once.",
		example = "Use " ..
			Tooltip.genContrastText("IG_BACKPACK_OPEN") ..
			" or SoundKit ID " ..
			Tooltip.genContrastText("862") .. " to play the Backpack Opened sound.\n\rUse " .. Tooltip.genContrastText('wowhead.com/sounds') .. " or similar to search for SoundKit/Sound IDs.",
		revert = nil,
		selfAble = false,
	}),
	[ACTION_TYPE.PlayLocalSoundFile] = scriptAction("Local Sound (File)", {
		command = function(vars) PlaySoundFile(vars) end,
		description = "Play a sound locally (to yourself only), by File ID.",
		dataName = "File ID",
		inputDescription = "Accepts multiple IDs, separated by commas, to equip multiple items at once.",
		example = "Use File ID " .. Tooltip.genContrastText("569593") .. " to play the Level-Up sound.\n\rUse " .. Tooltip.genContrastText('WoW.tools') .. " or similar to look for sound File IDs.",
		revert = nil,
		selfAble = false,
	}),
	[ACTION_TYPE.PlayPhaseSound] = serverAction("Phase Sound", {
		command = "phase playsound @N@",
		description = "Play a sound to the whole phase. Requires Phase Officer permissions.",
		dataName = "Sound ID",
		inputDescription = "The sound ID to play to the phase.",
		example = "Use Sound ID " ..
			Tooltip.genContrastText("11466") ..
			" to play Illidan's 'You are Not Prepared!' voice line to the entire phase.\n\rUse " .. Tooltip.genContrastText('wowhead.com/sounds') .. " to find Sound IDs to use.",
		revert = nil,
		selfAble = false,
	}),
	[ACTION_TYPE.MacroText] = scriptAction("Macro Script", {
		command = function(command) runMacroText(command); end,
		description =
		"Any line that can be processed in a macro (any slash commands & macro flags), or any valid Lua script.\n\rYou can use this for pretty much ANYTHING, technically, including custom short Lua scripts.\rDoes not accept comma separated multi-actions.",
		dataName = "/command or script",
		inputDescription =
		"Any /commands that can be processed in a macro-script, including emotes, addon commands, etc., or Lua scripts.\n\rYou can use any part of the ARC:API here as well. Use /arc for more info.",
		example = Tooltip.genContrastText("/emote begins to conjure up a fireball in their hand.") ..
			" to perform the emote.\n\r" .. Tooltip.genTooltipText("example", Tooltip.genContrastText("print(\"Example\")") .. " to print 'Example' in chat to yourself."),
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Command] = scriptAction("Server .Command", {
		command = cmdWithDotCheck,
		description = "Any other server command.\n\rType the full command you want in the input box.",
		dataName = "Full Command",
		inputDescription = "You can use any server command here, with or without the '.', and it will run after the delay.\n\rDoes NOT accept comma separated multi-actions.",
		example = "mod drunk 100",
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.MogitEquip] = scriptAction("Equip Mogit Set", {
		command = function(vars) SlashCmdList["MOGITE"](vars); end,
		description = "Equip a saved Mogit Wishlist set.\n\rMust specify the character name (profile) it's saved under first, then the set name.",
		dataName = "Profile & Set",
		inputDescription = "The Mogit Profile, and set name, just as if using the /moge chat command.",
		example = Tooltip.genContrastText(Constants.CHARACTER_NAME .. " Cool Armor Set") .. " to equip Cool Armor Set from this character.",
		revert = nil,
		dependency = "MogIt",
	}),
	[ACTION_TYPE.EquipSet] = scriptAction("Equip Set", {
		command = function(vars) C_EquipmentSet.UseEquipmentSet(C_EquipmentSet.GetEquipmentSetID(vars)) end,
		description = "Equip a saved set from Blizzard's Equipment Manager, by name.",
		dataName = "Set Name",
		inputDescription = "Set name from Equipment Manager (Blizzard's built in set manager).",
		revert = nil,
		revertAlternative = "a series of unequip actions",
	}),
	[ACTION_TYPE.ArcSpell] = scriptAction("Cast ArcSpell (Personal)", {
		command = function(commID)
			local spell = Vault.personal.findSpellByID(commID)
			if not spell then
				cprint("No spell with command '" .. commID .. "' found in your Personal Vault.")
				return
			end
			ns.Actions.Execute.executeSpell(spell.actions, nil, spell.fullName, spell)
		end,
		description = "Cast another Arcanum Spell from your Personal Vault.",
		dataName = "Spell Command",
		inputDescription = "The command ID (commID) used to cast the ArcSpell",
		example = "From " .. Tooltip.genContrastText('/sf MySpell') .. ", input just " .. Tooltip.genContrastText("MySpell") .. " as this input.",
		revert = nil,
	}),
	[ACTION_TYPE.ArcSpellPhase] = scriptAction("Cast ArcSpell (Phase)", {
		command = function(commID)
			local spell = Vault.phase.findSpellByID(commID)
			if not spell then
				cprint("No spell with command '" .. commID .. "' found in your current phase's Phase Vault.")
				return
			end
			ns.Actions.Execute.executeSpell(spell.actions, nil, spell.fullName, spell)
		end,
		description = "Cast another Arcanum Spell from your Personal Vault.",
		dataName = "Spell Command",
		inputDescription = "The command ID (commID) used to cast the ArcSpell",
		example = "From " .. Tooltip.genContrastText('/sf MySpell') .. ", input just " .. Tooltip.genContrastText("MySpell") .. " as this input.",
		revert = nil,
	}),
	[ACTION_TYPE.ArcSaveFromPhase] = scriptAction("Save ArcSpell (Phase)", {
		command = function(data)
			local commID, vocal = strsplit(",", data, 2)
			if vocal and (vocal == "false" or vocal == "nil" or vocal == "0") then vocal = nil end
			if vocal and vocal == "true" then vocal = true end
			ARC.PHASE:SAVE(commID, vocal)
		end,
		description = "Save an Arcanum Spell from the Phase Vault, with an optional message to let them know they learned a new ArcSpell!",
		dataName = "Spell Command, [send message (true/false)]",
		inputDescription = "Syntax: The command ID (commID) used to cast the ArcSpell, [print a 'New Spell Learned' message (true/false)]",
		example = "My Cool Spell, true",
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ArcCastbar] = scriptAction("Show Castbar", {
		command = function(data)
			local length, text, iconPath, channeled, showIcon, showShield = strsplit(",", data, 6)
			if length then length = strtrim(length) end
			if text then text = strtrim(text) end
			if iconPath then iconPath = { ["icon"] = strtrim(iconPath) } end
			if channeled then channeled = toBoolean(strtrim(channeled)) end
			if showIcon then showIcon = toBoolean(strtrim(showIcon)) end
			if showShield then showShield = toBoolean(strtrim(showShield)) end
			ns.UI.Castbar.showCastBar(length, text, iconPath, channeled, showIcon, showShield)
		end,
		description =
		"Show a custom Arcanum Castbar with your own settings & duration.\n\rSyntax: duration, [title, [iconPath/FileID, [channeled (true/false), [showIcon (true/false), [showShield (true/false)]]]]]\n\rDuration is the only required input.",
		dataName = "Castbar Settings",
		inputDescription = "Syntax: duration, [title, [iconPath/FileID, [channeled (true/false), [showIcon (true/false), [showShield (true/false)]]]]]\n\rDuration is the only required input.",
		example = Tooltip.genContrastText("5, Cool Spell!, 1, true, true, false") ..
			" will show a Castbar for 5 seconds, named 'Cool Spell!', with a gem icon, but no shield frame.\n\r" ..
			Tooltip.genTooltipText("lpurple", "Icon ID's " .. Tooltip.genContrastText("1 - " .. ns.UI.Icons.getNumCustomIcons()) .. " can be used for Arcanum's custom Icons."),
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ArcStopSpells] = scriptAction("Stop ArcSpells", {
		command = function() ns.Actions.Execute.stopRunningActions() end,
		description =
		"Stops all currently running ArcSpells - including this spell if called on a delay.\n\rUse it as the first action with a delay of 0 if you want to cancel any other running ArcSpells before you cast this spell.",
		revert = nil,
	}),
	[ACTION_TYPE.ArcStopThisSpell] = scriptAction("Stop This ArcSpell (If)", {
		command = function(script)
			if script then
				if not script:match("return") then
					script = "return " .. script
				end
				return runMacroText(script)
			else
				return true
			end
		end,
		description =
		"Stops this spell's remaining actions only. Will always stop this spell's actions no matter if used on a delay or not. You may optionally provide a script as the input, and the spell will only be stopped if that script returns true.",
		dataName = "Script",
		inputDescription = "A Lua Script to test if the spell should be stopped.",
		example = Tooltip.genContrastText("GetItemCount(143861) == 0") .. " to only stop if they do not have item 143861 (Tower Key) in their inventory.",
		doNotDelimit = true,
		revert = nil,
	}),
	[ACTION_TYPE.ArcStopSpellByName] = scriptAction("Stop Other ArcSpell", {
		command = function(spellCommID) ns.Actions.Execute.cancelSpellByCommID(spellCommID) end,
		description =
		"Stops another ArcSpell that's currently running, by commID.\n\rUse ARC:STOP(commID) in a script if you wish to only stop the spell if certain conditions are met.",
		dataName = "ArcSpell CommID",
		inputDescription = "The commID of the ArcSpell you wish to stop all remaining actions for.",
		revert = nil,
	}),
	[ACTION_TYPE.ARCSet] = scriptAction("Set My Variable", {
		command = function(data)
			local var, val = strsplit("|", data, 2);
			var = strtrim(var, " \t\r\n\124");
			val = strtrim(val, " \t\r\n\124");
			ARC:SET(var, val);
		end,
		description =
		"Set a Personal ARCVAR to a specific value.\n\rMy ARCVARs can be accessed via the table ARC.VAR, or via ARC:GET() in a macro script.\n\rPersonal ArcVars do not save between sessions.",
		dataName = "VarName | Value",
		inputDescription = "Provide the variable name & the value to set it as, separated by a | character. Inputs are trimmed of leading & trailing spaces.",
		revert = nil,
		revertAlternative = "another Set Variable action",
		example = "KeysCollected | 3",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ARCTog] = scriptAction("Toggle My Variable", {
		command = function(var) ARC:TOG(var) end,
		description =
		"Toggle a Personal ARCVAR, like a light switch.\n\rPersonal ARCVARs can be accessed via the table ARC.VAR, or via ARC:GET() in a macro script.\n\rPersonal ArcVars do not save between sessions.",
		dataName = "Variable Name",
		inputDescription = "The variable name to toggle.",
		revert = function(var) ARC:TOG(var) end,
		revertDesc = "Toggles the ARCVAR again.",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ARCPhaseSet] = scriptAction("Set Phase Variable", {
		command = function(data)
			local var, val = strsplit("|", data, 2);
			var = strtrim(var, " \t\r\n\124");
			val = strtrim(val, " \t\r\n\124");
			ARC.PHASE:SET(var, val);
		end,
		description =
		"Set a Phase ARCVAR to a specific value.\n\rPhase ARCVARs can be accessed via the table ARC.PHASEVAR, or via ARC.PHASE:GET() in a macro script.\n\rPhase ArcVars are saved between sessions, but should not be considered secure as a user can manipulate them as well.",
		dataName = "VarName | Value",
		inputDescription = "Provide the variable name & the value to set it as, separated by a | character.",
		revert = nil,
		revertAlternative = "another Phase Set Variable action",
		example = "KeysCollected | 3",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ARCPhaseTog] = scriptAction("Toggle Phase Variable", {
		command = function(var) ARC.PHASE:TOG(var) end,
		description =
		"Toggle a Phase ARCVAR, like a light switch.\n\rPhase ARCVARs can be accessed via the table ARC.PHASEVAR, or via ARC.PHASE:GET() in a macro script.\n\rPhase ArcVars are saved between sessions, but should not be considered secure as a user can manipulate them as well.",
		dataName = "Variable Name",
		inputDescription = "The variable name to toggle.",
		revert = function(var) ARC.PHASE:TOG(var) end,
		revertDesc = "Toggles the Phase ARCVAR again.",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ARCCopy] = scriptAction("Copy Text/URL", {
		command = function(text) ARC:COPY(text) end,
		description = "Open a dialog box to copy the given text (i.e., a URL).",
		dataName = "Text / URL",
		inputDescription = "The text / link / URL to copy.",
		example = "https://discord.gg/C8DZ7AxxcG",
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.PrintMsg] = scriptAction("Chatbox Message", {
		command = print,
		description = "Prints a message in the chatbox.",
		dataName = "Text",
		inputDescription = "The text to print into the chatbox.",
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.RaidMsg] = scriptAction("Raid Message", {
		command = function(msg)
			RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
		end,
		description = "Shows a custom Raid Warning message, only to the person casting the spell.",
		dataName = "Text",
		inputDescription = "The text to show as the raid warning.",
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ErrorMsg] = scriptAction("UI Message", {
		command = function(msg)
			local success, text, r, g, b, voiceID, soundKitID = pcall(function(val) return unpack(ns.Utils.Data.parseStringToArgs(val)) end, msg)
			if not success then
				ns.Logging.eprint("UI Message Action Failed: Error Parsing String to Args (Are you missing a \" ?)")
				ns.Logging.dprint(text)
				return
			end
			ns.Logging.uiErrorMessage(text, r, g, b, voiceID, soundKitID)
		end,
		description = "Shows a custom UI 'Error' message, only to the person casting the spell.\n\rThis is the same style message as 'You cannot do that.' etc.",
		dataName = "Text, R, G, B, voiceID, soundKitID",
		inputDescription =
		"The text to show as the UI Error Message (wrap in quotes \" \" if it contains a comma), along with any RGB (0-1 range). You may provide a voiceID to play also, or put it as 'nil' and then add a soundKitID to play a sound effect.",
		revert = nil,
		example = [["Look, a message!", 1, 0, 0, 12]],
		doNotDelimit = true,
	}),
	[ACTION_TYPE.HideMostUI] = scriptAction("Hide UI", {
		command = function() Scripts.ui.ToggleUIShown(false) end,
		description = "Hides your UI (just like ALT+Z), but leaves Raid Warning & UI Errors shown so you can see messages. UI can always be re-enabled/shown manually by hitting Escape.",
		revertDesc = "Unhides/Re-Shows the UI.",
		revert = function() Scripts.ui.ToggleUIShown(true) end,
	}),
	[ACTION_TYPE.UnhideMostUI] = scriptAction("Unhide/Show UI", {
		command = function() Scripts.ui.ToggleUIShown(true) end,
		description = "Unhides/Shows the UI (just like ALT+Z, a 2nd time).",
		revert = nil,
	}),
	[ACTION_TYPE.FadeOutMainUI] = scriptAction("Fade Out UI", {
		command = function(vars) UIFrameFadeOut(UIParent, tonumber(vars), UIParent:GetAlpha(), 0) end,
		description = "Fades out the main UI over the time given, until it's fully hidden.",
		dataName = "Seconds",
		inputDescription = "The number of seconds it takes for the UI to fade out.",

		revertDesc = "Fades the UI back in, over the same time. Revert timer should likely be longer than your fade out time input, otherwise it will not fully fade out before fading back in.",
		revert = function(vars) UIFrameFadeIn(UIParent, tonumber(vars), UIParent:GetAlpha(), 1) end,
	}),
	[ACTION_TYPE.FadeInMainUI] = scriptAction("Fade In UI", {
		command = function(vars) UIFrameFadeIn(UIParent, tonumber(vars), UIParent:GetAlpha(), 1) end,
		description = "Fades in the main UI over the time given, until it's fully visible.",
		dataName = "Seconds",
		inputDescription = "The number of seconds it takes for the UI to fade in.",

		revertDesc = "Fades the UI out.",
		revert = function(vars) UIFrameFadeOut(UIParent, tonumber(vars), UIParent:GetAlpha(), 0) end,
	}),
	[ACTION_TYPE.BoxMsg] = scriptAction("Popup Box Message", {
		command = function(msg)
			ns.UI.Popups.showCustomGenericConfirmation({
				text = msg,
				acceptText = OKAY,
				cancelText = false,
			})
		end,
		description = "Shows a pop-up box with a custom message.",
		dataName = "Text",
		inputDescription = "The text to show in the popup box.",
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.BoxPromptCommand] = scriptAction("Command Input Prompt", {
		command = function(msg)
			local description, okayText, cancText, command = strsplit(",", msg, 4)
			if not cancText and not command then command = okayText end
			if not okayText or okayText == "" then okayText = OKAY end
			if not cancText or cancText == "" then cancText = CANCEL end
			command = strtrim(command)
			ns.UI.Popups.showCustomGenericInputBox({
				callback = function(input)
					cmdWithDotCheck((command):gsub("@", input))
				end,
				text = description,
				acceptText = strtrim(okayText),
				cancelText = strtrim(cancText),
			})
		end,
		description = "Prompts the user with an input box, then adds that input to the command given.",
		dataName = "Text, OK, Cancel, Command",
		inputDescription = "The text to show in the prompt message, Okay Button Text, Cancel Button Text, and the command to use; separated by commas.\nUse the " ..
			Tooltip.genContrastText("@") .. " symbol as the placeholder to be replaced by the user input.\n\rOkay and Cancel can be left blank and will default as 'Okay' and 'Cancel'.",
		example = 'What item do you want to add?,,, additem @',
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.BoxPromptScript] = scriptAction("Script Input Prompt", {
		command = function(msg)
			local description, okayText, cancText, scriptString = strsplit(",", msg, 4)
			if not cancText and not scriptString then scriptString = okayText end
			if not okayText or okayText == "" then okayText = OKAY end
			if not cancText or cancText == "" then cancText = CANCEL end
			scriptString = strtrim(scriptString):gsub("@input", "userInput")
			local scriptTest, errorMessageTest = loadstring(scriptString)
			if scriptTest and not errorMessageTest then
				ns.UI.Popups.showCustomGenericInputBox({
					callback = function(userInput)
						local script, errorMessage = loadstring([[
							return function(userInput)
								]] .. (scriptString) .. [[
							end
						]])
						if script and not errorMessage then
							script()(userInput)
						else
							ns.Logging.eprint("Error with Input while loading Script (Script Input Prompt), please check your input or script. Error:")
							print(errorMessage)
						end
					end,
					text = description,
					acceptText = strtrim(okayText),
					cancelText = strtrim(cancText),
				})
			else
				ns.Logging.eprint("Error Loading Script in ArcSpell Action (Script Input Prompt), please check your script. Error:")
				print(errorMessageTest)
			end
		end,
		description = "Prompts the user with an input box, then adds that input to the script given.",
		dataName = "Text, OK, Cancel, Script",
		inputDescription = "The text to show in the prompt message, Okay Button Text, Cancel Button Text, and the script to use; separated by a comma.\nUse the " ..
			Tooltip.genContrastText("@input") .. " tag as the placeholder to be replaced by the user input.\n\rOkay and Cancel can be left blank and will default as 'Okay' and 'Cancel'.",
		example = [[What's 2+2?,,, if @input == "4" then print("Correct!") else print("Nope!") end]],
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.BoxPromptCommandNoInput] = scriptAction("Command Run Prompt", {
		command = function(msg)
			local description, okayText, cancText, command = strsplit(",", msg, 4)
			if not cancText and not command then command = okayText end
			if not okayText or okayText == "" then okayText = OKAY end
			if not cancText or cancText == "" then cancText = CANCEL end
			command = strtrim(command)
			ns.UI.Popups.showCustomGenericConfirmation({
				callback = function()
					cmdWithDotCheck(command)
				end,
				text = description,
				acceptText = strtrim(okayText),
				cancelText = strtrim(cancText),
			})
		end,
		description = "Prompts the user with a pop-up confirmation dialogue to run the given command.",
		dataName = "Text, OK, Cancel, Command",
		inputDescription =
		"The text to show in the prompt message, Okay Button Text, Cancel Button Text, and the command to use; separated by commas.\n\rOkay and Cancel can be left blank and will default as 'Okay' and 'Cancel'.",
		example = 'Do you wish to teleport?, Sure, No thanks!, phase tele CoolArea',
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.BoxPromptScriptNoInput] = scriptAction("Script Run Prompt", {
		command = function(msg)
			local description, okayText, cancText, scriptString = strsplit(",", msg, 4)
			if not cancText and not scriptString then scriptString = okayText end
			if not okayText or okayText == "" then okayText = OKAY end
			if not cancText or cancText == "" then cancText = CANCEL end
			scriptString = strtrim(scriptString)
			local script, errorMessage = loadstring(scriptString)
			if script and not errorMessage then
				ns.UI.Popups.showCustomGenericConfirmation({
					callback = script,
					text = description,
					acceptText = strtrim(okayText),
					cancelText = strtrim(cancText),
				})
			else
				ns.Logging.eprint("Error Loading Script in ArcSpell Action (Run Script Prompt), please check your script. Error:")
				print(errorMessage)
			end
		end,
		description = "Prompts the user with a pop-up confirmation dialog to run the script.",
		dataName = "Text, OK, Cancel, Script",
		inputDescription =
		"The text to show in the prompt message, Okay Button Text, Cancel Button Text, and the script to use; separated by commas.\n\rOkay and Cancel can be left blank and will default as 'Okay' and 'Cancel'.",
		example = [[Do you want to know the answer?, Yes, No, print("42! But what is the question..?")]],
		revert = nil,
		doNotDelimit = true,
	}),

	-- Location Actions
	[ACTION_TYPE.SaveARCLocation] = scriptAction("Save Location (ARC)", {
		command = function(key)
			ARC.LOCATIONS:SAVE(key)
		end,
		description =
		"Saves the current location when cast to the ARC.LOCATIONS Storage. You can recall to these locations later by using a revert, the ARC.LOCATIONS API, or using a 'Recall to Location (ARC)' action.).\n\rLocations are NOT preserved thru reloads or relogs.",
		dataName = "Location Key",
		inputDescription = "The Key (Name) you want to save it as. Keys are unique, so saving another with the same Key/Name will overwrite it.",
		revert = function(key)
			ARC.LOCATIONS:GOTO(key)
		end,
		revertDesc = "Recalls to this saved location at the end of the revert time.",
	}),
	[ACTION_TYPE.GotoARCLocation] = scriptAction("Recall to Location (ARC)", {
		command = function(key)
			ARC.LOCATIONS:GOTO(key)
		end,
		description = "Recalls to a previously saved ARC Location.",
		dataName = "Location Key",
		inputDescription = "The Key (Name) you want to recall to.",
		revert = nil,
	}),
	[ACTION_TYPE.WorldportCommand] = serverAction("Worldport", {
		command = "worldport @N@",
		description = "Worldport to the location data given.",
		dataName = "#x #y [#z [#mapid [#orientation]]]",
		inputDescription = "The location data you would like to world port to. This matches the same format as the command, '.worldport'.",
		revert = nil,
	}),
	[ACTION_TYPE.TeleCommand] = serverAction("Teleport", {
		command = "tele @N@",
		description = "Teleport to a given location.\n\rCommand: " .. Tooltip.genContrastText(".tele"),
		dataName = "Location Name",
		inputDescription = "The location name you would like to tele to. Use " .. Tooltip.genContrastText(".lookup tele") .. " to find teleport location names.",
		revert = nil,
	}),
	[ACTION_TYPE.PhaseTeleCommand] = serverAction("Phase Tele", {
		command = "phase tele @N@",
		description = "Teleport to a given phase location.\n\rCommand: " .. Tooltip.genContrastText(".phase tele"),
		dataName = "Phase Location",
		inputDescription = "The phase location name you would like to tele to. Use " .. Tooltip.genContrastText(".phase tele list") .. " to find phase tele location names.",
		revert = nil,
	}),


	-- QC Actions
	[ACTION_TYPE.QCBookToggle] = scriptAction("Toggle Book", {
		command = function(bookName)
			ns.UI.Quickcast.Book.toggleBookByName(bookName)
		end,
		description = "Toggle a Quickcast Book from being displayed on this character.",
		dataName = "Book Name",
		inputDescription = "The name of the Quickcast Book",
		revert = function(bookName)
			ns.UI.Quickcast.Book.toggleBookByName(bookName)
		end,
		revertDesc = "Re-Toggles the Quickcast Book on this character. Why tho?",
	}),
	[ACTION_TYPE.QCBookStyle] = scriptAction("Change Book Style", {
		command = function(vars)
			local bookName, pageNumber = AceConsole:GetArgs(vars, 2)
			ns.UI.Quickcast.Book.changeBookStyle(bookName, pageNumber)
		end,
		description = "Toggle a Quickcast Book from being displayed on this character.",
		dataName = "Book Name",
		inputDescription = "The name of the Quickcast Book & style name. If either have spaces, enclose them in quotations.",
		example = '"Quickcast Book 1" Arcfox',
		revert = nil,
		revertAlternative = "another Change Style action"
	}),
	[ACTION_TYPE.QCBookSwitchPage] = scriptAction("Switch Page", {
		command = function(vars)
			local bookName, pageNumber = AceConsole:GetArgs(vars, 2)
			ns.UI.Quickcast.Book.setPageInBook(bookName, pageNumber)
		end,
		description = "Toggle a Quickcast Book from being displayed on this character.",
		dataName = "BookName PageNumber",
		inputDescription = "The name of the Quickcast Book & the page number. If your book name has spaces, enclose it in quotations.",
		example = '"Quickcast Book 1" 2',
		revert = nil,
		revertAlternative = "another Switch Page action"
	}),
	[ACTION_TYPE.RotateCameraLeftStart] = scriptAction("Rotate Cam Left", {
		command = function(speed)
			SaveView(5)
			MoveViewLeftStart(speed / tonumber(GetCVar("cameraYawMoveSpeed")))
		end,
		description = "Rotate the camera left, in degrees per second. " .. Tooltip.genTooltipText("warning", "Must be reverted to properly stop rotation!"),
		dataName = "Degrees per Second",
		inputDescription = "The number of degrees, per second, to rotate.",
		example = Tooltip.genContrastText("45") .. " to rotate 45 degrees to the left each second.",
		revert = function()
			MoveViewLeftStop()
			SetView(5)
		end,
		revertDesc = "Stops the camera rotation & returns the camera to the players original camera view.",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.RotateCameraRightStart] = scriptAction("Rotate Cam Right", {
		command = function(speed)
			SaveView(5)
			MoveViewRightStart(speed / tonumber(GetCVar("cameraYawMoveSpeed")))
		end,
		description = "Rotate the camera right, in degrees per second. " .. Tooltip.genTooltipText("warning", "Must be reverted to properly stop rotation!"),
		dataName = "Degrees per Second",
		inputDescription = "The number of degrees, per second, to rotate.",
		example = Tooltip.genContrastText("45") .. " to rotate 45 degrees to the right each second.",
		revert = function()
			MoveViewRightStop()
			SetView(5)
		end,
		revertDesc = "Stops the camera rotation & returns the camera to the players original camera view.",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.RotateCameraUpStart] = scriptAction("Rotate Cam Up", {
		command = function(speed)
			SaveView(5)
			MoveViewUpStart(speed / tonumber(GetCVar("cameraPitchMoveSpeed")))
		end,
		description = "Rotate the camera up, in degrees per second. " .. Tooltip.genTooltipText("warning", "Must be reverted to properly stop rotation!"),
		dataName = "Degrees per Second",
		inputDescription = "The number of degrees, per second, to rotate.",
		example = Tooltip.genContrastText("45") .. " to rotate 45 degrees up each second.",
		revert = function()
			MoveViewUpStop()
			SetView(5)
		end,
		revertDesc = "Stops the camera rotation & returns the camera to the players original camera view.",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.RotateCameraDownStart] = scriptAction("Rotate Cam Down", {
		command = function(speed)
			SaveView(5)
			MoveViewDownStart(speed / tonumber(GetCVar("cameraPitchMoveSpeed")))
		end,
		description = "Rotate the camera down, in degrees per second. " .. Tooltip.genTooltipText("warning", "Must be reverted to properly stop rotation!"),
		dataName = "Degrees per Second",
		inputDescription = "The number of degrees, per second, to rotate.",
		example = Tooltip.genContrastText("45") .. " to rotate 45 degrees down each second.",
		revert = function()
			MoveViewDownStop()
			SetView(5)
		end,
		revertDesc = "Stops the camera rotation & returns the camera to the players original camera view.",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ZoomCameraOutStart] = scriptAction("Zoom Cam Out", {
		command = function(speed)
			--SaveView(5)
			MoveViewOutStart(speed / tonumber(GetCVar("cameraZoomSpeed")))
		end,
		description = "Zoom the camera out by the given amount per second. " .. Tooltip.genTooltipText("warning", "Must be reverted to properly stop movement!"),
		dataName = "Zoom Speed",
		inputDescription = "The speed at which to zoom (roughly yards per second).",
		example = Tooltip.genContrastText("5") .. " to zoom the camera out at 5 yards per second.",
		revert = function()
			MoveViewOutStop()
			--SetView(5)
		end,
		revertDesc = "Stops the camera movement, but does NOT return the camera to the players original camera view. Use a separate Save & Load Zoom action to restore Zoom levels after if needed.",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ZoomCameraInStart] = scriptAction("Zoom Cam In", {
		command = function(speed)
			--SaveView(5)
			MoveViewInStart(speed / tonumber(GetCVar("cameraZoomSpeed")))
		end,
		description = "Zoom the camera in by the given amount per second. " .. Tooltip.genTooltipText("warning", "Must be reverted to properly stop movement!"),
		dataName = "Zoom Speed",
		inputDescription = "The speed at which to zoom (roughly yards per second).",
		example = Tooltip.genContrastText("5") .. " to zoom the camera in at 5 yards per second.",
		revert = function()
			MoveViewInStop()
			--SetView(5)
		end,
		revertDesc = "Stops the camera movement, but does NOT return the camera to the players original camera view. Use a separate Save & Load Zoom action to restore Zoom levels after if needed.",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ZoomCameraSet] = scriptAction("Set Cam Zoom", {
		command = Scripts.camera.SetZoom,
		description = "Zoom the camera to a specific zoom amount. ",
		dataName = "Zoom Distance",
		inputDescription = "The Zoom amount you wish to set the camera to.",
		example = Tooltip.genContrastText("0") .. " to set the camera zoom to 0 (First Person).",
		revert = Scripts.camera.RevertZoom,
		revertDesc = "Returns the Camera Zoom level to the previous level before this action.",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ZoomCameraOutBy] = scriptAction("Zoom Cam Out By..", {
		command = CameraZoomOut,
		description = "Zoom the camera out by an exact distance. ",
		dataName = "Zoom Speed",
		inputDescription = "The Zoom amount you wish to zoom out by.",
		example = Tooltip.genContrastText("3") .. " to zoom out by 3 yards.",
		revert = CameraZoomIn,
		revertDesc = "Zooms the camera back in by the same amount.",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ZoomCameraInBy] = scriptAction("Zoom Cam In By..", {
		command = CameraZoomIn,
		description = "Zoom the camera in by an exact distance. ",
		dataName = "Zoom Speed",
		inputDescription = "The Zoom amount you wish to zoom in by.",
		example = Tooltip.genContrastText("3") .. " to zoom in by 3 yards.",
		revert = CameraZoomOut,
		revertDesc = "Zooms the camera back out by the same amount.",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ZoomCameraSaveCurrent] = scriptAction("Save Current Zoom", {
		command = Scripts.camera.SaveZoom,
		description = "Saves the current Zoom Level. Can be used with a Restore Zoom action to return to the last saved Zoom level.",
		dataName = nil,
		revert = Scripts.camera.RestoreSavedZoom,
		revertDesc = "Restores the saved Zoom level. You can use this to simplify instead of needing a separate Restore Zoom action.",
	}),
	[ACTION_TYPE.ZoomCameraLoadSaved] = scriptAction("Restore Zoom", {
		command = Scripts.camera.RestoreSavedZoom,
		description = "Saves the current Zoom Level. Can be used with a Restore Zoom action to return to the last saved Zoom level.",
		dataName = nil,
		revert = nil,
	}),
	[ACTION_TYPE.MouselookModeStart] = scriptAction("Enter Mouselook Mode", {
		command = Scripts.camera.EnableMouselook,
		description =
			"Enters mouse look mode; alters the character's movement/facing direction to where your mouse is aiming.\n\rInput: The Key to Exit Mouselook Mode. Exit Keys can accept modifiers (alt, shift, and ctrl) by adding them before the key, separated by a dash (" ..
			Tooltip.genTooltipText("example", "ALT-SHIFT-Z") .. ").\n\r" .. Tooltip.genContrastText("You must provide an Exit Key!"),
		dataName = "Exit Key",
		inputDescription =
		"The Key-Binding to use to Exit Mouselook Mode. Exit Key binds are also cleared as soon as they are ran, meaning you can use it to override a key, and then that key will return to original behavior after done.\n\rEx: Using Z will override Z for Sheathe while in Mouselook mode, but once Mouselook mode is exited, Z will return to Sheathe control.",
		example = Tooltip.genContrastText("Z") .. " to set it so that pressing Z cancels Mouselook mode.",
		revert = Scripts.camera.DisableMouselook,
		revertDesc = "Exits Mouselook Mode & Clears the Exit Binding.",
		doNotDelimit = true,
	}),

	[ACTION_TYPE.RotateCameraStop] = scriptAction("Stop Cam Movement", {
		command = function()
			MoveViewRightStop()
			MoveViewLeftStop()
			MoveViewUpStop()
			MoveViewDownStop()
			MoveViewInStop()
			MoveViewOutStop()
			MouselookStop()
		end,
		description = "Stops Left & Right Camera Rotations. " ..
			Tooltip.genTooltipText("warning", "You should really use a revert delay on the original rotate action instead of this! This can get skipped/cancelled and leave the camera in rotate hell!"),
		revert = nil,
		revertAlternative = "another rotate camera action",
	}),
	[ACTION_TYPE.SpawnBlueprint] = serverAction("Spawn Blueprint", {
		command = "gob blue spawn @N@",
		description = "Spawns a Gob Blueprint at your position.",
		dataName = "Blueprint ID",
		inputDescription = "The ID of the Blueprint to spawn.",
		example = Tooltip.genContrastText("144997") .. " to spawn a Teacup Blueprint.",
		revert = "go group del",
		revertDesc = "Deletes the currently selected gob group. " ..
			Tooltip.genTooltipText("warning", "Do not select another Gob Group between this action & it's revert or else it will delete that other gob group instead of the spawned blueprint!"),
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ArcTrigCooldown] = scriptAction("Trigger ArcSpell Cooldown", {
		command = function(vars)
			local commID, cooldownTime, isPhase = AceConsole:GetArgs(vars, 3)
			if isPhase then isPhase = toBoolean(isPhase) end
			ns.Actions.Cooldowns.addSpellCooldown(commID, cooldownTime, (isPhase and C_Epsilon.GetPhaseId() or nil))
		end,
		description = "Triggers a Cooldown on another ArcSpell. Useful for Sparks that are just pre-checks to then cast another ArcSpell.",
		dataName = "$commID #length &phase",
		inputDescription =
			"#commID = The commID of the spell to put on cooldown\n\r#length = How long (in seconds) for the cooldown\n\r&phase = " ..
			Tooltip.genContrastText("true") .. " if it should be a Phase Spell, leave blank for Personal Spell.\n\rIf your CommID has spaces, enclose it in quotations.",
		example = Tooltip.genContrastText('"Watergun Blast" 2 true') .. " to put the Phase ArcSpell 'Watergun Blast' on a 2 second cooldown.",
		revert = nil,
		revertAlternative = true,
		doNotDelimit = true,
	}),

	-- Kinesis Integrations
	[ACTION_TYPE.Kinesis_FlyEnable] = scriptAction("Toggle Flight Controls", {
		command = function(vars)
			if not Kinesis then return end
			revertHoldingVars[ACTION_TYPE.Kinesis_FlyEnable] = Kinesis.Flight.GetFlightControlsEnabled()
			Kinesis.Flight.SetFlightControlsEnabled(onToBoolean(vars))
		end,
		description = "Toggle Kinesis' 'Creative Mode' Flight Controls On/Off",
		dataName = "on/off",
		inputDescription = "On or Off to set the Flight Controls ('Creative Mode') toggle to that.",
		example = Tooltip.genContrastText("On") .. " to turn on Creative Mode Flight Controls.",
		revert = function(vars)
			if not Kinesis then return end
			if onToBoolean(vars) then
				Kinesis.Flight.SetFlightControlsEnabled(not (onToBoolean(vars)))
			else
				Kinesis.Flight.SetFlightControlsEnabled(revertHoldingVars[ACTION_TYPE.Kinesis_FlyEnable])
			end
		end,
		revertDesc =
		"Resets the Flight Controls toggle back to what it was set to before. Note that this may not directly revert your action. For example, if the Flight Controls is toggled off, and you run this action to turn if off, with a revert, it will remain off.",
		dependency = "Kinesis",
		softDependency = true,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_EFDEnable] = scriptAction("Toggle Ext. Flight Detection", {
		command = function(vars)
			if not Kinesis then return end
			revertHoldingVars[ACTION_TYPE.Kinesis_EFDEnable] = Kinesis.Flight.GetEFDEnabled()
			Kinesis.Flight.SetEFDEnabled(onToBoolean(vars))
		end,
		description = "Toggle Kinesis' Extended Flight Detection On/Off",
		dataName = "on/off",
		inputDescription = "On or Off to set the Extended Flight Detection toggle to that.",
		example = Tooltip.genContrastText("Off") .. " to turn on Kinesis Extended Flight Detection.",
		revert = function(vars)
			if not Kinesis then return end
			if onToBoolean(vars) then
				Kinesis.Flight.SetEFDEnabled(not (onToBoolean(vars)))
			else
				Kinesis.Flight.SetEFDEnabled(revertHoldingVars[ACTION_TYPE.Kinesis_EFDEnable])
			end
		end,
		revertDesc =
		"Resets the Extended Flight Detection toggle back to what it was set to before. Note that this may not directly revert your action. For example, if the Extended Flight Detection is toggled off, and you run this action to turn if off, with a revert, it will remain off.",
		dependency = "Kinesis",
		softDependency = true,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_LandJumpSet] = scriptAction("Jump-To-Land", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Flight.SetJumpToLand(tonumber(vars))
		end,
		description = "Set Kinesis' Jump-To-Land Feature as Double Jump, Triple Jump, or Disabled.",
		dataName = "Number of Jumps",
		inputDescription = Tooltip.genContrastText("0, 2, or 3") .. "\n\rThe number of jumps (2 or 3) needed to disable flight (AKA: Land).\rUse 0 to disable.",
		example = Tooltip.genContrastText("2") .. " to set Double Jump to disable flight.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_AutoLandDelay] = scriptAction("Auto-Land Delay", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Flight.SetLandingDelay(tonumber(vars))
		end,
		description = "Set Kinesis' Auto-Land Delay Timer (in seconds). This is how long you are on the ground before automatically disabling flight. Set to 0 to disable.",
		dataName = "Seconds",
		inputDescription = "The number of seconds you are on the ground before disabling flight mode.\n\rSet to 0 to disable.",
		example = Tooltip.genContrastText("2") .. " to disable flight if you have been on the ground for 2 seconds.",
		revert = nil,
		dependency = "Kinesis",
	}),

	-- Kinesis Flight Spells
	[ACTION_TYPE.Kinesis_ToggleFlightSpells] = scriptAction("Enable Flight Spells", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Flight.Spells.SetSpellsEnabled(onToBoolean(vars))
		end,
		description =
		"Enable or Disable triggering standard spells when you start Flying. Standard spells are applied using aura; if you need more control, consider using an ArcSpell.",
		dataName = "On/Off",
		inputDescription = "The Move Type (walk/fly/swim), followed by on/off to enable or disable that Move Type.",
		example = Tooltip.genContrastText("on") .. " to enable Flight Spells when triggering flying.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),

	[ACTION_TYPE.Kinesis_FlightArcEnabled] = scriptAction("Tog. Flight ArcSpells", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Flight.Spells.SetSpellArcanumEnabled(onToBoolean(vars))
		end,
		description = "Enable or Disable triggering ArcSpells when you start & stop Flying.",
		dataName = "On/Off",
		inputDescription = "On to enable triggering ArcSpells, Off to disable.",
		example = Tooltip.genContrastText("on") .. " to enable Flight triggering Arc Spells.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_FlightArcStart] = scriptAction("Flight Start ArcSpell", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Flight.Spells.SetSpellArcanumStart(vars)
		end,
		description = "Set the ArcSpell that will be cast when you start Flying.",
		dataName = "commID",
		inputDescription = "The CommID of the spell to cast when you start flying. Must be an ArcSpell in your Personal Vault.",
		example = Tooltip.genContrastText("myFlightModeArcSpell") .. " to set that Arcanum Spell to be cast when you start flying.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_FlightArcStop] = scriptAction("Flight Stop ArcSpell", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Flight.Spells.SetSpellArcanumStop(vars)
		end,
		description = "Set the ArcSpell that will be cast when you stop Flying.",
		dataName = "commID",
		inputDescription = "The CommID of the spell to cast when you stop flying. Must be an ArcSpell in your Personal Vault.",
		example = Tooltip.genContrastText("stopFlyingArcSpell") .. " to set that Arcanum Spell to be cast when you stop flying.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),

	[ACTION_TYPE.Kinesis_FlightSetSpells] = scriptAction("Set Flight Spells", {
		command = function(vars)
			if not Kinesis then return end
			local spellLists = Kinesis.Flight.Spells.StandardSpellsGetSets()
			local backupName = "ArcBackup_" .. UnitName("player")
			if spellLists[backupName] then
				local index = 1
				while (spellLists[backupName .. tostring(index)]) do
					index = index + 1
					if index > maxBackupsPerChar - 1 then
						index = 1
						break
					end
				end
				Kinesis.Flight.Spells.StandardSpellsSaveSet(backupName .. tostring(index), true, select(2, Kinesis.Flight.Spells.GetCurrentSpellList()))
			else
				Kinesis.Flight.Spells.StandardSpellsSaveSet(backupName, true, select(2, Kinesis.Flight.Spells.GetCurrentSpellList()))
			end
			Kinesis.Flight.Spells.StandardSpellsSetSpells(vars)
		end,
		description =
		"Set your Kinesis Flight Spells to the spells you specify.\n\rYour previous set of spells will be saved in a temporary backup Spell Set in the /kinesis menu.",
		dataName = "Spell ID(s)",
		inputDescription = "Spell IDs, separated by a command if you want multiple.",
		example = Tooltip.genContrastText("123, 456, 789") .. " to set your Flight Spells as 123, 456, 789.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_FlightLoadSpellSet] = scriptAction("Load Flight Spell Set", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Flight.Spells.StandardSpellsLoadSet(vars)
		end,
		description = "Load a Flight Spell Set by name.",
		dataName = "Spell Set Name",
		inputDescription = "The name of the Flight Spell Set to set as your current spells. Case sensitive (because MindScape was too lazy to fix it).",
		example = Tooltip.genContrastText("My Awesome Flight spells!") .. " to set that Flight Spell Set as your current Flight Spells.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),


	-- Kinesis Sprint

	[ACTION_TYPE.Kinesis_SprintEnabled] = scriptAction("Toggle All Shift-Sprint", {
		command = function(vars)
			if not Kinesis then return end
			revertHoldingVars[ACTION_TYPE.Kinesis_SprintEnabled] = Kinesis.Sprint.GetShiftSprintEnabled()
			Kinesis.Sprint.SetShiftSprintEnabled(onToBoolean(vars))
		end,
		description = "Toggle Kinesis' 'Shift-Sprint' Module On/Off",
		dataName = "on/off",
		inputDescription = "On or Off to set the Shift-Sprint toggle to that.",
		example = Tooltip.genContrastText("On") .. " to turn on Shift-Sprinting.",
		revert = function(vars)
			if not Kinesis then return end
			if onToBoolean(vars) then
				Kinesis.Sprint.SetShiftSprintEnabled(not (onToBoolean(vars)))
			else
				Kinesis.Sprint.SetShiftSprintEnabled(revertHoldingVars[ACTION_TYPE.Kinesis_SprintEnabled])
			end
		end,
		revertDesc =
		"Resets the Shift-Sprint Enabled toggle back to what it was set to before. Note that this may not directly revert your action. For example, if it is toggled off, and you run this action to turn if off, with a revert, it will remain off.",
		dependency = "Kinesis",
		softDependency = true,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_SprintGround] = scriptAction("Sprint Speed (Ground)", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Sprint.SetSprintSpeedGround(tonumber(vars))
		end,
		description = "Set the speed to use when sprinting on the ground.",
		dataName = "speed",
		inputDescription = "The speed to use for sprinting on the ground.",
		example = Tooltip.genContrastText("1.6") .. " to set your ground sprint speed to 1.6x normal speed.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_SprintFly] = scriptAction("Sprint Speed (Fly)", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Sprint.SetSprintSpeedFly(tonumber(vars))
		end,
		description = "Set the speed to use when sprinting while flying.",
		dataName = "speed",
		inputDescription = "The speed to use for sprinting while flying.",
		example = Tooltip.genContrastText("10") .. " to set your flying sprint speed to 10x normal speed.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_SprintSwim] = scriptAction("Sprint Speed (Swim)", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Sprint.SetSprintSpeedSwim(tonumber(vars))
		end,
		description = "Set the speed to use when sprinting while swimming.",
		dataName = "speed",
		inputDescription = "The speed to use for sprinting while swimming.",
		example = Tooltip.genContrastText("5") .. " to set your swimming sprint speed to 5x normal speed.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_SprintReturnOrig] = scriptAction("Tog. Return Speed", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Sprint.SetReturnToOriginalSpeed(onToBoolean(vars))
		end,
		description = "Toggles if your speed should return to the last speed you were at (Original Speed), or always return to speed 1, when you stop sprinting.",
		dataName = "On/Off",
		inputDescription = "On = Return to Last Speed (Original Speed)\nOff = Always Return to Speed One",
		example = Tooltip.genContrastText("On") .. " to always return to your last speed when stopping sprinting.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),

	[ACTION_TYPE.Kinesis_SprintEmoteAll] = scriptAction("Enable Sprint Emote", {
		command = function(vars)
			if not Kinesis then return end
			local movetype, val = strsplit(",", vars)
			movetype = strtrim(string.lower(movetype))
			if movetype == "walk" or movetype == "ground" then
				Kinesis.Sprint.Emotes.SetEmoteTriggerWalk(onToBoolean(val))
			elseif movetype == "fly" then
				Kinesis.Sprint.Emotes.SetEmoteTriggerFly(onToBoolean(val))
			elseif movetype == "swim" then
				Kinesis.Sprint.Emotes.SetEmoteTriggerSwim(onToBoolean(val))
			end
		end,
		description = "Toggles sending the Sprint Emote when you start sprinting for the various Move Types (Ground, Fly, Swim).",
		dataName = "MoveType, on/off",
		inputDescription = "The movetype (walk/fly/swim), followed by on/off to enable or disable that move-type.",
		example = Tooltip.genContrastText("swim, off") .. " to disable .",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_SprintEmoteText] = scriptAction("Sprint Emote Message", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Sprint.Emotes.SetEmoteText(vars)
		end,
		description = "desc",
		dataName = "data",
		inputDescription = "input.",
		example = Tooltip.genContrastText("begins to sprint.") .. " to set your Sprint Emote as '/emote begins to sprint.'.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_SprintEmoteRate] = scriptAction("Sprint Emote Rate", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Sprint.Emotes.SetEmoteRateLimit(tonumber(vars))
		end,
		description = "desc",
		dataName = "data",
		inputDescription = "input.",
		example = Tooltip.genContrastText("5") .. " to limit Sprint Emotes to once every 5 seconds max.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),

	[ACTION_TYPE.Kinesis_SprintSpellAll] = scriptAction("Enable Sprint Spell", {
		command = function(vars)
			if not Kinesis then return end
			local movetype, val = strsplit(",", vars)
			movetype = strtrim(string.lower(movetype))
			if movetype == "walk" or movetype == "ground" then
				Kinesis.Sprint.Spells.SetSpellTriggerWalk(onToBoolean(val))
			elseif movetype == "fly" then
				Kinesis.Sprint.Spells.SetSpellTriggerFly(onToBoolean(val))
			elseif movetype == "swim" then
				Kinesis.Sprint.Spells.SetSpellTriggerSwim(onToBoolean(val))
			end
		end,
		description =
		"Enable or Disable triggering standard spells when you start sprinting for the different Move Types (Ground, Fly, Swim). Standard spells are applied using aura; if you need more control, consider using an ArcSpell.",
		dataName = "MoveType, On/Off",
		inputDescription = "The Move Type (walk/fly/swim), followed by on/off to enable or disable that Move Type.",
		example = Tooltip.genContrastText("fly, on") .. " to enable Sprint Spells when triggering sprinting while flying.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),

	[ACTION_TYPE.Kinesis_SprintArcEnabled] = scriptAction("Tog. Sprint ArcSpells", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Sprint.Spells.SetSpellArcanumEnabled(onToBoolean(vars))
		end,
		description = "Enable or Disable triggering ArcSpells when you start & stop sprinting.",
		dataName = "On/Off",
		inputDescription = "On to enable triggering ArcSpells, Off to disable.",
		example = Tooltip.genContrastText("on") .. " to enable Sprint triggering Arc Spells.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_SprintArcStart] = scriptAction("Sprint Start ArcSpell", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Sprint.Spells.SetSpellArcanumStart(vars)
		end,
		description = "Set the ArcSpell that will be cast when you start sprinting.",
		dataName = "commID",
		inputDescription = "The CommID of the spell to cast when you start sprinting. Must be an ArcSpell in your Personal Vault.",
		example = Tooltip.genContrastText("mySprintingArcSpell") .. " to set that Arcanum Spell to be cast when you start sprinting.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_SprintArcStop] = scriptAction("Sprint Stop ArcSpell", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Sprint.Spells.SetSpellArcanumStop(vars)
		end,
		description = "Set the ArcSpell that will be cast when you stop sprinting.",
		dataName = "commID",
		inputDescription = "The CommID of the spell to cast when you stop sprinting. Must be an ArcSpell in your Personal Vault.",
		example = Tooltip.genContrastText("stopSprintingArcSpell") .. " to set that Arcanum Spell to be cast when you stop sprinting.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),

	[ACTION_TYPE.Kinesis_SprintSetSpells] = scriptAction("Set Sprint Spells", {
		command = function(vars)
			if not Kinesis then return end
			local spellLists = Kinesis.Sprint.Spells.StandardSpellsGetSets()
			local backupName = "ArcBackup_" .. UnitName("player")
			if spellLists[backupName] then
				local index = 1
				while (spellLists[backupName .. tostring(index)]) do
					index = index + 1
					if index > maxBackupsPerChar - 1 then
						index = 1
						break
					end
				end
				Kinesis.Sprint.Spells.StandardSpellsSaveSet(backupName .. tostring(index), true, select(2, Kinesis.Sprint.Spells.GetCurrentSpellList()))
			else
				Kinesis.Sprint.Spells.StandardSpellsSaveSet(backupName, true, select(2, Kinesis.Sprint.Spells.GetCurrentSpellList()))
			end
			Kinesis.Sprint.Spells.StandardSpellsSetSpells(vars)
		end,
		description =
		"Set your Kinesis Sprint Spells to the spells you specify.\n\rYour previous set of spells will be saved in a temporary backup Spell Set in the /kinesis menu.",
		dataName = "Spell ID(s)",
		inputDescription = "Spell IDs, separated by a command if you want multiple.",
		example = Tooltip.genContrastText("123, 456, 789") .. " to set your Sprint Spells as 123, 456, 789.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Kinesis_SprintLoadSpellSet] = scriptAction("Load Sprint Spell Set", {
		command = function(vars)
			if not Kinesis then return end
			Kinesis.Sprint.Spells.StandardSpellsLoadSet(vars)
		end,
		description = "Load a Sprint Spell Set by name.",
		dataName = "Spell Set Name",
		inputDescription = "The name of the Sprint Spell Set to set as your current spells. Case sensitive (because MindScape was too lazy to fix it).",
		example = Tooltip.genContrastText("My Awesome sprint spells!") .. " to set that Sprint Spell Set as your current Sprint Spells.",
		revert = nil,
		dependency = "Kinesis",
		doNotDelimit = true,
	}),

}

---@class Actions_Data
ns.Actions.Data = {
	ACTION_TYPE = ACTION_TYPE,
	actionTypeData = actionTypeData,
}
