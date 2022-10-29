local addonName, addonTable = ...
local addonVersion, addonAuthor, addonTitle = GetAddOnMetadata(addonName, "Version"), GetAddOnMetadata(addonName, "Author"), GetAddOnMetadata(addonName, "Title")
local addonPath = "Interface/AddOns/"..tostring(addonName)

local addonColor = "|cff".."ce2eff" -- options: 7e1af0 (hard to read) -- 7814ea -- 8a30f1 -- 9632ff
local addonMsgPrefix = "SCFORGE"

local localization = {}
localization.SPELLNAME = STAT_CATEGORY_SPELL.." "..NAME
localization.SPELLCOMM = STAT_CATEGORY_SPELL.." "..COMMAND

local savedSpellFromVault = {}

local modifiedGossips = {}
local isGossipLoaded

-- localized frequent functions for speed
local CTimerAfter = C_Timer.After
local C_Timer = C_Timer

--
-- local curDate = date("*t") -- Current Date for surprise launch - disabled since it's over anyways

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

-- This is deprecated, vault style 1 is no longer supported.
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

local function sendChat(text)
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
		print(addonColor..addonTitle.." Error @ "..line..": "..text..""..(rest and " | "..rest or "").." |r")
	else
		print(addonColor..addonTitle.." @ ERROR: "..text.." | "..rest.." |r")
		print(debugstack(2))
	end
end

--local dump = DevTools_Dump
local function dump(o)
	if not DevTools_Dump then
		UIParentLoadAddOn("Blizzard_DebugTools");
	end
	DevTools_Dump(o);

--[[ -- Old Table String-i-zer.. Replaced with Blizzard_DebugTools nice dump :)
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
--]]
end

local function ddump(o)
	if SpellCreatorMasterTable.Options["debug"] then
		local line = strmatch(debugstack(2),":(%d+):")
		print(addonColor..addonTitle.." DEBUG-DUMP "..line..":|r")
		dump(o)
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
	if isNotDefined(SpellCreatorMasterTable.Options["minimapIcon"]) then SpellCreatorMasterTable.Options["minimapIcon"] = true end

	if not SpellCreatorSavedSpells then SpellCreatorSavedSpells = {} end

	--[[ -- Current Date Check for past Oct 25, 2022. Disabled since we are past that anyways now.
	if (curDate.year >= 2023 or curDate.yday >= 298) then -- Only default to showing the minimap icon after October 25th, 2022
		
	end
	--]]

	-- reset these so we are not caching debug data longer than a single reload.
	SpellCreatorMasterTable.Options["debugPhaseData"] = nil
	SpellCreatorMasterTable.Options["debugPhaseKeys"] = nil
end

-------------------------------------------------------------------------------
-- UI Stuff
-------------------------------------------------------------------------------

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

------------- Background Models

local minimapModels = {
{disp = 58836, camScale = 1}, -- Purple Missle
{disp = 71960, camScale = 1}, -- Nightborne Missle
--{disp = 91994, camScale = 1}, -- Void Sporadic
{disp = 92827, camScale = 0.95}, -- Void Scrolling
{disp = 31497, camScale = 5, alpha=0.7}, -- Arcane Portal
--{disp = 39581, camScale = 5}, -- Blue Portalish - not great
{disp = 61420, camScale = 2.5}, -- Purple Portal
{disp = 66092, camScale = 3, alpha=0.2}, -- Thick Purple Magic Ring
{disp = 74190, camScale = 3, alpha=0.25}, -- Thick Blue Magic Ring
{disp = 88991, camScale = 6.5}, -- Void Ring
}

local function modelFrameSetModel(frame, id, list)
	id = tonumber(id)
	frame:SetDisplayInfo(list[id].disp)
	frame:SetCamDistanceScale(list[id].camScale)
	frame:SetRotation(0)
	frame:SetModelAlpha(list[id].alpha or 1)
end

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
		if actionData.doNotDelimit then
			varTable = { vars }
		else
			varTable = { strsplit(",", vars) }
		end
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
local function executeSpell(actionsToCommit, byPassCheck)
	if not byPassCheck then
		if tonumber(C_Epsilon.GetPhaseId()) == 169 and GetRealZoneText() == "Dranosh Valley" and not C_Epsilon.IsOfficer() then cprint("Casting Arcanum Spells in Main Phase Start Zone is Disabled. Trying to test the Main Phase Vault spells? Head somewhere other than Dranosh Valley.") return; end
	end
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
		["inputDescription"] = "You can use any server command here, without the '.', and it will run after the delay.\n\rTechnically accepts multiple commands, separated by commas.\n\rExample: 'mod drunk 100'.",
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
local selfColumnWidth = 32
local InputEntryColumnWidth = 140+42
local revertCheckColumnWidth = 60
local revertDelayColumnWidth = 80

-- Drop Down Generator
local function genStaticDropdownChild( parent, dropdownName, menuList, title, width )

	if not parent or not dropdownName or not menuList then return end;
	if not title then title = "Select" end
	if not width then width = 55 end
	local newDropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
	parent.Dropdown = newDropdown
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

local function setFrameFlicker(frame, iter, timeToFadeOut, timeToFadeIn, startAlpha, endAlpha, repeatnum)
	if not frame then return; end

	if not timeToFadeOut then timeToFadeOut = 0.1 end
	if not timeToFadeIn then timeToFadeIn = 0.5 end
	if not startAlpha then startAlpha = 1 end
	if not endAlpha then endAlpha = 0.33 end

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
local function stopFrameFlicker(frame, endAlpha, optFadeTime)
	for i = 1, #frame.flickerTimer do
		frame.flickerTimer[i]:Cancel()
	end
	if optFadeTime then
		UIFrameFadeOut(frame, optFadeTime, frame:GetAlpha(), endAlpha)
	else
		frame:SetAlpha(endAlpha or 1)
	end
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

local function RemoveSpellRow(rowToRemove)
	if numberOfSpellRows <= 1 then 
		local theSpellRow = _G["spellRow"..numberOfSpellRows]
		theSpellRow.mainDelayBox:SetText("")
		for k,v in pairs(theSpellRow.menuList) do
			v.checked = false
		end
		UIDropDownMenu_SetSelectedID(theSpellRow.actionSelectButton.Dropdown, 0)
		theSpellRow.actionSelectButton.Dropdown.Text:SetText("Action")
		updateSpellRowOptions(numberOfSpellRows, nil)

		theSpellRow.SelfCheckbox:SetChecked(false)
		theSpellRow.InputEntryBox:SetText("")
		theSpellRow.RevertDelayBox:SetText("")
		return;
	end

	if rowToRemove and (rowToRemove ~= numberOfSpellRows) then
		for i = rowToRemove, numberOfSpellRows-1 do
			local theRowToSet = _G["spellRow"..i]
			local theRowToGrab = _G["spellRow"..i+1]

			for k,v in pairs(theRowToSet.menuList) do
				v.checked = false
			end

			-- theRowToSet.actionSelectButton.Dropdown
			-- theRowToGrab.actionSelectButton.Dropdown
			UIDropDownMenu_SetSelectedID(theRowToSet.actionSelectButton.Dropdown, UIDropDownMenu_GetSelectedID(theRowToGrab.actionSelectButton.Dropdown))
			theRowToSet.actionSelectButton.Dropdown.Text:SetText(theRowToGrab.actionSelectButton.Dropdown.Text:GetText())
			theRowToSet.SelectedAction = theRowToGrab.SelectedAction
			updateSpellRowOptions(i, theRowToGrab.SelectedAction)
			
			theRowToSet.mainDelayBox:SetText(theRowToGrab.mainDelayBox:GetText())
			theRowToSet.SelfCheckbox:SetChecked(theRowToGrab.SelfCheckbox:GetChecked())
			theRowToSet.InputEntryBox:SetText(theRowToGrab.InputEntryBox:GetText())
			theRowToSet.RevertDelayBox:SetText(theRowToGrab.RevertDelayBox:GetText())
		end
	end

	-- Now that we moved the data if needed, let's delete the last row..
	local theSpellRow = _G["spellRow"..numberOfSpellRows]
	theSpellRow:Hide()

--	if SpellCreatorMasterTable.Options["clearRowOnRemove"] then
		theSpellRow.mainDelayBox:SetText("")

		for k,v in pairs(theSpellRow.menuList) do
			v.checked = false
		end
		-- theSpellRow.actionSelectButton.Dropdown
		UIDropDownMenu_SetSelectedID(theSpellRow.actionSelectButton.Dropdown, 0)
		theSpellRow.actionSelectButton.Dropdown.Text:SetText("Action")
		updateSpellRowOptions(numberOfSpellRows, nil)

		theSpellRow.SelfCheckbox:SetChecked(false)
		theSpellRow.InputEntryBox:SetText("")
		theSpellRow.RevertDelayBox:SetText("")
--	end

	numberOfSpellRows = numberOfSpellRows - 1

	_G["spellRow"..numberOfSpellRows].RevertDelayBox.nextEditBox = spellRow1.mainDelayBox

	--if numberOfSpellRows < maxNumberOfSpellRows then SCForgeMainFrame.AddSpellRowButton:Enable() end
	if numberOfSpellRows < maxNumberOfSpellRows then SCForgeMainFrame.AddRowRow.AddRowButton:Enable() end
	
	--if numberOfSpellRows <= 1 then SCForgeMainFrame.RemoveSpellRowButton:Disable() end
	SCForgeMainFrame.Inset.scrollFrame:UpdateScrollChildRect()

	SCForgeMainFrame.AddRowRow:SetPoint("TOPLEFT", "spellRow"..numberOfSpellRows, "BOTTOMLEFT", 0, 0)
end

