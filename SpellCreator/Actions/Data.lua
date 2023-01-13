---@class ns
local ns = select(2, ...)

local Aura = ns.Utils.Aura
local Cmd = ns.Cmd
local Logging = ns.Logging
local Vault = ns.Vault

local Constants = ns.Constants
local AceConsole = ns.Libs.AceConsole

local cmd, cmdWithDotCheck = Cmd.cmd, Cmd.cmdWithDotCheck
local runMacroText = Cmd.runMacroText
local cprint = Logging.cprint
local Tooltip = ns.Utils.Tooltip

---@enum ActionType
local ACTION_TYPE = {
	MacroText = "MacroText",
	Command = "Command",
	ArcSpell = "ArcSpell",
	ArcSpellPhase = "ArcSpellPhase",
	ArcSaveFromPhase = "ArcSaveFromPhase",
	ArcCastbar = "ArcCastbar",
	ArcStopSpells = "ArcStopSpells",

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

	PrintMsg = "PrintMsg",
	RaidMsg = "RaidMsg",
	BoxMsg = "BoxMsg",

	QCBookToggle = "QCBookToggle",
	QCBookStyle = "QCBookStyle",
	QCBookSwitchPage = "QCBookSwitchPage",
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
		command = "cast @N@", -- The chat command, or Lua function to process
		description = "Cast a spell using a Spell ID, to selected target, or self if no target.", -- Description for on-mouse-over
		dataName = "Spell ID(s)", -- Label for the ID Box, nil to disable the ID box
		inputDescription = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\rUse " .. Tooltip.genContrastText('.look spell') .. " to find IDs.", -- Description of the input for GameTooltip
		revert = "unaura @N@", -- The command that reverts it, i.e, 'unaura' for 'aura'
		revertDesc = "unaura",
		selfAble = true, -- True/False - if able to use the self-toggle checkbox
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
		command = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID) else cmd("aura "
					.. spellID)
			end
		end,
		description = "Toggles an Aura on / off.\n\rApplies to your target if you have Phase DM on & Officer+",
		dataName = "Spell ID",
		inputDescription = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\rUse " .. Tooltip.genContrastText('.look spell') .. " to find IDs.",
		revert = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID) else cmd("aura "
					.. spellID)
			end
		end,
		revertDesc = "Toggles the Aura again",
	}),
	[ACTION_TYPE.ToggleAuraSelf] = scriptAction("Toggle Aura (Self)", {
		command = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID .. " self") else cmd("aura "
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
		example = "You want to equip 'Violet Guardian's Helm', ID: 141357, but have 'Guardian's Leather Belt', ID: 35156 in your inventory also, using 'Guardian' as the text will equip the belt, so you'll want to use the full name, or better off just use the actual item ID.",
		revert = nil,
		revertAlternative = "a separate unequip item action",
		selfAble = false,
	}),
	[ACTION_TYPE.AddItem] = serverAction("Add Item", {
		command = "additem @N@",
		description = "Add an item to your inventory.\n\rYou may specify multiple items separated by commas, and may specify item count & bonusID per item as well.",
		dataName = "Item ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to add multiple items at once.\n\rUse " .. Tooltip.genContrastText('.look item') .. ", or mouse-over an item in your inventory for IDs.",
		example = Tooltip.genContrastText("125775 1 449, 125192 1 449") .. " will add 1 of each item with Heroic (449) tier",
		revert = nil,
		revertAlternative = "a separate remove item action",
		selfAble = false,
	}),
	[ACTION_TYPE.RemoveItem] = serverAction("Remove Item", {
		command = "additem @N@ -1",
		description = "Remove an item from your inventory.\n\rYou may specify multiple items separated by commas, and may optionally specify item count as a negative number to remove that many of the item.",
		dataName = "Item ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to remove multiple items at once.\n\rUse " ..
			Tooltip.genContrastText('.look item') .. ", or mouse-over an item in your inventory for IDs.",
		example = Tooltip.genContrastText("125775 -10") .. " to remove 10 of that item.",
		revert = nil,
		revertAlternative = "a separate add item action",
		selfAble = false,
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
		command = function(slotID) PickupInventoryItem(slotID); PutItemInBackpack(); end,
		description = "Unequips an item by item slot.\n\rCommon IDs:\rHead: 1          Shoulders: 2\rShirt: 4          Chest: 5\rWaist: 6         Legs 6\rFeet: 8           Wrist: 9\rHands: 10       Back: 15\rRanged: 18      Tabard: 19\rMain-hand: 16\rOff-hand: 17",
		dataName = "Item Slot ID(s)",
		inputDescription = "Common IDs:\rHead: 1          Shoulders: 2\rShirt: 4           Chest: 5\rWaist: 6         Legs 6\rFeet: 8            Wrist: 9\rHands: 10       Back: 15\rRanged: 18      Tabard: 19\rMain-hand: 16\rOff-hand: 17\n\rAccepts multiple slot ID's, separated by commas, to remove multiple slots at the same time.",
		revert = nil,
		revertAlternative = "a eparate Equip Item action",
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
	-- 	["description"] = "Any default emote.\n\rMust be a valid emote 'token', i.e., 'WAVE'\n\rGoogle 'WoWpedia DoEmote' for a full list - most match their /command, but some don't.",
	-- 	["dataName"] = "Emote Token",
	-- 	["inputDescription"] = "Usually just the text from the /command, i.e., /wave = wave.\n\rIf not working: Search Google for 'WoWpedia DoEmote', and go to the WoWpedia page, and find the table of tokens - some don't exactly match their command.",
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
		description = "Any line that can be processed in a macro (any slash commands & macro flags).\n\rYou can use this for pretty much ANYTHING, technically, including custom short Lua scripts.",
		dataName = "/command",
		inputDescription = "Any /commands that can be processed in a macro-script, including emotes, addon commands, Lua run scripts, etc.\n\rYou can use any part of the ARC:API here as well. Use /arc for more info.",
		example = Tooltip.genContrastText("/emote begins to conjur up a fireball in their hand.") .. " to perform the emote.",
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.Command] = scriptAction("Server .Command", {
		command = cmdWithDotCheck,
		description = "Any other server command.\n\rType the full command you want, without the dot, in the input box.",
		dataName = "Full Command",
		inputDescription = "You can use any server command here, without the '.', and it will run after the delay.\n\rDoes NOT accept comma separated multi-actions.",
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
			ARC:SAVE(commID, vocal)
		end,
		description = "Save an Arcanum Spell from the Phase Vault, with an optional message to let them know they learned a new ArcSpell!",
		dataName = "Spell Command, [send message (true/false)]",
		inputDescription = "Syntax: The command ID (commID) used to cast the ArcSpell, [print a 'New Spell Learned' message (true/false)]",
		example = "My Cool Spell, true",
		revert = nil,
	}),
	[ACTION_TYPE.ArcCastbar] = scriptAction("Show Castbar", {
		command = function(data)
			local length, text, iconPath, channeled, showIcon, showShield = strsplit(",", data, 6)
			if length then length = strtrim(length) end
			if text then text = strtrim(text) end
			if iconPath then iconPath = { ["icon"] = strtrim(iconPath) } end
			if channeled then channeled = ns.Utils.Data.toboolean(strtrim(channeled)) end
			if showIcon then showIcon = ns.Utils.Data.toboolean(strtrim(showIcon)) end
			if showShield then showShield = ns.Utils.Data.toboolean(strtrim(showShield)) end
			ns.UI.Castbar.showCastBar(length, text, iconPath, channeled, showIcon, showShield)
		end,
		description = "Show a custom Arcanum Castbar with your own settings & duration.\n\rSyntax: duration, [title, [iconPath/FileID, [channeled (true/false), [showIcon (true/false), [showShield (true/false)]]]]]\n\rDuration is the only required input.",
		dataName = "Castbar Settings",
		inputDescription = "Syntax: duration, [title, [iconPath/FileID, [channeled (true/false), [showIcon (true/false), [showShield (true/false)]]]]]\n\rDuration is the only required input.",
		example = Tooltip.genContrastText("5, Cool Spell!, 1, true, true, false") ..
			" will show a Castbar for 5 seconds, named 'Cool Spell!', with a gem icon, but no shield frame.\n\r" ..
			Tooltip.genTooltipText("lpurple", "Icon ID's " .. Tooltip.genContrastText("1 - 10") .. " can be used for Arcanum's custom Icons."),
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ArcStopSpells] = scriptAction("Stop ArcSpells", {
		command = function() ns.Actions.Execute.stopRunningActions() end,
		description = "Stops all currently running ArcSpells - including this spell if called on a delay.\n\rUse it as the first action with a delay of 0 if you want to cancel any other running ArcSpells before you cast this spell.",
		revert = nil,
	}),
	[ACTION_TYPE.ARCSet] = scriptAction("Set My Variable", {
		command = function(data)
			local var, val = strsplit("|", data, 2);
			var = strtrim(var, " \t\r\n\124");
			val = strtrim(val, " \t\r\n\124");
			ARC:SET(var, val);
		end,
		description = "Set a Personal ARCVAR to a specific value.\n\rMy ARCVARs can be accessed via the table ARC.VAR, or via ARC:GET() in a macro script.\n\rPersonal ArcVars do not save between sessions.",
		dataName = "VarName | Value",
		inputDescription = "Provide the variable name & the value to set it as, separated by a | character. Inputs are trimmed of leading & trailing spaces.",
		revert = nil,
		revertAlternative = "another Set Variable action",
		example = "KeysCollected | 3",
	}),
	[ACTION_TYPE.ARCTog] = scriptAction("Toggle My Variable", {
		command = function(var) ARC:TOG(var) end,
		description = "Toggle a Personal ARCVAR, like a light switch.\n\rMy ARCVARs can be accessed via the table ARC.VAR, or via ARC:GET() in a macro script.\n\rPersonal ArcVars do not save between sessions.",
		dataName = "Variable Name",
		inputDescription = "The variable name to toggle.",
		revert = function(var) ARC:TOG(var) end,
		revertDesc = "Toggles the ARCVAR again.",
	}),
	[ACTION_TYPE.ARCPhaseSet] = scriptAction("Set Phase Variable", {
		command = function(data)
			local var, val = strsplit("|", data, 2);
			var = strtrim(var, " \t\r\n\124");
			val = strtrim(val, " \t\r\n\124");
			ARC.PHASE:SET(var, val);
		end,
		description = "Set a Phase ARCVAR to a specific value.\n\rPhase ARCVARS can be accessed via the table ARC.PHASEVAR, or via ARC.PHASE:GET() in a macro script.\n\rPhase ArcVars are saved between sessions, but should not be considered secure as a user can manipulate them as well.",
		dataName = "VarName | Value",
		inputDescription = "Provide the variable name & the value to set it as, separated by a | character.",
		revert = nil,
		revertAlternative = "another Phase Set Variable action",
		example = "KeysCollected | 3",
	}),
	[ACTION_TYPE.ARCPhaseTog] = scriptAction("Toggle Phase Variable", {
		command = function(var) ARC.PHASE:TOG(var) end,
		description = "Toggle a Phase ARCVAR, like a light switch.\n\rPhase ARCVARS can be accessed via the table ARC.PHASEVAR, or via ARC.PHASE:GET() in a macro script.\n\rPhase ArcVars are saved between sessions, but should not be considered secure as a user can manipulate them as well.",
		dataName = "Variable Name",
		inputDescription = "The variable name to toggle.",
		revert = function(var) ARC.PHASE:TOG(var) end,
		revertDesc = "Toggles the Phase ARCVAR again.",
	}),
	[ACTION_TYPE.ARCCopy] = scriptAction("Copy Text/URL", {
		command = function(text) ARC:COPY(text) end,
		description = "Open a dialog box to copy the given text (i.e., a URL).",
		dataName = "Text / URL",
		inputDescription = "The text / link / URL to copy.",
		example = "https://discord.gg/C8DZ7AxxcG",
		revert = nil,
	}),
	[ACTION_TYPE.PrintMsg] = scriptAction("Chatbox Message", {
		command = print,
		description = "Prints a message in the chatbox.",
		dataName = "Text",
		inputDescription = "The text to print into the chatbox.",
		revert = nil,
	}),
	[ACTION_TYPE.RaidMsg] = scriptAction("Raid Message", {
		command = function(msg)
			RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
		end,
		description = "Shows a custom Raid Warning message, only to the persoon casting the spell.",
		dataName = "Text",
		inputDescription = "The text to show as the raid warning.",
		revert = nil,
	}),
	[ACTION_TYPE.BoxMsg] = scriptAction("Popup Box Message", {
		command = function(msg)
			ns.UI.Popups.showCustomGenericConfirmation({
				text = msg,
				acceptText = OKAY,
				cancelText = false,
			})
		end,
		description = "Shows a pop-up box with a customo message.",
		dataName = "Text",
		inputDescription = "The text to show in the popup box.",
		revert = nil,
	}),
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
	}),
	[ACTION_TYPE.QCBookStyle] = scriptAction("Change Book Style", {
		command = function(vars)
			local bookName, pageNumber = AceConsole:GetArgs(vars, 2)
			ns.UI.Quickcast.Book.changeBookStyle(bookName, pageNumber)
		end,
		description = "Toggle a Quickcast Book from being displayed on this character.",
		dataName = "Book Name",
		inputDescription = "The name of the Quickcast Book & style name. If either have spaces, enclose them in quotations.",
		example = '"Quickcast Book 1" Arcwolf',
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
}

---@class Actions_Data
ns.Actions.Data = {
	ACTION_TYPE = ACTION_TYPE,
	actionTypeData = actionTypeData,
}
