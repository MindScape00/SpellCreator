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
local ChatLink = ns.UI.ChatLink
local IconPicker = ns.UI.IconPicker
local ImportExport = ns.UI.ImportExport
local Models, Portrait = ns.UI.Models, ns.UI.Portrait
local LoadSpellFrame = ns.UI.LoadSpellFrame
local MainFrame = ns.UI.MainFrame.MainFrame
local MinimapButton = ns.UI.MinimapButton
local Options = ns.UI.Options
local Popups = ns.UI.Popups
local Quickcast = ns.UI.Quickcast.Quickcast
local SparkPopups = ns.UI.SparkPopups
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

local C_Epsilon = C_Epsilon

-------------------------------------------------------------------------------
-- Simple Chat & Helper Functions
-------------------------------------------------------------------------------

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
background:SetTexture(ADDON_PATH .. "/assets/bookbackground_full")
background:SetVertTile(false)
background:SetHorizTile(false)
background:SetAllPoints()

background.Overlay = SCForgeMainFrame.Inset:CreateTexture(nil, "BACKGROUND")
background.Overlay:SetTexture(ADDON_PATH .. "/assets/forge_ui_bg_anim")
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
SpellRow.addAddRowRow()

---@param spellToLoad VaultSpell
local function loadSpell(spellToLoad)
	--dprint("Loading spell.. "..spellToLoad.commID)

	if Popups.checkAndShowResetForgeConfirmation("load a spell", loadSpell, spellToLoad, true) then
		return
	end

	Attic.updateInfo(spellToLoad)

	---@type VaultSpellAction[]
	local localSpellActions = CopyTable(spellToLoad.actions)
	local numberOfActionsToLoad = #localSpellActions

	-- Adjust the number of available Action Rows
	SpellRow.setNumActiveRows(numberOfActionsToLoad)

	if SpellCreatorMasterTable.Options["loadChronologically"] then
		table.sort(localSpellActions, function(k1, k2) return k1.delay < k2.delay end)
	end

	-- Loop thru actions & set their data
	for rowNum, actionData in ipairs(localSpellActions) do
		SpellRow.setRowAction(rowNum, actionData)
	end

	-- We can safely do this after the rows have changed.
	-- (Not earlier - changing rows triggers the unsaved state b/c it can be done by user)
	Attic.markEditorSaved()
end

---Reset & Clears the Editor UI back to blank
---@param resetButton Button direct reference to the editor button in the basement
local function resetEditorUI(resetButton)
	-- 2 types of reset: Delete all the Rows, and load an empty spell to effectively reset the UI. We're doing both, the delete rows for visual, load for the actual reset
	local emptySpell = {
		["fullName"] = "",
		["commID"] = "",
		["description"] = "",
		["actions"] = { { ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, }, { ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, },
			{ ["vars"] = "", ["actionType"] = "reset", ["delay"] = "", ["selfOnly"] = false, }, },
	}

	resetButton:Disable()

	UIFrameFadeIn(SCForgeMainFrame.Inset.Bg.Overlay, 0.1, 0.05, 0.8)
	Animation.setFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 3, nil, nil, 0.05, 0.8)
	local numActiveRows = SpellRow.getNumActiveRows()
	local resetTime = min(numActiveRows / 40, 0.5)
	local resetPerRowTime = resetTime / numActiveRows
	local deleteRowIter = 0
	for i = numActiveRows, 1, -1 do
		deleteRowIter = deleteRowIter + 1
		C_Timer.After(resetPerRowTime * deleteRowIter, function() SpellRow.removeRow(i) end)
	end

	C_Timer.After(resetTime, function()
		C_Timer.After(0, function()
			Attic.markEditorSaved()
			loadSpell(emptySpell)
			Attic.setAuthorMe()
			Animation.stopFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 0.05, 0.25)
			resetButton:Enable();
		end)
	end)
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
	resetUI = resetEditorUI,
})

local phaseVaultKeys = {}
local phaseVaultKeysCompressed

local function noSpellsToLoad(fake)
	dprint("Phase Has No Spells to load.");
	phaseAddonDataListener:UnregisterEvent("CHAT_MSG_ADDON");
	if not fake then
		if isOfficerPlus() then
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText(
				"Vault is Empty\n\n\rSelect a spell in\ryour personal vault\rand click the Transfer\rbutton below!\n\n\rGo on, add\rsomething fun!");
		else
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("Vault is Empty");
		end
		SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Enable();
	end
	phaseVault.isSavingOrLoadingAddonData = false;
	phaseVault.isLoaded = false;
end

local function generateFailedSpell(commID)
	local spellData = {
		commID = commID,
		fullName = ADDON_COLORS.TOOLTIP_WARNINGRED:WrapTextInColorCode(commID .. " (ERROR)"),
		description = Tooltip.genTooltipText("warning", "This spell failed to load from the Phase Vault. It's data may be corrupted or too large for the server to send to your client."),
		actions = {},
		profile = "Failed to Load",
	}
	return spellData
end

local multiMessageData        = Comms.multiMessageData
local MSG_MULTI_FIRST         = multiMessageData.MSG_MULTI_FIRST
local MSG_MULTI_NEXT          = multiMessageData.MSG_MULTI_NEXT
local MSG_MULTI_LAST          = multiMessageData.MSG_MULTI_LAST
local MAX_CHARS_PER_SEGMENT   = multiMessageData.MAX_CHARS_PER_SEGMENT

