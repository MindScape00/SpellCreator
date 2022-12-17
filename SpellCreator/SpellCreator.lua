local addonName = ...
---@class ns
local ns = select(2, ...)

local ActionsData = ns.Actions.Data
local actionTypeData = ActionsData.actionTypeData
local cmd = ns.Cmd.cmd
local cprint, dprint, eprint = ns.Logging.cprint, ns.Logging.dprint, ns.Logging.eprint
local ADDON_COLORS = ns.Constants.ADDON_COLORS

local Comms = ns.Comms
local Constants = ns.Constants
local Execute = ns.Actions.Execute
local Gossip = ns.Gossip
local Permissions = ns.Permissions
local ProfileFilter = ns.ProfileFilter
local SavedVariables = ns.SavedVariables
local serializer = ns.Serializer
local Vault = ns.Vault
local Hotkeys = ns.Actions.Hotkeys

local DataUtils = ns.Utils.Data
local Debug = ns.Utils.Debug
local NineSlice = ns.Utils.NineSlice
local UIHelpers = ns.Utils.UIHelpers
local Tooltip = ns.Utils.Tooltip

local Animation = ns.UI.Animation
local Attic = ns.UI.Attic
local Basement = ns.UI.Basement
local ChatLink = ns.UI.ChatLink
local Icons = ns.UI.Icons
local ImportExport = ns.UI.ImportExport
local Models, Portrait = ns.UI.Models, ns.UI.Portrait
local LoadSpellFrame = ns.UI.LoadSpellFrame
local MainFrame = ns.UI.MainFrame
local MinimapButton = ns.UI.MinimapButton
local Options = ns.UI.Options
local Popups = ns.UI.Popups
local ProfileFilterMenu = ns.UI.ProfileFilterMenu
local Quickcast = ns.UI.Quickcast
local SpellRow = ns.UI.SpellRow
local SpellVaultFrame = ns.UI.SpellVaultFrame

local addonMsgPrefix = Comms.PREFIX
local ADDON_COLOR, ADDON_PATH, ADDON_TITLE = Constants.ADDON_COLOR, Constants.ADDON_PATH, Constants.ADDON_TITLE
local ASSETS_PATH = Constants.ASSETS_PATH
local SPELL_VISIBILITY = Constants.SPELL_VISIBILITY
local VAULT_TYPE = Constants.VAULT_TYPE
local executeSpell = Execute.executeSpell
local isOfficerPlus, isMemberPlus = Permissions.isOfficerPlus, Permissions.isMemberPlus
local phaseVault = Vault.phase
local isNotDefined = DataUtils.isNotDefined
local orderedPairs = DataUtils.orderedPairs

local addonVersion = GetAddOnMetadata(addonName, "Version")

---@type table<CommID, VaultSpell>
local savedSpellFromVault = {}

local saveSpell

-- localized frequent functions for speed
local C_Timer = C_Timer
local print = print
local SendChatMessage = SendChatMessage
local _G = _G
local ipairs = ipairs
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

local C_Epsilon = C_Epsilon

-------------------------------------------------------------------------------
-- Simple Chat & Helper Functions
-------------------------------------------------------------------------------

--[[ local function sendChat(text)
  SendChatMessage(text, "SAY");
end ]]

-- Frame Listeners
local phaseAddonDataListener = CreateFrame("Frame")
local phaseAddonDataListener2 = CreateFrame("Frame")

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
		UIHelpers.setTextureOffset(_frame.AddRowButton.PushedTex, 1, -1)
		_frame.AddRowButton:SetPushedTexture(_frame.AddRowButton.PushedTex)

		_frame.AddRowButton:SetMotionScriptsWhileDisabled(true)
		Tooltip.set(_frame.AddRowButton, "Add another Action Row", "Max number of Rows: "..SpellRow.maxNumberOfRows)
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

---@param spellToLoad VaultSpell
local function loadSpell(spellToLoad, byPassResetConfirmation)
	--dprint("Loading spell.. "..spellToLoad.commID)

	if not byPassResetConfirmation then
		if ns.UI.Popups.checkAndShowResetForgeConfirmation("load a spell", loadSpell, spellToLoad, true) then return end
	end

	Attic.updateInfo(spellToLoad)
	Attic.markEditorSaved()

	---@type VaultSpellAction[]
	local localSpellActions = CopyTable(spellToLoad.actions)
	local numberOfActionsToLoad = #localSpellActions

	-- Adjust the number of available Action Rows
	SpellRow.setNumActiveRows(numberOfActionsToLoad)

	if SpellCreatorMasterTable.Options["loadChronologically"] then
		table.sort(localSpellActions, function (k1, k2) return k1.delay < k2.delay end)
	end

	-- Loop thru actions & set their data
	for rowNum, actionData in ipairs(localSpellActions) do
		SpellRow.setRowAction(rowNum, actionData)
	end
