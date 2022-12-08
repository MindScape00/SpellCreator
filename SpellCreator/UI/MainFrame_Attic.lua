---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local DataUtils = ns.Utils.Data
local Localization = ns.Localization
local Tooltip = ns.Utils.Tooltip

local IconPicker = ns.UI.IconPicker
local Icons = ns.UI.Icons

local ASSETS_PATH = Constants.ASSETS_PATH
local isNotDefined = DataUtils.isNotDefined

local nameBox
local commandBox
local descBox
local castbarCheckButton
local profile -- to be replaced with actual select
local author
local editCommID
local iconButton

---@param mainFrame SCForgeMainFrame
local function createNameBox(mainFrame)
	nameBox = CreateFrame("EditBox", nil, mainFrame, "InputBoxInstructionsTemplate")
	nameBox:SetFontObject(ChatFontNormal)
	nameBox:SetMaxBytes(60)
	nameBox.disabledColor = GRAY_FONT_COLOR
	nameBox.enabledColor = HIGHLIGHT_FONT_COLOR
	nameBox.Instructions:SetText(Localization.SPELLNAME)
	nameBox.Instructions:SetTextColor(0.5,0.5,0.5)
	--nameBox.Title = nameBox:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	--nameBox.Title:SetText(NAME)
	--nameBox.Title:SetPoint("BOTTOM", nameBox, "TOP", 0, 0)
	nameBox:SetAutoFocus(false)
	nameBox:SetSize(mainFrame:GetWidth() / 4,23)
	nameBox:SetPoint("TOPRIGHT", mainFrame, "TOP", -3, -20)

	Tooltip.set(nameBox,
		Localization.SPELLNAME,
		"The name of the spell.\rThis can be anything and is only used for identifying the spell in the Vault & Chat Links.\n\rYes, you can have two spells with the same name, but that's annoying.."
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
	commandBox.Instructions:SetTextColor(0.5,0.5,0.5)
	--commandBox.Title = commandBox:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	--commandBox.Title:SetText(COMMAND)
	--commandBox.Title:SetPoint("BOTTOM", commandBox, "TOP", 0, 0)
	commandBox:SetAutoFocus(false)
	--commandBox:SetSize(mainFrame:GetWidth()/6,23)
	commandBox:SetSize(mainFrame:GetWidth()/5,23)
	commandBox:SetPoint("LEFT", nameBox, "RIGHT", 6, 0)

	Tooltip.set(commandBox,
		Localization.SPELLCOMM,
		{
			"The slash command trigger (commID) you want to use to call this spell.\n\rCast it using '/arcanum $command' after using Create.",
			" ",
			"This must be unique. Saving a spell with the same command ID as another will over-write the old spell."
		}
	)

	commandBox:HookScript("OnTextChanged", function(self)
		local selfText = self:GetText();
		if selfText:match(",") then self:SetText(selfText:gsub(",","")) end
	end)

	return commandBox
end

---@param mainFrame SCForgeMainFrame
local function createInfoDescBox(mainFrame)
	descBox = CreateFrame("EditBox", nil, mainFrame, "InputBoxInstructionsTemplate")
	descBox:SetFontObject(ChatFontNormal)
	descBox:SetMaxBytes(100)
	descBox.disabledColor = GRAY_FONT_COLOR
	descBox.enabledColor = HIGHLIGHT_FONT_COLOR
	descBox.Instructions:SetText("Description")
	descBox.Instructions:SetTextColor(0.5,0.5,0.5)
	--infoDescBox.Title = infoDescBox:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	--infoDescBox.Title:SetText("Description")
	--infoDescBox.Title:SetPoint("BOTTOM", infoDescBox, "TOP", 0, 0)
	descBox:SetAutoFocus(false)
	descBox:SetSize(mainFrame:GetWidth()/2.5,23)
	descBox.SetRelativePoints = function(self)
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", 0, 4)
		self:SetPoint("TOPRIGHT", commandBox, "BOTTOMRIGHT", 0, 4)
	end
	descBox:SetRelativePoints()

	Tooltip.set(descBox, "Description", "A short description of the spell.")

	return descBox
end

---@param mainFrame SCForgeMainFrame
local function createCastbarCheckButton(mainFrame)
	---@class CastbarCheckButton : CheckButton, UICheckButtonTemplate
	---@field checkState 0 | 1 | 2
	---@field checkTex Texture
	---@type CastbarCheckButton
	castbarCheckButton = CreateFrame("CheckButton", nil, mainFrame, "UICheckButtonTemplate")
	castbarCheckButton:SetSize(20,20)
	castbarCheckButton:SetPoint("LEFT", commandBox, "RIGHT", 0, 0)
	castbarCheckButton.text:SetText(" Cast/Channel Bar")
	castbarCheckButton.checkState = 1 -- 0 = none, 1 = cast, 2 = channel; default to cast

	castbarCheckButton.checkTex = castbarCheckButton:GetCheckedTexture()
	castbarCheckButton.UpdateCheckedTex = function(self)
		local checkState = self.checkState

		if checkState == 0 then
			self:SetChecked(false)
		elseif checkState == 1 then
			local checkTex = self:GetCheckedTexture()
			self:SetChecked(true);
			self.checkTex:SetTexture("Interface/Buttons/UI-CheckBox-Check")
			self.checkTex:SetAllPoints()
		elseif checkState == 2 then
			self:SetChecked(true);
			self.checkTex:SetAtlas("common-checkbox-partial")
			self.checkTex:ClearAllPoints()
			self.checkTex:SetPoint("CENTER")
			self.checkTex:SetSize(self:GetWidth()*0.5, self:GetHeight()*0.5)
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
	end)

	Tooltip.set(castbarCheckButton,
		"Castbar / Channelbar",
		function (self)
			local castingStateText = "None"
			if self.checkState == 1 then
				castingStateText = "Cast"
			elseif self.checkState == 2 then
				castingStateText = "Channel"
			end

			return {
				"Toggle the casting bar between:\rCast, Channel, or None.\n\rCastbars do not show, even if enabled, if the total spell length is under 0.25 seconds.",
				"\nCurrent: |cffAAAAFF" .. castingStateText .. "|r",
			}
		end,
		{ updateOnClick = true }
	)

	return castbarCheckButton
