---@class ns
local ns = select(2, ...)

local Aura = ns.Utils.Aura
local Cmd = ns.Cmd
local Logging = ns.Logging

local cmd, cmdWithDotCheck = Cmd.cmd, Cmd.cmdWithDotCheck
local runMacroText = Cmd.runMacroText
local cprint = Logging.cprint

---@enum ActionType
local ACTION_TYPE = {
	SpellHeader = "SpellHeader",
	AuraMenu = "AuraMenu",
	CastMenu = "CastMenu",
	MorphMenu = "MorphMenu",
	CharacterHeader = "CharacterHeader",
	AnimationMenu = "AnimationMenu",
	EquipmentMenu = "EquipmentMenu",
	SpeedMenu = "SpeedMenu",
	TRP3Menu = "TRP3Menu",
	RunHeader = "RunHeader",
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

	ARCSet = "ARCSet",
	ARCTog = "ARCTog",
	ARCCopy = "ARCCopy",
}

---@type ActionType[]
local actionTypeDataList = { -- formatted for easier sorting - whatever order they are here is the order they show up in dropdown as.
	ACTION_TYPE.SpellHeader,
	ACTION_TYPE.AuraMenu,
	ACTION_TYPE.CastMenu,
	ACTION_TYPE.MorphMenu,
	ACTION_TYPE.CharacterHeader,
	ACTION_TYPE.AnimationMenu,
	ACTION_TYPE.EquipmentMenu,
	ACTION_TYPE.Scale,
	ACTION_TYPE.SpeedMenu,
	ACTION_TYPE.TRP3Menu,
	ACTION_TYPE.RunHeader,
	ACTION_TYPE.MacroText,
	ACTION_TYPE.Command,
	ACTION_TYPE.ARCAPIMenu,
	ACTION_TYPE.ArcMenu,
}

---@class HeaderActionTypeData: ActionTypeDataBase
---@field type "header"
---@field name string

---@class MenuActionTypeData: ActionTypeDataBase
---@field type "submenu"
---@field name string
---@field menuDataLis? ActionType[]

---@class SpacerActionTypeData: ActionTypeDataBase
---@field type "spacer"

---@class ActionTypeDataBase
---@field name string
---@field command string | function
---@field dataName? string
---@field selfAble boolean
---@field inputDescription string
---@field dependency string | nil
---@field doNotDelimit boolean
---@field revertDesc string?

---@class FunctionActionTypeData: ActionTypeDataBase
---@field command function
---@field comTarget "func"
---@field revert function | nil
---@field revertAlternative string?

---@class ServerActionTypeData: ActionTypeDataBase
---@field command string
---@field comTarget "server"
---@field revert string | nil
---@field revertAlternative string?

