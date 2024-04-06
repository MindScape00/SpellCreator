local addonName = ...
---@class ns
local ns = select(2, ...)

local DataUtils = ns.Utils.Data
local AceGUI = ns.Libs.AceGUI
local AceConfig = ns.Libs.AceConfig
local AceConfigDialog = ns.Libs.AceConfigDialog
local AceConfigRegistry = ns.Libs.AceConfigRegistry
local Quickcast = ns.UI.Quickcast
local Tooltip = ns.Utils.Tooltip
local Popups = ns.UI.Popups
local Dropdown = ns.UI.Dropdown

local Actions = ns.Actions
local Constants = ns.Constants
local Permissions = ns.Permissions

local ConditionsData = Actions.ConditionsData

local ADDON_COLORS = ns.Constants.ADDON_COLORS
local ASSETS_PATH = Constants.ASSETS_PATH

local round = DataUtils.roundToNthDecimal
local orderedPairs = DataUtils.orderedPairs

local isNotDefined = ns.Utils.Data.isNotDefined

local function noop(...) return ... end

---@class ConditionEditorFrame: AceGUIFrame
---@field children AceGUIWidget[]
---@field frame Frame

---@class ConditionGroup: AceGUIInlineGroup
---@field children AceGUIWidget[]
---@field frame Frame
---@field parent ConditionEditorFrame

---@class ConditionRow: AceGUISimpleGroup
---@field children (AceGUIWidget|AceGUIButton)[]
---@field frame Frame
---@field parent ConditionGroup

---@class ConditionData
---@field Type string condition type key
---@field IsNot? boolean|nil
---@field Input? string

---@alias ConditionDataGroup ConditionData[]
---@alias ConditionDataTable ConditionDataGroup[]

---Override AceGUI classes to add frame fields that for sure exist but AceGUI Docs don't include
---@class AceGUIButton
---@field frame Frame

--#region
-- Status Display Controllers

local conMetDisplayIcon_Failed = CreateAtlasMarkup("MonsterEnemy", 24, 24)
local conMetDisplayIcon_Success = CreateAtlasMarkup("MonsterFriend", 24, 24)
local conMetDisplayIcon_Unknown = CreateAtlasMarkup("MonsterNeutral", 24, 24)
local conMetDisplayIcon_Error = CreateAtlasMarkup("Islands-QuestBang", 24, 24, 0, 0, 255, 0, 0)
local conMetDisplayIcon_Disabled = CreateAtlasMarkup("PlayerControlled", 24, 24)

---@enum (key) condStatusName
local condStatusName = {
	["na"] = 0,
	["ok"] = 1,
	["fail"] = 2,
	["error"] = 3,
	["disabled"] = 4,
}
local condStatusID = {
	[0] = { isMet = nil, icon = conMetDisplayIcon_Unknown, text = "Unknown (No Condition?)" },
	[1] = { isMet = true, icon = conMetDisplayIcon_Success, text = "Success - Condition Met!" },
	[2] = { isMet = false, icon = conMetDisplayIcon_Failed, text = "Failed - Condition not met." },
	[3] = { isMet = nil, icon = conMetDisplayIcon_Error, text = "Error - Invalid Condition Data" },
	[4] = { isMet = nil, icon = conMetDisplayIcon_Disabled, text = "Disabled - Not Checking Condition" }
}

---@param display AceGUIInteractiveLabel
---@param status condStatusName|number
---@param text? string
local function setMetIconStatus(display, status, text)
	if type(status) == "string" then
		status = condStatusName[status]
	end
	local condStatusData = condStatusID[status]
	display:SetUserData("isMet", status)
	display:SetUserData("conditionErrorText", text)
	display:SetText(condStatusData.icon)
end

local function statusLines(display)
	local lines = {}
	display = display.obj -- convert back to the ace widget
	local status = display:GetUserData("isMet")
	tinsert(lines, status and condStatusID[status].text or condStatusID[0].text)
	local errorText = display:GetUserData("conditionErrorText")
	if errorText then
		tinsert(lines, " ")
		tinsert(lines, "Condition Error:")
		tinsert(lines, errorText)
	end
	tinsert(lines, " ")
	local disabledStatus = display:GetUserData("disabled")
	local refreshLine = (disabledStatus and "Right-Click to Enable" or "Left-Click to Refresh, Right-Click to Disable")
	tinsert(lines, Constants.ADDON_COLORS.TOOLTIP_NOREVERT:WrapTextInColorCode(refreshLine))
	return lines
