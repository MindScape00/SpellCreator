---@class ns
local ns = select(2, ...)
local addonName = ...

local Logging = ns.Logging
local Libs = ns.Libs
local Comms = ns.Comms
local Tooltip = ns.Utils.Tooltip
local Vault = ns.Vault
local Hotkeys = ns.Actions.Hotkeys
local VAULT_TYPE = ns.Constants.VAULT_TYPE
local dprint = Logging.dprint
local eprint = Logging.eprint

local Indent = Libs.Indent
local Attic = ns.UI.MainFrame.Attic

-- //  Generic Popups System - this is a copy of Blizzard's GENERIC_CONFIRMATION and GENERIC_INPUT_BOX system added in Dragonflight, modified for BFA/SL compatibility

local function standardNonEmptyTextHandler(self)
	local parent = self:GetParent();
	parent.button1:SetEnabled(strtrim(parent.editBox:GetText()) ~= "");
end

local function standardEditBoxOnEscapePressed(self)
	self:GetParent():Hide();
end

-- Generic Input Box Dialog
StaticPopupDialogs["SCFORGE_GENERIC_INPUT_BOX"] = {
	text = "", -- supplied dynamically.
	button1 = "", -- supplied dynamically.
	button2 = "", -- supplied dynamically.
	hasEditBox = 1,
	OnShow = function(self, data)
		self.text:SetFormattedText(data.text, data.text_arg1, data.text_arg2);
		self.button1:SetText(data.acceptText or DONE);
		self.button2:SetText(data.cancelText or CANCEL);
		self.editBox:SetMaxLetters(data.maxLetters or 24);
		self.editBox:SetCountInvisibleLetters(not not data.countInvisibleLetters);

		if data.inputText then
			self.editBox:SetText(data.inputText)
			self.editBox:HighlightText()
		end

		standardNonEmptyTextHandler(self.editBox)
	end,
	OnAccept = function(self, data)
		if not data then return end
		local text = self.editBox:GetText();
		data.callback(text);
	end,
	OnCancel = function(self, data)
		if not data then return end
		local cancelCallback = data.cancelCallback;
		local text = self.editBox:GetText();
		if type(cancelCallback) == "function" then
			cancelCallback(text);
		end
	end,
	EditBoxOnEnterPressed = function(self, data)
		local parent = self:GetParent();
		if parent.button1:IsEnabled() then
			local text = parent.editBox:GetText();
			data.callback(text);
			parent:Hide();
		end
	end,
	EditBoxOnTextChanged = standardNonEmptyTextHandler,
	EditBoxOnEscapePressed = standardEditBoxOnEscapePressed,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
};

---@class GenericInputCustomData
---@field text string the text for the confirmation
---@field text_arg1? string formatted into text if provided
---@field text_arg2? string formatted into text if provided
---@field callback fun(text: string) the callback when the player accepts
---@field cancelCallback? fun(text: string?) the callback when the player cancels / not called on accept
---@field acceptText? string custom text for the accept button
---@field cancelText? string custom text for the cancel button
---@field maxLetters? integer the maximum text length that can be entered
---@field countInvisibleLetters? boolean used in tandem with maxLetters
---@field inputText? string default text for the input box
---@field editBoxWidth? number override width of input box

local hardOverrides = {
	"editBoxWidth",
}
local function runOverrides(dialogTemplate, customData)
	for i = 1, #hardOverrides do
		local field = hardOverrides[i]
		if customData[field] then
			dialogTemplate[field] = customData[field]
		end
	end
end
local function resetOverrides(dialogTemplate)
	for i = 1, #hardOverrides do
		local field = hardOverrides[i]
		dialogTemplate[field] = nil
	end
end

---@param customData GenericInputCustomData
---@param insertedFrame frame?
local function showCustomGenericInputBox(customData, insertedFrame)
	runOverrides(StaticPopupDialogs["SCFORGE_GENERIC_INPUT_BOX"], customData)
	StaticPopup_Show("SCFORGE_GENERIC_INPUT_BOX", nil, nil, customData, insertedFrame);
	resetOverrides(StaticPopupDialogs["SCFORGE_GENERIC_INPUT_BOX"])
end


-- Generic Multi-Line Input Box Dialog

local function multiLineNonEmptyTextHandler(self)
	local scrollframe = self:GetParent();
	local dialog = scrollframe:GetParent();
	dialog.button1:SetEnabled(strtrim(self:GetText()) ~= "");
end

local function multiLineEditBoxOnEscapePressed(self)
	self:GetParent():GetParent():Hide();
end

