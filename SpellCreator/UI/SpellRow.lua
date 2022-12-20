---@class ns
local ns = select(2, ...)

local ActionsData = ns.Actions.Data
local Constants = ns.Constants
local DataUtils = ns.Utils.Data
local Debug = ns.Utils.Debug
local UIHelpers = ns.Utils.UIHelpers
local Tooltip = ns.Utils.Tooltip

local MainFrame = ns.UI.MainFrame.MainFrame
local Attic = ns.UI.MainFrame.Attic

local actionTypeData, actionTypeDataList = ActionsData.actionTypeData, ActionsData.actionTypeDataList
local ASSETS_PATH = Constants.ASSETS_PATH
local columnWidths = MainFrame.size.columnWidths

-- Row Sizing / Info
local numActiveRows = 0
local maxNumberOfRows = 69
local rowHeight = 60

-- Column Widths
local delayColumnWidth = columnWidths.delay
local actionColumnWidth = columnWidths.action
local selfColumnWidth = columnWidths.self
local inputEntryColumnWidth = columnWidths.inputEntry
local revertDelayColumnWidth = columnWidths.revertDelay

SCForgeMainFrame.spellRows = {}

---@param row number
---@param selectedAction? string
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

---@param newRow Frame
local function genSpellRowTextures(newRow)
	newRow.Background = newRow:CreateTexture(nil,"BACKGROUND", nil, 5)
	newRow.Background:SetAllPoints()
	newRow.Background:SetTexture(ASSETS_PATH .. "/SpellForgeMainPanelRow1")
	newRow.Background:SetTexCoord(0.208,1-0.209,0,1)
	newRow.Background:SetPoint("BOTTOMRIGHT",-9,0)
	newRow.Background:SetAlpha(0.9)
	--newRow.Background:SetColorTexture(0,0,0,0.25)

	newRow.Background2 = newRow:CreateTexture(nil,"BACKGROUND", nil, 6)
	newRow.Background2:SetAllPoints()
	newRow.Background2:SetTexture(ASSETS_PATH .. "/SpellForgeMainPanelRow2")
	newRow.Background2:SetTexCoord(0.208,1-0.209,0,1)
	newRow.Background2:SetPoint("TOPLEFT",-3,0)
	newRow.Background2:SetPoint("BOTTOMRIGHT",-7,0)
	--newRow.Background2:SetAlpha(0.8)
	--newRow.Background:SetColorTexture(0,0,0,0.25)

	newRow.RowGem = newRow:CreateTexture(nil,"ARTWORK")
	newRow.RowGem:SetPoint("CENTER", newRow.Background2, "LEFT", 2, 0)
	newRow.RowGem:SetHeight(40)
	newRow.RowGem:SetWidth(40)
	newRow.RowGem:SetTexture(ASSETS_PATH .. "/DragonGem")
	--newRow.RowGem:SetTexCoord(0.208,1-0.209,0,1)
	--newRow.RowGem:SetPoint("RIGHT",-9,0)
end

local function updateActionDropdownCheckedStates(menuList, actionType, parentItem)
	for _, menuItem in pairs(menuList) do
		if menuItem.value == actionType then
			menuItem.checked = true
			if parentItem then
				parentItem.checked = true
			end
		else
			menuItem.checked = false
			if menuItem.menuList then
				updateActionDropdownCheckedStates(menuItem.menuList, actionType, menuItem)
			end
		end
	end
end

