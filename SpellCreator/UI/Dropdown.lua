---@class ns
local ns = select(2, ...)

---@alias DynamicText string | fun(): string
---@alias DynamicBoolean boolean | fun(): boolean

local currentMenu = {}

---@alias DropdownItemType
---| "button"
---| "checkbox"
---| "divider"
---| "header"
---| "input"
---| "radio"
---| "spacer"
---| "selectmenu"
---| "submenu"

---@class DropdownItemCreationOptions
---@field disabled? DynamicBoolean
---@field disabledWarning? string
---@field tooltipTitle? DynamicText
---@field tooltipText? DynamicText
---@field hidden? DynamicBoolean
---@field keepShownOnClick? DynamicBoolean overwrite options that default to not stay shown on click
---@field options? table the rest of the default UIDropDownMenu Info Table options since they are not special-handlers here

---@class DropdownInputCreationOptions: DropdownItemCreationOptions
---@field placeholder string
---@field set fun(self: Frame, text: string): nil
---@field hyperlinkEnabled? boolean

---@class DropdownToggleCreationOptions: DropdownItemCreationOptions
---@field get boolean | fun(self: Frame): boolean
---@field set fun(self: Frame, value: boolean): nil

---@class DropdownItem
---@field menuItem MenuItem
---@field type DropdownItemType
---@field text DynamicText?
---@field tooltipTitle DynamicText?
---@field tooltipText DynamicText?
---@field disabled DynamicBoolean?
---@field disabledWarning? string
---@field keepShownOnClick DynamicBoolean? overwrite options that default to not stay shown on click
---@field hidden DynamicBoolean?
---@field options table

--#region Pools

local function inputPoolResetter(pool, frame)
	frame:ClearFocus()
	frame:SetText("")
	frame:Hide()
end
local inputPool = CreateFramePool("EditBox", UIParent, "InputBoxInstructionsTemplate", inputPoolResetter)
DropDownList1:HookScript("OnHide", function()
	inputPool:ReleaseAll()
end)

--#endregion

---@generic V
---@param value (V | fun(): V)
---@return V
local function evaluate(value)
	if type(value) == "function" then
		return value()
	end

	return value
end

---Primes the DropdownItem's inner MenuItem with dynamic info and returns it.
---@param dropdownItem DropdownItem
---@return MenuItem
local function getMenuItem(dropdownItem)
	local menuItem = dropdownItem.menuItem

	menuItem.text = evaluate(dropdownItem.text) --[[@as string]]
	menuItem.disabled = evaluate(dropdownItem.disabled) --[[@as boolean]]

	if dropdownItem.tooltipTitle or dropdownItem.tooltipText then
		menuItem.tooltipOnButton = true
		menuItem.tooltipTitle = evaluate(dropdownItem.tooltipTitle) --[[@as string]]
		menuItem.tooltipText = evaluate(dropdownItem.tooltipText) --[[@as string]]
	end
	if dropdownItem.keepShownOnClick then
		menuItem.keepShownOnClick = evaluate(dropdownItem.keepShownOnClick) --[[@as boolean]]
	end

	if menuItem.disabled and dropdownItem.disabledWarning then
		menuItem.tooltipWhileDisabled = true
		menuItem.tooltipWarning = dropdownItem.disabledWarning
	end

	if dropdownItem.options then
		for k, v in pairs(dropdownItem.options) do -- copy the options table over, skipping anything we already have populated by the dropdownItem definition
			if not menuItem[k] then
				menuItem[k] = v
			end
		end
	end

	return menuItem
end

---@param level integer
---@param menuList DropdownItem[]
local function initialize(_, level, menuList)
	for index = 1, #menuList do
		local dropdownItem = menuList[index]

		if dropdownItem.type == "divider" then
			UIDropDownMenu_AddSeparator(level)
		elseif dropdownItem.type == "spacer" then
			UIDropDownMenu_AddSpace(level)
		else
			local menuItem = getMenuItem(dropdownItem)
			menuItem.index = index

			if not evaluate(dropdownItem.hidden) then
				UIDropDownMenu_AddButton(menuItem, level);
			end
		end
	end
