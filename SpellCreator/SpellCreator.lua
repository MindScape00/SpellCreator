local addonName = ...
---@class ns
local ns = select(2, ...)

local ActionsData = ns.Actions.Data
local actionTypeData = ActionsData.actionTypeData
local executeSpell = ns.Actions.Execute.executeSpell
local cmd, cmdWithDotCheck = ns.Cmd.cmd, ns.Cmd.cmdWithDotCheck
local runMacroText = ns.Cmd.runMacroText
local cprint, dprint, eprint = ns.Logging.cprint, ns.Logging.dprint, ns.Logging.eprint

local Comms = ns.Comms
local Constants = ns.Constants
local Permissions = ns.Permissions
local ProfileFilter = ns.ProfileFilter
local SavedVariables = ns.SavedVariables
local serializer = ns.Serializer
local Vault = ns.Vault

local DataUtils = ns.Utils.Data
local Debug = ns.Utils.Debug
local HTML = ns.Utils.HTML
local NineSlice = ns.Utils.NineSlice

local Animation = ns.UI.Animation
local Attic = ns.UI.Attic
local Castbar = ns.UI.Castbar
local ChatLink = ns.UI.ChatLink
local Icons = ns.UI.Icons
local Models, Portrait = ns.UI.Models, ns.UI.Portrait
local LoadSpellFrame = ns.UI.LoadSpellFrame
local MainFrame = ns.UI.MainFrame
local MinimapButton = ns.UI.MinimapButton
local ProfileFilterMenu = ns.UI.ProfileFilterMenu
local Quickcast = ns.UI.Quickcast
local SpellRow = ns.UI.SpellRow
local SpellVaultFrame = ns.UI.SpellVaultFrame

local addonMsgPrefix = Comms.PREFIX
local ADDON_COLOR, ADDON_PATH, ADDON_TITLE = Constants.ADDON_COLOR, Constants.ADDON_PATH, Constants.ADDON_TITLE
local ASSETS_PATH = Constants.ASSETS_PATH
local SPELL_VISIBILITY = Constants.SPELL_VISIBILITY
local VAULT_TYPE = Constants.VAULT_TYPE
local isDMEnabled, isOfficerPlus, isMemberPlus = Permissions.isDMEnabled, Permissions.isOfficerPlus, Permissions.isMemberPlus
local phaseVault = Vault.phase
local isNotDefined = DataUtils.isNotDefined

local addonVersion, addonAuthor = GetAddOnMetadata(addonName, "Version"), GetAddOnMetadata(addonName, "Author")

---@type table<CommID, VaultSpell>
local savedSpellFromVault = {}

local modifiedGossips = {}
local isGossipLoaded
local saveSpell

-- localized frequent functions for speed
local C_Timer = C_Timer
local print = print
local SendChatMessage = SendChatMessage
local _G = _G
local pairs, ipairs = pairs, ipairs
--local tContains = tContains
--
-- local curDate = date("*t") -- Current Date for surprise launch - disabled since it's over anyways

local AceComm = ns.Libs.AceComm

local sfCmd_ReplacerChar = "@N@"

-- local utils = Epsilon.utils
-- local messages = utils.messages
-- local server = utils.server
-- local tabs = utils.tabs

-- local main = Epsilon.main

-- Deprecated Functions Wrapper
local CloseGossip = CloseGossip or C_GossipInfo.CloseGossip;
local GetNumGossipOptions = GetNumGossipOptions or C_GossipInfo.GetNumOptions;
local SelectGossipOption = SelectGossipOption or C_GossipInfo.SelectOption;
local GetGossipText = GetGossipText or C_GossipInfo.GetText;

local C_Epsilon = C_Epsilon

-------------------------------------------------------------------------------
-- Simple Chat & Helper Functions
-------------------------------------------------------------------------------

local function sendChat(text)
  SendChatMessage(text, "SAY");
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

-- Frame Listeners
local phaseAddonDataListener = CreateFrame("Frame")
local phaseAddonDataListener2 = CreateFrame("Frame")

-------------------------------------------------------------------------------
-- UI Helper & Definitions
-------------------------------------------------------------------------------

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

--NineSliceUtil.ApplyLayout(SCForgeMainFrame, "BFAMissionAlliance") -- You can use this to apply other nine-slice templates to a nine-slice frame. We want a custom Nine-Slice tho so below is my application of it.

NineSlice.ApplyLayoutByName(SCForgeMainFrame.NineSlice, "ArcanumFrameTemplate")

Portrait.init()

-- The top bar Spell Info Boxes
Attic.init(SCForgeMainFrame)

local background = SCForgeMainFrame.Inset.Bg -- re-use the stock background, save a frame texture
	background:SetTexture(ADDON_PATH.."/assets/bookbackground_full")
	background:SetVertTile(false)
	background:SetHorizTile(false)
	background:SetAllPoints()

	background.Overlay = SCForgeMainFrame.Inset:CreateTexture(nil, "BACKGROUND")
	background.Overlay:SetTexture(ADDON_PATH.."/assets/forge_ui_bg_anim")
	background.Overlay:SetAllPoints()
	background.Overlay:SetAlpha(0.02)

	--[[
	background.Overlay2 = SCForgeMainFrame.Inset:CreateTexture(nil, "BACKGROUND")
	background.Overlay2:SetTexture(ADDON_PATH.."/assets/forge_ui_bg_runes")
	background.Overlay2:SetAllPoints()
	background.Overlay2:SetAlpha(0.25)
	--]]

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
	scrollFrame.ScrollBar.scrollStep = SpellRow.size.rowHeight

SCForgeMainFrame.TitleBar = CreateFrame("Frame", nil, SCForgeMainFrame.Inset)
	SCForgeMainFrame.TitleBar:SetPoint("TOPLEFT", SCForgeMainFrame.Inset, "TOPLEFT", 25, -8)
	SCForgeMainFrame.TitleBar:SetSize(MainFrame.size.x-50, 24)
	--SCForgeMainFrame.TitleBar:SetHeight(20)


	SCForgeMainFrame.TitleBar.Background = SCForgeMainFrame.TitleBar:CreateTexture(nil,"BACKGROUND", nil, 5)
		SCForgeMainFrame.TitleBar.Background:SetAllPoints()
		--SCForgeMainFrame.TitleBar.Background:SetColorTexture(0,0,0,1)
		SCForgeMainFrame.TitleBar.Background:SetAtlas("Rewards-Shadow") -- AftLevelup-ToastBG; Garr_BuildingInfoShadow; Rewards-Shadow
		SCForgeMainFrame.TitleBar.Background:SetAlpha(0.5)
		SCForgeMainFrame.TitleBar.Background:SetPoint("TOPLEFT",-20,0)
		SCForgeMainFrame.TitleBar.Background:SetPoint("BOTTOMRIGHT", 10, -3)

	SCForgeMainFrame.TitleBar.Overlay = SCForgeMainFrame.TitleBar:CreateTexture(nil,"BACKGROUND", nil, 6)
		--SCForgeMainFrame.TitleBar.Overlay:SetAllPoints(SCForgeMainFrame.TitleBar.Background)
		SCForgeMainFrame.TitleBar.Overlay:SetPoint("TOPLEFT",-3,0)
		SCForgeMainFrame.TitleBar.Overlay:SetPoint("BOTTOMRIGHT",-8,-3)
		--SCForgeMainFrame.TitleBar.Overlay:SetTexture(ADDON_PATH.."/assets/SpellForgeMainPanelRow2")
		SCForgeMainFrame.TitleBar.Overlay:SetAtlas("search-select") -- Garr_CostBar
		SCForgeMainFrame.TitleBar.Overlay:SetDesaturated(true)
		SCForgeMainFrame.TitleBar.Overlay:SetVertexColor(0.35,0.7,0.85)
		SCForgeMainFrame.TitleBar.Overlay:SetTexCoord(0.075,0.925,0,1)
		--SCForgeMainFrame.TitleBar.Overlay:SetTexCoord(0.208,1-0.209,0,1-0)

	SCForgeMainFrame.TitleBar.MainDelay = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
		SCForgeMainFrame.TitleBar.MainDelay:SetWidth(SpellRow.size.delayColumnWidth)
		SCForgeMainFrame.TitleBar.MainDelay:SetJustifyH("CENTER")
		SCForgeMainFrame.TitleBar.MainDelay:SetPoint("LEFT", SCForgeMainFrame.TitleBar, "LEFT", 13+25, 0)
		SCForgeMainFrame.TitleBar.MainDelay:SetText("Delay")

	SCForgeMainFrame.TitleBar.Action = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
		SCForgeMainFrame.TitleBar.Action:SetWidth(SpellRow.size.actionColumnWidth+50)
		SCForgeMainFrame.TitleBar.Action:SetJustifyH("CENTER")
		SCForgeMainFrame.TitleBar.Action:SetPoint("LEFT", SCForgeMainFrame.TitleBar.MainDelay, "RIGHT", 0, 0)
		SCForgeMainFrame.TitleBar.Action:SetText("Action")

	SCForgeMainFrame.TitleBar.Self = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
		SCForgeMainFrame.TitleBar.Self:SetWidth(SpellRow.size.selfColumnWidth+10)
		SCForgeMainFrame.TitleBar.Self:SetJustifyH("CENTER")
		SCForgeMainFrame.TitleBar.Self:SetPoint("LEFT", SCForgeMainFrame.TitleBar.Action, "RIGHT", -9, 0)
		SCForgeMainFrame.TitleBar.Self:SetText("Self")

	SCForgeMainFrame.TitleBar.InputEntry = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
		SCForgeMainFrame.TitleBar.InputEntry:SetWidth(SpellRow.size.inputEntryColumnWidth)
		SCForgeMainFrame.TitleBar.InputEntry:SetJustifyH("CENTER")
		SCForgeMainFrame.TitleBar.InputEntry:SetPoint("LEFT", SCForgeMainFrame.TitleBar.Self, "RIGHT", 5, 0)
		SCForgeMainFrame.TitleBar.InputEntry:SetText("Input")

	SCForgeMainFrame.TitleBar.RevertDelay = SCForgeMainFrame.TitleBar:CreateFontString(nil,"OVERLAY", "GameFontNormalLarge")
		SCForgeMainFrame.TitleBar.RevertDelay:SetWidth(SpellRow.size.revertDelayColumnWidth)
		SCForgeMainFrame.TitleBar.RevertDelay:SetJustifyH("CENTER")
		SCForgeMainFrame.TitleBar.RevertDelay:SetPoint("LEFT", SCForgeMainFrame.TitleBar.InputEntry, "RIGHT", 25, 0)
		SCForgeMainFrame.TitleBar.RevertDelay:SetText("Revert")