---@param dataList ActionType[]
---@param flatMenuList MenuItem[]
---@param menuList MenuItem[]
---@param parentItem MenuItem?
local function initActionDropdownItems(dataList, flatMenuList, menuList, parentItem)
	for i = 1, #dataList do
		local key = dataList[i]
		local data = actionTypeData[key]
		if data.dependency and not IsAddOnLoaded(data.dependency) then
			--eprint("AddOn " .. data.dependency .. " required for action "..data.name);
		else
			local menuItem = UIDropDownMenu_CreateInfo()
			menuItem.text = data.name

			if data.type == "header" then
				menuItem.isTitle = true
				menuItem.text = data.name
				menuItem.notCheckable = true
			elseif data.type == "spacer" then
				menuItem.text = ""
				menuItem.notCheckable = true
				menuItem.disabled = true
			elseif data.type == "submenu" then
				menuItem.text = data.name
				menuItem.hasArrow = true
				menuItem.keepShownOnClick = true
				menuItem.value = nil

				menuItem.menuList = {}

				initActionDropdownItems(data.menuDataList, flatMenuList, menuItem.menuList, menuItem)
			else
				menuItem.text = data.name
				menuItem.tooltipTitle = data.name
				menuItem.tooltipText = data.description

				if data.selfAble then
					menuItem.tooltipText = menuItem.tooltipText .. "\n\r" .. "Enable the "..Tooltip.genContrastText("Self").." checkbox to always apply to yourself."
				end

				if data.example then
					menuItem.tooltipText = menuItem.tooltipText .. "\n\r" .. (Tooltip.genTooltipText("example", data.example))
				end

				if data.revert and data.revertDesc then
					menuItem.tooltipText = menuItem.tooltipText .. "\n\r" .. (Tooltip.genTooltipText("revert", data.revertDesc))
				elseif data.revert == nil and data.revertAlternative then
					menuItem.tooltipText = menuItem.tooltipText .. "\n\r" .. (Tooltip.genTooltipText("norevert", "Cannot be reverted directly, use " .. data.revertAlternative .. "."))
				end

				menuItem.tooltipOnButton = true
				menuItem.value = key
				menuItem.arg1 = numActiveRows
				menuItem.func = function(self, arg1)
					for _, v in pairs(flatMenuList) do
						v.checked = false
					end

					menuItem.checked = true
					if (parentItem) then
						parentItem.checked = true
					end

					UIDropDownMenu_SetText(SCForgeMainFrame.spellRows[arg1].actionSelectButton, menuItem.text)
					Debug.ddump(self)
					updateSpellRowOptions(arg1, menuItem.value)

					Attic.markEditorUnsaved()

					if (parentItem) then
						CloseDropDownMenus()
					end
				end

				if (parentItem) then
					parentItem.func = function(self)
						_G[self:GetName().."Check"]:Hide()
					end
				end
			end

			table.insert(menuList, menuItem)
			table.insert(flatMenuList, menuItem)
		end
	end
end

---@param parent Frame
---@param dropdownName string
---@param menuList MenuItem[] | function
---@param title string
---@param width number?
local function genStaticDropdownChild( parent, dropdownName, menuList, title, width )
	if not parent or not dropdownName or not menuList then return end;
	if not title then title = "Select" end
	if not width then width = 55 end
	local newDropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
	--parent.Dropdown = newDropdown
	newDropdown:SetPoint("CENTER")

	if type(menuList) == "table" then
		local function newDropdown_Initialize(_, level, subMenu )
			local list = menuList
			if subMenu then list = subMenu end
			for index = 1, #list do
				local value = list[index]
				if (value.text) then
					value.index = index;
					UIDropDownMenu_AddButton( value, level );
				end
			end
		end

		UIDropDownMenu_Initialize(newDropdown, newDropdown_Initialize, "nope", nil, menuList)

	elseif type(menuList) == "function" then
		newDropdown.Button:SetScript("OnClick", function(self)
			EasyMenu(menuList(self), ARCProfileContextMenu, self, 0, 0, "DROPDOWN")
		end)
	end

	UIDropDownMenu_SetWidth(newDropdown, width);
	UIDropDownMenu_SetButtonWidth(newDropdown, width+15)
	UIDropDownMenu_SetSelectedID(newDropdown, 0)
	UIDropDownMenu_JustifyText(newDropdown, "LEFT")
	UIDropDownMenu_SetText(newDropdown, title)
	_G[dropdownName.."Text"]:SetFontObject("GameFontWhiteTiny2")
	_G[dropdownName.."Text"]:SetWidth(width-15)
	-- local fontName,fontHeight,fontFlags = _G[dropdownName.."Text"]:GetFont()
	-- _G[dropdownName.."Text"]:SetFont(fontName, 10)

	--newDropdown:GetParent():SetWidth(newDropdown:GetWidth())
	--newDropdown:GetParent():SetHeight(newDropdown:GetHeight())

	return newDropdown