StaticPopupDialogs["SCFORGE_GENERIC_MULTILINE_INPUT_BOX"] = {
	text = "",  -- supplied dynamically.
	button1 = "", -- supplied dynamically.
	button2 = "", -- supplied dynamically.
	subText = " ", -- always a blank space to start so it buffers space for the multi-line edit box
	OnShow = function(self, data)
		self.text:SetFormattedText(data.text, data.text_arg1, data.text_arg2);
		if data.subText then self.SubText:SetText(data.subText .. "\n\r") end -- force extra lines at the end to buffer space for the multi-line edit box
		self.button1:SetText(data.acceptText or DONE);
		self.button2:SetText(data.cancelText or CANCEL);
		self.insertedFrame.EditBox:SetMaxLetters(data.maxLetters or 999999);
		self.insertedFrame.EditBox:SetCountInvisibleLetters(not not data.countInvisibleLetters);

		if data.inputText then
			self.insertedFrame.EditBox:SetText(data.inputText)
			self.insertedFrame.EditBox:HighlightText()
		end

		self.insertedFrame.EditBox:SetScript("OnTextChanged", multiLineNonEmptyTextHandler)
		--self.insertedFrame.EditBox:SetScript("OnEscapePressed", multiLineEditBoxOnEscapePressed) -- nah

		multiLineNonEmptyTextHandler(self.insertedFrame.EditBox)
	end,
	OnAccept = function(self, data)
		if not data then return end
		local text = self.insertedFrame.EditBox:GetText();
		data.callback(text);
	end,
	OnCancel = function(self, data)
		if not data then return end
		local cancelCallback = data.cancelCallback;
		local text = self.insertedFrame.EditBox:GetText();
		if type(cancelCallback) == "function" then
			cancelCallback(text);
		end
	end,
	--[[
	EditBoxOnEnterPressed = function(self, data)
		local parent = self:GetParent();
		if parent.button1:IsEnabled() then
			local text = parent.editBox:GetText();
			data.callback(text);
			parent:Hide();
		end
	end,
	EditBoxOnTextChanged = standardNonEmptyTextHandler,
	EditBoxOnEscapePressed = standardEditBoxOnEscapePressed,
	--]]
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	editBoxWidth = 340
};

local multiLineInputBox
local function genMultiLineInputBoxOnDemand(width)
	if not multiLineInputBox then
		multiLineInputBox = CreateFrame("ScrollFrame", nil, nil, "InputScrollFrameTemplate")
		multiLineInputBox:SetSize(330, 180)
	end

	multiLineInputBox:SetWidth(width and tonumber(width) or 180)
	multiLineInputBox.EditBox:SetWidth(multiLineInputBox:GetWidth() - 18)
	multiLineInputBox.maxLetters = 999999

	return multiLineInputBox
end

---@param customData GenericInputCustomData
local function showCustomMultiLineInputBox(customData)
	StaticPopup_Show("SCFORGE_GENERIC_MULTILINE_INPUT_BOX", nil, nil, customData, genMultiLineInputBoxOnDemand(customData.editBoxWidth));
end

-- Script Input Box
StaticPopupDialogs["SCFORGE_SCRIPT_INPUT_BOX"] = {
	text = "Input/Script Editor",
	button1 = DONE,
	button2 = CANCEL,
	subText = " ", -- always a blank space so it buffers space for the multi-line edit box
	OnShow = function(self, data)
		if data.inputText then
			self.insertedFrame.EditBox:SetText(data.inputText)
			self.insertedFrame.EditBox:SetFocus(true)
			--self.insertedFrame.EditBox:HighlightText()
		else
			self.insertedFrame.EditBox:SetText("")
		end
		if data.enableLuaSyntax then
			self.insertedFrame.EditBox:enableLuaSyntax()
		else
			self.insertedFrame.EditBox:disableLuaSyntax()
		end
	end,
	OnAccept = function(self, data)
		if not data then return end
		local text = self.insertedFrame.EditBox:GetText();
		data.returnEditBox:SetText(text, true)
	end,

	hideOnEscape = false,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	editBoxWidth = 510
};

local genScriptInputBox
local function genScriptInputBoxOnDemand()
	if not genScriptInputBox then
		genScriptInputBox = CreateFrame("ScrollFrame", nil, nil, "InputScrollFrameTemplate")
		genScriptInputBox:SetSize(500, 330)
		genScriptInputBox.EditBox:HookScript("OnTextChanged", function(self)
			genScriptInputBox.CharCount:SetText(strlen(self:GetText())) -- override CharCount to show raw character number instead of remaining chars since we don't impose a hard limit
		end)

		genScriptInputBox.toggleLuaParsing = CreateFrame("Button", nil, genScriptInputBox, "UIPanelButtonTemplate")
		genScriptInputBox.toggleLuaParsing:SetPoint("BOTTOMRIGHT", genScriptInputBox, "TOPRIGHT", 5, 5)
		genScriptInputBox.toggleLuaParsing:SetSize(128, 24)
		genScriptInputBox.toggleLuaParsing:SetText("Enable Lua Syntax")
		Tooltip.set(genScriptInputBox.toggleLuaParsing, "Toggle Lua Syntax",
			"Syntax includes Code Highlighting & Auto-Indenting\n\rYou should only use this really on true script inputs.\n\rAll highlighting & indents are stripped when saving to input.")

		genScriptInputBox.EditBox.isLuaEnabled = false
		genScriptInputBox.EditBox.enableLuaSyntax = function(self)
			self.isLuaEnabled = true
			Indent.Enable(self, 4, Indent.defaultColorTable)
			--C_Timer.After(0, function() Indent.indentEditbox(self) end)
			genScriptInputBox.toggleLuaParsing:SetText("Disable Lua Syntax")
		end
		genScriptInputBox.EditBox.disableLuaSyntax = function(self)
			self.isLuaEnabled = false
			Indent.Disable(self)
			genScriptInputBox.toggleLuaParsing:SetText("Enable Lua Syntax")
		end
		genScriptInputBox.EditBox.toggleLuaSyntax = function(self)
			if self.isLuaEnabled then
				self:disableLuaSyntax()
			else
				self:enableLuaSyntax()
			end
		end

		genScriptInputBox.toggleLuaParsing:SetScript("OnClick", function(self)
			genScriptInputBox.EditBox:toggleLuaSyntax()
		end)

		genScriptInputBox.EditBox:SetFont("Fonts\\ARIALN.TTF", 16)
	end

	genScriptInputBox.EditBox:SetWidth(genScriptInputBox:GetWidth() - 18)

	return genScriptInputBox
end

