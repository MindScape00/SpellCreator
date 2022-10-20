local addonName, addonTable = ...
local addonVersion, addonAuthor, addonTitle = GetAddOnMetadata(addonName, "Version"), GetAddOnMetadata(addonName, "Author"), GetAddOnMetadata(addonName, "Title")
local addonFileName = GetAddOnInfo(addonName)
local addonColor = "|cff".."ce2eff" -- options: 7e1af0 (hard to read) -- 7814ea -- 8a30f1 -- 9632ff
local addonMsgPrefix = "SCFORGE"
local isAddonLoaded = false

local addonPath = "Interface/AddOns/"..tostring(addonName)

local localization = {}
localization.SPELLNAME = STAT_CATEGORY_SPELL.." "..NAME
localization.SPELLCOMM = STAT_CATEGORY_SPELL.." "..COMMAND

local savedSpellFromVault = {}

-- localized frequent functions for speed
local CTimerAfter = C_Timer.After
local C_Timer = C_Timer

--
local curDate = date("*t")

local LibDeflate
local AceSerializer
local AceComm
if LibStub then
	LibDeflate = LibStub:GetLibrary("LibDeflate")
	AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
	AceComm = LibStub:GetLibrary("AceComm-3.0")
end

local function serialCompressForAddonMsg(str)
	str = AceSerializer:Serialize(str)
	str = LibDeflate:CompressDeflate(str, {level = 9})
	--str = LibDeflate:EncodeForWoWAddonChannel(str)
	str = LibDeflate:EncodeForWoWChatChannel(str)
	return str;
end

local function serialDecompressForAddonMsg(str)
	--str = LibDeflate:DecodeForWoWAddonChannel(str)
	str = LibDeflate:DecodeForWoWChatChannel(str)
	str = LibDeflate:DecompressDeflate(str)
	_, str = AceSerializer:Deserialize(str)
	return str;
end

local vaultStyle = 2	-- 1 = pop-up window, 2 = attached tray

local sfCmd_ReplacerChar = "@N@"

-- local utils = Epsilon.utils
-- local messages = utils.messages
-- local server = utils.server
-- local tabs = utils.tabs

-- local main = Epsilon.main


-------------------------------------------------------------------------------
-- Simple Chat & Helper Functions
-------------------------------------------------------------------------------

local function cmd(text)
	SendChatMessage("."..text, "GUILD");
end

local function cmdNoDot(text)
	SendChatMessage(text, "GUILD");
end

local function cmdWithDotCheck(text)
	if text:sub(1, 1) == "." then cmdNoDot(text) else cmd(text) end
end

local function sendchat(text)
  SendChatMessage(text, "SAY");
end

-- Macro & /Slash Command Processing
local MacroEditBox = MacroEditBox
local dummy = function() end
local function RunMacroText(command)
	MacroEditBox:SetText(command)
	local ran = xpcall(ChatEdit_SendText, dummy, MacroEditBox)
	if not ran then
		eprint("This command failed: "..command)
	end
end

local function cprint(text)
	print(addonColor..addonTitle..": "..(text and text or "ERROR").."|r")
end

local function dprint(force, text, ...)
	if text then
		if force == true or SpellCreatorMasterTable.Options["debug"] then
			local rest = ... or ""
			local line = strmatch(debugstack(2),":(%d+):")
			if line then
				print(addonColor..addonTitle.." DEBUG "..line..": "..text, rest, " |r")
			else
				print(addonColor..addonTitle.." DEBUG: "..text, rest, " |r")
				print(debugstack(2))
			end
		end
	elseif SpellCreatorMasterTable.Options["debug"] then
		local line = strmatch(debugstack(2),":(%d+):")
		if line then
			print(addonColor..addonTitle.." DEBUG "..line..": "..force.." |r")
		else
			print(addonColor..addonTitle.." DEBUG: "..force.." |r")
			print(debugstack(2))
		end
	end
end

local function eprint(text,rest)
	local line = strmatch(debugstack(2),":(%d+):")
	if line then
		print(addonColor..addonTitle.." Error @ "..line..": "..text.." | "..(rest and " | "..rest or "").." |r")
	else
		print(addonColor..addonTitle.." @ ERROR: "..text.." | "..rest.." |r")
		print(debugstack(2))
	end
end

local dump = DevTools_Dump or function(o)
--local function dump(o)
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

local function hsvToRgb(h, s, v)
  local r, g, b

  local i = math.floor(h * 6);
  local f = h * 6 - i;
  local p = v * (1 - s);
  local q = v * (1 - f * s);
  local t = v * (1 - (1 - f) * s);

  i = i % 6

  if i == 0 then r, g, b = v, t, p
  elseif i == 1 then r, g, b = q, v, p
  elseif i == 2 then r, g, b = p, v, t
  elseif i == 3 then r, g, b = p, q, v
  elseif i == 4 then r, g, b = t, p, v
  elseif i == 5 then r, g, b = v, p, q
  end

  return r * 255, g * 255, b * 255
end

-- Frame Listeners
local phaseAddonDataListener = CreateFrame("Frame")
local phaseAddonDataListener2 = CreateFrame("Frame")
local isSavingOrLoadingPhaseAddonData = false

-------------------------------------------------------------------------------
-- Saved Variable Initialization
-------------------------------------------------------------------------------

local function isNotDefined(s)
	return s == nil or s == '';
end
SpellCreatorMasterTable = {}
SpellCreatorMasterTable.Options = {}
local function SC_loadMasterTable()

	if isNotDefined(SpellCreatorMasterTable.Options["debug"]) then SpellCreatorMasterTable.Options["debug"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["locked"]) then SpellCreatorMasterTable.Options["locked"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["mmLoc"]) then SpellCreatorMasterTable.Options["mmLoc"] = 2.7 end
	if isNotDefined(SpellCreatorMasterTable.Options["showTooltips"]) then SpellCreatorMasterTable.Options["showTooltips"] = true end
	if isNotDefined(SpellCreatorMasterTable.Options["biggerInputBox"]) then SpellCreatorMasterTable.Options["biggerInputBox"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["showVaultOnShow"]) then SpellCreatorMasterTable.Options["showVaultOnShow"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["clearRowOnRemove"]) then SpellCreatorMasterTable.Options["clearRowOnRemove"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["loadChronologically"]) then SpellCreatorMasterTable.Options["loadChronologically"] = false end
	
	if not SpellCreatorSavedSpells then SpellCreatorSavedSpells = {} end
	
	if (curDate.year >= 2023 or curDate.yday >= 298) then -- Only default to showing the minimap icon after October 25th, 2022
		if isNotDefined(SpellCreatorMasterTable.Options["minimapIcon"]) then SpellCreatorMasterTable.Options["minimapIcon"] = true end
	end
end

-------------------------------------------------------------------------------
-- UI Stuff
-------------------------------------------------------------------------------

--[[
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
--]]

local arcaneGemPath = addonPath.."/assets/gem-icons/Gem"
local arcaneGemIcons = {
"Blue",
--"Green",
"Indigo",
"Jade",
"Orange",
"Pink",
"Prismatic",
"Red",
"Violet",
--"Yellow",
}

--SCForgeMainFrame.portrait.icon:SetTexture("Interface/AddOns/SpellCreator/assets/gem-icons/GemViolet")

local runeIconOverlays = {}
local runeIconOverlay