end

---@param rowToRemove number?
local function removeRow(rowToRemove)
	if numActiveRows <= 1 then
		local theSpellRow = SCForgeMainFrame.spellRows[numActiveRows]
		theSpellRow.mainDelayBox:SetText("")
		for k,v in pairs(theSpellRow.menuList) do
			v.checked = false
		end
		UIDropDownMenu_SetSelectedID(theSpellRow.actionSelectButton, 0)
		theSpellRow.actionSelectButton.Text:SetText("Action")
		updateSpellRowOptions(numActiveRows, nil)

		theSpellRow.SelfCheckbox:SetChecked(false)
		theSpellRow.InputEntryBox:SetText("")
		theSpellRow.RevertDelayBox:SetText("")
		return;
	end

	if rowToRemove and (rowToRemove ~= numActiveRows) then
		for i = rowToRemove, numActiveRows-1 do
			local theRowToSet = SCForgeMainFrame.spellRows[i]
			local theRowToGrab = SCForgeMainFrame.spellRows[i+1]

			for k,v in pairs(theRowToSet.menuList) do
				v.checked = false
			end

			-- theRowToSet.actionSelectButton.Dropdown
			-- theRowToGrab.actionSelectButton.Dropdown
			UIDropDownMenu_SetSelectedID(theRowToSet.actionSelectButton, UIDropDownMenu_GetSelectedID(theRowToGrab.actionSelectButton))
			theRowToSet.actionSelectButton.Text:SetText(theRowToGrab.actionSelectButton.Text:GetText())
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

		for k,v in pairs(theSpellRow.menuList) do
			v.checked = false
		end
		-- theSpellRow.actionSelectButton.Dropdown
		UIDropDownMenu_SetSelectedID(theSpellRow.actionSelectButton, 0)
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

local function getRowActionTypeData(rowNum)
	if SCForgeMainFrame.spellRows[rowNum].SelectedAction and actionTypeData[SCForgeMainFrame.spellRows[rowNum].SelectedAction].dataName then return actionTypeData[SCForgeMainFrame.spellRows[rowNum].SelectedAction] end
end