local phaseVaultLoadingCount
local phaseVaultLoadingExpected
local messageTicketQueue      = {}
local phaseVaultCommIDQueue   = {}
local phaseVaultLoadingTimers = {}
local maxSpellsPerBatchLoad   = 30
local function processGrabbingSpellDataFromPhaseVault()
	local maxQueue = min(maxSpellsPerBatchLoad, #phaseVaultCommIDQueue)
	for i = 1, maxQueue do
		local v = phaseVaultCommIDQueue[i]
		dprint("Trying to load spell from phase: " .. v)
		local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_S_" .. v)
		messageTicketQueue[messageTicketID] = v -- add it to a fake queue table so we can watch for multiple prefixes... (storing the commID here also incase we need it for debug)
	end
	if #phaseVaultCommIDQueue > maxSpellsPerBatchLoad then
		table.removemulti(phaseVaultCommIDQueue, 1, maxSpellsPerBatchLoad)
		local timerContainer = {}
		timerContainer.timer = C_Timer.NewTimer(0.75, function()
			phaseVaultLoadingTimers[timerContainer] = nil;
			processGrabbingSpellDataFromPhaseVault()
		end)
		phaseVaultLoadingTimers[timerContainer] = timerContainer
	else
		table.wipe(phaseVaultCommIDQueue)
	end
end

local function cancelPendingPhaseVaultLoadingTimers()
	for _, timer in pairs(phaseVaultLoadingTimers) do
		timer:Cancel()
	end
	table.wipe(phaseVaultLoadingTimers)
end

local tempVaultSpellTable = {}
local tempVaultSpellStrings = {}
---@param keys table
---@param callback function?
local function getPhaseVaultDataFromKeys(keys, callback)
	phaseVaultLoadingCount = 0
	phaseVaultLoadingExpected = #keys

	phaseAddonDataListener2:RegisterEvent("CHAT_MSG_ADDON")
	phaseAddonDataListener2:SetScript("OnEvent", function(self, event, prefix, text, channel, sender, ...)
		if event == "CHAT_MSG_ADDON" and messageTicketQueue[prefix] and text then
			local expectedCommID = messageTicketQueue[prefix]
			messageTicketQueue[prefix] = nil -- remove it from the queue.. We'll reset the table next time anyways but whatever.

			--- multi part loading

			if string.match(text, "^[\001]") then        -- if first character is a multi-part identifier - \001 = first, \002 = middle, then we can add it to the strings table, and return with a call to get the next segment
				text = text:gsub("^[\001]", "")          -- remove the control character
				tempVaultSpellStrings[expectedCommID] = {} -- create the sub-table
				tinsert(tempVaultSpellStrings[expectedCommID], text) -- add to the table
				--tempVaultSpellStrings[expectedCommID][1] = text -- add to the table
				dprint("(PhaseVaultData) First Data Received, Asking for Next Segment of " .. expectedCommID)
				local newMultiPartTicket = C_Epsilon.GetPhaseAddonData("SCFORGE_S2_" .. expectedCommID)
				messageTicketQueue[newMultiPartTicket] = expectedCommID
				return
			elseif string.match(text, "^[\002]") then    -- if first character is a multi-part identifier - \001 = first, \002 = middle, then we can add it to the strings table, and return with a call to get the next segment
				text = text:gsub("^[\002]", "")          -- remove the control character
				local position = #tempVaultSpellStrings[expectedCommID] + 1
				tinsert(tempVaultSpellStrings[expectedCommID], text) -- add to the table
				--tempVaultSpellStrings[expectedCommID][position] = text -- add to the table
				dprint("(PhaseVaultData) Middle Data Received, Asking for Next Segment of " .. expectedCommID)
				local newMultiPartTicket = C_Epsilon.GetPhaseAddonData("SCFORGE_S" .. position + 1 .. "_" .. expectedCommID)
				messageTicketQueue[newMultiPartTicket] = expectedCommID
				return
			elseif string.match(text, "^[\003]") then    -- if first character is a last identifier - \003 = last, then we can add it to our table, then concat into a final string to use and continue
				text = text:gsub("^[\003]", "")          -- remove the control character
				tinsert(tempVaultSpellStrings[expectedCommID], text) -- add to the table
				dprint("(PhaseVaultData) Last Popup Data Received, Concat & Save coming up for " .. expectedCommID)

				text = table.concat(tempVaultSpellStrings[expectedCommID], "")

				-- reset our temp data
				tempVaultSpellStrings[expectedCommID] = nil -- erase it!
			else
				dprint("(PhaseVaultData) Data not a multi-part tagged string, continuing to load normally for " .. expectedCommID)
			end

			--- end multi part loading

			local loaded, interAction = pcall(serializer.decompressForAddonMsg, text)
			if not loaded then
				if Permissions.isOfficerPlus() then
					Popups.showCustomGenericConfirmation({
						text = ("Failed to load ArcSpell from the Phase Vault: %s\n\rThe spell data may be corrupted, or too large for the server to send to you, and likely cannot be recovered. You can delete it in the Phase Vault.")
							:format(Tooltip.genContrastText(expectedCommID)),
						showAlert = true,
						acceptText = OKAY,
						cancelText = false,
					})
				end
				tempVaultSpellTable[expectedCommID] = generateFailedSpell(expectedCommID)
			else
				--dprint("Spell found & adding to Phase Vault Table: " .. interAction.commID)
				tempVaultSpellTable[expectedCommID] = interAction
			end
			phaseVaultLoadingCount = phaseVaultLoadingCount + 1
			dprint("phaseVaultLoadingCount: " .. phaseVaultLoadingCount .. " | phaseVaultLoadingExpected: " .. phaseVaultLoadingExpected)
			if phaseVaultLoadingCount == phaseVaultLoadingExpected then
				dprint("All Spells should be loaded, adding them to the vault..")
				for k, v in ipairs(keys) do
					Vault.phase.addSpell(tempVaultSpellTable[v])
				end
				wipe(tempVaultSpellTable)
				dprint("Phase Vault Loading should be done")
				phaseAddonDataListener2:UnregisterEvent("CHAT_MSG_ADDON")
				phaseVault.isSavingOrLoadingAddonData = false
				phaseVault.isLoaded = true

				ns.UI.ItemIntegration.scripts.updateCache(true)

				if callback then callback(true); end
			end
		end
	end)

	for _, v in ipairs(keys) do
		tinsert(phaseVaultCommIDQueue, v)
	end
	processGrabbingSpellDataFromPhaseVault()
end

local tempPhaseVaultKeyStrings = {}
local tempPhaseVaultKeyStringsIter = 0
---@param callback function?
---@param bypassNoSpellsToLoad boolean?
---@param iter integer?
local function getPhaseVaultKeys(callback, bypassNoSpellsToLoad, iter)
	local dataKey = "SCFORGE_KEYS"
	if iter then dataKey = "SCFORGE_KEYS" .. iter + 1 end
	phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
	local messageTicketID = C_Epsilon.GetPhaseAddonData(dataKey)

	phaseAddonDataListener:SetScript("OnEvent", function(self, event, prefix, text, channel, sender, ...)
		if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
			--- multi part loading

			if string.match(text, "^[\001-\002]") then
				tempPhaseVaultKeyStringsIter = tempPhaseVaultKeyStringsIter + 1
				text = text:gsub("^[\001-\002]", "")
				tinsert(tempPhaseVaultKeyStrings, text)
				dprint(nil, "(PhaseVaultKeys) First or Mid-Control Character. Asking for Next Segment!")
				return getPhaseVaultKeys(callback, bypassNoSpellsToLoad, tempPhaseVaultKeyStringsIter)
			elseif string.match(text, "^[\003]") then
				tempPhaseVaultKeyStringsIter = tempPhaseVaultKeyStringsIter + 1
				text = text:gsub("^[\003]", "")
				tinsert(tempPhaseVaultKeyStrings, text)
				dprint(nil, "(PhaseVaultKeys) Last Data Received, Concat & Save coming up!")

				text = table.concat(tempPhaseVaultKeyStrings)

				-- reset temp data
				wipe(tempPhaseVaultKeyStrings)
				tempPhaseVaultKeyStringsIter = 0
			else
				dprint(nil, "(PhaseVaultKeys) Was not multi-part message, continuing to load normal.")
			end

			--- end multi part loading, continue..

			phaseAddonDataListener:UnregisterEvent("CHAT_MSG_ADDON")

			if (#text < 1 or text == "") then
				if not bypassNoSpellsToLoad then
					noSpellsToLoad();
				end
				dprint("Phase Vault Keys string was empty?")
				dprint(text)
				wipe(phaseVaultKeys)
				if callback then callback(phaseVaultKeys, text) end
				return;
			end
			phaseVaultKeys = serializer.decompressForAddonMsg(text)
			if #phaseVaultKeys < 1 then
				if not bypassNoSpellsToLoad then
					noSpellsToLoad();
				end
				dprint("Phase Vault Keys loaded as a table but empty?")
				if callback then callback(phaseVaultKeys, text) end
				return;
			end

			if callback then callback(phaseVaultKeys, text); end
		end
	end)
end

---Upload the phaseVaultKeys to the phase data, using a chunk based system if it's big!
---@param keys table?
local function savePhaseVaultKeys(keys)
	if not keys then keys = phaseVaultKeys end
	phaseVaultKeysCompressed = serializer.compressForAddonMsg(keys)
	local strLength = #phaseVaultKeysCompressed
	if strLength > MAX_CHARS_PER_SEGMENT then
		dprint("PhaseVaultKeys Exceeded MAX_CHARS_PER_SEGMENT : " .. strLength)
		local numEntriesRequired = math.ceil(strLength / MAX_CHARS_PER_SEGMENT)
		for i = 1, numEntriesRequired do
			local strSub = string.sub(phaseVaultKeysCompressed, (MAX_CHARS_PER_SEGMENT * (i - 1)) + 1, (MAX_CHARS_PER_SEGMENT * i))
			if i == 1 then
				strSub = MSG_MULTI_FIRST .. strSub
				--dprint(nil, "SCFORGE_KEYS :: " .. strSub)
				dprint(nil, "SCFORGE_KEYS :: " .. "<trimmed - bulk/first>")
				C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", strSub)
			else
				local controlChar = MSG_MULTI_NEXT
				if i == numEntriesRequired then controlChar = MSG_MULTI_LAST end
				strSub = controlChar .. strSub
				--dprint(nil, "SCFORGE_KEYS" .. i .. " :: " .. strSub)
				dprint(nil, "SCFORGE_KEYS" .. i .. " :: " .. "<trimmed - bulk/mid or last>")
				C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS" .. i, strSub)
			end
		end
	else
		dprint(nil, "PhaseVaultKeys was within MAX_CHARS_PER_SEGMENT, uploaded as a single chunk.")
		C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", phaseVaultKeysCompressed)
	end
end

local function cancelCurrentVaultLoad()
	-- cancel pending loading stuff
	cancelPendingPhaseVaultLoadingTimers()
	table.wipe(phaseVaultCommIDQueue)
	table.wipe(messageTicketQueue)

	-- clear any vault spells
	Vault.phase.clearSpells()

	-- reset all the temp tables
	tempPhaseVaultKeyStrings = {}
	tempPhaseVaultKeyStringsIter = 0
	tempVaultSpellTable = {}
	tempVaultSpellStrings = {}

	-- clear loading status
	phaseVault.isSavingOrLoadingAddonData = false
end

---@param callback function?
---@param iter integer?
local function getSpellForgePhaseVault(callback, iter)
	if not iter then
		cancelCurrentVaultLoad()
		dprint("Phase Spell Vault Loading...")
	end

	if phaseVault.isSavingOrLoadingAddonData and not iter then
		eprint("Arcanum is already loading or saving a spell. To avoid data corruption, you can't do that right now. Try again shortly.");
		return;
	end
	phaseVault.isSavingOrLoadingAddonData = true
	phaseVault.isLoaded = false

	getPhaseVaultKeys(function()
		dprint("Phase spell keys: ")
		Debug.ddump(phaseVaultKeys)
		Vault.phase.clearSpells()
		table.wipe(messageTicketQueue)
		getPhaseVaultDataFromKeys(phaseVaultKeys, callback)
	end)
end

local function sendPhaseVaultIOLock(toggle)
	local scforge_ChannelID = ns.Constants.ADDON_CHANNEL
	SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:SetEnabled(not toggle)
	local phaseID = C_Epsilon.GetPhaseId()
	if toggle == true then
		AceComm:SendCommMessage(addonMsgPrefix .. "_PLOCK", phaseID, "CHANNEL", tostring(scforge_ChannelID))
		dprint("Sending Lock Phase Vault IO Message for phase " .. phaseID)
	elseif toggle == false then
		AceComm:SendCommMessage(addonMsgPrefix .. "_PUNLOCK", phaseID, "CHANNEL", tostring(scforge_ChannelID))
		dprint("Sending Unlock Phase Vault IO Message for phase " .. phaseID)
	end
end

---@param vaultIndex integer
---@param callback function?
local function deleteSpellFromPhaseVault(vaultIndex, callback)
	-- get the phase spell keys, remove the one we want to delete, then re-save it, and then over-ride the PhaseAddonData for it's key with nothing..
	local realCommID = savedSpellFromVault[vaultIndex].commID

	if phaseVault.isSavingOrLoadingAddonData then
		eprint("Arcanum is already loading or saving a spell. To avoid data corruption, you can't do that right now. Try again in a moment.");
		return;
	end

	phaseVault.isSavingOrLoadingAddonData = true
	sendPhaseVaultIOLock(true)

	getPhaseVaultKeys(function()
		for k, v in ipairs(phaseVaultKeys) do
			if v == realCommID then
				table.remove(phaseVaultKeys, k) -- solves if they load out of order..
			end
		end
		savePhaseVaultKeys()

		dprint("Removing PhaseAddonData for SCFORGE_S_" .. realCommID)
		C_Epsilon.SetPhaseAddonData("SCFORGE_S_" .. realCommID, "")

		phaseVault.isSavingOrLoadingAddonData = false
		sendPhaseVaultIOLock(false)
		if callback then callback(); end
	end)
end

---@param commID CommID
---@param data any
local function uploadSpellDataToPhaseData(commID, data)
	local str = serializer.compressForAddonMsg(data)
	local keyRaw = "SCFORGE_S_" .. commID
	local keyFormat = "SCFORGE_S%s_" .. commID
	local strLength = #str
	if strLength > MAX_CHARS_PER_SEGMENT then
		dprint("Spell Data (" .. commID .. ") Exceeded MAX_CHARS_PER_SEGMENT : " .. strLength)
		local numEntriesRequired = math.ceil(strLength / MAX_CHARS_PER_SEGMENT)
		for i = 1, numEntriesRequired do
			local strSub = string.sub(str, (MAX_CHARS_PER_SEGMENT * (i - 1)) + 1, (MAX_CHARS_PER_SEGMENT * i))
			if i == 1 then
				strSub = MSG_MULTI_FIRST .. strSub
				--dprint(nil, keyRaw .. " :: " .. strSub)
				dprint(nil, keyRaw .. " :: " .. "<trimmed - bulk/first>")
				C_Epsilon.SetPhaseAddonData(keyRaw, strSub)
			else
				local controlChar = MSG_MULTI_NEXT
				local keyFormatted = keyFormat:format(tostring(i))
				if i == numEntriesRequired then controlChar = MSG_MULTI_LAST end
				strSub = controlChar .. strSub
				--dprint(nil, keyFormatted .. " :: " .. strSub)
				dprint(nil, keyFormatted .. " :: " .. "<trimmed - bulk/mid or last>")
				C_Epsilon.SetPhaseAddonData(keyFormatted, strSub)
			end
		end
	else
		--dprint(nil, keyRaw .. " :: " .. str)
		dprint(nil, keyRaw .. " :: " .. "<trimmed - solo>")
		C_Epsilon.SetPhaseAddonData(keyRaw, str)
	end
end

---@param commID CommID | integer commID if from personal vault, index if from phase vault
---@param overwrite boolean?
---@param fromPhase boolean?
---@param forcePrivate boolean?
local function saveSpellToPhaseVault(commID, overwrite, fromPhase, forcePrivate)
	local needToOverwrite = false
	local phaseVaultIndex
	if not commID then
		eprint("Invalid CommID.")
		return;
	end
	if fromPhase then
		if not phaseVault.isLoaded then
			eprint("CRITICAL ERROR: TRYING TO SAVE TO PHASE WHILE THE PHASE VAULT IS NOT LOADED, OH NO! Abort.. (try again in a moment)")
			return
		end
		phaseVaultIndex = commID
		local theSpell = Vault.phase.getSpellByIndex(phaseVaultIndex)
		if not theSpell then
			eprint("No Spell Found with the index (" .. phaseVaultIndex .. ") in the phase vault? (try again in a moment?)")
			return
		end
		commID = theSpell.commID
	end
	if phaseVault.isSavingOrLoadingAddonData then
		eprint("Arcanum is already loading or saving a spell. To avoid data corruption, you can't do that right now. Try again in a moment.");
		return;
	end
	if isMemberPlus() then
		dprint("Trying to save spell to phase vault.")

		getPhaseVaultKeys(function()
			phaseVault.isSavingOrLoadingAddonData = true
			sendPhaseVaultIOLock(true)

			dprint("Phase spell keys: ")
			Debug.ddump(phaseVaultKeys)

			for k, v in ipairs(phaseVaultKeys) do
				if v == commID then
					if not overwrite then
						-- phase already has this ID saved.. Handle over-write...
						dprint("Phase already has a spell saved by Command '" .. commID .. "'. Prompting to confirm over-write.")
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
				dprint(nil, "Force Vis was set to " .. tostring(forcePrivate))
			end

			uploadSpellDataToPhaseData(commID, _spellData)

			if not needToOverwrite then
				tinsert(phaseVaultKeys, commID)

				savePhaseVaultKeys(phaseVaultKeys)
			end

			cprint("Spell '" .. commID .. "' saved to the Phase Vault.")
			phaseVault.isSavingOrLoadingAddonData = false
			sendPhaseVaultIOLock(false)
			getSpellForgePhaseVault()
		end, true)
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
------------------------

local loadRowSpacing = 5

---@param fromPhaseDataLoaded boolean?
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
		SCForgeMainFrame.LoadSpellFrame.TitleBgColor:SetColorTexture(0.30, 0.10, 0.40, 0.5)
		SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Show()
		SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Disable()
		SCForgeMainFrame.LoadSpellFrame.ImportSpellButton:Show()
		SCForgeMainFrame.LoadSpellFrame.SparkManagerButton:Hide()
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
		SCForgeMainFrame.LoadSpellFrame.SparkManagerButton:Show()
		SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:Show()
		SCForgeMainFrame.LoadSpellFrame.TitleBgColor:SetColorTexture(0.20, 0.40, 0.50, 0.5)
		if fromPhaseDataLoaded then
			-- called from getSpellForgePhaseVault() - that means our saved spell from Vault is ready -- you can call with true also to skip loading the vault, if you know it's already loaded.
			savedSpellFromVault = Vault.phase.getSpells()
			dprint("Phase Spell Vault Loaded.")
			SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Enable()
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("")
		else
			if not phaseVault.isSavingOrLoadingAddonData then
				getSpellForgePhaseVault(updateSpellLoadRows)
			end
			SCForgeMainFrame.LoadSpellFrame.refreshVaultButton:Disable()
			SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.LoadingText:SetText("Loading...")
		end
	end

	VaultFilter.prepareFilter(currentVault)

	local spellLoadFrame = SCForgeMainFrame.LoadSpellFrame.spellVaultFrame.scrollChild
	local rowNum = 0
	local numSkippedRows = 0
	local thisRow
	local lastShownRow

	for k, v in orderedPairs(savedSpellFromVault) do
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
				--dprint(false, "SCForge Load Row " .. rowNum .. " Already existed - showing & setting it")

				-- Position the Rows
				if rowNum == 1 or rowNum - 1 - numSkippedRows < 1 then
					thisRow:SetPoint("TOPLEFT", spellLoadFrame, "TOPLEFT", 8, -8)
				else
					thisRow:SetPoint("TOPLEFT", spellLoadRows[lastShownRow], "BOTTOMLEFT", 0, -loadRowSpacing)
				end
			else
				--dprint(false, "SCForge Load Row " .. rowNum .. " Didn't exist - making it!")

				thisRow = SpellLoadRow.createRow(spellLoadFrame, rowNum)

				if rowNum == 1 or rowNum - 1 - numSkippedRows < 1 then
					thisRow:SetPoint("TOPLEFT", spellLoadFrame, "TOPLEFT", 8, -8)
				else
					thisRow:SetPoint("TOPLEFT", spellLoadRows[lastShownRow], "BOTTOMLEFT", 0, -loadRowSpacing)
				end

				spellLoadRows[rowNum] = thisRow
			end

			SpellLoadRow.updateRow(thisRow, rowNum, k, v)

			if SpellLoadRow.shouldHideRow(v) then
				thisRow:Hide()
				numSkippedRows = numSkippedRows + 1
			else
				lastShownRow = rowNum
			end
		end
	end
	MainFrame.updateFrameChildScales(SCForgeMainFrame)

	ns.UI.SpellBookUI.updateArcSpellBook()
end

---@param overwriteBypass boolean? did we want to overwrite a spell if it exists already
---@param fromPhaseVaultID integer? the index of the vault spell to save, if we are saving from the phase vault
---@param manualData VaultSpell? manual data passed in to save, instead of pulling from the phaseVault or from the forge UI
---@param sendLearnedMessage boolean? if we should send a fun 'You have learned a new ArcSpell' message
---@param callback function? optional callback function if it succeeds
saveSpell = function(overwriteBypass, fromPhaseVaultID, manualData, sendLearnedMessage, callback)
	local wasOverwritten = false
	local newSpellData = {}
	if fromPhaseVaultID then
		local phaseSpell = Vault.phase.getSpellByIndex(fromPhaseVaultID)
		-- this was setup originally to manually copy each VaultSpell field, except profile (to avoid copying profile). This is stupid, let's just nil profile every time instead..

		newSpellData = CopyTable(phaseSpell)
		newSpellData.profile = nil -- hard set profile to nil; will be set later by ensureProfile

		dprint("Saving Spell from Phase Vault, fake commID: " .. fromPhaseVaultID .. ", real commID: " .. newSpellData.commID)
	elseif manualData then
		newSpellData = manualData
		Debug.ddump(manualData)
		dprint("Saving Manual Spell Data (Import): " .. newSpellData.commID)
	else
		newSpellData = Attic.getInfo()
		if newSpellData.castbar == 1 then newSpellData.castbar = nil end -- data space saving - default is castbar, so if it's 1 for castbar, let's save the storage and leave it nil
		newSpellData.actions = {}
	end

	ProfileFilter.ensureProfile(newSpellData)
	ProfileFilter.toggleFilter(newSpellData.profile, true)

	if isNotDefined(newSpellData.fullName) or isNotDefined(newSpellData.commID) then
		cprint("Spell Name and/or Spell Command cannot be blank.")
		return;
	end

	local existingSpell = Vault.personal.findSpellByID(newSpellData.commID)
	if existingSpell then
		if overwriteBypass then
			wasOverwritten = true
		else
			Popups.showPersonalVaultOverwritePopup(newSpellData, existingSpell, fromPhaseVaultID, manualData, saveSpell, sendLearnedMessage, callback)
			return;
		end
	end

	if not fromPhaseVaultID and not manualData then
		for i = 1, SpellRow.getNumActiveRows() do
			local rowData = SpellRow.getRowAction(i)

			if rowData and rowData.delay >= 0 then
				if actionTypeData[rowData.actionType] then
					table.insert(newSpellData.actions, CopyTable(rowData))
					dprint(false, "Action Row " .. i .. " Captured successfully.. pending final save to data..")
				else
					dprint(false, "Action Row " .. i .. " Failed to save - invalid Action Type.")
				end
			else
				dprint(false, "Action Row " .. i .. " Failed to save - invalid Main Delay.")
			end
		end
	end

	if #newSpellData.actions >= 1 then
		Vault.personal.saveSpell(newSpellData)
		Attic.setEditCommId(Attic.getInfo().commID)
		SCForgeMainFrame.SaveSpellButton:UpdateIfValid()
		if sendLearnedMessage then
			print(ADDON_COLORS.LIGHT_PURPLE:WrapTextInColorCode(("You have learned a new ArcSpell: %s"):format(ChatLink.generateSpellLink(newSpellData, "PERSONAL"))))
		elseif wasOverwritten then
			cprint("Over-wrote spell with name: " .. newSpellData.fullName .. ". Use command: '/sf " .. newSpellData.commID .. "' to cast it! (" .. #newSpellData.actions .. " actions).")
		else
			cprint("Saved spell with name: " .. newSpellData.fullName .. ". Use command: '/sf " .. newSpellData.commID .. "' to cast it! (" .. #newSpellData.actions .. " actions).")
		end
	else
		cprint("Spell has no valid actions and was not saved. Please double check your actions & try again. You can turn on debug mode to see more information when trying to save (/sfdebug).")
		return false
	end
	if not fromPhaseVaultID then
		updateSpellLoadRows()
	end
	if manualData and newSpellData.items and next(newSpellData.items) then
		ns.UI.ItemIntegration.manageUI.checkIfNeedItems(newSpellData)
	end

	if callback then callback() end
	return true
end

---@param index integer
---@param vocal boolean?
---@param callback function?
local function downloadToPersonal(index, vocal, callback)
	Debug.ddump(Vault.phase.getSpellByIndex(index)) -- Dump the table of the phase vault spell for debug
	saveSpell(nil, index, nil, vocal, callback)
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
	import = ImportExport.showImportSpellMenu,
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
button.HighlightTexture:SetWidth(button:GetTextWidth() + 31)
button:SetScript("OnClick", function(self)
	PanelTemplates_SetTab(SCForgeMainFrame.LoadSpellFrame, 1)
	updateSpellLoadRows()
end)
button:SetScript("OnShow", function(self)
	self.Text:SetText(self.text)
	self.HighlightTexture:SetWidth(self:GetTextWidth() + 31)
	PanelTemplates_TabResize(self, 0)
end)

SCForgeMainFrame.LoadSpellFrame.TabButton2 = CreateFrame("BUTTON", "$parentTab2", SCForgeMainFrame.LoadSpellFrame, "TabButtonTemplate")
local button = SCForgeMainFrame.LoadSpellFrame.TabButton2
button.text = "Phase"
button.id = 2
button:SetPoint("LEFT", SCForgeMainFrame.LoadSpellFrame.TabButton1, "RIGHT", 0, 0)
--PanelTemplates_TabResize(button, 0)
button.HighlightTexture:SetWidth(button:GetTextWidth() + 31)
button:SetScript("OnClick", function(self)
	PanelTemplates_SetTab(SCForgeMainFrame.LoadSpellFrame, 2)
	updateSpellLoadRows(phaseVault.isLoaded)
end)
button:SetScript("OnShow", function(self)
	self.Text:SetText(self.text)
	self.HighlightTexture:SetWidth(self:GetTextWidth() + 31)
	PanelTemplates_TabResize(self, 0)
end)

PanelTemplates_SetNumTabs(SCForgeMainFrame.LoadSpellFrame, 2)
PanelTemplates_SetTab(SCForgeMainFrame.LoadSpellFrame, 1)

SCForgeMainFrame.LoadSpellFrame.refreshVaultButton = CreateFrame("BUTTON", nil, SCForgeMainFrame.LoadSpellFrame)
local button = SCForgeMainFrame.LoadSpellFrame.refreshVaultButton
button:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.LoadSpellFrame.Inset, "TOPRIGHT", -5, 2)
button:SetSize(24, 24)

UIHelpers.setupCoherentButtonTextures(button, "UI-RefreshButton", true)

button.animations = button:CreateAnimationGroup()
button.animations:SetLooping("REPEAT")
button.animations.rotate = button.animations:CreateAnimation("Rotation")
local _rot = button.animations.rotate
_rot:SetDegrees(-360)
_rot:SetDuration(0.33)

button:SetScript("OnClick", function(self, button)
	updateSpellLoadRows();
	SparkPopups.SparkPopups.getPopupTriggersFromPhase()
	self.animations:Play()
end)

Tooltip.set(button, "Refresh Phase Vault", "Reload the Phase Vault from the server, getting any new changes.")

button:SetScript("OnEnable", function(self)
	self.animations:Finish()
end)

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

local vaultLockTimer = C_Timer.NewTimer(0, function()
end) -- this just inits the lockTimer as a timer table, incase we somehow get the _PUNLOCK before a _PLOCK and then EOROROR
local sparkLockTimer = C_Timer.NewTimer(0, function()
end) -- this just inits the lockTimer as a timer table, incase we somehow get the _PUNLOCK before a _PLOCK and then EOROROR
local aceCommReceivedHandlers = {
	[addonMsgPrefix .. "REQ"] = function(prefix, message, channel, sender)
		Comms.sendSpellToPlayer(sender, message)
	end,
	[addonMsgPrefix .. "SPELL"] = function(prefix, message, channel, sender)
		Comms.receiveSpellData(message, sender, updateSpellLoadRows)
	end,
	[addonMsgPrefix .. "_CACHE"] = function(prefix, message, channel, sender)
		Comms.receiveSpellCache(message, sender)
	end,
	[addonMsgPrefix .. "_LCACHE"] = function(prefix, message, channel, sender)
		local localAreaData, spellData = strsplit(strchar(31), message, 2)
		local phase, posY, posX, instanceID, radius = strsplit(":", localAreaData, 5)
		if Comms.isLocal(phase, posY, posX, instanceID, radius) then
			Comms.receiveSpellCache(spellData, sender)
		end
	end,
	[addonMsgPrefix .. "_PLOCK"] = function(prefix, message, channel, sender)
		local phaseID = C_Epsilon.GetPhaseId()
		if message == phaseID then
			phaseVault.isSavingOrLoadingAddonData = true
			dprint("Phase Vault IO for Phase " .. phaseID .. " was locked by Addon Message")
			vaultLockTimer = C_Timer.NewTimer(5,
				function()
					phaseVault.isSavingOrLoadingAddonData = false;
					eprint("Phase Vault IO Lock on for longer than 5 seconds - disabled. If you get this after changing phases or a lag spike, ignore, otherwise please report it.");
				end)
		end
	end,
	[addonMsgPrefix .. "_PUNLOCK"] = function(prefix, message, channel, sender)
		local phaseID = C_Epsilon.GetPhaseId()
		if message == phaseID then
			phaseVault.isSavingOrLoadingAddonData = false
			dprint("Phase Vault IO for Phase " .. phaseID .. " was unlocked by Addon Message")
			vaultLockTimer:Cancel()
			if phaseVault.isLoaded then getSpellForgePhaseVault((SCForgeMainFrame.LoadSpellFrame:IsShown() and updateSpellLoadRows or nil)) end
		end
	end,
	[addonMsgPrefix .. "_SLOCK"] = function(prefix, message, channel, sender)
		local phaseID = C_Epsilon.GetPhaseId()
		if message == phaseID then
			SparkPopups.SparkPopups.setSparkLoadingStatus(true)
			dprint("Phase Spark IO for Phase " .. phaseID .. " was locked by Addon Message")
			sparkLockTimer = C_Timer.NewTimer(5, function()
				SparkPopups.SparkPopups.setSparkLoadingStatus(false)
				eprint("Phase Spark IO Lock on for longer than 5 seconds - disabled. If you get this after changing phases or a lag spike, ignore, otherwise please report it.");
			end)
		end
	end,
	[addonMsgPrefix .. "_SUNLOCK"] = function(prefix, message, channel, sender)
		local phaseID = C_Epsilon.GetPhaseId()
		if message == phaseID then
			SparkPopups.SparkPopups.setSparkLoadingStatus(false)
			dprint("Phase Spark IO for Phase " .. phaseID .. " was unlocked by Addon Message")
			sparkLockTimer:Cancel()
			SparkPopups.SparkPopups.getPopupTriggersFromPhase()
		end
	end,
	[addonMsgPrefix .. "_SPARKCD"] = function(prefix, message, channel, sender)
		--local curPhaseID = C_Epsilon.GetPhaseId()
		local phaseID, cdTime, sparkCDNameOverride = strsplit(":", message, 3)
		local commID, locData = strsplit(string.char(31), sparkCDNameOverride, 2)
		ns.Actions.Cooldowns.addSparkCooldown(sparkCDNameOverride, cdTime, commID, phaseID)
	end,
	[addonMsgPrefix .. "_PSUP"] = function(prefix, message, channel, sender)
		local curPhaseID = C_Epsilon.GetPhaseId()
		local phaseID, commID = strsplit(string.char(31), message, 2)
		if phaseID == curPhaseID then
			getPhaseVaultDataFromKeys({ commID }, function() updateSpellLoadRows(true) end)
		end
	end,
}

local function aceCommInit()
	for k, v in pairs(aceCommReceivedHandlers) do
		AceComm:RegisterComm(k, function(prefix, message, channel, sender)
			if sender == Constants.CHARACTER_NAME then
				dprint("aceCommReceivedHandler bypassed because we're talking to ourself.");
				return;
			end
			v(prefix, message, channel, sender)
		end)
	end
end

--- Gossip

Gossip.init({
	openArcanum = function()
		scforge_showhide("enableMMIcon")
	end,
	saveToPersonal = function(phaseVaultIndex, sendLearnedMessage)
		saveSpell(nil, phaseVaultIndex, nil, sendLearnedMessage)
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

if not C_Epsilon.IsDM then C_Epsilon.IsDM = false end

local function phaseChangeHandler()
	-- // Reset our PhaseVault loading since we changed phase and should no longer be tracking that we are loading - if they were loading, it will likely fail anyways.
	phaseVault.isSavingOrLoadingAddonData = false
	phaseVault.isLoaded = false
	cancelCurrentVaultLoad() -- force this immediately so we cancel any currently loading spells.

	-- // Reset phase DM tracker - TODO : this should move to the Epsilon AddOn later..
	C_Epsilon.IsDM = false

	-- // Update our spell Load Rows & get the phase vault from the new phase
	getSpellForgePhaseVault(SCForgeMainFrame.LoadSpellFrame:IsVisible() and updateSpellLoadRows or nil);
	updateSpellLoadRows();

	-- // Close the Spark manager & creation UIs, since we are changing phase
	SparkPopups.CreateSparkUI.closeSparkCreationUI()
	SparkPopups.SparkManagerUI.hideSparkManagerUI()

	-- // Load the sparks from the phase
	SparkPopups.SparkPopups.setSparkLoadingStatus(false)
	SparkPopups.SparkPopups.getPopupTriggersFromPhase()

	-- // Update the basement for permissions
	Basement.updateExecutePermission()
end

local function addonLoadedHandler()
	local hadUpdate = SavedVariables.init()
	ProfileFilter.init()
	LoadMinimapPosition();
	aceCommInit()
	Hotkeys.updateHotkeys()
	--SparkPopups.SparkPopups.setSparkKeybind(SpellCreatorMasterTable.Options.sparkKeybind) -- handled by delayed one now
	Quickcast.init()
	ns.UI.ItemIntegration.scripts.updateCache(true)
	C_Timer.After(5, ns.UI.ActionButton.loadActionButtonsFromRegister)

	hooksecurefunc("SetUIVisibility", function(shown)
		if shown then
			UIErrorsFrame:SetParent(UIParent)
			RaidWarningFrame:SetParent(UIParent)
		else
			UIErrorsFrame:SetParent(nil)
			RaidWarningFrame:SetParent(nil)
		end
	end)

	local broadcastChannelName = ns.Constants.broadcastChannelName
	local channelType, channelName = JoinChannelByName(broadcastChannelName)
	ns.Constants.ADDON_CHANNEL = GetChannelName(broadcastChannelName)

	--Quickly Show / Hide the Frame on Start-Up to initialize everything for key bindings & loading
	C_Timer.After(1, function()
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

	Options.newOptionsInit()

	-- Gen the first few spell rows
	C_Timer.After(0, function() -- TODO: Check if this is actually efficient or just making it worse lol
		SpellRow.addRow()
		SpellRow.addRow()
		SpellRow.addRow()
	end)

	Basement.updateExecutePermission()

	if hadUpdate then
		local updateMessage = ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode(("Arcanum has been Updated to v%s!"):format(addonVersion))
		C_Timer.After(1, function()
			RaidNotice_AddMessage(RaidWarningFrame, updateMessage, ChatTypeInfo["RAID_WARNING"])
			RaidNotice_AddMessage(RaidWarningFrame, ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode("Check-out the Changelog below, or by right-clicking the Mini-map Icon later!"),
				ChatTypeInfo["RAID_WARNING"])
		end)
		C_Timer.After(1, function() ns.UI.WelcomeUI.WelcomeMenu.showWelcomeScreen(true) end)
		--local changelogFrame = ns.UI.Options.changelogFrame
		--changelogFrame:SetShown(true);
		--changelogFrame:Raise()
		--			InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE);
		--			InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE);
		--	local titleText = SpellCreatorInterfaceOptions.panel.scrollFrame.Title
		--	titleText:SetText("Spell Forge - " .. ADDON_COLORS.UPDATED:GenerateHexColorMarkup() .. "UPDATED|r to v" .. addonVersion)
		--	titleText.Backdrop:SetSize(titleText:GetWidth() - 4, titleText:GetHeight() / 2)
	end
end

local function addonLoadedHandler_Delayed()
	SavedVariables.delayed_init()
end

------------------------------------
-- // Event Handler Functions
------------------------------------

-- Show custom warning messages when common attempts to use protected functions
local function addonActionBlockedHandler(addon, func)
	--print("addonActionBlockedHandler", addon, func)
	if func == "SendChatMessage()" then
		eprint("SendChatMessage Errored: /say & /yell cannot be used on timed actions while outdoors.")
	elseif addon == addonName then
		eprint("Arcanum was blocked from performing the following Action as it is a protected function: " .. func)
	end
end

------------------------------------
-- // Event Listener Frame & System
------------------------------------

local SC_Event_Listener = CreateFrame("frame");

local scEventHandlers = {
	ADDON_ACTION_BLOCKED = addonActionBlockedHandler,
	SCENARIO_UPDATE = phaseChangeHandler,
	PLAYER_ENTERING_WORLD = function(isInitialLogin, isReloadingUi)
		C_Timer.After(0, function()
			phaseChangeHandler()
			dprint("PLAYER_ENTERING_WORLD: " .. C_Epsilon.GetPhaseId())
		end)
		if isInitialLogin then
			Hotkeys.updateHotkeys()
			--SparkPopups.SparkPopups.setSparkKeybind(SpellCreatorMasterTable.Options.sparkKeybind) -- handled by delayed one now
		end
	end,
	ADDON_LOADED = function(nameVar)
		if nameVar == addonName then
			addonLoadedHandler()
		end
	end,
	UI_ERROR_MESSAGE = function(var1, ...)
		local errType, msg = var1, ...
		if msg == "DM mode is ON" then
			C_Epsilon.IsDM = true;
			dprint("DM Mode On");
		elseif msg == "DM mode is OFF" then
			C_Epsilon.IsDM = false;
			dprint("DM Mode Off");
		end
	end,
	GOSSIP_SHOW = function()
		Gossip.onGossipShow()
		updateGossipVaultButtons(true)
	end,
	GOSSIP_CLOSED = function()
		Gossip.onGossipClosed()
		updateGossipVaultButtons(false)
	end,
	VARIABLES_LOADED = function()
		dprint("VARIABLES_LOADED, initializing delayed addonLoadedHandler")
		C_Timer.After(0.5, addonLoadedHandler_Delayed)  -- Must delay to next frame, but we do 0.5 to be safe & ensure Blizzard's shit is actually loaded.
	end,
	--[[ -- Unused for now. Note, this may only be reliable if the phase has any hotfix data it needs to pull when you enter it?
	INITIAL_HOTFIXES_APPLIED = function()

	end,
	--]]
}

for k in pairs(scEventHandlers) do
	SC_Event_Listener:RegisterEvent(k)
end

SC_Event_Listener:SetScript("OnEvent", function(self, event, var1, ...)
	if scEventHandlers[event] then scEventHandlers[event](var1, ...) end
end);


-------------------------------------------------------------------------------
-- Version / Help / Toggle
-------------------------------------------------------------------------------

SLASH_SCFORGEMAIN1, SLASH_SCFORGEMAIN2 = '/arcanum', '/sf'; -- 3.
function SlashCmdList.SCFORGEMAIN(msg, editbox)             -- 4.
	if #msg > 0 then
		dprint(false, "Casting Arcanum Spell by CommID: " .. msg)
		local spell = Vault.personal.findSpellByID(msg)
		if spell then
			executeSpell(spell.actions, nil, spell.fullName, spell)
		elseif msg == "options" then
			scforge_showhide("options")
		else
			cprint("No spell with Command " .. msg .. " found.")
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
		dprint(true, "SC-Forge Debug Set to: " .. tostring(SpellCreatorMasterTable.Options["debug"]))
		return;
	end
	if SpellCreatorMasterTable.Options["debug"] and msg ~= "" then
		if command == "resetSpells" then
			dprint(true, "All Arcanum Spells reset. #GoodBye #ThisCannotBeUndoneHopeYouDidn'tFuckUp!")
			SpellCreatorSavedSpells = {}
			updateSpellLoadRows()
		elseif command == "listSpells" then
			for k, v in orderedPairs(Vault.personal.getSpells()) do
				cprint("ArcSpell: " .. k .. " =")
				Debug.dump(v)
			end
		elseif command == "listSpellKeys" then -- debug to list all spell keys by alphabetical order.
			local newTable = Vault.personal.getIDs()
			table.sort(newTable)
			Debug.dump(newTable)
		elseif command == "resetPhaseSpellKeys" then
			if rest == "confirm" then
				C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", "")
				dprint(true,
					"Wiped all Spell Keys from Phase Vault memory. This does not wipe the data itself of the spells, so they can technically be recovered by manually adding the key back, or either exporting the data yourself using '/sfdebug getPhaseSpellData $commID' where commID is the command it was saved as...")
			else
				dprint(true, "resetPhaseSpellKeys -- WARNING: YOU ARE ABOUT TO WIPE ALL OF YOUR PHASE VAULT. You need to add 'confirm' after this command in order for it to work.")
			end
		elseif command == "removePhaseKey" then
			if rest and tostring(rest) and rest ~= "" then
				rest = tostring(rest)

				getPhaseVaultKeys(function()
					local didDeleteKey = false
					for k, v in ipairs(phaseVaultKeys) do
						if v == rest then
							didDeleteKey = true
							tremove(phaseVaultKeys, k)
							dprint(true, "Deleted Phase Key: " .. rest)
						end
					end
					if didDeleteKey then
						savePhaseVaultKeys(phaseVaultKeys)
					else
						dprint(true, "Phase Key comm ID [" .. rest .. "] doesn't seem to exist.")
					end
				end, true)
			else
				dprint(true,
					"removePhaseKey -- You need to provide the comm ID (from getPhaseKeys) of the key to remove. This does not remove the spells data, only removes it's key from the key list, although you will not be able to access the spell afterwords.")
			end
		elseif command == "getPhaseSpellData" then
			local interAction
			if rest and rest ~= "" then
				dprint(true, "Retrieving Phase Vault Data for Key: '" .. rest .. "'")

				local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_S_" .. rest)

				phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")

				phaseAddonDataListener:SetScript("OnEvent", function(self, event, prefix, text, channel, sender, ...)
					if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
						phaseAddonDataListener:UnregisterEvent("CHAT_MSG_ADDON")
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
				getSpellForgePhaseVault(function()
					--[[ -- need to reimplement this
					-- iterate spells after they are loaded and save with following format:
					_phaseSpellDebugDataTable[interAction.fullName] = {
						["encoded"] = text,
						["decoded"] = interAction,
					}
					--]]
				end)
			end
			SpellCreatorMasterTable.Options["debugPhaseData"] = _phaseSpellDebugDataTable
			dprint(true, "Phase Vault key data cached for this single reload to the 'epsilon/_retail_/WTF/Account/NAME/SavedVariables/SpellCreator.lua' file.")
		elseif command == "getPhaseKeys" then
			getPhaseVaultKeys(function(finalKeys, originalString)
				print(originalString)
				SpellCreatorMasterTable.Options["debugPhaseKeys"] = originalString
				Debug.dump(finalKeys)
			end, true)
		elseif command == "getPhaseTriggers" then
			local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_POPUPS")

			phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")

			phaseAddonDataListener:SetScript("OnEvent", function(self, event, prefix, text, channel, sender, ...)
				if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
					phaseAddonDataListener:UnregisterEvent("CHAT_MSG_ADDON")
					SpellCreatorMasterTable.Options["debugPhaseTriggers"] = text
					print(text)
					local phaseSparkTriggers = serializer.decompressForAddonMsg(text)
					Debug.dump(phaseSparkTriggers)
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
		elseif command == "dataSalvager" then
			ns.UI.DataSalvager.showSalvagerMenu()
		elseif command == "resetCooldowns" then
			ns.Actions.Cooldowns.clearOldCooldowns(true)
		elseif command == "refreshActionBars" then
			ns.UI.ActionButton.loadActionButtonsFromRegister()
		end
	else
		cprint("DEBUG LIST")
		cprint("Version: " .. addonVersion)
		--cprint("RuneIcon: "..runeIconOverlay.atlas or runeIconOverlay.tex)
		cprint("Debug Commands (/sfdebug ...): ")
		print("... debug: Toggles Debug mode on/off. Must be on for these commands to work.")
		print("... clearbinding: Delete's a spell Keybind based on CommID.")
		print("... clearbindingkey: Delete's a spell Keybind based on Key.")
		print("... resetSpells: reset your vault to empty. Cannot be undone.")
		print("... listSpells: List all your vault spells' data.. this is alot of text!")
		print("... listSpellKeys: List all your vault spells by just keys. Easier to read.")
		print("... getPhaseKeys: Lists all the vault spells by keys.")
		print("... getPhaseSpellData [$commID/key]: Exports the spell data for all current keys, or the specified commID/key, to your '" ..
			ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. "..epsilon/_retail_/WTF/Account/NAME/SavedVariables/SpellCreator.lua|r' file.")
		print("... resetPhaseSpellKeys: reset your phase vault to empty. Technically the spell data remains, and can be exported to your WTF file by using getPhaseSpellData.")
		print("... removePhaseKey: Removes a single phase key from the Phase Vault. The data for the spell remains, and can be retrieved using getPhaseSpellData also.")
		print("... dataSalvager: Show a large edit box with Data Salvaging Tools to convert exported Arc data to readable format.")
		print("... refreshActionBars: Reload Action Bars from the saved Arcanum Action Bar cache. This should only be used if your Action Bars did not load the Arcanum spells onto them correctly.")
	end
end

local testComVar
SLASH_SCFORGETEST1 = '/sftest';
function SlashCmdList.SCFORGETEST(msg, editbox) -- 4.
	if testComVar and testComVar < #Models.minimapModels then testComVar = testComVar + 1 else testComVar = 1 end
	Models.modelFrameSetModel(SCForgeMainFrame.portrait.Model, testComVar, Models.minimapModels)
	print(testComVar)
end

local function getSavedSpellFromVaultTable()
	return savedSpellFromVault
end

---@class MainFuncs
ns.MainFuncs = {
	updateSpellLoadRows = updateSpellLoadRows,
	saveSpellToPhaseVault = saveSpellToPhaseVault,          -- Move to SpellStorage when done
	getSavedSpellFromVaultTable = getSavedSpellFromVaultTable, -- I think this would move to spell storage later?
	deleteSpellFromPhaseVault = deleteSpellFromPhaseVault,  -- Move to Spell Storage? Vaults?
	downloadToPersonal = downloadToPersonal,

	getSpellForgePhaseVault = getSpellForgePhaseVault,

	uploadSpellDataToPhaseData = uploadSpellDataToPhaseData,
	getPhaseVaultDataFromKeys = getPhaseVaultDataFromKeys,

	saveSpell = saveSpell,

	resetEditorUI = resetEditorUI,
	scforge_showhide = scforge_showhide,
}