local function initRuneIcon()
	runeIconOverlays = {
		{atlas = "Rune-0"..fastrandom(6).."-purple", desat = false, x = 30, y = 30, alpha=0.8},
		{atlas = "Rune-"..string.format("%02d",fastrandom(11)).."-light", desat = true, x = 30, y = 30, alpha=0.8},
		{atlas = "ChallengeMode-Runes-BL-Glow", desat = true, x = 32, y = 32},
		{atlas = "ChallengeMode-Runes-BR-Glow", desat = true, x = 32, y = 32},
		{atlas = "ChallengeMode-Runes-L-Glow", desat = true, x = 34, y = 34},
		{atlas = "ChallengeMode-Runes-R-Glow", desat = true, x = 32, y = 32},
		{atlas = "ChallengeMode-Runes-T-Glow", desat = true, x = 32, y = 32},
		{atlas = "heartofazeroth-slot-minor-unactivated-rune", desat = true, x = 44, y = 44, alpha=0.8},
		{atlas = "Darklink-active", desat = true},
		{tex = addonPath.."/assets/BookIcon", desat = false, x = 26, y = 26},
	}
	runeIconOverlay = runeIconOverlays[fastrandom(#runeIconOverlays)]
end
initRuneIcon()

-- debug over-ride, comment out when done
-- runeIconOverlay = {tex = "Interface/AddOns/SpellCreator/assets/BookIcon"}


--[[	-- Old Background System stuff
local frameBackgroundOptions = {
"interface/archeology/arch-bookitemleft",
"interface/archeology/arch-bookitemleft",
"interface/archeology/arch-bookitemleft",
"interface/archeology/arch-bookitemleft",
"interface/archeology/arch-bookcompletedleft",
"interface/spellbook/spellbook-page-1",
-------- enter single background territory if > 6
"Interface/AddOns/SpellCreator/assets/bookbackground_full"
}

local frameBackgroundOptionsEdge = {
"interface/archeology/arch-bookitemright",
"interface/archeology/arch-bookitemright",
"interface/archeology/arch-bookitemright",
"interface/archeology/arch-bookitemright",
"interface/archeology/arch-bookcompletedright",
"interface/spellbook/spellbook-page-2",
}
--]]

local load_row_background = addonPath.."/assets/SpellForgeVaultPanelRow"

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

-- the functions to actually process & cast the spells

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
		if delay == 0 then
			local varTable = varTable
			for i = 1, #varTable do
				local v = varTable[i] -- v = the ID or input string.
				if string.byte(v,1) == 32 then v = strtrim(v, " ") end
				actionData.command(v)
			end
		else
			CTimerAfter(delay, function()
				local varTable = varTable
				for i = 1, #varTable do
					local v = varTable[i]
					if string.byte(v,1) == 32 then v = strtrim(v, " ") end
					actionData.command(v)
				end
			end)
		end
	else
		if actionData.dataName then
			if delay == 0 then
				local varTable = varTable
				for i = 1, #varTable do
					local v = varTable[i] -- v = the ID or input.
					if string.byte(v,1) == 32 then v = strtrim(v, " ") end
					--print(actionData.command)
					local finalCommand = tostring(actionData.command)
					finalCommand = finalCommand:gsub(sfCmd_ReplacerChar, v)
					if selfOnly then finalCommand = finalCommand.." self" end
					--dprint(false, finalCommand)
					cmd(finalCommand)
					
				end
				if revertDelay and revertDelay > 0 then
					CTimerAfter(revertDelay, function()
						local varTable = varTable
						for i = 1, #varTable do
							local v = varTable[i]
							if string.byte(v,1) == 32 then v = strtrim(v, " ") end
							if selfOnly then
								cmd(actionData.revert.." "..v.." self")
							else
								cmd(actionData.revert.." "..v)
							end
						end
					end)
				end
			else
				CTimerAfter(delay, function()
					local varTable = varTable
					for i = 1, #varTable do
						local v = varTable[i] -- v = the ID or input.
						if string.byte(v,1) == 32 then v = strtrim(v, " ") end
						local finalCommand = tostring(actionData.command)
						finalCommand = finalCommand:gsub(sfCmd_ReplacerChar, v)
						if selfOnly then finalCommand = finalCommand.." self" end
						--dprint(false, finalCommand)
						cmd(finalCommand)
						
					end
					if revertDelay and revertDelay > 0 then
						CTimerAfter(revertDelay, function()
							local varTable = varTable
							for i = 1, #varTable do
								local v = varTable[i]
								if string.byte(v,1) == 32 then v = strtrim(v, " ") end
								if selfOnly then
									cmd(actionData.revert.." "..v.." self")
								else
									cmd(actionData.revert.." "..v)
								end
							end
						end)
					end
				end)
			end
		else
			if selfOnly then
				CTimerAfter(delay, function() cmd(actionData.command.." self") end)
			else
				CTimerAfter(delay, function() cmd(actionData.command) end)
			end
		end
	end
end

local actionsToCommit = {}
local function executeSpell(actionsToCommit)
	if tonumber(C_Epsilon.GetPhaseId()) == 169 and GetRealZoneText() == "Dranosh Valley" and not C_Epsilon.IsOfficer() then cprint("Casting Arcanum Spells in Main Phase Start Zone is Disabled. Trying to test the Main Phase Vault spells? Head somewhere other than start.") return; end
	for _,spell in pairs(actionsToCommit) do
		--dprint(false,"Delay: "..spell.delay.." | ActionType: "..spell.actionType.." | RevertDelay: "..tostring(spell.revertDelay).." | Self: "..tostring(spell.selfOnly).." | Vars: "..tostring(spell.vars))
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
"MacroText",
"Command",
"ArcSpell",
}

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
	["MacroText"] = {
		["name"] = "Slash /Command",
		["command"] = function(command) RunMacroText(command); end,
		["description"] = "Any line that can be processed in a macro (any slash commands & macro flags).\n\rYou can use this for pretty much ANYTHING, technically, including custom short Lua scripts.",
		["dataName"] = "/command",
		["inputDescription"] = "Any /commands that can be processed in a macro-script, including emotes, addon commands, Lua run scripts, etc.\n\rI.e., '/emote begins to conjur up a fireball in their hand.' ",
		["comTarget"] = "func",
		["revert"] = nil,
		},
	["Command"] = {
		["name"] = "Server .Command",
		["command"] = cmdWithDotCheck,
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
		["description"] = "Equip a saved set from Blizzard's Equipment Manager, by name.",
		["dataName"] = "Set Name",
		["inputDescription"] = "Set name from Equipment Manager (Blizzard's built in set manager).",
		["comTarget"] = "func",
		["revert"] = nil,
		},
	["ArcSpell"] = {
		["name"] = "Arcanum Spell",
		["command"] = function(commID) executeSpell(SpellCreatorSavedSpells[commID].actions) end,
		["description"] = "Cast another Arcanum Spell from your Personal Vault.",
		["dataName"] = "Spell Command",
		["inputDescription"] = "The Command key used to cast the ArcSpell\n\rExample: '/sf MySpell', where MySpell is the command key to input here.",
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

local function generateSpellChatLink(commID, vaultType)
	local spellName = savedSpellFromVault[commID].fullName
	local spellComm = savedSpellFromVault[commID].commID
	local spellDesc = savedSpellFromVault[commID].description
	if spellDesc == nil then spellDesc = "" end
	local charOrPhase
	if vaultType == "PHASE" then
		charOrPhase = C_Epsilon.GetPhaseId()
	else
		charOrPhase = GetUnitName("player",false)
	end
	local numActions = #savedSpellFromVault[commID].actions
	local chatLink = addonColor.."|HarcSpell:"..spellComm..":"..charOrPhase..":"..spellName..":"..numActions..":"..spellDesc.."|h["..spellName.."]|h|r"
	return chatLink;
end

StaticPopupDialogs["SCFORGE_RELOADUI_REQUIRED"] = {
	text = "A UI Reload is Required to Change Input Boxes.\n\rReload Now?\r[Warning: All un-saved data will be wiped]",
	showAlert = true,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data, data2)
		ReloadUI();
	end,
	timeout = 0,
	cancels = true,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

-------------------------------------------------------------------------------
-- Main UI Frame
-------------------------------------------------------------------------------

local function RemoveSpellRow()
	if numberOfSpellRows <= 1 then return; end
	local theSpellRow = _G["spellRow"..numberOfSpellRows]
	theSpellRow:Hide()
	
	if SpellCreatorMasterTable.Options["clearRowOnRemove"] then
		theSpellRow.mainDelayBox:SetText("")
		
		for k,v in pairs(theSpellRow.menuList) do
			v.checked = false
		end
		UIDropDownMenu_SetSelectedID(_G["spellRow"..numberOfSpellRows.."ActionSelectButton"], 0)
		_G["spellRow"..numberOfSpellRows.."ActionSelectButtonText"]:SetText("Action")
		updateSpellRowOptions(numberOfSpellRows, nil)
		
		theSpellRow.SelfCheckbox:SetChecked(false)
		theSpellRow.InputEntryBox:SetText("")
		theSpellRow.RevertCheckbox:SetChecked(false)
		theSpellRow.RevertDelayBox:SetText("")
	end

	numberOfSpellRows = numberOfSpellRows - 1
	
	_G["spellRow"..numberOfSpellRows].RevertDelayBox.nextEditBox = spellRow1.mainDelayBox
	
	if numberOfSpellRows < maxNumberOfSpellRows then SCForgeMainFrame.AddSpellRowButton:Enable() end
	if numberOfSpellRows <= 1 then SCForgeMainFrame.RemoveSpellRowButton:Disable() end
	SCForgeMainFrame.Inset.scrollFrame:UpdateScrollChildRect()
end

local function AddSpellRow()
	if numberOfSpellRows >= maxNumberOfSpellRows then SCForgeMainFrame.AddSpellRowButton:Disable() return; end -- hard cap
	SCForgeMainFrame.RemoveSpellRowButton:Enable()
	numberOfSpellRows = numberOfSpellRows+1		-- The number of spell rows that this row will be.
	local newRow
	if _G["spellRow"..numberOfSpellRows] then 
		newRow = _G["spellRow"..numberOfSpellRows]
		newRow:Show();
	else

		-- The main row frame
		newRow = CreateFrame("Frame", "spellRow"..numberOfSpellRows, SCForgeMainFrame.Inset.scrollFrame.scrollChild)
		if numberOfSpellRows == 1 then
			newRow:SetPoint("TOPLEFT", 25, 0)
		else
			newRow:SetPoint("TOPLEFT", "spellRow"..numberOfSpellRows-1, "BOTTOMLEFT", 0, 0)
		end
		newRow:SetWidth(mainFrameSize.x-50)
		newRow:SetHeight(rowHeight)
				
		newRow.Background = newRow:CreateTexture(nil,"BACKGROUND", nil, 5)
		newRow.Background:SetAllPoints()
		newRow.Background:SetTexture(addonPath.."/assets/SpellForgeMainPanelRow1")
		newRow.Background:SetTexCoord(0.208,1-0.209,0,1)
		newRow.Background:SetPoint("BOTTOMRIGHT",-9,0)
		newRow.Background:SetAlpha(0.9)
		--newRow.Background:SetColorTexture(0,0,0,0.25)
		
		newRow.Background2 = newRow:CreateTexture(nil,"BACKGROUND", nil, 6)
		newRow.Background2:SetAllPoints()
		newRow.Background2:SetTexture(addonPath.."/assets/SpellForgeMainPanelRow2")
		newRow.Background2:SetTexCoord(0.208,1-0.209,0,1)
		newRow.Background2:SetPoint("TOPLEFT",-3,0)
		newRow.Background2:SetPoint("BOTTOMRIGHT",-7,0)
		--newRow.Background2:SetAlpha(0.8)
		--newRow.Background:SetColorTexture(0,0,0,0.25)
		
		newRow.RowGem = newRow:CreateTexture(nil,"ARTWORK")
		newRow.RowGem:SetPoint("CENTER", newRow.Background2, "LEFT", 2, 0)
		newRow.RowGem:SetHeight(40)
		newRow.RowGem:SetWidth(40)
		newRow.RowGem:SetTexture(addonPath.."/assets/DragonGem")
		--newRow.RowGem:SetTexCoord(0.208,1-0.209,0,1)
		--newRow.RowGem:SetPoint("RIGHT",-9,0)
		
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
				GameTooltip:AddLine("How long after 'casting' the ArcSpell this action triggers.\rCan be '0' for instant.",1,1,1,true)
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
		if SpellCreatorMasterTable.Options["biggerInputBox"] == true then
			newRow.InputEntryScrollFrame = CreateFrame("ScrollFrame", "spellRow"..numberOfSpellRows.."InputEntryScrollFrame", newRow, "InputScrollFrameTemplate")
			newRow.InputEntryScrollFrame.CharCount:Hide()
			newRow.InputEntryScrollFrame:SetSize(InputEntryColumnWidth+20,40)
			newRow.InputEntryScrollFrame:SetPoint("LEFT", newRow.SelfCheckbox, "RIGHT", 15, 0)
			newRow.InputEntryBox = newRow.InputEntryScrollFrame.EditBox
			_G["spellRow"..numberOfSpellRows.."InputEntryBox"] = newRow.InputEntryBox
			newRow.InputEntryBox:SetWidth(newRow.InputEntryScrollFrame:GetWidth()-18)
		else
			newRow.InputEntryBox = CreateFrame("EditBox", "spellRow"..numberOfSpellRows.."InputEntryBox", newRow, "InputBoxInstructionsTemplate")
			newRow.InputEntryBox:SetSize(InputEntryColumnWidth+20,23)
			newRow.InputEntryBox:SetPoint("LEFT", newRow.SelfCheckbox, "RIGHT", 15, 0)
		end

		newRow.InputEntryBox:SetFontObject(ChatFontNormal)
		newRow.InputEntryBox.disabledColor = GRAY_FONT_COLOR
		newRow.InputEntryBox.enabledColor = HIGHLIGHT_FONT_COLOR
		newRow.InputEntryBox.Instructions:SetText("select an action...")
		newRow.InputEntryBox.Instructions:SetTextColor(0.5,0.5,0.5)
		newRow.InputEntryBox.Description = ""
		newRow.InputEntryBox.rowNumber = numberOfSpellRows
		newRow.InputEntryBox:SetAutoFocus(false)
		newRow.InputEntryBox:Disable()

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
		newRow.RevertCheckbox:SetPoint("LEFT", (newRow.InputEntryScrollFrame or newRow.InputEntryBox), "RIGHT", 10, 0)
		newRow.RevertCheckbox.RowID = numberOfSpellRows
		newRow.RevertCheckbox:Disable()
		newRow.RevertCheckbox:SetMotionScriptsWhileDisabled(true)
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

	-- Make Tab work to switch edit boxes
	
	end
	
		newRow.mainDelayBox.nextEditBox = newRow.InputEntryBox 			-- Main Delay -> Input
		newRow.mainDelayBox.previousEditBox = newRow.mainDelayBox 	-- Main Delay <- Main Delay (Can't reverse past itself, updated later)
		newRow.InputEntryBox.nextEditBox = newRow.RevertDelayBox		-- Input -> Revert
		newRow.InputEntryBox.previousEditBox = newRow.mainDelayBox		-- Input <- Main Delay
		newRow.RevertDelayBox.nextEditBox = newRow.mainDelayBox			-- Revert -> Main Delay (we change it later if needed)
		newRow.RevertDelayBox.previousEditBox = newRow.InputEntryBox	-- Revert <- Input
	
	if numberOfSpellRows > 1 then	
		newRow.mainDelayBox.previousEditBox = _G["spellRow"..numberOfSpellRows-1].RevertDelayBox 	-- Main Delay <- LAST Revert
		newRow.RevertDelayBox.nextEditBox = spellRow1.mainDelayBox			-- Revert -> Spell Row 1 Main Delay
		_G["spellRow"..numberOfSpellRows-1].RevertDelayBox.nextEditBox = newRow.mainDelayBox		-- LAST Revert -> THIS Main Delay
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
		_G["spellRow"..row.."InputEntryBox"].Instructions:SetText("select an action...")
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
SCForgeMainFrame:SetToplevel(true);
SCForgeMainFrame:EnableMouse(true)
SCForgeMainFrame:SetClampedToScreen(true)
SCForgeMainFrame:SetClampRectInsets(300, -300, 0, 500)
SCForgeMainFrame:SetScript("OnShow", function(self)
	if SpellCreatorMasterTable.Options["showVaultOnShow"] == true then
		if not SCForgeMainFrame.LoadSpellFrame:IsShown() then
			SCForgeMainFrame.LoadSpellFrame:Show()
		end
	end
	self:Raise()
end)
SCForgeMainFrame:SetScript("OnMouseDown", function(self)
	self:Raise()
end)


SCForgeMainFrame.TitleBgColor = SCForgeMainFrame:CreateTexture(nil, "BACKGROUND")
SCForgeMainFrame.TitleBgColor:SetPoint("TOPLEFT", SCForgeMainFrame.TitleBg)
SCForgeMainFrame.TitleBgColor:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.TitleBg)
SCForgeMainFrame.TitleBgColor:SetColorTexture(0.30,0.10,0.40,0.5)

SCForgeMainFrame.SettingsButton = CreateFrame("BUTTON", nil, SCForgeMainFrame, "UIPanelButtonNoTooltipTemplate")
SCForgeMainFrame.SettingsButton:SetSize(24,24)
SCForgeMainFrame.SettingsButton:SetPoint("RIGHT", SCForgeMainFrame.CloseButton, "LEFT", 4, 0)
SCForgeMainFrame.SettingsButton.icon = SCForgeMainFrame.SettingsButton:CreateTexture(nil, "ARTWORK")
SCForgeMainFrame.SettingsButton.icon:SetTexture("interface/buttons/ui-optionsbutton")
SCForgeMainFrame.SettingsButton.icon:SetSize(16,16)
SCForgeMainFrame.SettingsButton.icon:SetPoint("CENTER")
SCForgeMainFrame.SettingsButton:SetScript("OnClick", function(self)
	InterfaceOptionsFrame_OpenToCategory(addonTitle);
	InterfaceOptionsFrame_OpenToCategory(addonTitle);
end)
SCForgeMainFrame.SettingsButton:SetScript("OnMouseDown", function(self)
	local point, relativeTo, relativePoint, xOfs, yOfs = self.icon:GetPoint(1)
	self.icon:SetPoint(point, relativeTo, relativePoint, xOfs+2, yOfs-2)
end)
SCForgeMainFrame.SettingsButton:SetScript("OnMouseUp", function(self)
	local point, relativeTo, relativePoint, xOfs, yOfs = self.icon:GetPoint(1)
	self.icon:SetPoint(point, relativeTo, relativePoint, xOfs-2, yOfs+2)
end)
SCForgeMainFrame.SettingsButton:SetScript("OnDisable", function(self)
	self.icon:GetDisabledTexture():SetDesaturated(true)
end)
SCForgeMainFrame.SettingsButton:SetScript("OnEnable", function(self)
	self.icon:GetDisabledTexture():SetDesaturated(false)
end)


--NineSliceUtil.ApplyLayout(SCForgeMainFrame, "BFAMissionAlliance") -- You can use this to apply other nine-slice templates to a nine-slice frame. We want a custom Nine-Slice tho so below is my application of it.

local myNineSliceFile_corners = addonPath.."/assets/frame_border_corners"
local myNineSliceFile_vert = addonPath.."/assets/frame_border_vertical"
local myNineSliceFile_horz = addonPath.."/assets/frame_border_horizontal"
local newNineSliceOverride = {
    TopLeftCorner = { tex = myNineSliceFile_corners, txl = 0.263672, txr = 0.521484, txt = 0.263672, txb = 0.521484, }, --0.263672, 0.521484, 0.263672, 0.521484
    --TopRightCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.263672, txb = 0.521484, }, -- 0.00195312, 0.259766, 0.263672, 0.521484
	TopRightCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.525391, txb = 0.783203, }, -- 0.00195312, 0.259766, 0.525391, 0.783203 -- this is the double button one in the top right corner.
    BottomLeftCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.00195312, txb = 0.259766, }, -- 0.00195312, 0.259766, 0.00195312, 0.259766
    BottomRightCorner = { tex = myNineSliceFile_corners, txl = 0.263672, txr = 0.521484, txt = 0.00195312, txb = 0.259766, }, -- 0.263672, 0.521484, 0.00195312, 0.259766
    TopEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.263672, txb = 0.521484, }, -- 0, 1, 0.263672, 0.521484
    BottomEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.00195312, txb = 0.259766, }, -- 0, 1, 0.00195312, 0.259766
    LeftEdge = { tex = myNineSliceFile_vert, txl = 0.00195312, txr = 0.259766, txt = 0, txb = 1, }, -- 0.00195312, 0.259766, 0, 1
    RightEdge = { tex = myNineSliceFile_vert, txl = 0.263672, txr = 0.521484, txt = 0, txb = 1, }, -- 0.263672, 0.521484, 0, 1
}
for k,v in pairs(newNineSliceOverride) do
	SCForgeMainFrame.NineSlice[k]:SetTexture(v.tex)
	SCForgeMainFrame.NineSlice[k]:SetTexCoord(v.txl, v.txr, v.txt, v.txb)