local function AddSpellRow()
	--if numberOfSpellRows >= maxNumberOfSpellRows then SCForgeMainFrame.AddSpellRowButton:Disable() return; end -- hard cap
	if numberOfSpellRows >= maxNumberOfSpellRows then SCForgeMainFrame.AddRowRow.AddRowButton:Disable() return; end -- hard cap
	--SCForgeMainFrame.RemoveSpellRowButton:Enable()
	numberOfSpellRows = numberOfSpellRows+1		-- The number of spell rows that this row will be.
	local newRow
	if _G["spellRow"..numberOfSpellRows] then
		newRow = _G["spellRow"..numberOfSpellRows]
		newRow:Show();
	else

		-- The main row frame
		newRow = CreateFrame("Frame", "spellRow"..numberOfSpellRows, SCForgeMainFrame.Inset.scrollFrame.scrollChild)
		newRow.rowNum = numberOfSpellRows
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
		newRow.mainDelayBox = CreateFrame("EditBox", "spellRow"..numberOfSpellRows.."MainDelayBox", newRow, "InputBoxInstructionsTemplate")
			newRow.mainDelayBox:SetFontObject(ChatFontNormal)
			newRow.mainDelayBox.disabledColor = GRAY_FONT_COLOR
			newRow.mainDelayBox.enabledColor = HIGHLIGHT_FONT_COLOR
			newRow.mainDelayBox.Instructions:SetText("(Seconds)")
			newRow.mainDelayBox.Instructions:SetTextColor(0.5,0.5,0.5)
			newRow.mainDelayBox:SetAutoFocus(false)
			newRow.mainDelayBox:SetSize(delayColumnWidth,23)
			newRow.mainDelayBox:SetPoint("LEFT", 40, 0)
			newRow.mainDelayBox:SetMaxLetters(10)
			newRow.mainDelayBox:HookScript("OnTextChanged", function(self)
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
				ddump(self)
				updateSpellRowOptions(arg1, menuItem.value)
			end
			table.insert(menuList, menuItem)
		end

		newRow.actionSelectButton = CreateFrame("Frame", "spellRow"..numberOfSpellRows.."ActionSelectAnchor", newRow)
		newRow.actionSelectButton:SetPoint("LEFT", newRow.mainDelayBox, "RIGHT", 0, -2)
		genStaticDropdownChild( newRow.actionSelectButton, "spellRow"..numberOfSpellRows.."ActionSelectButton", menuList, "Action", actionColumnWidth)

		-- Self Checkbox
		newRow.SelfCheckbox = CreateFrame("CHECKBUTTON", "spellRow"..numberOfSpellRows.."SelfCheckbox", newRow, "UICheckButtonTemplate")
			newRow.SelfCheckbox:SetPoint("LEFT", newRow.actionSelectButton, "RIGHT", -5, 1)
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
			newRow.InputEntryScrollFrame:SetSize(InputEntryColumnWidth,40)
			newRow.InputEntryScrollFrame:SetPoint("LEFT", newRow.SelfCheckbox, "RIGHT", 15, 1)
			newRow.InputEntryBox = newRow.InputEntryScrollFrame.EditBox
			_G["spellRow"..numberOfSpellRows.."InputEntryBox"] = newRow.InputEntryBox
			newRow.InputEntryBox:SetWidth(newRow.InputEntryScrollFrame:GetWidth()-18)
		else
			newRow.InputEntryBox = CreateFrame("EditBox", "spellRow"..numberOfSpellRows.."InputEntryBox", newRow, "InputBoxInstructionsTemplate")
			newRow.InputEntryBox:SetSize(InputEntryColumnWidth,23)
			newRow.InputEntryBox:SetPoint("LEFT", newRow.SelfCheckbox, "RIGHT", 15, 1)
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
					if _G["spellRow"..row].SelectedAction and actionTypeData[_G["spellRow"..row].SelectedAction].dataName then
						local actionData = actionTypeData[_G["spellRow"..row].SelectedAction]
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

		-- Revert Delay Box

		newRow.RevertDelayBox = CreateFrame("EditBox", "spellRow"..numberOfSpellRows.."RevertDelayBox", newRow, "InputBoxInstructionsTemplate")
			newRow.RevertDelayBox:SetFontObject(ChatFontNormal)
			newRow.RevertDelayBox.disabledColor = GRAY_FONT_COLOR
			newRow.RevertDelayBox.enabledColor = HIGHLIGHT_FONT_COLOR
			newRow.RevertDelayBox.Instructions:SetText("Revert Delay")
			newRow.RevertDelayBox.Instructions:SetTextColor(0.5,0.5,0.5)
			newRow.RevertDelayBox:SetAutoFocus(false)
			newRow.RevertDelayBox:Disable()
			newRow.RevertDelayBox:SetSize(revertDelayColumnWidth,23)
			newRow.RevertDelayBox:SetPoint("LEFT", (newRow.InputEntryScrollFrame or newRow.InputEntryBox), "RIGHT", 25, 0)
			newRow.RevertDelayBox:SetMaxLetters(10)

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


		newRow.RemoveSpellRowButton = CreateFrame("BUTTON", nil, newRow)
			newRow.RemoveSpellRowButton.rowNum = numberOfSpellRows
			newRow.RemoveSpellRowButton:SetPoint("TOPRIGHT", -8, 0)
			newRow.RemoveSpellRowButton:SetSize(24,24)
			--local _atlas = "transmog-icon-remove"
			local _atlas = "communities-chat-icon-minus"

			newRow.RemoveSpellRowButton:SetNormalAtlas(_atlas)
			newRow.RemoveSpellRowButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

			newRow.RemoveSpellRowButton.DisabledTex = newRow.RemoveSpellRowButton:CreateTexture(nil, "ARTWORK")
			newRow.RemoveSpellRowButton.DisabledTex:SetAllPoints(true)
			newRow.RemoveSpellRowButton.DisabledTex:SetAtlas(_atlas)
			newRow.RemoveSpellRowButton.DisabledTex:SetDesaturated(true)
			newRow.RemoveSpellRowButton.DisabledTex:SetVertexColor(.6,.6,.6)
			newRow.RemoveSpellRowButton:SetDisabledTexture(newRow.RemoveSpellRowButton.DisabledTex)

			newRow.RemoveSpellRowButton.PushedTex = newRow.RemoveSpellRowButton:CreateTexture(nil, "ARTWORK")
			newRow.RemoveSpellRowButton.PushedTex:SetAllPoints(true)
			newRow.RemoveSpellRowButton.PushedTex:SetAtlas(_atlas)
			newRow.RemoveSpellRowButton.PushedTex:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
			newRow.RemoveSpellRowButton.PushedTex:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
			newRow.RemoveSpellRowButton.PushedTex:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
			newRow.RemoveSpellRowButton.PushedTex:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
			newRow.RemoveSpellRowButton:SetPushedTexture(newRow.RemoveSpellRowButton.PushedTex)

			newRow.RemoveSpellRowButton:SetMotionScriptsWhileDisabled(true)
			newRow.RemoveSpellRowButton:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				self.Timer = C_Timer.NewTimer(0.7,function()
					GameTooltip:SetText("Remove this row.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
			end)
			newRow.RemoveSpellRowButton:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
				--[[
				if ( not self:GetParent():IsMouseOver() ) then
					self:Hide()
				end
				--]]
			end)
			newRow.RemoveSpellRowButton:SetScript("OnClick", function(self)
				RemoveSpellRow(self.rowNum)
			end)
			newRow.RemoveSpellRowButton:SetScript("OnShow", function(self)
				self:SetScript("OnUpdate", function(self)
					local doHide = true
					local family = { self, newRow, newRow:GetChildren() }
					for i = 1, #family do
						local kin = family[i]
						if ( kin:IsMouseOver() ) then
							doHide = false
						end
					end
					if doHide then self:Hide(); end
				end)
			end)
			newRow.RemoveSpellRowButton:SetScript("OnHide", function(self)
				self:SetScript("OnUpdate", nil)
			end)
			newRow:SetScript("OnEnter", function(self)
				self.RemoveSpellRowButton:Show()
			end)
			newRow.RemoveSpellRowButton:Hide()

	end
	-- Make Tab work to switch edit boxes

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
	--if numberOfSpellRows >= maxNumberOfSpellRows then SCForgeMainFrame.AddSpellRowButton:Disable(); return; end -- hard cap
	if numberOfSpellRows >= maxNumberOfSpellRows then SCForgeMainFrame.AddRowRow.AddRowButton:Disable(); return; end -- hard cap

	SCForgeMainFrame.AddRowRow:SetPoint("TOPLEFT", "spellRow"..numberOfSpellRows, "BOTTOMLEFT", 0, 0)

	SCForgeMainFrame.Inset.scrollFrame:UpdateScrollChildRect()
end

function updateSpellRowOptions(row, selectedAction)
		-- perform action type checks here against the actionTypeData table & disable/enable buttons / entries as needed. See actionTypeData for available options. 
	if selectedAction then -- if we call it with no action, reset
		_G["spellRow"..row].SelectedAction = selectedAction
		if actionTypeData[selectedAction].selfAble then _G["spellRow"..row.."SelfCheckbox"]:Enable() else _G["spellRow"..row.."SelfCheckbox"]:Disable() end
		if actionTypeData[selectedAction].dataName then
			_G["spellRow"..row.."InputEntryBox"]:Enable()
			_G["spellRow"..row.."InputEntryBox"].Instructions:SetText(actionTypeData[selectedAction].dataName)
			if actionTypeData[selectedAction].inputDescription then _G["spellRow"..row.."InputEntryBox"].Description = actionTypeData[selectedAction].inputDescription end
		else
			_G["spellRow"..row.."InputEntryBox"]:Disable()
			_G["spellRow"..row.."InputEntryBox"].Instructions:SetText("n/a")
		end
		if actionTypeData[selectedAction].revert then
			_G["spellRow"..row.."RevertDelayBox"]:Enable();
		else
			_G["spellRow"..row.."RevertDelayBox"]:Disable();
		end
	else
		_G["spellRow"..row].SelectedAction = nil
		_G["spellRow"..row.."SelfCheckbox"]:Disable()
		_G["spellRow"..row.."InputEntryBox"].Instructions:SetText("select an action...")
		_G["spellRow"..row.."InputEntryBox"]:Disable()
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
SCForgeMainFrame.portrait.icon:SetAlpha(0.93)
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

SCForgeMainFrame.portrait.Model = CreateFrame("PLAYERMODEL", nil, SCForgeMainFrame, "MouseDisabledModelTemplate")
SCForgeMainFrame.portrait.Model:SetAllPoints(SCForgeMainFramePortrait)
SCForgeMainFrame.portrait.Model:SetFrameStrata("MEDIUM")
SCForgeMainFrame.portrait.Model:SetFrameLevel(SCForgeMainFrame:GetFrameLevel())
SCForgeMainFrame.portrait.Model:SetModelDrawLayer("OVERLAY")
SCForgeMainFrame.portrait.Model:SetKeepModelOnHide(true)
modelFrameSetModel(SCForgeMainFrame.portrait.Model, fastrandom(#minimapModels), minimapModels)
SCForgeMainFrame.portrait.Model:SetScript("OnMouseDown", function()
	local randID = fastrandom(#minimapModels)
	modelFrameSetModel(SCForgeMainFrame.portrait.Model, randID, minimapModels)
	dprint("Portrait Icon BG Model Set to ID "..randID)
end)

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

	background.Overlay = SCForgeMainFrame.Inset:CreateTexture(nil, "BACKGROUND")
	background.Overlay:SetTexture(addonPath.."/assets/forge_ui_bg_anim")
	background.Overlay:SetAllPoints()
	background.Overlay:SetAlpha(0.02)

	background.Overlay2 = SCForgeMainFrame.Inset:CreateTexture(nil, "BACKGROUND")
	background.Overlay2:SetTexture(addonPath.."/assets/forge_ui_bg_runes")
	background.Overlay2:SetAllPoints()
	background.Overlay2:SetAlpha(0.25)

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

SCForgeMainFrame.TitleBar = CreateFrame("Frame", nil, SCForgeMainFrame.Inset)
	SCForgeMainFrame.TitleBar:SetPoint("TOPLEFT", SCForgeMainFrame.Inset, "TOPLEFT", 25, -8)
	SCForgeMainFrame.TitleBar:SetSize(mainFrameSize.x-50, 24)
	--SCForgeMainFrame.TitleBar:SetHeight(20)

	SCForgeMainFrame.TitleBar.Background = SCForgeMainFrame.TitleBar:CreateTexture(nil,"BACKGROUND", nil, 5)
		SCForgeMainFrame.TitleBar.Background:SetAllPoints()
		SCForgeMainFrame.TitleBar.Background:SetColorTexture(0,0,0,0.25)
		local titleBackgroundClamp = 0
		SCForgeMainFrame.TitleBar.Background:SetPoint("TOPLEFT",-3+titleBackgroundClamp,0)
		SCForgeMainFrame.TitleBar.Background:SetPoint("BOTTOMRIGHT",-8-titleBackgroundClamp,0)

	SCForgeMainFrame.TitleBar.Overlay = SCForgeMainFrame.TitleBar:CreateTexture(nil,"BACKGROUND", nil, 6)
		SCForgeMainFrame.TitleBar.Overlay:SetAllPoints(SCForgeMainFrame.TitleBar.Background)
		--SCForgeMainFrame.TitleBar.Overlay:SetTexture(addonPath.."/assets/SpellForgeMainPanelRow2")
		SCForgeMainFrame.TitleBar.Overlay:SetAtlas("search-select")
		SCForgeMainFrame.TitleBar.Overlay:SetDesaturated(true)
		SCForgeMainFrame.TitleBar.Overlay:SetVertexColor(0.35,0.7,0.85)
		--SCForgeMainFrame.TitleBar.Overlay:SetTexCoord(0.208,1-0.209,0,1-0)

	SCForgeMainFrame.TitleBar.MainDelay = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
		SCForgeMainFrame.TitleBar.MainDelay:SetWidth(delayColumnWidth)
		SCForgeMainFrame.TitleBar.MainDelay:SetJustifyH("CENTER")
		SCForgeMainFrame.TitleBar.MainDelay:SetPoint("LEFT", SCForgeMainFrame.TitleBar, "LEFT", 13+25, 0)
		SCForgeMainFrame.TitleBar.MainDelay:SetText("Delay")

	SCForgeMainFrame.TitleBar.Action = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
		SCForgeMainFrame.TitleBar.Action:SetWidth(actionColumnWidth+50)
		SCForgeMainFrame.TitleBar.Action:SetJustifyH("CENTER")
		SCForgeMainFrame.TitleBar.Action:SetPoint("LEFT", SCForgeMainFrame.TitleBar.MainDelay, "RIGHT", 0, 0)
		SCForgeMainFrame.TitleBar.Action:SetText("Action")

	SCForgeMainFrame.TitleBar.Self = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
		SCForgeMainFrame.TitleBar.Self:SetWidth(selfColumnWidth+10)
		SCForgeMainFrame.TitleBar.Self:SetJustifyH("CENTER")
		SCForgeMainFrame.TitleBar.Self:SetPoint("LEFT", SCForgeMainFrame.TitleBar.Action, "RIGHT", -9, 0)
		SCForgeMainFrame.TitleBar.Self:SetText("Self")

	SCForgeMainFrame.TitleBar.InputEntry = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
		SCForgeMainFrame.TitleBar.InputEntry:SetWidth(InputEntryColumnWidth)
		SCForgeMainFrame.TitleBar.InputEntry:SetJustifyH("CENTER")
		SCForgeMainFrame.TitleBar.InputEntry:SetPoint("LEFT", SCForgeMainFrame.TitleBar.Self, "RIGHT", 5, 0)
		SCForgeMainFrame.TitleBar.InputEntry:SetText("Input")

	SCForgeMainFrame.TitleBar.RevertDelay = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
		SCForgeMainFrame.TitleBar.RevertDelay:SetWidth(revertDelayColumnWidth)
		SCForgeMainFrame.TitleBar.RevertDelay:SetJustifyH("CENTER")
		SCForgeMainFrame.TitleBar.RevertDelay:SetPoint("LEFT", SCForgeMainFrame.TitleBar.InputEntry, "RIGHT", 25, 0)
		SCForgeMainFrame.TitleBar.RevertDelay:SetText("Revert")

SCForgeMainFrame.AddRowRow = CreateFrame("Frame", nil, SCForgeMainFrame.Inset.scrollFrame.scrollChild)
local _frame = SCForgeMainFrame.AddRowRow
	_frame:SetPoint("TOPLEFT", 25, 0)
	_frame:SetWidth(mainFrameSize.x-50)
	_frame:SetHeight(rowHeight)

	_frame.Background = _frame:CreateTexture(nil,"BACKGROUND", nil, 5)
		_frame.Background:SetAllPoints()
		_frame.Background:SetTexture(addonPath.."/assets/SpellForgeMainPanelRow1")
		_frame.Background:SetTexCoord(0.208,1-0.209,0,1)
		_frame.Background:SetPoint("BOTTOMRIGHT",-9,0)
		_frame.Background:SetAlpha(0.9)

	_frame.Background2 = _frame:CreateTexture(nil,"BACKGROUND", nil, 6)
		_frame.Background2:SetAllPoints()
		_frame.Background2:SetTexture(addonPath.."/assets/SpellForgeMainPanelRow2")
		_frame.Background2:SetTexCoord(0.208,1-0.209,0,1)
		_frame.Background2:SetPoint("TOPLEFT",-3,0)
		_frame.Background2:SetPoint("BOTTOMRIGHT",-7,0)

		-- SCForgeMainFrame.AddRowRow.AddRowButton
	_frame.AddRowButton = CreateFrame("BUTTON", nil, _frame)
		--_frame.AddRowButton:SetPoint("CENTER")
		_frame.AddRowButton:SetAllPoints()
		--_frame.AddRowButton:SetSize(24,24)

		--local _atlas = "Garr_Building-AddFollowerPlus"
		local _atlas = "communities-chat-icon-plus"
		_frame.AddRowButton:SetNormalAtlas(_atlas)
		_frame.AddRowButton.Normal = _frame.AddRowButton:GetNormalTexture()
		_frame.AddRowButton.Normal:ClearAllPoints()
		_frame.AddRowButton.Normal:SetPoint("CENTER")
		_frame.AddRowButton.Normal:SetSize(48,48)
		_frame.AddRowButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

		_frame.AddRowButton.DisabledTex = _frame.AddRowButton:CreateTexture(nil, "ARTWORK")
		_frame.AddRowButton.DisabledTex:SetAllPoints(_frame.AddRowButton.Normal)
		_frame.AddRowButton.DisabledTex:SetAtlas(_atlas)
		_frame.AddRowButton.DisabledTex:SetDesaturated(true)
		_frame.AddRowButton.DisabledTex:SetVertexColor(.6,.6,.6)
		_frame.AddRowButton:SetDisabledTexture(_frame.AddRowButton.DisabledTex)

		_frame.AddRowButton.PushedTex = _frame.AddRowButton:CreateTexture(nil, "ARTWORK")
		_frame.AddRowButton.PushedTex:SetAllPoints(_frame.AddRowButton.Normal)
		_frame.AddRowButton.PushedTex:SetAtlas(_atlas)
		_frame.AddRowButton.PushedTex:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
		_frame.AddRowButton.PushedTex:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
		_frame.AddRowButton.PushedTex:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
		_frame.AddRowButton.PushedTex:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
		_frame.AddRowButton:SetPushedTexture(_frame.AddRowButton.PushedTex)

		_frame.AddRowButton:SetMotionScriptsWhileDisabled(true)
		_frame.AddRowButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			self.Timer = C_Timer.NewTimer(0.7,function()
				GameTooltip:SetText("Add another Action row.", nil, nil, nil, nil, true)
				GameTooltip:AddLine("Max number of Rows: "..maxNumberOfSpellRows,1,1,1,true)
				GameTooltip:Show()
			end)
		end)
		_frame.AddRowButton:SetScript("OnLeave", function(self)
			GameTooltip_Hide()
			self.Timer:Cancel()
		end)
		_frame.AddRowButton:SetScript("OnClick", function(self)
			AddSpellRow()
		end)


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

--[[ -- Replaced!
SCForgeMainFrame.AddSpellRowButton = CreateFrame("BUTTON", nil, SCForgeMainFrame)
	SCForgeMainFrame.AddSpellRowButton:SetPoint("BOTTOMRIGHT", -40, 2)
	SCForgeMainFrame.AddSpellRowButton:SetSize(24,24)

	--local _atlas = "Garr_Building-AddFollowerPlus"
	local _atlas = "communities-chat-icon-plus"
	SCForgeMainFrame.AddSpellRowButton:SetNormalAtlas(_atlas)
	SCForgeMainFrame.AddSpellRowButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

	SCForgeMainFrame.AddSpellRowButton.DisabledTex = SCForgeMainFrame.AddSpellRowButton:CreateTexture(nil, "ARTWORK")
	SCForgeMainFrame.AddSpellRowButton.DisabledTex:SetAllPoints(true)
	SCForgeMainFrame.AddSpellRowButton.DisabledTex:SetAtlas(_atlas)
	SCForgeMainFrame.AddSpellRowButton.DisabledTex:SetDesaturated(true)
	SCForgeMainFrame.AddSpellRowButton.DisabledTex:SetVertexColor(.6,.6,.6)
	SCForgeMainFrame.AddSpellRowButton:SetDisabledTexture(SCForgeMainFrame.AddSpellRowButton.DisabledTex)

	SCForgeMainFrame.AddSpellRowButton.PushedTex = SCForgeMainFrame.AddSpellRowButton:CreateTexture(nil, "ARTWORK")
	SCForgeMainFrame.AddSpellRowButton.PushedTex:SetAllPoints(true)
	SCForgeMainFrame.AddSpellRowButton.PushedTex:SetAtlas(_atlas)
	SCForgeMainFrame.AddSpellRowButton.PushedTex:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
	SCForgeMainFrame.AddSpellRowButton.PushedTex:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
	SCForgeMainFrame.AddSpellRowButton.PushedTex:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
	SCForgeMainFrame.AddSpellRowButton.PushedTex:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
	SCForgeMainFrame.AddSpellRowButton:SetPushedTexture(SCForgeMainFrame.AddSpellRowButton.PushedTex)

	SCForgeMainFrame.AddSpellRowButton:SetMotionScriptsWhileDisabled(true)
	SCForgeMainFrame.AddSpellRowButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
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
--]]

-- Remove Spell Row Button -- Replaced!
--[[
SCForgeMainFrame.RemoveSpellRowButton = CreateFrame("BUTTON", nil, SCForgeMainFrame)
SCForgeMainFrame.RemoveSpellRowButton:SetPoint("RIGHT", SCForgeMainFrame.AddSpellRowButton, "LEFT", -5, 0)
SCForgeMainFrame.RemoveSpellRowButton:SetSize(24,24)
--local _atlas = "transmog-icon-remove"
local _atlas = "communities-chat-icon-minus"

SCForgeMainFrame.RemoveSpellRowButton:SetNormalAtlas(_atlas)
SCForgeMainFrame.RemoveSpellRowButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

SCForgeMainFrame.RemoveSpellRowButton.DisabledTex = SCForgeMainFrame.RemoveSpellRowButton:CreateTexture(nil, "ARTWORK")
SCForgeMainFrame.RemoveSpellRowButton.DisabledTex:SetAllPoints(true)
SCForgeMainFrame.RemoveSpellRowButton.DisabledTex:SetAtlas(_atlas)
SCForgeMainFrame.RemoveSpellRowButton.DisabledTex:SetDesaturated(true)
SCForgeMainFrame.RemoveSpellRowButton.DisabledTex:SetVertexColor(.6,.6,.6)
SCForgeMainFrame.RemoveSpellRowButton:SetDisabledTexture(SCForgeMainFrame.RemoveSpellRowButton.DisabledTex)

SCForgeMainFrame.RemoveSpellRowButton.PushedTex = SCForgeMainFrame.RemoveSpellRowButton:CreateTexture(nil, "ARTWORK")
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetAllPoints(true)
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetAtlas(_atlas)
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
SCForgeMainFrame.RemoveSpellRowButton.PushedTex:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
SCForgeMainFrame.RemoveSpellRowButton:SetPushedTexture(SCForgeMainFrame.RemoveSpellRowButton.PushedTex)

SCForgeMainFrame.RemoveSpellRowButton:SetMotionScriptsWhileDisabled(true)
SCForgeMainFrame.RemoveSpellRowButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
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
--]]

-- Revert Forge UI Rows Button
SCForgeMainFrame.ResetUIButton = CreateFrame("BUTTON", nil, SCForgeMainFrame)
local button = SCForgeMainFrame.ResetUIButton
button:SetPoint("BOTTOMRIGHT", -40, 2)
button:SetSize(24,24)

button:SetNormalAtlas("transmog-icon-revert")
button:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

button.DisabledTex = button:CreateTexture(nil, "ARTWORK")
button.DisabledTex:SetAllPoints(true)
button.DisabledTex:SetAtlas("transmog-icon-revert")
button.DisabledTex:SetDesaturated(true)
button.DisabledTex:SetVertexColor(.6,.6,.6)
button:SetDisabledTexture(button.DisabledTex)

button.PushedTex = button:CreateTexture(nil, "ARTWORK")
button.PushedTex:SetAllPoints(true)
button.PushedTex:SetAtlas("transmog-icon-revert")
button.PushedTex:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
button.PushedTex:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
button.PushedTex:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
button.PushedTex:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
button:SetPushedTexture(button.PushedTex)

button:SetMotionScriptsWhileDisabled(true)
button:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Clear & Reset all rows.", nil, nil, nil, nil, true)
		GameTooltip:AddLine("WARNING: You'll lose any data that hasn't been saved yet using 'Create'!",1,1,1,true)
		GameTooltip:Show()
	end)
end)
button:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)
-- OnClick moved below loadSpell()

