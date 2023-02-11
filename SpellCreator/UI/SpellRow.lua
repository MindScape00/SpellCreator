---@class ns
local ns = select(2, ...)

local ActionsData = ns.Actions.Data
local Constants = ns.Constants
local DataUtils = ns.Utils.Data
local Debug = ns.Utils.Debug
local UIHelpers = ns.Utils.UIHelpers
local Tooltip = ns.Utils.Tooltip
local ADDON_COLORS = ns.Constants.ADDON_COLORS

local Attic = ns.UI.MainFrame.Attic
local Dropdown = ns.UI.Dropdown
local MainFrame = ns.UI.MainFrame.MainFrame
local SpellRowAction = ns.UI.SpellRowAction

local actionTypeData = ActionsData.actionTypeData
local ASSETS_PATH = Constants.ASSETS_PATH
local columnWidths = MainFrame.size.columnWidths
local rowHeight = MainFrame.size.rowHeight

-- Row Sizing / Info
local numActiveRows = 0
local maxNumberOfRows = 69

-- Column Widths
local delayColumnWidth = columnWidths.delay
local actionColumnWidth = columnWidths.action
local selfColumnWidth = columnWidths.self
local inputEntryColumnWidth = columnWidths.inputEntry
local revertDelayColumnWidth = columnWidths.revertDelay

---@type SpellRowFrame[]
SCForgeMainFrame.spellRows = {}

---@param row number
---@param selectedAction? ActionType
local function updateSpellRowOptions(row, selectedAction)
	-- perform action type checks here against the actionTypeData table & disable/enable buttons / entries as needed. See actionTypeData for available options.
	local theSpellRow = SCForgeMainFrame.spellRows[row]
	if selectedAction then -- if we call it with no action, reset
		local selectedActionData = actionTypeData[selectedAction]

		theSpellRow.SelectedAction = selectedAction
		if selectedActionData.selfAble then theSpellRow.SelfCheckbox:Enable() else theSpellRow.SelfCheckbox:Disable() end
		if selectedActionData.dataName then
			theSpellRow.InputEntryBox:Enable()
			theSpellRow.InputEntryBox.Instructions:SetText(selectedActionData.dataName)
			if selectedActionData.inputDescription then theSpellRow.InputEntryBox.Description = selectedActionData.inputDescription end
		else
			theSpellRow.InputEntryBox:Disable()
			theSpellRow.InputEntryBox.Instructions:SetText("n/a")
		end
		if selectedActionData.revert then
			theSpellRow.RevertDelayBox:Enable();
		else
			theSpellRow.RevertDelayBox:Disable();
		end
	else
		theSpellRow.SelectedAction = nil
		theSpellRow.SelfCheckbox:Disable()
		theSpellRow.InputEntryBox.Instructions:SetText("select an action...")
		theSpellRow.InputEntryBox:Disable()
		theSpellRow.RevertDelayBox:Disable()
	end
end

SpellRowAction.setCallback(updateSpellRowOptions)

---@param newRow SpellRowFrame
local function genSpellRowTextures(newRow)
	newRow.Background = newRow:CreateTexture(nil, "BACKGROUND", nil, 5)
	newRow.Background:SetAllPoints()
	newRow.Background:SetTexture(ASSETS_PATH .. "/SpellForgeMainPanelRow1")
	newRow.Background:SetTexCoord(0.208, 1 - 0.209, 0, 1)
	newRow.Background:SetPoint("BOTTOMRIGHT", -9, 0)
	newRow.Background:SetAlpha(0.9)
	--newRow.Background:SetColorTexture(0,0,0,0.25)

	newRow.Background2 = newRow:CreateTexture(nil, "BACKGROUND", nil, 6)
	newRow.Background2:SetAllPoints()
	newRow.Background2:SetTexture(ASSETS_PATH .. "/SpellForgeMainPanelRow2")
	newRow.Background2:SetTexCoord(0.208, 1 - 0.209, 0, 1)
	newRow.Background2:SetPoint("TOPLEFT", -3, 0)
	newRow.Background2:SetPoint("BOTTOMRIGHT", -7, 0)
	--newRow.Background2:SetAlpha(0.8)
	--newRow.Background:SetColorTexture(0,0,0,0.25)

	newRow.RowGem = newRow:CreateTexture(nil, "ARTWORK")
	newRow.RowGem:SetPoint("CENTER", newRow.Background2, "LEFT", 2, 0)
	newRow.RowGem:SetHeight(40)
	newRow.RowGem:SetWidth(40)
	newRow.RowGem:SetTexture(ASSETS_PATH .. "/DragonGem")
	--newRow.RowGem:SetTexCoord(0.208,1-0.209,0,1)
	--newRow.RowGem:SetPoint("RIGHT",-9,0)