end

---@param menuList DropdownItem[]
local function initializer(menuList)
	return function(frame, level, subMenu)
		local list = subMenu or menuList
		return initialize(frame, level, list)
	end
end

---Prepare a dropdown to open a menuList. Do not call open() when using this.
---@param menuList DropdownItem[]
---@param frame UIDropDownMenuTemplate
---@param displayMode "MENU" | string | nil
local function init(menuList, frame, displayMode)
	UIDropDownMenu_Initialize(frame, initializer(menuList), displayMode, nil, menuList);
end

---Open a menuList immediately without the need for init().
---@param menuList DropdownItem[]
---@param frame UIDropDownMenuTemplate
---@param anchor "cursor" | Region | nil
---@param x integer?
---@param y integer?
---@param displayMode "MENU" | string | nil
---@param autoHideDelay number?
local function open(menuList, frame, anchor, x, y, displayMode, autoHideDelay)
	if (displayMode == "MENU") then
		frame.displayMode = displayMode;
	end
	UIDropDownMenu_Initialize(frame, initialize, displayMode, nil, menuList);
	ToggleDropDownMenu(1, nil, frame, anchor, x, y, menuList, nil, autoHideDelay);

	currentMenu.menuList = menuList
	currentMenu.frame = frame
	currentMenu.anchor = anchor
	currentMenu.x = x
	currentMenu.y = y
	currentMenu.displayMode = displayMode
	currentMenu.autoHideDelay = autoHideDelay

	if anchor == "cursor" then
		local uiScale, cX, cY = UIParent:GetEffectiveScale(), GetCursorPosition()
		currentMenu.anchor = "UIParent"
		currentMenu.x = cX / uiScale
		currentMenu.y = cY / uiScale
	end
end

local function close()
	currentMenu = {}
	CloseDropDownMenus()
end

local function refresh()
	open(
		currentMenu.menuList,
		currentMenu.frame,
		currentMenu.anchor,
		currentMenu.x,
		currentMenu.y,
		currentMenu.displayMode,
		currentMenu.autoHideDelay
	)
end

---@return boolean
local function isOpen()
	return UIDROPDOWNMENU_OPEN_MENU ~= nil
end

---@param type DropdownItemType
---@param text DynamicText?
---@param options DropdownItemCreationOptions?
---@return DropdownItem
local function item(type, text, options)
	local menuItem = UIDropDownMenu_CreateInfo()

	---@type DropdownItem
	local dropdownItem = {
		type = type,
		text = text,
		menuItem = menuItem,
	}

	if options then
		dropdownItem.disabled = options.disabled
		dropdownItem.disabledWarning = options.disabledWarning
		dropdownItem.tooltipTitle = options.tooltipTitle
		dropdownItem.tooltipText = options.tooltipText
		dropdownItem.hidden = options.hidden
		dropdownItem.keepShownOnClick = options.keepShownOnClick
		dropdownItem.options = options.options -- non-special handled options
	end

	return dropdownItem
end

local checkSubChecksFunc = function(self)
	for _, childItem in ipairs(self.menuList) do
		local checked = childItem.menuItem.checked
		if type(checked) == "function" then
			checked = checked(self)
		end

		if checked then
			return true
		end
	end

	return false
end

---@param text DynamicText
---@param dropdownItems DropdownItem[]
---@param options DropdownItemCreationOptions?
---@return DropdownItem
local function selectmenu(text, dropdownItems, options)
	local dropdownItem = item("selectmenu", text, options)

	dropdownItem.menuItem.hasArrow = true
	dropdownItem.menuItem.keepShownOnClick = true
	dropdownItem.menuItem.value = nil
	dropdownItem.menuItem.menuList = dropdownItems
	dropdownItem.menuItem.checked = checkSubChecksFunc
	dropdownItem.menuItem.func = function(self, arg1, arg2, checked)
		local checkMark = _G[self:GetName() .. "Check"]
		local unCheckMark = _G[self:GetName() .. "UnCheck"]
		if checkSubChecksFunc(self) then
			checkMark:Show()
			unCheckMark:Hide()
		else
			checkMark:Hide()
			unCheckMark:Show()
		end
	end

	return dropdownItem