SCForgeMainFrame.AddRowRow = CreateFrame("Frame", nil, SCForgeMainFrame.Inset.scrollFrame.scrollChild)
local _frame = SCForgeMainFrame.AddRowRow
	_frame:SetPoint("TOPLEFT", 25, 0)
	_frame:SetWidth(MainFrame.size.x-50)
	_frame:SetHeight(SpellRow.size.rowHeight)

	_frame.Background = _frame:CreateTexture(nil,"BACKGROUND", nil, 5)
		_frame.Background:SetAllPoints()
		_frame.Background:SetTexture(ADDON_PATH.."/assets/SpellForgeMainPanelRow1")
		_frame.Background:SetTexCoord(0.208,1-0.209,0,1)
		_frame.Background:SetPoint("BOTTOMRIGHT",-9,0)
		_frame.Background:SetAlpha(0.9)

	_frame.Background2 = _frame:CreateTexture(nil,"BACKGROUND", nil, 6)
		_frame.Background2:SetAllPoints()
		_frame.Background2:SetTexture(ADDON_PATH.."/assets/SpellForgeMainPanelRow2")
		_frame.Background2:SetTexCoord(0.208,1-0.209,0,1)
		_frame.Background2:SetPoint("TOPLEFT",-3,0)
		_frame.Background2:SetPoint("BOTTOMRIGHT",-7,0)

		-- SCForgeMainFrame.AddRowRow.AddRowButton
	_frame.AddRowButton = CreateFrame("BUTTON", nil, _frame)
		_frame.AddRowButton:SetAllPoints()

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
				GameTooltip:SetText("Add another Action row", nil, nil, nil, nil, true)
				GameTooltip:AddLine("Max number of Rows: "..SpellRow.maxNumberOfRows,1,1,1,true)
				GameTooltip:Show()
			end)
		end)
		_frame.AddRowButton:SetScript("OnLeave", function(self)
			GameTooltip_Hide()
			self.Timer:Cancel()
		end)
		_frame.AddRowButton:SetScript("OnClick", function(self)
			SpellRow.addRow()
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
	local scale = MainFrame.updateFrameChildScales(self)
	local newHeight = self:GetHeight()
	local ratio = newHeight/MainFrame.size.y
	SCForgeMainFrame.LoadSpellFrame:SetSize(280*ratio, self:GetHeight())
	Attic.updateSize(SCForgeMainFrame:GetWidth())
end)

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
		GameTooltip:SetText("Clear & Reset the Spell Forge UI", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Use this to clear the action rows & spell info, and start fresh.",1,1,1,true)
		GameTooltip:AddLine("\nWARNING: You'll lose any data that hasn't been saved yet using 'Create'!",1,1,1,true)
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
--	Animation.setFrameFlicker(frame: any, iter: any, timeToFadeOut: any, timeToFadeIn: any, startAlpha: any, endAlpha: any)
	Animation.setFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 3, nil, nil, 0.05, 0.8)
	local maxDelay = 0
	local actionsToCommit = {}
	for i = 1, SpellRow.getNumActiveRows() do
		local actionData = SpellRow.getRowAction(i)

		if not actionData then
			dprint("Action Row " .. i .. " Invalid, Delay Not Set")
			break
		end

		if actionData.delay > maxDelay then maxDelay = actionData.delay end
		if actionData.revertDelay and actionData.revertDelay > maxDelay then maxDelay = actionData.revertDelay end

		table.insert(actionsToCommit, actionData)
	end
	C_Timer.After(maxDelay, function() Animation.stopFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 0.05, 0.25) end)

	local spellInfo = Attic.getInfo()
	local spellName = spellInfo.fullName
	local spellData = {["icon"] = Icons.getFinalIcon(spellInfo.icon)}
	executeSpell(actionsToCommit, nil, spellName, nil)
	local castBarStatus = spellInfo.castbar
	if castBarStatus ~= 0 then
		if castBarStatus == 1 then
			Castbar.showCastBar(maxDelay, spellName, spellData, false, nil, nil)
		elseif castBarStatus == 2 then
			Castbar.showCastBar(maxDelay, spellName, spellData, true, nil, nil)
		end
	end
end)
SCForgeMainFrame.ExecuteSpellButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Cast the above Actions", nil, nil, nil, nil, true)
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

SCForgeMainFrame.ExecuteSpellButton:SetEnabled(Permissions.canExecuteSpells())

---@param spellToLoad VaultSpell
local function loadSpell(spellToLoad)
	--dprint("Loading spell.. "..spellToLoad.commID)

	Attic.updateInfo(spellToLoad)

	local spellActions = spellToLoad.actions
	---@type VaultSpellAction[]
	local localSpellActions = CopyTable(spellActions)
	local numberOfActionsToLoad = #localSpellActions

	-- Adjust the number of available Action Rows
	SpellRow.setNumActiveRows(numberOfActionsToLoad)

	if SpellCreatorMasterTable.Options["loadChronologically"] then
		table.sort(localSpellActions, function (k1, k2) return k1.delay < k2.delay end)
	end

	-- Loop thru actions & set their data
	local rowNum, actionData
	for rowNum, actionData in ipairs(localSpellActions) do
		SpellRow.setRowAction(rowNum, actionData)
	end
end

SCForgeMainFrame.ResetUIButton:SetScript("OnClick", function(self)
	-- 2 types of reset: Delete all the Rows, and load an empty spell to effectively reset the UI. We're doing both, the delete rows for visual, load for the actual reset
--	self:Disable()
	local emptySpell = {
		["fullName"] = "", ["commID"] = "", ["description"] = "",
		["actions"] = { { ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, }, { ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, }, { ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, }, },
	}

	if SpellCreatorMasterTable.Options["fastReset"] then
		UIFrameFadeIn(SCForgeMainFrame.Inset.Bg.Overlay,0.2,0.05,0.8)
		C_Timer.After(0.2, function() UIFrameFadeOut(SCForgeMainFrame.Inset.Bg.Overlay,0.2,0.8,0.05); SCForgeMainFrame.ResetUIButton:Enable(); end)
		loadSpell(emptySpell)
	else
		UIFrameFadeIn(SCForgeMainFrame.Inset.Bg.Overlay,0.1,0.05,0.8)
		Animation.setFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 3, nil, nil, 0.05, 0.8)
		local deleteRowIter = 0
		for i = SpellRow.getNumActiveRows(), 1, -1 do
			deleteRowIter = deleteRowIter+1
			C_Timer.After(deleteRowIter/50, function() SpellRow.removeRow(i) end)
		end

		C_Timer.After(SpellRow.getNumActiveRows()/50, function()
			loadSpell(emptySpell)
			Animation.stopFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 0.05, 0.25)
			SCForgeMainFrame.ResetUIButton:Enable();
		end)
	end

end)

local phaseVaultKeys

---@param spellKey CommID
---@param where VaultType
local function deleteSpellConf(spellKey, where)
	local dialog = StaticPopup_Show("SCFORGE_CONFIRM_DELETE", savedSpellFromVault[spellKey].fullName, savedSpellFromVault[spellKey].commID)
	if dialog then dialog.data = spellKey; dialog.data2 = where end
end

local function noSpellsToLoad(fake)
	dprint("Phase Has No Spells to load.");
	phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" );
	if not fake then
		if isOfficerPlus() then
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("Vault is Empty\n\n\rSelect a spell in\ryour personal vault\rand click the Transfer\rbutton below!\n\n\rGo on, add\rsomething fun!");
		else
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("Vault is Empty");
		end
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Enable();
	end
	phaseVault.isSavingOrLoadingAddonData = false;
	phaseVault.isLoaded = false;
end

local function getSpellForgePhaseVault(callback)
	phaseVault.spells = {} -- reset the table
	dprint("Phase Spell Vault Loading...")

	--if phaseVault.isSavingOrLoadingAddonData then eprint("Arcaum is already loading or saving a spell. To avoid data corruption, you can't do that right now. Try again shortly."); return; end
	local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")
	phaseVault.isSavingOrLoadingAddonData = true
	phaseVault.isLoaded = false

	phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
	phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
		if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
			phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" )

			if (#text < 1 or text == "") then noSpellsToLoad(); return; end
			phaseVaultKeys = serializer.decompressForAddonMsg(text)
			if #phaseVaultKeys < 1 then noSpellsToLoad(); return; end
			dprint("Phase spell keys: ")
			Debug.ddump(phaseVaultKeys)
			local phaseVaultLoadingCount = 0
			local phaseVaultLoadingExpected = #phaseVaultKeys
			local messageTicketQueue = {}

			-- set up the phaseAddonDataListener2 ahead of time, and only once..
			phaseAddonDataListener2:RegisterEvent("CHAT_MSG_ADDON")
			phaseAddonDataListener2:SetScript("OnEvent", function (self, event, prefix, text, channel, sender, ...)
				if event == "CHAT_MSG_ADDON" and messageTicketQueue[prefix] and text then
					messageTicketQueue[prefix] = nil -- remove it from the queue.. We'll reset the table next time anyways but whatever.
					phaseVaultLoadingCount = phaseVaultLoadingCount+1
					local interAction = serializer.decompressForAddonMsg(text)
					dprint("Spell found & adding to Phase Vault Table: "..interAction.commID)
					tinsert(phaseVault.spells, interAction)
					--print("phaseVaultLoadingCount: ",phaseVaultLoadingCount," | phaseVaultLoadingExpected: ",phaseVaultLoadingExpected)
					if phaseVaultLoadingCount == phaseVaultLoadingExpected then
						dprint("Phase Vault Loading should be done")
						phaseAddonDataListener2:UnregisterEvent("CHAT_MSG_ADDON")
						phaseVault.isSavingOrLoadingAddonData = false
						phaseVault.isLoaded = true
						if callback then callback(true); end
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

	if phaseVault.isSavingOrLoadingAddonData then eprint("Arcaum is already loading or saving a spell. To avoid data corruption, you can't do that right now. Try again in a moment."); return; end

	phaseVault.isSavingOrLoadingAddonData = true
	sendPhaseVaultIOLock(true)
	local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")

	phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")

	phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
		if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
			phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" )
			phaseVaultKeys = serializer.decompressForAddonMsg(text)
			table.remove(phaseVaultKeys, commID)
			phaseVaultKeys = serializer.compressForAddonMsg(phaseVaultKeys)

			C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", phaseVaultKeys)
			local realCommID = savedSpellFromVault[commID].commID
			dprint("Removing PhaseAddonData for SCFORGE_S_"..realCommID)
			C_Epsilon.SetPhaseAddonData("SCFORGE_S_"..realCommID, "")

			phaseVault.isSavingOrLoadingAddonData = false
			sendPhaseVaultIOLock(false)
			if callback then callback(); end
		end
	end)
end

local function saveSpellToPhaseVault(commID, overwrite)
	local needToOverwrite = false
	if not commID then
		eprint("Invalid CommID.")
		return;
	end
	if phaseVault.isSavingOrLoadingAddonData then eprint("Arcaum is already loading or saving a spell. To avoid data corruption, you can't do that right now. Try again in a moment."); return; end
	if isMemberPlus() then
		dprint("Trying to save spell to phase vault.")

		local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")
		phaseVault.isSavingOrLoadingAddonData = true
		sendPhaseVaultIOLock(true)
		phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
		phaseAddonDataListener:SetScript("OnEvent", function( self, event, prefix, text, channel, sender, ... )
			if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
				phaseAddonDataListener:UnregisterEvent( "CHAT_MSG_ADDON" );

				--print(text)
				if (text ~= "" and #text > 0) then phaseVaultKeys = serializer.decompressForAddonMsg(text) else phaseVaultKeys = {} end

				dprint("Phase spell keys: ")
				Debug.ddump(phaseVaultKeys)

				for k,v in ipairs(phaseVaultKeys) do
					if v == commID then
						if not overwrite then
							-- phase already has this ID saved.. Handle over-write...
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

							phaseVault.isSavingOrLoadingAddonData = false
							sendPhaseVaultIOLock(false)
							return;
						else
							needToOverwrite = true
						end
					end
				end

				-- Passed checking for duplicates. NOW we can save it.
				local _spellData = SpellCreatorSavedSpells[commID]
				if LoadSpellFrame.getUploadToPhaseVisibility() == SPELL_VISIBILITY.PRIVATE then
					_spellData.private = true
				else
					_spellData.private = nil
				end
				local str = serializer.compressForAddonMsg(_spellData)

				local key = "SCFORGE_S_"..commID
				C_Epsilon.SetPhaseAddonData(key, str)

				if not needToOverwrite then
					tinsert(phaseVaultKeys, commID)
					phaseVaultKeys = serializer.compressForAddonMsg(phaseVaultKeys)
					C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", phaseVaultKeys)
				end

				cprint("Spell '"..commID.."' saved to the Phase Vault.")
				phaseVault.isSavingOrLoadingAddonData = false
				sendPhaseVaultIOLock(false)
				getSpellForgePhaseVault()
			end
		end)
	else
		eprint("You must be a member, officer, or owner in order to save spells to the phase.")
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
gossipAddMenuInsert:SetSize(300,68)
gossipAddMenuInsert:Hide()

gossipAddMenuInsert.vertDivLine = gossipAddMenuInsert:CreateTexture(nil, "ARTWORK")
	gossipAddMenuInsert.vertDivLine:SetPoint("TOP", -30, -4)
	gossipAddMenuInsert.vertDivLine:SetPoint("BOTTOM", -30, 18)
	gossipAddMenuInsert.vertDivLine:SetWidth(2)
	gossipAddMenuInsert.vertDivLine:SetColorTexture(1,1,1,0.2)

gossipAddMenuInsert.horizDivLine = gossipAddMenuInsert:CreateTexture(nil, "ARTWORK")
	gossipAddMenuInsert.horizDivLine:SetPoint("BOTTOMLEFT", 26, 16)
	gossipAddMenuInsert.horizDivLine:SetPoint("BOTTOMRIGHT", -26, 16)
	gossipAddMenuInsert.horizDivLine:SetHeight(2)
	gossipAddMenuInsert.horizDivLine:SetColorTexture(1,1,1,0.2)

gossipAddMenuInsert.hideButton = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
	gossipAddMenuInsert.hideButton:SetSize(26,26)
	gossipAddMenuInsert.hideButton:SetPoint("BOTTOM", -50, -12)
	gossipAddMenuInsert.hideButton.text:SetText("Hide after Casting")
	gossipAddMenuInsert.hideButton:SetHitRectInsets(0,-gossipAddMenuInsert.hideButton.text:GetWidth(),0,0)
	gossipAddMenuInsert.hideButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		self.Timer = C_Timer.NewTimer(0.7,function()
			GameTooltip:SetText("Hide the Gossip menu after Casting/Saving", nil, nil, nil, nil, true)
			GameTooltip:AddLine("\n\rFor On Click: The Gossip menu will close after you click, and then the spell will be casted or saved.",1,1,1,true)
			GameTooltip:AddLine("\nFor On Open: The Gossip menu will close immediately after opening, usually before it can be seen, and the spell will be casted or saved.",1,1,1,true)
			GameTooltip:Show()
		end)
	end)
	gossipAddMenuInsert.hideButton:SetScript("OnLeave", function(self)
		GameTooltip_Hide()
		self.Timer:Cancel()
	end)
	gossipAddMenuInsert.hideButton:SetScript("OnShow", function(self)
		self:SetChecked(false)
		self.text:SetText("Hide after Casting")
	end)

gossipAddMenuInsert.RadioOption = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
	gossipAddMenuInsert.RadioOption.text:SetText("..On Click (Option)")
	gossipAddMenuInsert.RadioOption:SetSize(26,26)
	gossipAddMenuInsert.RadioOption:SetChecked(true)
	gossipAddMenuInsert.RadioOption:SetHitRectInsets(0,-gossipAddMenuInsert.RadioOption.text:GetWidth(),0,0)
	gossipAddMenuInsert.RadioOption:SetPoint("TOPLEFT", gossipAddMenuInsert, "TOP", -13, 0)
	gossipAddMenuInsert.RadioOption.CheckedTex = gossipAddMenuInsert.RadioOption:GetCheckedTexture()
	gossipAddMenuInsert.RadioOption.CheckedTex:SetAtlas("common-checkbox-partial")
	gossipAddMenuInsert.RadioOption.CheckedTex:ClearAllPoints()
	gossipAddMenuInsert.RadioOption.CheckedTex:SetPoint("CENTER", -1, 0)
	gossipAddMenuInsert.RadioOption.CheckedTex:SetSize(12,12)
	gossipAddMenuInsert.RadioOption:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		self.Timer = C_Timer.NewTimer(0.7,function()
			GameTooltip:SetText("..On Click", nil, nil, nil, nil, true)
			GameTooltip:AddLine("\nAdds the ArcSpell & Tag to a Gossip Option. When that option is clicked, the spell will be cast.\n\rRequires Gossip Text, otherwise it's un-clickable.",1,1,1,true)
			GameTooltip:Show()
		end)
	end)
	gossipAddMenuInsert.RadioOption:SetScript("OnLeave", function(self)
		GameTooltip_Hide()
		self.Timer:Cancel()
	end)
	gossipAddMenuInsert.RadioOption:SetScript("OnShow", function(self)
		self:SetChecked(true)
	end)