end

--#endregion

---@type ConditionEditorFrame[]
local editors = {}

local CONDITION_DATA_KEY = Constants.CONDITION_DATA_KEY

---@alias ConditionDataTypes
---| "Type"
---| "IsNot"
---| "Input"

---@param row ConditionRow
---@return ConditionData
local function getConditionDataFromRow(row)
	return row:GetUserData(CONDITION_DATA_KEY)
end

local function setConditionDataOnRow(row, data)
	row:SetUserData(CONDITION_DATA_KEY, data)
end

---@param row ConditionRow
---@param key ConditionDataTypes
---@param value any
local function setDataByName(row, key, value)
	local data = row:GetUserData(CONDITION_DATA_KEY)
	data[key] = value
end

local numDropdownsMade = 0
local dropdownHolder = CreateFrame("Frame")
dropdownHolder:Hide()
local getLastSelectedRow = ns.Actions.ConditionsData.getLastSelectedRow
local setLastSelectedRow = ns.Actions.ConditionsData.setLastSelectedRow
local function createConditionDropdown()
	local conditionDropdown
	numDropdownsMade = numDropdownsMade + 1
	conditionDropdown = Dropdown.create(dropdownHolder, "SCForgeConditionDropdown" .. numDropdownsMade):WithAppearance(140)
	conditionDropdown:SetText("Select a Condition")

	conditionDropdown.Button:SetScript("OnClick", function(self)
		setLastSelectedRow(self:GetParent():GetParent().obj)
		Dropdown.open(ConditionsData.getMenuList(), conditionDropdown)
	end)

	-- Fixes error when opening, clicking outside, then opening again
	conditionDropdown.Button:SetScript("OnMouseDown", nil)


	Tooltip.set(conditionDropdown.Button,
		"Select a Condition Type",
		"Choose what type of condition you'd like to test for.",
		{ delay = 0.3 }
	)
	return conditionDropdown
end
local function resetConditionDropdown(_, frame)
	frame:ClearAllPoints()
	frame:Hide()
	frame:SetParent(dropdownHolder)
	frame:SetText("Select a Condition")
end
local conditionDropdownPool = CreateObjectPool(createConditionDropdown, resetConditionDropdown)

----------------------------------------------------------
-- Condition Rows (The actual Condition Dropdown + Input)

---@param group ConditionGroup
---@param row ConditionRow
---@return number?
local function getIndexOfRow(group, row)
	local conditionRows = group:GetUserData("conditionRows") --[[@as ConditionRow[] ]]
	return tIndexOf(conditionRows, row)
end

---@param group ConditionGroup
---@param row ConditionRow|integer Either the new row, or the specific index
local function updateIndexOfRow(group, row)
	local conditionRows = group:GetUserData("conditionRows") --[[@as ConditionRow[] ]]
	local newIndex

	if type(row) == "number" then
		newIndex = row
		row = conditionRows[row] --[[@as ConditionRow]]
	else
		---@cast row ConditionRow
		newIndex = tIndexOf(conditionRows, row)
	end

	if newIndex == 1 then
		row.children[1]:SetText("if.. ")
	else
		row.children[1]:SetText("and..")
	end
end

local function updateRowIndexes(group)
	local conditionRows = group:GetUserData("conditionRows") --[[@as ConditionRow[] ]]
	for i = 1, #conditionRows do
		-- local row = conditionRows[i] -- more efficient since we already know the index
		updateIndexOfRow(group, i)
	end
end

local function removeConditionRow(group, row)
	local conditionRows = group:GetUserData("conditionRows") --[[@as ConditionRow[] ]]
	--local rowToRemove = tremove(conditionRows, row)
	tDeleteItem(conditionRows, row)

	if row then
		row:Release()
		tDeleteItem(group.children, row)
		updateRowIndexes(group)
	end
end

local function updateRowByCondition(row, presetData)
	row:GetUserData("update")(presetData)
end

