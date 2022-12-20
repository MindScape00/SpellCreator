local addonName = ...
---@class ns
local ns = select(2, ...)

local ActionsData = ns.Actions.Data
local actionTypeData = ActionsData.actionTypeData
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
local VaultFilter = ns.VaultFilter
local Hotkeys = ns.Actions.Hotkeys

local DataUtils = ns.Utils.Data
local Debug = ns.Utils.Debug
local NineSlice = ns.Utils.NineSlice
local UIHelpers = ns.Utils.UIHelpers
local Tooltip = ns.Utils.Tooltip

local Animation = ns.UI.Animation
local Attic = ns.UI.MainFrame.Attic
local Basement = ns.UI.MainFrame.Basement
local IconPicker = ns.UI.IconPicker
local ImportExport = ns.UI.ImportExport
local Models, Portrait = ns.UI.Models, ns.UI.Portrait
local LoadSpellFrame = ns.UI.LoadSpellFrame
local MainFrame = ns.UI.MainFrame.MainFrame
local MinimapButton = ns.UI.MinimapButton
local Options = ns.UI.Options
local Popups = ns.UI.Popups
local ProfileFilterMenu = ns.UI.ProfileFilterMenu
local Quickcast = ns.UI.Quickcast
local SpellLoadRow = ns.UI.SpellLoadRow
local SpellLoadRowContextMenu = ns.UI.SpellLoadRowContextMenu
local SpellRow = ns.UI.SpellRow
local SpellVaultFrame = ns.UI.SpellVaultFrame

local addonMsgPrefix = Comms.PREFIX
local ADDON_COLOR, ADDON_PATH, ADDON_TITLE = Constants.ADDON_COLOR, Constants.ADDON_PATH, Constants.ADDON_TITLE
local SPELL_VISIBILITY = Constants.SPELL_VISIBILITY
local VAULT_TYPE = Constants.VAULT_TYPE
local executeSpell = Execute.executeSpell
local isOfficerPlus, isMemberPlus = Permissions.isOfficerPlus, Permissions.isMemberPlus
local phaseVault = Vault.phase
local shouldFilter = VaultFilter.shouldFilter
local isNotDefined = DataUtils.isNotDefined
local orderedPairs = DataUtils.orderedPairs

local addonVersion = GetAddOnMetadata(addonName, "Version")

---@type table<CommID, VaultSpell>
local savedSpellFromVault = {}

local saveSpell

-- localized frequent functions for speed
local C_Timer = C_Timer
local print = print
local ipairs = ipairs
--local tContains = tContains
--
-- local curDate = date("*t") -- Current Date for surprise launch - disabled since it's over anyways

local AceComm = ns.Libs.AceComm

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
Attic.init(SCForgeMainFrame, IconPicker)

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
local function loadSpell(spellToLoad)
	--dprint("Loading spell.. "..spellToLoad.commID)

	if Popups.checkAndShowResetForgeConfirmation("load a spell", loadSpell, spellToLoad, true) then
		return
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
			Attic.setAuthorMe()
			Animation.stopFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 0.05, 0.25)
			resetButton:Enable();
		end)
	end,
})

local phaseVaultKeys

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
			Vault.phase.clearSpells()
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

local profileDropDownMenu = CreateFrame("BUTTON", "ARCProfileContextMenu", UIParent, "UIDropDownMenuTemplate")

------------------------

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

	VaultFilter.prepareFilter(currentVault)

	local spellLoadFrame = SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.scrollChild
	local rowNum = 0
	local numSkippedRows = 0
	local thisRow

	for k,v in orderedPairs(savedSpellFromVault) do
	-- this will get an alphabetically sorted list of all spells, and their data. k = the key (commID), v = the spell's data table
		rowNum = rowNum + 1

		if currentVault == VAULT_TYPE.PERSONAL then
			ProfileFilter.ensureProfile(v)
		end

		if shouldFilter(v) then
			dprint("Spell filtered from vault (skipped): " .. k)
			rowNum = rowNum - 1
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

				thisRow = SpellLoadRow.createRow(spellLoadFrame, rowNum)

				if rowNum == 1 or rowNum-1-numSkippedRows < 1 then
					thisRow:SetPoint("TOPLEFT", spellLoadFrame, "TOPLEFT", 8, -8)
				else
					thisRow:SetPoint("TOPLEFT", spellLoadRows[rowNum-1-numSkippedRows], "BOTTOMLEFT", 0, -loadRowSpacing)
				end

				spellLoadRows[rowNum] = thisRow
			end

			SpellLoadRow.updateRow(thisRow, rowNum, k, v)

			if SpellLoadRow.shouldHideRow(v) then
				thisRow:Hide()
				numSkippedRows = numSkippedRows+1
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
		newSpellData.author = phaseSpell.author
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

---@param index integer
local function downloadToPersonal(index)
	Debug.ddump(Vault.phase.getSpellByIndex(index)) -- Dump the table of the phase vault spell for debug
	saveSpell(nil, index)
end

local function updateRows()
	updateSpellLoadRows(phaseVault.isLoaded)
end

ImportExport.init(saveSpell)
VaultFilter.init({
	updateRows = updateRows,
})

--------- Load Spell Frame - aka the Vault

SCForgeMainFrame.LoadSpellFrame = LoadSpellFrame.init({
	import = ImportExport.showImportMenu,
	downloadToPersonal = downloadToPersonal,
	upload = function(commID)
		saveSpellToPhaseVault(commID, IsShiftKeyDown())
	end,
})
SpellLoadRow.init({
	loadSpell = loadSpell,
	upload = function(commID, isPrivate)
		saveSpellToPhaseVault(commID, true, true, isPrivate)
	end,
})
SpellLoadRowContextMenu.init({
	loadSpell = loadSpell,
	downloadToPersonal = downloadToPersonal,
	upload = function(commID)
		saveSpellToPhaseVault(commID)
	end,
	updateRows = updateRows,
})

SCForgeMainFrame.LoadSpellFrame:Hide()
SCForgeMainFrame.LoadSpellFrame.Rows = {}
SCForgeMainFrame.LoadSpellFrame:HookScript("OnShow", function()
	dprint("Updating Spell Load Rows")
	updateSpellLoadRows(phaseVault.isLoaded)
end)

SCForgeMainFrame.LoadSpellFrame.spellVaultFrame = SpellVaultFrame.init(SCForgeMainFrame.LoadSpellFrame)

MainFrame.setResizeWithMainFrame(SCForgeMainFrame.LoadSpellFrame.spellVaultFrame)
MainFrame.setResizeWithMainFrame(SCForgeMainFrame.LoadSpellFrame.searchBox) -- this should be done in the searchBox creation I think but the load order doesn't allow that and I CBF'd fixing it atm..

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
			EasyMenu(ProfileFilterMenu.genProfileFilterDropDown(), profileDropDownMenu, self, 0 , 0, "DROPDOWN");
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
	getSavedSpellFromVaultTable = getSavedSpellFromVaultTable, -- I think this would move to spell storage later?
	deleteSpellFromPhaseVault = deleteSpellFromPhaseVault, -- Move to Spell Storage? Vaults?
}