---@param rowToAdd number?
local function addRow(rowToAdd)
	if numActiveRows >= maxNumberOfRows then SCForgeMainFrame.AddRowRow.AddRowButton:Disable() return; end -- hard cap
	numActiveRows = numActiveRows+1		-- The number of spell rows that this row will be.
	local newRow
	if SCForgeMainFrame.spellRows[numActiveRows] then
		newRow = SCForgeMainFrame.spellRows[numActiveRows]
		newRow:Show();
	else
		-- The main row frame
		newRow = CreateFrame("Frame", nil, SCForgeMainFrame.Inset.scrollFrame.scrollChild)
		newRow.rowNum = numActiveRows
		SCForgeMainFrame.spellRows[newRow.rowNum] = newRow

		if numActiveRows == 1 then
			newRow:SetPoint("TOPLEFT", 25, 0)
		else
			newRow:SetPoint("TOPLEFT", SCForgeMainFrame.spellRows[numActiveRows-1], "BOTTOMLEFT", 0, 0)
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
			newRow.mainDelayBox.Instructions:SetTextColor(0.5,0.5,0.5)
			newRow.mainDelayBox:SetAutoFocus(false)
			newRow.mainDelayBox:SetSize(delayColumnWidth,23)
			newRow.mainDelayBox:SetPoint("LEFT", 40, 0)
			newRow.mainDelayBox:SetMaxLetters(10)
			newRow.mainDelayBox:HookScript("OnTextChanged", function(self, userInput)
				if self:GetText() == self:GetText():match("%d+") or self:GetText() == self:GetText():match("%d+%.%d+") or self:GetText() == self:GetText():match("%.%d+") then
					self:SetTextColor(255,255,255,1)
				elseif self:GetText() == "" then
					self:SetTextColor(255,255,255,1)
				elseif self:GetText():find("%a") then
					self:SetText(self:GetText():gsub("%a", ""))
				else
					self:SetTextColor(1,0,0,1)
				end
				if userInput then Attic.markEditorUnsaved() end
			end)
			Tooltip.set(newRow.mainDelayBox, "Main Action Delay", "How long after 'casting' the ArcSpell this action triggers.\rCan be '0' for instant.")

		-- Action Dropdown Menu
		newRow.menuList = {} -- tree structure
		newRow.flatMenuList = {} -- flat structure for bulk operations
		local menuList = newRow.menuList

		initActionDropdownItems(actionTypeDataList, newRow.flatMenuList, menuList)

		--newRow.actionSelectButton = CreateFrame("Frame", nil, newRow)
		--newRow.actionSelectButton:SetPoint("LEFT", newRow.mainDelayBox, "RIGHT", 0, -2)
		newRow.actionSelectButton = genStaticDropdownChild( newRow, "SCForgeMainFrameSpellRow"..numActiveRows.."ActionSelectButton", menuList, "Action", actionColumnWidth)
		newRow.actionSelectButton:SetPoint("LEFT", newRow.mainDelayBox, "RIGHT", 0, -2)

		-- Self Checkbox
		newRow.SelfCheckbox = CreateFrame("CHECKBUTTON", nil, newRow, "UICheckButtonTemplate")
			newRow.SelfCheckbox:SetPoint("LEFT", newRow.actionSelectButton, "RIGHT", -5, 1)
			newRow.SelfCheckbox:Disable()
			newRow.SelfCheckbox:SetMotionScriptsWhileDisabled(true)
			Tooltip.set(newRow.SelfCheckbox, "Cast on Self", "Enable to use the 'Self' flag for Cast & Aura actions.")

		-- ID Entry Box (Input)
		if SpellCreatorMasterTable.Options["biggerInputBox"] == true then
			newRow.InputEntryScrollFrame = CreateFrame("ScrollFrame", nil, newRow, "InputScrollFrameTemplate")
			newRow.InputEntryScrollFrame.CharCount:Hide()
			newRow.InputEntryScrollFrame:SetSize(inputEntryColumnWidth,40)
			newRow.InputEntryScrollFrame:SetPoint("LEFT", newRow.SelfCheckbox, "RIGHT", 15, 1)
			newRow.InputEntryBox = newRow.InputEntryScrollFrame.EditBox
			-- SCForgeMainFrame.spellRows[numActiveRows].InputEntryBox = newRow.InputEntryBox
			newRow.InputEntryBox:SetWidth(newRow.InputEntryScrollFrame:GetWidth()-18)
		else
			newRow.InputEntryBox = CreateFrame("EditBox", nil, newRow, "InputBoxInstructionsTemplate")
			newRow.InputEntryBox:SetSize(inputEntryColumnWidth,23)
			newRow.InputEntryBox:SetPoint("LEFT", newRow.SelfCheckbox, "RIGHT", 15, 1)
		end

			newRow.InputEntryBox:SetFontObject(ChatFontNormal)
			newRow.InputEntryBox.disabledColor = GRAY_FONT_COLOR
			newRow.InputEntryBox.enabledColor = HIGHLIGHT_FONT_COLOR
			newRow.InputEntryBox.Instructions:SetText("select an action...")
			newRow.InputEntryBox.Instructions:SetTextColor(0.5,0.5,0.5)
			newRow.InputEntryBox.Description = ""
			newRow.InputEntryBox.rowNumber = numActiveRows
			newRow.InputEntryBox:SetAutoFocus(false)
			newRow.InputEntryBox:Disable()
			newRow.InputEntryBox:HookScript("OnTextChanged", function(self, userInput)
				if userInput then Attic.markEditorUnsaved() end
			end)

			Tooltip.set(newRow.InputEntryBox,
				function(self) -- title
					local _actionTypeData = getRowActionTypeData(self.rowNumber)
					if _actionTypeData then
						return _actionTypeData.dataName
					else
						return nil
					end
				end,
				function(self) -- body
					local _actionTypeData = getRowActionTypeData(self.rowNumber)
					local strings = {}

					if _actionTypeData.inputDescription then
						tinsert(strings, " ")
						tinsert(strings, _actionTypeData.inputDescription)
					end
					if _actionTypeData.example then
						tinsert(strings, " ")
						tinsert(strings, Tooltip.genTooltipText("example", _actionTypeData.example))
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
			newRow.RevertDelayBox.Instructions:SetTextColor(0.5,0.5,0.5)
			newRow.RevertDelayBox:SetAutoFocus(false)
			newRow.RevertDelayBox:Disable()
			newRow.RevertDelayBox:SetSize(revertDelayColumnWidth,23)
			newRow.RevertDelayBox:SetPoint("LEFT", (newRow.InputEntryScrollFrame or newRow.InputEntryBox), "RIGHT", 25, 0)
			newRow.RevertDelayBox:SetMaxLetters(10)

			newRow.RevertDelayBox:HookScript("OnTextChanged", function(self, userInput)
				if self:GetText() == self:GetText():match("%d+") or self:GetText() == self:GetText():match("%d+%.%d+") or self:GetText() == self:GetText():match("%.%d+") then
					self:SetTextColor(255,255,255,1)
				elseif self:GetText() == "" then
					self:SetTextColor(255,255,255,1)
				elseif self:GetText():find("%a") then
					self:SetText(self:GetText():gsub("%a", ""))
				else
					self:SetTextColor(1,0,0,1)
				end
				if userInput then Attic.markEditorUnsaved() end
			end)

			Tooltip.set(newRow.RevertDelayBox,
				"Revert Delay",
				{
					"How long after the initial action before reverting.\n",
					"Note: This is RELATIVE to this lines main action delay\n",
					Tooltip.genTooltipText("example", "Aura action with delay 2, and revert delay 3, means the revert is 3 seconds after the aura action itself, NOT 3 seconds after casting.."),
				}
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
			newRow.AddSpellRowButton:SetSize(24,24)
			--local _atlas = "transmog-icon-remove"
			local _atlas = "communities-chat-icon-plus"

			newRow.AddSpellRowButton:SetNormalAtlas(_atlas)
			newRow.AddSpellRowButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")

			newRow.AddSpellRowButton.DisabledTex = newRow.AddSpellRowButton:CreateTexture(nil, "ARTWORK")
			newRow.AddSpellRowButton.DisabledTex:SetAllPoints(true)
			newRow.AddSpellRowButton.DisabledTex:SetAtlas(_atlas)
			newRow.AddSpellRowButton.DisabledTex:SetDesaturated(true)
			newRow.AddSpellRowButton.DisabledTex:SetVertexColor(.6,.6,.6)
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
			end)
			newRow.AddSpellRowButton:SetScript("OnShow", function(self)
				if SCForgeMainFrame.AddRowRow.AddRowButton:IsEnabled() then self:Enable(); else self:Disable(); end
			end)
			newRow.AddSpellRowButton:Hide()

		newRow.RemoveSpellRowButton = CreateFrame("BUTTON", nil, newRow)
			newRow.RemoveSpellRowButton.rowNum = numActiveRows
			newRow.RemoveSpellRowButton:SetPoint("TOPRIGHT", -11, -1)
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
			UIHelpers.setTextureOffset(newRow.RemoveSpellRowButton.PushedTex, 1, -1)
			newRow.RemoveSpellRowButton:SetPushedTexture(newRow.RemoveSpellRowButton.PushedTex)

			newRow.RemoveSpellRowButton:SetMotionScriptsWhileDisabled(true)
			Tooltip.set(newRow.RemoveSpellRowButton, "Delete this row")

			newRow.RemoveSpellRowButton:SetScript("OnClick", function(self)
				removeRow(self.rowNum)
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

		newRow.mainDelayBox.nextEditBox = newRow.InputEntryBox 			-- Main Delay -> Input
		newRow.mainDelayBox.previousEditBox = newRow.mainDelayBox 	-- Main Delay <- Main Delay (Can't reverse past itself, updated later)
		newRow.InputEntryBox.nextEditBox = newRow.RevertDelayBox		-- Input -> Revert
		newRow.InputEntryBox.previousEditBox = newRow.mainDelayBox		-- Input <- Main Delay
		newRow.RevertDelayBox.nextEditBox = newRow.mainDelayBox			-- Revert -> Main Delay (we change it later if needed)
		newRow.RevertDelayBox.previousEditBox = newRow.InputEntryBox	-- Revert <- Input

	if numActiveRows > 1 then
		local prevRow = SCForgeMainFrame.spellRows[numActiveRows-1]
		newRow.mainDelayBox.previousEditBox = prevRow.RevertDelayBox 	-- Main Delay <- LAST Revert
		newRow.RevertDelayBox.nextEditBox = SCForgeMainFrame.spellRows[1].mainDelayBox			-- Revert -> Spell Row 1 Main Delay
		prevRow.RevertDelayBox.nextEditBox = newRow.mainDelayBox		-- LAST Revert -> THIS Main Delay

		newRow.mainDelayBox:SetText(prevRow.mainDelayBox:GetText())
	end

	MainFrame.updateFrameChildScales(SCForgeMainFrame)
	--if numActiveRows >= maxNumberOfRows then SCForgeMainFrame.AddSpellRowButton:Disable(); return; end -- hard cap
	if numActiveRows >= maxNumberOfRows then SCForgeMainFrame.AddRowRow.AddRowButton:Disable(); return; end -- hard cap

	SCForgeMainFrame.AddRowRow:SetPoint("TOPLEFT", SCForgeMainFrame.spellRows[numActiveRows], "BOTTOMLEFT", 0, 0)

	SCForgeMainFrame.Inset.scrollFrame:UpdateScrollChildRect()

	if rowToAdd then
		for i = numActiveRows, rowToAdd+1, -1 do
			local theRowToSet = SCForgeMainFrame.spellRows[i]
			local theRowToGrab = SCForgeMainFrame.spellRows[i-1]

			for k,v in pairs(theRowToSet.menuList) do
				v.checked = false
			end

			UIDropDownMenu_SetSelectedID(theRowToSet.actionSelectButton, UIDropDownMenu_GetSelectedID(theRowToGrab.actionSelectButton))
			theRowToSet.actionSelectButton.Text:SetText(theRowToGrab.actionSelectButton.Text:GetText())
			theRowToSet.SelectedAction = theRowToGrab.SelectedAction
			updateSpellRowOptions(i, theRowToGrab.SelectedAction)

			theRowToSet.mainDelayBox:SetText(theRowToGrab.mainDelayBox:GetText())
			theRowToSet.SelfCheckbox:SetChecked(theRowToGrab.SelfCheckbox:GetChecked())
			theRowToSet.InputEntryBox:SetText(theRowToGrab.InputEntryBox:GetText())
			theRowToSet.RevertDelayBox:SetText(theRowToGrab.RevertDelayBox:GetText())
		end
		local theRowToSet = SCForgeMainFrame.spellRows[rowToAdd]
		local prevRow = SCForgeMainFrame.spellRows[rowToAdd-1]
		UIDropDownMenu_SetSelectedID(theRowToSet.actionSelectButton, 0)
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
		UIDropDownMenu_SetSelectedID(_spellRow.actionSelectButton, 0)
		_spellRow.actionSelectButton.Text:SetText("Action")
		updateSpellRowOptions(rowNum)
	else
		updateActionDropdownCheckedStates(_spellRow.menuList, actionData.actionType)
		_spellRow.actionSelectButton.Text:SetText(actionTypeData[actionData.actionType].name)
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
    removeRow = removeRow,
	getNumActiveRows = getNumActiveRows,
	setNumActiveRows = setNumActiveRows,
	getRowAction = getRowAction,
	setRowAction = setRowAction,
	genStaticDropdownChild = genStaticDropdownChild,
}