---@param text string
---@param returnEditBox EditBox|editbox|EDITBOX
local function showScriptInputBox(text, returnEditBox, enableLuaSyntax)
	if not returnEditBox then error("Usage: showScriptInputBox(\"text\", returnEditBox)") end
	local customData = {
		inputText = text,
		returnEditBox = returnEditBox,
		enableLuaSyntax = enableLuaSyntax,
	}
	StaticPopup_Show("SCFORGE_SCRIPT_INPUT_BOX", nil, nil, customData, genScriptInputBoxOnDemand());
end

-- Generic Confirmation Dialog
StaticPopupDialogs["SCFORGE_GENERIC_CONFIRMATION"] = {
	text = "", -- supplied dynamically.
	button1 = "", -- supplied dynamically.
	button2 = "", -- supplied dynamically.
	OnShow = function(self, data)
		self.text:SetFormattedText(data.text, data.text_arg1, data.text_arg2);
		self.button1:SetText(data.acceptText or YES);
		self.button2:SetText(data.cancelText or NO);

		self.AlertIcon = _G[self:GetName() .. "AlertIcon"]; -- fix for this not being defined in the frame table before DF
		if data.showAlert then
			self.AlertIcon:SetTexture(STATICPOPUP_TEXTURE_ALERT);
			if (self.button3:IsShown()) then
				self.AlertIcon:SetPoint("LEFT", 24, 10);
			else
				self.AlertIcon:SetPoint("LEFT", 24, 0);
			end
			self.AlertIcon:Show();
		else
			self.AlertIcon:Hide();
		end
	end,
	OnAccept = function(self, data)
		if not data then return end
		if data.callback then
			data.callback();
		end
	end,
	OnCancel = function(self, data)
		if not data then return end
		local cancelCallback = data.cancelCallback;
		if type(cancelCallback) == "function" then
			cancelCallback();
		end
	end,
	OnHyperlinkEnter = function(self, link, text, region, boundsLeft, boundsBottom, boundsWidth, boundsHeight)
		GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
		GameTooltip:ClearAllPoints();
		local cursorClearance = 30;
		GameTooltip:SetPoint("TOPLEFT", region, "BOTTOMLEFT", boundsLeft, boundsBottom - cursorClearance);
		GameTooltip:SetHyperlink(link);
	end,
	OnHyperlinkLeave = function(self)
		GameTooltip:Hide();
	end,
	OnHyperlinkClick = function(self, link, text, button)
		GameTooltip:Hide();
	end,
	hideOnEscape = 1,
	timeout = 0,
	multiple = 1,
	whileDead = 1,
	wide = 1, -- Always wide to accommodate the alert icon if it is present.
};

---@class GenericConfirmationCustomData
---@field text string? the text for the confirmation
---@field text_arg1 string? formatted into text if provided
---@field text_arg2 string? formatted into text if provided
---@field callback fun()? the callback when the player accepts
---@field cancelCallback fun()? the callback when the player cancels / not called on accept
---@field acceptText string? custom text for the accept button
---@field cancelText string|boolean? custom text for the cancel button - provide false to hide the cancel button
---@field showAlert boolean? whether or not the alert texture should show
---@field referenceKey string? used with StaticPopup_IsCustomGenericConfirmationShown / not implemented here

---@param customData GenericConfirmationCustomData
---@param insertedFrame? frame
local function showCustomGenericConfirmation(customData, insertedFrame)
	local shownFrame
	if customData.cancelText == false then
		StaticPopupDialogs["SCFORGE_GENERIC_CONFIRMATION"].button2 = nil
		shownFrame = StaticPopup_Show("SCFORGE_GENERIC_CONFIRMATION", nil, nil, customData, insertedFrame);
		StaticPopupDialogs["SCFORGE_GENERIC_CONFIRMATION"].button2 = ""
	else
		shownFrame = StaticPopup_Show("SCFORGE_GENERIC_CONFIRMATION", nil, nil, customData, insertedFrame);
	end
	return shownFrame
end

---@param text string the text for the confirmation
---@param callback fun()? the callback when the player accepts
---@param insertedFrame frame?
local function showGenericConfirmation(text, callback, insertedFrame)
	local data = { text = text, callback = callback, };
	return showCustomGenericConfirmation(data, insertedFrame);
end

-- //

---@param newname string
---@param oldname string
---@return string
local function genOverwriteString(newname, oldname)
	if not oldname or (newname == oldname) then
		return "Do you want to overwrite the spell (" .. newname .. ")?"
	else
		return "Do you want to overwrite the spell?\rOld: " .. oldname .. "\rNew: " .. newname
	end
end

StaticPopupDialogs["SCFORGE_CONFIRM_OVERWRITE"] = {
	text = "Spell with CommID %s already exists.\n\r%s",
	OnAccept = function(self, data, data2)
		data.callback(true, (data.fromPhaseVaultID and data.fromPhaseVaultID or nil), (data.manualData and data.manualData or nil), (data.vocal and data.vocal or nil),
			(data.callbacksCallback and data.callbacksCallback or nil))
	end,
	button1 = "Overwrite",
	button2 = "Cancel",
	hideOnEscape = true,
	whileDead = true,
}

---@param newSpellData VaultSpell
---@param oldSpellData VaultSpell
---@param fromPhaseVaultID integer
---@param manualData VaultSpell
---@param callback fun()
---@param vocal boolean|string?
---@param callbacksCallback function? callback for the callback - I know, ick..
local function showPersonalVaultOverwritePopup(newSpellData, oldSpellData, fromPhaseVaultID, manualData, callback, vocal, callbacksCallback)
	local text1, text2 = Tooltip.genContrastText(newSpellData.commID), genOverwriteString(newSpellData.fullName, oldSpellData.fullName)
	local data = { fromPhaseVaultID = fromPhaseVaultID, manualData = manualData, callback = callback, vocal = vocal, callbacksCallback = callbacksCallback }
	StaticPopup_Show("SCFORGE_CONFIRM_OVERWRITE", text1, text2, data)
