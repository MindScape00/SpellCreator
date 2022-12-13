---@class ns
local ns = select(2, ...)

local Aura = ns.Utils.Aura
local Cmd = ns.Cmd
local Logging = ns.Logging
local Vault = ns.Vault

local cmd, cmdWithDotCheck = Cmd.cmd, Cmd.cmdWithDotCheck
local runMacroText = Cmd.runMacroText
local cprint = Logging.cprint
local Tooltip = ns.Utils.Tooltip

---@enum ActionType
local ACTION_TYPE = {
	SpellHeader = "SpellHeader",
	AuraMenu = "AuraMenu",
	CastMenu = "CastMenu",
	MorphMenu = "MorphMenu",
	CharacterHeader = "CharacterHeader",
	AnimationMenu = "AnimationMenu",
	AnimationHeader = "AnimationHeader",
	WeaponHeader = "WeaponHeader",
	ItemsMenu = "ItemsMenu",
	InventoryHeader = "InventoryHeader",
	EquipmentHeader = "EquipmentHeader",
	SpeedMenu = "SpeedMenu",
	TRP3Menu = "TRP3Menu",
	RunHeader = "RunHeader",
	CheatMenu = "CheatMenu",
	MacroText = "MacroText",
	Command = "Command",
	ARCAPIMenu = "ARCAPIMenu",

	ArcMenu = "ArcMenu",
	ArcSpell = "ArcSpell",
	ArcCastbar = "ArcCastbar",
	ArcStopSpells = "ArcStopSpells",

	Spacer = "Spacer",

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

	SpellCast = "SpellCast",
	SpellTrig = "SpellTrig",

	Equip = "Equip",
	EquipSet = "EquipSet",
	MogitEquip = "MogitEquip",
	Unequip = "Unequip",
	AddItem = "AddItem",
	RemoveItem = "RemoveItem",

	Scale = "Scale",

	AllSpeedHeader = "AllSpeedHeader",
	Speed = "Speed",
	SpecificSpeedHeader = "SpecificSpeedHeader",
	SpeedWalk = "SpeedWalk",
	SpeedBackwalk = "SpeedBackwalk",
	SpeedFly = "SpeedFly",
	SpeedSwim = "SpeedSwim",

	TRP3ProfileHeader = "TRP3ProfileHeader",
	TRP3Profile = "TRP3Profile",
	TRP3StatusHeader = "TRP3StatusHeader",
	TRP3StatusToggle = "TRP3StatusToggle",
	TRP3StatusIC = "TRP3StatusIC",
	TRP3StatusOOC = "TRP3StatusOOC",

	Morph = "Morph",
	Native = "Native",
	Unmorph = "Unmorph",

	CheatOn = "CheatOn",
	CheatOff = "CheatOff",

	ARCSet = "ARCSet",
	ARCTog = "ARCTog",
	ARCCopy = "ARCCopy",
}

---@param name string
---@return HeaderActionTypeData
local function header(name)
	return {
		name = name,
		type = "header",
	}
end

---@param name string
---@param actions ActionType[]
---@param dependency string?
---@return MenuActionTypeData
local function subMenu(name, actions, dependency)
	local menu = {
		name = name,
		type = "submenu",
		menuDataList = actions,
	}

	if dependency then menu.dependency = dependency end

	return menu
end

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

---@type ActionType[]
local actionTypeDataList = { -- formatted for easier sorting - whatever order they are here is the order they show up in dropdown as.
	ACTION_TYPE.SpellHeader,
	ACTION_TYPE.AuraMenu,
	ACTION_TYPE.CastMenu,
	ACTION_TYPE.MorphMenu,
	ACTION_TYPE.CharacterHeader,
	ACTION_TYPE.AnimationMenu,
	ACTION_TYPE.ItemsMenu,
	ACTION_TYPE.Scale,
	ACTION_TYPE.SpeedMenu,
	ACTION_TYPE.TRP3Menu,
	ACTION_TYPE.RunHeader,
	ACTION_TYPE.CheatMenu,
	ACTION_TYPE.MacroText,
	ACTION_TYPE.Command,
	ACTION_TYPE.ARCAPIMenu,
	ACTION_TYPE.ArcMenu,
}

