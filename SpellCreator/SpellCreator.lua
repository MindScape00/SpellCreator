-------------------------------------------------------------------------------
-- Simple Chat & Helper Functions
-------------------------------------------------------------------------------

local MYADDON, MyAddOn = ...
local addonVersion, addonAuthor, addonName = GetAddOnMetadata(MYADDON, "Version"), GetAddOnMetadata(MYADDON, "Author"), GetAddOnMetadata(MYADDON, "Title")
local addonColor = "|cff".."ce2eff"
local addonMsgPrefix = "SCFORGE"

C_ChatInfo.RegisterAddonMessagePrefix(addonMsgPrefix)
-- options: 7e1af0 (hard to read) -- 7814ea -- 8a30f1 -- 9632ff

local LibDeflate
if LibStub then
	LibDeflate = LibStub:GetLibrary("LibDeflate")
else
	LibDeflate = require("LibDeflate")
end

local function compressForChat(str)
	str = LibDeflate:CompressDeflate(str, {level = 9})
	str = LibDeflate:EncodeForPrint(str)
	return str;
end

local function decompressForChat(str)
	str = LibDeflate:DecodeForPrint(str)
	str = LibDeflate:DecompressDeflate(str)
	return str;
end
	--- Compress using raw deflate format
	--local compress_deflate = LibDeflate:CompressDeflate(example_input)

	-- decompress
	--local decompress_deflate = LibDeflate:DecompressDeflate(compress_deflate)

local clearSpellOnRowRemoved = false
local vaultStyle = 2	-- 1 = pop-up window, 2 = attached tray

sfCmd_ReplacerChar = "@N@"

-- local utils = Epsilon.utils
-- local messages = utils.messages
-- local server = utils.server
-- local tabs = utils.tabs

-- local main = Epsilon.main

local function cmd(text)
  SendChatMessage("."..text, "GUILD");
end

local function cmdNoDot(text)
  SendChatMessage(text, "GUILD");
end

local function sendchat(text)
  SendChatMessage(text, "SAY");
end

local function cprint(text)
	print(addonColor..addonName..": "..(text and text or "ERROR").."|r")
end

local function dprint(force, text, rest)
	local line = strmatch(debugstack(2),":(%d+):")
	if text then
		if force == true or SpellCreatorMasterTable.Options["debug"] then
			if line then
				print(addonColor..addonName.." DEBUG "..line..": "..text..(rest and " | "..rest or "").." |r")
			else
				print(addonColor..addonName.." DEBUG: "..text..(rest and " | "..rest or "").." |r")
				print(debugstack(2))
			end
		end
	elseif SpellCreatorMasterTable.Options["debug"] then
		if line then
			print(addonColor..addonName.." DEBUG "..line..": "..force.." |r")
		else
			print(addonColor..addonName.." DEBUG: "..force.." |r")
			print(debugstack(2))
		end
	end
end

local function eprint(text,rest)
	local line = strmatch(debugstack(2),":(%d+):")
	if line then
		print(addonColor..addonName.." Error @ "..line..": "..text.." | "..(rest and " | "..rest or "").." |r")
	else
		print(addonColor..addonName.." @ ERROR: "..text.." | "..rest.." |r")
		print(debugstack(2))
	end
end

local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function get_keys(t)
	local keys={}
	for key,_ in pairs(t) do
		table.insert(keys, key)
	end
	return keys
end