end

--local SC_randomFramePortrait = frameIconOptions[fastrandom(#frameIconOptions)] -- Old Random Icon Stuff
--SCForgeMainFrame:SetPortraitToAsset(SC_randomFramePortrait) -- Switched to using our version.
--SCForgeMainFrame.portrait:SetTexture(addonPath.."/assets/arcanum_icon")

SCForgeMainFrame.portrait:SetTexture(addonPath.."/assets/CircularBG")
SCForgeMainFrame.portrait:SetTexCoord(0.25,1-0.25,0,1)
SCForgeMainFrame.portrait.mask = SCForgeMainFrame:CreateMaskTexture()
SCForgeMainFrame.portrait.mask:SetAllPoints(SCForgeMainFrame.portrait)
SCForgeMainFrame.portrait.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
SCForgeMainFrame.portrait:AddMaskTexture(SCForgeMainFrame.portrait.mask)

SCForgeMainFrame.portrait.icon = SCForgeMainFrame:CreateTexture(nil, "OVERLAY", nil, 6)
SCForgeMainFrame.portrait.icon:SetTexture(arcaneGemPath..arcaneGemIcons[fastrandom(#arcaneGemIcons)])
SCForgeMainFrame.portrait.icon:SetAllPoints(SCForgeMainFrame.portrait)
--SCForgeMainFrame.portrait.icon:SetBlendMode("ADD")

SCForgeMainFrame.portrait.rune = SCForgeMainFrame:CreateTexture(nil, "OVERLAY", nil, 7)
local function setRuneTex(texInfo)
	if texInfo.atlas then 
		SCForgeMainFrame.portrait.rune:SetAtlas(texInfo.atlas)
	else
		SCForgeMainFrame.portrait.rune:SetTexture(texInfo.tex)
	end
	if texInfo.desat then
		SCForgeMainFrame.portrait.rune:SetDesaturated(true)
		SCForgeMainFrame.portrait.rune:SetVertexColor(0.9,0.9,0.9)
	else
		SCForgeMainFrame.portrait.rune:SetDesaturated(false)
		SCForgeMainFrame.portrait.rune:SetVertexColor(1,1,1)
	end
	SCForgeMainFrame.portrait.rune:SetPoint("CENTER", SCForgeMainFrame.portrait)
	SCForgeMainFrame.portrait.rune:SetSize(texInfo.x or 28, texInfo.y or 28)
	SCForgeMainFrame.portrait.rune:SetBlendMode(texInfo.blend or "ADD")
	SCForgeMainFrame.portrait.rune:SetAlpha(texInfo.alpha or 1)
end
setRuneTex(runeIconOverlay)

SCForgeMainFrame:SetTitle("Arcanum - Spell Forge")

SCForgeMainFrame.DragBar = CreateFrame("Frame", nil, SCForgeMainFrame)
SCForgeMainFrame.DragBar:SetPoint("TOPLEFT")
SCForgeMainFrame.DragBar:SetSize(mainFrameSize.x, 20)
SCForgeMainFrame.DragBar:EnableMouse(true)
SCForgeMainFrame.DragBar:RegisterForDrag("LeftButton")
SCForgeMainFrame.DragBar:SetScript("OnMouseDown", function(self)
    self:GetParent():Raise()
  end)
SCForgeMainFrame.DragBar:SetScript("OnDragStart", function(self)
    self:GetParent():StartMoving()
  end)
SCForgeMainFrame.DragBar:SetScript("OnDragStop", function(self)
    self:GetParent():StopMovingOrSizing()
  end)

-- The top bar Spell Info Boxes - Needs some placement love later..
SCForgeMainFrame.SpellInfoNameBox = CreateFrame("EditBox", nil, SCForgeMainFrame, "InputBoxInstructionsTemplate")
SCForgeMainFrame.SpellInfoNameBox:SetFontObject(ChatFontNormal)
SCForgeMainFrame.SpellInfoNameBox:SetMaxBytes(60)
SCForgeMainFrame.SpellInfoNameBox.disabledColor = GRAY_FONT_COLOR
SCForgeMainFrame.SpellInfoNameBox.enabledColor = HIGHLIGHT_FONT_COLOR
SCForgeMainFrame.SpellInfoNameBox.Instructions:SetText(localization.SPELLNAME)
SCForgeMainFrame.SpellInfoNameBox.Instructions:SetTextColor(0.5,0.5,0.5)
SCForgeMainFrame.SpellInfoNameBox.Title = SCForgeMainFrame.SpellInfoNameBox:CreateFontString(nil, "OVERLAY", "GameTooltipText")
SCForgeMainFrame.SpellInfoNameBox.Title:SetText(NAME)
SCForgeMainFrame.SpellInfoNameBox.Title:SetPoint("BOTTOM", SCForgeMainFrame.SpellInfoNameBox, "TOP", 0, 0)
SCForgeMainFrame.SpellInfoNameBox:SetAutoFocus(false)
SCForgeMainFrame.SpellInfoNameBox:SetSize(100,23)
SCForgeMainFrame.SpellInfoNameBox:SetPoint("TOPLEFT", 110, -35)
SCForgeMainFrame.SpellInfoNameBox:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText(localization.SPELLNAME, nil, nil, nil, nil, true)
		GameTooltip:AddLine("The name of the spell.\rThis can be anything and is only used for identifying the spell in the Vault & Chat Links.\n\rYes, you can have two spells with the same name, but that's annoying..",1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.SpellInfoNameBox:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)

SCForgeMainFrame.SpellInfoCommandBox = CreateFrame("EditBox", nil, SCForgeMainFrame, "InputBoxInstructionsTemplate")
SCForgeMainFrame.SpellInfoCommandBox:SetFontObject(ChatFontNormal)
SCForgeMainFrame.SpellInfoCommandBox:SetMaxBytes(40)
SCForgeMainFrame.SpellInfoCommandBox.disabledColor = GRAY_FONT_COLOR
SCForgeMainFrame.SpellInfoCommandBox.enabledColor = HIGHLIGHT_FONT_COLOR
SCForgeMainFrame.SpellInfoCommandBox.Instructions:SetText(localization.SPELLCOMM)
SCForgeMainFrame.SpellInfoCommandBox.Instructions:SetTextColor(0.5,0.5,0.5)
SCForgeMainFrame.SpellInfoCommandBox.Title = SCForgeMainFrame.SpellInfoCommandBox:CreateFontString(nil, "OVERLAY", "GameTooltipText")
SCForgeMainFrame.SpellInfoCommandBox.Title:SetText(COMMAND)
SCForgeMainFrame.SpellInfoCommandBox.Title:SetPoint("BOTTOM", SCForgeMainFrame.SpellInfoCommandBox, "TOP", 0, 0)
SCForgeMainFrame.SpellInfoCommandBox:SetAutoFocus(false)
SCForgeMainFrame.SpellInfoCommandBox:SetSize(SCForgeMainFrame:GetWidth()/8,23)
SCForgeMainFrame.SpellInfoCommandBox:SetPoint("TOP", 0, -35)
SCForgeMainFrame.SpellInfoCommandBox:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText(localization.SPELLCOMM, nil, nil, nil, nil, true)
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
SCForgeMainFrame.SpellInfoNameBox:SetPoint("RIGHT", SCForgeMainFrame.SpellInfoCommandBox, "LEFT", -10, 0)

SCForgeMainFrame.SpellInfoDescBox = CreateFrame("EditBox", nil, SCForgeMainFrame, "InputBoxInstructionsTemplate")
SCForgeMainFrame.SpellInfoDescBox:SetFontObject(ChatFontNormal)
SCForgeMainFrame.SpellInfoDescBox:SetMaxBytes(100)
SCForgeMainFrame.SpellInfoDescBox.disabledColor = GRAY_FONT_COLOR
SCForgeMainFrame.SpellInfoDescBox.enabledColor = HIGHLIGHT_FONT_COLOR
SCForgeMainFrame.SpellInfoDescBox.Instructions:SetText("Description")
SCForgeMainFrame.SpellInfoDescBox.Instructions:SetTextColor(0.5,0.5,0.5)
SCForgeMainFrame.SpellInfoDescBox.Title = SCForgeMainFrame.SpellInfoDescBox:CreateFontString(nil, "OVERLAY", "GameTooltipText")
SCForgeMainFrame.SpellInfoDescBox.Title:SetText("Description")
SCForgeMainFrame.SpellInfoDescBox.Title:SetPoint("BOTTOM", SCForgeMainFrame.SpellInfoDescBox, "TOP", 0, 0)
SCForgeMainFrame.SpellInfoDescBox:SetAutoFocus(false)
SCForgeMainFrame.SpellInfoDescBox:SetSize(100,23)
SCForgeMainFrame.SpellInfoDescBox:SetPoint("TOPRIGHT", -20, -35)
SCForgeMainFrame.SpellInfoDescBox:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Description", nil, nil, nil, nil, true)
		GameTooltip:AddLine("A short description of the spell.",1,1,1,true)
		--GameTooltip:AddLine(" ",1,1,1,true)
		--GameTooltip:AddLine("This is purely cosmetic.",1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.SpellInfoDescBox:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)
SCForgeMainFrame.SpellInfoDescBox:SetPoint("LEFT", SCForgeMainFrame.SpellInfoCommandBox, "RIGHT", 10, 0)

-- Enable Tabing between editboxes
SCForgeMainFrame.SpellInfoNameBox.nextEditBox = SCForgeMainFrame.SpellInfoCommandBox
SCForgeMainFrame.SpellInfoCommandBox.nextEditBox = SCForgeMainFrame.SpellInfoDescBox
SCForgeMainFrame.SpellInfoDescBox.nextEditBox = SCForgeMainFrame.SpellInfoNameBox
SCForgeMainFrame.SpellInfoDescBox.previousEditBox = SCForgeMainFrame.SpellInfoCommandBox
SCForgeMainFrame.SpellInfoCommandBox.previousEditBox = SCForgeMainFrame.SpellInfoNameBox
SCForgeMainFrame.SpellInfoNameBox.previousEditBox = SCForgeMainFrame.SpellInfoDescBox

local background = SCForgeMainFrame.Inset.Bg -- re-use the stock background, save a frame texture
	background:SetTexture(addonPath.."/assets/bookbackground_full")
	background:SetVertTile(false)
	background:SetHorizTile(false)
	background:SetAllPoints()
	
--[[ -- Old Background Setup

--- The Inner Frame
local isDualBackgroundRequired = false

local randomBackgroundID = fastrandom(#frameBackgroundOptions)
if randomBackgroundID < 7 then isDualBackgroundRequired = true end

if isDualBackgroundRequired then 
	background:SetTexCoord(0.05,1,0,0.96)
	background:SetPoint("TOPLEFT", SCForgeMainFrame.Inset, "TOPLEFT", 0,0) -- 12, -66
	background:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.Inset, "BOTTOMRIGHT", -20,0)
else
	background:SetAllPoints()
end

if isDualBackgroundRequired then 
	local background2 = SCForgeMainFrame.Inset:CreateTexture(nil,"BACKGROUND")
	background2:SetTexture(frameBackgroundOptionsEdge[randomBackgroundID])
	background2:SetPoint("TOPLEFT", background, "TOPRIGHT")
	background2:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", 30, 0)
	background2:SetTexCoord(0,1,0,0.96)
end
--]]

	SCForgeMainFrame.Inset.scrollFrame = CreateFrame("ScrollFrame", nil, SCForgeMainFrame.Inset, "UIPanelScrollFrameTemplate")
	local scrollFrame = SCForgeMainFrame.Inset.scrollFrame
	scrollFrame:SetPoint("TOPLEFT", 0, -35)
	scrollFrame:SetPoint("BOTTOMRIGHT", -24, 0)

	SCForgeMainFrame.Inset.scrollFrame.scrollChild = CreateFrame("Frame")
	local scrollChild = SCForgeMainFrame.Inset.scrollFrame.scrollChild
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(SCForgeMainFrame.Inset:GetWidth()-18)
	scrollChild:SetHeight(1) 
	
	scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, 18)
	scrollFrame.ScrollBar.scrollStep = rowHeight

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
	SCForgeMainFrame.SpellInfoCommandBox:SetSize(SCForgeMainFrame:GetWidth()/6,23)
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
SCForgeMainFrame.ExecuteSpellButton:SetText(ACTION_SPELL_CAST_SUCCESS:gsub("^%l", string.upper))
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
			--dprint(false, dump(actionData))
			table.insert(actionsToCommit, actionData)
		end
	end
	executeSpell(actionsToCommit)
end)
SCForgeMainFrame.ExecuteSpellButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Cast the above Actions.", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Useful to test your spell before saving.",1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.ExecuteSpellButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)
if tonumber(C_Epsilon.GetPhaseId()) == 169 and GetRealZoneText() == "Dranosh Valley" then 
	if C_Epsilon.IsOfficer() then return; end
	SCForgeMainFrame.ExecuteSpellButton:Disable()
else
	SCForgeMainFrame.ExecuteSpellButton:Enable()
end

local function loadSpell(spellToLoad)
	--dprint("Loading spell.. "..spellToLoad.commID)
	
	SCForgeMainFrame.SpellInfoCommandBox:SetText(spellToLoad.commID)
	SCForgeMainFrame.SpellInfoNameBox:SetText(spellToLoad.fullName)
	if spellToLoad.description then SCForgeMainFrame.SpellInfoDescBox:SetText(spellToLoad.description) end
	
	local spellActions = spellToLoad.actions
	numberOfActionsToLoad = #spellActions
	
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
	
	if SpellCreatorMasterTable.Options["loadChronologically"] then
		table.sort(spellActions, function (k1, k2) return k1.delay < k2.delay end)
	end
	
	-- Loop thru actions & set their data
	local rowNum, actionData
	for rowNum, actionData in ipairs(spellActions) do
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

local phaseVaultKeys
local SCForge_PhaseVaultSpells = {}

local function deleteSpellConf(spellKey, where)
	local dialog = StaticPopup_Show("SCFORGE_CONFIRM_DELETE", savedSpellFromVault[spellKey].fullName, savedSpellFromVault[spellKey].commID)
	if dialog then dialog.data = spellKey; dialog.data2 = where end
end

local function getSpellForgePhaseVault(callback)
	SCForge_PhaseVaultSpells = {} -- reset the table
	dprint("Phase Spell Vault Loading...")
	
	local function noSpellsToLoad()
		dprint("Phase Has No Spells to load.");
		phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" ); 
		SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("Vault is Empty");
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Enable();
		isSavingOrLoadingPhaseAddonData = false;
	end
	
	
	--if isSavingOrLoadingPhaseAddonData then eprint("Arcaum is already loading or saving a spell. To avoid data corruption, you can't do that right now. Try again shortly."); return; end
	local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")
	isSavingOrLoadingPhaseAddonData = true
	
	phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
	phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
		if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
			phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" )
			
			if (#text < 1 or text == "") then noSpellsToLoad(); return; end
			phaseVaultKeys = serialDecompressForAddonMsg(text)
			if #phaseVaultKeys < 1 then noSpellsToLoad(); return; end
			--dprint("Phase spell keys: "..dump(phaseVaultKeys))
			local phaseVaultLoadingCount = 0
			
			local messageTicketQueue = {}
			for k,v in ipairs(phaseVaultKeys) do
				local phaseVaultLoadingExpected = k
				dprint("Trying to load spell from phase: "..v)
				messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_S_"..v)
				messageTicketQueue[messageTicketID] = true -- add it to a fake queue table so we can watch for multiple prefixes...
				
				phaseAddonDataListener2:RegisterEvent("CHAT_MSG_ADDON")
				phaseAddonDataListener2:SetScript("OnEvent", function (self, event, prefix, text, channel, sender, ...)
					if event == "CHAT_MSG_ADDON" and messageTicketQueue[prefix] and text then
						messageTicketQueue[prefix] = nil -- remove it from the queue.. We'll reset the table next time anyways but whatever.
						phaseVaultLoadingCount = phaseVaultLoadingCount+1
						interAction = serialDecompressForAddonMsg(text)
						dprint("Spell found & adding to Phase Vault Table: "..interAction.commID)
						tinsert(SCForge_PhaseVaultSpells, interAction)
						if phaseVaultLoadingCount == phaseVaultLoadingExpected then
							callback(true);
							phaseAddonDataListener2:UnregisterEvent("CHAT_MSG_ADDON")
							isSavingOrLoadingPhaseAddonData = false
						end
					end
				end)
			end
		end
	end)
end

local function sendPhaseVaultIOLock(toggle)
	local phaseID = C_Epsilon.GetPhaseId()
	if toggle == true then
		AceComm:SendCommMessage(addonMsgPrefix.."_PLOCK", phaseID, "CHANNEL", tostring(scforge_ChannelID))
		dprint("Sending Lock Phase Vault IO Message for phase "..phaseID)
	elseif toggle == false then
		AceComm:SendCommMessage(addonMsgPrefix.."_PUNLOCK", phaseID, "CHANNEL", tostring(scforge_ChannelID))
		dprint("Sending Unlock Phase Vault IO Message for phase "..phaseID)
	end
end

local function deleteSpellFromPhaseVault(commID, callback)
	-- get the phase spell keys, remove the one we want to delete, then re-save it, and then over-ride the PhaseAddonData for it's key with nothing..
	
	if isSavingOrLoadingPhaseAddonData then eprint("Arcaum is already loading or saving a spell. To avoid data corruption, you can't do that right now. Try again in a moment."); return; end
	
	isSavingOrLoadingPhaseAddonData = true
	sendPhaseVaultIOLock(true)
	local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")

	phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
	
	phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
		if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
			phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" )
			phaseVaultKeys = serialDecompressForAddonMsg(text)
			table.remove(phaseVaultKeys, commID)
			phaseVaultKeys = serialCompressForAddonMsg(phaseVaultKeys)
			
			C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", phaseVaultKeys)
			local realCommID = savedSpellFromVault[commID].commID
			dprint("Removing PhaseAddonData for SCFORGE_S_"..realCommID)
			C_Epsilon.SetPhaseAddonData("SCFORGE_S_"..realCommID, "")
			
			isSavingOrLoadingPhaseAddonData = false
			sendPhaseVaultIOLock(false)
			if callback then callback(); end
		end
	end)
end

local function saveSpellToPhaseVault(commID)
	if not commID then
		eprint("Invalid CommID.")
		return;
	else 
		phaseSpellKey = commID
	end
	if isSavingOrLoadingPhaseAddonData then eprint("Arcaum is already loading or saving a spell. To avoid data corruption, you can't do that right now. Try again in a moment."); return; end
	if C_Epsilon.IsMember() or C_Epsilon.IsOfficer() or C_Epsilon.IsOwner() then
		dprint("Trying to save spell to phase vault.")

		local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")
		isSavingOrLoadingPhaseAddonData = true
		sendPhaseVaultIOLock(true)
		phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
		phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
			if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
				phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" );
				
				--print(text)
				if (text ~= "" and #text > 0) then phaseVaultKeys = serialDecompressForAddonMsg(text) else phaseVaultKeys = {} end

				dprint("Phase spell keys: "..dump(phaseVaultKeys))
				
				for k,v in ipairs(phaseVaultKeys) do
					if v == phaseSpellKey then
						-- phase already has this ID saved.. Handle over-write... ( see saveSpell() to steal the code if we want to change it later.. )
						eprint("Phase already has a spell saved by Command '"..phaseSpellKey.."'. You must delete it first before you can save a new one with that code.")
						isSavingOrLoadingPhaseAddonData = false
						sendPhaseVaultIOLock(false)
						return;
					end
				end
				
				-- Passed checking for duplicates. NOW we can save it.
				local str = serialCompressForAddonMsg(SpellCreatorSavedSpells[commID])
				
				local key = "SCFORGE_S_"..phaseSpellKey
				C_Epsilon.SetPhaseAddonData(key, str)
				
				tinsert(phaseVaultKeys, phaseSpellKey)
				phaseVaultKeys = serialCompressForAddonMsg(phaseVaultKeys)
				C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", phaseVaultKeys)
				
				cprint("Spell '"..phaseSpellKey.."' saved to the Phase Vault.")
				isSavingOrLoadingPhaseAddonData = false
				sendPhaseVaultIOLock(false)
			end
		end)
	else
		eprint("You must be a member, officer, or owner in order to save spells to the phase.")
	end

end

local selectedVaultRow
local function setSelectedVaultRow(rowID)
	if rowID then
		selectedVaultRow = rowID
		if C_Epsilon.IsOfficer() then
			SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Enable()
		else
			SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Disable()
		end
	else
		selectedVaultRow = nil
		SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Disable()
	end
end

local spellLoadRows = {}
local function clearSpellLoadRadios(self)
	if not self:GetChecked() then return; end
	for i = 1, #spellLoadRows do
		local button = spellLoadRows[i]
		if button ~= self and button:GetChecked() then
			button:SetChecked(false)
		end
	end
end

local loadRowHeight = 45
local loadRowSpacing = 5
local function updateSpellLoadRows(fromPhaseDataLoaded)
	spellLoadRows = SCForgeMainFrame.LoadSpellFrame.Rows
	for i = 1, #spellLoadRows do
		spellLoadRows[i]:Hide()
		spellLoadRows[i]:SetChecked(false)
	end
	setSelectedVaultRow(nil)
	savedSpellFromVault = {}
	local currentVault
	local currentVaultTab = PanelTemplates_GetSelectedTab(SCForgeMainFrame.LoadSpellFrame)
	
	if currentVaultTab == 1 then
		--personal vault is shown
		currentVault = "PERSONAL"
		savedSpellFromVault = SpellCreatorSavedSpells
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Hide()
		SCForgeMainFrame.LoadSpellFrame.TitleBgColor:SetColorTexture(0.30,0.10,0.40,0.5)
		SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Show()
		SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Disable()
		if next(savedSpellFromVault) == nil then
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("Vault is Empty")
		else
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("")
		end
	elseif currentVaultTab == 2 then
		--phase vault is shown
		currentVault = "PHASE"
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Show()
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Disable()
		SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Hide()
		SCForgeMainFrame.LoadSpellFrame.TitleBgColor:SetColorTexture(0.20,0.40,0.50,0.5)
		if fromPhaseDataLoaded then 
			-- called from getSpellForgePhaseVault() - that means our saved spell from Vault is ready
			savedSpellFromVault = SCForge_PhaseVaultSpells
			dprint("Phase Spell Vault Loaded.")
			SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Enable()
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("")
		else
			getSpellForgePhaseVault(updateSpellLoadRows)
			SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Disable()
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("Loading...")
		end
	end
	
	local spellLoadFrame = SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.scrollChild
	local rowNum = 0
	local columnWidth = spellLoadFrame:GetWidth()
		
	for k,v in orderedPairs(savedSpellFromVault) do
	-- this will get an alphabetically sorted list of all spells, and their data. k = the key (commID), v = the spell's data table
		rowNum = rowNum+1
		
		if spellLoadRows[rowNum] then
			spellLoadRows[rowNum]:Show()
			dprint(false,"SCForge Load Row "..rowNum.." Already existed - showing & setting it")
			
		else
			dprint(false,"SCForge Load Row "..rowNum.." Didn't exist - making it!")
			spellLoadRows[rowNum] = CreateFrame("CheckButton", "scForgeLoadRow"..rowNum, spellLoadFrame)

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
						
			-- A nice lil background to make them easier to tell apart			
			spellLoadRows[rowNum].Background = spellLoadRows[rowNum]:CreateTexture(nil,"BACKGROUND")
			spellLoadRows[rowNum].Background:SetPoint("TOPLEFT",-3,0)
			spellLoadRows[rowNum].Background:SetPoint("BOTTOMRIGHT",0,0)
			spellLoadRows[rowNum].Background:SetTexture(load_row_background)
			spellLoadRows[rowNum].Background:SetTexCoord(0.0625,1-0.066,0.125,1-0.15)
			
			spellLoadRows[rowNum]:SetCheckedTexture("Interface\\AddOns\\SpellCreator\\assets\\l_row_selected")
			spellLoadRows[rowNum].CheckedTexture = spellLoadRows[rowNum]:GetCheckedTexture()
			spellLoadRows[rowNum].CheckedTexture:SetAllPoints(spellLoadRows[rowNum].Background)
			spellLoadRows[rowNum].CheckedTexture:SetTexCoord(0.0625,1-0.066,0.125,1-0.15)
			spellLoadRows[rowNum].CheckedTexture:SetAlpha(0.75)
			--spellLoadRows[rowNum].CheckedTexture:SetPoint("RIGHT", spellLoadRows[rowNum].Background, "RIGHT", 5, 0)
			
			-- Original Atlas based texture with vertex shading for a unique look. Actually looked pretty good imo.
			--spellLoadRows[rowNum].Background:SetAtlas("TalkingHeads-Neutral-TextBackground")
			--spellLoadRows[rowNum].Background:SetVertexColor(0.75,0.70,0.8) -- Let T color it naturally :)
			--spellLoadRows[rowNum].Background:SetVertexColor(0.73,0.63,0.8)
			
			--[[ -- Disabled, not needed on the new load row backgrounds
			spellLoadRows[rowNum].spellNameBackground = spellLoadRows[rowNum]:CreateTexture(nil, "BACKGROUND")
			spellLoadRows[rowNum].spellNameBackground:SetPoint("TOPLEFT", spellLoadRows[rowNum].Background, "TOPLEFT", 5, -2)
			spellLoadRows[rowNum].spellNameBackground:SetPoint("BOTTOMRIGHT", spellLoadRows[rowNum].Background, "BOTTOM", 10, 2) -- default position - move it later with the actual name font string.

			spellLoadRows[rowNum].spellNameBackground:SetColorTexture(1,1,1,0.25)
			spellLoadRows[rowNum].spellNameBackground:SetGradient("HORIZONTAL", 0.5,0.5,0.5,1,1,1)
			spellLoadRows[rowNum].spellNameBackground:SetBlendMode("MOD")
			--]]

			
			-- Make the Spell Name Text
			spellLoadRows[rowNum].spellName = spellLoadRows[rowNum]:CreateFontString(nil,"OVERLAY", "GameFontNormalMed2")
			spellLoadRows[rowNum].spellName:SetWidth(columnWidth*2/3)
			spellLoadRows[rowNum].spellName:SetJustifyH("LEFT")
			spellLoadRows[rowNum].spellName:SetPoint("LEFT", 10, 0)
			spellLoadRows[rowNum].spellName:SetText(v.fullName) -- initial text, reset later when it needs updated
			spellLoadRows[rowNum].spellName:SetShadowColor(0, 0, 0)
			spellLoadRows[rowNum].spellName:SetMaxLines(3) -- hardlimit to 3 lines, but soft limit to 2 later.
