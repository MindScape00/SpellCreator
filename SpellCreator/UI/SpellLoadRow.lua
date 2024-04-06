---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local Cooldowns = ns.Actions.Cooldowns
local Execute = ns.Actions.Execute
local Gossip = ns.Gossip
local Hotkeys = ns.Actions.Hotkeys
local Logging = ns.Logging
local Permissions = ns.Permissions
local UIHelpers = ns.Utils.UIHelpers
local Vault = ns.Vault

local DataUtils = ns.Utils.Data
local Tooltip = ns.Utils.Tooltip

local ChatLink = ns.UI.ChatLink
local Dropdown = ns.UI.Dropdown
local LoadSpellFrame = ns.UI.LoadSpellFrame
local Icons = ns.UI.Icons
local Popups = ns.UI.Popups
local SpellLoadRowContextMenu = ns.UI.SpellLoadRowContextMenu

local ADDON_COLORS = Constants.ADDON_COLORS
local ASSETS_PATH = Constants.ASSETS_PATH
local VAULT_TYPE = Constants.VAULT_TYPE

local getCurrentVault = LoadSpellFrame.getCurrentVault
local isOfficerPlus, isMemberPlus = Permissions.isOfficerPlus, Permissions.isMemberPlus

---@type SpellLoadRow[]
local rows = {}

---@type fun(spell: VaultSpell)
local loadSpell
---@type fun(commID: CommID, isPrivate: boolean)
local upload

local load_row_background = ASSETS_PATH .. "/SpellForgeVaultPanelRow"
local loadRowHeight = 45

---@param commID CommID
---@return VaultSpell
local function getSpell(commID)
	if getCurrentVault() == VAULT_TYPE.PERSONAL then
		return Vault.personal.findSpellByID(commID)
	end
	return Vault.phase.getSpellByIndex(commID)
end

local function clearRadios(self)
	if not self:GetChecked() then return; end
	for i = 1, #rows do
		local row = rows[i]
		if row ~= self and row:GetChecked() then
			row:SetChecked(false)
		end
	end
end

---@param self SpellLoadRowDeleteButton
local function onDeleteClick(self)
	local where = getCurrentVault()
	local spell = getSpell(self.commID)

	local dialog = StaticPopup_Show(
		"SCFORGE_CONFIRM_DELETE",
		DataUtils.wordToProperCase(where),
		string.format("Name: %s\nCommand: /sf %s", spell.fullName, spell.commID))

	if dialog then
		dialog.data = self.commID
		dialog.data2 = where
	end
end

---@param self SpellLoadRow
---@param button string
local function onRowClick(self, button)
	local currentVault = LoadSpellFrame.getCurrentVault()
	local spell = getSpell(self.commID)

	if button == "LeftButton" then
		if IsModifiedClick("CHATLINK") then
			ChatLink.linkSpell(spell, currentVault)
			self:SetChecked(not self:GetChecked())
			return;
		end
		clearRadios(self)
		if self:GetChecked() then
			LoadSpellFrame.selectRow(self.rowID)
		else
			LoadSpellFrame.selectRow(nil)
		end
	elseif button == "RightButton" then
		SpellLoadRowContextMenu.show(self, spell)
		self:SetChecked(not self:GetChecked())
	end
end

---@param self SpellLoadRowIcon
---@param button string
local function onIconClick(self, button)
	local currentVault = LoadSpellFrame.getCurrentVault()
	local spell = getSpell(self.commID)

	if button == "LeftButton" then
		if IsModifiedClick("CHATLINK") then
			ChatLink.linkSpell(spell, currentVault)
			return;
		end
		if currentVault == VAULT_TYPE.PHASE then
			--Execute.executeSpell(spell.actions, nil, spell.fullName, spell)
			Execute.executePhaseSpell(spell.commID)
		else
			ARC:CAST(self.commID)
		end
	elseif button == "RightButton" then
		SpellLoadRowContextMenu.show(self:GetParent() --[[@as SpellLoadRow]], spell)
	end
end