end

StaticPopupDialogs["SCFORGE_CONFIRM_COMMOVERWRITE"] = {
	text = "Spell with CommID %s already exists.\n\r%s",
	OnAccept = function(self, data, data2)
		Comms.saveReceivedSpell(data, data2.charName)
		if data2.callback then data2.callback() end
	end,
	button1 = "Overwrite",
	button2 = "Cancel",
	hideOnEscape = true,
	whileDead = true,
}

---@param spellData VaultSpell
---@param charName string
---@param callback fun()
local function showCommOverwritePopup(spellData, charName, callback)
	local oldSpell = Vault.personal.findSpellByID(spellData.commID)
	if not oldSpell then return end
	local text1, text2 = Tooltip.genContrastText(spellData.commID), genOverwriteString(spellData.fullName, oldSpell.fullName)

	local dialog = StaticPopup_Show("SCFORGE_CONFIRM_COMMOVERWRITE", text1, text2, spellData)
	dialog.data2 = { charName = charName, callback = callback }
end

StaticPopupDialogs["SCFORGE_CONFIRM_POVERWRITE"] = {
	text = "Spell '%s' Already exists in the Phase Vault.\n\rDo you want to overwrite the spell?",
	OnAccept = function(self, commID, callback)
		ns.MainFuncs.saveSpellToPhaseVault(commID, true) -- temp in MainFuncs until SpellStorage is done.
		if callback then callback() end
	end,
	button1 = "Overwrite",
	button2 = CANCEL,
	hideOnEscape = true,
	whileDead = true,
}

---@param commID CommID
---@param callback? fun()
local function showPhaseVaultOverwritePopup(commID, callback)
	local dialog = StaticPopup_Show("SCFORGE_CONFIRM_POVERWRITE", Tooltip.genContrastText(commID), nil, commID)
	dialog.data2 = callback
end

local hotkeyModInsertFrame = CreateFrame("Frame", nil, UIParent)
hotkeyModInsertFrame:SetSize(300, 46)
hotkeyModInsertFrame:SetPoint("CENTER")
hotkeyModInsertFrame.hotkey = nil

hotkeyModInsertFrame.CurrentKeyText = hotkeyModInsertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hotkeyModInsertFrame.CurrentKeyText:SetPoint("TOPLEFT", 0, 0)
hotkeyModInsertFrame.CurrentKeyText:SetPoint("TOPRIGHT", 0, 0)
hotkeyModInsertFrame.CurrentKeyText:SetHeight(22)
local currentKeybindFormatText = "Currently Bound to: %s"
hotkeyModInsertFrame.CurrentKeyText:SetText(string.format(currentKeybindFormatText, "Unbound"))

hotkeyModInsertFrame.KeyBindText = hotkeyModInsertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hotkeyModInsertFrame.KeyBindText:SetPoint("TOPLEFT", hotkeyModInsertFrame.CurrentKeyText, "BOTTOMLEFT", 0, 0)
hotkeyModInsertFrame.KeyBindText:SetPoint("TOPRIGHT", hotkeyModInsertFrame.CurrentKeyText, "BOTTOMRIGHT", 0, 0)
hotkeyModInsertFrame.KeyBindText:SetHeight(22)
hotkeyModInsertFrame.KeyBindText:SetText("Press Any Key...")

hotkeyModInsertFrame.OverrideAlertText = hotkeyModInsertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hotkeyModInsertFrame.OverrideAlertText:SetHeight(33)
hotkeyModInsertFrame.OverrideAlertText:SetPoint("TOPLEFT", hotkeyModInsertFrame.KeyBindText, "BOTTOMLEFT", 0, 0)
hotkeyModInsertFrame.OverrideAlertText:SetPoint("TOPRIGHT", hotkeyModInsertFrame.KeyBindText, "BOTTOMRIGHT", 0, 0)
local overrideFormatText = "ALERT: %s is currently bound to %s. This will be overwritten."
local overrideDefFormatText = "ALERT: %s is currently bound to %s. This will be unusable while the Arc keybind is set."
hotkeyModInsertFrame.OverrideAlertText:SetText(overrideFormatText)

hotkeyModInsertFrame:Hide()

function hotkeyModInsertFrame:UpdateHeight()
	local newHeight = 46
	if self.OverrideAlertText:IsShown() then
		newHeight = newHeight + 33
	end
	self:SetHeight(newHeight)
	local theDialog = self:GetParent()
	theDialog.maxHeightSoFar = 0
	StaticPopup_Resize(theDialog, theDialog.which)
end