--			spellLoadRows[rowNum].spellNameBackground:SetPoint("RIGHT", spellLoadRows[rowNum].spellName, "RIGHT", 0, 0) -- move the right edge of the gradient to the right edge of the name

			-- Make the delete saved spell button
			spellLoadRows[rowNum].deleteButton = CreateFrame("BUTTON", nil, spellLoadRows[rowNum])
			local button = spellLoadRows[rowNum].deleteButton
			button.commID = k
			button:SetPoint("RIGHT", 0, 0)
			button:SetSize(24,24)
			--button:SetText("x")
			
			button:SetNormalTexture(addonPath.."/assets/icon-x")
			button:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

			button.DisabledTex = button:CreateTexture(nil, "ARTWORK")
			button.DisabledTex:SetAllPoints(true)
			button.DisabledTex:SetTexture(addonPath.."/assets/icon-x")
			SetDesaturation(button.DisabledTex, true)
			button.DisabledTex:SetVertexColor(.6,.6,.6)
			button:SetDisabledTexture(button.DisabledTex)

			button.PushedTex = button:CreateTexture(nil, "ARTWORK")
			button.PushedTex:SetAllPoints(true)
			button.PushedTex:SetTexture(addonPath.."/assets/icon-x")
			button.PushedTex:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
			button.PushedTex:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
			button.PushedTex:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
			button.PushedTex:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
			button:SetPushedTexture(button.PushedTex)
			
			button:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				self.Timer = C_Timer.NewTimer(0.7,function()
					GameTooltip:SetText("Delete '"..savedSpellFromVault[self.commID].commID.."'", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
			end)
			button:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
			end)
			

			-- Make the load button
			spellLoadRows[rowNum].loadButton = CreateFrame("BUTTON", nil, spellLoadRows[rowNum])
			local button = spellLoadRows[rowNum].loadButton
			button.commID = k
			button:SetPoint("RIGHT", spellLoadRows[rowNum].deleteButton, "LEFT", 0, 0)
			button:SetSize(24,24)
			--button:SetText(EDIT)
			
			button:SetNormalTexture(addonPath.."/assets/icon-edit")
			button:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

			button.DisabledTex = button:CreateTexture(nil, "ARTWORK")
			button.DisabledTex:SetAllPoints(true)
			button.DisabledTex:SetTexture(addonPath.."/assets/icon-edit")
			SetDesaturation(button.DisabledTex, true)
			button.DisabledTex:SetVertexColor(.6,.6,.6)
			button:SetDisabledTexture(button.DisabledTex)

			button.PushedTex = button:CreateTexture(nil, "ARTWORK")
			button.PushedTex:SetAllPoints(true)
			button.PushedTex:SetTexture(addonPath.."/assets/icon-edit")
			button.PushedTex:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
			button.PushedTex:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
			button.PushedTex:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
			button.PushedTex:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
			button:SetPushedTexture(button.PushedTex)
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetScript("OnClick", function(self, button)
				if button == "RightButton" then
					table.sort(savedSpellFromVault[self.commID].actions, function (k1, k2) return k1.delay < k2.delay end)
				end
				loadSpell(savedSpellFromVault[self.commID])
				if vaultStyle ~= 2 then SCForgeMainFrame.LoadSpellFrame:Hide(); end
			end)
			button:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				self.Timer = C_Timer.NewTimer(0.7,function()
					GameTooltip:SetText("Load ArcSpell '"..savedSpellFromVault[self.commID].commID.."' into the forge, where you can edit it.", nil, nil, nil, nil, true)
					GameTooltip:AddLine("Right-click to load the ArcSpell & re-sort it's actions into chronological order by delay.", 1,1,1,1)
					GameTooltip:Show()
				end)
			end)
			button:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
			end)
			
			
			--[[
			-- Transfer to Phase Button
			spellLoadRows[rowNum].saveToPhaseButton = CreateFrame("BUTTON", nil, spellLoadRows[rowNum], "UIPanelButtonTemplate")
			local button = spellLoadRows[rowNum].saveToPhaseButton
			button.commID = k
			button:SetPoint("RIGHT", spellLoadRows[rowNum].loadButton, "LEFT", 0, 0)
			button:SetSize(24,24)
			--button:SetText("P")
			button.icon = button:CreateTexture(nil, "ARTWORK")
			button.icon:SetTexture(addonPath.."/assets/icon-transfer")
			--button.icon:SetTexCoord(0,1,1,0)
			button.icon:SetAllPoints()
			button:Hide()
			button:SetScript("OnClick", function(self)
				saveSpellToPhaseVault(self.commID)
			end)
			button:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				self.Timer = C_Timer.NewTimer(0.7,function()
					GameTooltip:SetText("Transfer '"..self.commID.."' into the Phase Vault, where anyone in the phase can save a copy to their personal vault.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
			end)
			button:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
			end)
			--]]
		end
		
		-- Set the buttons stuff
		do
			-- make sure to set the data, otherwise it will still use old data if new spells have been saved since last.
			spellLoadRows[rowNum].spellName:SetText(v.fullName)
			spellLoadRows[rowNum].loadButton.commID = k
			spellLoadRows[rowNum].deleteButton.commID = k
			spellLoadRows[rowNum].commID = k -- used in new Transfer to Phase Button
			spellLoadRows[rowNum].rowID = rowNum
			
			spellLoadRows[rowNum].deleteButton:SetScript("OnClick", function(self)
				deleteSpellConf(self.commID, currentVault)
			end)
			
			-- NEED TO UPDATE THE ROWS IF WE ARE IN PHASE VAULT
			if currentVault == "PERSONAL" then
				--spellLoadRows[rowNum].loadButton:SetText(EDIT)
				--spellLoadRows[rowNum].saveToPhaseButton.commID = k
				--spellLoadRows[rowNum].Background:SetVertexColor(0.75,0.70,0.8)
				--spellLoadRows[rowNum].Background:SetTexCoord(0,1,0,1)
				spellLoadRows[rowNum].deleteButton:Show()
				
				--[[	-- Replaced with the <-> Phase Vault button
				if C_Epsilon.IsMember() or C_Epsilon.IsOfficer() or C_Epsilon.IsOwner() then
					spellLoadRows[rowNum].saveToPhaseButton:Show()
				else
					spellLoadRows[rowNum].saveToPhaseButton:Hide()
				end
				--]]
				
			elseif currentVault == "PHASE" then
				--spellLoadRows[rowNum].loadButton:SetText("Load")
				--spellLoadRows[rowNum].saveToPhaseButton:Hide()
				--spellLoadRows[rowNum].Background:SetVertexColor(0.73,0.63,0.8)
				--spellLoadRows[rowNum].Background:SetTexCoord(0,1,0,1)
				
				if C_Epsilon.IsMember() or C_Epsilon.IsOfficer() or C_Epsilon.IsOwner() then
					spellLoadRows[rowNum].deleteButton:Show()
				else
					spellLoadRows[rowNum].deleteButton:Hide()
				end
			end		
			
			-- Update the main row frame for mouse over - this allows us to hover & shift-click for links
			spellLoadRows[rowNum]:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				self.Timer = C_Timer.NewTimer(0.7,function()
					GameTooltip:SetText(v.fullName, nil, nil, nil, nil, true)
					if v.description then
						GameTooltip:AddLine(v.description, 1, 1, 1, 1)
					end
					GameTooltip:AddLine(" ", 1, 1, 1, 1)
					GameTooltip:AddLine("Command: '/sf "..v.commID.."'", 1, 1, 1, 1)
					GameTooltip:AddLine("Actions: "..#v.actions, 1, 1, 1, 1)
					GameTooltip:AddLine(" ", 1, 1, 1, 1)
					GameTooltip:AddLine("Shift-Click to link in chat & share with other players.", 1, 1, 1, 1)
					GameTooltip:Show()
				end)
			end)
			spellLoadRows[rowNum]:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
			end)
			spellLoadRows[rowNum]:SetScript("OnClick", function(self)
				if IsModifiedClick("CHATLINK") then
					ChatEdit_InsertLink(generateSpellChatLink(k, currentVault));
					self:SetChecked(not self:GetChecked());
					return;
				end
				clearSpellLoadRadios(self)
				if self:GetChecked() then
					setSelectedVaultRow(self.rowID)
				else
					setSelectedVaultRow(nil)
				end
			end)
			--[[
			spellLoadRows[rowNum]:SetScript("OnMouseDown", function(self)
				if IsModifiedClick("CHATLINK") then
					ChatEdit_InsertLink(generateSpellChatLink(k, currentVault))
				end
			end)
			--]]
		end
		
		-- Limit our Spell Name to 2 lines - but by downsizing the text instead of truncating..
		do
			local fontName,fontHeight,fontFlags = spellLoadRows[rowNum].spellName:GetFont()
			spellLoadRows[rowNum].spellName:SetFont(fontName, 14, fontFlags) -- reset the font to default first, then test if we need to scale it down.
			while spellLoadRows[rowNum].spellName:GetNumLines() > 2 do
				fontName,fontHeight,fontFlags = spellLoadRows[rowNum].spellName:GetFont()
				spellLoadRows[rowNum].spellName:SetFont(fontName, fontHeight-1, fontFlags)
				if fontHeight-1 <= 8 then break; end
			end
		end

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
	OnAccept = function(self, data, data2)
		if data2 == "PERSONAL" then
			deleteSpell(data)
		elseif data2 == "PHASE" then
			dprint("Deleting '"..data.."' from Phase Vault.")
			deleteSpellFromPhaseVault(data, updateSpellLoadRows)
		end
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
	newSpellData.description = SCForgeMainFrame.SpellInfoDescBox:GetText()
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
SCForgeMainFrame.SaveSpellButton:SetText(BATTLETAG_CREATE)
SCForgeMainFrame.SaveSpellButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
SCForgeMainFrame.SaveSpellButton:SetScript("OnClick", function(self, button)
	saveSpell(button)
end)
SCForgeMainFrame.SaveSpellButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Create your ArcSpell!", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Finish your spell & save to your Personal Vault.\nIt can then be casted using '/sf commandID' for quick use!\n\r",1,1,1,true)
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
		GameTooltip:SetText("Access your Vaults", nil, nil, nil, nil, true)
		GameTooltip:AddLine("You can load, edit, and manage all of your created/saved ArcSpells from the Personal Vault.\n\rThe Phase Vault can also be accessed here for any ArcSpells saved to the phase.",1,1,1,true)
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
SCForgeMainFrame.LoadSpellFrame:SetIgnoreParentScale()

