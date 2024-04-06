---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local DataUtils = ns.Utils.Data
local Localization = ns.Localization
local Tooltip = ns.Utils.Tooltip

local AtticProfileDropdown = ns.UI.MainFrame.AtticProfileDropdown
local Icons = ns.UI.Icons
local MainFrame = ns.UI.MainFrame.MainFrame

local ADDON_COLORS = Constants.ADDON_COLORS
local ASSETS_PATH = Constants.ASSETS_PATH
local isNotDefined = DataUtils.isNotDefined

local nameBox
local commandBox
local descBox
local cooldownBox
local castbarCheckButton
local author = UnitName("player")
local editCommID
local iconButton
local condButton
local editorsaved = true
local itemsCached

local function markEditorSaved()
	editorsaved = true
	MainFrame.markTitleChanges(false)
end

local function markEditorUnsaved()
	editorsaved = false
	MainFrame.markTitleChanges(true)
end

local function getEditorSavedState()
	return editorsaved
end

local function setAuthor(text)
	author = text
end

local function getAuthor()
	return author
end

local function setAuthorMe()
	author = UnitName("player")
end

---@param mainFrame SCForgeMainFrame
local function createNameBox(mainFrame)
	nameBox = CreateFrame("EditBox", nil, mainFrame, "InputBoxInstructionsTemplate")
	nameBox:SetFontObject(ChatFontNormal)
	nameBox:SetMaxBytes(100)
	nameBox.disabledColor = GRAY_FONT_COLOR
	nameBox.enabledColor = HIGHLIGHT_FONT_COLOR
	nameBox.Instructions:SetText(Localization.SPELLNAME)
	nameBox.Instructions:SetTextColor(0.5, 0.5, 0.5)
	--nameBox.Title = nameBox:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	--nameBox.Title:SetText(NAME)
	--nameBox.Title:SetPoint("BOTTOM", nameBox, "TOP", 0, 0)
	nameBox:SetAutoFocus(false)
	nameBox:SetSize(mainFrame:GetWidth() / 4.5, 23)
	nameBox:SetPoint("TOPRIGHT", mainFrame, "TOP", -38, -20)
	nameBox:HookScript("OnTextChanged", function(self, userInput)
		if userInput then markEditorUnsaved() end
	end)

	Tooltip.set(nameBox,
		Localization.SPELLNAME,
		"The name of the spell.\n\rThis can be anything and is only used for identifying the spell in the Vault & Chat Links.\n\rYes, you can have two spells with the same name, but that's annoying.."
	)

	return nameBox
end

---@param mainFrame SCForgeMainFrame
local function createCommandBox(mainFrame)
	commandBox = CreateFrame("EditBox", nil, mainFrame, "InputBoxInstructionsTemplate")
	commandBox:SetFontObject(ChatFontNormal)
	commandBox:SetMaxBytes(40)
	commandBox.disabledColor = GRAY_FONT_COLOR
	commandBox.enabledColor = HIGHLIGHT_FONT_COLOR
	commandBox.Instructions:SetText(Localization.SPELLCOMM)
	commandBox.Instructions:SetTextColor(0.5, 0.5, 0.5)
	--commandBox.Title = commandBox:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	--commandBox.Title:SetText(COMMAND)
	--commandBox.Title:SetPoint("BOTTOM", commandBox, "TOP", 0, 0)
	commandBox:SetAutoFocus(false)
	--commandBox:SetSize(mainFrame:GetWidth()/6,23)
	commandBox:SetSize(mainFrame:GetWidth() / 5, 23)
	commandBox:SetPoint("LEFT", nameBox, "RIGHT", 6, 0)

	Tooltip.set(commandBox,
		Localization.SPELLCOMM,
		{
			"The slash command trigger (commID) you want to use to call this spell.\n\rCast it using '/arcanum $command' after using Create.",
			" ",
			"This must be unique. Saving a spell with the same command ID as another will over-write the old spell."
		}
	)

	commandBox:HookScript("OnTextChanged", function(self, userInput)
		local selfText = self:GetText();
		if selfText:match(",") then self:SetText(selfText:gsub(",", "")) end
		if userInput then markEditorUnsaved() end
	end)

	return commandBox