gossipAddMenuInsert.RadioBody = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
	gossipAddMenuInsert.RadioBody.text:SetText("..On Open (Auto/Text)")
	gossipAddMenuInsert.RadioBody:SetSize(26,26)
	gossipAddMenuInsert.RadioBody:SetChecked(false)
	gossipAddMenuInsert.RadioBody:SetHitRectInsets(0,-gossipAddMenuInsert.RadioBody.text:GetWidth(),0,0)
	gossipAddMenuInsert.RadioBody:SetPoint("TOPLEFT", gossipAddMenuInsert.RadioOption, "BOTTOMLEFT", 0, 4)
	gossipAddMenuInsert.RadioBody.CheckedTex = gossipAddMenuInsert.RadioBody:GetCheckedTexture()
	gossipAddMenuInsert.RadioBody.CheckedTex:SetAtlas("common-checkbox-partial")
	gossipAddMenuInsert.RadioBody.CheckedTex:ClearAllPoints()
	gossipAddMenuInsert.RadioBody.CheckedTex:SetPoint("CENTER", -1, 0)
	gossipAddMenuInsert.RadioBody.CheckedTex:SetSize(12,12)
	gossipAddMenuInsert.RadioBody:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		self.Timer = C_Timer.NewTimer(0.7,function()
			GameTooltip:SetText("..On Open (Auto)", nil, nil, nil, nil, true)
			GameTooltip:AddLine("\nAdds the ArcSpell & Tag to the Gossip main menu, casting them atuotmaically from the Phase Vault when it is shown.\n\rDoes not require Gossip Text, you can add a tag without any additional text.",1,1,1,true)
			GameTooltip:Show()
		end)
	end)
	gossipAddMenuInsert.RadioBody:SetScript("OnLeave", function(self)
		GameTooltip_Hide()
		self.Timer:Cancel()
	end)
	gossipAddMenuInsert.RadioBody:SetScript("OnShow", function(self)
		self:SetChecked(false)
	end)

gossipAddMenuInsert.RadioOption:SetScript("OnClick", function(self)
	self:SetChecked(true)
	gossipAddMenuInsert.RadioBody:SetChecked(false)
	local parent = self:GetParent():GetParent()
	if #parent.editBox:GetText() > 0 then
		parent.button1:Enable()
	else
		parent.button1:Disable()
	end
end)
gossipAddMenuInsert.RadioBody:SetScript("OnClick", function(self)
	self:SetChecked(true)
	gossipAddMenuInsert.RadioOption:SetChecked(false)
	self:GetParent():GetParent().button1:Enable()
end)


gossipAddMenuInsert.RadioCast = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
	gossipAddMenuInsert.RadioCast.text:SetText("Cast Spell")
	gossipAddMenuInsert.RadioCast:SetSize(26,26)
	gossipAddMenuInsert.RadioCast:SetChecked(true)
	gossipAddMenuInsert.RadioCast:SetHitRectInsets(0,-gossipAddMenuInsert.RadioCast.text:GetWidth(),0,0)
	gossipAddMenuInsert.RadioCast:SetPoint("TOPLEFT", 26, 0)
	gossipAddMenuInsert.RadioCast.CheckedTex = gossipAddMenuInsert.RadioCast:GetCheckedTexture()
	gossipAddMenuInsert.RadioCast.CheckedTex:SetAtlas("common-checkbox-partial")
	gossipAddMenuInsert.RadioCast.CheckedTex:ClearAllPoints()
	gossipAddMenuInsert.RadioCast.CheckedTex:SetPoint("CENTER", -1, 0)
	gossipAddMenuInsert.RadioCast.CheckedTex:SetSize(12,12)
	gossipAddMenuInsert.RadioCast:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		self.Timer = C_Timer.NewTimer(0.7,function()
			GameTooltip:SetText("Cast Spell", nil, nil, nil, nil, true)
			GameTooltip:AddLine("\nCasts the ArcSpell from the Phase Vault.",1,1,1,true)
			GameTooltip:Show()
		end)
	end)
	gossipAddMenuInsert.RadioCast:SetScript("OnLeave", function(self)
		GameTooltip_Hide()
		self.Timer:Cancel()
	end)
	gossipAddMenuInsert.RadioCast:SetScript("OnShow", function(self)
		self:SetChecked(true)
	end)

gossipAddMenuInsert.RadioSave = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
	gossipAddMenuInsert.RadioSave.text:SetText("Save Spell")
	gossipAddMenuInsert.RadioSave:SetSize(26,26)
	gossipAddMenuInsert.RadioSave:SetChecked(false)
	gossipAddMenuInsert.RadioSave:SetHitRectInsets(0,-gossipAddMenuInsert.RadioSave.text:GetWidth(),0,0)
	gossipAddMenuInsert.RadioSave:SetPoint("TOPLEFT", gossipAddMenuInsert.RadioCast, "BOTTOMLEFT", 0, 4)
	gossipAddMenuInsert.RadioSave.CheckedTex = gossipAddMenuInsert.RadioSave:GetCheckedTexture()
	gossipAddMenuInsert.RadioSave.CheckedTex:SetAtlas("common-checkbox-partial")
	gossipAddMenuInsert.RadioSave.CheckedTex:ClearAllPoints()
	gossipAddMenuInsert.RadioSave.CheckedTex:SetPoint("CENTER", -1, 0)
	gossipAddMenuInsert.RadioSave.CheckedTex:SetSize(12,12)
	gossipAddMenuInsert.RadioSave:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		self.Timer = C_Timer.NewTimer(0.7,function()
			GameTooltip:SetText("Save Spell from Phase Vault", nil, nil, nil, nil, true)
			GameTooltip:AddLine("\nSaves the ArcSpell, from the Phase Vault, to the player's Personal Vault.",1,1,1,true)
			GameTooltip:Show()
		end)
	end)
	gossipAddMenuInsert.RadioSave:SetScript("OnLeave", function(self)
		GameTooltip_Hide()
		self.Timer:Cancel()
	end)
	gossipAddMenuInsert.RadioSave:SetScript("OnShow", function(self)
		self:SetChecked(false)
	end)

gossipAddMenuInsert.RadioCast:SetScript("OnClick", function(self)
	self:SetChecked(true)
	gossipAddMenuInsert.RadioSave:SetChecked(false)
	gossipAddMenuInsert.hideButton.text:SetText("Hide after Casting")
end)
gossipAddMenuInsert.RadioSave:SetScript("OnClick", function(self)
	self:SetChecked(true)
	gossipAddMenuInsert.RadioCast:SetChecked(false)
	gossipAddMenuInsert.hideButton.text:SetText("Hide after Saving")
end)

------------------------
local exportMenuFrame = CreateFrame("Frame")
exportMenuFrame:SetSize(350,120)
exportMenuFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, exportMenuFrame, "InputScrollFrameTemplate")
exportMenuFrame.ScrollFrame.CharCount:Hide()
exportMenuFrame.ScrollFrame:SetSize(350,100)
exportMenuFrame.ScrollFrame:SetPoint("CENTER")
exportMenuFrame.ScrollFrame.EditBox:SetWidth(exportMenuFrame.ScrollFrame:GetWidth()-18)
exportMenuFrame.ScrollFrame.EditBox:SetScript("OnEscapePressed", function(self) self:GetParent():GetParent():GetParent():Hide(); end)
exportMenuFrame:Hide();

StaticPopupDialogs["SCFORGE_EXPORT_SPELL"] = {
	text = "ArcSpell Export: %s",
	subText = "CTRL+C to Copy",
	closeButton = true,
	enterClicksFirstButton = true,
	button1 = DONE,
	hideOnEscape = true,
	whileDead = true,
}

-- Import Menu table moved below SaveSpell...

local function showExportMenu(spellName, data)
	local dialog = StaticPopup_Show("SCFORGE_EXPORT_SPELL", spellName, nil, nil, exportMenuFrame)
	dialog.insertedFrame.ScrollFrame.EditBox:SetText(data);
	dialog.insertedFrame.ScrollFrame.EditBox:SetFocus();
	dialog.insertedFrame.ScrollFrame.EditBox:HighlightText();
end

local function showImportMenu()
	local dialog = StaticPopup_Show("SCFORGE_IMPORT_SPELL", nil, nil, nil, exportMenuFrame)
	dialog.insertedFrame.ScrollFrame.EditBox:SetText("");
	dialog.insertedFrame.ScrollFrame.EditBox:SetFocus();
end

local baseVaultFilterTags = {
	"Macro", "Utility", "Morph", "Animation", "Teleport", "Quest", "Fun", "Officer+", "Gossip", "Spell",
}

local function editVaultTags( tag, spellCommID, vaultType ) --
	--print(spellCommID, tag)
	if not tag and not spellCommID then return; end
	if not vaultType then vaultType = 1 end
	if vaultType == 1 then
		if not SpellCreatorSavedSpells[spellCommID].tags then SpellCreatorSavedSpells[spellCommID].tags = {} end
		if SpellCreatorSavedSpells[spellCommID].tags[tag] then SpellCreatorSavedSpells[spellCommID].tags[tag] = nil else SpellCreatorSavedSpells[spellCommID].tags[tag] = true end
		--print(SpellCreatorSavedSpells[spellCommID].tags[tag])
	end
end