end

---@param row SpellRowFrame
local function createDropdown(row)
	local name = "SCForgeMainFrameSpellRow" .. numActiveRows .. "ActionSelectButtnewRn"

	return Dropdown.create(row, name):WithAppearance(actionColumnWidth):SetText("Action")
end

---@param rowToRemove number?
local function removeRow(rowToRemove)
	Attic.markEditorUnsaved()

	if numActiveRows <= 1 then
		local theSpellRow = SCForgeMainFrame.spellRows[numActiveRows]
		theSpellRow.mainDelayBox:SetText("")

		theSpellRow.actionSelectButton:SetText("Action")
		updateSpellRowOptions(numActiveRows, nil)

		theSpellRow.SelfCheckbox:SetChecked(false)
		theSpellRow.InputEntryBox:SetText("")
		theSpellRow.RevertDelayBox:SetText("")
		return;
	end

	if rowToRemove and (rowToRemove ~= numActiveRows) then
		for i = rowToRemove, numActiveRows - 1 do
			local theRowToSet = SCForgeMainFrame.spellRows[i]
			local theRowToGrab = SCForgeMainFrame.spellRows[i + 1]

			theRowToSet.actionSelectButton:SetText(theRowToGrab.actionSelectButton:GetText())
			theRowToSet.SelectedAction = theRowToGrab.SelectedAction
			updateSpellRowOptions(i, theRowToGrab.SelectedAction)

			theRowToSet.mainDelayBox:SetText(theRowToGrab.mainDelayBox:GetText())
			theRowToSet.SelfCheckbox:SetChecked(theRowToGrab.SelfCheckbox:GetChecked())
			theRowToSet.InputEntryBox:SetText(theRowToGrab.InputEntryBox:GetText())
			theRowToSet.RevertDelayBox:SetText(theRowToGrab.RevertDelayBox:GetText())
		end
	end

	-- Now that we moved the data if needed, let's delete the last row..
	local theSpellRow = SCForgeMainFrame.spellRows[numActiveRows]
	theSpellRow:Hide()

	--	if SpellCreatorMasterTable.Options["clearRowOnRemove"] then
	theSpellRow.mainDelayBox:SetText("")

	-- theSpellRow.actionSelectButton.Dropdown
	theSpellRow.actionSelectButton.Text:SetText("Action")
	updateSpellRowOptions(numActiveRows, nil)

	theSpellRow.SelfCheckbox:SetChecked(false)
	theSpellRow.InputEntryBox:SetText("")
	theSpellRow.RevertDelayBox:SetText("")
	--	end

	numActiveRows = numActiveRows - 1

	SCForgeMainFrame.spellRows[numActiveRows].RevertDelayBox.nextEditBox = SCForgeMainFrame.spellRows[1].mainDelayBox

	--if numActiveRows < maxNumberOfRows then SCForgeMainFrame.AddSpellRowButton:Enable() end
	if numActiveRows < maxNumberOfRows then SCForgeMainFrame.AddRowRow.AddRowButton:Enable() end

	--if numActiveRows <= 1 then SCForgeMainFrame.RemoveSpellRowButton:Disable() end
	SCForgeMainFrame.Inset.scrollFrame:UpdateScrollChildRect()

	SCForgeMainFrame.AddRowRow:SetPoint("TOPLEFT", SCForgeMainFrame.spellRows[numActiveRows], "BOTTOMLEFT", 0, 0)