end

---@param mainFrame SCForgeMainFrame
local function createInfoDescBox(mainFrame)
	descBox = CreateFrame("EditBox", nil, mainFrame, "InputBoxInstructionsTemplate")
	descBox:SetFontObject(ChatFontNormal)
	--descBox:SetMaxBytes(100) -- we needed this before to limit the length for chatlinks, but we removed description from chatlinks so woo..
	descBox.disabledColor = GRAY_FONT_COLOR
	descBox.enabledColor = HIGHLIGHT_FONT_COLOR
	descBox.Instructions:SetText("Description")
	descBox.Instructions:SetTextColor(0.5, 0.5, 0.5)
	--infoDescBox.Title = infoDescBox:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	--infoDescBox.Title:SetText("Description")
	--infoDescBox.Title:SetPoint("BOTTOM", infoDescBox, "TOP", 0, 0)
	descBox:SetAutoFocus(false)
	descBox:SetSize(mainFrame:GetWidth() / 2.5, 23)
	descBox.SetRelativePoints = function(self)
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", 0, 4)
		self:SetPoint("TOPRIGHT", commandBox, "BOTTOMRIGHT", 0, 4)
	end
	descBox:SetRelativePoints()

	descBox:HookScript("OnTextChanged", function(self, userInput)
		if userInput then markEditorUnsaved() end
	end)

	Tooltip.set(descBox, "Description", "A description of the spell. This will show up in tooltips.")

	return descBox
end

---@param mainFrame SCForgeMainFrame
local function createSpellCooldownBox(mainFrame)
	cooldownBox = CreateFrame("EditBox", nil, mainFrame, "InputBoxInstructionsTemplate")
	cooldownBox:SetFontObject(ChatFontNormal)
	cooldownBox.disabledColor = GRAY_FONT_COLOR
	cooldownBox.enabledColor = HIGHLIGHT_FONT_COLOR
	cooldownBox.Instructions:SetText("Cooldown")
	cooldownBox.Instructions:SetTextColor(0.5, 0.5, 0.5)

	cooldownBox:SetAutoFocus(false)
	cooldownBox:SetSize(60, 23)
	cooldownBox:SetPoint("LEFT", descBox, "RIGHT", 6, 0)

	cooldownBox:HookScript("OnTextChanged", function(self, userInput)
		if self:GetText() == self:GetText():match("%d+") or self:GetText() == self:GetText():match("%d+%.%d+") or self:GetText() == self:GetText():match("%.%d+") then
			self:SetTextColor(255, 255, 255, 1)
		elseif self:GetText() == "" then
			self:SetTextColor(255, 255, 255, 1)
		elseif self:GetText():find("%a") then
			self:SetText(self:GetText():gsub("%a", ""))
		else
			self:SetTextColor(1, 0, 0, 1)
		end
		if userInput then markEditorUnsaved() end
	end)

	Tooltip.set(cooldownBox, "Cooldown", "How long of a cooldown before you can cast the spell again, in seconds. May be left blank for no cooldown.")

	return cooldownBox
end