end


---@param text DynamicText
---@param dropdownItems DropdownItem[]
---@param options DropdownItemCreationOptions?
---@return DropdownItem
local function submenu(text, dropdownItems, options)
	local dropdownItem = item("submenu", text, options)

	dropdownItem.menuItem.hasArrow = true
	dropdownItem.menuItem.keepShownOnClick = true
	dropdownItem.menuItem.notCheckable = true
	dropdownItem.menuItem.value = nil
	dropdownItem.menuItem.menuList = dropdownItems

	return dropdownItem
end

---@param text DynamicText
---@param func fun(self): nil
---@param options DropdownItemCreationOptions?
---@return DropdownItem
local function execute(text, func, options)
	local dropdownItem = item("button", text, options)

	dropdownItem.menuItem.func = function(self)
		func(self)
		if options and evaluate(options.keepShownOnClick) then refresh() else close() end
	end
	dropdownItem.menuItem.notCheckable = true

	return dropdownItem
end

---@param text DynamicText
---@param options DropdownToggleCreationOptions
---@return DropdownItem
local function checkbox(text, options)
	local dropdownItem = item("checkbox", text, options)

	dropdownItem.menuItem.checked = options.get
	dropdownItem.menuItem.isNotRadio = true
	dropdownItem.menuItem.keepShownOnClick = true
	dropdownItem.menuItem.func = function(self, arg1, arg2, checked)
		options.set(self, checked)
		refresh()
	end

	return dropdownItem
end

---@param text DynamicText
---@param options DropdownToggleCreationOptions
---@return DropdownItem
local function radio(text, options)
	local dropdownItem = item("radio", text, options)

	dropdownItem.menuItem.checked = options.get
	dropdownItem.menuItem.func = function(self, arg1, arg2, checked)
		options.set(self, checked)
		close()
	end

	return dropdownItem
end

---@class CustomDropDownEditBox: UIDropDownCustomMenuEntry
local CustomDropDownEditBoxMixin = CreateFromMixins(UIDropDownCustomMenuEntryMixin)

function CustomDropDownEditBoxMixin:OnEnterPressed()
	local text = self:GetText()

	text = strtrim(text)

	if #text > 0 then
		self.set(self, text)
		close()
	end
end

function CustomDropDownEditBoxMixin:OnEscapePressed()
	close()
end

-- -- -- -- -- -- -- -- -- -- -- --
--#region Input Dropdown Registry
-- This system just hooks the HandleGlobalMouseEvent to NOT close the Dropdown menu if it's a chatlink, so we can shift-click items into dropdown inputs
-- -- -- -- -- -- -- -- -- -- -- --

local hookedEditBoxes = {}
---@param editBox EditBox
local function registerInputForChatLinks(editBox)
	tinsert(hookedEditBoxes, editBox)
end

local function unregisterInputForChatLinks(editBox)
	tDeleteItem(hookedEditBoxes, editBox)
end

local _UIDropDownMenu_HandleGlobalMouseEvent = UIDropDownMenu_HandleGlobalMouseEvent
UIDropDownMenu_HandleGlobalMouseEvent = function(button, event)
	if IsModifiedClick("CHATLINK") then
		for k, editBox in ipairs(hookedEditBoxes) do
			if editBox:IsVisible() and editBox:HasFocus() then
				return
			end
		end
	end
	_UIDropDownMenu_HandleGlobalMouseEvent(button, event)
end

-- -- -- -- -- -- -- -- -- -- -- --
--#endregion
-- -- -- -- -- -- -- -- -- -- -- --