end

Basement.init(SCForgeMainFrame, {
	getForgeActions = function()
		local actionsToCommit = {}

		for i = 1, SpellRow.getNumActiveRows() do
			local actionData = SpellRow.getRowAction(i)

			if not actionData then
				dprint("Action Row " .. i .. " Invalid, Delay Not Set")
				break
			end

			table.insert(actionsToCommit, actionData)
		end

		return actionsToCommit
	end,
	saveSpell = function(overwriteBypass)
		return saveSpell(overwriteBypass)
	end,
	toggleVault = function()
		SCForgeMainFrame.LoadSpellFrame:SetShown(not SCForgeMainFrame.LoadSpellFrame:IsShown())
	end,
	resetUI = function(resetButton)
		-- 2 types of reset: Delete all the Rows, and load an empty spell to effectively reset the UI. We're doing both, the delete rows for visual, load for the actual reset
		local emptySpell = {
			["fullName"] = "", ["commID"] = "", ["description"] = "",
			["actions"] = { { ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, }, { ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, }, { ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, }, },
		}

		resetButton:Disable()

		UIFrameFadeIn(SCForgeMainFrame.Inset.Bg.Overlay,0.1,0.05,0.8)
		Animation.setFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 3, nil, nil, 0.05, 0.8)
		local numActiveRows = SpellRow.getNumActiveRows()
		local resetTime = min(numActiveRows/40, 0.5)
		local resetPerRowTime = resetTime / numActiveRows
		local deleteRowIter = 0
		for i = numActiveRows, 1, -1 do
			deleteRowIter = deleteRowIter+1
			C_Timer.After(resetPerRowTime*deleteRowIter, function() SpellRow.removeRow(i) end)
		end

		C_Timer.After(resetTime, function()
			loadSpell(emptySpell)
			Animation.stopFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 0.05, 0.25)
			resetButton:Enable();
		end)
	end,
})

local phaseVaultKeys

---@param spellKey CommID
---@param where VaultType
local function deleteSpellConf(spellKey, where)
	local dialog = StaticPopup_Show("SCFORGE_CONFIRM_DELETE", DataUtils.wordToProperCase(where), string.format("Name: %s\nCommand: /sf %s", savedSpellFromVault[spellKey].fullName, savedSpellFromVault[spellKey].commID))
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
	Vault.phase.clearSpells()
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
					Vault.phase.addSpell(interAction)
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

local scforge_ChannelID = ns.Constants.ADDON_CHANNEL
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

local function saveSpellToPhaseVault(commID, overwrite, fromPhase, forcePrivate)
	local needToOverwrite = false
	local phaseVaultIndex
	if not commID then
		eprint("Invalid CommID.")
		return;
	end
	if fromPhase then
		phaseVaultIndex = commID
		commID = Vault.phase.getSpellByIndex(phaseVaultIndex).commID
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
							Popups.showPhaseVaultOverwritePopup(commID)
							phaseVault.isSavingOrLoadingAddonData = false
							sendPhaseVaultIOLock(false)
							return;
						else
							needToOverwrite = true
						end
					end
				end

				-- Passed checking for duplicates. NOW we can save it.
				local _spellData
				if fromPhase then
					_spellData = Vault.phase.getSpellByIndex(phaseVaultIndex)
				else
					_spellData = Vault.personal.findSpellByID(commID)
				end
				if LoadSpellFrame.getUploadToPhaseVisibility() == SPELL_VISIBILITY.PRIVATE then
					_spellData.private = true
				else
					_spellData.private = nil
				end
				if not isNotDefined(forcePrivate) then
					_spellData.private = forcePrivate
					dprint(nil, "Force Vis was set to "..tostring(forcePrivate))
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

------------------------

--[[ local baseVaultFilterTags = {
	"Macro", "Utility", "Morph", "Animation", "Teleport", "Quest", "Fun", "Officer+", "Gossip", "Spell",
}

local function editVaultTags( tag, spellCommID, vaultType ) --
	--print(spellCommID, tag)
	if not tag and not spellCommID then return; end
	if not vaultType then vaultType = 1 end
	if vaultType == 1 then
		local spell = Vault.personal.findSpellByID(spellCommID)
		if not spell.tags then spell.tags = {} end
		if spell.tags[tag] then spell.tags[tag] = nil else spell.tags[tag] = true end
		--print(spell.tags[tag])
	end
end ]]