local function orderedPairs (t, f) -- get keys & sort them - default sort is alphabetically
	local keys = {}
	for k in pairs(t) do keys[#keys+1] = k end
	table.sort(keys, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if keys[i] == nil then return nil
		else return keys[i], t[keys[i]]
		end
	end
	return iter
end

-------------------------------------------------------------------------------
-- Saved Variable Initialization
-------------------------------------------------------------------------------

local function isNotDefined(s)
	return s == nil or s == '';
end

local function SC_loadMasterTable()
	if not SpellCreatorMasterTable then SpellCreatorMasterTable = {} end
	if not SpellCreatorMasterTable.Options then SpellCreatorMasterTable.Options = {} end
	if isNotDefined(SpellCreatorMasterTable.Options["debug"]) then SpellCreatorMasterTable.Options["debug"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["locked"]) then SpellCreatorMasterTable.Options["locked"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["minimapIcon"]) then SpellCreatorMasterTable.Options["minimapIcon"] = true end
	if isNotDefined(SpellCreatorMasterTable.Options["mmLoc"]) then SpellCreatorMasterTable.Options["mmLoc"] = 2.7 end
	if isNotDefined(SpellCreatorMasterTable.Options["fadePanel"]) then SpellCreatorMasterTable.Options["fadePanel"] = true end
	if isNotDefined(SpellCreatorMasterTable.Options["showTooltips"]) then SpellCreatorMasterTable.Options["showTooltips"] = true end
	
	if not SpellCreatorSavedSpells then SpellCreatorSavedSpells = {} end
end

-------------------------------------------------------------------------------
-- UI Stuff
-------------------------------------------------------------------------------

local frameIconOptions = {
"interface/icons/70_professions_scroll_01",
"interface/icons/70_professions_scroll_02",
"interface/icons/70_professions_scroll_03",
"interface/icons/inv_inscription_80_scroll",
"interface/icons/inv_inscription_80_warscroll_battleshout",
"interface/icons/inv_inscription_80_warscroll_fortitude",
"interface/icons/inv_inscription_80_warscroll_intellect",
"interface/icons/inv_inscription_runescrolloffortitude_blue",
"interface/icons/inv_inscription_runescrolloffortitude_green",
"interface/icons/inv_inscription_runescrolloffortitude_red",
"interface/icons/inv_inscription_runescrolloffortitude_yellow",
"interface/icons/inv_misc_enchantedscroll",
"interface/icons/inv_misc_scrollrolled02d",
"interface/icons/inv_misc_scrollrolled02c",
"interface/icons/inv_misc_scrollrolled03d",
"interface/icons/inv_misc_scrollunrolled02d",
"interface/icons/inv_misc_scrollunrolled03d",
"interface/icons/inv_scroll_11",
"interface/icons/trade_archaeology_highborne_scroll",
--"interface/icons/inv_inscription_talenttome01", --oops, this is 9.0.1
"interface/icons/trade_archaeology_draenei_tome",
"interface/icons/inv_7xp_inscription_talenttome02",
"interface/icons/inv_7xp_inscription_talenttome01",
"interface/icons/inv_artifact_tome01",
"interface/icons/inv_archaeology_80_witch_book",
"interface/icons/inv_misc_book_17",
"interface/icons/inv_misc_paperbundle04b",
"interface/icons/inv_misc_paperbundle04c",
"interface/icons/inv_misc_codexofxerrath_nochains",
"interface/icons/70_inscription_steamy_romance_novel_kit",
"interface/icons/inv_inscription_80_contract_vulpera",
"interface/icons/inv_inscription_80_warscroll_fortitude",
"interface/icons/inv_inscription_80_warscroll_intellect",
"interface/icons/inv_inscription_tradeskill01",
"interface/icons/inv_inscription_trinket0"..math.random(4),
"interface/icons/inv_enchanting_70_leylightcrystal",
"interface/icons/inv_enchanting_70_pet_pen",
"interface/icons/inv_enchanting_70_toy_leyshocker",
"interface/icons/inv_enchanting_80_veiledcrystal",
"interface/icons/inv_enchanting_815_drustrod",
}

local frameBackgroundOptions = {
"interface/archeology/arch-bookitemleft",
"interface/archeology/arch-bookitemleft",
"interface/archeology/arch-bookitemleft",
"interface/archeology/arch-bookitemleft",
"interface/archeology/arch-bookcompletedleft",
"interface/spellbook/spellbook-page-1",
--[[
"something",
"something",
"something",
"something",
"something",
"something",
"something",
"something",
"something",
"something",
"something",
--]]
}

local frameBackgroundOptionsEdge = {
"interface/archeology/arch-bookitemright",
"interface/archeology/arch-bookitemright",
"interface/archeology/arch-bookitemright",
"interface/archeology/arch-bookitemright",
"interface/archeology/arch-bookcompletedright",
"interface/spellbook/spellbook-page-2",
}

local function get_Table_Position(str, tab)
	for i = 1, #tab do
		local v = tab[i] --cheaper ipairs as i,v
		if v == str then return i; end
		return nil;
	end
end

-------------------------------------------------------------------------------
-- Core Functions & Data
-------------------------------------------------------------------------------

-- the functions to actuall process & cast the spells

local actionTypeData = {} -- Defined here, but actually set below. Weird hack to bypass that they technically rely on each other..
local actionTypeDataList = {}

local function processAction(delay, actionType, revertDelay, selfOnly, vars)
	if not actionType then return; end
	local actionData = actionTypeData[actionType]
	if revertDelay then revertDelay = tonumber(revertDelay) end
	local varTable
	
	if vars then
		varTable = { strsplit(",", vars) }
	end
	
	if actionData.comTarget == "func" then
		C_Timer.After(delay, function()
			local varTable = varTable
			for i = 1, #varTable do
				local v = varTable[i]
				actionData.command(v)
			end
		end)
	else
		if actionData.dataName then
			C_Timer.After(delay, function()
				local varTable = varTable
				for i = 1, #varTable do
					local v = varTable[i] -- v = the ID or input.
					--print(actionData.command)
					local finalCommand = tostring(actionData.command)
					finalCommand = finalCommand:gsub(sfCmd_ReplacerChar, v)
					if selfOnly then finalCommand = finalCommand.." self" end
					dprint(false, finalCommand)
					cmd(finalCommand)
					
				end
				if revertDelay and revertDelay > 0 then
					C_Timer.After(revertDelay, function()
						local varTable = varTable
						for i = 1, #varTable do
							local v = varTable[i]
							if selfOnly then
								cmd(actionData.revert.." "..v.." self")
							else
								cmd(actionData.revert.." "..v)
							end
						end
					end)
				end
			end)
		else
			if selfOnly then
				C_Timer.After(delay, function() cmd(actionData.command.." self") end)
			else
				C_Timer.After(delay, function() cmd(actionData.command) end)
			end
		end
	end
end

local actionsToCommit = {}
local function executeSpell(actionsToCommit)
	for _,spell in pairs(actionsToCommit) do
		dprint(false,"Delay: "..spell.delay.." | ActionType: "..spell.actionType.." | RevertDelay: "..tostring(spell.revertDelay).." | Self: "..tostring(spell.selfOnly).." | Vars: "..tostring(spell.vars))
		processAction(spell.delay, spell.actionType, spell.revertDelay, spell.selfOnly, spell.vars)
	end
end

-- Action Types & Data Info

actionTypeDataList = { -- formatted for easier sorting - whatever order they are here is the order they show up in dropdown as.
"SpellCast", 
"SpellTrig", 
"SpellAura", 
"Anim", 
"Standstate", 
"Morph", 
"Native", 
"Equip", 
"EquipSet",
"MogitEquip", 
"RemoveAura", 
"RemoveAllAuras", 
"Unmorph", 
"Unequip", 
"DefaultEmote", 
"ArcSpell",
"Command",}

actionTypeData = {
	["SpellCast"] = {
		["name"] = "Cast Spell",							-- The Displayed Name in the UI
		["command"] = "cast @N@", 								-- The chat command, or Lua function to process
		["description"] = "Cast a spell using a Spell ID, to selected target, or self if no target.\n\rEnable the Self checkbox to cast always on yourself.\n\rRevert: Unaura", 	-- Description for on-mouse-over
		["dataName"] = "Spell ID(s)", 							-- Label for the ID Box, nil to disable the ID box
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\r'.look spell' for IDs.",							-- Description of the input for GameTooltip
		["comTarget"] = "server", 							-- Server for commands, func for custom Lua function in 'command'
		["revert"] = "unaura", 									-- The command that reverts it, i.e, 'unaura' for 'aura'
		["selfAble"] = true,								-- True/False - if able to use the self-toggle checkbox
		},
	["SpellTrig"] = {
		["name"] = "Cast Spell (Trig)",
		["command"] = "cast @N@ trig",
		["description"] = "Cast a spell using a Spell ID, to selected target, or self if no target, using the triggered flag.\n\rEnable the Self checkbox to cast always on yourself.\n\rRevert: Unaura",
		["dataName"] = "Spell ID(s)",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to cast multiple spells at once.\n\r'.look spell' for IDs.",
		["comTarget"] = "server",
		["revert"] = "unaura",
		["selfAble"] = true,
		},
	["SpellAura"] = {
		["name"] = "Apply Aura",
		["command"] = "aura @N@",
		["description"] = "Applies an Aura from a Spell ID on your target, or yourself if no target selected.\n\rEnable the 'self' checkbox to always aura yourself.\n\rRevert: Unaura",
		["dataName"] = "Spell ID(s)",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to apply multiple auras at once.\n\r'.look spell' for IDs.",
		["comTarget"] = "server",
		["revert"] = "unaura",
		["selfAble"] = true,
		},
	["Anim"] = {
		["name"] = "Emote",
		["command"] = "mod anim @N@",
		["description"] = "Modifies target's current animation.\n\rUse .lookup emote to find IDs.\n\rRevert: Reset to Anim 0 (none)",
		["dataName"] = "Emote ID",
		["inputDescription"] = "Accepts multiple IDs, separated by commas, to do multiple anims at once -- but the second usually over-rides the first.\n\r'.look emote' for IDs.",
		["comTarget"] = "server",
		["revert"] = "mod anim 0",
		["selfAble"] = false,
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
		["revert"] = "",
		["selfAble"] = true,
		},
	["Equip"] = {
		["name"] = "Equip Item",
		["command"] = function(vars) EquipItemByName(vars) end,
		["description"] = "Equip an Item by name or ID. Item must be in your inventory. Cannot be reverted directly.\n\rName is a search in your inventory by keyword - using ID is recommended.\n\ri.e., You want to equip 'Violet Guardian's Helm', ID: 141357, but have 'Guardian's Leather Belt', ID: 35156 in your inventory also, using 'Guardian' as the text will equip the belt, so you'll want to use the full name, or better off just use the actual item ID.",
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
		["description"] = "Remove all Auras.\n\rCannot be reverted.",
		["dataName"] = nil,
		["comTarget"] = "server",
		["revert"] = nil,
		["selfAble"] = true,
		},
	["Unmorph"] = {
		["name"] = "Remove Morph",
		["command"] = "demorph",
		["description"] = "Remove all morphs, including natives.\n\rCannot be reverted directly, use morph/native.",
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
	["DefaultEmote"] = {
		["name"] = "Default Emote",
		["command"] = function(emoteID) DoEmote(string.upper(emoteID)); end,
		["description"] = "Any default emote.\n\rMust be a valid emote 'token', i.e., 'WAVE'\n\rGoogle 'WoWpedia DoEmote' for a full list - most match their /command, but some don't.",
		["dataName"] = "Emote Token",
		["inputDescription"] = "Usually just the text from the /command, i.e., /wave = wave.\n\rIf not working: Search Google for 'WoWpedia DoEmote', and go to the WoWpedia page, and find the table of tokens - some don't exactly match their command.",
		["comTarget"] = "func",
		["revert"] = nil,
		},
	["Command"] = {
		["name"] = "Other Command",
		["command"] = cmd,
		["description"] = "Any other server command.\n\rType the full command you want, without the dot, in the input box.\n\ri.e., 'mod drunk 100'.",
		["dataName"] = "Full Command",
		["inputDescription"] = "You can use any server command here, without the '.', and it will run after the delay.\n\rTechnically accepts multiple commands, separated by commas.\n\rExample: 'mod drunk 100'.",
		["comTarget"] = "func",
		["revert"] = nil,
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
		["description"] = "Equip a saved Equipment Manager set by name.",
		["dataName"] = "Set Name",
		["inputDescription"] = "Set name from Equipment Manager (Blizzard's built in set manager).",
		["comTarget"] = "func",
		["revert"] = nil,
		},
	["ArcSpell"] = {
		["name"] = "Arcanum Spell",
		["command"] = function(commID) executeSpell(SpellCreatorSavedSpells[commID].actions) end,
		["description"] = "Cast another Arcanum spell from your vault.",
		["dataName"] = "Spell Command",
		["inputDescription"] = "The Command key used to cast the spell\n\rExample: '/sf MySpell', where MySpell is the command key to input here.",
		["comTarget"] = "func",
		["revert"] = nil,
		},
}

-------------------------------------------------------------------------------
-- UI Helper & Definitions
-------------------------------------------------------------------------------

-- Row Sizing / Info
local numberOfSpellRows = 0
local maxNumberOfSpellRows = 69
local rowHeight = 60
local rowSpacing = 30

local mainFrameSize = {
	["x"] = 700,
	["y"] = 700,
	["Xmin"] = 550,
	["Ymin"] = 550,
	["Xmax"] = math.min(1100,UIParent:GetHeight()), -- Don't let them resize it bigger than their screen is.. then you can't resize it down w/o using hidden right-click on X button
	["Ymax"] = math.min(1100,UIParent:GetHeight()), --
}

-- Column Widths
local delayColumnWidth = 100
local actionColumnWidth = 100
local selfColumnWidth = 41
local InputEntryColumnWidth = 100
local revertCheckColumnWidth = 60
local revertDelayColumnWidth = 100

-- Drop Down Generator
local function genStaticDropdownChild( parent, dropdownName, menuList, title, width )

	if not parent or not dropdownName or not menuList then return end;
	if not title then title = "Select" end
	if not width then width = 55 end
	local newDropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
	newDropdown:SetPoint("CENTER")
		
	local function newDropdown_Initialize( dropdownName, level )
		--for index,value in ipairs(menuList) do
		for index = 1, #menuList do
			local value = menuList[index]
			if (value.text) then
				value.index = index;
				UIDropDownMenu_AddButton( value, level );
			end
		end
	end
	
	UIDropDownMenu_Initialize(newDropdown, newDropdown_Initialize, "nope", nil, menuList)
	UIDropDownMenu_SetWidth(newDropdown, width);
	UIDropDownMenu_SetButtonWidth(newDropdown, width+15)
	UIDropDownMenu_SetSelectedID(newDropdown, 0)
	UIDropDownMenu_JustifyText(newDropdown, "LEFT")
	UIDropDownMenu_SetText(newDropdown, title)
	_G[dropdownName.."Text"]:SetFontObject("GameFontWhiteTiny2")
	_G[dropdownName.."Text"]:SetWidth(width-15)
	local fontName,fontHeight,fontFlags = _G[dropdownName.."Text"]:GetFont()
--	_G[dropdownName.."Text"]:SetFont(fontName, 10)
	
	newDropdown:GetParent():SetWidth(newDropdown:GetWidth())
	newDropdown:GetParent():SetHeight(newDropdown:GetHeight())	
end

-- Resizing Functions to scale with main frame resizing
local framesToResizeWithMainFrame = {}
local function setResizeWithMainFrame(frame)
	table.insert(framesToResizeWithMainFrame, frame)
end

local function updateFrameChildScales(frame)
	local n = frame:GetWidth()
	frame:SetHeight(n)
	SCForgeMainFrame.DragBar:SetWidth(n)
	local n = n / mainFrameSize.x
	local childrens = {frame.Inset:GetChildren()}
	for _,child in ipairs(childrens) do
		child:SetScale(n)
	end
	for _,child in pairs(framesToResizeWithMainFrame) do
		child:SetScale(n)
	end
	return n;
end

local function generateSpellChatLink(commID)
	local spellName = SpellCreatorSavedSpells[commID].fullName
	local spellComm = SpellCreatorSavedSpells[commID].commID
	local characterName = GetUnitName("player",false)
	local numActions = #SpellCreatorSavedSpells[commID].actions
	local chatLink = addonColor.."|HarcSpell:"..spellComm..":"..characterName..":"..spellName..":"..numActions.."|h["..spellName.."]|h|r"
	return chatLink;
end

-------------------------------------------------------------------------------
-- Main UI Frame
-------------------------------------------------------------------------------

local function RemoveSpellRow()
	if numberOfSpellRows <= 1 then return; end
	_G["spellRow"..numberOfSpellRows]:Hide()
	
	if clearSpellOnRowRemoved then
		_G["spellRow"..numberOfSpellRows.."MainDelayBox"]:SetText("")
		
		for k,v in pairs(_G["spellRow"..numberOfSpellRows].menuList) do
			v.checked = false
		end
		UIDropDownMenu_SetSelectedID(_G["spellRow"..numberOfSpellRows.."ActionSelectButton"], 0)
		_G["spellRow"..numberOfSpellRows.."ActionSelectButtonText"]:SetText("Action")
		updateSpellRowOptions(numberOfSpellRows, nil)
		
		_G["spellRow"..numberOfSpellRows.."SelfCheckbox"]:SetChecked(false)
		_G["spellRow"..numberOfSpellRows.."InputEntryBox"]:SetText("")
		_G["spellRow"..numberOfSpellRows.."RevertCheckbox"]:SetChecked(false)
		_G["spellRow"..numberOfSpellRows.."RevertDelayBox"]:SetText("")
	end

	numberOfSpellRows = numberOfSpellRows - 1
	
	if numberOfSpellRows < maxNumberOfSpellRows then SCForgeMainFrame.AddSpellRowButton:Enable() end
	SCForgeMainFrame.Inset.scrollFrame:UpdateScrollChildRect()
end

local function AddSpellRow()
	if numberOfSpellRows >= maxNumberOfSpellRows then SCForgeMainFrame.AddSpellRowButton:Disable() return; end -- hard cap
	numberOfSpellRows = numberOfSpellRows+1		-- The number of spell rows that this row will be.
	if _G["spellRow"..numberOfSpellRows] then _G["spellRow"..numberOfSpellRows]:Show(); else

		-- The main row frame
		newRow = CreateFrame("Frame", "spellRow"..numberOfSpellRows, SCForgeMainFrame.Inset.scrollFrame.scrollChild)
		if numberOfSpellRows == 1 then
			newRow:SetPoint("TOPLEFT", 25, 0)
		else
			newRow:SetPoint("TOPLEFT", "spellRow"..numberOfSpellRows-1, "BOTTOMLEFT", 0, -5)
		end
		newRow:SetWidth(mainFrameSize.x-50)
		newRow:SetHeight(rowHeight)
		
		newRow.Background = newRow:CreateTexture(nil,"BACKGROUND")
		newRow.Background:SetAllPoints()
		newRow.Background:SetColorTexture(0,0,0,0.25)
		
		-- main delay entry box
		newRow.mainDelayBox = CreateFrame("EditBox", "spellRow"..numberOfSpellRows.."MainDelayBox", newRow, "InputBoxTemplate")
		newRow.mainDelayBox:SetAutoFocus(false)
		newRow.mainDelayBox:SetSize(delayColumnWidth,23)
		newRow.mainDelayBox:SetPoint("LEFT", 40, 0)
		newRow.mainDelayBox:SetMaxLetters(9)
		newRow.mainDelayBox:SetScript("OnTextChanged", function(self)
			if self:GetText() == self:GetText():match("%d+") or self:GetText() == self:GetText():match("%d+%.%d+") or self:GetText() == self:GetText():match("%.%d+") then
				self:SetTextColor(255,255,255,1)
			elseif self:GetText() == "" then
				self:SetTextColor(255,255,255,1)
			elseif self:GetText():find("%a") then
				self:SetText(self:GetText():gsub("%a", ""))
			else
				self:SetTextColor(1,0,0,1)
			end
		end)
		newRow.mainDelayBox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			self.Timer = C_Timer.NewTimer(0.7,function()
				GameTooltip:SetText("Main Action Delay", nil, nil, nil, nil, true)
				GameTooltip:AddLine("How long after 'casting' the spell this action triggers.\rCan be '0' for instant.",1,1,1,true)
				GameTooltip:Show()
			end)
		end)
		newRow.mainDelayBox:SetScript("OnLeave", function(self)
			GameTooltip_Hide()
			self.Timer:Cancel()
		end)
		
		-- Action Dropdown Menu
		newRow.menuList = {}
		local menuList = newRow.menuList
		
		for i = 1, #actionTypeDataList do
			local v = actionTypeDataList[i]
--		for k,v in ipairs(actionTypeDataList) do
			local menuItem = UIDropDownMenu_CreateInfo()
			menuItem.text = actionTypeData[v].name
			menuItem.checked = false
			menuItem.tooltipTitle = actionTypeData[v].name
			menuItem.tooltipText = actionTypeData[v].description
			menuItem.tooltipOnButton = true
			menuItem.value = v
			menuItem.arg1 = numberOfSpellRows
			menuItem.func = function(self, arg1)
				for k,v in pairs(menuList) do
					v.checked = false
				end
				UIDropDownMenu_SetSelectedID(_G["spellRow"..arg1.."ActionSelectButton"], self:GetID())
				--_G["spellRow"..arg1.."ActionSelectButtonText"]:SetText(menuItem.text)
				dprint(false, dump(self))
				updateSpellRowOptions(arg1, menuItem.value)
			end
			table.insert(menuList, menuItem)
		end
		
		newRow.actionSelectButton = CreateFrame("Frame", "spellRow"..numberOfSpellRows.."ActionSelectAnchor", newRow)
		newRow.actionSelectButton:SetPoint("LEFT", newRow.mainDelayBox, "RIGHT", 0, -2)
		genStaticDropdownChild( newRow.actionSelectButton, "spellRow"..numberOfSpellRows.."ActionSelectButton", menuList, "Action", actionColumnWidth)
		
		-- Self Checkbox
		newRow.SelfCheckbox = CreateFrame("CHECKBUTTON", "spellRow"..numberOfSpellRows.."SelfCheckbox", newRow, "UICheckButtonTemplate")
		newRow.SelfCheckbox:SetPoint("LEFT", newRow.actionSelectButton, "RIGHT", 0, 2)
		newRow.SelfCheckbox:Disable()
		newRow.SelfCheckbox:SetMotionScriptsWhileDisabled(true)
		newRow.SelfCheckbox:SetScript("OnShow", function(self)

		end)
		newRow.SelfCheckbox:SetScript("OnClick", function(self)

		end)
		newRow.SelfCheckbox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			self.Timer = C_Timer.NewTimer(0.7,function()
				GameTooltip:SetText("Cast on Self", nil, nil, nil, nil, true)
				GameTooltip:AddLine("Enable to use the 'Self' flag for Cast & Aura actions.", 1,1,1,true)
				GameTooltip:Show()
			end)
		end)
		newRow.SelfCheckbox:SetScript("OnLeave", function(self)
			GameTooltip_Hide()
			self.Timer:Cancel()
		end)
		
		-- ID Entry Box (Input)
		newRow.InputEntryBox = CreateFrame("EditBox", "spellRow"..numberOfSpellRows.."InputEntryBox", newRow, "InputBoxInstructionsTemplate")
		newRow.InputEntryBox:SetFontObject(ChatFontNormal)
		newRow.InputEntryBox.disabledColor = GRAY_FONT_COLOR
		newRow.InputEntryBox.enabledColor = HIGHLIGHT_FONT_COLOR
		newRow.InputEntryBox.Instructions:SetText("...")
		newRow.InputEntryBox.Instructions:SetTextColor(0.5,0.5,0.5)
		newRow.InputEntryBox.Description = ""
		newRow.InputEntryBox.rowNumber = numberOfSpellRows
		newRow.InputEntryBox:SetAutoFocus(false)
		newRow.InputEntryBox:Disable()
		newRow.InputEntryBox:SetSize(InputEntryColumnWidth,23)
		newRow.InputEntryBox:SetPoint("LEFT", newRow.SelfCheckbox, "RIGHT", 25, 0)
		newRow.InputEntryBox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			local row = self.rowNumber
			self.Timer = C_Timer.NewTimer(0.7,function()
				if _G["spellRow"..row.."SelectedAction"] and actionTypeData[_G["spellRow"..row.."SelectedAction"]].dataName then 
					local actionData = actionTypeData[_G["spellRow"..row.."SelectedAction"]]
					GameTooltip:SetText(actionData.dataName, nil, nil, nil, nil, true)
					if actionData.inputDescription then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(actionData.inputDescription, 1, 1, 1, true)
						--GameTooltip:AddLine(" ")
					end
					GameTooltip:Show()
				end
			end)
		end)
		newRow.InputEntryBox:SetScript("OnLeave", function(self)
			GameTooltip_Hide()
			self.Timer:Cancel()
		end)

		
		-- Revert Checkbox
		newRow.RevertCheckbox = CreateFrame("CHECKBUTTON", "spellRow"..numberOfSpellRows.."RevertCheckbox", newRow, "UICheckButtonTemplate")
		newRow.RevertCheckbox:SetPoint("LEFT", newRow.InputEntryBox, "RIGHT", 20, 0)
		newRow.RevertCheckbox.RowID = numberOfSpellRows
		newRow.RevertCheckbox:Disable()
		newRow.RevertCheckbox:SetMotionScriptsWhileDisabled(true)
		newRow.RevertCheckbox:SetScript("OnShow", function(self)

		end)
		newRow.RevertCheckbox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			self.Timer = C_Timer.NewTimer(0.7,function()
				GameTooltip:SetText("Revert the Action", nil, nil, nil, nil, true)
				GameTooltip:AddLine("Enabling causes the action to revert (reverse, undo) after the specified Revert Delay time.\n\rSee actions tooltip info for what the revert action is.", 1,1,1,true)
				GameTooltip:Show()
			end)
		end)
		newRow.RevertCheckbox:SetScript("OnLeave", function(self)
			GameTooltip_Hide()
			self.Timer:Cancel()
		end)		
		
		-- Revert Delay Box
		
		newRow.RevertDelayBox = CreateFrame("EditBox", "spellRow"..numberOfSpellRows.."RevertDelayBox", newRow, "InputBoxInstructionsTemplate")
		newRow.RevertDelayBox:SetFontObject(ChatFontNormal)
		newRow.RevertDelayBox.disabledColor = GRAY_FONT_COLOR
		newRow.RevertDelayBox.enabledColor = HIGHLIGHT_FONT_COLOR
		newRow.RevertDelayBox.Instructions:SetText("Revert Delay")
		newRow.RevertDelayBox.Instructions:SetTextColor(0.5,0.5,0.5)
		newRow.RevertDelayBox:SetAutoFocus(false)
		newRow.RevertDelayBox:Disable()
		newRow.RevertDelayBox:SetSize(delayColumnWidth,23)
		newRow.RevertDelayBox:SetPoint("LEFT", newRow.RevertCheckbox, "RIGHT", 25, 0)
		newRow.RevertDelayBox:SetMaxLetters(9)
		
		newRow.RevertDelayBox:HookScript("OnTextChanged", function(self)
			if self:GetText() == self:GetText():match("%d+") or self:GetText() == self:GetText():match("%d+%.%d+") or self:GetText() == self:GetText():match("%.%d+") then
				self:SetTextColor(255,255,255,1)
			elseif self:GetText() == "" then
				self:SetTextColor(255,255,255,1)
			elseif self:GetText():find("%a") then
				self:SetText(self:GetText():gsub("%a", ""))
			else
				self:SetTextColor(1,0,0,1)
			end
		end)
		newRow.RevertDelayBox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			self.Timer = C_Timer.NewTimer(0.7,function()
				GameTooltip:SetText("Revert Delay", nil, nil, nil, nil, true)
				GameTooltip:AddLine("How long after the initial action before reverting.\n\rNote: This is RELATIVE to this lines main action delay.",1,1,1,true)
				GameTooltip:AddLine("\n\rEx: Aura action with delay 2, and revert delay 3, means the revert is 3 seconds after the aura action itself, NOT 3 seconds after casting..",1,1,1,true)
				GameTooltip:Show()
			end)
		end)
		newRow.RevertDelayBox:SetScript("OnLeave", function(self)
			GameTooltip_Hide()
			self.Timer:Cancel()
		end)
		
		--Sync Revert Delaybox & Checkbox Disable/Enable
		newRow.RevertCheckbox:SetScript("OnClick", function(self)
			local checked = self:GetChecked()
			local rowID = self.RowID
			if checked then _G["spellRow"..rowID.."RevertDelayBox"]:Enable() else _G["spellRow"..rowID.."RevertDelayBox"]:Disable() end
		end)

	end
	updateFrameChildScales(SCForgeMainFrame)
	if numberOfSpellRows >= maxNumberOfSpellRows then SCForgeMainFrame.AddSpellRowButton:Disable() return; end -- hard cap