end

---@param mainFrame SCForgeMainFrame
local function createIconButton(mainFrame)
	iconButton = CreateFrame("BUTTON", nil, mainFrame)
	iconButton:SetSize(34,34)
	iconButton:SetPoint("TOPRIGHT", nameBox, "TOPLEFT", -22, -6)
	iconButton:SetNormalTexture("Interface/Icons/inv_misc_questionmark")
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
			self.highlight:SetTexture( ASSETS_PATH .. "/dm-trait-highlight" )
			self.highlight:Show()
		else
			self.highlight:SetTexture( ASSETS_PATH .. "/dm-trait-select" )
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
			return
		end
		IconPicker.IconPicker_Open(self)
		self:SetSelected(true)
	end)
	iconButton:RegisterForClicks("RightButtonUp", "LeftButtonUp")

	Tooltip.set(iconButton, "Select an Icon", "Click to select an icon for your ArcSpell. This will be shown in the vault, castbar, and Quickcast when used.\n\rRight Click to remove the icon. You should probably select an icon tho..")

	return iconButton
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
	newSpellData.castbar = castbarCheckButton:GetCheckState()
	newSpellData.icon = iconButton:GetSelectedTexID()
	newSpellData.profile = profile
	newSpellData.author = author

	return newSpellData
end

---@param spell VaultSpell
local function updateInfo(spell)
	commandBox:SetText(spell.commID)
	nameBox:SetText(spell.fullName)
	castbarCheckButton:SetCheckState(spell.castbar)
	iconButton:SelectTex(spell.icon or 0)
	if spell.description then
		descBox:SetText(spell.description)
	end
	profile = spell.profile
	editCommID = spell.commID
end

local function isInfoValid()
	local spellInfo = getInfo()
	return not (isNotDefined(spellInfo.fullName) or isNotDefined(spellInfo.commID))
end

---@param mainFrameWidth integer
local function updateSize(mainFrameWidth)
	commandBox:SetWidth(mainFrameWidth / 5)
	nameBox:SetWidth(mainFrameWidth / 4)
	descBox:SetWidth(mainFrameWidth / 2.5)
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
local function init(mainFrame)
	mainFrame.SpellInfoNameBox = createNameBox(mainFrame)
	mainFrame.SpellInfoCommandBox = createCommandBox(mainFrame)
	mainFrame.SpellInfoDescBox = createInfoDescBox(mainFrame)
	mainFrame.CastBarCheckButton = createCastbarCheckButton(mainFrame)
	mainFrame.IconButton = createIconButton(mainFrame)

	-- Enable Tabbing between editboxes
	mainFrame.SpellInfoNameBox.nextEditBox = mainFrame.SpellInfoCommandBox
	mainFrame.SpellInfoCommandBox.nextEditBox = mainFrame.SpellInfoDescBox
	mainFrame.SpellInfoDescBox.nextEditBox = mainFrame.SpellInfoNameBox
	mainFrame.SpellInfoDescBox.previousEditBox = mainFrame.SpellInfoCommandBox
	mainFrame.SpellInfoCommandBox.previousEditBox = mainFrame.SpellInfoNameBox
	mainFrame.SpellInfoNameBox.previousEditBox = mainFrame.SpellInfoDescBox
end

SCForgeMainFrame.ExpandAttic = function(self)
	FrameTemplate_SetAtticHeight(self, 90)
	descBox:SetMultiLine(true)
	descBox:SetRelativePoints()
	descBox:SetPoint("BOTTOM", SCForgeMainFrame.Inset, "TOP")
	-- need to finish fixing the descBox to be expandable..
end

SCForgeMainFrame.CloseAttic = function(self)
	FrameTemplate_SetAtticHeight(self, 60)
	descBox:SetMultiLine(false)
	descBox:SetRelativePoints()
	descBox:SetSize(SCForgeMainFrame:GetWidth()/2.5,23)
end

---@class UI_Attic
ns.UI.Attic = {
	init = init,
	getInfo = getInfo,
	updateInfo = updateInfo,
	isInfoValid = isInfoValid,
	getEditCommId = getEditCommId,
	setEditCommId = setEditCommId,
	updateSize = updateSize,
	onNameChange = onNameChange,
	onCommandChange = onCommandChange,
}