function hotkeyModInsertFrame:Update()
	local commID = self:GetParent().data -- pulled from the StaticPopupDialog parent frame, data is defined there..
	local key = self.hotkey

	if key then
		hotkeyModInsertFrame.KeyBindText:SetText(key)
	else
		hotkeyModInsertFrame.KeyBindText:SetText("Press Any Key...")
	end

	local commIDAlreadyBoundTo = Hotkeys.getHotkeyByCommID(commID)
	if commIDAlreadyBoundTo then
		self.CurrentKeyText:SetText(string.format(currentKeybindFormatText, commIDAlreadyBoundTo));
	else
		self.CurrentKeyText:SetText(string.format(currentKeybindFormatText, "Unbound"));
	end

	local keyAlreadyBoundTo = Hotkeys.getHotkeyByKey(key)
	local defaultBindingAction = GetBindingAction(key and key or "", true)
	if defaultBindingAction:find("SCForgeHotkeyButton") then
		defaultBindingAction = nil
	elseif defaultBindingAction:find("SCForgePhaseCastPopupButton.keybind") then
		defaultBindingAction = ns.Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode("Arcanum: Activate Spark")
	elseif defaultBindingAction and defaultBindingAction ~= "" then
		defaultBindingAction = ns.Constants.ADDON_COLORS.TOOLTIP_CONTRAST:WrapTextInColorCode(defaultBindingAction)
	end

	if defaultBindingAction and defaultBindingAction ~= "" then
		self.OverrideAlertText:SetText(string.format(overrideDefFormatText, key, defaultBindingAction));
		self.OverrideAlertText:Show();
	elseif keyAlreadyBoundTo then
		self.OverrideAlertText:SetText(string.format(overrideFormatText, key, keyAlreadyBoundTo));
		self.OverrideAlertText:Show();
	else
		self.OverrideAlertText:Hide();
	end

	self:UpdateHeight()
end

hotkeyModInsertFrame:SetScript("OnShow", hotkeyModInsertFrame.Update)

hotkeyModInsertFrame:SetScript("OnHide", function(self)
	self.hotkey = nil
end)

local function hotkeyModInsertFrame_OnKeyDown(self, keyOrButton)
	local parent = self:GetParent()
	if keyOrButton == "ESCAPE" then
		StaticPopup_Hide("SCFORGE_LINK_HOTKEY")
		self:Hide()
		return
	end

	if GetBindingFromClick(keyOrButton) == "SCREENSHOT" then
		RunBinding("SCREENSHOT");
		return;
	end

	if keyOrButton == "ENTER" then
		if self.hotkey then
			parent.button1:Click();
		else
			Hotkeys.deregisterHotkeyByComm(parent.data)
			StaticPopup_Hide("SCFORGE_LINK_HOTKEY")
		end
		return;
	end

	local keyPressed = keyOrButton;

	if keyPressed == "UNKNOWN" then
		return;
	end

	-- Convert the mouse button names
	if keyPressed == "LeftButton" then
		keyPressed = "BUTTON1";
	elseif keyPressed == "RightButton" then
		keyPressed = "BUTTON2";
	elseif keyPressed == "MiddleButton" then
		keyPressed = "BUTTON3";
	end

	if keyPressed == "LSHIFT" or
		keyPressed == "RSHIFT" or
		keyPressed == "LCTRL" or
		keyPressed == "RCTRL" or
		keyPressed == "LALT" or
		keyPressed == "RALT" then
		return;
	end

	if IsShiftKeyDown() then
		keyPressed = "SHIFT-" .. keyPressed
	end

	if IsControlKeyDown() then
		keyPressed = "CTRL-" .. keyPressed
	end

	if IsAltKeyDown() then
		keyPressed = "ALT-" .. keyPressed
	end

	if keyPressed == "BUTTON1" or keyPressed == "BUTTON2" then
		return;
	end

	if not keyPressed then
		return;
	end

	self.hotkey = keyPressed
	self:Update()
end

hotkeyModInsertFrame:SetScript("OnKeyDown", hotkeyModInsertFrame_OnKeyDown)
--hooksecurefunc(hotkeyModInsertFrame.KeyBindText, "SetText", function(self) self:GetParent():Update() end)

StaticPopupDialogs["SCFORGE_LINK_HOTKEY"] = {
	text = "Press Key to Bind to ArcSpell %s",
	button1 = "Set Binding",
	button2 = CANCEL,
	--button3 = "Unbind spell", -- dynamically added if appropriate when called
	OnAccept = function(self, data, data2)
		Hotkeys.registerHotkey(self.insertedFrame.hotkey, data)
	end,
	OnAlt = function(self, data, data2)
		Hotkeys.deregisterHotkeyByComm(data)
	end,
	timeout = 0,
	cancels = "SCFORGE_LINK_HOTKEY", -- makes it so only one can be shown at a time
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	enterClicksFirstButton = true,
}

---@param commID CommID
local function showLinkHotkeyDialog(commID)
	if Hotkeys.getHotkeyByCommID(commID) then
		StaticPopupDialogs["SCFORGE_LINK_HOTKEY"].button3 = "Unbind spell"
	else
		StaticPopupDialogs["SCFORGE_LINK_HOTKEY"].button3 = nil
	end
	local dialog = StaticPopup_Show("SCFORGE_LINK_HOTKEY", Tooltip.genContrastText(commID), nil, nil, hotkeyModInsertFrame)
	dialog.data = commID
	dialog.insertedFrame:Update()
end

local gossipAddMenuInsert = CreateFrame("FRAME")
gossipAddMenuInsert:SetSize(300, 68)
gossipAddMenuInsert:Hide()

gossipAddMenuInsert.vertDivLine = gossipAddMenuInsert:CreateTexture(nil, "ARTWORK")
gossipAddMenuInsert.vertDivLine:SetPoint("TOP", -30, -4)
gossipAddMenuInsert.vertDivLine:SetPoint("BOTTOM", -30, 18)
gossipAddMenuInsert.vertDivLine:SetWidth(2)
gossipAddMenuInsert.vertDivLine:SetColorTexture(1, 1, 1, 0.2)

gossipAddMenuInsert.horizDivLine = gossipAddMenuInsert:CreateTexture(nil, "ARTWORK")
gossipAddMenuInsert.horizDivLine:SetPoint("BOTTOMLEFT", 26, 16)
gossipAddMenuInsert.horizDivLine:SetPoint("BOTTOMRIGHT", -26, 16)
gossipAddMenuInsert.horizDivLine:SetHeight(2)
gossipAddMenuInsert.horizDivLine:SetColorTexture(1, 1, 1, 0.2)