end

function updateSpellRowOptions(row, selectedAction) 
		-- perform action type checks here against the actionTypeData table & disable/enable buttons / entries as needed. See actionTypeData for available options. 
	if selectedAction then -- if we call it with no action, reset
		_G["spellRow"..row.."SelectedAction"] = selectedAction
		if actionTypeData[selectedAction].selfAble then _G["spellRow"..row.."SelfCheckbox"]:Enable() else _G["spellRow"..row.."SelfCheckbox"]:Disable() end
		if actionTypeData[selectedAction].dataName then 
			_G["spellRow"..row.."InputEntryBox"]:Enable()
			_G["spellRow"..row.."InputEntryBox"].Instructions:SetText(actionTypeData[selectedAction].dataName)
			if actionTypeData[selectedAction].inputDescription then _G["spellRow"..row.."InputEntryBox"].Description = actionTypeData[selectedAction].inputDescription end
		else
			_G["spellRow"..row.."InputEntryBox"]:Disable()
			_G["spellRow"..row.."InputEntryBox"].Instructions:SetText("n/a") 
		end
		if actionTypeData[selectedAction].revert then _G["spellRow"..row.."RevertCheckbox"]:Enable(); _G["spellRow"..row.."RevertDelayBox"]:Enable() else _G["spellRow"..row.."RevertCheckbox"]:Disable(); _G["spellRow"..row.."RevertDelayBox"]:Disable() end
	else
		_G["spellRow"..row.."SelectedAction"] = nil
		_G["spellRow"..row.."SelfCheckbox"]:Disable()
		_G["spellRow"..row.."InputEntryBox"].Instructions:SetText("...")
		_G["spellRow"..row.."InputEntryBox"]:Disable()
		_G["spellRow"..row.."RevertCheckbox"]:Disable();
		_G["spellRow"..row.."RevertDelayBox"]:Disable()
	end
end