local function genSpellTooltipLines(spell, isClickable)
	local strings = {}
	local hotkeyKey = Hotkeys.getHotkeyByCommID(spell.commID)

	if spell.description then tinsert(strings, spell.description) end
	tinsert(strings, " ")

	if spell.profile then tinsert(strings, Tooltip.createDoubleLine("Profile: ", spell.profile)) end

	if spell.cooldown then
		tinsert(strings, Tooltip.createDoubleLine("Actions: " .. #spell.actions, "Cooldown: " .. spell.cooldown .. "s"))
	else
		tinsert(strings, "Actions: " .. #spell.actions)
	end

	if spell.author then tinsert(strings, "Author: " .. spell.author); end
	if spell.items and next(spell.items) then tinsert(strings, "Items: " .. table.concat(spell.items, ", ")) end
	if hotkeyKey then tinsert(strings, "Hotkey: " .. hotkeyKey) end
	tinsert(strings, " ")

	if isClickable then
		tinsert(strings, Tooltip.genContrastText("Left-Click") .. " to cast " .. ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode(spell.commID))
	else
		tinsert(strings, "Command: " .. Tooltip.genContrastText("/sf " .. spell.commID))
	end
	return strings
end

---@param frame SpellLoadRowIcon | SpellLoadRow
local function setTooltip(frame, isIcon)
	Tooltip.set(
		frame,
		function(self)
			return getSpell(self.commID).fullName
		end,
		function(self)
			local spell = getSpell(self.commID)
			local strings = genSpellTooltipLines(spell, isIcon)
			tinsert(strings, Tooltip.genContrastText("Right-Click") .. " for more options!")
			tinsert(strings, Tooltip.genContrastText("Shift-Click") .. " to link in chat.")
			return strings
		end,
		{
			-- we expect a tooltip on the spell even if tooltips are disabled
			forced = true,
			delay = function() return isIcon and 0 or 0.7 end,
		}
	)
end

local function createSpellIcon(row)
	---@class SpellLoadRowIcon: BUTTON
	---@field commID CommID
	local spellIcon = CreateFrame("BUTTON", nil, row)

	spellIcon:SetPoint("RIGHT", row.spellName, "LEFT", -3, 0)
	spellIcon:SetSize(32, 32)

	spellIcon:SetNormalTexture("Interface/Icons/inv_misc_questionmark")

	spellIcon:SetHighlightTexture(ASSETS_PATH .. "/dm-trait-select")
	spellIcon.highlight = spellIcon:GetHighlightTexture()
	spellIcon.highlight:SetPoint("TOPLEFT", -4, 4)
	spellIcon.highlight:SetPoint("BOTTOMRIGHT", 4, -4)

	spellIcon.border = spellIcon:CreateTexture(nil, "OVERLAY")
	spellIcon.border:SetTexture(ASSETS_PATH .. "/dm-trait-border")
	spellIcon.border:SetPoint("TOPLEFT", -6, 6)
	spellIcon.border:SetPoint("BOTTOMRIGHT", 6, -6)

	spellIcon.cooldown = CreateFrame("Cooldown", nil, spellIcon, "CooldownFrameTemplate")
	spellIcon.cooldown:SetAllPoints()
	spellIcon.cooldown:SetUseCircularEdge(true)

	setTooltip(spellIcon, true)

	spellIcon:SetScript("OnClick", onIconClick)
	spellIcon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	ns.UI.ActionButton.makeButtonDraggableToActionBar(spellIcon)

	return spellIcon
end

local function createHotkeyIcon(row)
	---@class SpellLoadRowHotkeyIcon: BUTTON
	---@field commID CommID
	local hotkeyIcon = CreateFrame("BUTTON", nil, row)

	hotkeyIcon:SetPoint("CENTER", row.spellIcon, "TOPRIGHT", -4, -5)
	hotkeyIcon:SetSize(20, 10)

	ns.Utils.UIHelpers.setupCoherentButtonTextures(hotkeyIcon, "interface/tradeskillframe/ui-tradeskill-linkbutton")

	hotkeyIcon.NormalTexture:SetTexCoord(0, 1, 0, 0.5)
	hotkeyIcon.NormalTexture:SetRotation(math.rad(-45))

	hotkeyIcon.HighlightTexture:SetTexCoord(0, 1, 0, 0.5)
	hotkeyIcon.HighlightTexture:SetRotation(math.rad(-45))

	hotkeyIcon.PushedTexture:SetTexCoord(0, 1, 0, 0.5)
	hotkeyIcon.PushedTexture:SetRotation(math.rad(-45))

	Tooltip.set(hotkeyIcon,
		function(self)
			return "Bound to: " .. Hotkeys.getHotkeyByCommID(self.commID)
		end,
		{
			" ",
			"Left-Click to Edit Binding",
			"Shift+Right-Click to Unbind",
		}
	)

	hotkeyIcon:SetFrameLevel(row.spellIcon:GetFrameLevel() + 1)

	hotkeyIcon:SetScript("OnClick", function(self, button)
		if button == "LeftButton" then
			Popups.showLinkHotkeyDialog(self.commID)
		elseif button == "RightButton" and IsShiftKeyDown() then
			Hotkeys.deregisterHotkeyByComm(self.commID)
		end
	end)
	hotkeyIcon:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	return hotkeyIcon
end

local buttonType = 0
local function createItemConnectedIcon(row)
	---@class SpellLoadRowItemLinkedIcon: BUTTON
	---@field commID CommID
	local itemConnectedIcon = CreateFrame("BUTTON", nil, row)

	itemConnectedIcon:SetPoint("CENTER", row.spellIcon, "BOTTOMRIGHT", -4, 4)
	itemConnectedIcon:SetSize(16, 16)
	ns.Utils.UIHelpers.setupCoherentButtonTextures(itemConnectedIcon, "QuestSharing-QuestLog-Loot", true)

	Tooltip.set(itemConnectedIcon,
		function(self)
			--local spell = ns.Vault.personal.findSpellByID(self.commID)
			local spell = getSpell(self.commID)
			local spellLinks = {}
			for k, v in ipairs(spell.items) do
				local _, link = GetItemInfo(v)
				tinsert(spellLinks, link)
			end
			return "Connected Items:\n" .. table.concat(spellLinks, ", ")
		end,
		{
			" ",
			"Left-Click to Edit Item Connections",
		}
	)

	itemConnectedIcon:SetFrameLevel(row.spellIcon:GetFrameLevel() + 1)

	itemConnectedIcon:SetScript("OnClick", function(self, button)
		--local spell = ns.Vault.personal.findSpellByID(self.commID)
		local spell = getSpell(self.commID)
		local hasItems, itemsMenu = ns.UI.ItemIntegration.manageUI.genItemMenuSubMenu(spell)
		Dropdown.open(itemsMenu, row.contextMenu, "cursor", 0, 0, "MENU")
	end)
	itemConnectedIcon:RegisterForClicks("LeftButtonUp")

	return itemConnectedIcon
end

local function createDeleteButton(row)
	---@class SpellLoadRowDeleteButton: BUTTON
	---@field commID CommID
	local deleteButton = CreateFrame("BUTTON", nil, row)
	deleteButton:SetPoint("RIGHT", 0, 0)
	deleteButton:SetSize(24, 24)

	UIHelpers.setupCoherentButtonTextures(deleteButton, ASSETS_PATH .. "/icon-x")

	Tooltip.set(
		deleteButton,
		function(self)
			local spell = getSpell(self.commID)
			return "Delete '" .. spell.commID .. "'"
		end
	)

	deleteButton:SetScript("OnClick", onDeleteClick)

	return deleteButton
end

local function createLoadButton(row)
	---@class SpellLoadRowLoadButton: BUTTON
	---@field commID CommID
	local loadButton = CreateFrame("BUTTON", nil, row)
	loadButton:SetPoint("RIGHT", row.deleteButton, "LEFT", 0, 0)
	loadButton:SetSize(24, 24)

	UIHelpers.setupCoherentButtonTextures(loadButton, ASSETS_PATH .. "/icon-edit")

	loadButton:SetScript("OnClick", function(self, button)
		local spell = getSpell(self.commID)

		if button == "RightButton" then
			spell = CopyTable(spell) -- this is so it does not impact the original spell table at all
			table.sort(spell.actions, function(k1, k2) return k1.delay < k2.delay end)
		end
		loadSpell(spell)
	end)
	loadButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	Tooltip.set(
		loadButton,
		function(self)
			local spell = getSpell(self.commID)
			return "Load '" .. spell.commID .. "'"
		end,
		{
			"Load the spell into the Forge UI so you can edit it.",
			"\nRight-click to load the ArcSpell, and re-sort it's actions into chronological order by delay.",
		}
	)

	return loadButton
end

local function createGossipButton(row)
	local gossipButton = CreateFrame("BUTTON", nil, row)
	gossipButton:SetPoint("TOP", row.deleteButton, "BOTTOM", 0, 0)
	gossipButton:SetSize(16, 16)

	UIHelpers.setupCoherentButtonTextures(gossipButton, "groupfinder-waitdot", true)
	gossipButton:GetNormalTexture():SetVertexColor(1, 0.8, 0)

	gossipButton.speechIcon = gossipButton:CreateTexture(nil, "OVERLAY", nil, 7)
	gossipButton.speechIcon:SetTexture("interface/gossipframe/chatbubblegossipicon")
	gossipButton.speechIcon:SetSize(10, 10)
	gossipButton.speechIcon:SetTexCoord(1, 0, 0, 1)
	gossipButton.speechIcon:SetPoint("CENTER", gossipButton, "TOPRIGHT", -2, -1)

	gossipButton:SetMotionScriptsWhileDisabled(true)

	gossipButton:SetScript("OnClick", function(self)
		Popups.showAddGossipPopup(self.commID)
	end)
	gossipButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	Tooltip.set(
		gossipButton,
		"Add to Gossip Menu",
		{
			"With a gossip menu open, click here to add this ArcSpell to an NPC's gossip.",
			"\nThis allows you to link ArcSpells to cast from an NPC's gossip menu.",
			"\nFor example, you could add an ArcSpell with mining animations & an Add Item action, as an '..On Open' with hide, to simulate a mining node.",
		}
	)

	gossipButton:SetScript("OnDisable", function(self)
		self.speechIcon:SetDesaturated(true)
		self.speechIcon:SetVertexColor(.6, .6, .6)
	end)

	gossipButton:SetScript("OnEnable", function(self)
		self.speechIcon:SetDesaturated(false)
		self.speechIcon:SetVertexColor(1, 1, 1)
	end)

	return gossipButton
end

local function createPrivateIconButton(row)
	---@class SpellLoadRowPrivateIconButton: BUTTON
	---@field commID CommID
	local privateIconButton = CreateFrame("BUTTON", nil, row)
	privateIconButton.isPrivate = false
	privateIconButton:SetSize(16, 16)
	privateIconButton:SetPoint("RIGHT", row.gossipButton, "LEFT", -8, 0)

	--button:SetNormalAtlas("UI_Editor_Eye_Icon")
	UIHelpers.setupCoherentButtonTextures(privateIconButton, ASSETS_PATH .. "/icon_visible_32")
	privateIconButton:GetHighlightTexture():SetAlpha(0.2) -- override, 0.33 was still too bright on this one

	privateIconButton:SetMotionScriptsWhileDisabled(true)

	privateIconButton.SetPrivacy = function(self, priv)
		if not DataUtils.isNotDefined(priv) then
			self.isPrivate = priv
		else
			self.isPrivate = not self.isPrivate
		end

		if self.isPrivate then
			self:SetNormalTexture(ASSETS_PATH .. "/icon_hidden_32")
			self:GetNormalTexture():SetVertexColor(0.6, 0.6, 0.6)
			self:SetPushedTexture(ASSETS_PATH .. "/icon_hidden_32")
			self:GetHighlightTexture():SetTexture(ASSETS_PATH .. "/icon_hidden_32")
		else
			self:SetNormalTexture(ASSETS_PATH .. "/icon_visible_32")
			self:GetNormalTexture():SetVertexColor(0.9, 0.65, 0)
			self:SetPushedTexture(ASSETS_PATH .. "/icon_visible_32")
			self:GetHighlightTexture():SetTexture(ASSETS_PATH .. "/icon_visible_32")
		end
		self:GetPushedTexture():SetVertexColor(self:GetNormalTexture():GetVertexColor())

		return self.isPrivate
	end

	Tooltip.set(privateIconButton,
		function(self)
			local theSpell = getSpell(self.commID)
			local spellName = "'" .. ((theSpell and theSpell.fullName) and theSpell.fullName or "Loading ...")

			if self.isPrivate then
				return spellName .. "' is Private & visible only to Officers+"
			end

			return spellName .. "' is Public & visible to everyone"
		end,
		"Click to change this spell's visibility."
	)

	privateIconButton:SetScript("OnClick", function(self)
		if not isOfficerPlus() then
			Logging.eprint("You're not an officer.. You can't toggle a spell's visibility.")
			return
		end

		local priv = self:SetPrivacy()
		if priv == nil then priv = false end

		--upload(self.commID, priv) -- // replaced with single-upload updater. Feel free to spam away. Or.. Or don't still.. please.. but you can..
		local theSpell = getSpell(self.commID)
		theSpell.private = priv
		ns.Vault.phase.uploadSingleSpellAndNotifyUsers(theSpell.commID, theSpell)
	end)

	return privateIconButton
end

---@param parent Frame
---@param rowNum integer
local function createRow(parent, rowNum)
	local columnWidth = parent:GetWidth()
	---@class SpellLoadRow: CheckButton
	---@field commID CommID
	---@field rowID integer
	---@field vaultType VAULT_TYPE
	local thisRow = CreateFrame("CheckButton", "scForgeLoadRow" .. rowNum, parent)

	thisRow:SetWidth(columnWidth - 20)
	thisRow:SetHeight(loadRowHeight)

	-- A nice lil background to make them easier to tell apart
	thisRow.Background = thisRow:CreateTexture(nil, "BACKGROUND", nil, 5)
	thisRow.Background:SetPoint("TOPLEFT", -3, 0)
	thisRow.Background:SetPoint("BOTTOMRIGHT", 0, 0)
	thisRow.Background:SetTexture(load_row_background)
	thisRow.Background:SetTexCoord(0.0625, 1 - 0.066, 0.125, 1 - 0.15)

	thisRow:SetCheckedTexture("Interface\\AddOns\\SpellCreator\\assets\\l_row_selected")
	thisRow.CheckedTexture = thisRow:GetCheckedTexture()
	thisRow.CheckedTexture:SetAllPoints(thisRow.Background)
	thisRow.CheckedTexture:SetTexCoord(0.0625, 1 - 0.066, 0.125, 1 - 0.15)
	thisRow.CheckedTexture:SetAlpha(0.75)

	thisRow.spellName = thisRow:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
	thisRow.spellName:SetWidth((columnWidth * 2 / 3) - 15)
	thisRow.spellName:SetJustifyH("LEFT")
	thisRow.spellName:SetPoint("LEFT", 34, 0)
	thisRow.spellName:SetShadowColor(0, 0, 0)
	thisRow.spellName:SetMaxLines(3) -- hardlimit to 3 lines, but soft limit to 2 later.

	thisRow.spellIcon = createSpellIcon(thisRow)
	thisRow.hotkeyIcon = createHotkeyIcon(thisRow)
	thisRow.itemConnectedIcon = createItemConnectedIcon(thisRow)
	thisRow.deleteButton = createDeleteButton(thisRow)
	thisRow.loadButton = createLoadButton(thisRow)
	thisRow.gossipButton = createGossipButton(thisRow)
	thisRow.privateIconButton = createPrivateIconButton(thisRow)
	thisRow.contextMenu = SpellLoadRowContextMenu.createFor(thisRow, rowNum)

	setTooltip(thisRow, false)
	thisRow:SetScript("OnClick", onRowClick)
	thisRow:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	tinsert(rows, thisRow)

	return thisRow
end

---@param row SpellLoadRow
local function setModePersonal(row)
	row.deleteButton:Show()
	row.deleteButton:ClearAllPoints()
	row.deleteButton:SetPoint("RIGHT")
	row.loadButton:ClearAllPoints()
	row.loadButton:SetPoint("RIGHT", row.deleteButton, "LEFT", 0, 0)
	row.gossipButton:Hide()
	row.privateIconButton:Hide()
	row.vaultType = Constants.VAULT_TYPE.PERSONAL
end

---@param row SpellLoadRow
local function setModePhase(row)
	if isMemberPlus() then
		row.deleteButton:Show()
		row.deleteButton:ClearAllPoints()
		row.deleteButton:SetPoint("TOPRIGHT")
		row.loadButton:ClearAllPoints()
		row.loadButton:SetPoint("RIGHT", row.deleteButton, "LEFT", 0, 0)
		row.gossipButton:Show()
		row.gossipButton:SetEnabled(Gossip.isLoaded())
		row.privateIconButton:Show()
	else
		row.deleteButton:Hide()
		row.deleteButton:ClearAllPoints()
		row.deleteButton:SetPoint("RIGHT")
		row.loadButton:ClearAllPoints()
		row.loadButton:SetPoint("CENTER", row.deleteButton, "CENTER", 0, 0)
		row.gossipButton:Hide()
		row.privateIconButton:SetShown(SpellCreatorMasterTable.Options["debug"])
	end
	row.vaultType = Constants.VAULT_TYPE.PHASE
end

---@param row SpellLoadRow
local function setMode(row)
	if getCurrentVault() == VAULT_TYPE.PERSONAL then
		setModePersonal(row)
	else
		setModePhase(row)
	end
end

-- Limit our Spell Name to 2 lines - but by downsizing the text instead of truncating..
---@param row SpellLoadRow
local function resizeName(row)
	local fontName, fontHeight, fontFlags = row.spellName:GetFont()

	row.spellName:SetFont(fontName, 14, fontFlags) -- reset the font to default first, then test if we need to scale it down.

	while row.spellName:GetNumLines() > 2 do
		fontName, fontHeight, fontFlags = row.spellName:GetFont()
		row.spellName:SetFont(fontName, fontHeight - 1, fontFlags)

		-- don't go smaller than 8 point font. Becomes too hard to read. We'll take a truncated text over that.
		if fontHeight - 1 <= 8 then
			break
		end
	end
end

---@param spell VaultSpell
local function shouldHideRow(spell)
	return getCurrentVault() == VAULT_TYPE.PHASE and spell.private and
		not (isOfficerPlus() or SpellCreatorMasterTable.Options["debug"])
end

---@param row SpellLoadRow
---@param rowNum integer
---@param commIDOrIndex CommID | integer
---@param spell VaultSpell
local function updateRow(row, rowNum, commIDOrIndex, spell)
	local commID = commIDOrIndex

	row.spellName:SetText(spell.fullName)
	row.loadButton.commID = commID
	row.deleteButton.commID = commID
	row.gossipButton.commID = commID
	row.privateIconButton.commID = commID
	row.spellIcon.commID = commID
	row.hotkeyIcon.commID = commID
	row.itemConnectedIcon.commID = commID
	row.commID = commID -- used in new Transfer to Phase Button - all the other ones should probably move to using this anyways..
	row.rowID = rowNum

	row.hotkeyIcon:SetShown(Hotkeys.getHotkeyByCommID(commID) ~= nil)
	row.itemConnectedIcon:SetShown(spell.items and #spell.items > 0)
	row.spellIcon:SetNormalTexture(Icons.getFinalIcon(spell.icon))

	setMode(row)
	resizeName(row)

	local vaultType = row.vaultType
	local cooldownTime, cooldownLength = Cooldowns.isSpellOnCooldown(spell.commID, (vaultType == Constants.VAULT_TYPE.PHASE and C_Epsilon.GetPhaseId() or nil))
	local currentTime = GetTime()
	if cooldownTime then
		row.spellIcon.cooldown:SetCooldown(currentTime - (cooldownLength - cooldownTime), cooldownLength)
	else
		row.spellIcon.cooldown:Clear()
	end

	row.privateIconButton:SetPrivacy(spell.private and spell.private or false)
end

---@param inject { loadSpell: fun(spell: VaultSpell), upload: fun(commID: CommID, isPrivate: boolean) }
local function init(inject)
	loadSpell = inject.loadSpell
	upload = inject.upload
end

local function triggerCooldownVisual(commID, cooldownTime)
	local currTime = GetTime()
	for k, v in ipairs(rows) do
		if v.commID == commID then
			v.spellIcon.cooldown:SetCooldown(currTime, cooldownTime)
		end
	end
end

---@class UI_SpellLoadRow
ns.UI.SpellLoadRow = {
	init = init,
	createRow = createRow,
	updateRow = updateRow,
	shouldHideRow = shouldHideRow,
	triggerCooldownVisual = triggerCooldownVisual,
}