---@type table<ActionType, FunctionActionTypeData | ServerActionTypeData | HeaderActionTypeData | MenuActionTypeData | SpacerActionTypeData>
local actionTypeData = {
	[ACTION_TYPE.SpellHeader] = {
		["name"] = "Spells and effects",
		["type"] = "header",
	},
	[ACTION_TYPE.CharacterHeader] = {
		["name"] = "Character",
		["type"] = "header",
	},
	[ACTION_TYPE.RunHeader] = {
		["name"] = "Run",
		["type"] = "header",
	},
	[ACTION_TYPE.AllSpeedHeader] = {
		["name"] = "All types",
		["type"] = "header",
	},
	[ACTION_TYPE.SpecificSpeedHeader] = {
		["name"] = "Per mode",
		["type"] = "header",
	},
	[ACTION_TYPE.TRP3ProfileHeader] = {
		["name"] = "Profile",
		["type"] = "header",
	},
	[ACTION_TYPE.TRP3StatusHeader] = {
		["name"] = "Status",
		["type"] = "header",
	},
	[ACTION_TYPE.AnimationMenu] = {
		["name"] = "Animation",
		["type"] = "submenu",
		["menuDataList"] = {
			ACTION_TYPE.Anim,
			ACTION_TYPE.Standstate,
			ACTION_TYPE.Spacer,
			ACTION_TYPE.ResetAnim,
			ACTION_TYPE.ResetStandstate,
		},
	},
	[ACTION_TYPE.AuraMenu] = {
		["name"] = "Aura",
		["type"] = "submenu",
		["menuDataList"] = {
			ACTION_TYPE.SpellAura,
			ACTION_TYPE.ToggleAura,
			ACTION_TYPE.ToggleAuraSelf,
			ACTION_TYPE.Spacer,
			ACTION_TYPE.RemoveAura,
			ACTION_TYPE.RemoveAllAuras,
		},
	},
	[ACTION_TYPE.CastMenu] = {
		["name"] = "Cast",
		["type"] = "submenu",
		["menuDataList"] = {
			ACTION_TYPE.SpellCast,
			ACTION_TYPE.SpellTrig,
		},
	},
	[ACTION_TYPE.EquipmentMenu] = {
		["name"] = "Equipment",
		["type"] = "submenu",
		["menuDataList"] = {
			ACTION_TYPE.AddItem,
			ACTION_TYPE.RemoveItem,
			ACTION_TYPE.Spacer,
			ACTION_TYPE.Equip,
			ACTION_TYPE.EquipSet,
			ACTION_TYPE.MogitEquip,
			ACTION_TYPE.Spacer,
			ACTION_TYPE.Unequip,
		},
	},
	[ACTION_TYPE.SpeedMenu] = {
		["name"] = "Speed",
		["type"] = "submenu",
		["menuDataList"] = {
			ACTION_TYPE.AllSpeedHeader,
			ACTION_TYPE.Speed,
			ACTION_TYPE.SpecificSpeedHeader,
			ACTION_TYPE.SpeedWalk,
			ACTION_TYPE.SpeedBackwalk,
			ACTION_TYPE.SpeedFly,
			ACTION_TYPE.SpeedSwim,
		},
	},
	[ACTION_TYPE.TRP3Menu] = {
		["name"] = "Total RP 3",
		["type"] = "submenu",
		["menuDataList"] = {
			ACTION_TYPE.TRP3ProfileHeader,
			ACTION_TYPE.TRP3Profile,
			ACTION_TYPE.TRP3StatusHeader,
			ACTION_TYPE.TRP3StatusToggle,
			ACTION_TYPE.TRP3StatusIC,
			ACTION_TYPE.TRP3StatusOOC,
		},
		["dependency"] = "totalRP3",
	},
	[ACTION_TYPE.MorphMenu] = {
		["name"] = "Morph",
		["type"] = "submenu",
		["menuDataList"] = {
			ACTION_TYPE.Morph,
			ACTION_TYPE.Native,
			ACTION_TYPE.Spacer,
			ACTION_TYPE.Unmorph,
		},
	},
	[ACTION_TYPE.ARCAPIMenu] = {
		["name"] = "ARC:API",
		["type"] = "submenu",
		["menuDataList"] = {
			ACTION_TYPE.ARCSet,
			ACTION_TYPE.ARCTog,
			ACTION_TYPE.ARCCopy,
		},
	},
	[ACTION_TYPE.ArcMenu] = {
		["name"] = "Arcanum",
		["type"] = "submenu",
		["menuDataList"] = {
			ACTION_TYPE.ArcSpell,
			ACTION_TYPE.ArcCastbar,
			ACTION_TYPE.ArcStopSpells,
		},
	},
	[ACTION_TYPE.Spacer] = {
		["type"] = "spacer",
	},
	[ACTION_TYPE.SpellCast] = {
		["name"] = "Cast Spell", -- The Displayed Name in the UI
		["command"] = "cast @N@", -- The chat command, or Lua function to process
		["description"] = "Cast a spell using a Spell ID, to selected target, or self if no target.", -- Description for on-mouse-over
		["dataName"] = "Spell ID(s)", -- Label for the ID Box, nil to disable the ID box
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\r'.look spell' for IDs.", -- Description of the input for GameTooltip
		["comTarget"] = "server", -- Server for commands, func for custom Lua function in 'command'
		["revert"] = "unaura @N@", -- The command that reverts it, i.e, 'unaura' for 'aura'
		["revertDesc"] = "unaura",
		["selfAble"] = true, -- True/False - if able to use the self-toggle checkbox
	},
	[ACTION_TYPE.SpellTrig] = {
		["name"] = "Cast Spell (Trig)",
		["command"] = "cast @N@ trig",
		["description"] = "Cast a spell using a Spell ID, to selected target, or self if no target, using the triggered flag.",
		["dataName"] = "Spell ID(s)",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\r'.look spell' for IDs.",
		["comTarget"] = "server",
		["revert"] = "unaura @N@",
		["revertDesc"] = "unaura",
		["selfAble"] = true,
	},
	[ACTION_TYPE.SpellAura] = {
		["name"] = "Apply Aura",
		["command"] = "aura @N@",
		["description"] = "Applies an Aura from a Spell ID on your target if able, or yourself otherwise.",
		["dataName"] = "Spell ID(s)",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to apply multiple auras at once.\n\r'.look spell' for IDs.",
		["comTarget"] = "server",
		["revert"] = "unaura @N@",
		["revertDesc"] = "unaura",
		["selfAble"] = true,
	},
	[ACTION_TYPE.ToggleAura] = {
		["name"] = "Toggle Aura",
		["command"] = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID) else cmd("aura "
			.. spellID) end end,
		["description"] = "Toggles an Aura on / off.\n\rApplies to your target if you have Phase DM on & Officer+",
		["dataName"] = "Spell ID",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\r'.look spell' for IDs.",
		["comTarget"] = "func",
		["revert"] = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID) else cmd("aura "
			.. spellID) end end,
		["revertDesc"] = "Toggles the Aura again",
	},
	[ACTION_TYPE.ToggleAuraSelf] = {
		["name"] = "Toggle Aura (Self)",
		["command"] = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID .. " self") else cmd("aura "
			.. spellID .. " self") end end,
		["description"] = "Toggles an Aura on / off.\n\rAlways applies on yourself.",
		["dataName"] = "Spell ID",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\r'.look spell' for IDs.",
		["comTarget"] = "func",
		["revert"] = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura " .. spellID .. " self") else cmd("aura "
			.. spellID .. " self") end end,
		["revertDesc"] = "Toggles the Aura again",
	},
	[ACTION_TYPE.Anim] = {
		["name"] = "Emote/Anim",
		["command"] = "mod anim @N@",
		["description"] = "Modifies target's current animation using 'mod anim'.\n\rUse .lookup emote to find IDs.",
		["dataName"] = "Emote ID",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to do multiple anims at once -- but the second usually over-rides the first anyways.\n\r'.look emote' for IDs.",
		["comTarget"] = "server",
		["revert"] = "mod anim 0",
		["revertDesc"] = "Reset to Anim 0 (none)",
		["selfAble"] = false,
	},
	[ACTION_TYPE.ResetAnim] = {
		["name"] = "Reset Emote/Anim",
		["command"] = "mod anim 0",
		["description"] = "Reset target's current animation to Anim 0 (none).",
		["dataName"] = nil,
		["comTarget"] = "server",
		["revert"] = nil,
		["revertAlternative"] = "another emote action",
	},
	[ACTION_TYPE.ResetStandstate] = {
		["name"] = "Reset Standstate",
		["command"] = "mod stand 0",
		["description"] = "Reset the Standstate of your character to 0 (none).",
		["dataName"] = nil,
		["comTarget"] = "server",
		["revert"] = nil,
		["revertAlternative"] = "another emote action",
	},
	[ACTION_TYPE.Morph] = {
		["name"] = "Morph",
		["command"] = "morph @N@",
		["description"] = "Morph into a Display ID.",
		["dataName"] = "Display ID",
		["inputDescription"] = "No, you can't put multiple to become a hybrid monster..\n\r'.look displayid' for IDs.",
		["comTarget"] = "server",
		["revert"] = "demorph",
		["revertDesc"] = "demorph",
		["selfAble"] = false,
	},
	[ACTION_TYPE.Native] = {
		["name"] = "Native",
		["command"] = "mod native @N@",
		["description"] = "Modifies your Native to specified Display ID.",
		["dataName"] = "Display ID",
		["inputDescription"] = ".look displayid' for IDs.",
		["comTarget"] = "server",
		["revert"] = "demorph",
		["revertDesc"] = "demorph",
		["selfAble"] = false,
	},
	[ACTION_TYPE.Standstate] = {
		["name"] = "Standstate",
		["command"] = "mod standstate @N@",
		["description"] = "Change the emote of your character while standing to an Emote ID.",
		["dataName"] = "Standstate ID",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to set multiple standstates at once.. but you can't have two, so probably don't try it.\n\r'.look emote' for IDs.",
		["comTarget"] = "server",
		["revert"] = "mod stand 0",
		["revertDesc"] = "Set Standstate to 0 (none)",
		["selfAble"] = false,
	},
	[ACTION_TYPE.Equip] = {
		["name"] = "Equip Item",
		["command"] = function(vars) EquipItemByName(vars) end,
		["description"] = "Equip an Item by name or ID. Item must be in your inventory.\n\rName is a search in your inventory by keyword - using ID is recommended.\n\rEX: You want to equip 'Violet Guardian's Helm', ID: 141357, but have 'Guardian's Leather Belt', ID: 35156 in your inventory also, using 'Guardian' as the text will equip the belt, so you'll want to use the full name, or better off just use the actual item ID.",
		["dataName"] = "Item ID or Name(s)",
		["inputDescription"] = "Accepts multiple IDs/Names, separated by commas, to equip multiple items at once.\n\r'.look item', or mouse-over an item in your inventory for IDs.",
		["comTarget"] = "func",
		["revert"] = nil,
		["revertAlternative"] = "a separate unequip item action",
		["selfAble"] = false,
	},
	[ACTION_TYPE.AddItem] = {
		["name"] = "Add Item",
		["command"] = "additem @N@",
		["description"] = "Add an item to your inventory.\n\rYou may specify multiple items separated by commas, and may specify item count & bonusID per item as well.\n\rEx: '125775 1 449, 125192 1 449' will add 1 of each item with Heroic (449) tier.",
		["dataName"] = "Item ID(s)",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to add multiple items at once.\n\r'.look item', or mouse-over an item in your inventory for IDs.",
		["comTarget"] = "server",
		["revert"] = nil,
		["revertAlternative"] = "a separate remove item action",
		["selfAble"] = false,
	},
	[ACTION_TYPE.RemoveItem] = {
		["name"] = "Remove Item",
		["command"] = "additem @N@ -1",
		["description"] = "Remove an item from your inventory.\n\rYou may specify multiple items separated by commas, and may optionally specify item count as a negative number to remove that many of the item.\n\rEx: '125775 -10' to remove 10 of that item.",
		["dataName"] = "Item ID(s)",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to remove multiple items at once.\n\r'.look item', or mouse-over an item in your inventory for IDs.",
		["comTarget"] = "server",
		["revert"] = nil,
		["revertAlternative"] = "a separate add item action",
		["selfAble"] = false,
	},
	[ACTION_TYPE.RemoveAura] = {
		["name"] = "Remove Aura",
		["command"] = "unaura @N@",
		["description"] = "Remove an Aura by Spell ID.",
		["dataName"] = "Spell ID(s)",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to remove multiple auras at once.",
		["comTarget"] = "server",
		["revert"] = "aura",
		["revertDesc"] = "Reapplies the same aura",
		["selfAble"] = true,
	},
	[ACTION_TYPE.RemoveAllAuras] = {
		["name"] = "Remove All Auras",
		["command"] = "unaura all",
		["description"] = "Remove all Auras.",
		["dataName"] = nil,
		["comTarget"] = "server",
		["revert"] = nil,
		["revertAlternative"] = "another aura/cast action",
		["selfAble"] = true,
	},
	[ACTION_TYPE.Unmorph] = {
		["name"] = "Remove Morph",
		["command"] = "demorph",
		["description"] = "Remove all morphs, including natives.",
		["dataName"] = nil,
		["comTarget"] = "server",
		["revert"] = nil,
		["revertAlternative"] = "another morph/native action",
	},
	[ACTION_TYPE.Unequip] = {
		["name"] = "Unequip Item",
		["command"] = function(slotID) PickupInventoryItem(slotID); PutItemInBackpack(); end,
		["description"] = "Unequips an item by item slot.\n\rCommon IDs:\rHead: 1          Shoulders: 2\rShirt: 4          Chest: 5\rWaist: 6         Legs 6\rFeet: 8           Wrist: 9\rHands: 10       Back: 15\rRanged: 18      Tabard: 19\rMain-hand: 16\rOff-hand: 17",
		["dataName"] = "Item Slot ID(s)",
		["inputDescription"] = "Common IDs:\rHead: 1          Shoulders: 2\rShirt: 4           Chest: 5\rWaist: 6         Legs 6\rFeet: 8            Wrist: 9\rHands: 10       Back: 15\rRanged: 18      Tabard: 19\rMain-hand: 16\rOff-hand: 17\n\rAccepts multiple slot ID's, separated by commas, to remove multiple slots at the same time.",
		["comTarget"] = "func",
		["revert"] = nil,
		["revertAlternative"] = "a eparate Equip Item action",
	},
	[ACTION_TYPE.TRP3Profile] = {
		["name"] = "TRP3 Profile",
		["command"] = function(profile) SlashCmdList.TOTALRP3("profile " .. profile) end,
		["description"] = "Change the active Total RP profile to the profile with the specified name.",
		["dataName"] = "Profile name",
		["inputDescription"] = "The name of the profile as it appears in Total RP's profile list.",
		["comTarget"] = "func",
		["revert"] = nil,
		["selfAble"] = false,
		["dependency"] = "totalRP3",
	},
	[ACTION_TYPE.TRP3StatusToggle] = {
		["name"] = "TRP3: IC/OOC",
		["command"] = function() SlashCmdList.TOTALRP3("status toggle") end,
		["description"] = "Switch your Total RP 3 status to the opposite state.",
		["dataName"] = nil,
		["comTarget"] = "func",
		["revert"] = nil,
		["selfAble"] = false,
		["dependency"] = "totalRP3",
	},
	[ACTION_TYPE.TRP3StatusIC] = {
		["name"] = "TRP3: IC",
		["command"] = function() SlashCmdList.TOTALRP3("status ic") end,
		["description"] = "Set your Total RP 3 status to IC.",
		["dataName"] = nil,
		["comTarget"] = "func",
		["revert"] = nil,
		["selfAble"] = false,
		["dependency"] = "totalRP3",
	},
	[ACTION_TYPE.TRP3StatusOOC] = {
		["name"] = "TRP3: OOC",
		["command"] = function() SlashCmdList.TOTALRP3("status ooc") end,
		["description"] = "Set your Total RP 3 status to OOC.",
		["dataName"] = nil,
		["comTarget"] = "func",
		["revert"] = nil,
		["selfAble"] = false,
		["dependency"] = "totalRP3",
	},
	[ACTION_TYPE.Scale] = {
		["name"] = "Scale",
		["command"] = "mod scale @N@",
		["description"] = "Modifies size using 'mod scale'.\n\rApplies to self if no target is selected.",
		["dataName"] = "Scale",
		["inputDescription"] = "Value may range from 0.1 to 10.",
		["comTarget"] = "server",
		["revert"] = "mod scale 1",
		["revertDesc"] = "Reset to scale 1",
		["selfAble"] = false,
	},
	[ACTION_TYPE.Speed] = {
		["name"] = "Speed",
		["command"] = "mod speed @N@",
		["description"] = "Modifies movement speed using 'mod speed'.\n\rApplies to self if no target is selected.",
		["dataName"] = "Speed",
		["inputDescription"] = "Value may range from 0.1 to 50.",
		["comTarget"] = "server",
		["revert"] = "mod speed 1",
		["revertDesc"] = "Reset to speed 1",
		["selfAble"] = false,
	},
	[ACTION_TYPE.SpeedBackwalk] = {
		["name"] = "Walk Speed (Back)",
		["command"] = "mod speed backwalk @N@",
		["description"] = "Modifies speed of walking backwards.\n\rApplies to self if no target is selected.",
		["dataName"] = "Speed",
		["inputDescription"] = "Value may range from 0.1 to 50.",
		["comTarget"] = "server",
		["revert"] = "mod speed backwalk 1",
		["revertDesc"] = "Reset to backwalk speed 1",
		["selfAble"] = false,
	},
	[ACTION_TYPE.SpeedFly] = {
		["name"] = "Fly Speed",
		["command"] = "mod speed fly @N@",
		["description"] = "Modifies flying speed.\n\rApplies to self if no target is selected.",
		["dataName"] = "Speed",
		["inputDescription"] = "Value may range from 0.1 to 50.",
		["comTarget"] = "server",
		["revert"] = "mod speed fly 1",
		["revertDesc"] = "Reset to fly speed 1",
		["selfAble"] = false,
	},
	[ACTION_TYPE.SpeedWalk] = {
		["name"] = "Walk Speed",
		["command"] = "mod speed walk @N@",
		["description"] = "Modifies walking speed.\n\rApplies to self if no target is selected.",
		["dataName"] = "Speed",
		["inputDescription"] = "Value may range from 0.1 to 50.",
		["comTarget"] = "server",
		["revert"] = "mod speed walk 1",
		["revertDesc"] = "Reset to walk speed 1",
		["selfAble"] = false,
	},
	[ACTION_TYPE.SpeedSwim] = {
		["name"] = "Swim Speed",
		["command"] = "mod speed swim @N@",
		["description"] = "Modifies swimming speed.\n\rApplies to self if no target is selected.",
		["dataName"] = "Speed",
		["inputDescription"] = "Value may range from 0.1 to 50.",
		["comTarget"] = "server",
		["revert"] = "mod speed swim 1",
		["revertDesc"] = "Reset to swim speed 1",
		["selfAble"] = false,
	},
	-- [ACTION_TYPE.DefaultEmote] = {
	-- 	["name"] = "Default Emote",
	-- 	["command"] = function(emoteID) DoEmote(string.upper(emoteID)); end,
	-- 	["description"] = "Any default emote.\n\rMust be a valid emote 'token', i.e., 'WAVE'\n\rGoogle 'WoWpedia DoEmote' for a full list - most match their /command, but some don't.",
	-- 	["dataName"] = "Emote Token",
	-- 	["inputDescription"] = "Usually just the text from the /command, i.e., /wave = wave.\n\rIf not working: Search Google for 'WoWpedia DoEmote', and go to the WoWpedia page, and find the table of tokens - some don't exactly match their command.",
	-- 	["comTarget"] = "func",
	-- 	["revert"] = nil,
	-- },
	[ACTION_TYPE.MacroText] = {
		["name"] = "Macro Script",
		["command"] = function(command) runMacroText(command); end,
		["description"] = "Any line that can be processed in a macro (any slash commands & macro flags).\n\rYou can use this for pretty much ANYTHING, technically, including custom short Lua scripts.",
		["dataName"] = "/command",
		["inputDescription"] = "Any /commands that can be processed in a macro-script, including emotes, addon commands, Lua run scripts, etc.\n\rI.e., '/emote begins to conjur up a fireball in their hand.'\n\rYou can use any part of the ARC:API here as well. Use /arc for more info.",
		["comTarget"] = "func",
		["revert"] = nil,
		["doNotDelimit"] = true,
	},
	[ACTION_TYPE.Command] = {
		["name"] = "Server .Command",
		["command"] = cmdWithDotCheck,
		["description"] = "Any other server command.\n\rType the full command you want, without the dot, in the input box.",
		["dataName"] = "Full Command",
		["inputDescription"] = "You can use any server command here, without the '.', and it will run after the delay.\n\rDoes NOT accept comma separated multi-actions.",
		["example"] = "mod drunk 100",
		["comTarget"] = "func",
		["revert"] = nil,
		["doNotDelimit"] = true,
	},
	[ACTION_TYPE.MogitEquip] = {
		["name"] = "Equip Mogit Set",
		["command"] = function(vars) SlashCmdList["MOGITE"](vars); end,
		["description"] = "Equip a saved Mogit Wishlist set.\n\rMust specify the character name (profile) it's saved under first, then the set name.",
		["dataName"] = "Profile & Set",
		["inputDescription"] = "The Mogit Profile, and set name, just as if using the /moge chat command.\n\rExample: " ..
			GetUnitName("player", false) .. " Cool Armor Set 1",
		["comTarget"] = "func",
		["revert"] = nil,
		["dependency"] = "MogIt",
	},
	[ACTION_TYPE.EquipSet] = {
		["name"] = "Equip Set",
		["command"] = function(vars) C_EquipmentSet.UseEquipmentSet(C_EquipmentSet.GetEquipmentSetID(vars)) end,
		["description"] = "Equip a saved set from Blizzard's Equipment Manager, by name.",
		["dataName"] = "Set Name",
		["inputDescription"] = "Set name from Equipment Manager (Blizzard's built in set manager).",
		["comTarget"] = "func",
		["revert"] = nil,
		["revertAlternative"] = "a series of unequip actions",
	},
	[ACTION_TYPE.ArcSpell] = {
		["name"] = "Arc Spell",
		["command"] = function(commID)
			if not SpellCreatorSavedSpells[commID] then
				cprint("No spell with command '"..commID.."' found in your Personal Vault.")
				return
			end
			ns.Actions.Execute.executeSpell(SpellCreatorSavedSpells[commID].actions, nil, SpellCreatorSavedSpells[commID].fullName, SpellCreatorSavedSpells[commID])
		end,
		["description"] = "Cast another Arcanum Spell from your Personal Vault.",
		["dataName"] = "Spell Command",
		["inputDescription"] = "The command ID (commID) used to cast the ArcSpell\n\rExample: From '/sf MySpell', input just MySpell as this input.",
		["comTarget"] = "func",
		["revert"] = nil,
	},
	[ACTION_TYPE.ArcCastbar] = {
		["name"] = "Castbar",
		["command"] = function(data)
			local length, text, iconPath, channeled, showIcon, showShield = strsplit(",",data,6)
			if length then length = strtrim(length) end
			if text then text = strtrim(text) end
			if iconPath then iconPath = {["icon"] = strtrim(iconPath)} end
			if channeled then channeled = ns.Utils.Data.toboolean(strtrim(channeled)) end
			if showIcon then showIcon = ns.Utils.Data.toboolean(strtrim(showIcon)) end
			if showShield then showShield = ns.Utils.Data.toboolean(strtrim(showShield)) end
			ns.UI.Castbar.showCastBar(length, text, iconPath, channeled, showIcon, showShield)
		end,
		["description"] = "Show a custom Arcanum Castbar with your own settings & duration.",
		["dataName"] = "Castbar Settings",
		["inputDescription"] = "Syntax: duration, [title, [iconPath/FileID, [channeled (true/false), [showIcon (true/false), [showShield (true/false)]]]]]\n\rDuration is the only required input.",
		["comTarget"] = "func",
		["revert"] = nil,
		["doNotDelimit"] = true,
	},
	[ACTION_TYPE.ArcStopSpells] = {
		["name"] = "Stop ArcSpells",
		["command"] = function() ns.Actions.Execute.stopRunningActions() end,
		["description"] = "Stops all currently running ArcSpells - including this spell if called on a delay.\n\rUse it as the first action with a delay of 0 if you want to cancel any other running ArcSpells before you cast this spell.",
		["comTarget"] = "func",
		["revert"] = nil,
	},
	[ACTION_TYPE.ARCSet] = {
		["name"] = "Set Variable",
		["command"] = function(data)
			local var, val = strsplit("|", data, 2);
			var = strtrim(var, " \t\r\n\124");
			val = strtrim(val, " \t\r\n\124");
			ARC:SET(var, val);
		end,
		["description"] = "Set an ARCVAR to a specific value.",
		["dataName"] = "VarName | Value",
		["inputDescription"] = "Provide the variable name & the value to set it as, separated by a | character.",
		["comTarget"] = "func",
		["revert"] = nil,
		["revertAlternative"] = "another Set Variable action",
	},
	[ACTION_TYPE.ARCTog] = {
		["name"] = "Toggle Variable",
		["command"] = function(var) ARC:TOG(var) end,
		["description"] = "Toggle an ARCVAR, like a light switch.",
		["dataName"] = "Variable Name",
		["inputDescription"] = "The variable name to toggle.",
		["comTarget"] = "func",
		["revert"] = function(var) ARC:TOG(var) end,
		["revertDesc"] = "Toggles the ARCVAR again.",
	},
	[ACTION_TYPE.ARCCopy] = {
		["name"] = "Copy Text/URL",
		["command"] = function(text) ARC:COPY(text) end,
		["description"] = "Open a dialog box to copy the given text (i.e., a URL).",
		["dataName"] = "Text / URL",
		["inputDescription"] = "The text / link / URL to copy.",
		["comTarget"] = "func",
		["revert"] = nil,
	},
}

---@class Actions_Data
ns.Actions.Data = {
	actionTypeDataList = actionTypeDataList,
	actionTypeData = actionTypeData,
}