---@param text DynamicText
---@param options DropdownInputCreationOptions
---@return DropdownItem
local function input(text, options)
	local dropdownItem = item("input", text, options)

	--local editBox = CreateFrame("EditBox", nil, UIParent, "InputBoxInstructionsTemplate")

	local editBox, isNew = inputPool:Acquire()
	---@cast editBox EditBox|InputBoxInstructionsTemplate

	editBox.Instructions:SetText(options.placeholder)

	if isNew then
		editBox:SetAutoFocus(false)

		-- need to raise the textures to avoid draw conflicts that occasionally happen with the dropdown menu background
		editBox.Left:SetDrawLayer("BORDER")
		editBox.Middle:SetDrawLayer("BORDER")
		editBox.Right:SetDrawLayer("BORDER")

		Mixin(editBox, CustomDropDownEditBoxMixin)
		---@cast editBox +CustomDropDownEditBox
	end


	editBox.set = options.set
	editBox:SetScript("OnEnterPressed", editBox.OnEnterPressed)
	editBox:SetScript("OnEscapePressed", editBox.OnEscapePressed)

	editBox:SetScript("OnShow", function()
		if options.hyperlinkEnabled then
			ns.UI.ChatLink.registerEditBox(editBox)
			registerInputForChatLinks(editBox)
		end
		editBox:SetFocus()
	end)

	editBox:SetScript("OnHide", function(self)
		if self.registeredForHyperlinks then
			ns.UI.ChatLink.unregisterEditBox(editBox)
			unregisterInputForChatLinks(editBox)
		end
		self:ClearFocus()
	end)
	if options.hyperlinkEnabled then
		editBox:SetHyperlinksEnabled()
	end

	function editBox:OnSetOwningButton()
		editBox:SetWidth(130)
		editBox:SetHeight(editBox.owningButton:GetHeight())
		editBox:Raise()
	end

	---@cast editBox -EditBox, -InputBoxInstructionsTemplate
	dropdownItem.menuItem.customFrame = editBox

	return submenu(text, { dropdownItem }, options)
end

---@param name DynamicText
---@return DropdownItem
local function header(name)
	local dropdownItem = item("header", name)

	dropdownItem.menuItem.isTitle = true
	dropdownItem.menuItem.notCheckable = true

	return dropdownItem
end

---@return DropdownItem
local function spacer()
	return item("spacer")
end

---@return DropdownItem
local function divider()
	return item("divider")
end

---@class DropdownTemplate: UIDropDownMenuTemplate
local DropdownMixin = {}

---@param self UIDropDownMenuTemplate
---@param width integer
---@return DropdownTemplate
function DropdownMixin:WithAppearance(width)
	UIDropDownMenu_SetWidth(self, width);
	UIDropDownMenu_SetButtonWidth(self, width + 15)
	UIDropDownMenu_JustifyText(self, "LEFT")

	self.Text:SetFontObject("GameFontWhiteTiny2")
	self.Text:SetWidth(width - 15)

	---@cast self DropdownTemplate
	return self
end

---@param self UIDropDownMenuTemplate
---@return string
function DropdownMixin:GetText()
	return self.Text:GetText() --[[@as string]]
end

---@param self UIDropDownMenuTemplate
---@param text string
function DropdownMixin:SetText(text)
	UIDropDownMenu_SetText(self, text)

	---@cast self DropdownTemplate
	return self
end

---@param parent Frame
---@param name string
---@return DropdownTemplate
local function create(parent, name)
	local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")

	Mixin(dropdown, DropdownMixin)
	---@cast dropdown DropdownTemplate

	return dropdown
end

local genericDropdownHolder = create(UIParent, select(1, ...) .. "GenericDropdownHolder")

---@class UI_Dropdown
ns.UI.Dropdown = {
	create = create,
	init = init,
	open = open,
	close = close,
	isOpen = isOpen,
	refresh = refresh,

	checkbox = checkbox,
	divider = divider,
	execute = execute,
	input = input,
	header = header,
	radio = radio,
	spacer = spacer,
	selectmenu = selectmenu,
	submenu = submenu,
	genericDropdownHolder = genericDropdownHolder,
}