local function genConditionRow(group, index)
	local row = AceGUI:Create("SimpleGroup") --[[@as ConditionRow]]
	row:SetLayout("Flow")
	row:SetFullWidth(true)
	row:SetHeight(100)

	row:SetUserData(CONDITION_DATA_KEY, {})

	local label = AceGUI:Create("Label") --[[@as AceGUILabel]]
	if index == 1 then label:SetText("if.. ") else label:SetText("and..") end
	label:SetRelativeWidth(0.045)
	row:AddChild(label)

	local notCheckbox = AceGUI:Create("CheckBox") --[[@as AceGUICheckBox]]
	notCheckbox:SetRelativeWidth(0.08)
	notCheckbox:SetLabel("Not")
	row:AddChild(notCheckbox)
	-- callback moved below conditionMetDisplay

	Tooltip.setAceTT(
		notCheckbox,
		"Not",
		("When enabled, the conditional is inverted.\n\r%s"):format(
			"When 'Not' is checked for a 'Has Item' condition, it will check that the player does NOT have that item instead."
		)
	)

	-- Fuck AceGUI, we're just gonna use a group to create the space and use a custom dropdown here..
	local dropdownContainer = AceGUI:Create("SimpleGroup") --[[@as AceGUISimpleGroup]]
	dropdownContainer:SetRelativeWidth(0.255)
	dropdownContainer:SetLayout("Flow")
	dropdownContainer:SetHeight(30)
	row:AddChild(dropdownContainer)

	local dropdown = conditionDropdownPool:Acquire()
	row:SetUserData("dropdown", dropdown)
	dropdown:SetParent(row.frame)
	dropdown:SetPoint("CENTER", dropdownContainer.frame, "CENTER", 0, -2)
	dropdown:Show()

	dropdownContainer:SetCallback("OnRelease", function()
		conditionDropdownPool:Release(dropdown)
	end)

	local editBoxType = "MAW-Editbox"
	if SpellCreatorMasterTable.Options["biggerInputBox"] == true then
		editBoxType = "MultiLineEditBox"
	end

	local input = AceGUI:Create(editBoxType) --[[@as AceGUIMultiLineEditBox|AceGUIEditBox]]
	row:SetUserData("inputBox", input)
	row:AddChild(input)
	input:SetLabel("Input")
	input:SetRelativeWidth(0.5)
	if input.DisableButton then input:DisableButton(true) end
	input:SetCallback("OnTextChanged", function(_, _, val)
		setDataByName(row, "Input", val and val or nil)
	end)
	input:SetDisabled(true)
	-- OnFocusLost handlers moved down below conditionMetDisplay

	local conditionMetDisplay = AceGUI:Create("InteractiveLabel") --[[@as AceGUIInteractiveLabel]]
	row:AddChild(conditionMetDisplay)
	conditionMetDisplay:SetRelativeWidth(0.04)
	--conditionMetDisplay:SetHeight(26)
	conditionMetDisplay:SetText(conMetDisplayIcon_Unknown)
	conditionMetDisplay:SetJustifyH("CENTER")
	conditionMetDisplay:SetUserData("isMet", 0)
	local function updateMetIcon(conditionInfo, resetDisabled)
		local isDisplayDisabled = conditionMetDisplay:GetUserData("disabled")
		if not conditionInfo then conditionInfo = getConditionDataFromRow(row) end
		if not conditionInfo then return end
		if not conditionInfo.Type then
			if isDisplayDisabled then
				setMetIconStatus(conditionMetDisplay, "disabled")
				return
			else
				setMetIconStatus(conditionMetDisplay, "na")
				return
			end
		end

		local conditionData = ConditionsData.getByKey(conditionInfo.Type)
		local conditionInput = conditionInfo.Input
		if not conditionInput then conditionInput = "" end

		-- This disabled section should really be simplified back down to just true & false since resetDisabled is given every type change and that's the only time we care to auto-flip
		if resetDisabled then
			isDisplayDisabled = nil
			conditionMetDisplay:SetUserData("disabled", nil)
		end
		if conditionData.doNotTestEval and isDisplayDisabled == nil then -- Type changed, and this type has a do not test flag
			conditionMetDisplay:SetUserData("disabled", true)      -- Force Disabled by default
			setMetIconStatus(conditionMetDisplay, "disabled")
			return
		end

		if isDisplayDisabled then
			setMetIconStatus(conditionMetDisplay, "disabled")
			return
		end

		local func = conditionData.script
		local retOK, retConditionSuccess = pcall(func, unpack(ns.Utils.Data.parseStringToArgs(conditionInput)))
		if not retOK then
			local errorText = strmatch(retConditionSuccess, ".*:%d+:(.*)")
			setMetIconStatus(conditionMetDisplay, "error", errorText)
			return
		end
		if conditionInfo.IsNot then retConditionSuccess = not (retConditionSuccess) end
		if retConditionSuccess then
			setMetIconStatus(conditionMetDisplay, "ok")
		else
			setMetIconStatus(conditionMetDisplay, "fail")
		end
	end
	Tooltip.setAceTT(conditionMetDisplay, "Condition Status:", statusLines, { delay = 0, forced = true })
	conditionMetDisplay:SetCallback("OnClick", function(self, cb, button)
		if button == "RightButton" then
			local newStatus = not conditionMetDisplay:GetUserData("disabled")
			conditionMetDisplay:SetUserData("disabled", newStatus)
		end
		updateMetIcon()
		Tooltip.rawSetTooltip(conditionMetDisplay.frame, "Condition Status:", statusLines)
	end)

	-- No Checkbox Callback (After ConditionMetDisplay so it can use it)
	notCheckbox:SetCallback("OnValueChanged", function(_, _, val)
		setDataByName(row, "IsNot", val and val or nil)
		updateMetIcon()
	end)

	-- Input Lost Focused Hooks to update condition met display
	local function input_LostFocused()
		updateMetIcon()
	end

	input:SetCallback("OnEditFocusLost", input_LostFocused) -- Works on MultiLineEditBox
	input:SetCallback("OnEnterPressed", input_LostFocused) -- Uses MAW-Editbox OnFocusLost redirected from OnEnterPressed instead for normal..

	local function update(presetData)
		if presetData then setConditionDataOnRow(row, presetData) end
		local conditionInfo = getConditionDataFromRow(row)
		if not conditionInfo then return end
		if not conditionInfo.Type then return end

		local conditionData = ConditionsData.getByKey(conditionInfo.Type)
		if not conditionData then return end

		dropdown:SetText(conditionData.name)

		input:SetDisabled((not (conditionData.inputs)))
		if conditionInfo.Input then input:SetText(conditionInfo.Input) end

		if conditionData.inputs then
			local ttTitle = conditionData.name
			Tooltip.setAceTT(input, ttTitle, ns.Utils.InputHelper.genTooltip(conditionData.inputs, conditionData.inputDesc, conditionData.inputExample), { delay = 0, forced = true })
		else
			input:SetCallback("OnEnter", noop)
			input:SetCallback("OnLeave", noop)
		end

		notCheckbox:SetValue(conditionInfo.IsNot)

		updateMetIcon(conditionInfo, true)
	end
	row:SetUserData("update", update)

	local endButtonWidths = 0.07

	--[=[ -- Turns out these are pointless so y'know
	local moveUpButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
	frame:AddChild(moveUpButton)
	moveUpButton:SetText(CreateTextureMarkup("Interface/Azerite/Azerite", 62 * 4, 44 * 4, 1.4, 0, 0.51953125, 0.76171875, 0.416015625, 0.373046875))
	moveUpButton:SetRelativeWidth(endButtonWidths)

	local moveDownButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
	frame:AddChild(moveDownButton)
	moveDownButton:SetText(CreateAtlasMarkup("Azerite-PointingArrow"))
	moveDownButton:SetRelativeWidth(endButtonWidths)
	--]=]

	local removeRowButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
	row:AddChild(removeRowButton)
	removeRowButton:SetText(CreateAtlasMarkup("Map-MarkedDefeated"))
	removeRowButton:SetRelativeWidth(endButtonWidths)
	removeRowButton:SetCallback("OnClick", function()
		removeConditionRow(group, row)
		group.parent:DoLayout()
	end)
	Tooltip.setAceTT(removeRowButton, "Remove this Condition Row")

	return row