local newNineSliceOverride = {
    TopLeftCorner = { tex = myNineSliceFile_corners, txl = 0.525391, txr = 0.783203, txt = 0.00195312, txb = 0.259766, }, --0.525391, 0.783203, 0.00195312, 0.259766
    TopRightCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.263672, txb = 0.521484, }, -- 0.00195312, 0.259766, 0.263672, 0.521484
	--TopRightCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.525391, txb = 0.783203, }, -- 0.00195312, 0.259766, 0.525391, 0.783203 -- this is the double one
    BottomLeftCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.00195312, txb = 0.259766, }, -- 0.00195312, 0.259766, 0.00195312, 0.259766
    BottomRightCorner = { tex = myNineSliceFile_corners, txl = 0.263672, txr = 0.521484, txt = 0.00195312, txb = 0.259766, }, -- 0.263672, 0.521484, 0.00195312, 0.259766
    TopEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.263672, txb = 0.521484, }, -- 0, 1, 0.263672, 0.521484
    BottomEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.00195312, txb = 0.259766, }, -- 0, 1, 0.00195312, 0.259766
    LeftEdge = { tex = myNineSliceFile_vert, txl = 0.00195312, txr = 0.259766, txt = 0, txb = 1, }, -- 0.00195312, 0.259766, 0, 1
    RightEdge = { tex = myNineSliceFile_vert, txl = 0.263672, txr = 0.521484, txt = 0, txb = 1, }, -- 0.263672, 0.521484, 0, 1
}

for k,v in pairs(newNineSliceOverride) do
	SCForgeMainFrame.LoadSpellFrame.NineSlice[k]:SetTexture(v.tex)
	SCForgeMainFrame.LoadSpellFrame.NineSlice[k]:SetTexCoord(v.txl, v.txr, v.txt, v.txb)
end

if vaultStyle == 2 then 
	SCForgeMainFrame.LoadSpellFrame:SetPoint("TOPLEFT", SCForgeMainFrame, "TOPRIGHT", 0, 0)
	SCForgeMainFrame.LoadSpellFrame:SetSize(280,SCForgeMainFrame:GetHeight())
	SCForgeMainFrame.LoadSpellFrame:SetFrameStrata("MEDIUM")
	--setResizeWithMainFrame(SCForgeMainFrame.LoadSpellFrame.Inset)