-- Cast Spell Button
SCForgeMainFrame.ExecuteSpellButton = CreateFrame("BUTTON", nil, SCForgeMainFrame, "UIPanelButtonTemplate")
SCForgeMainFrame.ExecuteSpellButton:SetPoint("BOTTOM", 0, 3)
SCForgeMainFrame.ExecuteSpellButton:SetSize(24*4,24)
SCForgeMainFrame.ExecuteSpellButton:SetText(ACTION_SPELL_CAST_SUCCESS:gsub("^%l", string.upper))
SCForgeMainFrame.ExecuteSpellButton:SetMotionScriptsWhileDisabled(true)
SCForgeMainFrame.ExecuteSpellButton:SetScript("OnClick", function()
	setFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 3, nil, nil, 0.05, 0.3)
	local maxDelay = 0
	local actionsToCommit = {}
	for i = 1, numberOfSpellRows do
		if isNotDefined(tonumber(_G["spellRow"..i.."MainDelayBox"]:GetText())) then
			dprint("Action Row "..i.." Invalid, Delay Not Set")
		else
			local actionData = {}
			actionData.actionType = (_G["spellRow"..i].SelectedAction)
			actionData.delay = tonumber(_G["spellRow"..i.."MainDelayBox"]:GetText())
			if actionData.delay > maxDelay then maxDelay = actionData.delay end
			actionData.revertDelay = tonumber(_G["spellRow"..i.."RevertDelayBox"]:GetText())
			if actionData.revertDelay and actionData.revertDelay > maxDelay then maxDelay = actionData.revertDelay end
			actionData.selfOnly = _G["spellRow"..i.."SelfCheckbox"]:GetChecked()
			actionData.vars = _G["spellRow"..i.."InputEntryBox"]:GetText()
			ddump(actionData)
			table.insert(actionsToCommit, actionData)
		end
	end
	C_Timer.After(maxDelay, function() stopFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 0.02, 0.25) end)
	executeSpell(actionsToCommit)