local function setSpellProfile(spellCommID, profileName, vaultType, callback)
	if not vaultType then vaultType = 1 end
	if not spellCommID then return; end
	if not profileName then
		StaticPopupDialogs["SCFORGE_NEW_PROFILE"] = {
			text = "Assign to new Profile",
			subText = "Assigning ArcSpell: '"..savedSpellFromVault[spellCommID].fullName.."'",
			closeButton = true,
			hasEditBox = true,
			enterClicksFirstButton = true,
			editBoxInstructions = "New Profile Name",
			--editBoxWidth = 310,
			maxLetters = 50,
			OnButton1 = function(self, data)
				local text = self.editBox:GetText();
				setSpellProfile(data.comm, text, data.vault, data.callback )
			end,
			EditBoxOnTextChanged = function (self)
				local text = self:GetText();
				if #text > 0 and text ~= "" then
					self:GetParent().button1:Enable()
				else
					self:GetParent().button1:Disable()
				end
			end,

			button1 = ADD,
			button2 = CANCEL,
			hideOnEscape = true,
			EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end,
			EditBoxOnEnterPressed = function(self)
				local parent = self:GetParent();
				if parent.button1:IsEnabled() then
					parent.button1:Click()
				end
			end,
			whileDead = true,
			OnShow = function (self, data)
				self.button1:Disable()
			end,
		}
		local dialog = StaticPopup_Show("SCFORGE_NEW_PROFILE")
		dialog.data = {comm = spellCommID, vault = vaultType, callback = callback}
		return;
	end
	if vaultType == 1 then
		SpellCreatorSavedSpells[spellCommID].profile = profileName
	end
	if callback then
		callback()
	end
end

local contextDropDownMenu = CreateFrame("BUTTON", "ARCLoadRowContextMenu", UIParent, "UIDropDownMenuTemplate")
local profileDropDownMenu = CreateFrame("BUTTON", "ARCProfileContextMenu", UIParent, "UIDropDownMenuTemplate")

---@param vault VaultType
---@param spellCommID CommID
local function genDropDownContextOptions(vault, spellCommID, callback)
	local menuList = {}
	local item
	local playerName = GetUnitName("player")
	local _profile
	if vault == VAULT_TYPE.PHASE then
		menuList = {
			{text = phaseVault.spells[spellCommID].fullName, notCheckable = true, isTitle=true},
			{text = "Cast", notCheckable = true, func = function() executeSpell(phaseVault.spells[spellCommID].actions, nil, phaseVault.spells[spellCommID].fullName, phaseVault.spells[spellCommID]) end},
			{text = "Edit", notCheckable = true, func = function() loadSpell(phaseVault.spells[spellCommID]) end},
			{text = "Transfer", tooltipTitle="Transfer to Personal Vault", tooltipOnButton=true, notCheckable = true, func = function() saveSpell(nil, spellCommID) end},
		}
		item = {text = "Add to Gossip", notCheckable = true, func = function() _G["scForgeLoadRow"..spellCommID].gossipButton:Click() end}
		if not isGossipLoaded then item.disabled = true; item.text = "(Open a Gossip Menu)"; end
		tinsert(menuList, item)
	else
		_profile = SpellCreatorSavedSpells[spellCommID].profile
		menuList = {
			{text = SpellCreatorSavedSpells[spellCommID].fullName, notCheckable = true, isTitle=true},
			{text = "Cast", notCheckable = true, func = function() ARC:CAST(spellCommID) end},
			{text = "Edit", notCheckable = true, func = function() loadSpell(savedSpellFromVault[spellCommID]) end},
			{text = "Transfer", tooltipTitle="Transfer to Phase Vault", tooltipOnButton=true, notCheckable = true, func = function() saveSpellToPhaseVault(spellCommID) end},
		}

		-- Profiles Menu
		item = {text = "Profile", notCheckable=true, hasArrow=true, keepShownOnClick=true,
			menuList = {
				{ text = "Account", isNotRadio = (_profile=="Account"), checked = (_profile=="Account"), disabled = (_profile=="Account"), disablecolor = ((_profile=="Account") and "|cFFCE2EFF" or nil), func = function() setSpellProfile(spellCommID, "Account", 1, callback); CloseDropDownMenus(); end },
				{ text = playerName, isNotRadio = (_profile==playerName), checked = (_profile==playerName), disabled = (_profile==playerName), disablecolor = ((_profile==playerName) and "|cFFCE2EFF" or nil), func = function() setSpellProfile(spellCommID, playerName, 1, callback); CloseDropDownMenus(); end },
			},
		}

		local profileNames = SavedVariables.getProfileNames(true, true)
		sort(profileNames)

		for _, profileName in ipairs(profileNames) do
			item.menuList[#item.menuList+1] = {
				text = profileName,
				isNotRadio = (_profile == profileName),
				checked = (_profile == profileName),
				disabled = (_profile == profileName),
				disablecolor = ((_profile == profileName) and "|cFFCE2EFF" or nil),
				func = function()
					setSpellProfile(spellCommID, profileName, 1, callback)
					CloseDropDownMenus()
				end
			}
		end

		item.menuList[#item.menuList+1] = { text = "Add New", fontObject=GameFontNormalSmallLeft, func = function() setSpellProfile(spellCommID, nil, nil, callback); CloseDropDownMenus(); end }

		tinsert(menuList, item)

		-- Tags Menu
		--[[
		item = {text = "Edit Tags", notCheckable=true, hasArrow=true, keepShownOnClick=true,
			menuList = {}
		}
		for k,v in ipairs(baseVaultFilterTags) do
			interTagTable[v] = false
		end
		if SpellCreatorSavedSpells[spellCommID].tags then
			for k,v in pairs(SpellCreatorSavedSpells[spellCommID].tags) do
				interTagTable[k] = true
			end
		end
		for k,v in orderedPairs(interTagTable) do
			tinsert(item.menuList, { text = k, checked = v, keepShownOnClick=true, func = function(self) editVaultTags(k, spellCommID, 1); end })
		end
		--tinsert(item.menuList, { })
		--tinsert(item.menuList, { text = "Add New", })
		tinsert(menuList, item)
		--]]
		if tContains(SpellCreatorMasterTable.quickCastSpells, spellCommID) then
			menuList[#menuList+1] = {text = "Remove from QuickCast", notCheckable = true, func = function()
				tDeleteItem(SpellCreatorMasterTable.quickCastSpells, spellCommID);
				Quickcast.hideCastCuttons()
			end}
		else
			menuList[#menuList+1] = {text = "Add to QuickCast", notCheckable = true, func = function()
				tinsert(SpellCreatorMasterTable.quickCastSpells, spellCommID);
			end}
		end

		--[[
		menuList[#menuList+1] = {text = "Link Hotkey", notCheckable = true, func = function()
			ChatLink.linkSpell(savedSpellFromVault[spellCommID], vault)
		end}
		--]]
	end

	menuList[#menuList+1] = {text = "Chatlink", notCheckable = true, func = function()
		ChatLink.linkSpell(savedSpellFromVault[spellCommID], vault)
	end}
	menuList[#menuList+1] = {text = "Export", notCheckable = true, func = function()
		local exportData = savedSpellFromVault[spellCommID]
		showExportMenu(savedSpellFromVault[spellCommID].commID, savedSpellFromVault[spellCommID].commID..":"..serializer.compressForExport(exportData))
	end}


	return menuList
end

------------------------

local load_row_background = ASSETS_PATH.."/SpellForgeVaultPanelRow"

local loadRowHeight = 45
local loadRowSpacing = 5
local function updateSpellLoadRows(fromPhaseDataLoaded)
	spellLoadRows = SCForgeMainFrame.LoadSpellFrame.Rows
	for i = 1, #spellLoadRows do
		spellLoadRows[i]:Hide()
		spellLoadRows[i]:SetChecked(false)
	end
	LoadSpellFrame.selectRow(nil)
	savedSpellFromVault = {}
	local currentVault = LoadSpellFrame.getCurrentVault()

	if currentVault == VAULT_TYPE.PERSONAL then
		savedSpellFromVault = SpellCreatorSavedSpells
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Hide()
		SCForgeMainFrame.LoadSpellFrame.profileButton:Show()
		SCForgeMainFrame.LoadSpellFrame.TitleBgColor:SetColorTexture(0.30,0.10,0.40,0.5)
		SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Show()
		SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Disable()
		SCForgeMainFrame.LoadSpellFrame.ImportSpellButton:Show()
		SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:Hide()
		if next(savedSpellFromVault) == nil then
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("Vault is Empty")
		else
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("")
		end
	elseif currentVault == VAULT_TYPE.PHASE then
		SCForgeMainFrame.LoadSpellFrame.profileButton:Hide()
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Show()
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Disable()
		--SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.animations:Play() -- not a fan of it playing here lol
		SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Hide()
		SCForgeMainFrame.LoadSpellFrame.ImportSpellButton:Hide()
		SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:Show()
		SCForgeMainFrame.LoadSpellFrame.TitleBgColor:SetColorTexture(0.20,0.40,0.50,0.5)
		if fromPhaseDataLoaded then
			-- called from getSpellForgePhaseVault() - that means our saved spell from Vault is ready -- you can call with true also to skip loading the vault, if you know it's already loaded.
			savedSpellFromVault = phaseVault.spells
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
		rowNum = rowNum + 1

		if currentVault == VAULT_TYPE.PERSONAL then
			ProfileFilter.ensureProfile(v)
		end

		if currentVault == VAULT_TYPE.PERSONAL and ProfileFilter.shouldFilterFromPersonalVault(v) then
			dprint("Load Row Filtered from Personal Vault Profiles (skipped): "..k)
			rowNum = rowNum-1
		else
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
				thisRow.spellName:SetWidth((columnWidth*2/3)-15)
				thisRow.spellName:SetJustifyH("LEFT")
				thisRow.spellName:SetPoint("LEFT", 25, 0)
				thisRow.spellName:SetText(v.fullName) -- initial text, reset later when it needs updated
				thisRow.spellName:SetShadowColor(0, 0, 0)
				thisRow.spellName:SetMaxLines(3) -- hardlimit to 3 lines, but soft limit to 2 later.
				--thisRow.spellNameBackground:SetPoint("RIGHT", thisRow.spellName, "RIGHT", 0, 0) -- move the right edge of the gradient to the right edge of the name

				thisRow.spellIcon = CreateFrame("BUTTON", nil, thisRow)
				local button = thisRow.spellIcon
					button.commID = k
					button:SetPoint("RIGHT", thisRow.spellName, "LEFT", -2, 0)
					button:SetSize(24,24)
					button:SetNormalTexture("Interface/Icons/inv_misc_questionmark")
					button:SetHighlightTexture(ASSETS_PATH .. "/dm-trait-select")
					button.highlight = button:GetHighlightTexture()
					button.highlight:SetPoint("TOPLEFT", -3, 3)
					button.highlight:SetPoint("BOTTOMRIGHT", 3, -3)
					button.border = button:CreateTexture(nil, "OVERLAY")
					button.border:SetTexture(ASSETS_PATH .. "/dm-trait-border")
					button.border:SetPoint("TOPLEFT", -4, 4)
					button.border:SetPoint("BOTTOMRIGHT", 4, -4)
					button:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_LEFT")
						self.Timer = C_Timer.NewTimer(0.7,function()
							GameTooltip:SetText(savedSpellFromVault[self.commID].fullName, nil, nil, nil, nil, true)
							if savedSpellFromVault[self.commID].description then
								GameTooltip:AddLine(savedSpellFromVault[self.commID].description, 1, 1, 1, 1)
							end
							GameTooltip:AddLine(" ", 1, 1, 1, 1)
							--GameTooltip:AddLine("Command: '/sf "..v.commID.."'", 1, 1, 1, 1)
							GameTooltip:AddLine("Click to cast '"..savedSpellFromVault[self.commID].commID.."'", 1, 1, 1, 1)
							GameTooltip:AddLine("Actions: "..#savedSpellFromVault[self.commID].actions, 1, 1, 1, 1)
							GameTooltip:AddLine(" ", 1, 1, 1, 1)
							GameTooltip:AddLine("Shift-Click to link in chat & share with other players.", 1, 1, 1, 1)
							GameTooltip:Show()
						end)
					end)
					button:SetScript("OnLeave", function(self)
						GameTooltip_Hide()
						self.Timer:Cancel()
					end)
					button:SetScript("OnClick", function(self, button)
						local currentVault = LoadSpellFrame.getCurrentVault()
						if button == "LeftButton" then
							if IsModifiedClick("CHATLINK") then
								ChatLink.linkSpell(savedSpellFromVault[self.commID], currentVault)
								return;
							end
							if currentVault == VAULT_TYPE.PHASE then
								executeSpell(phaseVault.spells[self.commID].actions, nil, phaseVault.spells[self.commID].fullName, phaseVault.spells[self.commID])
							else
								ARC:CAST(self.commID)
							end
						elseif button == "RightButton" then
							--Show & Update Right-Click Context Menu
							EasyMenu(genDropDownContextOptions(currentVault, self.commID, updateSpellLoadRows), contextDropDownMenu, "cursor", 0 , 0, "MENU");
						end
					end)
					button:RegisterForClicks("LeftButtonUp","RightButtonUp")

				-- Make the delete saved spell button
				thisRow.deleteButton = CreateFrame("BUTTON", nil, thisRow)
				local button = thisRow.deleteButton
					button.commID = k
					button:SetPoint("RIGHT", 0, 0)
					button:SetSize(24,24)
					--button:SetText("x")

					button:SetNormalTexture(ADDON_PATH.."/assets/icon-x")
					button:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

					button.DisabledTex = button:CreateTexture(nil, "ARTWORK")
					button.DisabledTex:SetAllPoints(true)
					button.DisabledTex:SetTexture(ADDON_PATH.."/assets/icon-x")
					button.DisabledTex:SetDesaturated(true)
					button.DisabledTex:SetVertexColor(.6,.6,.6)
					button:SetDisabledTexture(button.DisabledTex)

					button.PushedTex = button:CreateTexture(nil, "ARTWORK")
					button.PushedTex:SetAllPoints(true)
					button.PushedTex:SetTexture(ADDON_PATH.."/assets/icon-x")
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

					button:SetNormalTexture(ADDON_PATH.."/assets/icon-edit")
					button:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

					button.DisabledTex = button:CreateTexture(nil, "ARTWORK")
					button.DisabledTex:SetAllPoints(true)
					button.DisabledTex:SetTexture(ADDON_PATH.."/assets/icon-edit")
					button.DisabledTex:SetDesaturated(true)
					button.DisabledTex:SetVertexColor(.6,.6,.6)
					button:SetDisabledTexture(button.DisabledTex)

					button.PushedTex = button:CreateTexture(nil, "ARTWORK")
					button.PushedTex:SetAllPoints(true)
					button.PushedTex:SetTexture(ADDON_PATH.."/assets/icon-edit")
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
					end)
					button:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_LEFT")
						self.Timer = C_Timer.NewTimer(0.7,function()
							GameTooltip:SetText("Load '"..savedSpellFromVault[self.commID].commID.."'", nil, nil, nil, nil, true)
							GameTooltip:AddLine("Load the spell into the Forge UI so you can edit it.", 1,1,1,1)
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
							text = "Add ArcSpell to NPC Gossip",
							subText = "ArcSpell: '"..savedSpellFromVault[self.commID].fullName.."' ("..savedSpellFromVault[self.commID].commID..")",
							closeButton = true,
							hasEditBox = true,
							enterClicksFirstButton = true,
							editBoxInstructions = "Gossip Text (i.e., 'Cast the Spell!')",
							editBoxWidth = 310,
							maxLetters = 255-25-20-#savedSpellFromVault[self.commID].commID, -- 255 minus 25 for the max <arcanum> tag size, minus '.ph fo np go op ad ' size, minus spellCommID size.
							EditBoxOnTextChanged = function (self, data)
								local text = self:GetText();
								if #text > 0 and text ~= "" then
									self:GetParent().button1:Enable()
								else
									self:GetParent().button1:Disable()
								end
							end,
							OnButton1 = function(self, data)
								local text = self.editBox:GetText();
								local tag = "<arc_"
								if self.insertedFrame.RadioCast:GetChecked() then tag = tag.."cast"; elseif self.insertedFrame.RadioSave:GetChecked() then tag = tag.."save"; end
								if self.insertedFrame.hideButton:GetChecked() then tag = tag.."_hide" end
								tag = tag..":"
								local command
								if self.insertedFrame.RadioOption:GetChecked() then command = "ph fo np go op ad "; elseif self.insertedFrame.RadioBody:Getchecked() then command = "ph fo np go te ad "; end

								local finalCommand = command..text.." "..tag..savedSpellFromVault[data].commID..">"
								cmd(finalCommand)

								--if self.insertedFrame.hideButton:GetChecked() then cmd("ph fo np go op ad "..text.."<arcanum_cast_hide:"..savedSpellFromVault[data].commID..">") else cmd("ph fo np go op ad "..text.."<arcanum_cast:"..savedSpellFromVault[data].commID..">") end
								--savedSpellFromVault[data].commID
							end,
							button1 = ADD,
							button2 = CANCEL,
							hideOnEscape = true,
							EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end,
							whileDead = true,
							OnShow = function (self, data)
								self.button1:Disable()
							end,
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
					button:SetNormalTexture(ADDON_PATH.."/assets/icon_visible_32")
					button.normal = button:GetNormalTexture()
					button.normal:SetVertexColor(0.9,0.65,0)
					--button:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

					button.DisabledTex = button:CreateTexture(nil, "ARTWORK")
					button.DisabledTex:SetAllPoints(true)
					--button.DisabledTex:SetAtlas("transmog-icon-hidden")
					button.DisabledTex:SetTexture(ADDON_PATH.."/assets/icon_hidden_32")
					--button.DisabledTex:SetDesaturated(true)
					button.DisabledTex:SetVertexColor(.6,.6,.6)
					button:SetDisabledTexture(button.DisabledTex)

					button:SetMotionScriptsWhileDisabled(true)

					button:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_LEFT")
						self.Timer = C_Timer.NewTimer(0.7,function()
							if self:IsEnabled() then
								GameTooltip:SetText("'"..savedSpellFromVault[self.commID].fullName.."' is visible to everyone", nil, nil, nil, nil, true)
							else
								GameTooltip:SetText("'"..savedSpellFromVault[self.commID].fullName.."' is visible only to Officers+", nil, nil, nil, nil, true)
							end
							GameTooltip:AddLine("\nTo change this spells privacy, please re-upload it with the privacy desired.", 1,1,1,1)
							GameTooltip:Show()
						end)
					end)
					button:SetScript("OnLeave", function(self)
						GameTooltip_Hide()
						self.Timer:Cancel()
					end)

			end

			-- Set the buttons stuff
			do
				-- make sure to set the data, otherwise it will still use old data if new spells have been saved since last.
				thisRow.spellName:SetText(v.fullName)
				thisRow.loadButton.commID = k
				thisRow.deleteButton.commID = k
				thisRow.gossipButton.commID = k
				thisRow.privateIconButton.commID = k
				thisRow.spellIcon.commID = k
				thisRow.commID = k -- used in new Transfer to Phase Button - all the other ones should probably move to using this anyways..
				thisRow.rowID = rowNum

				if v.icon then
					dprint(nil, Icons.getFinalIcon(v.icon))
					thisRow.spellIcon:SetNormalTexture(Icons.getFinalIcon(v.icon))
				else
					thisRow.spellIcon:SetNormalTexture("Interface/Icons/inv_misc_questionmark")
				end
				thisRow.deleteButton:SetScript("OnClick", function(self, button)
					if button == "LeftButton" then
						deleteSpellConf(self.commID, LoadSpellFrame.getCurrentVault())
					elseif button == "RightButton" then

					end
				end)

				-- NEED TO UPDATE THE ROWS IF WE ARE IN PHASE VAULT
				if currentVault == VAULT_TYPE.PERSONAL then
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
					if isMemberPlus() then
						thisRow.saveToPhaseButton:Show()
					else
						thisRow.saveToPhaseButton:Hide()
					end
					--]]

				elseif currentVault == VAULT_TYPE.PHASE then
					--thisRow.loadButton:SetText("Load")
					--thisRow.saveToPhaseButton:Hide()
					--thisRow.Background:SetVertexColor(0.73,0.63,0.8)
					--thisRow.Background:SetTexCoord(0,1,0,1)
					--thisRow.BGOverlay:SetAtlas("Garr_FollowerToast-Epic")

					if isMemberPlus() then
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
						if SpellCreatorMasterTable.Options["debug"] then thisRow.privateIconButton:Show() else thisRow.privateIconButton:Hide() end
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
				thisRow:SetScript("OnClick", function(self, button)
					local currentVault = LoadSpellFrame.getCurrentVault()
					if button == "LeftButton" then
						if IsModifiedClick("CHATLINK") then
							ChatLink.linkSpell(savedSpellFromVault[k], currentVault)
							self:SetChecked(not self:GetChecked());
							return;
						end
						clearSpellLoadRadios(self)
						if self:GetChecked() then
							LoadSpellFrame.selectRow(self.rowID)
						else
							LoadSpellFrame.selectRow(nil)
						end
					elseif button == "RightButton" then
						--Show & Update Right-Click Context Menu
						EasyMenu(genDropDownContextOptions(currentVault, self.commID, updateSpellLoadRows), contextDropDownMenu, "cursor", 0 , 0, "MENU");
						self:SetChecked( not self:GetChecked() )
					end
				end)
				thisRow:RegisterForClicks("LeftButtonUp","RightButtonUp")
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

			if currentVault == VAULT_TYPE.PHASE and v.private and not (isOfficerPlus() or SpellCreatorMasterTable.Options["debug"]) then
				thisRow:Hide()
				numSkippedRows = numSkippedRows+1
			end
			if v.private then
				thisRow.privateIconButton:Disable()
			else
				thisRow.privateIconButton:Enable()
			end
		end
	end
	MainFrame.updateFrameChildScales(SCForgeMainFrame)
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
		if data2 == VAULT_TYPE.PERSONAL then
			deleteSpell(data)
		elseif data2 == VAULT_TYPE.PHASE then
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