end

---@param group ConditionGroup
---@return ConditionRow newRow
local function addConditionRow(group)
	local conditionRows = group:GetUserData("conditionRows") --[[@as ConditionRow[] ]]
	local rowID = #conditionRows + 1

	local newRow = genConditionRow(group, rowID)
	tinsert(conditionRows, newRow)

	group:AddChild(newRow)

	return newRow
end

----------------------------------------------------------
-- Condition Groups (Collections of Condition Rows that are 'And' conditions ) - Separate Groups are then 'Or' conditions

local function getIndexOfGroup(editor, group)
	local conditionalGroups = editor:GetUserData("conditionalGroups") --[[@as ConditionGroup[] ]]
	return tIndexOf(conditionalGroups, group)
end

---@param editor ConditionEditorFrame
---@param group ConditionGroup|integer Either the new row, or the specific index
local function updateIndexOfGroup(editor, group)
	local conditionalGroups = editor:GetUserData("conditionalGroups") --[[@as ConditionGroup[] ]]
	local newIndex

	if type(group) == "number" then
		newIndex = group
		group = conditionalGroups[group] --[[@as ConditionGroup]]
	else
		---@cast group ConditionGroup
		newIndex = tIndexOf(conditionalGroups, group)
	end

	if group.SetTitle then
		if newIndex == 1 then
			group:SetTitle("If...")
		else
			group:SetTitle("Or...")
		end
	end