---@param mainFrame SCForgeMainFrame
local function createCastbarCheckButton(mainFrame)
	---@class CastbarCheckButton : CheckButton, UICheckButtonTemplate
	---@field checkState 0 | 1 | 2
	---@field checkTex Texture
	---@type CastbarCheckButton
	castbarCheckButton = CreateFrame("CheckButton", nil, mainFrame, "UICheckButtonTemplate")
	castbarCheckButton:SetSize(20, 20)
	castbarCheckButton:SetPoint("LEFT", commandBox, "RIGHT", 0, 0)
	castbarCheckButton.text:SetText("Channeled")
	castbarCheckButton.checkState = 1 -- 0 = none, 1 = cast, 2 = channel; default to cast

	castbarCheckButton.checkTex = castbarCheckButton:GetCheckedTexture()
	castbarCheckButton.UpdateCheckedTex = function(self)
		local checkState = self.checkState

		if checkState == 0 then
			self:SetChecked(false)
			self.text:SetText("None")
		elseif checkState == 1 then
			local checkTex = self:GetCheckedTexture()
			self:SetChecked(true);
			self.checkTex:SetTexture("Interface/Buttons/UI-CheckBox-Check")
			self.checkTex:SetAllPoints()
			self.text:SetText("Cast")
		elseif checkState == 2 then
			self:SetChecked(true);
			self.checkTex:SetAtlas("common-checkbox-partial")
			self.checkTex:ClearAllPoints()
			self.checkTex:SetPoint("CENTER")
			self.checkTex:SetSize(self:GetWidth() * 0.5, self:GetHeight() * 0.5)
			self.text:SetText("Channel")
		end
	end
	castbarCheckButton:UpdateCheckedTex()

	castbarCheckButton.GetCheckState = function(self)
		return self.checkState
	end
	castbarCheckButton.SetCheckState = function(self, state)
		if not state then state = 1 end
		self.checkState = state
		self:UpdateCheckedTex()
	end

	castbarCheckButton:SetScript("OnClick", function(self)
		self.checkState = self.checkState + 1
		if self.checkState > 2 then self.checkState = 0 end
		self:UpdateCheckedTex()
		markEditorUnsaved()
	end)

	Tooltip.set(castbarCheckButton,
		"Castbar / Channelbar",
		function(self)
			local castingStateText = "None"
			if self.checkState == 1 then
				castingStateText = "Cast"
			elseif self.checkState == 2 then
				castingStateText = "Channel"
			end

			return {
				"Toggle the casting bar between:\rCast, Channel, or None.\n\rCastbars do not show, even if enabled, if the total spell length is under 0.25 seconds.",
				"\nCurrent: " .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. "" .. castingStateText .. "|r",
			}
		end,
		{ updateOnClick = true, delay = 0.3 }
	)

	return castbarCheckButton
end

---@param mainFrame SCForgeMainFrame
---@param IconPicker UI_IconPicker
local function createIconButton(mainFrame, IconPicker)
	iconButton = CreateFrame("BUTTON", nil, mainFrame)
	iconButton:SetSize(34, 34)
	iconButton:SetPoint("TOPRIGHT", nameBox, "TOPLEFT", -14, -6)
	--iconButton:SetPoint("TOPLEFT", 70, -26)
	iconButton:SetNormalTexture("Interface/Icons/inv_misc_questionmark")
	iconButton.normal = iconButton:GetNormalTexture()
	iconButton.normal:SetDrawLayer("BACKGROUND")
	iconButton.mask = iconButton:CreateMaskTexture()
	iconButton.mask:SetAllPoints(iconButton.normal)
	iconButton.mask:SetTexture("interface/framegeneral/uiframeiconmask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")

	iconButton.normal:AddMaskTexture(iconButton.mask)

	iconButton.highlight = iconButton:CreateTexture(nil, "OVERLAY")
	iconButton.highlight:SetTexture(ASSETS_PATH .. "/dm-trait-select")
	iconButton.highlight:SetPoint("TOPLEFT", -4, 4)
	iconButton.highlight:SetPoint("BOTTOMRIGHT", 4, -4)
	iconButton.highlight:Hide()

	iconButton.border = iconButton:CreateTexture(nil, "BORDER")
	iconButton.border:SetTexture(ASSETS_PATH .. "/dm-trait-border")
	iconButton.border:SetPoint("TOPLEFT", -6, 6)
	iconButton.border:SetPoint("BOTTOMRIGHT", 6, -6)

	iconButton.SetSelected = function(self, selected)
		if (selected == nil) then
			if self.selected ~= nil then selected = not self.selected else selected = true end
		end
		self.selected = selected
		if selected then
			self.highlight:SetTexture(ASSETS_PATH .. "/dm-trait-highlight")
			self.highlight:Show()
		else
			self.highlight:SetTexture(ASSETS_PATH .. "/dm-trait-select")
			self.highlight:Hide()
		end
	end

	iconButton.SelectTex = Icons.SelectIcon
	iconButton.ResetTex = Icons.ResetIcon
	iconButton.GetSelectedTexID = function(self)
		local tex = self.selectedTex
		if tonumber(tex) then
			tex = tex
		else
			tex = Icons.convertPathToCustomIconIndex(tex);
		end
		return tex
	end

	iconButton:SetScript("OnEnter", function(self)
		self.highlight:Show()
	end)
	iconButton:SetScript("OnLeave", function(self)
		if not self.selected then
			self.highlight:Hide()
		end
	end)
	iconButton:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			self:ResetTex()
			markEditorUnsaved()
			return
		end
		IconPicker.IconPicker_Open(self)
		self:SetSelected(true)
	end)
	iconButton:RegisterForClicks("RightButtonUp", "LeftButtonUp")

	Tooltip.set(iconButton, "Select an Icon",
		"Select an icon for your ArcSpell.\n\rThis will be shown across the addon to represent the spell (i.e., in the vault, castbar, Quickcast, chatlinks).\n\r" ..
		Tooltip.genContrastText("Right-Click") .. " to remove the icon. You should probably have an icon tho..")

	return iconButton