saveSpell = function (mousebutton, fromPhaseVaultID, manualData)

	local wasOverwritten = false
	local newSpellData = {}
	if fromPhaseVaultID then
		newSpellData.commID = phaseVault.spells[fromPhaseVaultID].commID
		newSpellData.fullName = phaseVault.spells[fromPhaseVaultID].fullName
		newSpellData.description = phaseVault.spells[fromPhaseVaultID].description or nil
		newSpellData.actions = phaseVault.spells[fromPhaseVaultID].actions
		newSpellData.castbar = phaseVault.spells[fromPhaseVaultID].castbar
		newSpellData.icon = phaseVault.spells[fromPhaseVaultID].icon
		dprint("Saving Spell from Phase Vault, fake commID: "..fromPhaseVaultID..", real commID: "..newSpellData.commID)
	elseif manualData then
		newSpellData = manualData
		Debug.dump(manualData)
		dprint("Saving Manual Spell Data (Import): "..newSpellData.commID)
	else
		newSpellData = Attic.getInfo()
		if newSpellData.castbar == 1 then newSpellData.castbar = nil end; -- data space saving - default is castbar, so if it's 1 for castbar, let's save the storage and leave it nil
		newSpellData.actions = {}
	end

	ProfileFilter.ensureProfile(newSpellData)

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
					OnAccept = function() saveSpell("RightButton", (fromPhaseVaultID and fromPhaseVaultID or nil), (manualData and manualData or nil)) end,
					button1 = "Overwrite",
					button2 = "Cancel",
					hideOnEscape = true,
					whileDead = true,
				}
				StaticPopup_Show("SCFORGE_CONFIRM_OVERWRITE")
				return;
			end
		end

	if not fromPhaseVaultID and not manualData then
		for i = 1, SpellRow.getNumActiveRows() do
			local rowData = SpellRow.getRowAction(i)

			if rowData and rowData.delay >= 0 then
				if actionTypeData[rowData.actionType] then
					table.insert(newSpellData.actions, CopyTable(rowData))
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
		SpellCreatorSavedSpells[newSpellData.commID] = newSpellData
		if wasOverwritten then
			cprint("Over-wrote spell with name: "..newSpellData.fullName..". Use command: '/sf "..newSpellData.commID.."' to cast it! ("..#newSpellData.actions.." actions).")
		else
			cprint("Saved spell with name: "..newSpellData.fullName..". Use command: '/sf "..newSpellData.commID.."' to cast it! ("..#newSpellData.actions.." actions).")
		end
	else
		cprint("Spell has no valid actions and was not saved. Please double check your actions & try again. You can turn on debug mode to see more information when trying to save (/sfdebug).")
	end
	if not fromPhaseVaultID then
		updateSpellLoadRows()
	end
end

SCForgeMainFrame.SaveSpellButton = CreateFrame("BUTTON", nil, SCForgeMainFrame, "UIPanelButtonTemplate")
SCForgeMainFrame.SaveSpellButton:SetPoint("BOTTOMLEFT", 20, 3)
SCForgeMainFrame.SaveSpellButton:SetSize(24*4,24)
SCForgeMainFrame.SaveSpellButton:SetText(BATTLETAG_CREATE)
SCForgeMainFrame.SaveSpellButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
SCForgeMainFrame.SaveSpellButton:SetScript("OnClick", function(self, button)
	Animation.setFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 3, nil, nil, 0.05, 0.8)
	saveSpell(button)
	C_Timer.After(1, function() Animation.stopFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 0.05, 0.25) end)
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

StaticPopupDialogs["SCFORGE_IMPORT_SPELL"] = {
	text = "ArcSpell Import",
	subText = "CTRL+V to Paste",
	closeButton = true,
	enterClicksFirstButton = true,
	button1 = "Import",
	OnButton1 = function(self)
		local text = self.insertedFrame.ScrollFrame.EditBox:GetText();
		if not text then return; end
		local text, rest = strsplit(":", text, 2)
		local spellData
		if text and rest and rest ~= "" then
			spellData = serializer.decompressForImport(rest)
		elseif text ~= "" then
			spellData = serializer.decompressForImport(text)
		else
			dprint("Invalid ArcSpell data. Try again."); return;
		end
		if spellData and spellData ~= "" then saveSpell(nil, nil, spellData) end
	end,
	hideOnEscape = true,
	whileDead = true,
}

SCForgeMainFrame.OpenVaultButton = CreateFrame("BUTTON", nil, SCForgeMainFrame, "UIPanelButtonTemplate")
SCForgeMainFrame.OpenVaultButton:SetPoint("LEFT", SCForgeMainFrame.SaveSpellButton, "RIGHT", 0, 0)
SCForgeMainFrame.OpenVaultButton:SetSize(24*4,24)
SCForgeMainFrame.OpenVaultButton:SetText("Vault")
SCForgeMainFrame.OpenVaultButton:SetScript("OnClick", function()
	if SCForgeMainFrame.LoadSpellFrame:IsShown() then
		SCForgeMainFrame.LoadSpellFrame:Hide()
	else
		SCForgeMainFrame.LoadSpellFrame:Show()
	end
end)
SCForgeMainFrame.OpenVaultButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	self.Timer = C_Timer.NewTimer(0.7,function()
		GameTooltip:SetText("Access your Vaults", nil, nil, nil, nil, true)
		GameTooltip:AddLine("You can load, edit, and manage all of your created/saved ArcSpells from the Personal Vault.\n\rThe Phase Vault can also be accessed here for any ArcSpells saved to the phase.",1,1,1,true)
		GameTooltip:Show()
	end)
end)
SCForgeMainFrame.OpenVaultButton:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.Timer:Cancel()
end)