end)
SCForgeMainFrame.ExecuteSpellButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Cast the above Actions.", nil, nil, nil, nil, true)
		if self:IsEnabled() then
			GameTooltip:AddLine("Useful to test your spell before saving.",1,1,1,true)
		else
			GameTooltip:AddLine("You cannot cast spells in main-phase Dranosh Valley.",1,1,1,true)
		end
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
		local _spellRow = _G["spellRow"..rowNum]
		if actionData.actionType == "reset" then
			UIDropDownMenu_SetSelectedID(_spellRow.actionSelectButton.Dropdown, 0)
			_spellRow.actionSelectButton.Dropdown.Text:SetText("Action")
			updateSpellRowOptions(rowNum)
		else
			for k,v in pairs(_spellRow.menuList) do
				v.checked = false
			end
			UIDropDownMenu_SetSelectedID(_spellRow.actionSelectButton.Dropdown, get_Table_Position(actionData.actionType, actionTypeDataList))
			_spellRow.actionSelectButton.Dropdown.Text:SetText(actionTypeData[actionData.actionType].name)
			updateSpellRowOptions(rowNum, actionData.actionType)
		end

		_spellRow.mainDelayBox:SetText(tonumber(actionData.delay) or "") --delay
		if actionData.selfOnly then _spellRow.SelfCheckbox:SetChecked(true) else _spellRow.SelfCheckbox:SetChecked(false) end --SelfOnly
		if actionData.vars then _spellRow.InputEntryBox:SetText(actionData.vars) else _spellRow.InputEntryBox:SetText("") end --Input Entrybox
		if actionData.revertDelay then
			_spellRow.RevertDelayBox:SetText(actionData.revertDelay) --revertDelay
		else
			_spellRow.RevertDelayBox:SetText("") --revertDelay
		end
	end
end

SCForgeMainFrame.ResetUIButton:SetScript("OnClick", function(self)
	-- load an empty spell to effectively reset the UI
	local emptySpell = {
		["fullName"] = "", ["commID"] = "", ["description"] = "",
		["actions"] = { { ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, }, { ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, }, { ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, }, },
	}
	loadSpell(emptySpell)
end)

local phaseVaultKeys
local SCForge_PhaseVaultSpells = {}

local function deleteSpellConf(spellKey, where)
	local dialog = StaticPopup_Show("SCFORGE_CONFIRM_DELETE", savedSpellFromVault[spellKey].fullName, savedSpellFromVault[spellKey].commID)
	if dialog then dialog.data = spellKey; dialog.data2 = where end
end

local function noSpellsToLoad(fake)
	dprint("Phase Has No Spells to load.");
	phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" );
	if not fake then
		if C_Epsilon.IsOfficer() then
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("Vault is Empty\n\rC'mon, add something fun!");
		else
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("Vault is Empty");
		end
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Enable();
	end
	isSavingOrLoadingPhaseAddonData = false;
end

local function getSpellForgePhaseVault(callback)
	SCForge_PhaseVaultSpells = {} -- reset the table
	dprint("Phase Spell Vault Loading...")

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
			dprint("Phase spell keys: ")
			ddump(phaseVaultKeys)
			local phaseVaultLoadingCount = 0
			local phaseVaultLoadingExpected = #phaseVaultKeys
			local messageTicketQueue = {}

			-- set up the phaseAddonDataListener2 ahead of time, and only once..
			phaseAddonDataListener2:RegisterEvent("CHAT_MSG_ADDON")
			phaseAddonDataListener2:SetScript("OnEvent", function (self, event, prefix, text, channel, sender, ...)
				if event == "CHAT_MSG_ADDON" and messageTicketQueue[prefix] and text then
					messageTicketQueue[prefix] = nil -- remove it from the queue.. We'll reset the table next time anyways but whatever.
					phaseVaultLoadingCount = phaseVaultLoadingCount+1
					interAction = serialDecompressForAddonMsg(text)
					dprint("Spell found & adding to Phase Vault Table: "..interAction.commID)
					tinsert(SCForge_PhaseVaultSpells, interAction)
					--print("phaseVaultLoadingCount: ",phaseVaultLoadingCount," | phaseVaultLoadingExpected: ",phaseVaultLoadingExpected)
					if phaseVaultLoadingCount == phaseVaultLoadingExpected then
						callback(true);
						phaseAddonDataListener2:UnregisterEvent("CHAT_MSG_ADDON")
						isSavingOrLoadingPhaseAddonData = false
					end
				end
			end)

			for k,v in ipairs(phaseVaultKeys) do
				--phaseVaultLoadingExpected = k
				dprint("Trying to load spell from phase: "..v)
				local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_S_"..v)
				messageTicketQueue[messageTicketID] = true -- add it to a fake queue table so we can watch for multiple prefixes...

			end
		end
	end)
end

local scforge_ChannelID -- this is set later by the server
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

local uploadAsPrivateSpell = false
local function saveSpellToPhaseVault(commID, overwrite)
	local needToOverwrite = false
	if not commID then
		eprint("Invalid CommID.")
		return;
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

				dprint("Phase spell keys: ")
				ddump(phaseVaultKeys)

				for k,v in ipairs(phaseVaultKeys) do
					if v == commID then
						if not overwrite then
							-- phase already has this ID saved.. Handle over-write... ( see saveSpell() to steal the code if we want to change it later.. )
							dprint("Phase already has a spell saved by Command '"..commID.."'. Prompting to confirm over-write.")

							StaticPopupDialogs["SCFORGE_CONFIRM_POVERWRITE"] = {
								text = "Spell '"..commID.."' Already exists in the Phase Vault.\n\rDo you want to overwrite the spell?",
								OnAccept = function() saveSpellToPhaseVault(commID, true) end,
								button1 = "Overwrite",
								button2 = CANCEL,
								hideOnEscape = true,
								whileDead = true,
							}
							StaticPopup_Show("SCFORGE_CONFIRM_POVERWRITE")

							isSavingOrLoadingPhaseAddonData = false
							sendPhaseVaultIOLock(false)
							return;
						else
							needToOverwrite = true
						end
					end
				end

				-- Passed checking for duplicates. NOW we can save it.
				local _spellData = SpellCreatorSavedSpells[commID]
				if uploadAsPrivateSpell then _spellData.private = true else _spellData.private = nil end
				local str = serialCompressForAddonMsg(_spellData)

				local key = "SCFORGE_S_"..commID
				C_Epsilon.SetPhaseAddonData(key, str)

				if not needToOverwrite then
					tinsert(phaseVaultKeys, commID)
					phaseVaultKeys = serialCompressForAddonMsg(phaseVaultKeys)
					C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", phaseVaultKeys)
				end

				cprint("Spell '"..commID.."' saved to the Phase Vault.")
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
		SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:Enable()
	else
		selectedVaultRow = nil
		SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Disable()
		SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:Disable()
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

local gossipAddMenuInsert = CreateFrame("FRAME")
gossipAddMenuInsert:SetSize(110,26)
gossipAddMenuInsert:Hide()
gossipAddMenuInsert.hideButton = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
gossipAddMenuInsert.hideButton:SetSize(26,26)
gossipAddMenuInsert.hideButton:SetPoint("BOTTOMLEFT", 0, -7)
gossipAddMenuInsert.hideButton.text:SetText("Hide after Casting")
gossipAddMenuInsert.hideButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Hide the Gossip menu after Casting.", nil, nil, nil, nil, true)
		GameTooltip:AddLine("\nShould the gossip be hidden after casting? If you enable this and select Cast on Show (Auto), the frame will closed immediately before they see it.",1,1,1,true)
		GameTooltip:Show()
	end)