else
	SCForgeMainFrame.LoadSpellFrame:SetPoint("CENTER", UIParent, 0, 100)
	SCForgeMainFrame.LoadSpellFrame:SetSize(500,250)
	SCForgeMainFrame.LoadSpellFrame:SetFrameStrata("DIALOG")
end
do
	SCForgeMainFrame.LoadSpellFrame.Inset.Bg2 = SCForgeMainFrame.LoadSpellFrame.Inset:CreateTexture(nil, "BACKGROUND")
	local background = SCForgeMainFrame.LoadSpellFrame.Inset.Bg2
	background:SetTexture(addonPath.."/assets/SpellForgeVaultBG")
	background:SetVertTile(false)
	background:SetHorizTile(false)
	background:SetTexCoord(0.0546875,1-0.0546875,0.228515625,1-0.228515625)
	background:SetPoint("TOPLEFT")
	background:SetPoint("BOTTOMRIGHT",-19,0)
end

SCForgeMainFrame.LoadSpellFrame:SetTitle("Spell Vault")
SCForgeMainFrame.LoadSpellFrame.TitleBgColor = SCForgeMainFrame.LoadSpellFrame:CreateTexture(nil, "BACKGROUND")
SCForgeMainFrame.LoadSpellFrame.TitleBgColor:SetPoint("TOPLEFT", SCForgeMainFrame.LoadSpellFrame.TitleBg)
SCForgeMainFrame.LoadSpellFrame.TitleBgColor:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.LoadSpellFrame.TitleBg)
SCForgeMainFrame.LoadSpellFrame.TitleBgColor:SetColorTexture(0.40,0.10,0.50,0.5)

SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton = CreateFrame("BUTTON", nil, SCForgeMainFrame.LoadSpellFrame, "UIPanelButtonNoTooltipTemplate")
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetPoint("BOTTOM", 0, 3)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetSize(24*5,24)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetText("   Phase Vault")

SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton.icon = SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:CreateTexture(nil, "ARTWORK")
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton.icon:SetTexture(addonPath.."/assets/icon-transfer")
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton.icon:SetTexCoord(0,1,1,0)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton.icon:SetPoint("TOPLEFT", 5, 0)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton.icon:SetSize(24,24)


SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnClick", function(self)
	if selectedVaultRow then
		--print(selectedVaultRow)
		commID = spellLoadRows[selectedVaultRow].commID
		--print(commID)
		saveSpellToPhaseVault(commID)
	end
end)

SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnDisable", function(self)
	self.icon:SetDesaturated(true)
end)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnEnable", function(self)
	self.icon:SetDesaturated(false)
end)

SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetMotionScriptsWhileDisabled(true)

SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Transfer to Phase Vault.", nil, nil, nil, nil, true)
		if self:IsEnabled() then
			GameTooltip:AddLine("Transfer the spell to the Phase Vault.",1,1,1,true)
		else
			GameTooltip:AddLine("You do not currently have permissions to upload to this phase's vault.\n\rIf you were just given officer, rejoin the phase.",1,1,1,true)
		end
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnShow", function(self)
	if not selectedVaultRow then self:Disable(); end
end)


SCForgeMainFrame.LoadSpellFrame:Hide()
SCForgeMainFrame.LoadSpellFrame.Rows = {}
SCForgeMainFrame.LoadSpellFrame:HookScript("OnShow", function()
	dprint("Updating Spell Load Rows")
	updateSpellLoadRows()
end)

-- Spell Vault Scroll Frame
	SCForgeMainFrame.LoadSpellFrame.spellVaultFrame = CreateFrame("ScrollFrame", nil, SCForgeMainFrame.LoadSpellFrame.Inset, "UIPanelScrollFrameTemplate")
	local scrollFrame = SCForgeMainFrame.LoadSpellFrame.spellVaultFrame
	setResizeWithMainFrame(SCForgeMainFrame.LoadSpellFrame.spellVaultFrame)
	scrollFrame:SetPoint("TOPLEFT", 0, -3)
	scrollFrame:SetPoint("BOTTOMRIGHT", -24, 0)
	scrollFrame.ScrollBar.scrollStep = loadRowHeight+5
	
	SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText = SCForgeMainFrame.LoadSpellFrame.spellVaultFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetPoint("TOP", 0, -100)
	SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("Loading...")

	SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.scrollChild = CreateFrame("Frame")
	local scrollChild = SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.scrollChild
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(SCForgeMainFrame.LoadSpellFrame.Inset:GetWidth()-12)
	scrollChild:SetHeight(1) 
	
local function SpellForgeLoadFrame_Update()
	local selectedTab = PanelTemplates_GetSelectedTab(SCForgeMainFrame.LoadSpellFrame)
	if (selectedTab == 1) then
		updateSpellLoadRows()
	elseif (selectedTab == 2) then
		updateSpellLoadRows()
	end	
end

SCForgeMainFrame.LoadSpellFrame.TabButton1 = CreateFrame("BUTTON", "$parentTab1", SCForgeMainFrame.LoadSpellFrame, "TabButtonTemplate")
local button = SCForgeMainFrame.LoadSpellFrame.TabButton1
button.text = "Personal"
button.id = 1
button:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.LoadSpellFrame.Inset, "TOP", 0, 0)
--PanelTemplates_TabResize(button, 0)
button.HighlightTexture:SetWidth(button:GetTextWidth()+31)
button:SetScript("OnClick", function(self)
	PanelTemplates_SetTab(SCForgeMainFrame.LoadSpellFrame, 1)
	updateSpellLoadRows()
end)
button:SetScript("OnShow", function(self)
	self.Text:SetText(self.text)
	self.HighlightTexture:SetWidth(self:GetTextWidth()+31)
	PanelTemplates_TabResize(self, 0)
end)

SCForgeMainFrame.LoadSpellFrame.TabButton2 = CreateFrame("BUTTON", "$parentTab2", SCForgeMainFrame.LoadSpellFrame, "TabButtonTemplate")
local button = SCForgeMainFrame.LoadSpellFrame.TabButton2
button.text = "Phase"
button.id = 2
button:SetPoint("LEFT", SCForgeMainFrame.LoadSpellFrame.TabButton1, "RIGHT", 0, 0)
--PanelTemplates_TabResize(button, 0)
button.HighlightTexture:SetWidth(button:GetTextWidth()+31)
button:SetScript("OnClick", function(self)
	PanelTemplates_SetTab(SCForgeMainFrame.LoadSpellFrame, 2)
	updateSpellLoadRows()
end)
button:SetScript("OnShow", function(self)
	self.Text:SetText(self.text)
	self.HighlightTexture:SetWidth(self:GetTextWidth()+31)
	PanelTemplates_TabResize(self, 0)
end)

PanelTemplates_SetNumTabs(SCForgeMainFrame.LoadSpellFrame, 2)
PanelTemplates_SetTab(SCForgeMainFrame.LoadSpellFrame, 1)

-- Disabled button - Replacing with Tabbed Vault Experience
SCForgeMainFrame.LoadSpellFrame.refreshVaultButton = CreateFrame("BUTTON", nil, SCForgeMainFrame.LoadSpellFrame)
SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.LoadSpellFrame.Inset,"TOPRIGHT", -5, 2)
SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetSize(24,24)

SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetNormalAtlas("UI-RefreshButton")
SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetPushedAtlas("UI-RefreshButton")
SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetDisabledAtlas("UI-RefreshButton")
SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")


SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetScript("OnClick", function(self, button)
	updateSpellLoadRows();
end)

SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Refresh Phase Vault", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Reload the Phase Vault from the server, getting any new changes.",1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)
SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetScript("OnMouseDown", function(self)
	local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(1)
	self:SetPoint(point, relativeTo, relativePoint, xOfs+2, yOfs-2)
end)
SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetScript("OnMouseUp", function(self)
	local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(1)
	self:SetPoint(point, relativeTo, relativePoint, xOfs-2, yOfs+2)
end)
SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetScript("OnDisable", function(self)
	self:GetDisabledTexture():SetDesaturated(true)
end)
SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetScript("OnEnable", function(self)
	self:GetDisabledTexture():SetDesaturated(false)
end)


-------------------------------------------------------------------------------
-- Custom Chat Link Stuff
-------------------------------------------------------------------------------

local function requestSpellFromPlayer(playerName, commID)
	AceComm:SendCommMessage(addonMsgPrefix.."REQ", commID, "WHISPER", playerName)
	dprint("Request Spell '"..commID.."' from "..playerName)
end

local function sendSpellToPlayer(playerName, commID)
	dprint("Sending Spell '"..commID.."' to "..playerName)
	if SpellCreatorSavedSpells[commID] then
		local message = serialCompressForAddonMsg(SpellCreatorSavedSpells[commID])
		AceComm:SendCommMessage(addonMsgPrefix.."SPELL", message, "WHISPER", playerName)
	end
end

local function savedReceivedSpell(msg, charName)
	SpellCreatorSavedSpells[msg.commID] = msg
	cprint("Saved Spell from "..charName..": "..msg.commID)
	updateSpellLoadRows()
end

local function receiveSpellData(msg, charName)
	msg = serialDecompressForAddonMsg(msg)
	dprint("Received Arcanum Spell '"..msg.commID.."' from "..charName)
	if msg.commID then
		if SpellCreatorSavedSpells[msg.commID] then
			dprint("The spell already exists, prompting to confirm over-write.")
			StaticPopupDialogs["SCFORGE_CONFIRM_OVERWRITE"] = {
				text = "Spell '"..msg.commID.."' Already exists.\n\rDo you want to overwrite the spell ("..msg.fullName..")".."?",
				OnAccept = function() savedReceivedSpell(msg, charName) end,
				button1 = "Overwrite",
				button2 = "Cancel",
				hideOnEscape = true,
				whileDead = true,
			}
			StaticPopup_Show("SCFORGE_CONFIRM_OVERWRITE")
			return;
		end
		savedReceivedSpell(msg, charName)
	end
end