local function setSpellProfile(spellCommID, profileName, vaultType, callback)
	if not vaultType then vaultType = 1 end
	if not spellCommID then return; end
	if isNotDefined(profileName) then
		Popups.showNewProfilePopup(spellCommID, vaultType, callback)
		return;
	end
	if vaultType == 1 then
		Vault.personal.findSpellByID(spellCommID).profile = profileName
	end
	if callback then
		callback()
	end
end

local contextDropDownMenu = CreateFrame("BUTTON", "ARCLoadRowContextMenu", UIParent, "UIDropDownMenuTemplate")
local profileDropDownMenu = CreateFrame("BUTTON", "ARCProfileContextMenu", UIParent, "UIDropDownMenuTemplate")

---@param vault VaultType
---@param spellCommID CommID | integer
local function genDropDownContextOptions(vault, spellCommID, callback)
	local menuList = {}
	local item
	local playerName = GetUnitName("player")
	local _profile
	if vault == VAULT_TYPE.PHASE then
		---@cast spellCommID integer
		local phaseSpell = Vault.phase.getSpellByIndex(spellCommID)
		menuList = {
			{text = phaseSpell.fullName, notCheckable = true, isTitle=true},
			{text = "Cast", notCheckable = true, func = function() executeSpell(phaseSpell.actions, nil, phaseSpell.fullName, phaseSpell) end},
			{text = "Edit", notCheckable = true, func = function() loadSpell(phaseSpell) end},
			{text = "Transfer", tooltipTitle="Copy to Personal Vault", tooltipOnButton=true, notCheckable = true, func = function() saveSpell(nil, spellCommID) end},
		}
		item = {text = "Add to Gossip", notCheckable = true, func = function() _G["scForgeLoadRow"..spellCommID].gossipButton:Click() end}
		if not Gossip.isLoaded() then item.disabled = true; item.text = "(Open a Gossip Menu)"; end
		tinsert(menuList, item)
	else
		---@cast spellCommID CommID
		local spell = Vault.personal.findSpellByID(spellCommID)

		if not spell then return end

		_profile = spell.profile
		menuList = {
			{text = spell.fullName, notCheckable = true, isTitle=true},
			{text = "Cast", notCheckable = true, func = function() ARC:CAST(spellCommID) end},
			{text = "Edit", notCheckable = true, func = function() loadSpell(savedSpellFromVault[spellCommID]) end},
			{text = "Transfer", tooltipTitle="Copy to Phase Vault", tooltipOnButton=true, notCheckable = true, func = function() saveSpellToPhaseVault(spellCommID) end},
		}

		-- Profiles Menu
		item = {text = "Profile", notCheckable=true, hasArrow=true, keepShownOnClick=true,
			menuList = {
				{ text = "Account", isNotRadio = (_profile=="Account"), checked = (_profile=="Account"), disabled = (_profile=="Account"), disablecolor = ((_profile=="Account") and ADDON_COLORS.MENU_SELECTED:GenerateHexColorMarkup() or nil), func = function() setSpellProfile(spellCommID, "Account", 1, callback); CloseDropDownMenus(); end },
				{ text = playerName, isNotRadio = (_profile==playerName), checked = (_profile==playerName), disabled = (_profile==playerName), disablecolor = ((_profile==playerName) and ADDON_COLORS.MENU_SELECTED:GenerateHexColorMarkup() or nil), func = function() setSpellProfile(spellCommID, playerName, 1, callback); CloseDropDownMenus(); end },
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
				disablecolor = ((_profile == profileName) and ADDON_COLORS.MENU_SELECTED:GenerateHexColorMarkup() or nil),
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
		if spell.tags then
			for k,v in pairs(spell.tags) do
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

		menuList[#menuList+1] = {text = "Link Hotkey", notCheckable = true, func = function()
			Popups.showLinkHotkeyDialog(savedSpellFromVault[spellCommID].commID)
		end}

	end

	menuList[#menuList+1] = {text = "Chatlink", notCheckable = true, func = function()
		ChatLink.linkSpell(savedSpellFromVault[spellCommID], vault)
	end}
	menuList[#menuList+1] = {text = "Export", notCheckable = true, func = function()
		ImportExport.exportSpell(savedSpellFromVault[spellCommID])
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
		savedSpellFromVault = Vault.personal.getSpells()
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
			savedSpellFromVault = Vault.phase.getSpells()
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
				thisRow.spellName:SetPoint("LEFT", 34, 0)
				thisRow.spellName:SetText(v.fullName) -- initial text, reset later when it needs updated
				thisRow.spellName:SetShadowColor(0, 0, 0)
				thisRow.spellName:SetMaxLines(3) -- hardlimit to 3 lines, but soft limit to 2 later.
				--thisRow.spellNameBackground:SetPoint("RIGHT", thisRow.spellName, "RIGHT", 0, 0) -- move the right edge of the gradient to the right edge of the name

				thisRow.spellIcon = CreateFrame("BUTTON", nil, thisRow)
				local button = thisRow.spellIcon
					button.commID = k
					button:SetPoint("RIGHT", thisRow.spellName, "LEFT", -3, 0)
					button:SetSize(32,32)
					button:SetNormalTexture("Interface/Icons/inv_misc_questionmark")
					button:SetHighlightTexture(ASSETS_PATH .. "/dm-trait-select")
					button.highlight = button:GetHighlightTexture()
					button.highlight:SetPoint("TOPLEFT", -4, 4)
					button.highlight:SetPoint("BOTTOMRIGHT", 4, -4)
					button.border = button:CreateTexture(nil, "OVERLAY")
					button.border:SetTexture(ASSETS_PATH .. "/dm-trait-border")
					button.border:SetPoint("TOPLEFT", -6, 6)
					button.border:SetPoint("BOTTOMRIGHT", 6, -6)

					-- NOTE: INCLUDE THE FORCED TAG ON THIS TOOLTIP, WE EXPECT A TOOLTIP ON THE ICON EVEN IF TOOLTIPS ARE DISABLED
					Tooltip.set(button,function(self) return savedSpellFromVault[self.commID].fullName end,
						function(self)
							local strings = {}
							if savedSpellFromVault[self.commID].description then tinsert(strings, savedSpellFromVault[self.commID].description); end
							tinsert(strings, " ")
							tinsert(strings, "Click to cast "..Tooltip.genContrastText(savedSpellFromVault[self.commID].commID))
							tinsert(strings, "Actions: "..#savedSpellFromVault[self.commID].actions)
							local hotkeyKey = Hotkeys.getHotkeyByCommID(self.commID)
							if hotkeyKey then tinsert(strings, "Hotkey: "..hotkeyKey) end
							tinsert(strings, " ")
							tinsert(strings, Tooltip.genContrastText("Right-Click").." for more options!")
							--tinsert(strings, " ")
							tinsert(strings, Tooltip.genContrastText("Shift-Click").." to link in chat.")
							return strings
					end, {forced = true})

					button:SetScript("OnClick", function(self, button)
						local currentVault = LoadSpellFrame.getCurrentVault()
						if button == "LeftButton" then
							if IsModifiedClick("CHATLINK") then
								ChatLink.linkSpell(savedSpellFromVault[self.commID], currentVault)
								return;
							end
							if currentVault == VAULT_TYPE.PHASE then
								local phaseSpell = Vault.phase.getSpellByIndex(self.commID)
								executeSpell(phaseSpell.actions, nil, phaseSpell.fullName, phaseSpell)
							else
								ARC:CAST(self.commID)
							end
						elseif button == "RightButton" then
							--Show & Update Right-Click Context Menu
							EasyMenu(genDropDownContextOptions(currentVault, self.commID, updateSpellLoadRows), contextDropDownMenu, "cursor", 0 , 0, "MENU");
						end
					end)
					button:RegisterForClicks("LeftButtonUp","RightButtonUp")


				thisRow.hotkeyIcon = CreateFrame("BUTTON", nil, thisRow)
				local button = thisRow.hotkeyIcon
					button.commID = k
					button:SetPoint("CENTER", thisRow.spellIcon, "TOPRIGHT", -4, -5)
					button:SetSize(20,10)
					button:SetNormalTexture("interface/tradeskillframe/ui-tradeskill-linkbutton")
					button.normal = button:GetNormalTexture()
					button.normal:SetTexCoord(0, 1, 0, 0.5)
					button.normal:SetRotation(math.rad(-45))
					button:SetHighlightTexture("interface/tradeskillframe/ui-tradeskill-linkbutton")
					button.hilight = button:GetHighlightTexture()
					button.hilight:SetTexCoord(0, 1, 0, 0.5)
					button.hilight:SetRotation(math.rad(-45))

					Tooltip.set(button, function(self) return "Bound to: "..Hotkeys.getHotkeyByCommID(self.commID) end, {" ","Left-Click to Edit Binding","Shift+Right-Click to Unbind"})
					button:SetFrameLevel(thisRow.spellIcon:GetFrameLevel()+1)
					button:SetScript("OnClick", function(self, button)
						if button == "LeftButton" then
							Popups.showLinkHotkeyDialog(self.commID)
						elseif button == "RightButton" and IsShiftKeyDown() then
							Hotkeys.deregisterHotkeyByComm(self.commID)
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

					UIHelpers.setupCoherentButtonTextures(button, ADDON_PATH.."/assets/icon-x")

					Tooltip.set(button, function(self) return "Delete '"..savedSpellFromVault[self.commID].commID.."'" end)


				-- Make the load button
				thisRow.loadButton = CreateFrame("BUTTON", nil, thisRow)
					local button = thisRow.loadButton
					button.commID = k
					button:SetPoint("RIGHT", thisRow.deleteButton, "LEFT", 0, 0)
					button:SetSize(24,24)
					--button:SetText(EDIT)

					UIHelpers.setupCoherentButtonTextures(button, ADDON_PATH.."/assets/icon-edit")

					button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
					button:SetScript("OnClick", function(self, button)
						if button == "RightButton" then
							table.sort(savedSpellFromVault[self.commID].actions, function (k1, k2) return k1.delay < k2.delay end)
						end
						loadSpell(savedSpellFromVault[self.commID])
					end)
					Tooltip.set(button, function(self) return "Load '"..savedSpellFromVault[self.commID].commID.."'" end, {"Load the spell into the Forge UI so you can edit it.", "\nRight-click to load the ArcSpell, and re-sort it's actions into chronological order by delay."})

				--

				thisRow.gossipButton = CreateFrame("BUTTON", nil, thisRow)
					local button = thisRow.gossipButton
					button.commID = k
					button:SetPoint("TOP", thisRow.deleteButton, "BOTTOM", 0, 0)
					button:SetSize(16,16)

					UIHelpers.setupCoherentButtonTextures(button, "groupfinder-waitdot", true)
					button.NormalTexture:SetVertexColor(1,0.8,0)

					button.speechIcon = button:CreateTexture(nil, "OVERLAY", nil, 7)
					button.speechIcon:SetTexture("interface/gossipframe/chatbubblegossipicon")
					button.speechIcon:SetSize(10,10)
					button.speechIcon:SetTexCoord(1,0,0,1)
					button.speechIcon:SetPoint("CENTER", button, "TOPRIGHT",-2,-1)

					button:SetMotionScriptsWhileDisabled(true)
					button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
					button:SetScript("OnClick", function(self, button)
						Popups.showAddGossipPopup(self.commID)
					end)

					Tooltip.set(button, "Add to Gossip Menu", {
						"With a gossip menu open, click here to add this ArcSpell to an NPC's gossip.",
						"\nThis allows you to link ArcSpells to cast from an NPC's gossip menu.",
						"\nFor example, you could add an ArcSpell with mining animations & an Add Item action, as an '..On Open' with hide, to simulate a mining node.",
					})
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
					button.isPrivate = false
					button:SetSize(16,16)
					button:SetPoint("RIGHT", thisRow.gossipButton, "LEFT", -8, 0)

					--button:SetNormalAtlas("UI_Editor_Eye_Icon")
					UIHelpers.setupCoherentButtonTextures(button, ADDON_PATH.."/assets/icon_visible_32")
					button.HighlightTexture:SetAlpha(0.2) -- override, 0.33 was still too bright on this one

					button:SetMotionScriptsWhileDisabled(true)

					button.SetPrivacy = function(self, priv)
						if not isNotDefined(priv) then self.isPrivate = priv else self.isPrivate = not self.isPrivate end
						if self.isPrivate then
							self:SetNormalTexture(ASSETS_PATH .. "/icon_hidden_32")
							self:GetNormalTexture():SetVertexColor(0.6,0.6,0.6)
							self:SetPushedTexture(ASSETS_PATH .. "/icon_hidden_32")
							self.HighlightTexture:SetTexture(ASSETS_PATH .. "/icon_hidden_32")
						else
							self:SetNormalTexture(ASSETS_PATH .. "/icon_visible_32")
							self:GetNormalTexture():SetVertexColor(0.9,0.65,0)
							self:SetPushedTexture(ASSETS_PATH .. "/icon_visible_32")
							self.HighlightTexture:SetTexture(ASSETS_PATH .. "/icon_visible_32")
						end
						self.PushedTexture:SetVertexColor(self:GetNormalTexture():GetVertexColor())

						return self.isPrivate
					end

					Tooltip.set(button, function(self) if self.isPrivate then return "'"..savedSpellFromVault[self.commID].fullName.."' is Private & visible only to Officers+" else return "'"..savedSpellFromVault[self.commID].fullName.."' is Public & visible to everyone" end end, "Click to change this spell's visibility.")

					button:SetScript("OnClick", function(self)
						if not isOfficerPlus() then eprint("You're not an officer.. You can't toggle a spell's visibility.") return end
						local priv = self:SetPrivacy()
						if priv == nil then priv = false end
						saveSpellToPhaseVault(self.commID, true, true, priv)
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
				thisRow.hotkeyIcon.commID = k
				thisRow.commID = k -- used in new Transfer to Phase Button - all the other ones should probably move to using this anyways..
				thisRow.rowID = rowNum

				if Hotkeys.getHotkeyByCommID(k) then thisRow.hotkeyIcon:Show() else thisRow.hotkeyIcon:Hide() end

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
						if Gossip.isLoaded() then
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

				Tooltip.set(thisRow,function(self) return savedSpellFromVault[self.commID].fullName end,
					function(self)
						local strings = {}
						if savedSpellFromVault[self.commID].description then tinsert(strings, savedSpellFromVault[self.commID].description); end
						tinsert(strings, " ")
						tinsert(strings, "Command: "..Tooltip.genContrastText("/sf "..savedSpellFromVault[self.commID].commID))
						tinsert(strings, "Actions: "..#savedSpellFromVault[self.commID].actions)
						local hotkeyKey = Hotkeys.getHotkeyByCommID(self.commID)
						if hotkeyKey then tinsert(strings, "Hotkey: "..hotkeyKey) end
						tinsert(strings, " ")
						tinsert(strings, Tooltip.genContrastText("Right-Click").." for more options!")
						--tinsert(strings, " ")
						tinsert(strings, Tooltip.genContrastText("Shift-Click").." to link in chat.")
						return strings
				end, {forced = true})

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
					if fontHeight-1 <= 8 then break; end -- don't go smaller than 8 point font. Becomes too hard to read. We'll take a truncated text over that.
				end
			end

			if currentVault == VAULT_TYPE.PHASE and v.private and not (isOfficerPlus() or SpellCreatorMasterTable.Options["debug"]) then
				thisRow:Hide()
				numSkippedRows = numSkippedRows+1
			end
			if v.private then
				thisRow.privateIconButton:SetPrivacy(true)
			else
				thisRow.privateIconButton:SetPrivacy(false)
			end
		end
	end
	MainFrame.updateFrameChildScales(SCForgeMainFrame)
end

---@param fromPhaseVaultID integer?
saveSpell = function (overwriteBypass, fromPhaseVaultID, manualData)

	local wasOverwritten = false
	local newSpellData = {}
	if fromPhaseVaultID then
		local phaseSpell = Vault.phase.getSpellByIndex(fromPhaseVaultID)
		newSpellData.commID = phaseSpell.commID
		newSpellData.fullName = phaseSpell.fullName
		newSpellData.description = phaseSpell.description or nil
		newSpellData.actions = phaseSpell.actions
		newSpellData.castbar = phaseSpell.castbar
		newSpellData.icon = phaseSpell.icon
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
		local existingSpell = Vault.personal.findSpellByID(newSpellData.commID)
		if existingSpell then
			if overwriteBypass then
				wasOverwritten = true
			else
				Popups.showPersonalVaultOverwritePopup(newSpellData, existingSpell, fromPhaseVaultID, manualData, saveSpell)
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
		Vault.personal.saveSpell(newSpellData)
		Attic.setEditCommId(Attic.getInfo().commID)
		SCForgeMainFrame.SaveSpellButton:UpdateIfValid()
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
	return true
end


ImportExport.init(saveSpell)

--------- Load Spell Frame - aka the Vault

SCForgeMainFrame.LoadSpellFrame = LoadSpellFrame.init({
	import = ImportExport.showImportMenu,
	upload = function(commID)
		saveSpellToPhaseVault(commID, IsShiftKeyDown())
	end,
	downloadToPersonal = function (commID)
		Debug.ddump(Vault.phase.getSpellByIndex(commID)) -- Dump the table of the phase vault spell for debug
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
local button = SCForgeMainFrame.LoadSpellFrame.refreshVaultButton
	button:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.LoadSpellFrame.Inset,"TOPRIGHT", -5, 2)
	button:SetSize(24,24)

	UIHelpers.setupCoherentButtonTextures(button, "UI-RefreshButton", true)

	button.animations = button:CreateAnimationGroup()
	button.animations:SetLooping("REPEAT")
	button.animations.rotate = button.animations:CreateAnimation("Rotation")
	local _rot = button.animations.rotate
	_rot:SetDegrees(-360)
	_rot:SetDuration(0.33)

	button:SetScript("OnClick", function(self, button)
		updateSpellLoadRows();
		self.animations:Play()
	end)

	Tooltip.set(button, "Refresh Phase Vault", "Reload the Phase Vault from the server, getting any new changes.")

	button:SetScript("OnEnable", function(self)
		self.animations:Finish()
	end)

SCForgeMainFrame.LoadSpellFrame.profileButton = CreateFrame("BUTTON", nil, SCForgeMainFrame.LoadSpellFrame)
	local _button = SCForgeMainFrame.LoadSpellFrame.profileButton
	_button:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.LoadSpellFrame.Inset,"TOPRIGHT", -5, 2)
	_button:SetSize(24,24)

	-- PartySizeIcon; QuestSharing-QuestLog-Active; QuestSharing-DialogIcon; socialqueuing-icon-group
	UIHelpers.setupCoherentButtonTextures(_button, "socialqueuing-icon-group", true)
	_button.NormalTexture:SetDesaturated(true)
	_button.NormalTexture:SetVertexColor(1,0.8,0)
	_button.PushedTexture:SetVertexColor(1,0.8,0)

	_button:SetScript("OnClick", function(self, button)
		if button == "LeftButton" then
			EasyMenu(ProfileFilterMenu.genProfileFilterDropDown(updateSpellLoadRows), profileDropDownMenu, self, 0 , 0, "DROPDOWN");
		elseif button == "RightButton" then
			EasyMenu(ProfileFilterMenu.genChangeDefaultProfileDropDown(), profileDropDownMenu, self, 0 , 0, "DROPDOWN");
		end
	end)
	_button:RegisterForClicks("LeftButtonUp","RightButtonUp")

	Tooltip.set(_button, "Change Profile", "Switch to another profile to view that profiles vault.\n\rRight-Click to change your default selected profile.", {delay = 0.3})

-------------------------------------------------------------------------------
-- Mini-Map Icon
-------------------------------------------------------------------------------

---comment
---@param where "options" | "enableMMIcon" | nil
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
	if not SpellCreatorMasterTable.Options["minimapIcon"] then MinimapButton.setShown(false) end
end

-------------------------------------------------------------------------------
-- Addon Loaded & Communication
-------------------------------------------------------------------------------
local lockTimer = C_Timer.NewTimer(0, function() end) -- this just inits the lockTimer as a timer table, incase we somehow get the _PUNLOCK before a _PLOCK and then EOROROR
local function onCommReceived(prefix, message, channel, sender)
	if sender == GetUnitName("player") then dprint("onCommReceived bypassed because we're talking to ourselves."); return; end
	if prefix == addonMsgPrefix.."REQ" then
		Comms.sendSpellToPlayer(sender, message)
	elseif prefix == addonMsgPrefix.."SPELL" then
		Comms.receiveSpellData(message, sender, updateSpellLoadRows)
	elseif prefix == addonMsgPrefix.."_CACHE" then
		Comms.receiveSpellCache(message, sender)
	elseif prefix == addonMsgPrefix.."_LCACHE" then
		local localAreaData, spellData = strsplit(strchar(31), message, 2)
		local phase,posY,posX,instanceID,radius = strsplit(":", localAreaData, 5)
		if Comms.isLocal(phase, posY, posX, instanceID, radius) then
			Comms.receiveSpellCache(spellData, sender)
		end
	elseif prefix == addonMsgPrefix.."_PLOCK" then
		local phaseID = C_Epsilon.GetPhaseId()
		if message == phaseID then
			phaseVault.isSavingOrLoadingAddonData = true
			dprint("Phase Vault IO for Phase "..phaseID.." was locked by Addon Message")
			lockTimer = C_Timer.NewTimer(5, function() phaseVault.isSavingOrLoadingAddonData=false; eprint("Phase IO Lock on for longer than 10 seconds - disabled. If you get this after changing phases, ignore, otherwise please report it."); end)
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
	AceComm:RegisterComm(addonMsgPrefix.."_CACHE", onCommReceived)
	AceComm:RegisterComm(addonMsgPrefix.."_LCACHE", onCommReceived)
end

--- Gossip

Gossip.init({
	openArcanum = function()
		scforge_showhide("enableMMIcon")
	end,
	saveToPersonal = function(phaseVaultIndex)
		saveSpell(nil, phaseVaultIndex)
	end,
	loadPhaseVault = function(callback)
		getSpellForgePhaseVault(callback)
	end,
})

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

		Basement.updateExecutePermission()

		return;

	-- Addon Loaded Handler
	elseif event == "ADDON_LOADED" and (name == addonName) then
		local hadUpdate = SavedVariables.init()
		ProfileFilter.init()
		LoadMinimapPosition();
		aceCommInit()
		Hotkeys.updateHotkeys()
		if not SpellCreatorMasterTable.Options["quickcastToggle"] then Quickcast.setShown(false) end

		local channelType, channelName = JoinChannelByName("scforge_comm")
		ns.Constants.ADDON_CHANNEL = GetChannelName("scforge_comm")

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

		Options.createSpellCreatorInterfaceOptions()

		-- Gen the first few spell rows
		SpellRow.addRow()
		SpellRow.addRow()
		SpellRow.addRow()

		Basement.updateExecutePermission()

		if hadUpdate then
			RaidNotice_AddMessage(RaidWarningFrame, "\n\r"..ADDON_COLOR.."Arcanum - Updated to v"..addonVersion.."\n\rCheck-out the Changelog by right-clicking the Mini-map Icon!|r", ChatTypeInfo["RAID_WARNING"])
--			InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE);
--			InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE);
			local titleText = SpellCreatorInterfaceOptions.panel.scrollFrame.Title
			titleText:SetText("Spell Forge - "..ADDON_COLORS.UPDATED:GenerateHexColorMarkup().."UPDATED|r to v"..addonVersion)
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
		Gossip.onGossipShow()
		updateGossipVaultButtons(true)
	elseif event == "GOSSIP_CLOSED" then
		Gossip.onGossipClosed()
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
		local spell = Vault.personal.findSpellByID(msg)
		if spell then
			executeSpell(spell.actions, nil, spell.fullName, spell)
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
			dprint(true, "All Arcanum Spells reset. #GoodBye #ThisCannotBeUndoneHopeYouDidn'tFuckUp!")
			SpellCreatorSavedSpells = {}
			updateSpellLoadRows()
		elseif command == "listSpells" then
			for k,v in orderedPairs(Vault.personal.getSpells()) do
				cprint("ArcSpell: "..k.." =")
				Debug.dump(v)
			end
		elseif command == "listSpellKeys" then -- debug to list all spell keys by alphabetical order.
			local newTable = Vault.personal.getIDs()
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

		elseif command == "clearbinding" then
			if rest and rest ~= "" then
				Hotkeys.deregisterHotkeyByComm(rest)
			end
		elseif command == "clearbindingkey" then
			if rest and rest ~= "" then
				Hotkeys.deregisterHotkeyByKey(rest)
			end
		end
	else
		cprint("DEBUG LIST")
		cprint("Version: "..addonVersion)
		--cprint("RuneIcon: "..runeIconOverlay.atlas or runeIconOverlay.tex)
		cprint("Debug Commands (/sfdebug ...): ")
		print("... debug: Toggles Debug mode on/off. Must be on for these commands to work.")
		print("... clearbinding: Delete's a spell Keybind based on CommID.")
		print("... clearbindingkey: Delete's a spell Keybind based on Key.")
		print("... resetSpells: reset your vault to empty. Cannot be undone.")
		print("... listSpells: List all your vault spells' data.. this is alot of text!")
		print("... listSpellKeys: List all your vault spells by just keys. Easier to read.")
		print("... getPhaseKeys: Lists all the vault spells by keys.")
		print("... getPhaseSpellData [$commID/key]: Exports the spell data for all current keys, or the specified commID/key, to your '"..ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup().."..epsilon/_retail_/WTF/Account/NAME/SavedVariables/SpellCreator.lua|r' file.")
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

local function getSavedSpellFromVaultTable()
	return savedSpellFromVault
end

---@class MainFuncs
ns.MainFuncs = {
	updateSpellLoadRows = updateSpellLoadRows,
	saveSpellToPhaseVault = saveSpellToPhaseVault, -- Move to SpelLStrorage when done
	setSpellProfile = setSpellProfile, -- used in the profile popup, no idea where this should go tbh
	getSavedSpellFromVaultTable = getSavedSpellFromVaultTable, -- I think this would move to spell storage later?
	deleteSpellFromPhaseVault = deleteSpellFromPhaseVault, -- Move to Spell Storage? Vaults?
}