end

local copiedFXFinFunc = function(self)
	self:GetRegionParent():Hide()
end
local copiedFXPlayFunc = function(self, action)
	if action == "copy" then
		self.copyFX:SetAtlas("GarrMission_CounterHalfCheck")
	elseif action == "paste" then
		self.copyFX:SetAtlas("GarrMission_CounterCheck")
	else
		self.copyFX:SetAtlas("groupfinder-icon-redx")
	end
	self.copyFX:Show()
	self.copyFX.anims:Play()
end

---@param mainFrame SCForgeMainFrame
---@return BUTTON
local function createConditionsButton(mainFrame)
	condButton = CreateFrame("BUTTON", nil, mainFrame)
	condButton:SetSize(26, 26)
	condButton:SetPoint("BOTTOMLEFT", cooldownBox, "BOTTOMRIGHT", 0, 6)
	ns.Utils.UIHelpers.setupCoherentButtonTextures(condButton, ASSETS_PATH .. "/ConditionsButtonGreyed")
	condButton:SetMotionScriptsWhileDisabled(true)
	condButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	condButton.copyFX = condButton:CreateTexture(nil, "OVERLAY")
	condButton.copyFX:SetAllPoints()
	condButton.copyFX:Hide()
	condButton.copyFX:SetAtlas("GarrMission_CounterHalfCheck")

	condButton.copyFX.anims = condButton.copyFX:CreateAnimationGroup()
	condButton.copyFX.anims.iconFlash = condButton.copyFX.anims:CreateAnimation("Alpha")
	condButton.copyFX.anims.iconFlash:SetFromAlpha(1)
	condButton.copyFX.anims.iconFlash:SetToAlpha(0)
	condButton.copyFX.anims.iconFlash:SetDuration(0.25)
	condButton.copyFX.anims.iconFlash:SetScript("OnFinished", copiedFXFinFunc)
	condButton.copyFX.anims.iconFlash:SetSmoothing("IN")
	condButton.copied = copiedFXPlayFunc

	--mainFrame.conditionsData = {}

	Tooltip.set(condButton,
		"Add Conditions to this Spell",
		function()
			local lines = {
				"This allows you to set it so the spell will only cast IF the conditions are met.",
				"For example, you could set a condition for this spell to only cast if you currently have a specific item in your inventory.",
				" "
			}
			if mainFrame.conditionsData and #mainFrame.conditionsData > 0 then
				tinsert(lines, "Current Conditions:")
				for gi, groupData in ipairs(mainFrame.conditionsData) do
					local groupString = (gi == 1 and "If") or "..Or"
					for ri, rowData in ipairs(groupData) do
						local continueStatement = (ri ~= 1 and "and ") or ""
						local condName = ns.Actions.ConditionsData.getByKey(rowData.Type).name
						groupString = string.join(" ", groupString, continueStatement .. condName)
					end
					tinsert(lines, groupString)
				end
				tinsert(lines, Tooltip.genTooltipText("norevert", "Ctrl+Left Click to Copy\nCtrl+Right Click to Paste"))
			else
				tinsert(lines, "This Spell has no current Conditions")
				tinsert(lines, Tooltip.genTooltipText("norevert", "Ctrl+Right Click to Paste"))
			end
			return lines
		end
	)
	condButton:SetScript("OnClick", function(self, button)
		local isCtrlDown = IsControlKeyDown()
		if button == "RightButton" then
			if not isCtrlDown then return end
			-- paste
			mainFrame.conditionsData = ns.Actions.ConditionsData.copyGet()
			self:copied("paste")
			self:update()
			return
		elseif button == "LeftButton" and isCtrlDown then
			-- copy
			ns.Actions.ConditionsData.copySave(mainFrame.conditionsData)
			self:copied("copy")
			return
		end

		ns.UI.ConditionsEditor.open(mainFrame, "spell", mainFrame.conditionsData)
		markEditorUnsaved()
	end)
	condButton.update = function(self)
		if mainFrame.conditionsData and #mainFrame.conditionsData > 0 then
			self:SetNormalTexture(ASSETS_PATH .. "/ConditionsButton")
		else
			self:SetNormalTexture(ASSETS_PATH .. "/ConditionsButtonGreyed")
		end
	end

	return condButton
