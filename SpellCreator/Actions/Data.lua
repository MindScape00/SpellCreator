---@class ns
local ns = select(2, ...)

local Aura = ns.Utils.Aura
local cmd, cmdWithDotCheck = ns.Cmd.cmd, ns.Cmd.cmdWithDotCheck
local runMacroText = ns.Cmd.runMacroText

local actionTypeDataList = { -- formatted for easier sorting - whatever order they are here is the order they show up in dropdown as.
	"SpellHeader",
	"AuraMenu",
	"CastMenu",
	"MorphMenu",
	"CharacterHeader",
	"AnimationMenu",
	"EquipmentMenu",
	"SpeedMenu",
	"TRP3Menu",
	"RunHeader",
	"MacroText",
	"Command",
	"ARCAPIMenu",
	"ArcSpell",
}

local actionTypeData = {
	["SpellHeader"] = {
		["name"] = "Spells and effects",
		["type"] = "header",
	},
	["CharacterHeader"] = {
		["name"] = "Character",
		["type"] = "header",
	},
	["RunHeader"] = {
		["name"] = "Run",
		["type"] = "header",
	},
	["AllSpeedHeader"] = {
		["name"] = "All types",
		["type"] = "header",
	},
	["SpecificSpeedHeader"] = {
		["name"] = "Per mode",
		["type"] = "header",
	},
	["TRP3ProfileHeader"] = {
		["name"] = "Profile",
		["type"] = "header",
	},
	["TRP3StatusHeader"] = {
		["name"] = "Status",
		["type"] = "header",
	},
	["AnimationMenu"] = {
		["name"] = "Animation",
		["type"] = "submenu",
		["menuDataList"] = {
			"Anim",
			"Standstate",
			"Spacer",
			"ResetAnim",
			"ResetStandstate",
		},
	},
	["AuraMenu"] = {
		["name"] = "Aura",
		["type"] = "submenu",
		["menuDataList"] = {
			"SpellAura",
			"ToggleAura",
			"ToggleAuraSelf",
			"Spacer",
			"RemoveAura",
			"RemoveAllAuras",
		},
	},
	["CastMenu"] = {
		["name"] = "Cast",
		["type"] = "submenu",
		["menuDataList"] = {
			"SpellCast",
			"SpellTrig",
		},
	},
	["EquipmentMenu"] = {
		["name"] = "Equipment",
		["type"] = "submenu",
		["menuDataList"] = {
			"Equip",
			"EquipSet",
			"MogitEquip",
			"Spacer",
			"Unequip",
		},
	},
	["SpeedMenu"] = {
		["name"] = "Speed",
		["type"] = "submenu",
		["menuDataList"] = {
			"AllSpeedHeader",
			"Speed",
			"SpecificSpeedHeader",
			"SpeedWalk",
			"SpeedBackwalk",
			"SpeedFly",
			"SpeedSwim",
		},
	},
	["TRP3Menu"] = {
		["name"] = "Total RP 3",
		["type"] = "submenu",
		["menuDataList"] = {
			"TRP3ProfileHeader",
			"TRP3Profile",
			"TRP3StatusHeader",
			"TRP3StatusToggle",
			"TRP3StatusIC",
			"TRP3StatusOOC",
		},
	},
	["MorphMenu"] = {
		["name"] = "Morph",
		["type"] = "submenu",
		["menuDataList"] = {
			"Morph",
			"Native",
			"Spacer",
			"Unmorph",
		},
	},
	["ARCAPIMenu"] = {
		["name"] = "ARC:API",
		["type"] = "submenu",
		["menuDataList"] = {
			"ARCSet",
			"ARCTog",
			"ARCCopy",
		},
	},
	["Spacer"] = {
		["type"] = "spacer",
	},
	["SpellCast"] = {
		["name"] = "Cast Spell",							-- The Displayed Name in the UI
		["command"] = "cast @N@", 								-- The chat command, or Lua function to process
		["description"] = "Cast a spell using a Spell ID, to selected target, or self if no target.\n\rEnable the 'Self' checkbox to cast always on yourself.\n\rRevert: Unaura", 	-- Description for on-mouse-over
		["dataName"] = "Spell ID(s)", 							-- Label for the ID Box, nil to disable the ID box
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\r'.look spell' for IDs.",							-- Description of the input for GameTooltip
		["comTarget"] = "server", 							-- Server for commands, func for custom Lua function in 'command'
		["revert"] = "unaura @N@", 									-- The command that reverts it, i.e, 'unaura' for 'aura'
		["selfAble"] = true,								-- True/False - if able to use the self-toggle checkbox
		},
	["SpellTrig"] = {
		["name"] = "Cast Spell (Trig)",
		["command"] = "cast @N@ trig",
		["description"] = "Cast a spell using a Spell ID, to selected target, or self if no target, using the triggered flag.\n\rEnable the 'Self' checkbox to cast always on yourself.\n\rRevert: Unaura",
		["dataName"] = "Spell ID(s)",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\r'.look spell' for IDs.",
		["comTarget"] = "server",
		["revert"] = "unaura @N@",
		["selfAble"] = true,
		},
	["SpellAura"] = {
		["name"] = "Apply Aura",
		["command"] = "aura @N@",
		["description"] = "Applies an Aura from a Spell ID on your target if able, or yourself otherwise.\n\rEnable the 'Self' checkbox to always aura yourself.\n\rRevert: Unaura",
		["dataName"] = "Spell ID(s)",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to apply multiple auras at once.\n\r'.look spell' for IDs.",
		["comTarget"] = "server",
		["revert"] = "unaura @N@",
		["selfAble"] = true,
		},
	["ToggleAura"] = {
		["name"] = "Toggle Aura",
		["command"] = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura "..spellID) else cmd("aura "..spellID) end; end,
		["description"] = "Toggles an Aura on / off.\n\rApplies to your target if you have Phase DM on & Officer+\n\rRevert: Toggles the Aura again.",
		["dataName"] = "Spell ID",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\r'.look spell' for IDs.",
		["comTarget"] = "func",
		["revert"] = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura "..spellID) else cmd("aura "..spellID) end; end,
	},
	["ToggleAuraSelf"] = {
		["name"] = "Toggle Aura (Self)",
		["command"] = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura "..spellID.." self") else cmd("aura "..spellID.." self") end; end,
		["description"] = "Toggles an Aura on / off\n\rApples on yourself.\n\rRevert: Toggles the Aura again.",
		["dataName"] = "Spell ID",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\r'.look spell' for IDs.",
		["comTarget"] = "func",
		["revert"] = function(spellID) if Aura.checkForAuraID(tonumber(spellID)) then cmd("unaura "..spellID.." self") else cmd("aura "..spellID.." self") end; end,
	},
	["Anim"] = {
		["name"] = "Emote/Anim",
		["command"] = "mod anim @N@",
		["description"] = "Modifies target's current animation using 'mod anim'.\n\rUse .lookup emote to find IDs.\n\rRevert: Reset to Anim 0 (none)",
		["dataName"] = "Emote ID",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to do multiple anims at once -- but the second usually over-rides the first anyways.\n\r'.look emote' for IDs.",
		["comTarget"] = "server",
		["revert"] = "mod anim 0",
		["selfAble"] = false,
	},
	["ResetAnim"] = {
		["name"] = "Reset Emote/Anim",
		["command"] = "mod anim 0",
		["description"] = "Reset target's current animation to Anim 0 (none).\n\rCannot be reverted directly, use another emote action.",
		["dataName"] = nil,
		["comTarget"] = "server",
		["revert"] = nil,
	},
	["ResetStandstate"] = {
		["name"] = "Reset Standstate",
		["command"] = "mod stand 0",
		["description"] = "Reset the Standstate of your character to 0 (none).\n\rCannot be reverted directly, use another emote action.",
		["dataName"] = nil,
		["comTarget"] = "server",
		["revert"] = nil,
	},
	["Morph"] = {
		["name"] = "Morph",
		["command"] = "morph @N@",
		["description"] = "Morph into a Display ID.\n\rRevert: Demorph",
		["dataName"] = "Display ID",
		["inputDescription"] = "No, you can't put multiple to become a hybrid monster..\n\r'.look displayid' for IDs.",
		["comTarget"] = "server",
		["revert"] = "demorph",
		["selfAble"] = false,
		},
	["Native"] = {
		["name"] = "Native",
		["command"] = "mod native @N@",
		["description"] = "Modifies your Native to specified Display ID.\n\rRevert: Demorph",
		["dataName"] = "Display ID",
		["inputDescription"] = ".look displayid' for IDs.",
		["comTarget"] = "server",
		["revert"] = "demorph",
		["selfAble"] = false,
		},
	["Standstate"] = {
		["name"] = "Standstate",
		["command"] = "mod standstate @N@",
		["description"] = "Change the emote of your character while standing to an Emote ID.\n\rRevert: Standstate to 0 (none)",
		["dataName"] = "Standstate ID",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to set multiple standstates at once.. but you can't have two, so probably don't try it.\n\r'.look emote' for IDs.",
		["comTarget"] = "server",
		["revert"] = "mod stand 0",
		["selfAble"] = true,
		},
	["Equip"] = {
		["name"] = "Equip Item",
		["command"] = function(vars) EquipItemByName(vars) end,
		["description"] = "Equip an Item by name or ID. Item must be in your inventory.\n\rName is a search in your inventory by keyword - using ID is recommended.\n\ri.e., You want to equip 'Violet Guardian's Helm', ID: 141357, but have 'Guardian's Leather Belt', ID: 35156 in your inventory also, using 'Guardian' as the text will equip the belt, so you'll want to use the full name, or better off just use the actual item ID.\n\rCannot be reverted directly, use a separate unequip item action.",
		["dataName"] = "Item ID or Name(s)",
		["inputDescription"] = "Accepts multiple IDs/Names, separated by commas, to equip multiple items at once.\n\r'.look item', or mouse-over an item in your inventory for IDs.",
		["comTarget"] = "func",
		["revert"] = nil,
		["selfAble"] = false,
		},
	["RemoveAura"] = {
		["name"] = "Remove Aura",
		["command"] = "unaura @N@",
		["description"] = "Remove an Aura by Spell ID.\n\rRevert: Re-applies the same aura after the delay.",
		["dataName"] = "Spell ID(s)",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to remove multiple auras at once.",
		["comTarget"] = "server",
		["revert"] = "aura",
		["selfAble"] = true,
		},
	["RemoveAllAuras"] = {
		["name"] = "Remove All Auras",
		["command"] = "unaura all",
		["description"] = "Remove all Auras.\n\rCannot be reverted directly, use another aura/cast action.",
		["dataName"] = nil,
		["comTarget"] = "server",
		["revert"] = nil,
		["selfAble"] = true,
		},
	["Unmorph"] = {
		["name"] = "Remove Morph",
		["command"] = "demorph",
		["description"] = "Remove all morphs, including natives.\n\rCannot be reverted directly, use another morph/native action.",
		["dataName"] = nil,
		["comTarget"] = "server",
		["revert"] = nil,
		},
	["Unequip"] = {
		["name"] = "Unequip Item",
		["command"] = function(slotID) PickupInventoryItem(slotID); PutItemInBackpack(); end,
		["description"] = "Unequips an item by item slot.\n\rCommon IDs:\rHead: 1          Shoulders: 2\rShirt: 4          Chest: 5\rWaist: 6         Legs 6\rFeet: 8           Wrist: 9\rHands: 10       Back: 15\rRanged: 18      Tabard: 19\rMain-hand: 16\rOff-hand: 17\n\rCannot be reverted directly, use Equip.",
		["dataName"] = "Item Slot ID(s)",
		["inputDescription"] = "Common IDs:\rHead: 1          Shoulders: 2\rShirt: 4           Chest: 5\rWaist: 6         Legs 6\rFeet: 8            Wrist: 9\rHands: 10       Back: 15\rRanged: 18      Tabard: 19\rMain-hand: 16\rOff-hand: 17\n\rAccepts multiple slot ID's, separated by commas, to remove multiple slots at the same time.",
		["comTarget"] = "func",
		["revert"] = nil,
		},
	["TRP3Profile"] = {
		["name"] = "TRP3 Profile",
		["command"] = function(profile) SlashCmdList.TOTALRP3("profile " .. profile) end,
		["description"] = "Change the active Total RP profile to the profile with the specified name.",
		["dataName"] = "Profile name",
		["inputDescription"] = "The name of the profile as it appears in Total RP's profile list.",
		["comTarget"] = "func",
		["revert"] = nil,
		["selfAble"] = false,
	},
	["TRP3StatusToggle"] = {
		["name"] = "TRP3: IC/OOC",
		["command"] = function() SlashCmdList.TOTALRP3("status toggle") end,
		["description"] = "Switch your Total RP 3 status to the opposite state.",
		["dataName"] = nil,
		["comTarget"] = "func",
		["revert"] = nil,
		["selfAble"] = false,
	},
	["TRP3StatusIC"] = {
		["name"] = "TRP3: IC",
		["command"] = function() SlashCmdList.TOTALRP3("status ic") end,
		["description"] = "Set your Total RP 3 status to IC.",
		["dataName"] = nil,
		["comTarget"] = "func",
		["revert"] = nil,
		["selfAble"] = false,
	},
	["TRP3StatusOOC"] = {
		["name"] = "TRP3: OOC",
		["command"] = function() SlashCmdList.TOTALRP3("status ooc") end,
		["description"] = "Set your Total RP 3 status to OOC.",
		["dataName"] = nil,
		["comTarget"] = "func",
		["revert"] = nil,
		["selfAble"] = false,
	},
	["Speed"] = {
		["name"] = "Speed",
		["command"] = "mod speed @N@",
		["description"] = "Modifies movement speed using 'mod speed'.\n\rApplies to self if no target is selected.\n\rCannot be reverted directly, use another speed action.",
		["dataName"] = "Speed",
		["inputDescription"] = "Value may range from 0.1 to 50.",
		["comTarget"] = "server",
		["revert"] = nil,
		["selfAble"] = false,
	},
	["SpeedBackwalk"] = {
		["name"] = "Walk Speed (Back)",
		["command"] = "mod speed backwalk @N@",
		["description"] = "Modifies speed of walking backwards.\n\rApplies to self if no target is selected.\n\rCannot be reverted directly, use another speed action.",
		["dataName"] = "Speed",
		["inputDescription"] = "Value may range from 0.1 to 50.",
		["comTarget"] = "server",
		["revert"] = nil,
		["selfAble"] = false,
	},
	["SpeedFly"] = {
		["name"] = "Fly Speed",
		["command"] = "mod speed fly @N@",
		["description"] = "Modifies flying speed.\n\rApplies to self if no target is selected.\n\rCannot be reverted directly, use another speed action.",
		["dataName"] = "Speed",
		["inputDescription"] = "Value may range from 0.1 to 50.",
		["comTarget"] = "server",
		["revert"] = nil,
		["selfAble"] = false,
	},
	["SpeedWalk"] = {
		["name"] = "Walk Speed",
		["command"] = "mod speed walk @N@",
		["description"] = "Modifies walking speed.\n\rApplies to self if no target is selected.\n\rCannot be reverted directly, use another speed action.",
		["dataName"] = "Speed",
		["inputDescription"] = "Value may range from 0.1 to 50.",
		["comTarget"] = "server",
		["revert"] = nil,
		["selfAble"] = false,
	},
	["SpeedSwim"] = {
		["name"] = "Swim Speed",
		["command"] = "mod speed swim @N@",
		["description"] = "Modifies swimming speed.\n\rApplies to self if no target is selected.\n\rCannot be reverted directly, use another speed action.",
		["dataName"] = "Speed",
		["inputDescription"] = "Value may range from 0.1 to 50.",
		["comTarget"] = "server",
		["revert"] = nil,
		["selfAble"] = false,
	},
	["DefaultEmote"] = {
		["name"] = "Default Emote",
		["command"] = function(emoteID) DoEmote(string.upper(emoteID)); end,
		["description"] = "Any default emote.\n\rMust be a valid emote 'token', i.e., 'WAVE'\n\rGoogle 'WoWpedia DoEmote' for a full list - most match their /command, but some don't.",
		["dataName"] = "Emote Token",
		["inputDescription"] = "Usually just the text from the /command, i.e., /wave = wave.\n\rIf not working: Search Google for 'WoWpedia DoEmote', and go to the WoWpedia page, and find the table of tokens - some don't exactly match their command.",
		["comTarget"] = "func",
		["revert"] = nil,
		},
	["MacroText"] = {
		["name"] = "Macro Script",
		["command"] = function(command) runMacroText(command); end,
		["description"] = "Any line that can be processed in a macro (any slash commands & macro flags).\n\rYou can use this for pretty much ANYTHING, technically, including custom short Lua scripts.",
		["dataName"] = "/command",
		["inputDescription"] = "Any /commands that can be processed in a macro-script, including emotes, addon commands, Lua run scripts, etc.\n\rI.e., '/emote begins to conjur up a fireball in their hand.'\n\rYou can use any part of the ARC:API here as well. Use /arc for more info.",
		["comTarget"] = "func",
		["revert"] = nil,
		["doNotDelimit"] = true,
		},
	["Command"] = {
		["name"] = "Server .Command",
		["command"] = cmdWithDotCheck,
		["description"] = "Any other server command.\n\rType the full command you want, without the dot, in the input box.\n\ri.e., 'mod drunk 100'.",
		["dataName"] = "Full Command",
		["inputDescription"] = "You can use any server command here, without the '.', and it will run after the delay.\n\rDoes NOT accept comma separated multi-actions.\n\rExample: 'mod drunk 100'.",
		["comTarget"] = "func",
		["revert"] = nil,
		["doNotDelimit"] = true,
		},
	["MogitEquip"] = {
		["name"] = "Equip Mogit Set",
		["command"] = function(vars) SlashCmdList["MOGITE"](vars); end,
		["description"] = "Equip a saved Mogit Wishlist set.\n\rMust specify the character name (profile) it's saved under first, then the set name.",
		["dataName"] = "Profile & Set",
		["inputDescription"] = "The Mogit Profile, and set name, just as if using the /moge chat command.\n\rExample: "..GetUnitName("player", false).." Cool Armor Set 1",
		["comTarget"] = "func",
		["revert"] = nil,
		},
	["EquipSet"] = {
		["name"] = "Equip Set",
		["command"] = function(vars) C_EquipmentSet.UseEquipmentSet(C_EquipmentSet.GetEquipmentSetID(vars)) end,
		["description"] = "Equip a saved set from Blizzard's Equipment Manager, by name.",
		["dataName"] = "Set Name",
		["inputDescription"] = "Set name from Equipment Manager (Blizzard's built in set manager).",
		["comTarget"] = "func",
		["revert"] = nil,
		},
	["ArcSpell"] = {
		["name"] = "Arcanum Spell",
		["command"] = function(commID) ns.Actions.Execute.executeSpell(SpellCreatorSavedSpells[commID].actions, nil, SpellCreatorSavedSpells[commID].fullName) end,
		["description"] = "Cast another Arcanum Spell from your Personal Vault.",
		["dataName"] = "Spell Command",
		["inputDescription"] = "The command ID (commID) used to cast the ArcSpell\n\rExample: '/sf MySpell', where MySpell is the command ID to input here.",
		["comTarget"] = "func",
		["revert"] = nil,
		},
	["ARCSet"] = {
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
		},
	["ARCTog"] = {
		["name"] = "Toggle Variable",
		["command"] = function(var) ARC:TOG(var) end,
		["description"] = "Toggle an ARCVAR, like a light switch.\n\rRevert: Toggles the variable again.",
		["dataName"] = "Variable Name",
		["inputDescription"] = "The variable name to toggle.",
		["comTarget"] = "func",
		["revert"] = function(var) ARC:TOG(var) end,
		},
	["ARCCopy"] = {
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