end)
gossipAddMenuInsert.hideButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)
gossipAddMenuInsert.hideButton:SetScript("OnHide", function(self)
	self:SetChecked(false)
end)
--[[
gossipAddMenuInsert.hideButton:SetScript("OnClick", function(self)
	local parent = self:GetParent():GetParent()
	if parent.editBox then
		if self:GetChecked() then
			parent.editBox:Hide()
			local height = parent:GetHeight() - parent.editBox:GetHeight()
			parent:SetHeight(height)
		else
			parent.editBox:Show()
			local height = parent:GetHeight() + parent.editBox:GetHeight()
			parent:SetHeight(height)
		end
	end
end)
--]]

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
		SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:Hide()
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
		SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:Show()
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
	local realRowNum = 0
	local numSkippedRows = 0
	local columnWidth = spellLoadFrame:GetWidth()
	local thisRow

	for k,v in orderedPairs(savedSpellFromVault) do
	-- this will get an alphabetically sorted list of all spells, and their data. k = the key (commID), v = the spell's data table
		--[[
		realRowNum = realRowNum+1
		rowNum = realRowNum-numSkippedRows
		--]]
		rowNum = rowNum+1

		if spellLoadRows[rowNum] then
			thisRow = spellLoadRows[rowNum]
			thisRow:Show()
			dprint(false,"SCForge Load Row "..rowNum.." Already existed - showing & setting it")

			-- Position the Rows
			if rowNum == 1 or rowNum-1-numSkippedRows < 1 then
				thisRow:SetPoint("TOPLEFT", spellLoadFrame, "TOPLEFT", 8, -8)
			else
				thisRow:SetPoint("TOPLEFT", spellLoadRows[rowNum-1-numSkippedRows], "BOTTOMLEFT", 0, -loadRowSpacing)
			end

		else
			dprint(false,"SCForge Load Row "..rowNum.." Didn't exist - making it!")
			spellLoadRows[rowNum] = CreateFrame("CheckButton", "scForgeLoadRow"..rowNum, spellLoadFrame)
			thisRow = spellLoadRows[rowNum]

			-- Position the Rows
			if rowNum == 1 or rowNum-1-numSkippedRows < 1 then
				thisRow:SetPoint("TOPLEFT", spellLoadFrame, "TOPLEFT", 8, -8)
			else
				thisRow:SetPoint("TOPLEFT", spellLoadRows[rowNum-1-numSkippedRows], "BOTTOMLEFT", 0, -loadRowSpacing)
			end
			thisRow:SetWidth(columnWidth-20)
			thisRow:SetHeight(loadRowHeight)

			-- A nice lil background to make them easier to tell apart			
			thisRow.Background = thisRow:CreateTexture(nil,"BACKGROUND",nil,5)
			thisRow.Background:SetPoint("TOPLEFT",-3,0)
			thisRow.Background:SetPoint("BOTTOMRIGHT",0,0)
			thisRow.Background:SetTexture(load_row_background)
			thisRow.Background:SetTexCoord(0.0625,1-0.066,0.125,1-0.15)

			--[[
			thisRow.BGOverlay = thisRow:CreateTexture(nil,"BACKGROUND",nil,6)
			thisRow.BGOverlay:SetAllPoints(thisRow.Background)
			thisRow.BGOverlay:SetAtlas("Garr_FollowerToast-Rare")
			thisRow.BGOverlay:SetAlpha(0.25)
			--]]

			thisRow:SetCheckedTexture("Interface\\AddOns\\SpellCreator\\assets\\l_row_selected")
			thisRow.CheckedTexture = thisRow:GetCheckedTexture()
			thisRow.CheckedTexture:SetAllPoints(thisRow.Background)
			thisRow.CheckedTexture:SetTexCoord(0.0625,1-0.066,0.125,1-0.15)
			thisRow.CheckedTexture:SetAlpha(0.75)
			--thisRow.CheckedTexture:SetPoint("RIGHT", thisRow.Background, "RIGHT", 5, 0)

			-- Original Atlas based texture with vertex shading for a unique look. Actually looked pretty good imo.
			--thisRow.Background:SetAtlas("TalkingHeads-Neutral-TextBackground")
			--thisRow.Background:SetVertexColor(0.75,0.70,0.8) -- Let T color it naturally :)
			--thisRow.Background:SetVertexColor(0.73,0.63,0.8)

			--[[ -- Disabled, not needed on the new load row backgrounds
			thisRow.spellNameBackground = thisRow:CreateTexture(nil, "BACKGROUND")
			thisRow.spellNameBackground:SetPoint("TOPLEFT", thisRow.Background, "TOPLEFT", 5, -2)
			thisRow.spellNameBackground:SetPoint("BOTTOMRIGHT", thisRow.Background, "BOTTOM", 10, 2) -- default position - move it later with the actual name font string.

			thisRow.spellNameBackground:SetColorTexture(1,1,1,0.25)
			thisRow.spellNameBackground:SetGradient("HORIZONTAL", 0.5,0.5,0.5,1,1,1)
			thisRow.spellNameBackground:SetBlendMode("MOD")
			--]]


			-- Make the Spell Name Text
			thisRow.spellName = thisRow:CreateFontString(nil,"OVERLAY", "GameFontNormalMed2")
			thisRow.spellName:SetWidth(columnWidth*2/3)
			thisRow.spellName:SetJustifyH("LEFT")
			thisRow.spellName:SetPoint("LEFT", 10, 0)
			thisRow.spellName:SetText(v.fullName) -- initial text, reset later when it needs updated
			thisRow.spellName:SetShadowColor(0, 0, 0)
			thisRow.spellName:SetMaxLines(3) -- hardlimit to 3 lines, but soft limit to 2 later.
--			thisRow.spellNameBackground:SetPoint("RIGHT", thisRow.spellName, "RIGHT", 0, 0) -- move the right edge of the gradient to the right edge of the name

			-- Make the delete saved spell button
			thisRow.deleteButton = CreateFrame("BUTTON", nil, thisRow)
			local button = thisRow.deleteButton
			button.commID = k
			button:SetPoint("RIGHT", 0, 0)
			button:SetSize(24,24)
			--button:SetText("x")

			button:SetNormalTexture(addonPath.."/assets/icon-x")
			button:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

			button.DisabledTex = button:CreateTexture(nil, "ARTWORK")
			button.DisabledTex:SetAllPoints(true)
			button.DisabledTex:SetTexture(addonPath.."/assets/icon-x")
			button.DisabledTex:SetDesaturated(true)
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
			thisRow.loadButton = CreateFrame("BUTTON", nil, thisRow)
			local button = thisRow.loadButton
			button.commID = k
			button:SetPoint("RIGHT", thisRow.deleteButton, "LEFT", 0, 0)
			button:SetSize(24,24)
			--button:SetText(EDIT)

			button:SetNormalTexture(addonPath.."/assets/icon-edit")
			button:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

			button.DisabledTex = button:CreateTexture(nil, "ARTWORK")
			button.DisabledTex:SetAllPoints(true)
			button.DisabledTex:SetTexture(addonPath.."/assets/icon-edit")
			button.DisabledTex:SetDesaturated(true)
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
					GameTooltip:AddLine("\nRight-click to load the ArcSpell, and re-sort it's actions into chronological order by delay.", 1,1,1,1)
					GameTooltip:Show()
				end)
			end)
			button:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
			end)

			--

			thisRow.gossipButton = CreateFrame("BUTTON", nil, thisRow)
			local button = thisRow.gossipButton
			button.commID = k
			button:SetPoint("TOP", thisRow.deleteButton, "BOTTOM", 0, 0)
			button:SetSize(16,16)

			button:SetNormalAtlas("groupfinder-waitdot")
			button.normal = button:GetNormalTexture()
			button.normal:SetVertexColor(1,0.8,0)
			button:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

			button.speechIcon = button:CreateTexture(nil, "ARTWORK", nil, 7)
			button.speechIcon:SetTexture("interface/gossipframe/chatbubblegossipicon")
			button.speechIcon:SetSize(10,10)
			button.speechIcon:SetTexCoord(1,0,0,1)
			button.speechIcon:SetPoint("CENTER", button, "TOPRIGHT",-2,-1)

			button.DisabledTex = button:CreateTexture(nil, "ARTWORK")
			button.DisabledTex:SetAllPoints(true)
			button.DisabledTex:SetAtlas("groupfinder-waitdot")
			button.DisabledTex:SetDesaturated(true)
			button.DisabledTex:SetVertexColor(.6,.6,.6)
			button:SetDisabledTexture(button.DisabledTex)

			button.PushedTex = button:CreateTexture(nil, "ARTWORK")
			button.PushedTex:SetAllPoints(true)
			button.PushedTex:SetAtlas("groupfinder-waitdot")
			button.PushedTex:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
			button.PushedTex:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
			button.PushedTex:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
			button.PushedTex:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
			button:SetPushedTexture(button.PushedTex)

			button:SetMotionScriptsWhileDisabled(true)
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetScript("OnClick", function(self, button)
				StaticPopupDialogs["SCFORGE_ADD_GOSSIP"] = {
					text = "Add ArcSpell Gossip Option",
					subText = "ArcSpell: '"..savedSpellFromVault[self.commID].fullName.."' ("..savedSpellFromVault[self.commID].commID..")",
					closeButton = true,
					hasEditBox = true,
					enterClicksFirstButton = true,
					editBoxInstructions = "Gossip Option Label Text (i.e., 'Cast the Spell!')",
					editBoxWidth = 350,
					maxLetters = 255-25-20-#savedSpellFromVault[self.commID].commID, -- 255 minus 25 for the max <arcanum> tag size, minus '.ph fo np go op ad ' size, minus spellCommID size.
					OnButton1 = function(self, data)
						local text = self.editBox:GetText();
						if self.insertedFrame.button:GetChecked() then cmd("ph fo np go op ad "..text.."<arcanum_cast_hide:"..savedSpellFromVault[data].commID..">") else cmd("ph fo np go op ad "..text.."<arcanum_cast:"..savedSpellFromVault[data].commID..">") end
					end,
					OnButton2 = function(self, data)
						local text = self.editBox:GetText();
						if self.insertedFrame.button:GetChecked() then cmd("ph fo np go op ad "..text.."<arcanum_cast_auto_hide:"..savedSpellFromVault[data].commID..">") else cmd("ph fo np go op ad "..text.."<arcanum_cast_auto:"..savedSpellFromVault[data].commID..">") end
					end,
					OnButton3 = function(self, data)
						local text = self.editBox:GetText();
						if self.insertedFrame.button:GetChecked() then cmd("ph fo np go te ad "..text.."<arcanum_cast_auto_hide:"..savedSpellFromVault[data].commID..">") else cmd("ph fo np go te ad "..text.."<arcanum_cast_auto:"..savedSpellFromVault[data].commID..">") end
					end,
					button1 = "Option - Click",
					button2 = "Option - Auto",
					button3 = "Main Text - Auto",
					extraButton = CANCEL,
					hideOnEscape = true,
					whileDead = true,
				}
				local dialog = StaticPopup_Show("SCFORGE_ADD_GOSSIP", nil, nil, nil, gossipAddMenuInsert)
				dialog.data = self.commID
			end)

			button:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				self.Timer = C_Timer.NewTimer(0.7,function()
					GameTooltip:SetText("Add to Gossip Menu", nil, nil, nil, nil, true)
					GameTooltip:AddLine("\nWith a gossip menu open, click here to add this ArcSpell to an NPC's gossip.", 1,1,1,1)
					GameTooltip:Show()
				end)
			end)
			button:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
			end)
			button:SetScript("OnDisable", function(self)
				self.speechIcon:SetDesaturated(true)
				self.speechIcon:SetVertexColor(.6,.6,.6)
			end)
			button:SetScript("OnEnable", function(self)
				self.speechIcon:SetDesaturated(false)
				self.speechIcon:SetVertexColor(1,1,1)
			end)


			-------------
			thisRow.privateIconButton = CreateFrame("BUTTON", nil, thisRow)
			local button = thisRow.privateIconButton
			button.commID = k
			button:SetSize(16,16)
			button:SetPoint("RIGHT", thisRow.gossipButton, "LEFT", -8, 0)

			--button:SetNormalAtlas("UI_Editor_Eye_Icon")
			button:SetNormalTexture(addonPath.."/assets/icon_visible_32")
			button.normal = button:GetNormalTexture()
			button.normal:SetVertexColor(0.9,0.65,0)
			--button:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

			button.DisabledTex = button:CreateTexture(nil, "ARTWORK")
			button.DisabledTex:SetAllPoints(true)
			--button.DisabledTex:SetAtlas("transmog-icon-hidden")
			button.DisabledTex:SetTexture(addonPath.."/assets/icon_hidden_32")
			--button.DisabledTex:SetDesaturated(true)
			button.DisabledTex:SetVertexColor(.6,.6,.6)
			button:SetDisabledTexture(button.DisabledTex)

			button:SetMotionScriptsWhileDisabled(true)

			button:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				self.Timer = C_Timer.NewTimer(0.7,function()
					if self:IsEnabled() then
						GameTooltip:SetText("'"..savedSpellFromVault[self.commID].fullName.."' is visible to everyone.", nil, nil, nil, nil, true)
					else
						GameTooltip:SetText("'"..savedSpellFromVault[self.commID].fullName.."' is visible only to Officers+.", nil, nil, nil, nil, true)
					end
					GameTooltip:AddLine("\nTo change this spells privacy, please re-upload it with the privacy desired.", 1,1,1,1)
					GameTooltip:Show()
				end)
			end)
			button:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
			end)
			----------

			--

			--[[
			-- Transfer to Phase Button
			thisRow.saveToPhaseButton = CreateFrame("BUTTON", nil, thisRow, "UIPanelButtonTemplate")
			local button = thisRow.saveToPhaseButton
			button.commID = k
			button:SetPoint("RIGHT", thisRow.loadButton, "LEFT", 0, 0)
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
			thisRow.spellName:SetText(v.fullName)
			thisRow.loadButton.commID = k
			thisRow.deleteButton.commID = k
			thisRow.gossipButton.commID = k
			thisRow.privateIconButton.commID = k
			thisRow.commID = k -- used in new Transfer to Phase Button
			thisRow.rowID = rowNum

			thisRow.deleteButton:SetScript("OnClick", function(self, button)
				if button == "LeftButton" then
					deleteSpellConf(self.commID, currentVault)
				elseif button == "RightButton" then

				end
			end)

			-- NEED TO UPDATE THE ROWS IF WE ARE IN PHASE VAULT
			if currentVault == "PERSONAL" then
				--thisRow.loadButton:SetText(EDIT)
				--thisRow.saveToPhaseButton.commID = k
				--thisRow.Background:SetVertexColor(0.75,0.70,0.8)
				--thisRow.Background:SetTexCoord(0,1,0,1)
				thisRow.deleteButton:Show()
				thisRow.deleteButton:ClearAllPoints()
				thisRow.deleteButton:SetPoint("RIGHT")
				thisRow.loadButton:ClearAllPoints()
				thisRow.loadButton:SetPoint("RIGHT", thisRow.deleteButton, "LEFT", 0, 0)
				thisRow.gossipButton:Hide()
				thisRow.privateIconButton:Hide()
				--thisRow.BGOverlay:SetAtlas("Garr_FollowerToast-Rare")

				--[[	-- Replaced with the <-> Phase Vault button
				if C_Epsilon.IsMember() or C_Epsilon.IsOfficer() or C_Epsilon.IsOwner() then
					thisRow.saveToPhaseButton:Show()
				else
					thisRow.saveToPhaseButton:Hide()
				end
				--]]

			elseif currentVault == "PHASE" then
				--thisRow.loadButton:SetText("Load")
				--thisRow.saveToPhaseButton:Hide()
				--thisRow.Background:SetVertexColor(0.73,0.63,0.8)
				--thisRow.Background:SetTexCoord(0,1,0,1)
				--thisRow.BGOverlay:SetAtlas("Garr_FollowerToast-Epic")

				if C_Epsilon.IsMember() or C_Epsilon.IsOfficer() or C_Epsilon.IsOwner() then
					thisRow.deleteButton:Show()
					thisRow.deleteButton:ClearAllPoints()
					thisRow.deleteButton:SetPoint("TOPRIGHT")
					thisRow.loadButton:ClearAllPoints()
					thisRow.loadButton:SetPoint("RIGHT", thisRow.deleteButton, "LEFT", 0, 0)
					thisRow.gossipButton:Show()
					thisRow.privateIconButton:Show()
					if isGossipLoaded then
						thisRow.gossipButton:Enable()
					else
						thisRow.gossipButton:Disable()
					end
				else
					thisRow.deleteButton:Hide()
					thisRow.deleteButton:ClearAllPoints()
					thisRow.deleteButton:SetPoint("RIGHT")
					thisRow.loadButton:ClearAllPoints()
					thisRow.loadButton:SetPoint("CENTER", thisRow.deleteButton, "CENTER", 0, 0)
					thisRow.gossipButton:Hide()
					thisRow.privateIconButton:Hide()
				end
			end

			-- Update the main row frame for mouse over - this allows us to hover & shift-click for links
			thisRow:SetScript("OnEnter", function(self)
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
			thisRow:SetScript("OnLeave", function(self)
				GameTooltip_Hide()
				self.Timer:Cancel()
			end)
			thisRow:SetScript("OnClick", function(self)
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
			thisRow:SetScript("OnMouseDown", function(self)
				if IsModifiedClick("CHATLINK") then
					ChatEdit_InsertLink(generateSpellChatLink(k, currentVault))
				end
			end)
			--]]
		end

		-- Limit our Spell Name to 2 lines - but by downsizing the text instead of truncating..
		do
			local fontName,fontHeight,fontFlags = thisRow.spellName:GetFont()
			thisRow.spellName:SetFont(fontName, 14, fontFlags) -- reset the font to default first, then test if we need to scale it down.
			while thisRow.spellName:GetNumLines() > 2 do
				fontName,fontHeight,fontFlags = thisRow.spellName:GetFont()
				thisRow.spellName:SetFont(fontName, fontHeight-1, fontFlags)
				if fontHeight-1 <= 8 then break; end
			end
		end

		if currentVault=="PHASE" and v.private and not (C_Epsilon.IsOfficer() or C_Epsilon.IsOwner() or SpellCreatorMasterTable.Options["debug"]) then
			thisRow:Hide()
			numSkippedRows = numSkippedRows+1
		end
		if v.private then
			thisRow.privateIconButton:Disable()
		else
			thisRow.privateIconButton:Enable()
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

local function saveSpell(mousebutton, fromPhaseVault)

	local wasOverwritten = false
	local newSpellData = {}
	if fromPhaseVault then
		newSpellData.commID = SCForge_PhaseVaultSpells[fromPhaseVault].commID
		newSpellData.fullName = SCForge_PhaseVaultSpells[fromPhaseVault].fullName
		newSpellData.description = SCForge_PhaseVaultSpells[fromPhaseVault].description or nil
		newSpellData.actions = SCForge_PhaseVaultSpells[fromPhaseVault].actions
		dprint("Saving Spell from Phase Vault, fake commID: "..fromPhaseVault..", real commID: "..newSpellData.commID)
	else
		newSpellData.commID = SCForgeMainFrame.SpellInfoCommandBox:GetText()
		newSpellData.fullName = SCForgeMainFrame.SpellInfoNameBox:GetText()
		newSpellData.description = SCForgeMainFrame.SpellInfoDescBox:GetText()
		newSpellData.actions = {}
	end
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
					OnAccept = function() saveSpell("RightButton", (fromPhaseVault and fromPhaseVault or nil)) end,
					button1 = "Overwrite",
					button2 = "Cancel",
					hideOnEscape = true,
					whileDead = true,
				}
				StaticPopup_Show("SCFORGE_CONFIRM_OVERWRITE")
				return;
			end
		end

	if not fromPhaseVault then
		for i = 1, numberOfSpellRows do

			local actionData = {}
			actionData.delay = tonumber(_G["spellRow"..i.."MainDelayBox"]:GetText())
			if actionData.delay and actionData.delay >= 0 then
				actionData.actionType = (_G["spellRow"..i].SelectedAction)
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
	if not fromPhaseVault then
		updateSpellLoadRows()
	end
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
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetText("    Phase Vault")
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetMotionScriptsWhileDisabled(true)

SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton.icon = SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:CreateTexture(nil, "ARTWORK")
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton.icon:SetTexture(addonPath.."/assets/icon-transfer")
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton.icon:SetTexCoord(0,1,1,0)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton.icon:SetPoint("TOPLEFT", 5, 0)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton.icon:SetSize(24,24)


SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnClick", function(self, button)
	if selectedVaultRow then
		local commID = spellLoadRows[selectedVaultRow].commID
		saveSpellToPhaseVault(commID, IsShiftKeyDown())
	end
end)

SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnDisable", function(self)
	self.icon:SetDesaturated(true)
end)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnEnable", function(self)
	self.icon:SetDesaturated(false)
end)

SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Transfer to Phase Vault.", nil, nil, nil, nil, true)
		if self:IsEnabled() then
			GameTooltip:AddLine("Transfer the spell to the Phase Vault.\n\rShift-Click to automatically over-write any spell with the same command ID in the Phase Vault.",1,1,1,true)
		else
			if selectedVaultRow then
				GameTooltip:AddLine("You do not currently have permissions to upload to this phase's vault.\n\rIf you were just given officer, rejoin the phase.",1,1,1,true)
			else
				GameTooltip:AddLine("Select a spell above to transfer it.",1,1,1,true)
			end
		end
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)

------------
SCForgeMainFrame.LoadSpellFrame.PrivateUploadToggle = CreateFrame("CHECKBUTTON", nil, SCForgeMainFrame.LoadSpellFrame)
local _frame = SCForgeMainFrame.LoadSpellFrame.PrivateUploadToggle
_frame:SetPoint("LEFT", SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton, "RIGHT", 6, 0)
_frame:SetSize(20,20)
--_frame.text:SetText("Private")

_frame:SetNormalTexture(addonPath.."/assets/icon_visible_32")
_frame.NormalTexture = _frame:GetNormalTexture()
_frame.NormalTexture:SetVertexColor(0.9,0.65,0)

_frame:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight", "ADD")

_frame:SetCheckedTexture(addonPath.."/assets/icon_hidden_32")
_frame.CheckedTexture = _frame:GetCheckedTexture()
_frame.CheckedTexture:SetBlendMode("BLEND")
_frame.CheckedTexture:SetVertexColor(0.6,0.6,0.6)

_frame.updateTooltip = function(self)
	if self:GetChecked() then
		GameTooltip:SetText("Uploading as: Private Spell", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Click to switch to Public Visibility",1,1,1,true)
	else
		GameTooltip:SetText("Uploading as: Public Spell", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Click to switch to Private Visibility",1,1,1,true)
	end
	GameTooltip:AddLine("\nWhen uploaded as a private spell, only Officers+ will be able to see it in the Phase Vault - however, it can still be used by anyone (i.e., via Gossip integration).\n\rThe main use of this is to reduce clutter for normal players if you have specific ArcSpells for background use, like an NPC Gossip.",1,1,1,true)
	GameTooltip:Show()
end

_frame:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		self:updateTooltip()
	end)
end)
_frame:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)
_frame:SetScript("OnClick", function(self)
	uploadAsPrivateSpell = not uploadAsPrivateSpell
	self:updateTooltip()
	if self:GetChecked() then
		self:SetNormalTexture("")
	else
		self:SetNormalTexture(addonPath.."/assets/icon_visible_32")
	end
end)

----------
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnShow", function(self)
	if not selectedVaultRow then self:Disable(); end
	SCForgeMainFrame.LoadSpellFrame.PrivateUploadToggle:Show()
end)
SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:SetScript("OnHide", function(self)
	SCForgeMainFrame.LoadSpellFrame.PrivateUploadToggle:Hide()
end)

------------

SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton = CreateFrame("BUTTON", nil, SCForgeMainFrame.LoadSpellFrame, "UIPanelButtonNoTooltipTemplate")
SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:SetPoint("BOTTOM", 0, 3)
SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:SetSize(24*5.5,24)
SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:SetText("     Personal Vault")
SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:SetMotionScriptsWhileDisabled(true)

SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton.icon = SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:CreateTexture(nil, "ARTWORK")
SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton.icon:SetTexture(addonPath.."/assets/icon-transfer")
SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton.icon:SetTexCoord(0,1,1,0)
SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton.icon:SetPoint("TOPLEFT", 5, 0)
SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton.icon:SetSize(24,24)


SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:SetScript("OnClick", function(self)
	if selectedVaultRow then
		local commID = spellLoadRows[selectedVaultRow].commID
		ddump(SCForge_PhaseVaultSpells[commID]) -- Dump the table of the phase vault spell for debug
		saveSpell(nil, commID)
	end
end)

SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:SetScript("OnDisable", function(self)
	self.icon:SetDesaturated(true)
end)
SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:SetScript("OnEnable", function(self)
	self.icon:SetDesaturated(false)
end)

SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Transfer to Personal Vault.", nil, nil, nil, nil, true)
		if self:IsEnabled() then
			GameTooltip:AddLine("Transfer the spell to your Personal Vault.",1,1,1,true)
		else
			if selectedVaultRow then
				GameTooltip:AddLine("Idk how you are seeing this text but report it as a bug lol..",1,1,1,true)
			else
				GameTooltip:AddLine("Select a spell above to transfer it.",1,1,1,true)
			end
		end
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)
SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:SetScript("OnShow", function(self)
	if not selectedVaultRow then self:Disable(); end
end)

---------


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
		local spellComm, charOrPhase, spellName, numActions, spellDesc = strsplit(":", linkData)
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
	local scriptFrame = parentIfNeeded or frame
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