end

local function updateGroupIndexes(editor)
	local conditionalGroups = editor:GetUserData("conditionalGroups") --[[@as ConditionGroup[] ]]
	for i = 1, #conditionalGroups do
		-- local group = conditionalGroups[i] -- more efficient to use index since we already know it
		updateIndexOfGroup(editor, i)
	end
end

---@param editor AceGUIContainer
---@param group ConditionGroup
local function removeGroup(editor, group)
	local conditionalGroups = editor:GetUserData("conditionalGroups") --[[@as AceGUIInlineGroup[] ]]
	tDeleteItem(conditionalGroups, group)

	if group then
		tDeleteItem(group.parent.children, group)
		group:Release()
		updateGroupIndexes(editor)
		editor:DoLayout()
	end
end

---@param parent AceGUIScrollFrame The Editor's Scroll Frame..
---@param beforeGroup any always the addGroupButton for that editor..
---@param index any The index, only used to determine if it's named 'If' or 'Or'..
---@return ConditionGroup
local function genConditionGroup(parent, beforeGroup, index)
	local frame = AceGUI:Create("InlineGroup") --[[@as ConditionGroup]]
	frame:SetLayout("OptionalFlow")
	frame:SetFullWidth(true)
	frame:SetAutoAdjustHeight(true)

	local addConditionButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
	frame:AddChild(addConditionButton)
	addConditionButton:SetHeight(24)
	addConditionButton:SetAutoWidth(true)
	addConditionButton:SetText("Add Condition")
	addConditionButton:ClearAllPoints()
	addConditionButton:SetPoint("RIGHT", frame.frame, "BOTTOMRIGHT", 0, 2)
	addConditionButton:SetUserData("SkipLayout", true)
	addConditionButton:SetCallback("OnClick", function()
		addConditionRow(frame)
		frame.parent:DoLayout()
	end)
	Tooltip.setAceTT(
		addConditionButton,
		"Add Condition to Group",
		("Conditions added to the group work as 'and' conditions; all conditions in a single group must be met to continue.\n\r%s"):format(
			Tooltip.genTooltipText("example", "HasItem 1234 .. AND .. HasAura 5678")
		)
	)

	if index == 1 then frame:SetTitle("If...") else frame:SetTitle("Or...") end

	local removeGroupButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
	frame:AddChild(removeGroupButton)
	removeGroupButton:SetHeight(24)
	removeGroupButton:SetWidth(46)
	removeGroupButton:SetText("X")
	removeGroupButton:ClearAllPoints()
	removeGroupButton:SetPoint("TOPRIGHT", frame.frame, "TOPRIGHT", 0, -12)
	--removeGroupButton.frame:Show()
	removeGroupButton:SetUserData("SkipLayout", true)
	removeGroupButton:SetCallback("OnClick", function(self)
		removeGroup(parent, frame)
		parent:DoLayout()
	end)
	Tooltip.setAceTT(removeGroupButton, "Remove this Condition Group", "All Conditions in this group will be deleted.", { forced = true, delay = 0 })

	---@type AceGUIInlineGroup[]
	local conditionRows = {}
	frame:SetUserData("conditionRows", conditionRows)

	return frame