SCForgeMainFrame = CreateFrame("Frame", "SCForgeMainFrame", UIParent, "ButtonFrameTemplate")
SCForgeMainFrame:SetPoint("CENTER")
SCForgeMainFrame:SetSize(mainFrameSize.x, mainFrameSize.y)
SCForgeMainFrame:SetMaxResize(mainFrameSize.Xmax, mainFrameSize.Ymax)
SCForgeMainFrame:SetMinResize(mainFrameSize.Xmin, mainFrameSize.Ymin)
SCForgeMainFrame:SetMovable(true)
SCForgeMainFrame:SetResizable(true)
SCForgeMainFrame:EnableMouse(true)
SCForgeMainFrame:SetClampedToScreen(true)
SCForgeMainFrame:SetClampRectInsets(300, -300, 0, 500)

	SC_randomFramePortrait = frameIconOptions[fastrandom(#frameIconOptions)]
SCForgeMainFrame:SetPortraitToAsset(SC_randomFramePortrait)
SCForgeMainFrame:SetTitle("Arcanum - Spell Forge")

SCForgeMainFrame.DragBar = CreateFrame("Frame", nil, SCForgeMainFrame)
SCForgeMainFrame.DragBar:SetPoint("TOPLEFT")
SCForgeMainFrame.DragBar:SetSize(mainFrameSize.x, 20)
SCForgeMainFrame.DragBar:EnableMouse(true)
SCForgeMainFrame.DragBar:RegisterForDrag("LeftButton")
SCForgeMainFrame.DragBar:SetScript("OnDragStart", function(self)
    self:GetParent():StartMoving()
  end)
SCForgeMainFrame.DragBar:SetScript("OnDragStop", function(self)
    self:GetParent():StopMovingOrSizing()
  end)

-- The top bar Spell Info Boxes - Needs some placement love later..
SCForgeMainFrame.SpellInfoNameBox = CreateFrame("EditBox", nil, SCForgeMainFrame, "InputBoxInstructionsTemplate")
SCForgeMainFrame.SpellInfoNameBox:SetFontObject(ChatFontNormal)
SCForgeMainFrame.SpellInfoNameBox.disabledColor = GRAY_FONT_COLOR
SCForgeMainFrame.SpellInfoNameBox.enabledColor = HIGHLIGHT_FONT_COLOR
SCForgeMainFrame.SpellInfoNameBox.Instructions:SetText("Spell Name")
SCForgeMainFrame.SpellInfoNameBox.Instructions:SetTextColor(0.5,0.5,0.5)
SCForgeMainFrame.SpellInfoNameBox.Title = SCForgeMainFrame.SpellInfoNameBox:CreateFontString(nil, "OVERLAY", "GameTooltipText")
SCForgeMainFrame.SpellInfoNameBox.Title:SetText("Name:")
SCForgeMainFrame.SpellInfoNameBox.Title:SetPoint("RIGHT", SCForgeMainFrame.SpellInfoNameBox, "LEFT", -10, 0)
SCForgeMainFrame.SpellInfoNameBox:SetAutoFocus(false)
SCForgeMainFrame.SpellInfoNameBox:SetSize(100,23)
SCForgeMainFrame.SpellInfoNameBox:SetPoint("TOP", -100, -30)
SCForgeMainFrame.SpellInfoNameBox:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Spell Name", nil, nil, nil, nil, true)
		GameTooltip:AddLine("The name of the spell.\rThis can be anything and is only used for identifying the spell in the Vault & Chat Links.\n\rYes, you can have two spells with the same name.",1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.SpellInfoNameBox:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)

SCForgeMainFrame.SpellInfoCommandBox = CreateFrame("EditBox", nil, SCForgeMainFrame, "InputBoxInstructionsTemplate")
SCForgeMainFrame.SpellInfoCommandBox:SetFontObject(ChatFontNormal)
SCForgeMainFrame.SpellInfoCommandBox.disabledColor = GRAY_FONT_COLOR
SCForgeMainFrame.SpellInfoCommandBox.enabledColor = HIGHLIGHT_FONT_COLOR
SCForgeMainFrame.SpellInfoCommandBox.Instructions:SetText("Spell Command")
SCForgeMainFrame.SpellInfoCommandBox.Instructions:SetTextColor(0.5,0.5,0.5)
SCForgeMainFrame.SpellInfoCommandBox.Title = SCForgeMainFrame.SpellInfoCommandBox:CreateFontString(nil, "OVERLAY", "GameTooltipText")
SCForgeMainFrame.SpellInfoCommandBox.Title:SetText("Command (ID):")
SCForgeMainFrame.SpellInfoCommandBox.Title:SetPoint("RIGHT", SCForgeMainFrame.SpellInfoCommandBox, "LEFT", -10, 0)
SCForgeMainFrame.SpellInfoCommandBox:SetAutoFocus(false)
SCForgeMainFrame.SpellInfoCommandBox:SetSize(100,23)
SCForgeMainFrame.SpellInfoCommandBox:SetPoint("LEFT", SCForgeMainFrame.SpellInfoNameBox, "RIGHT", 120, 0)
SCForgeMainFrame.SpellInfoCommandBox:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Spell Command", nil, nil, nil, nil, true)
		GameTooltip:AddLine("The slash command trigger you want to use to call this spell.\n\rCast it using '/arcanum $command'.",1,1,1,true)
		GameTooltip:AddLine(" ",1,1,1,true)
		GameTooltip:AddLine("This must be unique. Saving a spell with the same command name as another will over-write the old spell.",1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.SpellInfoCommandBox:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)

--- The Inner Frame

local randomBackgroundID = fastrandom(#frameBackgroundOptions)
local background = SCForgeMainFrame.Inset.Bg -- re-use the stock background, save a frame texture
background:SetTexture(frameBackgroundOptions[randomBackgroundID])
background:SetTexCoord(0.05,1,0,0.96)
--background:SetAllPoints()
background:SetVertTile(false)
background:SetHorizTile(false)
background:SetPoint("TOPLEFT", SCForgeMainFrame.Inset, "TOPLEFT", 0,0) -- 12, -66
background:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.Inset, "BOTTOMRIGHT", -20,0)


local background2 = SCForgeMainFrame.Inset:CreateTexture(nil,"BACKGROUND")
background2:SetTexture(frameBackgroundOptionsEdge[randomBackgroundID])
background2:SetPoint("TOPLEFT", background, "TOPRIGHT")
background2:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", 30, 0)
background2:SetTexCoord(0,1,0,0.96)

	SCForgeMainFrame.Inset.scrollFrame = CreateFrame("ScrollFrame", nil, SCForgeMainFrame.Inset, "UIPanelScrollFrameTemplate")
	local scrollFrame = SCForgeMainFrame.Inset.scrollFrame
	scrollFrame:SetPoint("TOPLEFT", 0, -35)
	scrollFrame:SetPoint("BOTTOMRIGHT", -20, 5)

	SCForgeMainFrame.Inset.scrollFrame.scrollChild = CreateFrame("Frame")
	local scrollChild = SCForgeMainFrame.Inset.scrollFrame.scrollChild
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(SCForgeMainFrame.Inset:GetWidth()-18)
	scrollChild:SetHeight(1) 
	
	scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, -16+30)
	scrollFrame.ScrollBar.scrollStep = rowHeight+5

--This is a sub-frame of the Main Frame.. Should it be? Idk..
SCForgeMainFrame.TitleBar = CreateFrame("Frame", nil, SCForgeMainFrame)
SCForgeMainFrame.TitleBar:SetPoint("TOPLEFT", SCForgeMainFrame.Inset, "TOPLEFT", 25, -10)
SCForgeMainFrame.TitleBar:SetSize(mainFrameSize.x-50, 20)
--SCForgeMainFrame.TitleBar:SetHeight(20)
setResizeWithMainFrame(SCForgeMainFrame.TitleBar)

SCForgeMainFrame.TitleBar.Background = SCForgeMainFrame.TitleBar:CreateTexture(nil,"BACKGROUND")
SCForgeMainFrame.TitleBar.Background:SetAllPoints()
SCForgeMainFrame.TitleBar.Background:SetColorTexture(0,0,0,0.25)

SCForgeMainFrame.TitleBar.MainDelay = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
SCForgeMainFrame.TitleBar.MainDelay:SetWidth(delayColumnWidth)
SCForgeMainFrame.TitleBar.MainDelay:SetJustifyH("CENTER")
SCForgeMainFrame.TitleBar.MainDelay:SetPoint("TOPLEFT", SCForgeMainFrame.TitleBar, "TOPLEFT", 13+25, 0)
SCForgeMainFrame.TitleBar.MainDelay:SetText("Delay")

SCForgeMainFrame.TitleBar.Action = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
SCForgeMainFrame.TitleBar.Action:SetWidth(actionColumnWidth+52)
SCForgeMainFrame.TitleBar.Action:SetJustifyH("CENTER")
SCForgeMainFrame.TitleBar.Action:SetPoint("LEFT", SCForgeMainFrame.TitleBar.MainDelay, "RIGHT", 0, 0)
SCForgeMainFrame.TitleBar.Action:SetText("Action")

SCForgeMainFrame.TitleBar.Self = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
SCForgeMainFrame.TitleBar.Self:SetWidth(selfColumnWidth)
SCForgeMainFrame.TitleBar.Self:SetJustifyH("LEFT")
SCForgeMainFrame.TitleBar.Self:SetPoint("LEFT", SCForgeMainFrame.TitleBar.Action, "RIGHT", 0, 0)
SCForgeMainFrame.TitleBar.Self:SetText("Self")

SCForgeMainFrame.TitleBar.InputEntry = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
SCForgeMainFrame.TitleBar.InputEntry:SetWidth(InputEntryColumnWidth+10)
SCForgeMainFrame.TitleBar.InputEntry:SetJustifyH("CENTER")
SCForgeMainFrame.TitleBar.InputEntry:SetPoint("LEFT", SCForgeMainFrame.TitleBar.Self, "RIGHT", 5, 0)
SCForgeMainFrame.TitleBar.InputEntry:SetText("Input")

SCForgeMainFrame.TitleBar.RevertCheck = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
SCForgeMainFrame.TitleBar.RevertCheck:SetWidth(revertCheckColumnWidth+10)
SCForgeMainFrame.TitleBar.RevertCheck:SetJustifyH("CENTER")
SCForgeMainFrame.TitleBar.RevertCheck:SetPoint("LEFT", SCForgeMainFrame.TitleBar.InputEntry, "RIGHT", 5, 0)
SCForgeMainFrame.TitleBar.RevertCheck:SetText("Revert")

SCForgeMainFrame.TitleBar.RevertDelay = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
SCForgeMainFrame.TitleBar.RevertDelay:SetWidth(revertDelayColumnWidth)
SCForgeMainFrame.TitleBar.RevertDelay:SetJustifyH("CENTER")
SCForgeMainFrame.TitleBar.RevertDelay:SetPoint("LEFT", SCForgeMainFrame.TitleBar.RevertCheck, "RIGHT", 0, 0)
SCForgeMainFrame.TitleBar.RevertDelay:SetText("Delay")

SCForgeMainFrame.ResizeDragger = CreateFrame("BUTTON", nil, SCForgeMainFrame)
SCForgeMainFrame.ResizeDragger:SetSize(16,16)
SCForgeMainFrame.ResizeDragger:SetPoint("BOTTOMRIGHT", -2, 2)
SCForgeMainFrame.ResizeDragger:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
SCForgeMainFrame.ResizeDragger:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
SCForgeMainFrame.ResizeDragger:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
SCForgeMainFrame.ResizeDragger:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" then
		local parent = self:GetParent()
		self.isScaling = true
		parent:StartSizing("BOTTOMRIGHT")
	end
end)
SCForgeMainFrame.ResizeDragger:SetScript("OnMouseUp", function(self, button)
	if button == "LeftButton" then
		local parent = self:GetParent()
		self.isScaling = false
		parent:StopMovingOrSizing()
	end
end)
SCForgeMainFrame.CloseButton:HookScript("OnMouseDown", function(self, button)
	if button == "RightButton" then
		local parent = self:GetParent()
		self.isScaling = true
		parent:StartSizing("BOTTOMRIGHT")
	end
end)
SCForgeMainFrame.CloseButton:HookScript("OnMouseUp", function(self, button)
	if button == "RightButton" then
		local parent = self:GetParent()
		self.isScaling = false
		parent:StopMovingOrSizing()
	end
end)

SCForgeMainFrame:SetScript("OnSizeChanged", function(self)
	local scale = updateFrameChildScales(self)
	if vaultStyle == 2 then
		local newHeight = self:GetHeight()
		local ratio = newHeight/mainFrameSize.y
		SCForgeLoadFrame:SetSize(280*ratio, self:GetHeight())
	end
end)

SCForgeMainFrame.AddSpellRowButton = CreateFrame("BUTTON", nil, SCForgeMainFrame)
SCForgeMainFrame.AddSpellRowButton:SetPoint("BOTTOMRIGHT", -40, 2)
SCForgeMainFrame.AddSpellRowButton:SetSize(24,24)
SCForgeMainFrame.AddSpellRowButton:SetNormalAtlas("communities-chat-icon-plus")
SCForgeMainFrame.AddSpellRowButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

SCForgeMainFrame.AddSpellRowButton.DisabledTex = SCForgeMainFrame.AddSpellRowButton:CreateTexture(nil, "ARTWORK")
SCForgeMainFrame.AddSpellRowButton.DisabledTex:SetAllPoints(true)
SCForgeMainFrame.AddSpellRowButton.DisabledTex:SetAtlas("communities-chat-icon-plus")
SetDesaturation(SCForgeMainFrame.AddSpellRowButton.DisabledTex, true)
SCForgeMainFrame.AddSpellRowButton.DisabledTex:SetVertexColor(.6,.6,.6)
SCForgeMainFrame.AddSpellRowButton:SetDisabledTexture(SCForgeMainFrame.AddSpellRowButton.DisabledTex)

SCForgeMainFrame.AddSpellRowButton.PushedTex = SCForgeMainFrame.AddSpellRowButton:CreateTexture(nil, "ARTWORK")
SCForgeMainFrame.AddSpellRowButton.PushedTex:SetAllPoints(true)
SCForgeMainFrame.AddSpellRowButton.PushedTex:SetAtlas("communities-chat-icon-plus")
SCForgeMainFrame.AddSpellRowButton.PushedTex:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
SCForgeMainFrame.AddSpellRowButton.PushedTex:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
SCForgeMainFrame.AddSpellRowButton.PushedTex:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
SCForgeMainFrame.AddSpellRowButton.PushedTex:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
SCForgeMainFrame.AddSpellRowButton:SetPushedTexture(SCForgeMainFrame.AddSpellRowButton.PushedTex)