---@type table<ActionType, FunctionActionTypeData | ServerActionTypeData | HeaderActionTypeData | MenuActionTypeData | SpacerActionTypeData>
local actionTypeData = {
	[ACTION_TYPE.SpellHeader] = header("Spells and effects"),
	[ACTION_TYPE.CharacterHeader] = header("Character"),
	[ACTION_TYPE.RunHeader] = header("Run"),
	[ACTION_TYPE.AnimationHeader] = header("Animation"),
	[ACTION_TYPE.WeaponHeader] = header("Weapon"),
	[ACTION_TYPE.InventoryHeader] = header("Inventory"),
	[ACTION_TYPE.EquipmentHeader] = header("Equipment"),
	[ACTION_TYPE.AllSpeedHeader] = header("All types"),
	[ACTION_TYPE.SpecificSpeedHeader] = header("Per mode"),
	[ACTION_TYPE.TRP3ProfileHeader] = header("Profile"),
	[ACTION_TYPE.TRP3StatusHeader] = header("Status"),

	[ACTION_TYPE.AnimationMenu] = subMenu("Animation", {
		ACTION_TYPE.AnimationHeader,
		ACTION_TYPE.Anim,
		ACTION_TYPE.Standstate,
		ACTION_TYPE.Spacer,
		ACTION_TYPE.ResetAnim,
		ACTION_TYPE.ResetStandstate,
		ACTION_TYPE.WeaponHeader,
		ACTION_TYPE.ToggleSheath,
	}),
	[ACTION_TYPE.AuraMenu] = subMenu("Aura", {
		ACTION_TYPE.SpellAura,
		ACTION_TYPE.ToggleAura,
		ACTION_TYPE.ToggleAuraSelf,
		ACTION_TYPE.Spacer,
		ACTION_TYPE.RemoveAura,
		ACTION_TYPE.RemoveAllAuras,
	}),
	[ACTION_TYPE.CastMenu] = subMenu("Cast", {
		ACTION_TYPE.SpellCast,
		ACTION_TYPE.SpellTrig,
	}),
	[ACTION_TYPE.ItemsMenu] = subMenu("Items", {
		ACTION_TYPE.InventoryHeader,
		ACTION_TYPE.AddItem,
		ACTION_TYPE.RemoveItem,
		ACTION_TYPE.EquipmentHeader,
		ACTION_TYPE.Equip,
		ACTION_TYPE.EquipSet,
		ACTION_TYPE.MogitEquip,
		ACTION_TYPE.Spacer,
		ACTION_TYPE.Unequip,
	}),
	[ACTION_TYPE.SpeedMenu] = subMenu("Speed", {
		ACTION_TYPE.AllSpeedHeader,
		ACTION_TYPE.Speed,
		ACTION_TYPE.SpecificSpeedHeader,
		ACTION_TYPE.SpeedWalk,
		ACTION_TYPE.SpeedBackwalk,
		ACTION_TYPE.SpeedFly,
		ACTION_TYPE.SpeedSwim,
	}),
	[ACTION_TYPE.TRP3Menu] = subMenu("Total RP 3", {
		ACTION_TYPE.TRP3ProfileHeader,
		ACTION_TYPE.TRP3Profile,
		ACTION_TYPE.TRP3StatusHeader,
		ACTION_TYPE.TRP3StatusToggle,
		ACTION_TYPE.TRP3StatusIC,
		ACTION_TYPE.TRP3StatusOOC,
	}, "totalRP3"),
	[ACTION_TYPE.MorphMenu] = subMenu("Morph", {
		ACTION_TYPE.Morph,
		ACTION_TYPE.Native,
		ACTION_TYPE.Spacer,
		ACTION_TYPE.Unmorph,
	}),
	[ACTION_TYPE.CheatMenu] = subMenu("Cheat", {
		ACTION_TYPE.CheatOn,
		ACTION_TYPE.CheatOff,
	}),
	[ACTION_TYPE.ARCAPIMenu] = subMenu("ARC:API", {
		ACTION_TYPE.ARCSet,
		ACTION_TYPE.ARCTog,
		ACTION_TYPE.ARCCopy,
	}),
	[ACTION_TYPE.ArcMenu] = subMenu("Arcanum", {
		ACTION_TYPE.ArcSpell,
		ACTION_TYPE.ArcCastbar,
		ACTION_TYPE.ArcStopSpells,
	}),

	[ACTION_TYPE.Spacer] = {
		["type"] = "spacer",
	},

	[ACTION_TYPE.SpellCast] = serverAction("Cast Spell", {
		command = "cast @N@", -- The chat command, or Lua function to process
		description = "Cast a spell using a Spell ID, to selected target, or self if no target.", -- Description for on-mouse-over
		dataName = "Spell ID(s)", -- Label for the ID Box, nil to disable the ID box
		inputDescription = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\rUse "..Tooltip.genContrastText('.look spell').." to find IDs.", -- Description of the input for GameTooltip
		revert = "unaura @N@", -- The command that reverts it, i.e, 'unaura' for 'aura'
		revertDesc = "unaura",
		selfAble = true, -- True/False - if able to use the self-toggle checkbox
	}),
	[ACTION_TYPE.SpellTrig] = serverAction("Cast Spell (Trig)", {
		command = "cast @N@ trig",
		description = "Cast a spell using a Spell ID, to selected target, or self if no target, using the triggered flag.",
		dataName = "Spell ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\rUse "..Tooltip.genContrastText('.look spell').." to find IDs.",
		revert = "unaura @N@",
		revertDesc = "unaura",
		selfAble = true,
	}),
	[ACTION_TYPE.SpellAura] = serverAction("Apply Aura", {
		command = "aura @N@",
		description = "Applies an Aura from a Spell ID on your target if able, or yourself otherwise.",
		dataName = "Spell ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to apply multiple auras at once.\n\rUse "..Tooltip.genContrastText('.look spell').." to find IDs.",
		revert = "unaura @N@",
		revertDesc = "unaura",
		selfAble = true,
	}),
	[ACTION_TYPE.ToggleAura] = scriptAction("Toggle Aura", {
		command = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID) else cmd("aura "
			.. spellID) end end,
		description = "Toggles an Aura on / off.\n\rApplies to your target if you have Phase DM on & Officer+",
		dataName = "Spell ID",
		inputDescription = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\rUse "..Tooltip.genContrastText('.look spell').." to find IDs.",
		revert = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID) else cmd("aura "
			.. spellID) end end,
		revertDesc = "Toggles the Aura again",
	}),
	[ACTION_TYPE.ToggleAuraSelf] = scriptAction("Toggle Aura (Self)", {
		command = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID .. " self") else cmd("aura "
			.. spellID .. " self") end end,
		description = "Toggles an Aura on / off.\n\rAlways applies on yourself.",
		dataName = "Spell ID",
		inputDescription = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\rUse"..Tooltip.genContrastText('.look spell').." to find IDs.",
		revert = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID .. " self") else cmd("aura " .. spellID .. " self") end end,
		revertDesc = "Toggles the Aura again",
	}),
	[ACTION_TYPE.Anim] = serverAction("Emote/Anim", {
		command = "mod anim @N@",
		description = "Modifies target's current animation using 'mod anim'.\n\rUse "..Tooltip.genContrastText('.look emote').." to find IDs.",
		dataName = "Emote ID",
		inputDescription = "Accepts multiple IDs, separated by commas, to do multiple anims at once -- but the second usually over-rides the first anyways.\n\rUse "..Tooltip.genContrastText('.look emote').." to find IDs.",
		revert = "mod anim 0",
		revertDesc = "Reset to Anim 0 (none)",
		selfAble = false,
	}),
	[ACTION_TYPE.ResetAnim] = serverAction("Reset Emote/Anim", {
		command = "mod anim 0",
		description = "Reset target's current animation to Anim 0 (none).",
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
		inputDescription = "No, you can't put multiple to become a hybrid monster..\n\rUse "..Tooltip.genContrastText('.look displayid').." to find IDs.",
		revert = "demorph",
		revertDesc = "demorph",
		selfAble = false,
	}),
	[ACTION_TYPE.Native] = serverAction("Native", {
		command = "mod native @N@",
		description = "Modifies your Native to specified Display ID.",
		dataName = "Display ID",
		inputDescription = "Use "..Tooltip.genContrastText('.look displayid').." to find IDs.",
		revert = "demorph",
		revertDesc = "demorph",
		selfAble = false,
	}),
	[ACTION_TYPE.Standstate] = serverAction("Standstate", {
		command = "mod standstate @N@",
		description = "Change the emote of your character while standing to an Emote ID.",
		dataName = "Standstate ID",
		inputDescription = "Accepts multiple IDs, separated by commas, to set multiple standstates at once.. but you can't have two, so probably don't try it.\n\rUse "..Tooltip.genContrastText('.look emote').." to find IDs.",
		revert = "mod stand 0",
		revertDesc = "Set Standstate to 0 (none)",
		selfAble = false,
	}),
	[ACTION_TYPE.ToggleSheath] = scriptAction("Sheath/Unsheath Weapon", {
		command =  function() ToggleSheath() end,
		description = "Sheath or unsheath your weapon.",
	}),
	[ACTION_TYPE.Equip] = scriptAction("Equip Item", {
		command = function(vars) EquipItemByName(vars) end,
		description = "Equip an Item by name or ID. Item must be in your inventory.\n\rName is a search in your inventory by keyword - using ID is recommended.",
		dataName = "Item ID or Name(s)",
		inputDescription = "Accepts multiple IDs/Names, separated by commas, to equip multiple items at once.\n\rUse "..Tooltip.genContrastText('.look item')..", or mouse-over an item in your inventory for IDs.",
		example = "You want to equip 'Violet Guardian's Helm', ID: 141357, but have 'Guardian's Leather Belt', ID: 35156 in your inventory also, using 'Guardian' as the text will equip the belt, so you'll want to use the full name, or better off just use the actual item ID.",
		revert = nil,
		revertAlternative = "a separate unequip item action",
		selfAble = false,
	}),
	[ACTION_TYPE.AddItem] = serverAction("Add Item", {
		command = "additem @N@",
		description = "Add an item to your inventory.\n\rYou may specify multiple items separated by commas, and may specify item count & bonusID per item as well.",
		dataName = "Item ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to add multiple items at once.\n\rUse "..Tooltip.genContrastText('.look item')..", or mouse-over an item in your inventory for IDs.",
		example = Tooltip.genContrastText("125775 1 449, 125192 1 449").." will add 1 of each item with Heroic (449) tier",
		revert = nil,
		revertAlternative = "a separate remove item action",
		selfAble = false,
	}),
	[ACTION_TYPE.RemoveItem] = serverAction("Remove Item", {
		command = "additem @N@ -1",
		description = "Remove an item from your inventory.\n\rYou may specify multiple items separated by commas, and may optionally specify item count as a negative number to remove that many of the item.",
		dataName = "Item ID(s)",
		inputDescription = "Accepts multiple IDs, separated by commas, to remove multiple items at once.\n\rUse "..Tooltip.genContrastText('.look item')..", or mouse-over an item in your inventory for IDs.",
		example = Tooltip.genContrastText("125775 -10").." to remove 10 of that item.",
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
		description = "Enables the specified cheat.\n\rUse "..Tooltip.genContrastText('.cheat').." to view available cheats.",
		dataName = "Cheat",
		inputDescription = "The cheat command to enable.\n\rCommon Cheats:\r"..Tooltip.genContrastText({"casttime","cooldown","god","waterwalk","duration","slowcast"}).."\n\rUse "..Tooltip.genContrastText(".cheat").." to view all available cheats.",
		example = "\r"..Tooltip.genContrastText("cast").." will enable instant cast cheat\r"..Tooltip.genContrastText("cool").." will enable no cooldowns cheat",
		revert = "cheat @N@ off",
		revertDesc = "Disable the cheat",
		selfAble = false,
	}),
	[ACTION_TYPE.CheatOff] = serverAction("Disable Cheat", {
		command = "cheat @N@ off",
		description = "Disables the specified cheat.\n\rUse "..Tooltip.genContrastText('.cheat').." to view available cheats.",
		dataName = "Cheat",
		inputDescription = "The cheat command to disable.\n\rUse "..Tooltip.genContrastText('.cheat').." to view available cheats.",
		example = "\r"..Tooltip.genContrastText("cast").." will disable instant cast cheat\r"..Tooltip.genContrastText("cool").." will disable no cooldowns cheat",
		revert = "cheat @N@ on",
		revertDesc = "Enable the cheat",
		selfAble = false,
	}),
	[ACTION_TYPE.MacroText] = scriptAction("Macro Script", {
		command = function(command) runMacroText(command); end,
		description = "Any line that can be processed in a macro (any slash commands & macro flags).\n\rYou can use this for pretty much ANYTHING, technically, including custom short Lua scripts.",
		dataName = "/command",
		inputDescription = "Any /commands that can be processed in a macro-script, including emotes, addon commands, Lua run scripts, etc.\n\rYou can use any part of the ARC:API here as well. Use /arc for more info.",
		example = Tooltip.genContrastText("/emote begins to conjur up a fireball in their hand.").." to perform the emote.",
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
		example = Tooltip.genContrastText(GetUnitName("player") .. " Cool Armor Set").." to equip Cool Armor Set from this character.",
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
	[ACTION_TYPE.ArcSpell] = scriptAction("Arc Spell", {
		["command"] = function(commID)
			local spell = Vault.personal.findSpellByID(commID)
			if not spell then
				cprint("No spell with command '"..commID.."' found in your Personal Vault.")
				return
			end
			ns.Actions.Execute.executeSpell(spell.actions, nil, spell.fullName, spell)
		end,
		["description"] = "Cast another Arcanum Spell from your Personal Vault.",
		["dataName"] = "Spell Command",
		["inputDescription"] = "The command ID (commID) used to cast the ArcSpell",
		["example"] = "From "..Tooltip.genContrastText('/sf MySpell')..", input just "..Tooltip.genContrastText("MySpell").." as this input.",
		["revert"] = nil,
	}),
	[ACTION_TYPE.ArcCastbar] = scriptAction("Castbar", {
		command = function(data)
			local length, text, iconPath, channeled, showIcon, showShield = strsplit(",",data,6)
			if length then length = strtrim(length) end
			if text then text = strtrim(text) end
			if iconPath then iconPath = {["icon"] = strtrim(iconPath)} end
			if channeled then channeled = ns.Utils.Data.toboolean(strtrim(channeled)) end
			if showIcon then showIcon = ns.Utils.Data.toboolean(strtrim(showIcon)) end
			if showShield then showShield = ns.Utils.Data.toboolean(strtrim(showShield)) end
			ns.UI.Castbar.showCastBar(length, text, iconPath, channeled, showIcon, showShield)
		end,
		description = "Show a custom Arcanum Castbar with your own settings & duration.",
		dataName = "Castbar Settings",
		inputDescription = "Syntax: duration, [title, [iconPath/FileID, [channeled (true/false), [showIcon (true/false), [showShield (true/false)]]]]]\n\rDuration is the only required input.",
		revert = nil,
		doNotDelimit = true,
	}),
	[ACTION_TYPE.ArcStopSpells] = scriptAction("Stop ArcSpells", {
		command = function() ns.Actions.Execute.stopRunningActions() end,
		description = "Stops all currently running ArcSpells - including this spell if called on a delay.\n\rUse it as the first action with a delay of 0 if you want to cancel any other running ArcSpells before you cast this spell.",
		revert = nil,
	}),
	[ACTION_TYPE.ARCSet] = scriptAction("Set Variable", {
		command = function(data)
			local var, val = strsplit("|", data, 2);
			var = strtrim(var, " \t\r\n\124");
			val = strtrim(val, " \t\r\n\124");
			ARC:SET(var, val);
		end,
		description = "Set an ARCVAR to a specific value.",
		dataName = "VarName | Value",
		inputDescription = "Provide the variable name & the value to set it as, separated by a | character.",
		revert = nil,
		revertAlternative = "another Set Variable action",
	}),
	[ACTION_TYPE.ARCTog] = scriptAction("Toggle Variable", {
		command = function(var) ARC:TOG(var) end,
		description = "Toggle an ARCVAR, like a light switch.",
		dataName = "Variable Name",
		inputDescription = "The variable name to toggle.",
		revert = function(var) ARC:TOG(var) end,
		revertDesc = "Toggles the ARCVAR again.",
	}),
	[ACTION_TYPE.ARCCopy] = scriptAction("Copy Text/URL", {
		command = function(text) ARC:COPY(text) end,
		description = "Open a dialog box to copy the given text (i.e., a URL).",
		dataName = "Text / URL",
		inputDescription = "The text / link / URL to copy.",
		example = "https://discord.gg/C8DZ7AxxcG",
		revert = nil,
	}),
}

---@class Actions_Data
ns.Actions.Data = {
	actionTypeDataList = actionTypeDataList,
	actionTypeData = actionTypeData,
}