--------- Load Spell Frame - aka the Vault


SCForgeMainFrame.LoadSpellFrame = LoadSpellFrame.init({
	import = showImportMenu,
	upload = function(commID)
		saveSpellToPhaseVault(commID, IsShiftKeyDown())
	end,
	downloadToPersonal = function (commID)
		Debug.ddump(phaseVault.spells[commID]) -- Dump the table of the phase vault spell for debug
		saveSpell(nil, commID)
	end
})

SCForgeMainFrame.LoadSpellFrame:Hide()
SCForgeMainFrame.LoadSpellFrame.Rows = {}
SCForgeMainFrame.LoadSpellFrame:HookScript("OnShow", function()
	dprint("Updating Spell Load Rows")
	updateSpellLoadRows(phaseVault.isLoaded)
end)

SCForgeMainFrame.LoadSpellFrame.spellVaultFrame = SpellVaultFrame.init(SCForgeMainFrame.LoadSpellFrame)

MainFrame.setResizeWithMainFrame(SCForgeMainFrame.LoadSpellFrame.spellVaultFrame)

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
		updateSpellLoadRows(phaseVault.isLoaded)
	end)
	button:SetScript("OnShow", function(self)
		self.Text:SetText(self.text)
		self.HighlightTexture:SetWidth(self:GetTextWidth()+31)
		PanelTemplates_TabResize(self, 0)
	end)

PanelTemplates_SetNumTabs(SCForgeMainFrame.LoadSpellFrame, 2)
PanelTemplates_SetTab(SCForgeMainFrame.LoadSpellFrame, 1)

SCForgeMainFrame.LoadSpellFrame.refreshVaultButton = CreateFrame("BUTTON", nil, SCForgeMainFrame.LoadSpellFrame)
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.LoadSpellFrame.Inset,"TOPRIGHT", -5, 2)
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetSize(24,24)

	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetNormalAtlas("UI-RefreshButton")
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetPushedAtlas("UI-RefreshButton")
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.Pushed = SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:GetPushedTexture()
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.Pushed:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.Pushed:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.Pushed:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.Pushed:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetDisabledAtlas("UI-RefreshButton")
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.disabled = SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:GetDisabledTexture()
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.disabled:SetDesaturated(true)
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.animations = SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:CreateAnimationGroup()
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.animations:SetLooping("REPEAT")
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.animations.rotate = SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.animations:CreateAnimation("Rotation")
	local _rot = SCForgeMainFrame.LoadSpellFrame.refreshVaultButton.animations.rotate
	_rot:SetDegrees(-360)
	_rot:SetDuration(0.25)

	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetScript("OnClick", function(self, button)
		updateSpellLoadRows();
		self.animations.rotate:SetSmoothing("NONE")
		self.animations:Play()
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
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetScript("OnEnable", function(self)
		self.animations:Finish()
		self.animations.rotate:SetSmoothing("IN_OUT")
	end)

SCForgeMainFrame.LoadSpellFrame.profileButton = CreateFrame("BUTTON", nil, SCForgeMainFrame.LoadSpellFrame)
	local _button = SCForgeMainFrame.LoadSpellFrame.profileButton
	_button:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.LoadSpellFrame.Inset,"TOPRIGHT", -5, 2)
	_button:SetSize(24,24)

	-- PartySizeIcon; QuestSharing-QuestLog-Active; QuestSharing-DialogIcon; socialqueuing-icon-group
	_button:SetNormalAtlas("socialqueuing-icon-group")
	_button.normal = _button:GetNormalTexture()
	_button.normal:SetDesaturated(true)
	_button.normal:SetVertexColor(1,0.8,0)
	_button:SetPushedAtlas("socialqueuing-icon-group")
		_button.pushed = _button:GetPushedTexture()
		_button.pushed:SetVertexColor(1,0.8,0)
		_button.pushed:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
		_button.pushed:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
		_button.pushed:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
		_button.pushed:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
	_button:SetDisabledAtlas("socialqueuing-icon-group")
		_button.disabled = _button:GetDisabledTexture()
		_button.disabled:SetDesaturated(true)
	_button:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")

	_button:SetScript("OnClick", function(self, button)
		if button == "LeftButton" then
			EasyMenu(ProfileFilterMenu.genProfileSelectDropDown(updateSpellLoadRows), profileDropDownMenu, self, 0 , 0, "DROPDOWN");
		elseif button == "RightButton" then
			EasyMenu(ProfileFilterMenu.genChangeDefaultProfileDropDown(), profileDropDownMenu, self, 0 , 0, "DROPDOWN");
		end
	end)
	_button:RegisterForClicks("LeftButtonUp","RightButtonUp")

	_button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		self.Timer = C_Timer.NewTimer(0.7,function()
			GameTooltip:SetText("Change Profile", nil, nil, nil, nil, true)
			GameTooltip:AddLine("Switch to another profile to view that profiles vault.\n\rRight-Click to change your default selected profile.",1,1,1,true)
			GameTooltip:Show()
		end)
	end)
	_button:SetScript("OnLeave", function(self)
		GameTooltip_Hide()
		self.Timer:Cancel()
	end)

-------------------------------------------------------------------------------
-- Mini-Map Icon
-------------------------------------------------------------------------------

local function scforge_showhide(where)
	if where == "options" then
		InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE);
		InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE);
	else
		if not SCForgeMainFrame:IsShown() then
			SCForgeMainFrame:Show()
			if where == "enableMMIcon" and SpellCreatorMasterTable.Options["minimapIcon"] == nil then
				SpellCreatorMasterTable.Options["minimapIcon"] = true
				MinimapButton.onEnabled()
			end
		else
			SCForgeMainFrame:Hide()
		end
	end
end

MinimapButton.setCallback(scforge_showhide)

local function LoadMinimapPosition()
	local radian = tonumber(SpellCreatorMasterTable.Options["mmLoc"]) or 2.7
	MinimapButton.updateAngle(radian);
	if not SpellCreatorMasterTable.Options["minimapIcon"] then MinimapButton:setShown(false) end
end

-------------------------------------------------------------------------------
-- Interface Options - Addon section
-------------------------------------------------------------------------------

function CreateSpellCreatorInterfaceOptions()
	SpellCreatorInterfaceOptions = {};
	SpellCreatorInterfaceOptions.panel = CreateFrame( "Frame", "SpellCreatorInterfaceOptionsPanel", UIParent );
	SpellCreatorInterfaceOptions.panel.name = ADDON_TITLE;

	local SpellCreatorInterfaceOptionsHeader = SpellCreatorInterfaceOptions.panel:CreateFontString("HeaderString", "OVERLAY", "GameFontNormalLarge")
	SpellCreatorInterfaceOptionsHeader:SetPoint("TOPLEFT", 15, -15)
	SpellCreatorInterfaceOptionsHeader:SetText(ADDON_TITLE.." v"..addonVersion.." by "..addonAuthor)


	SpellCreatorInterfaceOptions.panel.scrollFrame = CreateFrame("ScrollFrame", nil, SpellCreatorInterfaceOptions.panel, "UIPanelScrollFrameTemplate")
	local scrollFrame = SpellCreatorInterfaceOptions.panel.scrollFrame
		scrollFrame:SetPoint("TOPLEFT", 20, -75*2)
		scrollFrame:SetPoint("BOTTOMRIGHT", -50, 30)

		scrollFrame.backdrop = CreateFrame("FRAME", nil, scrollFrame)
			scrollFrame.backdrop:SetPoint("TOPLEFT", scrollFrame, -15, 3)
			scrollFrame.backdrop:SetPoint("BOTTOMRIGHT", scrollFrame, 40, -3)
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

		scrollFrame.Title.Backdrop = scrollFrame.backdrop:CreateTexture(nil, "BORDER", nil, 6)
			scrollFrame.Title.Backdrop:SetColorTexture(0,0,0)
			scrollFrame.Title.Backdrop:SetPoint("CENTER", scrollFrame.Title, "CENTER", -1, -1)
			scrollFrame.Title.Backdrop:SetSize(scrollFrame.Title:GetWidth()-4, scrollFrame.Title:GetHeight()/2)

	-- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
	local scrollChild = CreateFrame("SimpleHTML")
	scrollChild:SetWidth(InterfaceOptionsFramePanelContainer:GetWidth()-75)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetScript("OnHyperlinkClick", HTML.copyLink)
	scrollChild:SetFontObject("p", GameFontHighlight);
	scrollChild:SetFontObject("h1", GameFontNormalHuge2);
	scrollChild:SetFontObject("h2", GameFontNormalLarge);
	scrollChild:SetFontObject("h3", GameFontNormalMed2);
	scrollChild:SetText(HTML.stringToHTML(ns.ChangelogText));
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
		button:SetMotionScriptsWhileDisabled(true)

		return button;
	end

	--Minimap Icon Toggle
	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = nil, relativePoint = nil, x = 20, y = -40,},
		["title"] = "Enable Minimap Button",
		["tooltipTitle"] = "Enable Minimap Button",
		["tooltipText"] = nil,
		["optionKey"] = "minimapIcon",
		["onClickHandler"] = function(self) if SpellCreatorMasterTable.Options["minimapIcon"] then MinimapButton.setShown(true) else MinimapButton.setShown(false) end end,
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
		["anchor"] = {point = "TOP", relativeTo = nil, relativePoint = nil, x = 20, y = -40,},
		["title"] = "Load Actions Chronologically",
		["tooltipTitle"] = "Load Chronologically by Delay",
		["tooltipText"] = "When loading a spell, actions will be loaded in order of their delays, despite the order they were saved in.",
		["optionKey"] = "loadChronologically",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.loadChronologicallyToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.loadChronologicallyToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -5,},
		["title"] = "Fast Reset the Forge UI",
		["tooltipTitle"] = "Fast Reset",
		["tooltipText"] = "Skip the Animation of Resetting the UI, and instantly reset it, when you use the Clear & Reset button.",
		["optionKey"] = "fastReset",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.fastResetToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.fastResetToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -5,},
		["title"] = "Show Tooltips",
		["tooltipTitle"] = "Show Tooltips",
		["tooltipText"] = "Show Tooltips when you mouse-over UI elements like buttons, editboxes, and spells in the vault, just like this one!\nYou can't currently toggle these off, maybe later.",
		["optionKey"] = "showTooltips",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.showTooltipsToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)
	SpellCreatorInterfaceOptions.panel.showTooltipsToggle:Disable()

	-- Debug Checkbox
	local SpellCreatorInterfaceOptionsDebug = CreateFrame("CHECKBUTTON", "SC_DebugToggleOption", SpellCreatorInterfaceOptions.panel, "OptionsSmallCheckButtonTemplate")
	SpellCreatorInterfaceOptionsDebug:SetPoint("BOTTOMRIGHT", 0, 0)
	SpellCreatorInterfaceOptionsDebug:SetHitRectInsets(-35,0,0,0)
	SpellCreatorInterfaceOptionsDebug.Text = SC_DebugToggleOptionText -- This is defined by $parentText and is never made a child by the template, smfh
	SpellCreatorInterfaceOptionsDebug.Text:SetTextColor(1,1,1,1)
	SpellCreatorInterfaceOptionsDebug.Text:SetText("Debug")
	SpellCreatorInterfaceOptionsDebug.Text:SetPoint("LEFT", -30, 0)
	SpellCreatorInterfaceOptionsDebug:SetScript("OnShow", function(self)
		if SpellCreatorMasterTable.Options["debug"] == true then SpellCreatorInterfaceOptionsDebug:SetChecked(true) else SpellCreatorInterfaceOptionsDebug:SetChecked(false) end
	end)
	SpellCreatorInterfaceOptionsDebug:SetScript("OnClick", function(self)
		SpellCreatorMasterTable.Options["debug"] = not SpellCreatorMasterTable.Options["debug"]
		if SpellCreatorMasterTable.Options["debug"] then
			cprint("Toggled Debug (VERBOSE) Mode")
		end
	end)

	InterfaceOptions_AddCategory(SpellCreatorInterfaceOptions.panel);
	if SpellCreatorMasterTable.Options["debug"] == true then SpellCreatorInterfaceOptionsDebug:SetChecked(true) else SpellCreatorInterfaceOptionsDebug:SetChecked(false) end