SCForgeMainFrame.AddSpellRowButton:SetMotionScriptsWhileDisabled(true)
SCForgeMainFrame.AddSpellRowButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(SCForgeMainFrame.AddSpellRowButton, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Add another Action row.", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Max number of Rows: "..maxNumberOfSpellRows,1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.AddSpellRowButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)
SCForgeMainFrame.AddSpellRowButton:SetScript("OnClick", function(self)
	AddSpellRow()
end)

-- Remove Spell Row
SCForgeMainFrame.RemoveSpellRowButton = CreateFrame("BUTTON", nil, SCForgeMainFrame)
SCForgeMainFrame.RemoveSpellRowButton:SetPoint("RIGHT", SCForgeMainFrame.AddSpellRowButton, "LEFT", -5, 0)
SCForgeMainFrame.RemoveSpellRowButton:SetSize(24,24)

SCForgeMainFrame.RemoveSpellRowButton:SetNormalAtlas("communities-chat-icon-minus", true)
SCForgeMainFrame.RemoveSpellRowButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

SCForgeMainFrame.RemoveSpellRowButton.DisabledTex = SCForgeMainFrame.RemoveSpellRowButton:CreateTexture(nil, "ARTWORK")
SCForgeMainFrame.RemoveSpellRowButton.DisabledTex:SetAllPoints(true)
SCForgeMainFrame.RemoveSpellRowButton.DisabledTex:SetAtlas("communities-chat-icon-minus")
SetDesaturation(SCForgeMainFrame.RemoveSpellRowButton.DisabledTex, true)
SCForgeMainFrame.RemoveSpellRowButton.DisabledTex:SetVertexColor(.6,.6,.6)
SCForgeMainFrame.RemoveSpellRowButton:SetDisabledTexture(SCForgeMainFrame.RemoveSpellRowButton.DisabledTex)

SCForgeMainFrame.RemoveSpellRowButton.PushedTex = SCForgeMainFrame.RemoveSpellRowButton:CreateTexture(nil, "ARTWORK")
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetAllPoints(true)
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetAtlas("communities-chat-icon-minus")
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
SCForgeMainFrame.RemoveSpellRowButton:SetPushedTexture(SCForgeMainFrame.RemoveSpellRowButton.PushedTex)

SCForgeMainFrame.RemoveSpellRowButton:SetMotionScriptsWhileDisabled(true)
SCForgeMainFrame.RemoveSpellRowButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(SCForgeMainFrame.RemoveSpellRowButton, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Remove the last Action row.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.RemoveSpellRowButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)
SCForgeMainFrame.RemoveSpellRowButton:SetScript("OnClick", function(self)
	RemoveSpellRow()
end)

SCForgeMainFrame.ExecuteSpellButton = CreateFrame("BUTTON", nil, SCForgeMainFrame, "UIPanelButtonTemplate")
SCForgeMainFrame.ExecuteSpellButton:SetPoint("BOTTOM", 0, 3)
SCForgeMainFrame.ExecuteSpellButton:SetSize(24*4,24)
SCForgeMainFrame.ExecuteSpellButton:SetText("Execute")
SCForgeMainFrame.ExecuteSpellButton:SetScript("OnClick", function()
	local actionsToCommit = {}
	for i = 1, numberOfSpellRows do
		if isNotDefined(tonumber(_G["spellRow"..i.."MainDelayBox"]:GetText())) then 
			cprint("Action Row "..i.." Invalid, Delay Not Set") 
		else
			local actionData = {}
			actionData.actionType = (_G["spellRow"..i.."SelectedAction"])
			actionData.delay = tonumber(_G["spellRow"..i.."MainDelayBox"]:GetText())
			actionData.revertDelay = tonumber(_G["spellRow"..i.."RevertDelayBox"]:GetText())
			actionData.selfOnly = _G["spellRow"..i.."SelfCheckbox"]:GetChecked()
			actionData.vars = _G["spellRow"..i.."InputEntryBox"]:GetText()
			dprint(false, dump(actionData))
			table.insert(actionsToCommit, actionData)
		end
	end
	executeSpell(actionsToCommit)
end)
SCForgeMainFrame.ExecuteSpellButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Execute the above Actions.", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Useful to test your spell before saving.",1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.ExecuteSpellButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)

local function loadSpell(spellKey)
	print("Loading spell.. "..spellKey)
	spellToLoad = SpellCreatorSavedSpells[spellKey]
	
	SCForgeMainFrame.SpellInfoCommandBox:SetText(spellToLoad.commID)
	SCForgeMainFrame.SpellInfoNameBox:SetText(spellToLoad.fullName)
	
	numberOfActionsToLoad = #spellToLoad.actions
	
	-- Adjust the number of available Action Rows
	if numberOfActionsToLoad > numberOfSpellRows then
		for i = 1, numberOfActionsToLoad-numberOfSpellRows do
			AddSpellRow()
		end
	elseif numberOfActionsToLoad < numberOfSpellRows then
		for i = 1, numberOfSpellRows-numberOfActionsToLoad do
			RemoveSpellRow()
		end
	end
	
	-- Loop thru actions & set their data
	local rowNum, actionData
	for rowNum, actionData in ipairs(spellToLoad.actions) do
		for k,v in pairs(_G["spellRow"..rowNum].menuList) do
			v.checked = false
		end
		UIDropDownMenu_SetSelectedID(_G["spellRow"..rowNum.."ActionSelectButton"], get_Table_Position(actionData.actionType, actionTypeDataList))
		_G["spellRow"..rowNum.."ActionSelectButtonText"]:SetText(actionTypeData[actionData.actionType].name)
		updateSpellRowOptions(rowNum, actionData.actionType)
		
		_G["spellRow"..rowNum.."MainDelayBox"]:SetText(tonumber(actionData.delay)) --delay
		if actionData.selfOnly then _G["spellRow"..rowNum.."SelfCheckbox"]:SetChecked(true) else _G["spellRow"..rowNum.."SelfCheckbox"]:SetChecked(false) end --SelfOnly
		if actionData.vars then _G["spellRow"..rowNum.."InputEntryBox"]:SetText(actionData.vars) else _G["spellRow"..rowNum.."InputEntryBox"]:SetText("") end --Input Entrybox
		if actionData.revertDelay then
			_G["spellRow"..rowNum.."RevertDelayBox"]:SetText(actionData.revertDelay) --revertDelay
			_G["spellRow"..rowNum.."RevertCheckbox"]:SetChecked(true) --Revert Checkbox
		else
			_G["spellRow"..rowNum.."RevertDelayBox"]:SetText("") --revertDelay
			_G["spellRow"..rowNum.."RevertCheckbox"]:SetChecked(false) --Revert Checkbox
		end
	end
end

local function deleteSpellConf(spellKey)
	local dialog = StaticPopup_Show("SCFORGE_CONFIRM_DELETE", SpellCreatorSavedSpells[spellKey].fullName, SpellCreatorSavedSpells[spellKey].commID)
	if dialog then dialog.data = spellKey end
end

local loadRowHeight = 30
local loadRowSpacing = 10
local function updateSpellLoadRows()
	local spellLoadRows = SCForgeMainFrame.LoadSpellFrame.Rows
	for i = 1, #spellLoadRows do
		spellLoadRows[i]:Hide()
	end
	local spellLoadFrame = SCForgeMainFrame.LoadSpellFrame.scrollFrame.scrollChild
	local rowNum = 0
	local columnWidth = (spellLoadFrame:GetWidth())/2
	if vaultStyle == 2 then 
		columnWidth = columnWidth*2;
		loadRowSpacing = 5
	end
	for k,v in orderedPairs(SpellCreatorSavedSpells) do
		rowNum = rowNum+1
		if spellLoadRows[rowNum] then
			spellLoadRows[rowNum]:Show()
			dprint(false,"SCForge Load Row "..rowNum.." Already existed - showing & setting it")
			
			-- make sure to set the data, otherwise it will still use old data if new spells have been saved since last.
			spellLoadRows[rowNum].spellName:SetText(v.fullName)
			spellLoadRows[rowNum].loadButton.commID = k
			spellLoadRows[rowNum].deleteButton.commID = k
		else
			dprint(false,"SCForge Load Row "..rowNum.." Didn't exist - making it!")
			spellLoadRows[rowNum] = CreateFrame("Frame", "scForgeLoadRow"..rowNum, spellLoadFrame)
			
			-- Position the Rows
			if vaultStyle == 2 then
				if rowNum == 1 then
					spellLoadRows[rowNum]:SetPoint("TOPLEFT", spellLoadFrame, "TOPLEFT", 8, -8)
				else
					spellLoadRows[rowNum]:SetPoint("TOPLEFT", spellLoadRows[rowNum-1], "BOTTOMLEFT", 0, -loadRowSpacing)
				end
				spellLoadRows[rowNum]:SetWidth(columnWidth-20)
			else
				if rowNum == 1 then
					spellLoadRows[rowNum]:SetPoint("TOPRIGHT", spellLoadFrame, "TOP", -5, -5)
				elseif rowNum == 2 then
					spellLoadRows[rowNum]:SetPoint("TOPLEFT", spellLoadFrame, "TOP", 5, -5)
				else
					spellLoadRows[rowNum]:SetPoint("TOPLEFT", spellLoadRows[rowNum-2], "BOTTOMLEFT", 0, -loadRowSpacing)
				end
				spellLoadRows[rowNum]:SetWidth(columnWidth-15)
			end
			spellLoadRows[rowNum]:SetHeight(loadRowHeight)
			
			spellLoadRows[rowNum]:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				self.Timer = C_Timer.NewTimer(0.7,function()
					GameTooltip:SetText("Spell: "..v.fullName, nil, nil, nil, nil, true)
					GameTooltip:AddLine("Command: '/sf "..v.commID.."'", 1, 1, 1, 1)
					GameTooltip:AddLine("Actions: "..#v.actions, 1, 1, 1, 1)
					GameTooltip:Show()
				end)
			end)
			spellLoadRows[rowNum]:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
			end)
			spellLoadRows[rowNum]:SetScript("OnMouseDown", function(self)
				if IsModifiedClick("CHATLINK") then
					ChatEdit_InsertLink(generateSpellChatLink(v.commID))
				end
			end)
			
			-- A nice lil background to make them easier to tell apart			
			spellLoadRows[rowNum].Background = spellLoadRows[rowNum]:CreateTexture(nil,"BACKGROUND")
			--spellLoadRows[rowNum].Background:SetAllPoints()
			spellLoadRows[rowNum].Background:SetPoint("TOPLEFT",-9,5)
			spellLoadRows[rowNum].Background:SetPoint("BOTTOMRIGHT",10,-5)
			spellLoadRows[rowNum].Background:SetAtlas("TalkingHeads-Neutral-TextBackground")
			--SetDesaturation(spellLoadRows[rowNum].Background, true)
			spellLoadRows[rowNum].Background:SetVertexColor(0.75,0.70,0.8)
			--spellLoadRows[rowNum].Background:SetColorTexture(1,1,1,0.25)
			
			spellLoadRows[rowNum].spellNameBackground = spellLoadRows[rowNum]:CreateTexture(nil, "BACKGROUND")
			spellLoadRows[rowNum].spellNameBackground:SetPoint("TOPLEFT", spellLoadRows[rowNum].Background, "TOPLEFT")
			spellLoadRows[rowNum].spellNameBackground:SetPoint("BOTTOMRIGHT", spellLoadRows[rowNum].Background, "BOTTOM", 10, 0)
			--spellLoadRows[rowNum].spellNameBackground:SetAtlas("parchmentpopup-hide-left")
			spellLoadRows[rowNum].spellNameBackground:SetColorTexture(1,1,1,0.25)
			spellLoadRows[rowNum].spellNameBackground:SetGradient("HORIZONTAL", 0.5,0.5,0.5,1,1,1)
			spellLoadRows[rowNum].spellNameBackground:SetBlendMode("MOD")
			
			--[[
			Atlas Ideas:
			islands-queue-card-namescroll
			AdventureMap_TileBg_Parchment
			parchmentpopup-top
			_AllianceFrame_Title-Tile
			UI-Frame-Alliance-CardParchment
			UI-Frame-Marine-CardParchment
			UI-Frame-Horde-CardParchment
			UI-Frame-Neutral-CardParchment
			
			UI-Frame-Alliance-CardParchmentWider 	--maybe
			Legionfall_Background					--meh
			store-card-splash1-nobanner				-- no
			FontStyle_Parchment						-- too plain?
			parchmentpopup-hide-left				-- maybe?
			loottab-background						-- okayish
			QuestBG-Legionfall						-- nope
			challenges-timerbg						-- usable with offset (TL -5, 2 | BR 3, -2)
			islands-queue-card2						-- could work ish
			TalkingHeads-Neutral-TextBackground		-- yes
			shop-card-full-15thAnniversary			-- no
			store-card-horizontalfull				
			shop-card-bundle
			--]]
			
			-- Make the Spell Name Text
			spellLoadRows[rowNum].spellName = spellLoadRows[rowNum]:CreateFontString(nil,"OVERLAY", "GameFontNormalMed2")
			spellLoadRows[rowNum].spellName:SetWidth(columnWidth/2)
			spellLoadRows[rowNum].spellName:SetJustifyH("LEFT")
			spellLoadRows[rowNum].spellName:SetPoint("LEFT", 1, 0)
			spellLoadRows[rowNum].spellName:SetText(v.fullName)
			--spellLoadRows[rowNum].spellName:SetTextColor(1, 1, 1)
			spellLoadRows[rowNum].spellName:SetShadowColor(0, 0, 0)
			spellLoadRows[rowNum].spellName:SetMaxLines(3) -- hardlimit to 3 lines, but soft limit to 2 later.

			-- Make the delete saved spell button
			spellLoadRows[rowNum].deleteButton = CreateFrame("BUTTON", nil, spellLoadRows[rowNum], "UIPanelButtonTemplate")
			local button = spellLoadRows[rowNum].deleteButton
			button.commID = k
			button:SetPoint("RIGHT", 0, 0)
			button:SetSize(20,20)
			button:SetText("x")
			button:SetScript("OnClick", function(self)
				deleteSpellConf(self.commID)
			end)
			button:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				self.Timer = C_Timer.NewTimer(0.7,function()
					GameTooltip:SetText("Delete '"..self.commID.."'", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
			end)
			button:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
			end)
			
						
			-- Make the load button
			spellLoadRows[rowNum].loadButton = CreateFrame("BUTTON", nil, spellLoadRows[rowNum], "UIPanelButtonTemplate")
			local button = spellLoadRows[rowNum].loadButton
			button.commID = k
			button:SetPoint("RIGHT", spellLoadRows[rowNum].deleteButton, "LEFT", 0, 0)
			button:SetSize(60,24)
			button:SetText("Edit")
			button:SetScript("OnClick", function(self)
				loadSpell(self.commID)
				if vaultStyle ~= 2 then SCForgeMainFrame.LoadSpellFrame:Hide(); end
			end)
			button:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				self.Timer = C_Timer.NewTimer(0.7,function()
					GameTooltip:SetText("Load spell '"..self.commID.."' into the forge, where you can edit it.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
			end)
			button:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
			end)
			
		end
		
		-- Limit our Spell Name to 2 lines - but by downsizing the text instead of truncating..
		do
			local fontName,fontHeight,fontFlags = spellLoadRows[rowNum].spellName:GetFont()
			spellLoadRows[rowNum].spellName:SetFont(fontName, 14, fontFlags) -- reset the font to default first, then test if we need to scale it down.
			while spellLoadRows[rowNum].spellName:GetNumLines() > 2 do
				fontName,fontHeight,fontFlags = spellLoadRows[rowNum].spellName:GetFont()
				spellLoadRows[rowNum].spellName:SetFont(fontName, fontHeight-1, fontFlags)
				if fontHeight-1 <= 8 then break end
			end
		end

		-- this will get an alphabetically sorted list of all spells, and their data. k = the key (commID), v = the spell's data table
		-- generate load lines here for each spell found. Re-use old lines if already made. See AddSpellRow() for copying it over.
		-- Load frame design:
		--	[Spell_1 Command]  [Spell_1 Name]  [Load_1 Button] | [Spell_2 Command]  [Spell_2 Name]  [Load_2 Button]
		--	[Spell_3 Command]  [Spell_3 Name]  [Load_3 Button] | [Spell_4 Command]  [Spell_4 Name]  [Load_4 Button]
		--	[Spell_5 Command]  [Spell_5 Name]  [Load_5 Button] | [Spell_6 Command]  [Spell_6 Name]  [Load_6 Button]
		--	[Spell_7 Command]  [Spell_7 Name]  [Load_7 Button] | [Spell_8 Command]  [Spell_8 Name]  [Load_8 Button]
		--	[Spell_9 Command]  [Spell_9 Name]  [Load_9 Button] | [Spell_10 Command] [Spell_10 Name] [Load_10 Button]
		-- ... etc
	end
	updateFrameChildScales(SCForgeMainFrame)