gossipAddMenuInsert.hideButton = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
gossipAddMenuInsert.hideButton:SetSize(26, 26)
gossipAddMenuInsert.hideButton:SetPoint("BOTTOM", -50, -12)
gossipAddMenuInsert.hideButton.text:SetText("Hide after Casting")
gossipAddMenuInsert.hideButton:SetHitRectInsets(0, -gossipAddMenuInsert.hideButton.text:GetWidth(), 0, 0)
Tooltip.set(gossipAddMenuInsert.hideButton, "Hide the Gossip menu after Casting/Saving",
	"\n\rFor On Click: The Gossip menu will close after you click, and then the spell will be casted or saved.\n\rFor On Open: The Gossip menu will close immediately after opening, usually before it can be seen, and the spell will be casted or saved.")
gossipAddMenuInsert.hideButton:SetScript("OnShow", function(self)
	self:SetChecked(false)
	self.text:SetText("Hide after Casting")
end)

gossipAddMenuInsert.RadioOption = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
gossipAddMenuInsert.RadioOption.text:SetText("..On Click (Option)")
gossipAddMenuInsert.RadioOption:SetSize(26, 26)
gossipAddMenuInsert.RadioOption:SetChecked(true)
gossipAddMenuInsert.RadioOption:SetHitRectInsets(0, -gossipAddMenuInsert.RadioOption.text:GetWidth(), 0, 0)
gossipAddMenuInsert.RadioOption:SetPoint("TOPLEFT", gossipAddMenuInsert, "TOP", -13, 0)
gossipAddMenuInsert.RadioOption.CheckedTex = gossipAddMenuInsert.RadioOption:GetCheckedTexture()
gossipAddMenuInsert.RadioOption.CheckedTex:SetAtlas("common-checkbox-partial")
gossipAddMenuInsert.RadioOption.CheckedTex:ClearAllPoints()
gossipAddMenuInsert.RadioOption.CheckedTex:SetPoint("CENTER", -1, 0)
gossipAddMenuInsert.RadioOption.CheckedTex:SetSize(12, 12)
Tooltip.set(gossipAddMenuInsert.RadioOption, "..OnClick",
	"\nAdds the ArcSpell & Tag to a Gossip Option. When that option is clicked, the spell will be cast.\n\rRequires Gossip Text, otherwise it's un-clickable.")
gossipAddMenuInsert.RadioOption:SetScript("OnShow", function(self)
	self:SetChecked(true)
end)

gossipAddMenuInsert.RadioBody = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
gossipAddMenuInsert.RadioBody.text:SetText("..On Open (Auto/Text)")
gossipAddMenuInsert.RadioBody:SetSize(26, 26)
gossipAddMenuInsert.RadioBody:SetChecked(false)
gossipAddMenuInsert.RadioBody:SetHitRectInsets(0, -gossipAddMenuInsert.RadioBody.text:GetWidth(), 0, 0)
gossipAddMenuInsert.RadioBody:SetPoint("TOPLEFT", gossipAddMenuInsert.RadioOption, "BOTTOMLEFT", 0, 4)
gossipAddMenuInsert.RadioBody.CheckedTex = gossipAddMenuInsert.RadioBody:GetCheckedTexture()
gossipAddMenuInsert.RadioBody.CheckedTex:SetAtlas("common-checkbox-partial")
gossipAddMenuInsert.RadioBody.CheckedTex:ClearAllPoints()
gossipAddMenuInsert.RadioBody.CheckedTex:SetPoint("CENTER", -1, 0)
gossipAddMenuInsert.RadioBody.CheckedTex:SetSize(12, 12)
Tooltip.set(gossipAddMenuInsert.RadioBody, "..On Open (Auto)",
	"\nAdds the ArcSpell & Tag to the Gossip main menu, casting them atuotmaically from the Phase Vault when it is shown.\n\rDoes not require Gossip Text, you can add a tag without any additional text.")
gossipAddMenuInsert.RadioBody:SetScript("OnShow", function(self)
	self:SetChecked(false)
end)

gossipAddMenuInsert.RadioOption:SetScript("OnClick", function(self)
	self:SetChecked(true)
	gossipAddMenuInsert.RadioBody:SetChecked(false)
	local parent = self:GetParent():GetParent()
	if #parent.editBox:GetText() > 0 then
		parent.button1:Enable()
	else
		parent.button1:Disable()
	end
end)
gossipAddMenuInsert.RadioBody:SetScript("OnClick", function(self)
	self:SetChecked(true)
	gossipAddMenuInsert.RadioOption:SetChecked(false)
	self:GetParent():GetParent().button1:Enable()
end)


gossipAddMenuInsert.RadioCast = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
gossipAddMenuInsert.RadioCast.text:SetText("Cast Spell")
gossipAddMenuInsert.RadioCast:SetSize(26, 26)
gossipAddMenuInsert.RadioCast:SetChecked(true)
gossipAddMenuInsert.RadioCast:SetHitRectInsets(0, -gossipAddMenuInsert.RadioCast.text:GetWidth(), 0, 0)
gossipAddMenuInsert.RadioCast:SetPoint("TOPLEFT", 26, 0)
gossipAddMenuInsert.RadioCast.CheckedTex = gossipAddMenuInsert.RadioCast:GetCheckedTexture()
gossipAddMenuInsert.RadioCast.CheckedTex:SetAtlas("common-checkbox-partial")
gossipAddMenuInsert.RadioCast.CheckedTex:ClearAllPoints()
gossipAddMenuInsert.RadioCast.CheckedTex:SetPoint("CENTER", -1, 0)
gossipAddMenuInsert.RadioCast.CheckedTex:SetSize(12, 12)
Tooltip.set(gossipAddMenuInsert.RadioCast, "Cast Spell", "\nCasts the ArcSpell from the Phase Vault.")
gossipAddMenuInsert.RadioCast:SetScript("OnShow", function(self)
	self:SetChecked(true)
end)