local _ChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow
function ChatFrame_OnHyperlinkShow(...)
	pcall(_ChatFrame_OnHyperlinkShow, ...)
	if IsModifiedClick() then return end
	local linkType, linkData, displayText = LinkUtil.ExtractLink(select(3, ...))
	if linkType == "arcSpell" then
		spellComm, charOrPhase, spellName, numActions, spellDesc = strsplit(":", linkData)
		local spellIconPath = addonPath.."/assets/BookIcon"
		local spellIconSize = 24
		local spellIconSequence = "|T"..spellIconPath..":"..spellIconSize.."|t "
		local tooltipTitle = spellIconSequence..addonColor..spellName
		--local tooltipTitle = addonColor..spellName
		GameTooltip_SetTitle(ItemRefTooltip, tooltipTitle)
		--ItemRefTooltip:AddTexture(spellIconPath, {width=spellIconSize, height=spellIconSize, anchor=ItemRefTooltip.LeftTop })
		ItemRefTooltip:AddLine(spellDesc, nil, nil, nil, true)
		ItemRefTooltip:AddLine(" ")
		ItemRefTooltip:AddDoubleLine("Command: "..spellComm, "Actions: "..numActions, 1, 1, 1, 1, 1, 1)
		ItemRefTooltip:AddDoubleLine( "Arcanum Spell", charOrPhase, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75 )
		--ItemRefTooltip:AddLine("Actions: "..numActions, 1, 1, 1, 1 )
		--ItemRefTooltip:AddLine(" ")
			CTimerAfter(0, function()
				local button
				if tonumber(charOrPhase) then -- is a phase, not a character
					if charOrPhase == "169" then
						ItemRefTooltip:AddLine(" ")
						ItemRefTooltip:AddLine("Get it from the Main Phase Vault")
					else
						ItemRefTooltip:AddLine(" ")
						ItemRefTooltip:AddLine("Get it from Phase "..charOrPhase.."'s Vault")
					end
				elseif charOrPhase == UnitName("player") then
					ItemRefTooltip:AddLine(" ")
					ItemRefTooltip:AddLine("This is your spell.")
				else
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
					button.playerName = charOrPhase
					button.commID = spellComm
				end
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
		InterfaceOptionsFrame_OpenToCategory(addonTitle);
		InterfaceOptionsFrame_OpenToCategory(addonTitle);
	else
		if not SCForgeMainFrame:IsShown() then
			SCForgeMainFrame:Show()
			if where == "enableMMIcon" and SpellCreatorMasterTable.Options["minimapIcon"] == nil then 
				SpellCreatorMasterTable.Options["minimapIcon"] = true
				UIFrameFlash(SpellCreatorMinimapButton.Flash, 1.0, 1.0, -1, false, 0, 0);
				SpellCreatorMinimapButton:SetShown(true)
				UIFrameFadeIn(SpellCreatorMinimapButton, 0.5)
			end
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

local function minimap_OnUpdate(self)
	local radian;

	local mx, my = Minimap:GetCenter();
	local px, py = GetCursorPosition();
	local scale = Minimap:GetEffectiveScale();
	px, py = px / scale, py / scale;
	radian = math.atan2(py - my, px - mx);

	MinimapButton_UpdateAngle(radian);
	SpellCreatorMasterTable.Options["mmLoc"] = radian;
	if not self.highlight.anim:IsPlaying() then self.highlight.anim:Play() end
end

minimapButton.Flash = minimapButton:CreateTexture("$parentFlash", "OVERLAY")
minimapButton.Flash:SetAtlas("Azerite-Trait-RingGlow")
minimapButton.Flash:SetAllPoints()
minimapButton.Flash:SetPoint("TOPLEFT", -4, 4)
minimapButton.Flash:SetPoint("BOTTOMRIGHT", 4, -4)
minimapButton.Flash:SetDesaturated(true)
minimapButton.Flash:SetVertexColor(1,1,0)
minimapButton.Flash:Hide()
local function rainbowVertex(frame, parentIfNeeded)
	frame.elapsed = 0
	frame.rainbowVertex = true
	scriptFrame = parentIfNeeded or frame
	scriptFrame:HookScript("OnUpdate", function(self,elapsed)
		if frame.rainbowVertex then
			elapsed = elapsed/10
			frame.elapsed = frame.elapsed + elapsed
			if frame.elapsed > 1 then frame.elapsed = 0 end
			local r,g,b = hsvToRgb(frame.elapsed, 1, 1)
			frame:SetVertexColor(r/255, g/255, b/255)
		end
	end)
end

minimapButton.bg = minimapButton:CreateTexture("$parentBg", "BACKGROUND")
minimapButton.bg:SetTexture(addonPath.."/assets/CircularBG")
minimapButton.bg:SetSize(24,24)
minimapButton.bg:SetPoint("CENTER")
minimapButton.bg.mask = minimapButton:CreateMaskTexture()
minimapButton.bg.mask:SetAllPoints(minimapButton.bg)
minimapButton.bg.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
minimapButton.bg:AddMaskTexture(minimapButton.bg.mask)

local mmIcon = arcaneGemPath.."Violet"
minimapButton.icon = minimapButton:CreateTexture("$parentIcon", "ARTWORK")
minimapButton.icon:SetTexture(mmIcon)
minimapButton.icon:SetSize(22,22)
minimapButton.icon:SetPoint("CENTER")

--[[
minimapButton.rune = minimapButton:CreateTexture(nil, "OVERLAY", nil, 7)
if runeIconOverlay.atlas then 
	minimapButton.rune:SetAtlas(runeIconOverlay.atlas)
else
	minimapButton.rune:SetTexture(runeIconOverlay.tex)
end

minimapButton.rune:SetDesaturated(true)
minimapButton.rune:SetVertexColor(1,1,1)
minimapButton.rune:SetBlendMode("ADD")
minimapButton.rune:SetPoint("CENTER")
minimapButton.rune:SetSize(12,12)
--minimapButton.rune:SetPoint("TOPLEFT", minimapButton, 8, -8)
--minimapButton.rune:SetPoint("BOTTOMRIGHT", minimapButton, -8, 8)
--]]

-- Minimap Border Ideas (Atlas):
local mmBorders = {
	{atlas = "Artifacts-PerkRing-Final", size=0.58, posx=1, posy=-1 },	-- 1 -- Thin Gold Border with gloss over the icon area like glass
	{atlas = "auctionhouse-itemicon-border-purple", size=0.62, posx=-1, posy=0, hilight="Relic-Arcane-TraitGlow", }, -- 2 -- purple ring w/ arcane highlight
	{atlas = "legionmission-portraitring-epicplus", size=0.65, posx=-1, posy=0, hilight="Relic-Arcane-TraitGlow", }, -- 2 -- thicker purple ring w/ gold edges & decor
	{tex = addonPath.."/assets/Icon_Ring_Border", size=0.62, posx=-1, posy=0, hilight="Relic-Arcane-TraitGlow", }, -- 2 -- purple ring w/ arcane highlight
}

local mmBorder = mmBorders[4]	-- put your table choice here
minimapButton.border = minimapButton:CreateTexture("$parentBorder", "BORDER")
	if mmBorder.atlas then minimapButton.border:SetAtlas(mmBorder.atlas, false) else minimapButton.border:SetTexture(mmBorder.tex) end
minimapButton.border:SetSize(56*mmBorder.size,56*mmBorder.size)
minimapButton.border:SetPoint("TOPLEFT",mmBorder.posx,mmBorder.posy)
if mmBorder.hilight then minimapButton:SetHighlightAtlas(mmBorder.hilight) else minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight") end
minimapButton.highlight = minimapButton:GetHighlightTexture()

local function setFrameFlicker(frame, iter, timeToFadeOut, timeToFadeIn, startAlpha, endAlpha, repeatnum)
	if repeatnum then
		if not frame.flickerTimer then frame.flickerTimer = {} end
		frame.flickerTimer[repeatnum] = C_Timer.NewTimer((fastrandom(10,30)/10), function()
			UIFrameFadeOut(frame,timeToFadeOut,startAlpha,endAlpha)
			frame.fadeInfo.finishedFunc = function() UIFrameFadeIn(frame,timeToFadeIn,endAlpha,startAlpha) end
			setFrameFlicker(frame, nil, timeToFadeOut, timeToFadeIn, startAlpha, endAlpha, repeatnum)
		end)
	else
		if not iter then iter = 1 end
		for i = 1,iter do
			if not frame.flickerTimer then frame.flickerTimer = {} end
			frame.flickerTimer[i] = C_Timer.NewTimer((fastrandom(10,30)/10), function()
				UIFrameFadeOut(frame,timeToFadeOut,startAlpha,endAlpha)
				frame.fadeInfo.finishedFunc = function() UIFrameFadeIn(frame,timeToFadeIn,endAlpha,startAlpha) end
				setFrameFlicker(frame, nil, timeToFadeOut, timeToFadeIn, startAlpha, endAlpha, i)
			end)
		end
	end
end
local function stopFrameFlicker(frame, endAlpha)
	for i = 1, #frame.flickerTimer do
		frame.flickerTimer[i]:Cancel()
	end
	frame:SetAlpha(endAlpha or 1)
end

minimapButton.highlight.anim = minimapButton.highlight:CreateAnimationGroup()
minimapButton.highlight.anim:SetLooping("REPEAT")
minimapButton.highlight.anim.rot = minimapButton.highlight.anim:CreateAnimation("Rotation")
minimapButton.highlight.anim.rot:SetDegrees(-360)
minimapButton.highlight.anim.rot:SetDuration(5)
minimapButton.highlight.anim:SetScript("OnPlay", function(self)
	setFrameFlicker(self:GetParent(), 2, 0.1, 0.5, 1, 0.33)
end)
minimapButton.highlight.anim:SetScript("OnPause", function(self)
	stopFrameFlicker(self:GetParent(), 1)
end)

--[[
SpellCreatorMinimapButton.border:SetSize(56*0.6,56*0.6)
SpellCreatorMinimapButton.border:SetPoint("TOPLEFT",2,-1)
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
		-- kept these here for ez copy-paste in-game lol
--]]

minimapButton:SetScript("OnDragStart", function(self)
	self:LockHighlight()
	self:SetScript("OnUpdate", minimap_OnUpdate)
end)
minimapButton:SetScript("OnDragStop", function(self)
	self:UnlockHighlight()
	self.highlight.anim:Pause()
	self:SetScript("OnUpdate", nil)
end)
minimapButton:SetScript("OnMouseUp", function(self, button)
	if button == "LeftButton" then
		scforge_showhide()
	elseif button == "RightButton" then
		scforge_showhide("options")
	end
end)

minimapButton:SetScript("OnEnter", function(self)
	self.highlight.anim:Play()
	SetCursor("Interface/CURSOR/voidstorage.blp");
	-- interface/cursor/argusteleporter.blp , interface/cursor/trainer.blp , 
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(addonTitle)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("/arcanum - Toggle UI",1,1,1,true)
	GameTooltip:AddLine("/sfdebug - Toggle Debug",1,1,1,true)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("|cffFFD700Left-Click|r to toggle the main UI!",1,1,1,true)
	GameTooltip:AddLine("|cffFFD700Right-Click|r for Options.",1,1,1,true)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Mouse over most UI Elements to see tooltips for help! (Like this one!)",0.9,0.75,0.75,true)
	GameTooltip:AddDoubleLine(" ", addonTitle.." v"..addonVersion, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8);
	GameTooltip:AddDoubleLine(" ", "by "..addonAuthor, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8);
	GameTooltip:Show()
	
	if self.Flash:IsShown() then UIFrameFlashStop(self.Flash) end
	self.Flash.rainbowVertex = false
	
end)
minimapButton:SetScript("OnLeave", function(self)
	self.highlight.anim:Pause()
	ResetCursor();
	GameTooltip:Hide()
end)

minimapButton:SetScript("OnShow", function(self)
	if not self.Flash:IsShown() then UIFrameFlash(self.Flash, 0.75, 0.75, 4.5, false, 0, 0); end
	rainbowVertex(minimapButton.Flash, minimapButton)
end)
	
local function LoadMinimapPosition()
	local radian = tonumber(SpellCreatorMasterTable.Options["mmLoc"]) or 2.7
	MinimapButton_UpdateAngle(radian);
	if not SpellCreatorMasterTable.Options["minimapIcon"] then minimapButton:SetShown(false) end
end

-------------------------------------------------------------------------------
-- Interface Options - Addon section
-------------------------------------------------------------------------------

function CreateSpellCreatorInterfaceOptions()
	SpellCreatorInterfaceOptions = {};
	SpellCreatorInterfaceOptions.panel = CreateFrame( "Frame", "SpellCreatorInterfaceOptionsPanel", UIParent );
	SpellCreatorInterfaceOptions.panel.name = addonTitle;
	
	local SpellCreatorInterfaceOptionsHeader = SpellCreatorInterfaceOptions.panel:CreateFontString("HeaderString", "OVERLAY", "GameFontNormalLarge")
	SpellCreatorInterfaceOptionsHeader:SetPoint("TOPLEFT", 15, -15)
	SpellCreatorInterfaceOptionsHeader:SetText(addonTitle.." v"..addonVersion.." by "..addonAuthor)
		
	
	local scrollFrame = CreateFrame("ScrollFrame", nil, SpellCreatorInterfaceOptions.panel, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 3, -75*3)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 30)
	
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
	scrollFrame.Title:SetText("Spell Forge")
	scrollFrame.Title:SetPoint('TOP',scrollFrame.backdrop,0,5)

	-- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
	local scrollChild = CreateFrame("Frame")
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(InterfaceOptionsFramePanelContainer:GetWidth()-18)
	scrollChild:SetHeight(1) 

	-- Add widgets to the scrolling child frame as desired


--[[  -- Testing/example to force the scroll frame to have a bunch to scroll
	local footer = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	footer:SetPoint("TOP", 0, -5000)
	footer:SetText("This is 5000 below the top, so the scrollChild automatically expanded.")
--]]
	
	local function genOptionsCheckbutton(buttonData, parent)
	
		--[[
		local buttonData = {
		["anchor"] = {point = , relativeTo = , relativePoint = , x = , y = ,}, 
		["title"] = ,
		["tooltipTitle"] = ,
		["tooltipText"] = ,
		["optionKey"] = ,
		["onClickHandler"] = , -- extra OnClick function
		["customOnLoad"] = , -- extra OnLoad function
		}
		--]]
		button = CreateFrame("CHECKBUTTON", nil, parent, "InterfaceOptionsCheckButtonTemplate")
		if buttonData.anchor.relativePoint then
			button:SetPoint(buttonData.anchor.point, buttonData.anchor.relativeTo, buttonData.anchor.relativePoint, buttonData.anchor.x, buttonData.anchor.y)
		else
			button:SetPoint(buttonData.anchor.point, buttonData.anchor.x, buttonData.anchor.y)
		end
		button.Text:SetText(buttonData.title)
		button:SetScript("OnShow", function(self)
			if SpellCreatorMasterTable.Options[buttonData.optionKey] == true then
				self:SetChecked(true)
			else
				self:SetChecked(false)
			end
		end)
		button:SetScript("OnClick", function(self)
			SpellCreatorMasterTable.Options[buttonData.optionKey] = not SpellCreatorMasterTable.Options[buttonData.optionKey]
			if buttonData.onClickHandler then buttonData.onClickHandler(button); end
		end)
		
		
		button:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			self.Timer = C_Timer.NewTimer(0.7,function()
				GameTooltip:SetText(buttonData.tooltipTitle, nil, nil, nil, nil, true)
				if buttonData.tooltipText then
					GameTooltip:AddLine(buttonData.tooltipText, 1,1,1,1 )
				end
				GameTooltip:Show()
			end)
		end)
		button:SetScript("OnLeave", function(self)
			GameTooltip_Hide()
			self.Timer:Cancel()
		end)
		if SpellCreatorMasterTable.Options[buttonData.optionKey] == true then -- handle default checking of the box
			button:SetChecked(true)
		else
			button:SetChecked(false)
		end
		if buttonData.customOnLoad then buttonData.customOnLoad(); end
		return button;
	end
	
	--Minimap Icon Toggle
	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = nil, relativePoint = nil, x = 20, y = -40,}, 
		["title"] = "Enable Minimap Button",
		["tooltipTitle"] = "Enable Minimap Button",
		["tooltipText"] = nil,
		["optionKey"] = "minimapIcon",
		["onClickHandler"] = function(self) if SpellCreatorMasterTable.Options["minimapIcon"] then minimapButton:SetShown(true) else minimapButton:SetShown(false) end end,
		}
	SpellCreatorInterfaceOptions.panel.MinimapIconToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)
	
	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.MinimapIconToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -5,}, 
		["title"] = "Use Larger Scrollable Input Box",
		["tooltipTitle"] = "Use Larger Input Box.",
		["tooltipText"] = "Switches the 'Input' entry box with a larger, scrollable editbox.\n\rRequires /reload to take affect after changing it.",
		["optionKey"] = "biggerInputBox",
		["onClickHandler"] = function() StaticPopup_Show("SCFORGE_RELOADUI_REQUIRED") end,
		}
	SpellCreatorInterfaceOptions.panel.BiggerInputBoxToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)
	
	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.BiggerInputBoxToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -5,}, 
		["title"] = "AutoShow Vault",
		["tooltipTitle"] = "AutpShow Vault",
		["tooltipText"] = "Automatically show the Vault when you open the Forge.",
		["optionKey"] = "showVaultOnShow",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.showVaultToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.showVaultToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -5,}, 
		["title"] = "Clear Action Data when Removing Row",
		["tooltipTitle"] = "Clear Action Data when Removing Row",
		["tooltipText"] = "When an Action Row is removed using the |cffFFAAAA—|r button, the data is wiped. If off, you can use the |cff00AAFF+|r button and the data will still be there again.",
		["optionKey"] = "clearRowOnRemove",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.clearRowOnRemoveToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.clearRowOnRemoveToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -5,}, 
		["title"] = "Load Actions Chronologically",
		["tooltipTitle"] = "Load Chronologically by Delay",
		["tooltipText"] = "When loading a spell, actions will be loaded in order of their delays, despite the order they were saved in.",
		["optionKey"] = "loadChronologically",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.loadChronologicallyToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.loadChronologicallyToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -5,}, 
		["title"] = "Show Tooltips",
		["tooltipTitle"] = "Show Tooltips",
		["tooltipText"] = "Show Tooltips when you mouse-over UI elements like buttons, editboxes, and spells in the vault, just like this one!",
		["optionKey"] = "showTooltips",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.showTooltipsToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)
	SpellCreatorInterfaceOptions.panel.showTooltipsToggle:Disable()

	-- Debug Checkbox
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
local lockTimer
local function onCommReceived(prefix, message, channel, sender)
	if prefix == addonMsgPrefix.."REQ" then
		sendSpellToPlayer(sender, message)
	elseif prefix == addonMsgPrefix.."SPELL" then
		receiveSpellData(message, sender)
	elseif prefix == addonMsgPrefix.."_PLOCK" then
		local phaseID = C_Epsilon.GetPhaseId()
		if message == phaseID then
			isSavingOrLoadingPhaseAddonData = true
			dprint("Phase Vault IO for Phase "..phaseID.." was locked by Addon Message")
			lockTimer = C_Timer.NewTicker(5, function() isSavingOrLoadingPhaseAddonData=false; eprint("Phase IO Lock on for longer than 10 seconds - disabled. If you get this after changing phases, ignore, otherwise please report it."); end)
		end
	elseif prefix == addonMsgPrefix.."_PUNLOCK" then
		local phaseID = C_Epsilon.GetPhaseId()
		if message == phaseID then
			isSavingOrLoadingPhaseAddonData = false
			dprint("Phase Vault IO for Phase "..phaseID.." was unlocked by Addon Message")
			lockTimer:Cancel()
		end	
	end
