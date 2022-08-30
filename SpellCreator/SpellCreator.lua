-------------------------------------------------------------------------------
-- Simple Chat Functions
-------------------------------------------------------------------------------

local MYADDON, MyAddOn = ...
local addonVersion, addonAuthor, addonName = GetAddOnMetadata(MYADDON, "Version"), GetAddOnMetadata(MYADDON, "Author"), GetAddOnMetadata(MYADDON, "Title")
local addonColor = "|cff".."7e1af0"

local utils = Epsilon.utils
local messages = utils.messages
local server = utils.server
local tabs = utils.tabs

local main = Epsilon.main

local function cmd(text)
  SendChatMessage("."..text, "GUILD");
end

local function msg(text)
  SendChatMessage(""..text, "SAY");
end

local function cprint(text)
	print(addonColor..addonName..": "..(text and text or "ERROR").."|r")
end

local function dprint(force, text, rest)
	if force == true or SpellCreatorMasterTable.Options["debug"] then
		local line = strmatch(debugstack(2),":(%d+):")
		if line then
			print(addonColor..addonName.." DEBUG "..line..": "..text..(rest and " | "..rest or "").." |r")
		else
			print(addonColor..addonName.." DEBUG: "..text..(rest and " | "..rest or "").." |r")
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
-- Minimap Icon
-------------------------------------------------------------------------------

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
minimapButton:SetScript("OnClick", function(self)
	-- show / hide the frame
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
end

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
"interface/icons/inv_inscription_talenttome01",
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
"interface/archeology/arch-bookitemleft",
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
"interface/archeology/arch-bookitemright.blp",
"interface/archeology/arch-bookitemright.blp",
"interface/archeology/arch-bookitemright.blp",
"interface/archeology/arch-bookitemright.blp",
"interface/archeology/arch-bookitemright.blp",
"interface/spellbook/spellbook-page-2",
}
-------------------------------------------------------------------------------
-- Addon Loaded
-------------------------------------------------------------------------------