gossipAddMenuInsert.RadioSave = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
gossipAddMenuInsert.RadioSave.text:SetText("Save Spell")
gossipAddMenuInsert.RadioSave:SetSize(26, 26)
gossipAddMenuInsert.RadioSave:SetChecked(false)
gossipAddMenuInsert.RadioSave:SetHitRectInsets(0, -gossipAddMenuInsert.RadioSave.text:GetWidth(), 0, 0)
gossipAddMenuInsert.RadioSave:SetPoint("TOPLEFT", gossipAddMenuInsert.RadioCast, "BOTTOMLEFT", 0, 4)
gossipAddMenuInsert.RadioSave.CheckedTex = gossipAddMenuInsert.RadioSave:GetCheckedTexture()
gossipAddMenuInsert.RadioSave.CheckedTex:SetAtlas("common-checkbox-partial")
gossipAddMenuInsert.RadioSave.CheckedTex:ClearAllPoints()
gossipAddMenuInsert.RadioSave.CheckedTex:SetPoint("CENTER", -1, 0)
gossipAddMenuInsert.RadioSave.CheckedTex:SetSize(12, 12)
Tooltip.set(gossipAddMenuInsert.RadioSave, "Save Spell from Phase Vault", "\nSaves the ArcSpell, from the Phase Vault, to the player's Personal Vault.")
gossipAddMenuInsert.RadioSave:SetScript("OnShow", function(self)
	self:SetChecked(false)
end)

gossipAddMenuInsert.RadioCast:SetScript("OnClick", function(self)
	self:SetChecked(true)
	gossipAddMenuInsert.RadioSave:SetChecked(false)
	gossipAddMenuInsert.hideButton.text:SetText("Hide after Casting")
end)
gossipAddMenuInsert.RadioSave:SetScript("OnClick", function(self)
	self:SetChecked(true)
	gossipAddMenuInsert.RadioCast:SetChecked(false)
	gossipAddMenuInsert.hideButton.text:SetText("Hide after Saving")
end)