end

-------------------------------------------------------------------------------
-- Addon Loaded & Communication
-------------------------------------------------------------------------------
local lockTimer
local function onCommReceived(prefix, message, channel, sender)
	if sender == GetUnitName("player") then dprint("onCommReceived bypassed because we're talking to ourselves."); return; end
	if prefix == addonMsgPrefix.."REQ" then
		Comms.sendSpellToPlayer(sender, message)
	elseif prefix == addonMsgPrefix.."SPELL" then
		Comms.receiveSpellData(message, sender, updateSpellLoadRows)
	elseif prefix == addonMsgPrefix.."_PLOCK" then
		local phaseID = C_Epsilon.GetPhaseId()
		if message == phaseID then
			phaseVault.isSavingOrLoadingAddonData = true
			dprint("Phase Vault IO for Phase "..phaseID.." was locked by Addon Message")
			lockTimer = C_Timer.NewTicker(5, function() phaseVault.isSavingOrLoadingAddonData=false; eprint("Phase IO Lock on for longer than 10 seconds - disabled. If you get this after changing phases, ignore, otherwise please report it."); end)
		end
	elseif prefix == addonMsgPrefix.."_PUNLOCK" then
		local phaseID = C_Epsilon.GetPhaseId()
		if message == phaseID then
			phaseVault.isSavingOrLoadingAddonData = false
			dprint("Phase Vault IO for Phase "..phaseID.." was unlocked by Addon Message")
			lockTimer:Cancel()
			if phaseVault.isLoaded then getSpellForgePhaseVault((SCForgeMainFrame.LoadSpellFrame:IsShown() and updateSpellLoadRows or nil)) end
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

local spellsToCast = {}
local shouldAutoHide = false
local shouldLoadSpellVault = false
local useImmersion = false
local gossipOptionPayload
local gossipGreetPayload
local lastGossipText
local currGossipText
local origImmersionSetText = nil

local gossipScript = {
	show = function()
		scforge_showhide("enableMMIcon");
	end,
	auto_cast = function(payLoad)
		table.insert(spellsToCast, payLoad)
		dprint("Adding AutoCast from Gossip: '"..payLoad.."'.")
	end,
	click_cast = function(payLoad)
		if phaseVault.isSavingOrLoadingAddonData then eprint("Phase Vault was still loading. Casting when loaded..!"); table.insert(spellsToCast, payLoad) return; end
		local spellRanSuccessfully
		for k,v in pairs(phaseVault.spells) do
			if v.commID == payLoad then
				executeSpell(v.actions, true, v.fullName, v);
				spellRanSuccessfully = true
			end
		end
		if not spellRanSuccessfully then cprint("No spell with command "..payLoad.." found in the Phase Vault. Please let a phase officer know.") end
	end,
	save = function(payLoad)
		if phaseVault.isSavingOrLoadingAddonData then eprint("Phase Vault was still loading. Please try again in a moment."); return; end
		dprint("Scanning Phase Vault for Spell to Save: "..payLoad)
		for k,v in pairs(phaseVault.spells) do
			if v.commID == payLoad then dprint("Found & Saving Spell '"..payLoad.."' ("..k..") to your Personal Vault."); saveSpell(nil, k); end
		end
	end,
	cmd = function(payLoad)
		cmdWithDotCheck(payLoad)
	end,
	hide_check = function(button)
		if button then -- came from an OnClick, so we need to close now, instead of toggling AutoHide which already past.
			CloseGossip();
		else
			shouldAutoHide = true
		end
	end,
}