end

local function getEditCommId()
	return editCommID
end

local function setEditCommId(commID)
	editCommID = commID
end

---@return VaultSpell
local function getInfo()
	local newSpellData = {}

	newSpellData.commID = commandBox:GetText()
	newSpellData.fullName = nameBox:GetText()
	newSpellData.description = descBox:GetText()
	newSpellData.cooldown = tonumber(cooldownBox:GetText())
	newSpellData.castbar = castbarCheckButton:GetCheckState()
	newSpellData.icon = iconButton:GetSelectedTexID()
	newSpellData.profile = AtticProfileDropdown.getSelectedProfile()
	newSpellData.author = author or nil
	newSpellData.items = itemsCached
	newSpellData.conditions = (SCForgeMainFrame.conditionsData and #SCForgeMainFrame.conditionsData > 0) and SCForgeMainFrame.conditionsData or nil

	return newSpellData
end

---@param spell VaultSpell
local function updateInfo(spell)
	commandBox:SetText(spell.commID)
	nameBox:SetText(spell.fullName)
	cooldownBox:SetText(spell.cooldown and tostring(spell.cooldown) or "")
	castbarCheckButton:SetCheckState(spell.castbar)
	iconButton:SelectTex(spell.icon or 0)
	if spell.description then
		descBox:SetText(spell.description)
	end
	AtticProfileDropdown.setSelectedProfile(spell.profile)
	editCommID = spell.commID
	author = spell.author or nil
	itemsCached = spell.items or nil
	SCForgeMainFrame.conditionsData = spell.conditions or {}

	condButton:update()
end

local function isInfoValid()
	local spellInfo = getInfo()
	return not (isNotDefined(spellInfo.fullName) or isNotDefined(spellInfo.commID))
end

---@param mainFrameWidth integer
local function updateSize(mainFrameWidth)
	local widthScale = mainFrameWidth / MainFrame.size.Xmin
	local squareRootWidthScale = widthScale ^ 0.5
	local effectiveOffsetScale = widthScale ^ 1.5

	commandBox:SetWidth((mainFrameWidth / 5) * squareRootWidthScale)
	nameBox:SetWidth((mainFrameWidth / 4.5) * squareRootWidthScale)
	descBox:SetWidth((mainFrameWidth / 2.5) * squareRootWidthScale)

	iconButton:SetPoint("TOPRIGHT", nameBox, "TOPLEFT", -14 * effectiveOffsetScale, -6)
	condButton:SetPoint("BOTTOMLEFT", cooldownBox, "BOTTOMRIGHT", 2 * (effectiveOffsetScale * 3) - 3, 6)
	--print(widthScale, effectiveOffsetScale, squareRootWidthScale)
end

---@param callback fun()
local function onNameChange(callback)
	nameBox:HookScript("OnTextChanged", callback)
end

---@param callback fun()
local function onCommandChange(callback)
	commandBox:HookScript("OnTextChanged", callback)
end

---@param mainFrame SCForgeMainFrame
---@param IconPicker UI_IconPicker
local function init(mainFrame, IconPicker)
	mainFrame.SpellInfoNameBox = createNameBox(mainFrame)
	mainFrame.SpellInfoCommandBox = createCommandBox(mainFrame)
	mainFrame.SpellInfoDescBox = createInfoDescBox(mainFrame)
	mainFrame.SpellCooldownBox = createSpellCooldownBox(mainFrame)
	mainFrame.CastBarCheckButton = createCastbarCheckButton(mainFrame)
	mainFrame.IconButton = createIconButton(mainFrame, IconPicker)
	mainFrame.ConditionalButton = createConditionsButton(mainFrame)
	mainFrame.ProfileSelectMenu = AtticProfileDropdown.createDropdown({
		mainFrame = mainFrame,
		markEditorUnsaved = markEditorUnsaved,
	})

	-- Enable Tabbing between editboxes
	mainFrame.SpellInfoNameBox.nextEditBox = mainFrame.SpellInfoCommandBox
	mainFrame.SpellInfoCommandBox.nextEditBox = mainFrame.SpellInfoDescBox
	mainFrame.SpellInfoDescBox.nextEditBox = mainFrame.SpellCooldownBox
	mainFrame.SpellCooldownBox.nextEditBox = mainFrame.SpellInfoNameBox

	mainFrame.SpellCooldownBox.previousEditBox = mainFrame.SpellInfoDescBox
	mainFrame.SpellInfoDescBox.previousEditBox = mainFrame.SpellInfoCommandBox
	mainFrame.SpellInfoCommandBox.previousEditBox = mainFrame.SpellInfoNameBox
	mainFrame.SpellInfoNameBox.previousEditBox = mainFrame.SpellCooldownBox

	MainFrame.onSizeChanged(updateSize)
end

SCForgeMainFrame.ExpandAttic = function(self)
	FrameTemplate_SetAtticHeight(self, 90)
	descBox:SetMultiLine(true)
	descBox:SetRelativePoints()
	descBox:SetPoint("BOTTOM", SCForgeMainFrame.Inset, "TOP")
	-- need to finish fixing the descBox to be expandable..
end

SCForgeMainFrame.CollapseAttic = function(self)
	FrameTemplate_SetAtticHeight(self, 60)
	descBox:SetMultiLine(false)
	descBox:SetRelativePoints()
	descBox:SetSize(SCForgeMainFrame:GetWidth() / 2.5, 23)
end

---@class UI_MainFrame_Attic
ns.UI.MainFrame.Attic = {
	init = init,
	getInfo = getInfo,
	updateInfo = updateInfo,
	isInfoValid = isInfoValid,
	getEditCommId = getEditCommId,
	setEditCommId = setEditCommId,
	onNameChange = onNameChange,
	onCommandChange = onCommandChange,
	markEditorSaved = markEditorSaved,
	markEditorUnsaved = markEditorUnsaved,
	getEditorSavedState = getEditorSavedState,
	setAuthor = setAuthor,
	setAuthorMe = setAuthorMe,
	getAuthor = getAuthor,
}