end
local function aceCommInit()
	AceComm:RegisterComm(addonMsgPrefix.."REQ", onCommReceived)
	AceComm:RegisterComm(addonMsgPrefix.."SPELL", onCommReceived)
	AceComm:RegisterComm(addonMsgPrefix.."_PLOCK", onCommReceived)
	AceComm:RegisterComm(addonMsgPrefix.."_PUNLOCK", onCommReceived)
end


local SC_Addon_Listener = CreateFrame("frame");
SC_Addon_Listener:RegisterEvent("ADDON_LOADED");
SC_Addon_Listener:RegisterEvent("SCENARIO_UPDATE")
SC_Addon_Listener:RegisterEvent("UI_ERROR_MESSAGE");
SC_Addon_Listener:RegisterEvent("GOSSIP_SHOW");
SC_Addon_Listener:RegisterEvent("GOSSIP_CLOSED");

local modifiedGossips = {}
if not C_Epsilon.IsDM then C_Epsilon.IsDM = false end
SC_Addon_Listener:SetScript("OnEvent", function( self, event, name, ... )
	-- Phase Change Listener
	if event == "SCENARIO_UPDATE" then -- SCENARIO_UPDATE fires whenever a phase change occurs. Lucky us.
		--dprint("Caught Phase Change - Refreshing Load Rows & Checking for Main Phase / Start") -- Commented out for performance.
		isSavingOrLoadingPhaseAddonData = false
		C_Epsilon.IsDM = false
		updateSpellLoadRows();
		
		if tonumber(C_Epsilon.GetPhaseId()) == 169 and GetRealZoneText() == "Dranosh Valley" and not C_Epsilon.IsOfficer() then 
			SCForgeMainFrame.ExecuteSpellButton:Disable()
		else
			SCForgeMainFrame.ExecuteSpellButton:Enable()
		end
		
		return;
		
	-- Addon Loaded Handler
	elseif event == "ADDON_LOADED" and (name == addonName) then
		SC_loadMasterTable();
		LoadMinimapPosition();
		aceCommInit()
	
		local channelType, channelName = JoinChannelByName("scforge_comm")
		scforge_ChannelID = GetChannelName("scforge_comm")
	
		--Quickly Show / Hide the Frame on Start-Up to initialize everything for key bindings & loading
		CTimerAfter(1,function()
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
				
		-- Gen the first few spell rows
		AddSpellRow()
		AddSpellRow()
		AddSpellRow()
		
		isAddonLoaded = true

	-- Phase DM Toggle Listener
	elseif event == "UI_ERROR_MESSAGE" then
		local errType, msg = name, ...
		if msg=="DM mode is ON" then C_Epsilon.IsDM = true; dprint("DM Mode On");
			elseif msg=="DM mode is OFF" then C_Epsilon.IsDM = false; dprint("DM Mode Off");
		end

	-- Gossip Menu Listener
	elseif event == "GOSSIP_SHOW" then
		local spellsToCast = {} -- outside the for loops so we don't reset it on every time
		local shouldAutoHide = false
		local shouldLoadSpellVault = false
		
		for i = 1, GetNumGossipOptions() do
			--[[	-- Doesn't appear this is needed
			_G["GossipTitleButton" .. i]:SetScript("OnClick", function()
				SelectGossipOption(i)
			end)
			--]] 
			local titleButton = _G["GossipTitleButton" .. i]
			local titleButtonText = titleButton:GetText();
			if not titleButtonText then
				local immersionButton = _G["ImmersionTitleButton"..i]
				if immersionButton then titleButton = immersionButton; titleButtonText = immersionButton:GetText() end
			end
			
			--if titleButtonText:match("<arcanum_") then titleButton:SetScript("OnClick", function() end) end
			if titleButtonText:match("<arcanum_auto>") then
				if C_Epsilon.IsDM and (C_Epsilon.IsOfficer() or C_Epsilon.IsOwner()) then
					titleButton:SetText(titleButtonText:gsub("<arcanum_auto>", "<arcanum_auto::DM>"));
					titleButtonText = titleButton:GetText()
					titleButton:HookScript("OnClick", function() scforge_showhide("enableMMIcon") end)
					modifiedGossips[i] = titleButton
				else
					CloseGossip();
					scforge_showhide("enableMMIcon");
				end
				
			elseif titleButtonText:match("<arcanum_toggle>") then
				if not(C_Epsilon.IsDM and (C_Epsilon.IsOfficer() or C_Epsilon.IsOwner())) then
					titleButton:SetText(titleButtonText:gsub("<arcanum_toggle>", ""));
					titleButtonText = titleButton:GetText()
				else
					titleButton:SetText(titleButtonText:gsub("<arcanum_toggle>", "<arcanum_toggle::DM>"));
					titleButtonText = titleButton:GetText()
				end
				titleButton:HookScript("OnClick", function() scforge_showhide("enableMMIcon") end)
				modifiedGossips[i] = titleButton
			end
					
			if titleButtonText:match("<arcanum_cast") then
				
				shouldLoadSpellVault = true
				
				local patterns = {
					"<arcanum_cast:(.*)>",
					"<arcanum_cast_hide:(.*)>",
					"<arcanum_cast_auto:(.*)>",
					"<arcanum_cast_auto_hide:(.*)>",
					}

				for n = 1, #patterns do
					if not titleButtonText then break; end
					if titleButtonText:match(patterns[n]) then
						local payLoad = string.match(titleButtonText, patterns[n]);
						local shouldHide = false
						
						if not(C_Epsilon.IsDM and (C_Epsilon.IsOfficer() or C_Epsilon.IsOwner())) then

							if titleButtonText:match("<arcanum_cast_.*hide:") then -- Only close gossip frame if "hide" is part of the tag.
								shouldHide = true
							end

							if titleButtonText:match("<arcanum_cast_auto.*:") then
								table.insert(spellsToCast, payLoad)
								dprint("Adding AutoCast from Gossip: '"..payLoad.."'.")
								if shouldHide then shouldAutoHide = true end
								titleButton:Hide()
							end
							titleButton:SetText(titleButtonText:gsub(patterns[n], ""));
							titleButtonText = titleButton:GetText()
						else
							titleButton:SetText(titleButtonText:gsub(patterns[n], patterns[n]:gsub("%(%.%*%)",payLoad.."::DM")));
							titleButtonText = titleButton:GetText()
						end

						titleButton:HookScript("OnClick", function() 
							if isSavingOrLoadingPhaseAddonData then eprint("Phase Vault was still loading. Try again in a moment."); return; end
							for k,v in pairs(SCForge_PhaseVaultSpells) do
								if v.commID == payLoad then
									executeSpell(SCForge_PhaseVaultSpells[k].actions); 
								end
							end
							if shouldHide then CloseGossip(); end 
						end)
						modifiedGossips[i] = titleButton
						
					end
				end
				if shouldAutoHide then CloseGossip(); end
			end
			
			GossipResize(titleButton)
			
		end

		if shouldLoadSpellVault then
			getSpellForgePhaseVault(function(ready) 
				if next(spellsToCast) == nil then dprint("No Auto Cast Spells in Gossip"); return; end
				for i,j in pairs(spellsToCast) do
					for k,v in pairs(SCForge_PhaseVaultSpells) do
						if v.commID == j then
							executeSpell(SCForge_PhaseVaultSpells[k].actions); 
						end
					end
				end
				spellsToCast = {} -- empty the table.
			end)
		end

	elseif event == "GOSSIP_CLOSED" then
		for k,v in pairs(modifiedGossips) do
			v:SetScript("OnClick", function()
				SelectGossipOption(k)
			end)
			modifiedGossips[k] = nil
		end
	end

end);
-------------------------------------------------------------------------------
-- Version / Help / Toggle
-------------------------------------------------------------------------------

SLASH_SCFORGEHELP1, SLASH_SCFORGEHELP2 = '/arcanum', '/sf'; -- 3.
function SlashCmdList.SCFORGEHELP(msg, editbox) -- 4.
	if #msg > 0 then
		dprint(false,"Casting Arcanum Spell by CommID: "..msg)
		if SpellCreatorSavedSpells[msg] then
			executeSpell(SpellCreatorSavedSpells[msg].actions)
		elseif msg == "options" then
			scforge_showhide("options")
		else
			cprint("No spell with Command "..msg.." found.")
		end
	else
		scforge_showhide()
	end
end

SLASH_SCFORGEDEBUG1 = '/sfdebug';
function SlashCmdList.SCFORGEDEBUG(msg, editbox) -- 4.
	if SpellCreatorMasterTable.Options["debug"] and msg ~= "" then
		if msg == "debug" then
			cprint("DEBUG LIST")
			cprint("Version: "..addonVersion)
			--cprint("RuneIcon: "..runeIconOverlay.atlas or runeIconOverlay.tex)
			cprint("Debug Commands: ")
			print(" - resetSpells: reset your vault to empty. Cannot be undone.")
			print(" - listSpells: List all your vault spells.. this is alot of stuff.")
			print(" - listSpellKeys: List all your vault spells by just keys. Easier to read.")
			print(" - resetPhaseSpellKeys: reset your phase vault to empty. Technically the spell data remains, but cannot be restored without manual help from MindScape.")
			print(" - getPhaseKeys: Lists all the vault spells by keys.")
			
		elseif msg == "resetSpells" then
			dprint(true, "All Arcaum Spells reset. #GoodBye #ThisCannotBeUndoneHopeYouDidn'tFuckUp!")
			SpellCreatorSavedSpells = {}
			updateSpellLoadRows()
		elseif msg == "listSpells" then
			for k,v in orderedPairs(SpellCreatorSavedSpells) do
				print(k, dump(v))
			end
		elseif msg == "listSpellKeys" then -- debug to list all spell keys by alphabetical order.
			local newTable = get_keys(SpellCreatorSavedSpells)
			table.sort(newTable)
			print(dump(newTable))
		elseif msg == "resetPhaseSpellKeys" then
			C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", "")
			dprint(true, "Wiped all Spell Keys from Phase Vault memory. This does not wipe the data itself of the spells, so they can technically be recovered by manually adding the key back, or begging Azar/Raz to give you the data and then running it thru libDeflate/AceSerializer/Decode. Yeah..")
		elseif msg == "getPhaseKeys" then
			local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")

			phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
			
			phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
				if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
					phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" )
					print(text)
					phaseVaultKeys = serialDecompressForAddonMsg(text)
					print(dump(phaseVaultKeys))
				end
			end)
		
		end
	else
		SpellCreatorMasterTable.Options["debug"] = not SpellCreatorMasterTable.Options["debug"]
		dprint(true, "SC-Forge Debug Set to: "..tostring(SpellCreatorMasterTable.Options["debug"]))
	end
end


SLASH_SCFORGETEST1 = '/sftest';
function SlashCmdList.SCFORGETEST(msg, editbox) -- 4.

	if msg == "getPhaseKeys" then
		local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")

		phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
		
		phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
			if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
				phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" )
				print(text)
				phaseVaultKeys = serialDecompressForAddonMsg(text)
				print(dump(phaseVaultKeys))
			end
		end)
	else
		initRuneIcon()
		setRuneTex(runeIconOverlay)
	end
	
end