minimapButton.Model = CreateFrame("PLAYERMODEL", nil, minimapButton, "MouseDisabledModelTemplate")
minimapButton.Model:SetAllPoints()
minimapButton.Model:SetFrameStrata("MEDIUM")
minimapButton.Model:SetFrameLevel(minimapButton:GetFrameLevel())
minimapButton.Model:SetModelDrawLayer("BORDER")
minimapButton.Model:SetKeepModelOnHide(true)
modelFrameSetModel(minimapButton.Model, 2, minimapModels)
modelFrameSetModel(minimapButton.Model, fastrandom(#minimapModels), minimapModels)

--SpellCreatorMinimapButton.Model
--SpellCreatorMinimapButton.Model:SetCamDistanceScale()

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
		modelFrameSetModel(minimapButton.Model, fastrandom(#minimapModels), minimapModels)
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
	GameTooltip:AddLine("/sf - Shortcut Command!",1,1,1,true)
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

	--[[
	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.showVaultToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -5,},
		["title"] = "Clear Action Data when Removing Row",
		["tooltipTitle"] = "Clear Action Data when Removing Row",
		["tooltipText"] = "When an Action Row is removed using the |cffFFAAAA—|r button, the data is wiped. If off, you can use the |cff00AAFF+|r button and the data will still be there again.",
		["optionKey"] = "clearRowOnRemove",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.clearRowOnRemoveToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)
	--]]

	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.showVaultToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -5,},
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



--- Gossip Helper Functions & Tables

local spellsToCast = {} -- outside the for loops so we don't reset it every loop iteration
local shouldAutoHide = false
local shouldLoadSpellVault = false
local useImmersion = false
local gossipOptionPayload
local gossipGreetPayload

local gossipScript = {
	show = function(doHide)
		
	end


}
local gossipTags = {
	default = "<arcanum_.->",
	capture = "<arcanum_(.-)>",
	dm = "<arcanum::DM_",
	body = {
		cast = {tag = "cast", script = function() 
			
		end},
		show = {tag = "show", script = function() 
			if C_Epsilon.IsDM and (C_Epsilon.IsOfficer() or C_Epsilon.IsOwner()) then
				scforge_showhide("enableMMIcon");
			else
				CloseGossip();
				scforge_showhide("enableMMIcon");
			end
		end},
		autosave = {tag = "autosave", script = function() 
		
		end},
	},
	option = {
		show = {tag = "show", script = function() end},
		toggle = {tag = "toggle", script = function() end},
		cast = {tag = "cast", script = function() end},
		save = {tag = "save", script = function() end},
		cmd = {tag = "cmd", script = function() end},
	},
	extensions = {
		{ ext = "hide", script = function() end},
		{ ext = "auto", script = function() end},
	}
}

local function updateGossipVaultButtons(enable)
	local spellLoadRows = SCForgeMainFrame.LoadSpellFrame.Rows
	for i = 1, #spellLoadRows do
		spellLoadRows[i].gossipButton:SetEnabled(enable)
	end
end

local SC_Addon_Listener = CreateFrame("frame");
SC_Addon_Listener:RegisterEvent("ADDON_LOADED");
SC_Addon_Listener:RegisterEvent("SCENARIO_UPDATE")
SC_Addon_Listener:RegisterEvent("UI_ERROR_MESSAGE");
SC_Addon_Listener:RegisterEvent("GOSSIP_SHOW");
SC_Addon_Listener:RegisterEvent("GOSSIP_CLOSED");

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

		if tonumber(C_Epsilon.GetPhaseId()) == 169 and GetRealZoneText() == "Dranosh Valley" and not C_Epsilon.IsOfficer() then
			SCForgeMainFrame.ExecuteSpellButton:Disable()
		else
			SCForgeMainFrame.ExecuteSpellButton:Enable()
		end

	-- Phase DM Toggle Listener
	elseif event == "UI_ERROR_MESSAGE" then
		local errType, msg = name, ...
		if msg=="DM mode is ON" then C_Epsilon.IsDM = true; dprint("DM Mode On");
			elseif msg=="DM mode is OFF" then C_Epsilon.IsDM = false; dprint("DM Mode Off");
		end

	-- Gossip Menu Listener
	elseif event == "GOSSIP_SHOW" then

		spellsToCast = {} -- outside the for loops so we don't reset it every loop iteration
		shouldAutoHide = false
		shouldLoadSpellVault = false
		useImmersion = false
		gossipOptionPayload = nil
		gossipGreetPayload = nil

		-- add GossipGreetingText support
		local gossipGreetingText = GossipGreetingText:GetText()
		if ImmersionFrame and ImmersionFrame.TalkBox and ImmersionFrame.TalkBox.TextFrame then gossipGreetingText = ImmersionFrame.TalkBox.TextFrame.Text.storedText; useImmersion = true; dprint("Immersion detected, using it"); end

		while gossipGreetingText and gossipGreetingText:match(gossipTags.default) do -- while gossipGreetingText has an arcTag
			gossipGreetPayload = gossipGreetingText:match(gossipTags.capture) -- capture the tag
			local strTag, strArg = strsplit(":", gossipGreetPayload) -- split the tag from the data
			local mainTag, extTags = strsplit("_", strTag, 2) -- split the main tag from the extension tags

			if gossipTags.body[mainTag] then
				gossipTags.body[mainTag].script()
			end
			--[[ -- loop processor - replace with table processor for main tags, loop only for 
			for k,v in ipairs(gossipTags.body) do
				if mainTag:match(v.tag) then v.script() end
			end
			--]]

			--[[
			for k,v in ipairs(gossipTags.extensions) do
				if extTags:match(v.tag) then v.script() end
			end
			table.insert(spellsToCast, strArg)
			--]]
			if C_Epsilon.IsDM and (C_Epsilon.IsOfficer() or C_Epsilon.IsOwner()) then 
				if useImmersion then
					ImmersionFrame.TalkBox.TextFrame.Text.storedText = gossipGreetingText:gsub(gossipTags.default, "")
					ImmersionFrame.TalkBox.TextFrame.Text:SetText(ImmersionFrame.TalkBox.TextFrame.Text:GetText():gsub(gossipTags.default, gossipTags.dm..gossipGreetPayload..">"))
					gossipGreetingText = ImmersionFrame.TalkBox.TextFrame.Text:GetText()
				else
					GossipGreetingText:SetText(gossipGreetingText:gsub(gossipTags.default, gossipTags.dm..gossipGreetPayload..">"))
					gossipGreetingText = GossipGreetingText:GetText()
				end
			else
				if useImmersion then
					ImmersionFrame.TalkBox.TextFrame.Text.storedText = gossipGreetingText:gsub(gossipTags.default, "")
					ImmersionFrame.TalkBox.TextFrame.Text:SetText(ImmersionFrame.TalkBox.TextFrame.Text:GetText():gsub(gossipTags.default, ""))
					gossipGreetingText = ImmersionFrame.TalkBox.TextFrame.Text:GetText()
				else
					GossipGreetingText:SetText(gossipGreetingText:gsub(gossipTags.default, ""))
					gossipGreetingText = GossipGreetingText:GetText()
				end
			end

			dprint("Saw a gossip greeting | Tag: "..mainTag.." | Spell: "..(strArg or "none").." | Ext: "..(tostring(extTags) or "none"))
		end

		for i = 1, GetNumGossipOptions() do
			--[[	-- Replaced with a memory of modifiedGossips that we reset when gossip is closed instead.
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

--			if titleButtonText:match("<arcanum_") then titleButton:SetScript("OnClick", function() end) end
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
			elseif titleButtonText:match("<arcanum_save:.*>") then
				payLoad = titleButtonText:match("<arcanum_save:(.*)>")

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
								--titleButton:Hide()
							end
							titleButton:SetText(titleButtonText:gsub(patterns[n], ""));
							titleButtonText = titleButton:GetText()
						else
							titleButton:SetText(titleButtonText:gsub(patterns[n], patterns[n]:gsub("%(%.%*%)",payLoad.."::DM")));
							titleButtonText = titleButton:GetText()
						end

						titleButton:HookScript("OnClick", function()
							if isSavingOrLoadingPhaseAddonData then eprint("Phase Vault was still loading. Try again in a moment."); return; end
							local spellRanSuccessfully
							for k,v in pairs(SCForge_PhaseVaultSpells) do
								if v.commID == payLoad then
									executeSpell(SCForge_PhaseVaultSpells[k].actions, true);
									spellRanSuccessfully = true
								end
							end
							if not spellRanSuccessfully then cprint("No spell with command "..payLoad.." found in the Phase Vault. Please let a phase officer know.") end
							if shouldHide then CloseGossip(); end
						end)
						modifiedGossips[i] = titleButton

					end
				end
				if shouldAutoHide then CloseGossip(); end
			end

			GossipResize(titleButton)

		end

		if shouldLoadSpellVault and not isGossipLoaded then
			getSpellForgePhaseVault(function(ready)
				if next(spellsToCast) == nil then dprint("No Auto Cast Spells in Gossip"); return; end
				local spellRanSuccessfully
				for i,j in pairs(spellsToCast) do
					for k,v in pairs(SCForge_PhaseVaultSpells) do
						if v.commID == j then
							executeSpell(SCForge_PhaseVaultSpells[k].actions, true);
							spellRanSuccessfully = true
						end
					end
				end
				if not spellRanSuccessfully then cprint("No spell found in the Phase Vault. Please let a phase officer know.") end
				spellsToCast = {} -- empty the table.
			end)
		end

		isGossipLoaded = true
		updateGossipVaultButtons(true)

	elseif event == "GOSSIP_CLOSED" then

		for k,v in pairs(modifiedGossips) do
			v:SetScript("OnClick", function()
				SelectGossipOption(k)
			end)
			modifiedGossips[k] = nil
		end

		isGossipLoaded = false
		updateGossipVaultButtons(false)

	end

end);


-------------------------------------------------------------------------------
-- Pseudo Scripting/API Helpers
-------------------------------------------------------------------------------

ARC = {}
ARC.VAR = {}

-- SYNTAX: ARC:C("command here") - i.e., ARC:C("cheat fly")
function ARC:C(text)
	if text and text ~= "" then
		cmdWithDotCheck(text)
	else
		cprint('ARC:API SYNTAX - C - Sends a Command to the Server.')
		print(addonColor..'Function: |cffFFAAAAARC:C("command here")|r')
		print(addonColor..'Example: |cffFFAAAAARC:C("cheat fly")')
	end
end

-- SYNTAX: ARC:RUNP("commID") - i.e., ARC:RUNP("teleportEffectsSpell")
function ARC:RUNP(text)
	if text and text ~= "" then
		local spellRanSuccessfully
		if isSavingOrLoadingPhaseAddonData then eprint("Phase Vault was still loading. Try again in a moment."); return; end
		for k,v in pairs(SCForge_PhaseVaultSpells) do
			if v.commID == text then
				executeSpell(SCForge_PhaseVaultSpells[k].actions, true);
				spellRanSuccessfully = true
			end
		end
		if not spellRanSuccessfully then cprint("No spell with command "..text.." found in the Phase Vault (or vault was not loaded). Please let a phase officer know.") end
	else
		cprint('ARC:API SYNTAX - RUNP - Casts a Spell from the Phase Vault.')
		print(addonColor..'Function: |cffFFAAAAARC:RUNP("commID")|r')
		print(addonColor..'Example: |cffFFAAAAARC:RUNP("teleportEffectsSpell")')
		print(addonColor..'Silently Fails if there is no spell by that commID in the vault.')
	end
end

-- SYNTAX: ARC:IF(tag, Command if True, Command if False, [Variables for True], [Variables for False])
function ARC:IF(tag, command1, command2, var1, var2)
	if (tag and command1 and command2) and (tag ~= "" and command1 ~= "" and command2 ~= "") then
		if var1 == "" then var1 = nil end
		if var2 == "" then var2 = nil end
		command1 = command1..(var1 and " "..var1 or "")
		command2 = command2..(var2 and " "..var2 or var1 and " "..var1 or "")
		if ARC.VAR[tag] then cmdWithDotCheck(command1) else cmdWithDotCheck(command2) end
	else
		cprint('ARC:API SYNTAX - IF - Checks if "tag" is true, and runs CommandTrue if so, or CommandFalse if not. Optionally you can define a "Var1" to append to both commands.')
		print(addonColor..'Function: |cffFFAAAAARC:IF("tag", "CommandTrue", "CommandFalse", "Var1")|r')
		print(addonColor..'Example 1: |cffFFAAAAARC:IF("ToggleLight","aura 243893", "unau 243893")|r')
		print(addonColor..'Example 2: |cffFFAAAAARC:IF("ToggleLight","aura", "unau", "243893")|r')
		print(addonColor.."Both of these will result in the same outcome - If ToggleLight is true, then apply the aura, else unaura.|r")
	end
end

function ARC:TOG(tag)
	if tag and tag ~= "" then
		if ARC.VAR[tag] then ARC.VAR[tag] = false else ARC.VAR[tag] = true end
		dprint(tostring(ARC.VAR[tag]))
	else
		cprint('ARC:API SYNTAX - TOG - Toggles an ArcTag (ARC.VAR) between true and false.')
		print(addonColor..'Function: |cffFFAAAAARC:TOG("tag")|r')
		print(addonColor..'Example: |cffFFAAAAARC:TOG("ToggleLight")|r')
		print(addonColor.."Use alongside ARC:IF to make toggle spells.|r")
	end
end

function ARC:SET(tag, str)
	if tag == "" then tag = nil end
	if str == "" then str = nil end
	if tag and str then
		ARC.VAR[tag] = str
	else
		cprint('ARC:API SYNTAX - SET - Set an ArcTag (ARC.VAR) to a specific value.')
		print(addonColor..'Function: |cffFFAAAAARC:SET("tag", "value")|r')
		print(addonColor..'Example 1: |cffFFAAAAARC:SET("ToggleLight","2")|r')
		print(addonColor..'Example 2: |cffFFAAAAARC:SET("ToggleLight","3")|r')
		print(addonColor.."This is likely only useful for power-users and super specific spells.|r")
	end
end

function ARC:GET(tag)
	if tag and tag ~= nil then
		return ARC.VAR[tag];
	else
		cprint("ARC:API SYNTAX - GET - Get the value of an ArcTag (ARC.VAR).")
		print(addonColor..'Function: |cffFFAAAAARC:GET("tag")|r')
		print(addonColor..'Example 1: |cffFFAAAAARC:GET("ToggleLight")|r')
	end
end



-------------------------------------------------------------------------------
-- Version / Help / Toggle
-------------------------------------------------------------------------------

SLASH_SCFORGEMAIN1, SLASH_SCFORGEMAIN2 = '/arcanum', '/sf'; -- 3.
function SlashCmdList.SCFORGEMAIN(msg, editbox) -- 4.
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

function CastARC(commID)
	SlashCmdList.SCFORGEMAIN(commID)
end

SLASH_SCFORGEAPI1 = '/arc'; -- 3.
function SlashCmdList.SCFORGEAPI(msg, editbox) -- 4.
	local command, rest = msg:match("^(%S*)%s*(.-)$")
	if not command or command == "" then
		cprint("Commands & API")
		print(addonColor.."Main Commands:")
		print(addonColor.."/arcanum [$commID] - Cast an ArcSpell by it's command ID you gave it (aka CommID), or open the Spell Forge UI if left blank.")
		print(addonColor.."/sf [$commID] - Shorter Alternative to /arcanum.")
		print(" ")
		print(addonColor.."API Commands:")
		print(addonColor.."/arc ..")
		print(addonColor.."     .. cast $commID - The same as /arcanum or /sf")
		print(addonColor.."     .. c $command - Runs the server $command specified (i.e., 'cheat fly').")
		print("               Direct Function: |cffFFAAAA/run ARC:C()|r".." - Run this for a better description.")
		print(addonColor..'     .. if $tag "$commandTrue" "$commandFalse" ["$var1"]')
		print(addonColor.."          Checks if the $tag is true and runs the $commandTrue (with $var1 added if given), or $commandFalse if not true (with $var1 added if given).")
		print("               Direct Function: |cffFFAAAA/run ARC:IF()|r".." - Run this for a better description.")
		print(addonColor.."     .. tog $tag - Toggles the $tag between true & false, used with ARC:IF (/arc if).")
		print("             Direct Function: |cffFFAAAA/run ARC:TOG()|r".." - Run this for a better description.")
		print(addonColor..'     .. set $tag "$value" - Sets the $tag to a specific "$value". You will need to query with ARC:GET and compare directly.')
		print("               Direct Function: |cffFFAAAA/run ARC:SET()|r".." - Run this for a better description.")
		print(addonColor.."/sfdebug - List all the Debug Commands. WARNING: These are for DEBUG, not for you to play with and complain you broke something.")
		return;
	elseif command == "cast" then
		SlashCmdList.SCFORGEMAIN(rest)
	elseif command == "tog" then
		ARC:TOG(rest)
	elseif command == "if" then
		print(rest)
		local tag, command1, command2, var1, var2
		tag, rest = rest:match("^(%S*)%s*(.-)$")
		command1, rest = rest:match("^(%S*)%s*(.-)$")
		command2, rest = rest:match("^(%S*)%s*(.-)$")
		var1, rest = rest:match("^(%S*)%s*(.-)$")
		var2, rest = rest:match("^(%S*)%s*(.-)$")
		ARC:IF(tag, command1,command2,var1,var2)
	end
end

local _phaseSpellDebugDataTable = {}
SLASH_SCFORGEDEBUG1 = '/sfdebug';
function SlashCmdList.SCFORGEDEBUG(msg, editbox) -- 4.
	local command, rest = msg:match("^(%S*)%s*(.-)$")
	if SpellCreatorMasterTable.Options["debug"] and msg ~= "" then
		if command == "debug" then
			SpellCreatorMasterTable.Options["debug"] = not SpellCreatorMasterTable.Options["debug"]
			dprint(true, "SC-Forge Debug Set to: "..tostring(SpellCreatorMasterTable.Options["debug"]))
		elseif command == "resetSpells" then
			dprint(true, "All Arcaum Spells reset. #GoodBye #ThisCannotBeUndoneHopeYouDidn'tFuckUp!")
			SpellCreatorSavedSpells = {}
			updateSpellLoadRows()
		elseif command == "listSpells" then
			for k,v in orderedPairs(SpellCreatorSavedSpells) do
				cprint("ArcSpell: "..k.." =")
				dump(v)
			end
		elseif command == "listSpellKeys" then -- debug to list all spell keys by alphabetical order.
			local newTable = get_keys(SpellCreatorSavedSpells)
			table.sort(newTable)
			dump(newTable)
		elseif command == "resetPhaseSpellKeys" then
			if reset == "confirm" then
				C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", "")
				dprint(true, "Wiped all Spell Keys from Phase Vault memory. This does not wipe the data itself of the spells, so they can technically be recovered by manually adding the key back, or either exporting the data yourself using '/sfdebug getPhaseSpellData $commID' where commID is the command it was saved as...")
			else
				dprint(true, "resetPhaseSpellKeys -- WARNING: YOU ARE ABOUT TO WIPE ALL OF YOUR PHASE VAULT. You need to add 'confirm' after this command in order for it to work.")
			end
		elseif command == "removePhaseKey" then
			if rest and tonumber(rest) then
				rest = tonumber(rest)
				local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")

				phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")

				phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
					if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
						phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" )
						phaseVaultKeys = serialDecompressForAddonMsg(text)
						local theDeletedKey = phaseVaultKeys[rest]
						if theDeletedKey then
							table.remove(phaseVaultKeys, rest)
							phaseVaultKeys = serialCompressForAddonMsg(phaseVaultKeys)
							dprint(true, "Deleted Phase Key: ["..rest.."] = "..theDeletedKey)
							C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", phaseVaultKeys)
						else
							dprint(true, "Phase Key ID ["..rest.."] doesn't seem to exist.")
						end
					end
				end)
			else
				dprint(true, "removePhaseKey -- You need to prove the numerical ID (from getPhaseKeys) of the key to remove. This does not remove the spells data, only removes it's key from the key list, although you will not be able to access the spell afterwords.")
			end
		elseif command == "getPhaseSpellData" then
			local interAction
			if rest and rest ~= "" then
				dprint(true, "Retrieving Phase Vault Data for Key: '"..rest.."'")

				local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_S_"..rest)

				phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")

				phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
					if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
						phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" )
						interAction = serialDecompressForAddonMsg(text)
						_phaseSpellDebugDataTable[interAction.fullName] = {
							["encoded"] = text,
							["decoded"] = interAction,
						}
						dump(interAction)
					end
				end)
			else
				dprint(true, "Retrieving Phase Vault Data based on Phase Vault Keys...")
				local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")
				dprint("ticketID = "..messageTicketID)
				phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
				phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
					if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
						phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" )

						if (#text < 1 or text == "") then noSpellsToLoad(true); return; end
						phaseVaultKeys = serialDecompressForAddonMsg(text)
						if #phaseVaultKeys < 1 then noSpellsToLoad(true); return; end
						local phaseVaultLoadingCount = 0
						local phaseVaultLoadingExpected = #phaseVaultKeys
						local messageTicketQueue = {}

						-- set up the phaseAddonDataListener2 ahead of time instead of EVERY SINGLE FUCKING ITERATION..

						phaseAddonDataListener2:RegisterEvent("CHAT_MSG_ADDON")
						phaseAddonDataListener2:SetScript("OnEvent", function (self, event, prefix, text, channel, sender, ...)
							if event == "CHAT_MSG_ADDON" and messageTicketQueue[prefix] and text then
								messageTicketQueue[prefix] = nil -- remove it from the queue.. We'll reset the table next time anyways but whatever.
								phaseVaultLoadingCount = phaseVaultLoadingCount+1
								interAction = serialDecompressForAddonMsg(text)
								_phaseSpellDebugDataTable[interAction.fullName] = {
									["encoded"] = text,
									["decoded"] = interAction,
								}
								dprint(true, interAction.fullName.." saved to debugPhaseData")
								if phaseVaultLoadingCount == phaseVaultLoadingExpected then
									phaseAddonDataListener2:UnregisterEvent("CHAT_MSG_ADDON")
								end
							end
						end)

						for k,v in ipairs(phaseVaultKeys) do
							--phaseVaultLoadingExpected = k
							dprint(true, "Trying to load spell from phase: "..v)
							local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_S_"..v)
							messageTicketQueue[messageTicketID] = true -- add it to a fake queue table so we can watch for multiple prefixes...
						end
					end
				end)
			end
			SpellCreatorMasterTable.Options["debugPhaseData"] = _phaseSpellDebugDataTable
			dprint(true, "Phase Vault key data cached for this single reload to the 'epsilon/_retail_/WTF/Account/NAME/SavedVariables/SpellCreator.lua' file.")
		elseif command == "getPhaseKeys" then
			local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")

			phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")

			phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
				if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
					phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" )
					SpellCreatorMasterTable.Options["debugPhaseKeys"] = text
					print(text)
					phaseVaultKeys = serialDecompressForAddonMsg(text)
					dump(phaseVaultKeys)
				end
			end)

		end
	else
		cprint("DEBUG LIST")
		cprint("Version: "..addonVersion)
		--cprint("RuneIcon: "..runeIconOverlay.atlas or runeIconOverlay.tex)
		cprint("Debug Commands (/sfdebug ...): ")
		print("... resetSpells: reset your vault to empty. Cannot be undone.")
		print("... listSpells: List all your vault spells.. this is alot of stuff.")
		print("... listSpellKeys: List all your vault spells by just keys. Easier to read.")
		print("... resetPhaseSpellKeys: reset your phase vault to empty. Technically the spell data remains, and can be exported to your WTF file by using getPhaseSpellData below.")
		print("... getPhaseKeys: Lists all the vault spells by keys.")
		print("... getPhaseSpellData [$commID/key]: Exports the spell data for all current keys, or the specified commID/key, to your '|cffFFAAAA..epsilon/_retail_/WTF/Account/NAME/SavedVariables/SpellCreator.lua|r' file.")
	end
end

local testComVar
SLASH_SCFORGETEST1 = '/sftest';
function SlashCmdList.SCFORGETEST(msg, editbox) -- 4.
	if testComVar and testComVar < #minimapModels then testComVar = testComVar+1 else testComVar = 1 end
	modelFrameSetModel(SCForgeMainFrame.portrait.Model, testComVar, minimapModels)
	print(testComVar)

--[[
	if msg ~= "" then
		modelFrameSetModel(minimapButton.Model, msg, minimapModels)
	else
		initRuneIcon()
		setRuneTex(runeIconOverlay)
	end
--]]

end