end

---@return FunctionActionTypeData | ServerActionTypeData | nil
local function getRowActionTypeData(rowNum)
	local actionType = SCForgeMainFrame.spellRows[rowNum].SelectedAction


	if actionType and actionTypeData[actionType] then
		return actionTypeData[actionType]
	end
end

---@param rowToAdd number?
local function addRow(rowToAdd)
	if numActiveRows >= maxNumberOfRows then SCForgeMainFrame.AddRowRow.AddRowButton:Disable() end -- hard cap the add button
	numActiveRows = numActiveRows + 1 -- The number of spell rows that this row will be.

	---@class SpellRowFrame: Frame
	---@field SelectedAction ActionType
	local newRow
	if SCForgeMainFrame.spellRows[numActiveRows] then
		newRow = SCForgeMainFrame.spellRows[numActiveRows]
		newRow:Show();
	else
		newRow = CreateFrame("Frame", nil, SCForgeMainFrame.Inset.scrollFrame.scrollChild) --[[@as SpellRowFrame]]
		newRow.rowNum = numActiveRows
		SCForgeMainFrame.spellRows[newRow.rowNum] = newRow

		if numActiveRows == 1 then
			newRow:SetPoint("TOPLEFT", 25, 0)
		else
			newRow:SetPoint("TOPLEFT", SCForgeMainFrame.spellRows[numActiveRows - 1], "BOTTOMLEFT", 0, 0)
		end
		newRow:SetWidth(MainFrame.size.x - 50)
		newRow:SetHeight(rowHeight)

		genSpellRowTextures(newRow)

		-- main delay entry box
		newRow.mainDelayBox = CreateFrame("EditBox", nil, newRow, "InputBoxInstructionsTemplate")
		newRow.mainDelayBox:SetFontObject(ChatFontNormal)
		newRow.mainDelayBox.disabledColor = GRAY_FONT_COLOR
		newRow.mainDelayBox.enabledColor = HIGHLIGHT_FONT_COLOR
		newRow.mainDelayBox.Instructions:SetText("(Seconds)")
		newRow.mainDelayBox.Instructions:SetTextColor(0.5, 0.5, 0.5)
		newRow.mainDelayBox:SetAutoFocus(false)
		newRow.mainDelayBox:SetSize(delayColumnWidth, 23)
		newRow.mainDelayBox:SetPoint("LEFT", 40, 0)
		newRow.mainDelayBox:SetMaxLetters(10)
		newRow.mainDelayBox:HookScript("OnTextChanged", function(self, userInput)
			if self:GetText() == self:GetText():match("%d+") or self:GetText() == self:GetText():match("%d+%.%d+") or self:GetText() == self:GetText():match("%.%d+") then
				self:SetTextColor(255, 255, 255, 1)
			elseif self:GetText() == "" then
				self:SetTextColor(255, 255, 255, 1)
			elseif self:GetText():find("%a") then
				self:SetText(self:GetText():gsub("%a", ""))
			else
				self:SetTextColor(1, 0, 0, 1)
			end
			if userInput then Attic.markEditorUnsaved(); SCForgeMainFrame.SaveSpellButton:UpdateIfValid(); end
		end)
		Tooltip.set(newRow.mainDelayBox, "Main Action Delay", "How long after 'casting' the ArcSpell this action triggers.\rCan be '0' for instant.")

		newRow.actionSelectButton = createDropdown(newRow)
		newRow.actionSelectButton:SetPoint("LEFT", newRow.mainDelayBox, "RIGHT", 0, -2)
		SpellRowAction.initialize(newRow)

		-- Self Checkbox
		newRow.SelfCheckbox = CreateFrame("CHECKBUTTON", nil, newRow, "UICheckButtonTemplate")
		newRow.SelfCheckbox:SetPoint("LEFT", newRow.actionSelectButton, "RIGHT", -5, 1)
		newRow.SelfCheckbox:Disable()
		newRow.SelfCheckbox:SetMotionScriptsWhileDisabled(true)
		Tooltip.set(newRow.SelfCheckbox, "Cast on Self", "Enable to use the 'Self' flag for Cast & Aura actions.")


		---@class SpellRowFrameInput: EditBox, InputBoxInstructionsTemplate
		---@field rowNumber integer
		local inputEntryBox

		-- ID Entry Box (Input)
		if SpellCreatorMasterTable.Options["biggerInputBox"] == true then
			newRow.InputEntryScrollFrame = CreateFrame("ScrollFrame", nil, newRow, "InputScrollFrameTemplate")
			newRow.InputEntryScrollFrame.CharCount:Hide()
			newRow.InputEntryScrollFrame:SetSize(inputEntryColumnWidth, 40)
			newRow.InputEntryScrollFrame:SetPoint("LEFT", newRow.SelfCheckbox, "RIGHT", 15, 1)
			inputEntryBox = newRow.InputEntryScrollFrame.EditBox --[[@as SpellRowFrameInput]]
			inputEntryBox:SetWidth(newRow.InputEntryScrollFrame:GetWidth() - 18)
		else
			inputEntryBox = CreateFrame("EditBox", nil, newRow, "InputBoxInstructionsTemplate") --[[@as SpellRowFrameInput]]
			inputEntryBox:SetSize(inputEntryColumnWidth, 23)
			inputEntryBox:SetPoint("LEFT", newRow.SelfCheckbox, "RIGHT", 15, 1)
		end

		newRow.InputEntryBox = inputEntryBox

		newRow.InputEntryBox:SetFontObject(ChatFontNormal)
		newRow.InputEntryBox.disabledColor = GRAY_FONT_COLOR
		newRow.InputEntryBox.enabledColor = HIGHLIGHT_FONT_COLOR
		newRow.InputEntryBox.Instructions:SetText("select an action...")
		newRow.InputEntryBox.Instructions:SetTextColor(0.5, 0.5, 0.5)
		newRow.InputEntryBox.Description = ""
		newRow.InputEntryBox.rowNumber = numActiveRows
		newRow.InputEntryBox:SetAutoFocus(false)
		newRow.InputEntryBox:Disable()
		newRow.InputEntryBox:HookScript("OnTextChanged", function(self, userInput)
			if userInput then Attic.markEditorUnsaved() end
		end)

		Tooltip.set(newRow.InputEntryBox,
			function(self) -- title
				local actionData = getRowActionTypeData(self.rowNumber)
				return actionData and actionData.dataName or nil
			end,
			function(self) -- body
				local actionData = getRowActionTypeData(self.rowNumber)
				local strings = {}

				if actionData then
					if actionData.inputDescription then
						tinsert(strings, " ")
						tinsert(strings, actionData.inputDescription)
					end
					if actionData.example then
						tinsert(strings, " ")
						tinsert(strings, Tooltip.genTooltipText("example", actionData.example))
					end
				end

				return strings
			end
		)

		-- Revert Delay Box

		newRow.RevertDelayBox = CreateFrame("EditBox", nil, newRow, "InputBoxInstructionsTemplate")
		newRow.RevertDelayBox:SetFontObject(ChatFontNormal)
		newRow.RevertDelayBox.disabledColor = GRAY_FONT_COLOR
		newRow.RevertDelayBox.enabledColor = HIGHLIGHT_FONT_COLOR
		newRow.RevertDelayBox.Instructions:SetText("Revert Delay")
		newRow.RevertDelayBox.Instructions:SetTextColor(0.5, 0.5, 0.5)
		newRow.RevertDelayBox.rowNumber = numActiveRows
		newRow.RevertDelayBox:SetAutoFocus(false)
		newRow.RevertDelayBox:Disable()
		newRow.RevertDelayBox:SetSize(revertDelayColumnWidth, 23)
		newRow.RevertDelayBox:SetPoint("LEFT", (newRow.InputEntryScrollFrame or newRow.InputEntryBox), "RIGHT", 25, 0)
		newRow.RevertDelayBox:SetMaxLetters(10)

		newRow.RevertDelayBox:HookScript("OnTextChanged", function(self, userInput)
			if self:GetText() == self:GetText():match("%d+") or self:GetText() == self:GetText():match("%d+%.%d+") or self:GetText() == self:GetText():match("%.%d+") then
				self:SetTextColor(255, 255, 255, 1)
			elseif self:GetText() == "" then
				self:SetTextColor(255, 255, 255, 1)
			elseif self:GetText():find("%a") then
				self:SetText(self:GetText():gsub("%a", ""))
			else
				self:SetTextColor(1, 0, 0, 1)
			end
			if userInput then Attic.markEditorUnsaved() end
		end)

		Tooltip.set(newRow.RevertDelayBox,
			"Revert Delay",
			function(self) -- body
				local actionData = getRowActionTypeData(self.rowNumber)
				local strings = {
					"How long after the initial action before reverting.\n",
				}

				if actionData then
					if actionData.revertDesc then
						tinsert(strings, Tooltip.genTooltipText("revert", actionData.revertDesc))
					elseif actionData.revertAlternative then
						tinsert(strings, Tooltip.genTooltipText("norevert", "This Action cannot be reverted directly, use " .. actionData.revertAlternative .. "."))
					else
						tinsert(strings, ADDON_COLORS.TOOLTIP_NOREVERT:WrapTextInColorCode("The current action cannot be reverted."))
					end
				else
					tinsert(strings, ADDON_COLORS.TOOLTIP_NOREVERT:WrapTextInColorCode("No Action Selected."))
				end

				tinsert(strings, "Note: This is RELATIVE to this lines main action delay\n")
				tinsert(strings, Tooltip.genTooltipText("example", "Aura action with delay 2, and revert delay 3, means the revert is 3 seconds after the aura action itself, NOT 3 seconds after casting.."))
				return strings
			end
		)

		newRow.RevertDelayBox:HookScript("OnDisable", function(self)
			self.Instructions:SetText("n/a")
		end)
		newRow.RevertDelayBox:HookScript("OnEnable", function(self)
			self.Instructions:SetText("Revert Delay")
		end)

		newRow.AddSpellRowButton = CreateFrame("BUTTON", nil, newRow)
		newRow.AddSpellRowButton.rowNum = numActiveRows
		newRow.AddSpellRowButton:SetPoint("TOPLEFT", 2, -3)
		newRow.AddSpellRowButton:SetSize(24, 24)
		--local _atlas = "transmog-icon-remove"
		local _atlas = "communities-chat-icon-plus"

		newRow.AddSpellRowButton:SetNormalAtlas(_atlas)
		newRow.AddSpellRowButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

		newRow.AddSpellRowButton.DisabledTex = newRow.AddSpellRowButton:CreateTexture(nil, "ARTWORK")
		newRow.AddSpellRowButton.DisabledTex:SetAllPoints(true)
		newRow.AddSpellRowButton.DisabledTex:SetAtlas(_atlas)
		newRow.AddSpellRowButton.DisabledTex:SetDesaturated(true)
		newRow.AddSpellRowButton.DisabledTex:SetVertexColor(.6, .6, .6)
		newRow.AddSpellRowButton:SetDisabledTexture(newRow.AddSpellRowButton.DisabledTex)

		newRow.AddSpellRowButton.PushedTex = newRow.AddSpellRowButton:CreateTexture(nil, "ARTWORK")
		newRow.AddSpellRowButton.PushedTex:SetAllPoints(true)
		newRow.AddSpellRowButton.PushedTex:SetAtlas(_atlas)
		UIHelpers.setTextureOffset(newRow.AddSpellRowButton.PushedTex, 1, -1)
		newRow.AddSpellRowButton:SetPushedTexture(newRow.AddSpellRowButton.PushedTex)

		newRow.AddSpellRowButton:SetMotionScriptsWhileDisabled(true)

		Tooltip.set(newRow.AddSpellRowButton, "Add a new, blank row above this one")

		newRow.AddSpellRowButton:SetScript("OnClick", function(self)
			addRow(self.rowNum)
			SCForgeMainFrame.SaveSpellButton:UpdateIfValid()
		end)
		newRow.AddSpellRowButton:SetScript("OnShow", function(self)
			if SCForgeMainFrame.AddRowRow.AddRowButton:IsEnabled() then self:Enable(); else self:Disable(); end
		end)
		newRow.AddSpellRowButton:Hide()

		newRow.RemoveSpellRowButton = CreateFrame("BUTTON", nil, newRow)
		newRow.RemoveSpellRowButton.rowNum = numActiveRows
		newRow.RemoveSpellRowButton:SetPoint("TOPRIGHT", -11, -1)
		newRow.RemoveSpellRowButton:SetSize(24, 24)
		--local _atlas = "transmog-icon-remove"
		local _atlas = "communities-chat-icon-minus"

		newRow.RemoveSpellRowButton:SetNormalAtlas(_atlas)
		newRow.RemoveSpellRowButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

		newRow.RemoveSpellRowButton.DisabledTex = newRow.RemoveSpellRowButton:CreateTexture(nil, "ARTWORK")
		newRow.RemoveSpellRowButton.DisabledTex:SetAllPoints(true)
		newRow.RemoveSpellRowButton.DisabledTex:SetAtlas(_atlas)
		newRow.RemoveSpellRowButton.DisabledTex:SetDesaturated(true)
		newRow.RemoveSpellRowButton.DisabledTex:SetVertexColor(.6, .6, .6)
		newRow.RemoveSpellRowButton:SetDisabledTexture(newRow.RemoveSpellRowButton.DisabledTex)

		newRow.RemoveSpellRowButton.PushedTex = newRow.RemoveSpellRowButton:CreateTexture(nil, "ARTWORK")
		newRow.RemoveSpellRowButton.PushedTex:SetAllPoints(true)
		newRow.RemoveSpellRowButton.PushedTex:SetAtlas(_atlas)
		UIHelpers.setTextureOffset(newRow.RemoveSpellRowButton.PushedTex, 1, -1)
		newRow.RemoveSpellRowButton:SetPushedTexture(newRow.RemoveSpellRowButton.PushedTex)

		newRow.RemoveSpellRowButton:SetMotionScriptsWhileDisabled(true)
		Tooltip.set(newRow.RemoveSpellRowButton, "Delete this row")

		newRow.RemoveSpellRowButton:SetScript("OnClick", function(self)
			removeRow(self.rowNum)
			SCForgeMainFrame.SaveSpellButton:UpdateIfValid()
		end)
		newRow.RemoveSpellRowButton:SetScript("OnShow", function(self)
			self:SetScript("OnUpdate", function(self)
				if not self:GetParent():IsMouseOver() then self:Hide(); end
			end)
			newRow.AddSpellRowButton:Show()
		end)
		newRow.RemoveSpellRowButton:SetScript("OnHide", function(self)
			self:SetScript("OnUpdate", nil)
			newRow.AddSpellRowButton:Hide()
		end)
		newRow:SetScript("OnEnter", function(self)
			self.RemoveSpellRowButton:Show()
		end)
		newRow.RemoveSpellRowButton:Hide()

	end
	-- Make Tab work to switch edit boxes

	newRow.mainDelayBox.nextEditBox = newRow.InputEntryBox -- Main Delay -> Input
	newRow.mainDelayBox.previousEditBox = newRow.mainDelayBox -- Main Delay <- Main Delay (Can't reverse past itself, updated later)
	newRow.InputEntryBox.nextEditBox = newRow.RevertDelayBox -- Input -> Revert
	newRow.InputEntryBox.previousEditBox = newRow.mainDelayBox -- Input <- Main Delay
	newRow.RevertDelayBox.nextEditBox = newRow.mainDelayBox -- Revert -> Main Delay (we change it later if needed)
	newRow.RevertDelayBox.previousEditBox = newRow.InputEntryBox -- Revert <- Input

	if numActiveRows > 1 then
		local prevRow = SCForgeMainFrame.spellRows[numActiveRows - 1]
		newRow.mainDelayBox.previousEditBox = prevRow.RevertDelayBox -- Main Delay <- LAST Revert
		newRow.RevertDelayBox.nextEditBox = SCForgeMainFrame.spellRows[1].mainDelayBox -- Revert -> Spell Row 1 Main Delay
		prevRow.RevertDelayBox.nextEditBox = newRow.mainDelayBox -- LAST Revert -> THIS Main Delay

		newRow.mainDelayBox:SetText(prevRow.mainDelayBox:GetText())
	end

	MainFrame.updateFrameChildScales(SCForgeMainFrame)

	SCForgeMainFrame.AddRowRow:SetPoint("TOPLEFT", SCForgeMainFrame.spellRows[numActiveRows], "BOTTOMLEFT", 0, 0)

	SCForgeMainFrame.Inset.scrollFrame:UpdateScrollChildRect()

	if rowToAdd then
		for i = numActiveRows, rowToAdd + 1, -1 do
			local theRowToSet = SCForgeMainFrame.spellRows[i]
			local theRowToGrab = SCForgeMainFrame.spellRows[i - 1]

			theRowToSet.actionSelectButton:SetText(theRowToGrab.actionSelectButton:GetText())
			theRowToSet.SelectedAction = theRowToGrab.SelectedAction
			updateSpellRowOptions(i, theRowToGrab.SelectedAction)

			theRowToSet.mainDelayBox:SetText(theRowToGrab.mainDelayBox:GetText())
			theRowToSet.SelfCheckbox:SetChecked(theRowToGrab.SelfCheckbox:GetChecked())
			theRowToSet.InputEntryBox:SetText(theRowToGrab.InputEntryBox:GetText())
			theRowToSet.RevertDelayBox:SetText(theRowToGrab.RevertDelayBox:GetText())
		end
		local theRowToSet = SCForgeMainFrame.spellRows[rowToAdd]
		local prevRow = SCForgeMainFrame.spellRows[rowToAdd - 1]
		theRowToSet.actionSelectButton.Text:SetText("Action")
		updateSpellRowOptions(rowToAdd)

		if prevRow then
			theRowToSet.mainDelayBox:SetText(prevRow.mainDelayBox:GetText())
		else
			theRowToSet.mainDelayBox:SetText("")
		end
		theRowToSet.SelfCheckbox:SetChecked(false)
		theRowToSet.InputEntryBox:SetText("")
		theRowToSet.RevertDelayBox:SetText("")
	end
end

local function addAddRowRow()
	local addRowRow = CreateFrame("Frame", nil, SCForgeMainFrame.Inset.scrollFrame.scrollChild)
	addRowRow:SetPoint("TOPLEFT", 25, 0)
	addRowRow:SetWidth(MainFrame.size.x - 50)
	addRowRow:SetHeight(MainFrame.size.rowHeight)

	addRowRow.Background = addRowRow:CreateTexture(nil, "BACKGROUND", nil, 5)
	addRowRow.Background:SetAllPoints()
	addRowRow.Background:SetTexture(ASSETS_PATH .. "/SpellForgeMainPanelRow1")
	addRowRow.Background:SetTexCoord(0.208, 1 - 0.209, 0, 1)
	addRowRow.Background:SetPoint("BOTTOMRIGHT", -9, 0)
	addRowRow.Background:SetAlpha(0.9)

	addRowRow.Background2 = addRowRow:CreateTexture(nil, "BACKGROUND", nil, 6)
	addRowRow.Background2:SetAllPoints()
	addRowRow.Background2:SetTexture(ASSETS_PATH .. "/SpellForgeMainPanelRow2")
	addRowRow.Background2:SetTexCoord(0.208, 1 - 0.209, 0, 1)
	addRowRow.Background2:SetPoint("TOPLEFT", -3, 0)
	addRowRow.Background2:SetPoint("BOTTOMRIGHT", -7, 0)

	local addRowButton = CreateFrame("BUTTON", nil, addRowRow)
	addRowButton:SetAllPoints()

	local _atlas = "communities-chat-icon-plus"
	addRowButton:SetNormalAtlas(_atlas)
	addRowButton.Normal = addRowButton:GetNormalTexture()
	addRowButton.Normal:ClearAllPoints()
	addRowButton.Normal:SetPoint("CENTER")
	addRowButton.Normal:SetSize(48, 48)
	addRowButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

	addRowButton.DisabledTex = addRowButton:CreateTexture(nil, "ARTWORK")
	addRowButton.DisabledTex:SetAllPoints(addRowButton.Normal)
	addRowButton.DisabledTex:SetAtlas(_atlas)
	addRowButton.DisabledTex:SetDesaturated(true)
	addRowButton.DisabledTex:SetVertexColor(.6, .6, .6)
	addRowButton:SetDisabledTexture(addRowButton.DisabledTex)

	addRowButton.PushedTex = addRowButton:CreateTexture(nil, "ARTWORK")
	addRowButton.PushedTex:SetAllPoints(addRowButton.Normal)
	addRowButton.PushedTex:SetAtlas(_atlas)
	UIHelpers.setTextureOffset(addRowButton.PushedTex, 1, -1)
	addRowButton:SetPushedTexture(addRowButton.PushedTex)

	addRowButton:SetMotionScriptsWhileDisabled(true)
	Tooltip.set(addRowButton, "Add another Action Row", "Max number of Rows: " .. maxNumberOfRows)
	addRowButton:SetScript("OnClick", function()
		addRow()
	end)

	addRowRow.AddRowButton = addRowButton
	SCForgeMainFrame.AddRowRow = addRowRow
end

local function getNumActiveRows()
	return numActiveRows
end

---@param numRows number
local function setNumActiveRows(numRows)
	if numRows > numActiveRows then
		for i = 1, numRows - numActiveRows do
			addRow()
		end
	elseif numRows < numActiveRows then
		for i = 1, numActiveRows - numRows do
			removeRow()
		end
	end
end

---@return VaultSpellAction | nil
local function getRowAction(rowNum)
	local row = SCForgeMainFrame.spellRows[rowNum]

	local mainDelay = tonumber(row.mainDelayBox:GetText())
	if DataUtils.isNotDefined(mainDelay) then return end

	local actionData = {}

	actionData.actionType = row.SelectedAction
	actionData.delay = mainDelay
	actionData.revertDelay = tonumber(row.RevertDelayBox:GetText())
	actionData.selfOnly = row.SelfCheckbox:GetChecked()
	actionData.vars = row.InputEntryBox:GetText()

	Debug.ddump(actionData)

	return actionData
end

---@param rowNum number
---@param actionData VaultSpellAction
local function setRowAction(rowNum, actionData)
	local _spellRow = SCForgeMainFrame.spellRows[rowNum]
	if actionData.actionType == "reset" then
		_spellRow.actionSelectButton:SetText("Action")
		updateSpellRowOptions(rowNum)
	else
		_spellRow.actionSelectButton:SetText(actionTypeData[actionData.actionType].name)
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

local function isRowValid(rowNum)
	local rowData = getRowAction(rowNum)
	if not rowData then return end
	if not rowData.delay and not rowData.delay >= 0 then return end
	if not getRowActionTypeData(rowNum) then return end
	return true
end

local function isAnyActionRowValid()
	for i = 1, getNumActiveRows() do
		if isRowValid(i) then
			return true
		end
	end
end

---@class UI_SpellRow
ns.UI.SpellRow = {
	maxNumberOfRows = maxNumberOfRows,
	size = {
		rowHeight = rowHeight,

		delayColumnWidth = delayColumnWidth,
		actionColumnWidth = actionColumnWidth,
		selfColumnWidth = selfColumnWidth,
		inputEntryColumnWidth = inputEntryColumnWidth,
		revertDelayColumnWidth = delayColumnWidth,
	},

	addRow = addRow,
	addAddRowRow = addAddRowRow,
	removeRow = removeRow,
	getNumActiveRows = getNumActiveRows,
	setNumActiveRows = setNumActiveRows,
	getRowAction = getRowAction,
	setRowAction = setRowAction,
	isRowValid = isRowValid,
	isAnyActionRowValid = isAnyActionRowValid,
}