local gossipTags = {
	default = "<arc[anum]-_.->",
	capture = "<arc[anum]-_(.-)>",
	dm = "<arc-DM :: ",
	body = { -- tag is pointless, I changed it to tags are the table key, but kept for readability
		show = {tag = "show", script = gossipScript.show},
		cast = {tag = "cast", script = gossipScript.auto_cast},
		save = {tag = "save", script = gossipScript.save},
		cmd = {tag = "cmd", script = gossipScript.cmd},
		macro = {tag = "macro", script = runMacroText},
	},
	option = {
		show = {tag = "show", script = gossipScript.show},
		toggle = {tag = "toggle", script = gossipScript.show}, -- kept for back-compatibility, but undocumented. They should use Show now.
		cast = {tag = "cast", script = gossipScript.click_cast},
		save = {tag = "save", script = gossipScript.save},
		cmd = {tag = "cmd", script = gossipScript.cmd},
		macro = {tag = "macro", script = runMacroText},
	},
	extensions = {
		{ ext = "hide", script = gossipScript.hide_check},
	},
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
SC_Addon_Listener:RegisterEvent("PLAYER_ENTERING_WORLD")
SC_Addon_Listener:RegisterEvent("UI_ERROR_MESSAGE");
SC_Addon_Listener:RegisterEvent("GOSSIP_SHOW");
SC_Addon_Listener:RegisterEvent("GOSSIP_CLOSED");

local function gossipReloadCheck()
	if isGossipLoaded and lastGossipText and lastGossipText == currGossipText then return true; else return false; end
end

if not C_Epsilon.IsDM then C_Epsilon.IsDM = false end
SC_Addon_Listener:SetScript("OnEvent", function( self, event, name, ... )
	-- Phase Change Listener
	if event == "SCENARIO_UPDATE" or (event == "PLAYER_ENTERING_WORLD" and not name) then -- SCENARIO_UPDATE fires whenever a phase change occurs. Lucky us.
		--dprint("Caught Phase Change - Refreshing Load Rows & Checking for Main Phase / Start") -- Commented out for performance.
		phaseVault.isSavingOrLoadingAddonData = false
		phaseVault.isLoaded = false

		C_Epsilon.IsDM = false
		updateSpellLoadRows();

		getSpellForgePhaseVault(SCForgeMainFrame.LoadSpellFrame:IsShown() and updateSpellLoadRows or nil);

		SCForgeMainFrame.ExecuteSpellButton:SetEnabled(Permissions.canExecuteSpells())

		return;

	-- Addon Loaded Handler
	elseif event == "ADDON_LOADED" and (name == addonName) then
		local hadUpdate = SavedVariables.init()
		ProfileFilter.init()
		LoadMinimapPosition();
		aceCommInit()

		local channelType, channelName = JoinChannelByName("scforge_comm")
		scforge_ChannelID = GetChannelName("scforge_comm")

		--Quickly Show / Hide the Frame on Start-Up to initialize everything for key bindings & loading
		C_Timer.After(1,function()
			SCForgeMainFrame:Show();
			if not SpellCreatorMasterTable.Options["debug"] then SCForgeMainFrame:Hide(); --[[ SCForgeLoadFrame:Hide() ]] end
		end)

		-- Adjust Radial Offset for Minimap Icon for alternate UI Overhaul Addons
		if IsAddOnLoaded("AzeriteUI") then
			MinimapButton.setRadialOffset(18)
		elseif IsAddOnLoaded("DiabolicUI") then
			MinimapButton.setRadialOffset(12)
		elseif IsAddOnLoaded("GoldieSix") then
			--GoldpawUI
			MinimapButton.setRadialOffset(18)
		elseif IsAddOnLoaded("GW2_UI") then
			MinimapButton.setRadialOffset(44)
		elseif IsAddOnLoaded("SpartanUI") then
			MinimapButton.setRadialOffset(8)
		else
			MinimapButton.setRadialOffset(10)
		end

		CreateSpellCreatorInterfaceOptions()

		-- Gen the first few spell rows
		SpellRow.addRow()
		SpellRow.addRow()
		SpellRow.addRow()

		SCForgeMainFrame.ExecuteSpellButton:SetEnabled(Permissions.canExecuteSpells())

		if hadUpdate then
			RaidNotice_AddMessage(RaidWarningFrame, "\n\r"..ADDON_COLOR.."Arcanum - Updated to v"..addonVersion.."\n\rCheck-out the Changelog by right-clicking the Mini-map Icon!|r", ChatTypeInfo["RAID_WARNING"])
--			InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE);
--			InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE);
			local titleText = SpellCreatorInterfaceOptions.panel.scrollFrame.Title
			titleText:SetText("Spell Forge - |cff57F287UPDATED|r to v"..addonVersion)
			titleText.Backdrop:SetSize(titleText:GetWidth()-4, titleText:GetHeight()/2)
		end

	-- Phase DM Toggle Listener
	elseif event == "UI_ERROR_MESSAGE" then
		local errType, msg = name, ...
		if msg=="DM mode is ON" then C_Epsilon.IsDM = true; dprint("DM Mode On");
			elseif msg=="DM mode is OFF" then C_Epsilon.IsDM = false; dprint("DM Mode Off");
		end

	-- Gossip Menu Listener
	elseif event == "GOSSIP_SHOW" then

		spellsToCast = {} -- make sure our variables are reset before we start processing
		shouldAutoHide = false
		shouldLoadSpellVault = false
		useImmersion = false
		gossipOptionPayload = nil
		gossipGreetPayload = nil
		currGossipText = GetGossipText();

		local gossipGreetingText = GossipGreetingText:GetText()
		if ImmersionFrame and ImmersionFrame.TalkBox and ImmersionFrame.TalkBox.TextFrame then
			gossipGreetingText = ImmersionFrame.TalkBox.TextFrame.Text.storedText;
			local tagSearchText = gossipGreetingText
			useImmersion = true;
			dprint("Immersion detected, using it");

			while tagSearchText and tagSearchText:match(gossipTags.default) do -- while tagSearchText has an arcTag - this allows multiple tags - For Immersion, we need to split our filters between the whole text, and the displayed text
				shouldLoadSpellVault = true
				gossipGreetPayload = tagSearchText:match(gossipTags.capture) -- capture the tag
				local strTag, strArg = strsplit(":", gossipGreetPayload, 2) -- split the tag from the data
				local mainTag, extTags = strsplit("_", strTag, 2) -- split the main tag from the extension tags

				if gossipReloadCheck() then
					dprint("Gossip Reload of the Same Page detected. Skipping Auto Functions.")
				else
					if isDMEnabled() then cprint("DM Enabled - Skipping Auto Function ("..gossipGreetPayload..")") else
						if gossipTags.body[mainTag] then -- Checking Main Tags & Running their code if present
							gossipTags.body[mainTag].script(strArg)
						end
						if extTags then
							for k,v in ipairs(gossipTags.extensions) do -- Checking for any tag extensions
								if extTags:match(v.ext) then v.script() end
							end
						end
					end
				end
				tagSearchText = tagSearchText:gsub(gossipTags.default, "", 1)
				dprint("Saw a gossip greeting | Tag: "..mainTag.." | Spell: "..(strArg or "none").." | Ext: "..(tostring(extTags) or "none"))
			end
			ImmersionFrame.TalkBox.TextFrame.Text.storedText = tagSearchText
			tagSearchText = nil

			ImmersionFrame.TalkBox.TextFrame.Text:RepeatTexts() -- this triggers Immersion to restart the text, pulling from it's storedText, which we already cleaned.

		else

			while gossipGreetingText and gossipGreetingText:match(gossipTags.default) do -- while gossipGreetingText has an arcTag - this allows multiple tags
				shouldLoadSpellVault = true
				gossipGreetPayload = gossipGreetingText:match(gossipTags.capture) -- capture the tag
				local strTag, strArg = strsplit(":", gossipGreetPayload, 2) -- split the tag from the data
				local mainTag, extTags = strsplit("_", strTag, 2) -- split the main tag from the extension tags

				if gossipReloadCheck() then
					dprint("Gossip Reload of the Same Page detected. Skipping Auto Functions.")
				else
					if isDMEnabled() then cprint("DM Enabled - Skipping Auto Function ("..gossipGreetPayload..")") else
						if gossipTags.body[mainTag] then -- Checking Main Tags & Running their code if present
							gossipTags.body[mainTag].script(strArg)
						end
						if extTags then
							for k,v in ipairs(gossipTags.extensions) do -- Checking for any tag extensions
								if extTags:match(v.ext) then v.script() end
							end
						end
					end
				end

				if isDMEnabled() then -- Updating GossipGreetingText
					GossipGreetingText:SetText(gossipGreetingText:gsub(gossipTags.default, gossipTags.dm..gossipGreetPayload..">", 1))
					gossipGreetingText = GossipGreetingText:GetText()
				else
					GossipGreetingText:SetText(gossipGreetingText:gsub(gossipTags.default, "", 1))
					gossipGreetingText = GossipGreetingText:GetText()
				end
				dprint("Saw a gossip greeting | Tag: "..mainTag.." | Spell: "..(strArg or "none").." | Ext: "..(tostring(extTags) or "none"))
			end
		end

		for i = 1, GetNumGossipOptions() do
			--[[	-- Replaced with a memory of modifiedGossips that we reset when gossip is closed instead.
			_G["GossipTitleButton" .. i]:SetScript("OnClick", function()
				SelectGossipOption(i)
			end)
			--]]
			local titleButton = _G["GossipTitleButton" .. i]
			local titleButtonText = titleButton:GetText();
			if ImmersionFrame then
				local immersionButton = _G["ImmersionTitleButton"..i]
				if immersionButton then titleButton = immersionButton; titleButtonText = immersionButton:GetText() end
			end

			while titleButtonText and titleButtonText:match(gossipTags.default) do
				shouldLoadSpellVault = true
				gossipOptionPayload = titleButtonText:match(gossipTags.capture) -- capture the tag
				local strTag, strArg = strsplit(":", gossipOptionPayload, 2) -- split the tag from the data
				local mainTag, extTags = strsplit("_", strTag, 2) -- split the main tag from the extension tags

				if gossipTags.option[mainTag] then -- Checking Main Tags & Running their code if present
					--[[
					if not titleButton.isHookedByArc then
						titleButton:HookScript("OnClick", function() gossipTags.option[mainTag].script(strArg) end)
						titleButton.isHookedByArc = true
					end
					modifiedGossips[i] = titleButton
					--]]
					local function _newOnClickHook() gossipTags.option[mainTag].script(strArg); dprint("Hooked gossip clicked for <"..mainTag..":"..strArg..">") end

					if extTags then
						if extTags:match("auto") then -- legacy auto support - hard coded to avoid breaking gossipText
							if isDMEnabled() then
								cprint("Legacy Auto Gossip Option skipped due to DM Mode On.")
							else
								if mainTag == "cast" then
									dprint("Running Legacy Auto-Cast..")
									gossipScript.auto_cast(strArg)
								else
									gossipTags.option[mainTag].script(strArg)
									dprint("Running Legacy Auto Tag Support.. This may not work.")
								end
							end
						end
						if extTags == "auto_hide" then shouldAutoHide = true end
						for k,v in ipairs(gossipTags.extensions) do -- Checking for any tag extensions
							if extTags:match(v.ext) then
								local _origNewOnClickHook = _newOnClickHook
								function _newOnClickHook(self, button)
									_origNewOnClickHook()
									v.script(strArg or button)
								end
							end
						end
					end
					if ImmersionFrame then
						if not titleButton.isHookedByArc then
							titleButton:HookScript("OnClick", _newOnClickHook)
							titleButton.isHookedByArc = true
						end
					else
						titleButton:HookScript("OnClick", _newOnClickHook)
						titleButton.isHookedByArc = true
					end
					modifiedGossips[i] = titleButton
				end


				if isDMEnabled() then -- Update the text
					-- Is DM and Officer+
					titleButton:SetText(titleButtonText:gsub(gossipTags.default, gossipTags.dm..gossipOptionPayload..">", 1));
				else
					-- Is not DM or Officer+
					titleButton:SetText(titleButtonText:gsub(gossipTags.default, "", 1));
				end
				titleButtonText = titleButton:GetText();
				dprint("Saw an option tag | Tag: "..mainTag.." | Spell: "..(strArg or "none").." | Ext: "..(tostring(extTags) or "none"))
			end

			GossipResize(titleButton) -- Fix the size if the gossip option changed number of lines.

		end

		if shouldLoadSpellVault and not isGossipLoaded then
			local castTheSpells = function(ready)
				if next(spellsToCast) == nil then dprint("No Auto Cast Spells in Gossip"); return; end
				local spellRanSuccessfully
				for i,j in pairs(spellsToCast) do
					for k,v in pairs(phaseVault.spells) do
						if v.commID == j then
							executeSpell(v.actions, true, v.fullName, v);
							spellRanSuccessfully = true
						end
					end
				end
				if not spellRanSuccessfully then cprint("No spell found in the Phase Vault. Please let a phase officer know.") end
				spellsToCast = {} -- empty the table.
			end
			if phaseVault.isLoaded then
				castTheSpells()
			else
				getSpellForgePhaseVault(castTheSpells)
			end
		end

		isGossipLoaded = true
		lastGossipText = currGossipText
		updateGossipVaultButtons(true)

		if shouldAutoHide and not(isDMEnabled()) then CloseGossip(); end -- Final check if we toggled shouldAutoHide and close gossip if so.

	elseif event == "GOSSIP_CLOSED" then

		for k,v in pairs(modifiedGossips) do
			v:SetScript("OnClick", function()
				SelectGossipOption(k)
			end)
			v.isHookedByArc = nil
			modifiedGossips[k] = nil
		end

		isGossipLoaded = false
		updateGossipVaultButtons(false)

	end

end);


-------------------------------------------------------------------------------
-- Version / Help / Toggle
-------------------------------------------------------------------------------

SLASH_SCFORGEMAIN1, SLASH_SCFORGEMAIN2 = '/arcanum', '/sf'; -- 3.
function SlashCmdList.SCFORGEMAIN(msg, editbox) -- 4.
	if #msg > 0 then
		dprint(false,"Casting Arcanum Spell by CommID: "..msg)
		if SpellCreatorSavedSpells[msg] then
			executeSpell(SpellCreatorSavedSpells[msg].actions, nil, SpellCreatorSavedSpells[msg].fullName, SpellCreatorSavedSpells[msg])
		elseif msg == "options" then
			scforge_showhide("options")
		else
			cprint("No spell with Command "..msg.." found.")
		end
	else
		scforge_showhide()
	end
end

local _phaseSpellDebugDataTable = {}
SLASH_SCFORGEDEBUG1 = '/sfdebug';
function SlashCmdList.SCFORGEDEBUG(msg, editbox) -- 4.
	local command, rest = msg:match("^(%S*)%s*(.-)$")
	if command == "debug" then
		SpellCreatorMasterTable.Options["debug"] = not SpellCreatorMasterTable.Options["debug"]
		dprint(true, "SC-Forge Debug Set to: "..tostring(SpellCreatorMasterTable.Options["debug"]))
		return;
	end
	if SpellCreatorMasterTable.Options["debug"] and msg ~= "" then
		if command == "resetSpells" then
			dprint(true, "All Arcaum Spells reset. #GoodBye #ThisCannotBeUndoneHopeYouDidn'tFuckUp!")
			SpellCreatorSavedSpells = {}
			updateSpellLoadRows()
		elseif command == "listSpells" then
			for k,v in orderedPairs(SpellCreatorSavedSpells) do
				cprint("ArcSpell: "..k.." =")
				Debug.dump(v)
			end
		elseif command == "listSpellKeys" then -- debug to list all spell keys by alphabetical order.
			local newTable = get_keys(SpellCreatorSavedSpells)
			table.sort(newTable)
			Debug.dump(newTable)
		elseif command == "resetPhaseSpellKeys" then
			if rest == "confirm" then
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
						phaseVaultKeys = serializer.decompressForAddonMsg(text)
						local theDeletedKey = phaseVaultKeys[rest]
						if theDeletedKey then
							table.remove(phaseVaultKeys, rest)
							phaseVaultKeys = serializer.compressForAddonMsg(phaseVaultKeys)
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
						interAction = serializer.decompressForAddonMsg(text)
						_phaseSpellDebugDataTable[interAction.fullName] = {
							["encoded"] = text,
							["decoded"] = interAction,
						}
						Debug.dump(interAction)
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
						phaseVaultKeys = serializer.decompressForAddonMsg(text)
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
								interAction = serializer.decompressForAddonMsg(text)
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
					phaseVaultKeys = serializer.decompressForAddonMsg(text)
					Debug.dump(phaseVaultKeys)
				end
			end)

		end
	else
		cprint("DEBUG LIST")
		cprint("Version: "..addonVersion)
		--cprint("RuneIcon: "..runeIconOverlay.atlas or runeIconOverlay.tex)
		cprint("Debug Commands (/sfdebug ...): ")
		print("... debug: Toggles Debug mode on/off. Must be on for these commands to work.")
		print("... resetSpells: reset your vault to empty. Cannot be undone.")
		print("... listSpells: List all your vault spells' data.. this is alot of text!")
		print("... listSpellKeys: List all your vault spells by just keys. Easier to read.")
		print("... getPhaseKeys: Lists all the vault spells by keys.")
		print("... getPhaseSpellData [$commID/key]: Exports the spell data for all current keys, or the specified commID/key, to your '|cffFFAAAA..epsilon/_retail_/WTF/Account/NAME/SavedVariables/SpellCreator.lua|r' file.")
		print("... resetPhaseSpellKeys: reset your phase vault to empty. Technically the spell data remains, and can be exported to your WTF file by using getPhaseSpellData.")
		print("... removePhaseKey: Removes a single phase key from the Phase Vault. The data for the spell remains, and can be retrieved using getPhaseSpellData also.")
	end
end

local testComVar
SLASH_SCFORGETEST1 = '/sftest';
function SlashCmdList.SCFORGETEST(msg, editbox) -- 4.
	if testComVar and testComVar < #Models.minimapModels then testComVar = testComVar+1 else testComVar = 1 end
	Models.modelFrameSetModel(SCForgeMainFrame.portrait.Model, testComVar, Models.minimapModels)
	print(testComVar)

	--[[
	if msg ~= "" then
		Models.modelFrameSetModel(minimapButton.Model, msg, Models.minimapModels)
	else
		initRuneIcon()
		setRuneTex(runeIconOverlay)
	end
--]]

end