end

local function deleteSpell(spellKey)
	SpellCreatorSavedSpells[spellKey] = nil
	updateSpellLoadRows()
end

StaticPopupDialogs["SCFORGE_CONFIRM_DELETE"] = {
  text = "Are you sure you want to delete the spell?\n\rName: %s\nCommand: /sf %s\r",
  showAlert = true,
  button1 = "Delete",
  button2 = "Cancel",
  OnAccept = function(self, data)
      deleteSpell(data)
  end,
  timeout = 0,
  cancels = true,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

local function saveSpell(mousebutton)

	local wasOverwritten = false
	local newSpellData = {}
	newSpellData.commID = SCForgeMainFrame.SpellInfoCommandBox:GetText()
	newSpellData.fullName = SCForgeMainFrame.SpellInfoNameBox:GetText()
	newSpellData.actions = {}
	if isNotDefined(newSpellData.fullName) or isNotDefined(newSpellData.commID) then
		cprint("Spell Name and/or Spell Command cannot be blank.")
		return;
	end

		if SpellCreatorSavedSpells[newSpellData.commID] then
			if mousebutton and mousebutton == "RightButton" then
				wasOverwritten = true
			else
				--cprint("Duplicate Spell Command Detected.. Press Save with right-click to over-write the old spell.")
				StaticPopupDialogs["SCFORGE_CONFIRM_OVERWRITE"] = {
					text = "Spell '"..newSpellData.commID.."' Already exists.\n\rDo you want to overwrite the spell ("..newSpellData.fullName..")".."?",
					OnAccept = function() saveSpell("RightButton") end,
					button1 = "Overwrite",
					button2 = "Cancel",
					hideOnEscape = true,
					whileDead = true,
				}
				StaticPopup_Show("SCFORGE_CONFIRM_OVERWRITE")
				return;
			end
		end

	for i = 1, numberOfSpellRows do
		
			local actionData = {}
			actionData.delay = tonumber(_G["spellRow"..i.."MainDelayBox"]:GetText())
			if actionData.delay and actionData.delay >= 0 then
				actionData.actionType = (_G["spellRow"..i.."SelectedAction"])
				if actionTypeData[actionData.actionType] then
					actionData.revertDelay = tonumber(_G["spellRow"..i.."RevertDelayBox"]:GetText())
					actionData.selfOnly = _G["spellRow"..i.."SelfCheckbox"]:GetChecked()
					actionData.vars = _G["spellRow"..i.."InputEntryBox"]:GetText()
					table.insert(newSpellData.actions, actionData)
					dprint(false,"Action Row "..i.." Captured successfully.. pending final save to data..")
				else
					dprint(false,"Action Row "..i.." Failed to save - invalid Action Type.")
				end
			else
				dprint(false,"Action Row "..i.." Failed to save - invalid Main Delay.")
			end
	end
	
	if #newSpellData.actions >= 1 then
		--table.insert(SpellCreatorSavedSpells, newSpellData)
		SpellCreatorSavedSpells[newSpellData.commID] = newSpellData
		if wasOverwritten then
			cprint("Over-wrote spell with name: "..newSpellData.fullName..". Use command: '/sf "..newSpellData.commID.."' to cast it! ("..#newSpellData.actions.." actions).")
		else
			cprint("Saved spell with name: "..newSpellData.fullName..". Use command: '/sf "..newSpellData.commID.."' to cast it! ("..#newSpellData.actions.." actions).")
		end
	else
		cprint("Spell has no valid actions and was not saved. Please double check your actions & try again. You can turn on debug mode to see more information when trying to save (/sfdebug).")
	end
	updateSpellLoadRows()
end

SCForgeMainFrame.SaveSpellButton = CreateFrame("BUTTON", nil, SCForgeMainFrame, "UIPanelButtonTemplate")
SCForgeMainFrame.SaveSpellButton:SetPoint("BOTTOMLEFT", 20, 3)
SCForgeMainFrame.SaveSpellButton:SetSize(24*4,24)
SCForgeMainFrame.SaveSpellButton:SetText("Create")
SCForgeMainFrame.SaveSpellButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
SCForgeMainFrame.SaveSpellButton:SetScript("OnClick", function(self, button)
	saveSpell(button)
end)
SCForgeMainFrame.SaveSpellButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Create your spell!", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Finish your spell & save to the vault.\nIt can then be casted using '/sf commandID' for quick use!\n\r",1,1,1,true)
		GameTooltip:AddLine("Right-click to over-write a previous spell with the same Command ID without confirmation.",1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.SaveSpellButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)


SCForgeMainFrame.LoadSpellButton = CreateFrame("BUTTON", nil, SCForgeMainFrame, "UIPanelButtonTemplate")
SCForgeMainFrame.LoadSpellButton:SetPoint("LEFT", SCForgeMainFrame.SaveSpellButton, "RIGHT", 0, 0)
SCForgeMainFrame.LoadSpellButton:SetSize(24*4,24)
SCForgeMainFrame.LoadSpellButton:SetText("Vault")
SCForgeMainFrame.LoadSpellButton:SetScript("OnClick", function()
	if SCForgeMainFrame.LoadSpellFrame:IsShown() then
		SCForgeMainFrame.LoadSpellFrame:Hide()
	else
		SCForgeMainFrame.LoadSpellFrame:Show()
	end
end)
SCForgeMainFrame.LoadSpellButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Access your Vault", nil, nil, nil, nil, true)
		GameTooltip:AddLine("All of your created & saved spells are stored here.\n\rYou can load & manage your spells from the vault.",1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.LoadSpellButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)

--------- Load Spell Frame - aka the Vault

SCForgeMainFrame.LoadSpellFrame = CreateFrame("Frame", "SCForgeLoadFrame", SCForgeMainFrame, "ButtonFrameTemplate")
ButtonFrameTemplate_HidePortrait(SCForgeMainFrame.LoadSpellFrame)
if vaultStyle == 2 then 
	SCForgeMainFrame.LoadSpellFrame:SetPoint("TOPLEFT", SCForgeMainFrame, "TOPRIGHT", 0, 0)
	SCForgeMainFrame.LoadSpellFrame:SetSize(280,SCForgeMainFrame:GetHeight())
	SCForgeMainFrame.LoadSpellFrame:SetFrameStrata("MEDIUM")
	setResizeWithMainFrame(SCForgeMainFrame.LoadSpellFrame.Inset)
else
	SCForgeMainFrame.LoadSpellFrame:SetPoint("CENTER", UIParent, 0, 100)
	SCForgeMainFrame.LoadSpellFrame:SetSize(500,250)
	SCForgeMainFrame.LoadSpellFrame:SetFrameStrata("DIALOG")
end
SCForgeMainFrame.LoadSpellFrame:SetTitle("Spell Vault")
SCForgeMainFrame.LoadSpellFrame:Hide()
SCForgeMainFrame.LoadSpellFrame.Rows = {}
SCForgeMainFrame.LoadSpellFrame:HookScript("OnShow", function()
	dprint("Updating Spell Load Rows")
	updateSpellLoadRows()
end)

	SCForgeMainFrame.LoadSpellFrame.scrollFrame = CreateFrame("ScrollFrame", nil, SCForgeMainFrame.LoadSpellFrame.Inset, "UIPanelScrollFrameTemplate")
	local scrollFrame = SCForgeMainFrame.LoadSpellFrame.scrollFrame
	scrollFrame:SetPoint("TOPLEFT", 0, -3)
	scrollFrame:SetPoint("BOTTOMRIGHT", -24, 0)
	scrollFrame.ScrollBar.scrollStep = loadRowHeight+5

	SCForgeMainFrame.LoadSpellFrame.scrollFrame.scrollChild = CreateFrame("Frame")
	local scrollChild = SCForgeMainFrame.LoadSpellFrame.scrollFrame.scrollChild
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(SCForgeMainFrame.LoadSpellFrame.Inset:GetWidth()-12)
	scrollChild:SetHeight(1) 

--[[ -- Disabled button - Replacing with Tabbed Vault Experience
SCForgeMainFrame.LoadSpellFrame.moreVaultButton = CreateFrame("BUTTON", nil, SCForgeMainFrame.LoadSpellFrame, "UIPanelCloseButtonNoScripts")
SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetPoint("RIGHT", SCForgeLoadFrameCloseButton,"LEFT", 1, 0)
SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetSize(24,24)
--SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetSize(24,20)
--SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetText("P")
SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetNormalTexture("Interface/Buttons/UI-SquareButton-Up")
SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetPushedTexture("Interface/Buttons/UI-SquareButton-Down")
SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight")
SCForgeMainFrame.LoadSpellFrame.moreVaultButton.Icon = SCForgeMainFrame.LoadSpellFrame.moreVaultButton:CreateTexture(nil, "OVERLAY")
SCForgeMainFrame.LoadSpellFrame.moreVaultButton.Icon:SetPoint("CENTER")
SCForgeMainFrame.LoadSpellFrame.moreVaultButton.Icon:SetSize(16,16)
SCForgeMainFrame.LoadSpellFrame.moreVaultButton.Icon:SetTexture("interface/cursor/argusteleporter")
	-- Interface/CURSOR/voidstorage.blp
	-- interface/cursor/argusteleporter.blp , interface/cursor/trainer.blp , 
SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetScript("OnClick", function(self, button)
	InterfaceOptionsFrame_OpenToCategory(addonName);
	InterfaceOptionsFrame_OpenToCategory(addonName);
end)
SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Phase Vault", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Open the phases' spell vault, where you can pull spells from your current phase.",1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)
SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetScript("OnMouseDown", function(self)
	self.Icon:SetPoint("CENTER", self, "CENTER", -2, -1)
end)
SCForgeMainFrame.LoadSpellFrame.moreVaultButton:SetScript("OnMouseUp", function(self)
	self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0)
end)
--]]