local SC_Addon_OnLoad = CreateFrame("frame","SC_Addon_OnLoad");
SC_Addon_OnLoad:RegisterEvent("ADDON_LOADED");
SC_Addon_OnLoad:SetScript("OnEvent", function(self,event,name)
	if name == "SpellCreator" then
				
		SC_loadMasterTable();
		LoadMinimapPosition();
	
		--Quickly Show / Hide the Frame on Start-Up to initialize everything for key bindings & loading
		C_Timer.After(1,function()
			SCForgeMainFrame:Show();
			SCForgeMainFrame:Hide();
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
	end
end);

-------------------------------------------------------------------------------
-- Core Functions & Data
-------------------------------------------------------------------------------

local actionTypeDataList = {"SpellCast", "SpellAura", "Anim", "Morph", "Standstate", "Equip", "RemoveAura", "RemoveAllAuras", "Unmorph", "Unequip"}
local actionTypeData = {
	["SpellCast"] = {
		["name"] = "Cast Spell",							-- The Displayed Name in the UI
		["command"] = "cast", 								-- The chat command, or Lua function to process
		["description"] = "Cast a spell using a Spell ID", 	-- Description for on-mouse-over
		["dataName"] = "Spell ID", 							-- Label for the ID Box, nil to disable the ID box
		["comTarget"] = "server", 							-- Server for commands, func for custom Lua function in 'command'
		["revert"] = "", 									-- The command that reverts it, i.e, 'unaura' for 'aura'
		["selfAble"] = true,								-- True/False - if able to use the self-toggle checkbox
		},
	["SpellAura"] = {
		["name"] = "Apply Aura",
		["command"] = "aura",
		["description"] = "Applies an Aura on you, or your target.",
		["dataName"] = "Spell ID",
		["comTarget"] = "server",
		["revert"] = "unaura",
		["selfAble"] = true,
		},
	["Anim"] = {
		["name"] = "Emote",
		["command"] = "",
		["description"] = "",
		["dataName"] = "Emote ID",
		["comTarget"] = "server",
		["revert"] = "",
		["selfAble"] = true,
		},
	["Morph"] = {
		["name"] = "Morph",
		["command"] = "",
		["description"] = "",
		["dataName"] = "Display ID",
		["comTarget"] = "server",
		["revert"] = "demorph",
		["selfAble"] = false,
		},
	["Standstate"] = {
		["name"] = "Standstate",
		["command"] = "",
		["description"] = "",
		["dataName"] = "Standstate ID",
		["comTarget"] = "server",
		["revert"] = "",
		["selfAble"] = true,
		},
	["Equip"] = {
		["name"] = "Equip Item",
		["command"] = function(vars) EquipItemByName(vars) end,
		["description"] = "Equip an Item by name or ID. Cannot be reverted directly.",
		["dataName"] = "Item ID or Name",
		["comTarget"] = "func",
		["revert"] = nil,
		["selfAble"] = false,
		},
	["RemoveAura"] = {
		["name"] = "Remove Aura",
		["command"] = "unaura",
		["description"] = "Remove an Aura. Revert re-applies it after the delay.",
		["dataName"] = "Spell ID",
		["comTarget"] = "server",
		["revert"] = "aura",
		["selfAble"] = true,
		},
	["RemoveAllAuras"] = {
		["name"] = "Remove All Auras",
		["command"] = "unaura all",
		["description"] = "Remove all Auras. Cannot be reverted.",
		["dataName"] = nil,
		["comTarget"] = "server",
		["revert"] = nil,
		["selfAble"] = true,
		},
	["Unmorph"] = {
		["name"] = "Remove Morph",
		["command"] = "demorph",
		["description"] = "Remove all morphs.",
		["dataName"] = nil,
		["comTarget"] = "server",
		["revert"] = nil,
		},
	["Unequip"] = {
		["name"] = "Unequip Item",
		["command"] = function(slotID) PickupInventoryItem(slotID); PutItemInBackpack(); end,
		["description"] = "Unequips an item by item slot (i.e., tabard).",
		["dataName"] = "Item Slot ID",
		["comTarget"] = "func",
		["revert"] = nil,
		},
}

local function processAction(delay, actionType, revertTime, selfOnly, vars)
	local actionData = actionTypeData[actionType]
	if revertTime then revertTime = tonumber(revertTime) end
	local varTable
	
	if vars then
		varTable = { strsplit(",", vars) }
	end
		
	if actionType == "Equip" then
		C_Timer.After(delay, function()
			local varTable = varTable
			for k,v in ipairs(varTable) do
				EquipItemByName(v)
			end
		end)
	elseif actionData.comTarget == "func" then
		C_Timer.After(delay, function()
			local varTable = varTable
			for k,v in ipairs(varTable) do
				actionData.command(v)
			end
		end)
	else
		if actionData.dataName then
			C_Timer.After(delay, function()
				local varTable = varTable
				for k,v in ipairs(varTable) do
					if selfOnly then
						cmd(actionData.command.." "..v.." self")
					else
						cmd(actionData.command.." "..v)
					end
				end
				if revertTime > 0 then
					C_Timer.After(revertTime, function()
						local varTable = varTable
						for k,v in ipairs(varTable) do
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
				C_Timer.After(delay, cmd(actionData.command))
			else
				C_Timer.After(delay, cmd(actionData.command))
			end
		end
	end
end



-------------------------------------------------------------------------------
-- Main UI Frame
-------------------------------------------------------------------------------

SCForgeMainFrame = CreateFrame("Frame", "SCForgeMainFrame", UIParent, "ButtonFrameTemplate")
SCForgeMainFrame:SetPoint("CENTER")
SCForgeMainFrame:SetSize(700, 600)
SCForgeMainFrame:SetMovable(true)
SCForgeMainFrame:SetPortraitToAsset(frameIconOptions[fastrandom(#frameIconOptions)])
SCForgeMainFrame:SetTitle("Arcanum - Spell Forge")
SCForgeMainFrame.Inset:SetPoint("TOPLEFT", 4, -25)
local randomBackgroundID = fastrandom(#frameBackgroundOptions)
local background = SCForgeMainFrame:CreateTexture(nil,"BACKGROUND")
background:SetTexture(frameBackgroundOptions[randomBackgroundID])
--background:SetAllPoints()
background:SetTexCoord(0.05,1,0,1)
background:SetPoint("TOPLEFT",0,-25)
background:SetPoint("BOTTOMRIGHT",-30,5)
local background2 = SCForgeMainFrame:CreateTexture(nil,"BACKGROUND")
background2:SetTexture(frameBackgroundOptionsEdge[randomBackgroundID])
background2:SetPoint("TOPLEFT", background, "TOPRIGHT")
background2:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", 30, 0)

SCForgeMainFrame:Show()

local function genStaticDropdownChild( parent, dropdownName, menuList, title, width )

	if not parent or not dropdownName or not menuList then return end;
	if not title then title = "Select" end
	if not width then width = 55 end
	local newDropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
	newDropdown:SetPoint("CENTER")
		
	local function newDropdown_Initialize( dropdownName, level )
		for index,value in ipairs(menuList) do
		--for index = 1, #dropdownName.menuList do
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
	_G[dropdownName.."Text"]:SetFont(fontName, 8)
	
	newDropdown:GetParent():SetWidth(newDropdown:GetWidth())
	newDropdown:GetParent():SetHeight(newDropdown:GetHeight())	
end

local numberOfSpellRows = 0
local rowHeight = 60
local rowSpacing = 30

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

local function AddSpellRow()
	numberOfSpellRows = numberOfSpellRows+1
	if _G["spellRow"..numberOfSpellRows] then _G["spellRow"..numberOfSpellRows]:Show(); else
		newRow = CreateFrame("Frame", "spellRow"..numberOfSpellRows, SCForgeMainFrameInset)
		--newRow:SetAllPoints()
		if numberOfSpellRows == 1 then
			newRow:SetPoint("TOPLEFT", 25, (rowSpacing+5)*-numberOfSpellRows)
		else
			newRow:SetPoint("TOPLEFT", 25, ((rowHeight+5)*-numberOfSpellRows)+30)
		end
		newRow:SetWidth(650)
		newRow:SetHeight(rowHeight)
		
		newRow.Background = newRow:CreateTexture(nil,"BACKGROUND")
		newRow.Background:SetAllPoints()
		newRow.Background:SetColorTexture(0,0,0,0.25)
		
		newRow.mainDelayBox = CreateFrame("EditBox", "spellRow"..numberOfSpellRows.."MainDelayBox", newRow, "InputBoxTemplate")
		newRow.mainDelayBox:SetAutoFocus(false)
		newRow.mainDelayBox:SetSize(60,23)
		newRow.mainDelayBox:SetPoint("LEFT", 40, 0)
		newRow.mainDelayBox:SetMaxLetters(7)
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
		
		-- Action Menu
		local menuList = {}
		
		for k,v in ipairs(actionTypeDataList) do
			local menuItem = UIDropDownMenu_CreateInfo()
			menuItem.text = actionTypeData[v].name
			menuItem.value = v
			menuItem.arg1 = numberOfSpellRows
			menuItem.func = function(self, arg1)
				_G["spellRow"..arg1.."ActionSelectButton"].Title:SetText("Something")
			end
			table.insert(menuList, menuItem)
		end
		
		newRow.actionSelectButton = CreateFrame("Frame", "spellRow"..numberOfSpellRows.."ActionSelectAnchor", newRow)
		newRow.actionSelectButton:SetPoint("LEFT", newRow.mainDelayBox, "RIGHT", 0, 0)
		genStaticDropdownChild( newRow.actionSelectButton, "spellRow"..numberOfSpellRows.."ActionSelectButton", menuList, "Action", 70)
		
	end
end

AddSpellRow()
AddSpellRow()
AddSpellRow()
AddSpellRow()

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
	
	local SpellCreatorInterfaceOptionsSpellList = SpellCreatorInterfaceOptions.panel:CreateFontString("Inventory Slot IDs", "OVERLAY", "GameFontNormalLeft")
	SpellCreatorInterfaceOptionsSpellList:SetPoint("BOTTOMLEFT", 20, 140)
	SpellCreatorInterfaceOptionsSpellList:SetText("Inventory Slot IDs:")
	SpellListHorizontalSpacing = 160
		local SpellCreatorInterfaceOptionsSpellListRow1 = SpellCreatorInterfaceOptions.panel:CreateFontString("SpellRow1","OVERLAY",SpellCreatorInterfaceOptionsSpellList)
		SpellCreatorInterfaceOptionsSpellListRow1:SetPoint("TOPLEFT",SpellCreatorInterfaceOptionsSpellList,"BOTTOMLEFT",9,-15)
		local SpellCreatorInterfaceOptionsSpellListRow2 = SpellCreatorInterfaceOptions.panel:CreateFontString("SpellRow2","OVERLAY",SpellCreatorInterfaceOptionsSpellListRow1)
		SpellCreatorInterfaceOptionsSpellListRow2:SetPoint("TOPLEFT",SpellCreatorInterfaceOptionsSpellListRow1,"BOTTOMLEFT",0,-25)
			local SpellCreatorInterfaceOptionsSpellListSpell1 = SpellCreatorInterfaceOptions.panel:CreateFontString("Spell1","OVERLAY","GameFontNormalLeft")
				SpellCreatorInterfaceOptionsSpellListSpell1:SetPoint("LEFT",SpellCreatorInterfaceOptionsSpellListRow1,"RIGHT",SpellListHorizontalSpacing*0,0)
				SpellCreatorInterfaceOptionsSpellListSpell1:SetText("Head: 1      Shoulders: 2      Shirt: 4      Chest: 5      Waist: 6      Legs 6      Feet: 8      Wrist: 9")

			local SpellCreatorInterfaceOptionsSpellListSpell4 = SpellCreatorInterfaceOptions.panel:CreateFontString("Spell4","OVERLAY","GameFontNormalLeft")
				SpellCreatorInterfaceOptionsSpellListSpell4:SetPoint("LEFT",SpellCreatorInterfaceOptionsSpellListRow2,"RIGHT",SpellListHorizontalSpacing*0,0)
				SpellCreatorInterfaceOptionsSpellListSpell4:SetText("Hands: 10      Back: 15      Main-hand: 16      Off-hand: 17      Ranged: 18      Tabard: 19 ")
	
	local SpellCreatorInterfaceOptionsEmoteList = SpellCreatorInterfaceOptions.panel:CreateFontString("EmoteList", "OVERLAY", "GameFontNormalLeft")
	SpellCreatorInterfaceOptionsEmoteList:SetPoint("TOPLEFT", SpellCreatorInterfaceOptionsSpellList, "BOTTOMLEFT", 0, -70)
	SpellCreatorInterfaceOptionsEmoteList:SetText("Common Emote IDs:")
		local SpellCreatorInterfaceOptionsEmoteListRow1 = SpellCreatorInterfaceOptions.panel:CreateFontString("EmoteRow1","OVERLAY",SpellCreatorInterfaceOptionsEmoteList)
		SpellCreatorInterfaceOptionsEmoteListRow1:SetPoint("TOPLEFT",SpellCreatorInterfaceOptionsEmoteList,"BOTTOMLEFT",9,-15)
		local SpellCreatorInterfaceOptionsEmoteListRow2 = SpellCreatorInterfaceOptions.panel:CreateFontString("EmoteRow2","OVERLAY",SpellCreatorInterfaceOptionsEmoteListRow1)
		SpellCreatorInterfaceOptionsEmoteListRow2:SetPoint("TOPLEFT",SpellCreatorInterfaceOptionsEmoteListRow1,"BOTTOMLEFT",0,-25)
			local SpellCreatorInterfaceOptionsEmoteListEmote1 = SpellCreatorInterfaceOptions.panel:CreateFontString("Emote1","OVERLAY","GameFontNormalLeft")
				SpellCreatorInterfaceOptionsEmoteListEmote1:SetPoint("LEFT",SpellCreatorInterfaceOptionsEmoteListRow1,"RIGHT",SpellListHorizontalSpacing*0,0)
				SpellCreatorInterfaceOptionsEmoteListEmote1:SetText("Talk: 396")
			local SpellCreatorInterfaceOptionsEmoteListEmote2 = SpellCreatorInterfaceOptions.panel:CreateFontString("Emote2","OVERLAY","GameFontNormalLeft")
				SpellCreatorInterfaceOptionsEmoteListEmote2:SetPoint("LEFT",SpellCreatorInterfaceOptionsEmoteListRow1,"RIGHT",SpellListHorizontalSpacing*1,0)
				SpellCreatorInterfaceOptionsEmoteListEmote2:SetText("Exclamation: 5")
			local SpellCreatorInterfaceOptionsEmoteListEmote3 = SpellCreatorInterfaceOptions.panel:CreateFontString("Emote3","OVERLAY","GameFontNormalLeft")
				SpellCreatorInterfaceOptionsEmoteListEmote3:SetPoint("LEFT",SpellCreatorInterfaceOptionsEmoteListRow1,"RIGHT",SpellListHorizontalSpacing*2,0)
				SpellCreatorInterfaceOptionsEmoteListEmote3:SetText("Question: 6")
			local SpellCreatorInterfaceOptionsEmoteListEmote4 = SpellCreatorInterfaceOptions.panel:CreateFontString("Emote4","OVERLAY","GameFontNormalLeft")
				SpellCreatorInterfaceOptionsEmoteListEmote4:SetPoint("LEFT",SpellCreatorInterfaceOptionsEmoteListRow1,"RIGHT",SpellListHorizontalSpacing*3,0)
				SpellCreatorInterfaceOptionsEmoteListEmote4:SetText("Working: 432")
			local SpellCreatorInterfaceOptionsEmoteListEmote5 = SpellCreatorInterfaceOptions.panel:CreateFontString("Emote5","OVERLAY","GameFontNormalLeft")
				SpellCreatorInterfaceOptionsEmoteListEmote5:SetPoint("LEFT",SpellCreatorInterfaceOptionsEmoteListRow2,"RIGHT",SpellListHorizontalSpacing*0,0)
				SpellCreatorInterfaceOptionsEmoteListEmote5:SetText("Read Book: 641")
			local SpellCreatorInterfaceOptionsEmoteListEmote6 = SpellCreatorInterfaceOptions.panel:CreateFontString("Emote6","OVERLAY","GameFontNormalLeft")
				SpellCreatorInterfaceOptionsEmoteListEmote6:SetPoint("LEFT",SpellCreatorInterfaceOptionsEmoteListRow2,"RIGHT",SpellListHorizontalSpacing*1,0)
				SpellCreatorInterfaceOptionsEmoteListEmote6:SetText("Read Map: 492")
			local SpellCreatorInterfaceOptionsEmoteListEmote7 = SpellCreatorInterfaceOptions.panel:CreateFontString("Emote7","OVERLAY","GameFontNormalLeft")
				SpellCreatorInterfaceOptionsEmoteListEmote7:SetPoint("LEFT",SpellCreatorInterfaceOptionsEmoteListRow2,"RIGHT",SpellListHorizontalSpacing*2,0)
				SpellCreatorInterfaceOptionsEmoteListEmote7:SetText("Read Map & Talk: 588")
	
	--Minimap Icon Toggle
	local SpellCreatorInterfaceOptionsMiniMapToggle = CreateFrame("CHECKBUTTON", "SC_ToggleMiniMapIconOption", SpellCreatorInterfaceOptions.panel, "InterfaceOptionsCheckButtonTemplate")
	SC_ToggleMiniMapIconOption:SetPoint("TOPLEFT", 20, -40)
	SC_ToggleMiniMapIconOptionText:SetText("Enable the Minimap Button / Icon")
	SC_ToggleMiniMapIconOption:SetScript("OnShow", function(self)
		if SpellCreatorMasterTable.Options["minimapIcon"] == true then
			self:SetChecked(true)
		else
			self:SetChecked(false)
			DisableOptions(true)
		end
	end)
	SC_ToggleMiniMapIconOption:SetScript("OnClick", function(self)
		SpellCreatorMasterTable.Options["minimapIcon"] = not SpellCreatorMasterTable.Options["minimapIcon"]
		-- do the work here
	end)
	SC_ToggleMiniMapIconOption:SetScript("OnEnter", function()
		GameTooltip:SetOwner(SC_ToggleMiniMapIconOption, "ANCHOR_LEFT")
		SC_ToggleMiniMapIconOption.Timer = C_Timer.NewTimer(0.7,function()
			GameTooltip:SetText("Toggle the mini map icon on / off.", nil, nil, nil, nil, true)
			GameTooltip:Show()
		end)
	end)
	SC_ToggleMiniMapIconOption:SetScript("OnLeave", function()
		GameTooltip_Hide()
		SC_ToggleMiniMapIconOption.Timer:Cancel()
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
-- Version / Help / Toggle
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

SLASH_SCFORGEHELP1, SLASH_SCFORGEHELP2 = '/arcanum', '/sf'; -- 3.
function SlashCmdList.SCFORGEHELP(msg, editbox) -- 4.
	if SpellCreatorMasterTable.Options["debug"] and msg == "debug" then
		cprint(addonName.." | DEBUG LIST")
		cprint("Version: "..addonVersion)
	else
		scforge_showhide(msg)
	end
end

SLASH_SCFORGEDEBUG1 = '/sfdebug';
function SlashCmdList.SCFORGEDEBUG(msg, editbox) -- 4.
	SpellCreatorMasterTable.Options["debug"] = not SpellCreatorMasterTable.Options["debug"]
	dprint("SC-Forge Debug Set to: "..tostring(SpellCreatorMasterTable.Options["debug"]),true)
end

SLASH_SCFORGETEST1 = '/sftest';
function SlashCmdList.SCFORGETEST(msg, editbox) -- 4.
	delay, actionType, revertTime, selfOnly, vars = 1, "Equip", 0, nil, "125539,160175"
	processAction(delay, actionType, revertTime, selfOnly, vars)
end