StaticPopupDialogs["SCFORGE_ADD_GOSSIP"] = {
	text = "Add ArcSpell to NPC Gossip",
	subText = "ArcSpell: %s (%s)",
	closeButton = true,
	hasEditBox = true,
	enterClicksFirstButton = true,
	editBoxInstructions = "Gossip Text (i.e., 'Cast the Spell!')",
	editBoxWidth = 310,
	maxLetters = 255 - 25 - 20 - 25, -- 255 minus 25 for the max <arcanum> tag size, minus '.ph fo np go op ad ' size, minus spellCommID size.
	EditBoxOnTextChanged = function(self, data)
		local text = self:GetText();
		if #text > 0 and text:gsub(" ", "") ~= "" then
			self:GetParent().button1:Enable()
		else
			self:GetParent().button1:Disable()
		end
	end,
	OnButton1 = function(self, data)
		local text = self.editBox:GetText();
		local tag = "<arc_"
		if self.insertedFrame.RadioCast:GetChecked() then tag = tag .. "cast"; elseif self.insertedFrame.RadioSave:GetChecked() then tag = tag .. "save"; end
		if self.insertedFrame.hideButton:GetChecked() then tag = tag .. "_hide" end
		tag = tag .. ":"
		local command
		if self.insertedFrame.RadioOption:GetChecked() then command = "ph fo np go op ad "; elseif self.insertedFrame.RadioBody:GetChecked() then command = "ph fo np go te ad "; end

		local finalCommand = command .. text .. " " .. tag .. data.commID .. ">"
		ns.Cmd.cmd(finalCommand)

		--if self.insertedFrame.hideButton:GetChecked() then cmd("ph fo np go op ad "..text.."<arcanum_cast_hide:"..savedSpellFromVault[data].commID..">") else cmd("ph fo np go op ad "..text.."<arcanum_cast:"..savedSpellFromVault[data].commID..">") end
		--savedSpellFromVault[data].commID
	end,
	button1 = ADD,
	button2 = CANCEL,
	hideOnEscape = true,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end,
	whileDead = true,
	OnShow = function(self, data)
		self.button1:Disable()
		self.SubText:SetText(string.format(self.SubText:GetText(), Tooltip.genContrastText(data.fullName), Tooltip.genContrastText(data.commID)))
		self.editBox:SetMaxLetters(255 - 25 - 20 - #data.commID) -- 255 minus 25 for the max <arcanum> tag size, minus '.ph fo np go op ad ' size, minus spellCommID size.
	end,
}

---@param commID CommID
local function showAddGossipPopup(commID)
	local spellTable = ns.MainFuncs.getSavedSpellFromVaultTable()
	local spell = spellTable[commID]
	StaticPopup_Show("SCFORGE_ADD_GOSSIP", nil, nil, spell, gossipAddMenuInsert)
end

-- Confirm Deletion Popup Dialog
StaticPopupDialogs["SCFORGE_CONFIRM_DELETE"] = {
	text = "Are you sure you want to delete the spell from the %s Vault?\n\r%s\r",
	showAlert = true,
	button1 = DELETE,
	button2 = CANCEL,
	OnAccept = function(self, data, data2)
		if data2 == VAULT_TYPE.PERSONAL then
			Vault.personal.deleteSpell(data)
			ns.MainFuncs.updateSpellLoadRows()
			Hotkeys.deregisterHotkeyByComm(data)
		elseif data2 == VAULT_TYPE.PHASE then
			dprint("Deleting '" .. data .. "' from Phase Vault.")
			ns.MainFuncs.deleteSpellFromPhaseVault(data, ns.MainFuncs.updateSpellLoadRows)
		end
	end,
	timeout = 0,
	cancels = true,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["SCFORGE_RESETFORGE_CONFIRM"] = {
	text = "You have unsaved edits in the forge UI.\n\rAre you sure you want to %s?",
	showAlert = true,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, callback, data2)
		Attic.markEditorSaved()
		callback(unpack(data2))
	end,
	timeout = 0,
	cancels = true,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
local function showResetForgeConfirmation(text, callback, ...)
	local data = callback
	local dialog = StaticPopup_Show("SCFORGE_RESETFORGE_CONFIRM", text, nil, data)
	dialog.data2 = { ... }
end

local function checkAndShowResetForgeConfirmation(text, callback, ...)
	if Attic.getEditorSavedState() then return false end
	showResetForgeConfirmation(text, callback, ...)
	return true
end

StaticPopupDialogs["SCFORGE_ASSIGN_AUTHOR"] = {
	text = "Assign Author to spell " .. Tooltip.genContrastText("%s"),
	closeButton = true,
	hasEditBox = true,
	enterClicksFirstButton = true,
	editBoxInstructions = "Author Name",
	--editBoxWidth = 310,
	maxLetters = 50,
	OnButton1 = function(self, data)
		local text = self.editBox:GetText();
		Vault.personal.assignPersonalSpellAuthor(data.commID, text)
	end,
	EditBoxOnTextChanged = function(self)
		local text = self:GetText();
		if #text > 0 and text:gsub(" ", "") ~= "" then
			self:GetParent().button1:Enable()
		else
			self:GetParent().button1:Disable()
		end
	end,
	button1 = ADD,
	button2 = CANCEL,
	hideOnEscape = true,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		if parent.button1:IsEnabled() then
			parent.button1:Click()
		end
	end,
	whileDead = true,
	OnShow = function(self, data)
		self.button1:Disable()
		if data then
			if data.subText then
				self.SubText:SetText(data.subText)
			end
			if data.author then
				self.editBox:SetText(data.author)
			end
		end
	end,
}
local function showAssignPersonalSpellAuthorPopup(spellCommID, author)
	local data = { commID = spellCommID, author = author }
	StaticPopup_Show("SCFORGE_ASSIGN_AUTHOR", spellCommID, nil, data)
end

-- // Hooking StaticPopup_Show to watch for ADDON_ACTION_FORBIDDEN for SpellCreator, and prompt them to enable Dangerous Scripts.. The popup box fails if it's triggered by SC so rip.., or a notice they tried to use a protected function.
hooksecurefunc("StaticPopup_Show", function(which, text_arg1)
	if which == "ADDON_ACTION_FORBIDDEN" then
		if text_arg1 == addonName then
			if not AreDangerousScriptsAllowed() then
				showCustomGenericConfirmation({
					text =
						"Arcanum was blocked from running user scripts. Please enable Allow Dangerous Scripts if you wish to use this ArcSpell.\n\rAlways be sure to carefully review ArcSpell user scripts before using them.\n\rIf the Dangerous Scripts Warning pop-up does not work, you can manually trigger a working version using\r" ..
						Tooltip.genContrastText("/script SetAllowDangerousScripts(true)"),
					acceptText = OKAY,
					cancelText = false,
				})
				--StaticPopup_Show("DANGEROUS_SCRIPTS_WARNING")
			else
				showCustomGenericConfirmation({
					text =
					"Arcanum was blocked from running a macro script because it used a function that is protected at this time (are you in combat?)\n\rThis isn't an error with the AddOn, but with a Macro Script in the ArcSpell being cast.",
					acceptText = OKAY,
					cancelText = false,
				})
			end
		end
	elseif which == "DANGEROUS_SCRIPTS_WARNING" then
		showCustomGenericConfirmation({
			text =
				"An AddOn or Macro was blocked from running a user-script. Blizzard defines any user script as 'dangerous', and they have the potential to be dangerous! You will need to enable Dangerous Scripts for the action you attempted to work.\n\rIf the Dangerous Scripts Warning pop-up does not work, you can manually trigger a working version using\r" ..
				Tooltip.genContrastText("/script SetAllowDangerousScripts(true)"),
			acceptText = OKAY,
			cancelText = false,
		})
	end
end)

---@class UI_Popups
ns.UI.Popups = {
	showPersonalVaultOverwritePopup = showPersonalVaultOverwritePopup,
	showCommOverwritePopup = showCommOverwritePopup,
	showPhaseVaultOverwritePopup = showPhaseVaultOverwritePopup,
	showLinkHotkeyDialog = showLinkHotkeyDialog,
	showAddGossipPopup = showAddGossipPopup,
	checkAndShowResetForgeConfirmation = checkAndShowResetForgeConfirmation,
	showAssignPersonalSpellAuthorPopup = showAssignPersonalSpellAuthorPopup,
	showCustomGenericInputBox = showCustomGenericInputBox,
	showCustomMultiLineInputBox = showCustomMultiLineInputBox,
	showCustomGenericConfirmation = showCustomGenericConfirmation,
	showGenericConfirmation = showGenericConfirmation,

	showScriptInputBox = showScriptInputBox,
}