--[[

SCForgeMainFrame.SpellActionButton = CreateFrame("CHECKBUTTON", nil, SCForgeMainFrame, "MacroButtonTemplate")
SCForgeMainFrame.SpellActionButton:SetPoint("center")
SCForgeMainFrame.SpellActionButton:SetSize(14,14)
SCForgeMainFrame.SpellActionButton:SetScript("OnClick", function(self)
	self:SetChecked(false);
	--PickupMacro()
end)
--]]


-- Gen First Row, and a few since who's gonna want just one anyways

AddSpellRow()
AddSpellRow()
AddSpellRow()
AddSpellRow()

-------------------------------------------------------------------------------
-- Custom Chat Link Stuff
-------------------------------------------------------------------------------

local function requestSpellFromPlayer(playerName, commID)
	dprint("Request Spell '"..commID.."' from "..playerName)
	C_ChatInfo.SendAddonMessage(addonMsgPrefix, commID, "WHISPER", playerName)
end

local function sendSpellToPlayer(playerName, commID)
	dprint("Sending Spell '"..commID.."' to "..playerName)
end

local function generateSpellChatLink(commID)
	local spellName = SpellCreatorSavedSpells[commID].fullName
	local spellComm = SpellCreatorSavedSpells[commID].commID
	local characterName = GetUnitName("player",false)
	local numActions = #SpellCreatorSavedSpells[commID].actions
	local chatLink = addonColor.."|HarcSpell:"..spellComm..":"..characterName..":"..spellName..":"..numActions.."|h["..spellName.."]|h|r"
	return chatLink;
end

local _ChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow
function ChatFrame_OnHyperlinkShow(...)
	pcall(_ChatFrame_OnHyperlinkShow, ...)
	if IsModifiedClick() then return end
	local linkType, linkData, displayText = LinkUtil.ExtractLink(select(3, ...))
	if linkType == "arcSpell" then
		spellComm, charName, spellName, numActions = strsplit(":", linkData)
		GameTooltip_SetTitle(ItemRefTooltip, addonColor..spellName)
		ItemRefTooltip:AddLine("Command: "..spellComm, 1, 1, 1, 1)
		ItemRefTooltip:AddLine("Actions: "..numActions, 1, 1, 1, 1 )
		ItemRefTooltip:AddDoubleLine( "Arcanum Spell", charName, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75 )
		ItemRefTooltip:AddLine(" ")
		C_Timer.After(0, function()
			local button
            if SCForgeSpellRefTooltipButton then
				button = SCForgeSpellRefTooltipButton
			else
				button = CreateFrame("BUTTON", "SCForgeSpellRefTooltipButton", ItemRefTooltip, "UIPanelButtonTemplate")
				button:SetScript("OnClick", function(self)
					requestSpellFromPlayer(self.playerName, self.commID)
				end)
				button:SetText("Request Spell")
			end
			button:SetHeight(GameTooltip_InsertFrame(ItemRefTooltip, button))
			button:SetPoint("RIGHT", -10, 0)
			button.playerName = charName
			button.commID = spellComm
			--
			ItemRefTooltip:Show()
			if ItemRefTooltipTextLeft1:GetRight() > ItemRefCloseButton:GetLeft() then
				ItemRefTooltip:SetPadding(16, 0)
			end
		end)
	end
end

-------------------------------------------------------------------------------
-- Mini-Map Icon
-------------------------------------------------------------------------------

local function scforge_showhide(where)
	if where == "options" then
		InterfaceOptionsFrame_OpenToCategory(addonName);
		InterfaceOptionsFrame_OpenToCategory(addonName);
	else
		if not SCForgeMainFrame:IsShown() then
			SCForgeMainFrame:Show()
		else
			SCForgeMainFrame:Hide()
		end
	end
end

local minimapButton = CreateFrame("Button", "SpellCreatorMinimapButton", Minimap)
minimapButton:SetMovable(true)
minimapButton:EnableMouse(true)
minimapButton:SetSize(33,33)
minimapButton:SetFrameStrata("MEDIUM"); 
minimapButton:SetFrameLevel("62"); 
minimapButton:SetClampedToScreen(true); 
minimapButton:SetClampRectInsets(5,-5,-5,5)
minimapButton:SetPoint("TOPLEFT")
minimapButton:RegisterForDrag("LeftButton","RightButton")
minimapButton:RegisterForClicks("LeftButtonUp","RightButtonUp")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local minimapShapes = {
	["ROUND"] = {true, true, true, true},
	["SQUARE"] = {false, false, false, false},
	["CORNER-TOPLEFT"] = {false, false, false, true},
	["CORNER-TOPRIGHT"] = {false, false, true, false},
	["CORNER-BOTTOMLEFT"] = {false, true, false, false},
	["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
	["SIDE-LEFT"] = {false, true, false, true},
	["SIDE-RIGHT"] = {true, false, true, false},
	["SIDE-TOP"] = {false, false, true, true},
	["SIDE-BOTTOM"] = {true, true, false, false},
	["TRICORNER-TOPLEFT"] = {false, true, true, true},
	["TRICORNER-TOPRIGHT"] = {true, false, true, true},
	["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
	["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
}

local RadialOffset = 10;	--minimapbutton offset
local function MinimapButton_UpdateAngle(radian)
	local x, y, q = math.cos(radian), math.sin(radian), 1;
	if x < 0 then q = q + 1 end
	if y > 0 then q = q + 2 end
	local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND";
	local quadTable = minimapShapes[minimapShape];
	local w = (Minimap:GetWidth() / 2) + RadialOffset	--10
	local h = (Minimap:GetHeight() / 2) + RadialOffset
	if quadTable[q] then
		x, y = x*w, y*h
	else
		local diagRadiusW = sqrt(2*(w)^2) - RadialOffset	--  -10
		local diagRadiusH = sqrt(2*(h)^2) - RadialOffset
		x = max(-w, min(x*diagRadiusW, w));
		y = max(-h, min(y*diagRadiusH, h));
	end
	minimapButton:ClearAllPoints()
	minimapButton:SetPoint("CENTER", "Minimap", "CENTER", x, y);
end

local function minimap_OnUpdate()
	local radian;

	local mx, my = Minimap:GetCenter();
	local px, py = GetCursorPosition();
	local scale = Minimap:GetEffectiveScale();
	px, py = px / scale, py / scale;
	radian = math.atan2(py - my, px - mx);

	MinimapButton_UpdateAngle(radian);
	SpellCreatorMasterTable.Options["mmLoc"] = radian;
end

minimapButton:SetScript("OnDragStart", function(self)
	self:LockHighlight()
	self:SetScript("OnUpdate", minimap_OnUpdate)
end)
minimapButton:SetScript("OnDragStop", function(self)
	self:UnlockHighlight()
	self:SetScript("OnUpdate", nil)
end)
minimapButton:SetScript("OnClick", function(self, button)
	if button == "LeftButton" then
		scforge_showhide()
	elseif button == "RightButton" then
		scforge_showhide("options")
	end
end)

minimapButton:SetScript("OnEnter", function(self)
	SetCursor("Interface/CURSOR/voidstorage.blp");
	-- interface/cursor/argusteleporter.blp , interface/cursor/trainer.blp , 
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(addonName)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("/arcanum - Toggle UI",1,1,1,true)
	GameTooltip:AddLine("/sfdebug - Toggle Debug",1,1,1,true)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("|cffFFD700Left-Click|r to toggle the main UI!",1,1,1,true)
	GameTooltip:AddLine("|cffFFD700Right-Click|r for Options, Changelog, and the Help Manual!",1,1,1,true)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Mouse over most UI Elements to see tooltips for help! (Like this one!)",0.9,0.75,0.75,true)
	GameTooltip:AddDoubleLine(" ", addonName.." v"..addonVersion, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8);
	GameTooltip:AddDoubleLine(" ", "by "..addonAuthor, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8);
	GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function(self)
	ResetCursor();
	GameTooltip:Hide()
end)
minimapButton.icon = minimapButton:CreateTexture("$parentIcon", "ARTWORK")
minimapButton.icon:SetTexture("interface\\icons\\inv_7xp_inscription_talenttome02")
minimapButton.icon:SetSize(21,21)
minimapButton.icon:SetPoint("CENTER")
minimapButton.border = minimapButton:CreateTexture("$parentBorder", "OVERLAY")
minimapButton.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapButton.border:SetSize(56,56)
minimapButton.border:SetPoint("TOPLEFT")

local function LoadMinimapPosition()
	local radian = tonumber(SpellCreatorMasterTable.Options["mmLoc"]) or 2.7
	MinimapButton_UpdateAngle(radian);
	if not SpellCreatorMasterTable.Options["minimapIcon"] then minimapButton:Hide() end
end

-------------------------------------------------------------------------------
-- Interface Options - Addon section
-------------------------------------------------------------------------------

function CreateSpellCreatorInterfaceOptions()
	SpellCreatorInterfaceOptions = {};
	SpellCreatorInterfaceOptions.panel = CreateFrame( "Frame", "SpellCreatorInterfaceOptionsPanel", UIParent );
	SpellCreatorInterfaceOptions.panel.name = addonName;
	
	local SpellCreatorInterfaceOptionsHeader = SpellCreatorInterfaceOptions.panel:CreateFontString("HeaderString", "OVERLAY", "GameFontNormalLarge")
	SpellCreatorInterfaceOptionsHeader:SetPoint("TOPLEFT", 15, -15)
	SpellCreatorInterfaceOptionsHeader:SetText(addonName.." v"..addonVersion.." by "..addonAuthor)
		
	local scrollFrame = CreateFrame("ScrollFrame", nil, SpellCreatorInterfaceOptions.panel, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 3, -75)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 90)
	
	scrollFrame.backdrop = CreateFrame("FRAME", nil, scrollFrame)
	scrollFrame.backdrop:SetPoint("TOPLEFT", scrollFrame, 3, 3)
	scrollFrame.backdrop:SetPoint("BOTTOMRIGHT", scrollFrame, 26, -3)
	scrollFrame.backdrop:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 14,
    insets = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4,
    },
})
	scrollFrame.backdrop:SetBackdropColor(0, 0, 0, 0.25)
	scrollFrame.backdrop:SetFrameLevel(2)

	scrollFrame.Title = scrollFrame.backdrop:CreateFontString(nil,'ARTWORK')
	scrollFrame.Title:SetFont(STANDARD_TEXT_FONT,12,'OUTLINE')
	scrollFrame.Title:SetTextColor(1,1,1)
	scrollFrame.Title:SetText("Spells")
	scrollFrame.Title:SetPoint('TOP',scrollFrame.backdrop,0,5)

	-- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
	local scrollChild = CreateFrame("Frame")
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(InterfaceOptionsFramePanelContainer:GetWidth()-18)
	scrollChild:SetHeight(1) 

	-- Add widgets to the scrolling child frame as desired