end

---@param editor AceGUIContainer
---@return ConditionGroup newGroup
local function addGroup(editor)
	local conditionalGroups = editor:GetUserData("conditionalGroups") --[[@as ConditionGroup[] ]]
	local groupID = #conditionalGroups + 1

	local scroll = editor:GetUserData("scroll") --[[@as AceGUIScrollFrame]]

	local beforeGroup = editor:GetUserData("addGroupRegion")
	local newGroup = genConditionGroup(scroll, beforeGroup, groupID)
	tinsert(conditionalGroups, newGroup)

	scroll:AddChild(newGroup, beforeGroup)

	return newGroup
end

-------------
-- Conditions Editor Main

---@param actionRowID integer row index
local function closeEditor(actionRowID)
	local actionRow_ConditionalEditor = editors[actionRowID]

	if actionRow_ConditionalEditor then
		actionRow_ConditionalEditor:Release() -- this should also release any children, no need to release on our own. Children get released whenever parents do, all the way down
	end
end


---@param conditionsContainer frame|table The frame to use, or table, that contains the conditionsData sub-table. Always 'conditionsData' because I hate myself
---@param editorIndex any The row index, or any other unique name for storing this in the editors
---@param spellConditions? ConditionDataTable
local function openConditionsEditor(conditionsContainer, editorIndex, spellConditions)
	local editorIndexID = editorIndex
	if not editorIndexID then editorIndexID = 0 end -- use the base one
	local alreadyOpenEditor = editors[editorIndexID]
	if alreadyOpenEditor then
		alreadyOpenEditor:Show()
		alreadyOpenEditor.frame:Raise()
		AceGUI:SetFocus(alreadyOpenEditor)
		return
	end

	local frame = AceGUI:Create("Window") --[[@as ConditionEditorFrame]]
	if editorIndexID == "spell" then
		frame:SetTitle(("Arcanum - Spell Conditions"))
	elseif editorIndexID == "spark" then
		frame:SetTitle(("Arcanum - Spark Conditions"))
	else
		frame:SetTitle(("Arcanum - Action Conditions (Row %s)"):format(editorIndexID))
	end
	frame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		editors[editorIndexID] = nil
	end)
	frame:EnableResize(false)
	frame:SetLayout("Fill")

	editors[editorIndexID] = frame

	---@type ConditionGroup[]
	local conditionalGroups = {}
	frame:SetUserData("conditionalGroups", conditionalGroups)

	local scroll = AceGUI:Create("ScrollFrame") --[[@as AceGUIScrollFrame]]
	scroll:SetLayout("List")
	frame:AddChild(scroll)
	scroll:SetUserData("conditionalGroups", conditionalGroups)

	local addGroupRegion = AceGUI:Create("SimpleGroup") --[[@as AceGUISimpleGroup]]
	addGroupRegion:SetLayout("List")
	addGroupRegion:SetAutoAdjustHeight(true)
	addGroupRegion:SetFullWidth(true)
	scroll:AddChild(addGroupRegion)

	local addGroupSpacer = AceGUI:Create("Label") --[[@as AceGUILabel]]
	addGroupSpacer:SetText(" ")
	addGroupSpacer:SetFullWidth(true)
	addGroupSpacer:SetHeight(10)
	addGroupRegion:AddChild(addGroupSpacer)

	local _atlas = "communities-chat-icon-plus"
	local plusButtonMarkup = CreateAtlasMarkup(_atlas, 64, 64, 0, 1) -- Offset up to move it into the actual icon area. Hacky? Yes. Works? Also yes :)

	local addGroupButton = AceGUI:Create("Icon") --[[@as AceGUIIcon]]
	addGroupButton:SetImage(ASSETS_PATH .. "/SpellForgeMainPanelRow2", 0.208, 1 - 0.209, 0, 1)
	addGroupButton:SetImageSize(656, 50)
	addGroupButton:SetHeight(40)
	addGroupButton:SetFullWidth(true)
	addGroupButton:SetLabel(plusButtonMarkup)
	addGroupButton.label:ClearAllPoints()
	addGroupButton.label:SetPoint("CENTER", addGroupButton.image)
	addGroupButton.label:SetJustifyV("MIDDLE")

	--addGroupButton.label:SetJustifyV("BOTTOM")
	addGroupButton:SetCallback("OnRelease", function(self)
		self:SetLabel() -- Must clear label otherwise our modifications to the JustifyV do not take place next acquire if it's the same object again
		self.label:ClearAllPoints()
		self.label:SetPoint("BOTTOMLEFT")
		self.label:SetPoint("BOTTOMRIGHT")
		self.label:SetJustifyH("CENTER")
		self.label:SetJustifyV("TOP")
		self.label:SetHeight(18)
	end)
	--]]
	addGroupButton:SetCallback("OnClick", function(self)
		addConditionRow(addGroup(frame))
		scroll:DoLayout() -- Force update the layout to adjust scroll size
	end)

	Tooltip.setAceTT(
		addGroupButton,
		"Add Conditions Group",
		("Adds a new Conditions Group. Groups are treated as separate 'or' condition sets.\n\r%s"):format(
			Tooltip.genTooltipText('example', "If you have two condition groups, and the first group fails, but the second group succeeds, the action will continue run.")
		)
	)

	addGroupRegion:AddChild(addGroupButton)

	local saveButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
	saveButton:SetText("Save Conditions")
	saveButton:SetAutoWidth(true)
	saveButton:SetHeight(24)
	saveButton:ClearAllPoints()
	saveButton:SetPoint("CENTER", frame.frame, "BOTTOM", 0, 5)
	frame:AddChild(saveButton)
	saveButton.frame:Show() -- Manually show because 'fill' type will not handle it, YAY, this actually helps us..
	saveButton:SetCallback("OnClick", function()
		local conditionsTable = {} --[[@as ConditionDataTable]]
		for k, group in ipairs(conditionalGroups) do
			local groupRows = group:GetUserData("conditionRows")
			if #groupRows ~= 0 then -- skip groups with 0 rows.
				local groupTable = {} --[[@as ConditionDataGroup]]
				for i, row in ipairs(groupRows) do
					local conditionData = CopyTable(row:GetUserData(CONDITION_DATA_KEY)) --[[@as ConditionData]]
					tinsert(groupTable, conditionData)
				end
				tinsert(conditionsTable, groupTable)
			end
		end

		if #conditionsTable == 0 then conditionsTable = nil end -- space saver, no blank table, just nil
		conditionsContainer.conditionsData = conditionsTable

		if conditionsContainer.ConditionalButton then
			conditionsContainer.ConditionalButton:update()
		end
		if editorIndexID == "spark" then
			AceConfigRegistry:NotifyChange(Constants.SPARK_CREATE_UI_NAME)
		end

		frame:Release()
	end)

	frame:SetUserData("scroll", scroll)
	frame:SetUserData("addGroupRegion", addGroupRegion)

	if spellConditions and #spellConditions > 0 then
		for _, groupData in ipairs(spellConditions) do
			local newGroup = addGroup(frame)
			for _, rowData in ipairs(groupData) do
				local newRow = addConditionRow(newGroup)
				updateRowByCondition(newRow, rowData)
			end
		end
	else
		addConditionRow(addGroup(frame))
	end

	local numOpenEditors = 0
	for k, v in pairs(editors) do
		numOpenEditors = numOpenEditors + 1
	end

	if numOpenEditors > 1 then
		local p, r, rp, x, y = frame:GetPoint()
		local offSetBy = numOpenEditors - 1
		x = x + (30 * offSetBy)
		y = y - (30 * offSetBy)
		frame:SetPoint(p, r, rp, x, y)
	end

	frame:Show()
	frame.frame:Raise()
	return frame
end

---@param actionRowID integer
---@return AceGUIContainer
local function getEditorForRow(actionRowID)
	return editors[actionRowID]
end

---@class UI_ConditionsEditor
ns.UI.ConditionsEditor = {
	open = openConditionsEditor,
	getRow = getEditorForRow,
	close = closeEditor,
}