--  -- Testing to force the scroll frame to have a bunch to scroll
	local footer = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	footer:SetPoint("TOP", 0, -5000)
	footer:SetText("This is 5000 below the top, so the scrollChild automatically expanded.")
--]]
	
	
	local SpellCreatorInterfaceOptionsInventoryIDsList = SpellCreatorInterfaceOptions.panel:CreateFontString("Inventory Slot IDs", "OVERLAY", "GameFontNormalLeft")
	SpellCreatorInterfaceOptionsInventoryIDsList:SetPoint("BOTTOMLEFT", 20, 70)
	SpellCreatorInterfaceOptionsInventoryIDsList:SetText("Inventory Slot IDs:")
	SpellListHorizontalSpacing = 160
		local SpellCreatorInterfaceOptionsInventoryIDsListRow1 = SpellCreatorInterfaceOptions.panel:CreateFontString("SpellRow1","OVERLAY",SpellCreatorInterfaceOptionsInventoryIDsList)
		SpellCreatorInterfaceOptionsInventoryIDsListRow1:SetPoint("TOPLEFT",SpellCreatorInterfaceOptionsInventoryIDsList,"BOTTOMLEFT",9,-15)
		local SpellCreatorInterfaceOptionsInventoryIDsListRow2 = SpellCreatorInterfaceOptions.panel:CreateFontString("SpellRow2","OVERLAY",SpellCreatorInterfaceOptionsInventoryIDsListRow1)
		SpellCreatorInterfaceOptionsInventoryIDsListRow2:SetPoint("TOPLEFT",SpellCreatorInterfaceOptionsInventoryIDsListRow1,"BOTTOMLEFT",0,-25)
			local SpellCreatorInterfaceOptionsInventoryIDsListSpell1 = SpellCreatorInterfaceOptions.panel:CreateFontString("Spell1","OVERLAY","GameFontNormalLeft")
				SpellCreatorInterfaceOptionsInventoryIDsListSpell1:SetPoint("LEFT",SpellCreatorInterfaceOptionsInventoryIDsListRow1,"RIGHT",SpellListHorizontalSpacing*0,0)
				SpellCreatorInterfaceOptionsInventoryIDsListSpell1:SetText("Head: 1      Shoulders: 2      Shirt: 4      Chest: 5      Waist: 6      Legs 6      Feet: 8      Wrist: 9")

			local SpellCreatorInterfaceOptionsInventoryIDsListSpell4 = SpellCreatorInterfaceOptions.panel:CreateFontString("Spell4","OVERLAY","GameFontNormalLeft")
				SpellCreatorInterfaceOptionsInventoryIDsListSpell4:SetPoint("LEFT",SpellCreatorInterfaceOptionsInventoryIDsListRow2,"RIGHT",SpellListHorizontalSpacing*0,0)
				SpellCreatorInterfaceOptionsInventoryIDsListSpell4:SetText("Hands: 10      Back: 15      Main-hand: 16      Off-hand: 17      Ranged: 18      Tabard: 19 ")

	--Minimap Icon Toggle
	local SpellCreatorInterfaceOptionsMiniMapToggle = CreateFrame("CHECKBUTTON", "SC_ToggleMiniMapIconOption", SpellCreatorInterfaceOptions.panel, "InterfaceOptionsCheckButtonTemplate")
	SC_ToggleMiniMapIconOption:SetPoint("TOPLEFT", 20, -40)
	SC_ToggleMiniMapIconOptionText:SetText("Enable the Minimap Button / Icon")
	SC_ToggleMiniMapIconOption:SetScript("OnShow", function(self)
		if SpellCreatorMasterTable.Options["minimapIcon"] == true then
			self:SetChecked(true)
		else
			self:SetChecked(false)
		end
	end)
	SC_ToggleMiniMapIconOption:SetScript("OnClick", function(self)
		SpellCreatorMasterTable.Options["minimapIcon"] = not SpellCreatorMasterTable.Options["minimapIcon"]
		if SpellCreatorMasterTable.Options["minimapIcon"] then
			minimapButton:Show()
		else
			minimapButton:Hide()
		end
	end)
	SC_ToggleMiniMapIconOption:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		self.Timer = C_Timer.NewTimer(0.7,function()
			GameTooltip:SetText("Toggle the mini map icon on / off.", nil, nil, nil, nil, true)
			GameTooltip:Show()
		end)
	end)
	SC_ToggleMiniMapIconOption:SetScript("OnLeave", function(self)
		GameTooltip_Hide()
		self.Timer:Cancel()
	end)
	
	local SpellCreatorInterfaceOptionsDebug = CreateFrame("CHECKBUTTON", "SC_DebugToggleOption", SpellCreatorInterfaceOptions.panel, "OptionsSmallCheckButtonTemplate")
	SC_DebugToggleOption:SetPoint("BOTTOMRIGHT", 0, 0)
	SC_DebugToggleOption:SetHitRectInsets(-35,0,0,0)
	SC_DebugToggleOptionText:SetTextColor(1,1,1,1)
	SC_DebugToggleOptionText:SetText("Debug")
	SC_DebugToggleOptionText:SetPoint("LEFT", -30, 0)
	SC_DebugToggleOption:SetScript("OnShow", function(self)
		updateSCInterfaceOptions()
	end)
	SC_DebugToggleOption:SetScript("OnClick", function(self)
		SpellCreatorMasterTable.Options["debug"] = not SpellCreatorMasterTable.Options["debug"]
		if SpellCreatorMasterTable.Options["debug"] then
			cprint("Toggled Debug (VERBOSE) Mode")
		end
	end)
	
	InterfaceOptions_AddCategory(SpellCreatorInterfaceOptions.panel);
	updateSCInterfaceOptions() -- Call this because OnShow isn't triggered first time, and neither is OnLoad for some reason, so lets just update them manually
end

function updateSCInterfaceOptions()
	if SpellCreatorMasterTable.Options["debug"] == true then SC_DebugToggleOption:SetChecked(true) else SC_DebugToggleOption:SetChecked(false) end
end

-------------------------------------------------------------------------------
-- Addon Loaded & Communication
-------------------------------------------------------------------------------

local function onCommReceived(message, channel, sender)
	sendSpellToPlayer(sender, message)
end

local SCForge_OnEvent = CreateFrame("frame","SCForge_OnEvent");
SCForge_OnEvent:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
	if event == "CHAT_MSG_ADDON" and prefix == addonMsgPrefix then
		onCommReceived(message, channel, sender)
	end
end)
SCForge_OnEvent:RegisterEvent("CHAT_MSG_ADDON")


local SC_Addon_OnLoad = CreateFrame("frame","SC_Addon_OnLoad");
SC_Addon_OnLoad:RegisterEvent("ADDON_LOADED");
SC_Addon_OnLoad:SetScript("OnEvent", function(self,event,name)
	if name == "SpellCreator" then
				
		SC_loadMasterTable();
		LoadMinimapPosition();
	
		--Quickly Show / Hide the Frame on Start-Up to initialize everything for key bindings & loading
		C_Timer.After(1,function()
			SCForgeMainFrame:Show();
			if not SpellCreatorMasterTable.Options["debug"] then SCForgeMainFrame:Hide(); --[[ SCForgeLoadFrame:Hide() ]] end
		end)
		
		-- Adjust Radial Offset for Minimap Icon for alternate UI Overhaul Addons
		if IsAddOnLoaded("AzeriteUI") then
			RadialOffset = 18;
		elseif IsAddOnLoaded("DiabolicUI") then
			RadialOffset = 12;
		elseif IsAddOnLoaded("GoldieSix") then
			--GoldpawUI
			RadialOffset = 18;
		elseif IsAddOnLoaded("GW2_UI") then
			RadialOffset = 44;
		elseif IsAddOnLoaded("SpartanUI") then
			RadialOffset = 8;
		else
			RadialOffset = 10;
		end
		
		CreateSpellCreatorInterfaceOptions()
		
		if SpellCreatorMasterTable.Options["minimapIcon"] then SC_ToggleMiniMapIconOption:SetChecked(true) end
		
	end
end);
-------------------------------------------------------------------------------
-- Version / Help / Toggle
-------------------------------------------------------------------------------

SLASH_SCFORGEHELP1, SLASH_SCFORGEHELP2 = '/arcanum', '/sf'; -- 3.
function SlashCmdList.SCFORGEHELP(msg, editbox) -- 4.
	if SpellCreatorMasterTable.Options["debug"] and msg == "debug" then
		cprint(addonName.." | DEBUG LIST")
		cprint("Version: "..addonVersion)
		cprint("Portrait: "..SC_randomFramePortrait)
	elseif #msg > 0 then
		dprint(false,"Casting Arcaum Spell by CommID: "..msg)
		if SpellCreatorSavedSpells[msg] then
			executeSpell(SpellCreatorSavedSpells[msg].actions)
		else
			cprint("No spell with Command "..msg.." found.")
		end
		--[[ --Old Array-Based table parser.
		local didWeCastSpell = false
		for i = 1, #SpellCreatorSavedSpells do
			spellData = SpellCreatorSavedSpells[i]
			if spellData.commID == msg then
				executeSpell(spellData.actions)
				didWeCastSpell = true
			end
		end
		if didWeCastSpell == false then
			cprint("No spell with Command "..msg.." found.")
		end
		--]]
	else
		scforge_showhide(msg)
	end
end

SLASH_SCFORGEDEBUG1 = '/sfdebug';
function SlashCmdList.SCFORGEDEBUG(msg, editbox) -- 4.
	if SpellCreatorMasterTable.Options["debug"] and msg == "resetSpells" then
		dprint(true, "All Arcaum Spells reset. #GoodBye #ThisCannotBeUndoneHopeYouDidn'tFuckUp!")
		SpellCreatorSavedSpells = {}
		updateSpellLoadRows()
	elseif SpellCreatorMasterTable.Options["debug"] and msg == "listSpells" then
		--print(dump(SpellCreatorSavedSpells))
		for k,v in orderedPairs(SpellCreatorSavedSpells) do
			print(k, dump(v))
		end
	elseif SpellCreatorMasterTable.Options["debug"] and msg == "listSpellKeys" then -- debug to list all spell keys by alphabetical order.
		local newTable = get_keys(SpellCreatorSavedSpells)
		table.sort(newTable)
		print(dump(newTable))
	else
		SpellCreatorMasterTable.Options["debug"] = not SpellCreatorMasterTable.Options["debug"]
		dprint(true, "SC-Forge Debug Set to: "..tostring(SpellCreatorMasterTable.Options["debug"]))
	end
end

SLASH_SCFORGETEST1 = '/sftest';
function SlashCmdList.SCFORGETEST(msg, editbox) -- 4.
	
	--[[
	local spellName = SpellCreatorSavedSpells[msg].fullName
	local printableTable = compressForChat(dump(SpellCreatorSavedSpells[msg]))
	print(printableTable)
	print(" ")
	local decodedTable = decompressForChat(printableTable)
	print(decodedTable)
	--]]
	sendchat(generateSpellChatLink(msg))
	
	
	--[[
	if msg == "newport" then
		SC_randomFramePortrait = frameIconOptions[fastrandom(#frameIconOptions)]
		SCForgeMainFrame:SetPortraitToAsset(SC_randomFramePortrait)
		cprint("Portrait: "..SC_randomFramePortrait)
	elseif msg == "addrow" then
		AddSpellRow()
	elseif msg == "removerow" then
		RemoveSpellRow()
	else
		delay, actionType, revertTime, selfOnly, vars = 1, "Equip", 0, nil, "125539,160175"
		processAction(delay, actionType, revertTime, selfOnly, vars)
	end
	--]]
end