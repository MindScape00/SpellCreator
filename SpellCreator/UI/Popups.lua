---@class ns
local ns = select(2, ...)

local Comms = ns.Comms
local Tooltip = ns.Utils.Tooltip
local Vault = ns.Vault
local Hotkeys = ns.Actions.Hotkeys
local VAULT_TYPE = ns.Constants.VAULT_TYPE
local dprint = ns.Logging.dprint

local Attic = ns.UI.MainFrame.Attic

StaticPopupDialogs["SCFORGE_RELOADUI_REQUIRED"] = {
	text = "A UI Reload is Required to Change Input Boxes.\n\rReload Now?\r[Warning: All un-saved data will be wiped]",
	showAlert = true,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data, data2)
		ReloadUI();
	end,
	timeout = 0,
	cancels = true,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

---@param newname string
---@param oldname string
---@return string
local function genOverwriteString(newname, oldname)
	if not oldname or (newname == oldname) then
		return "Do you want to overwrite the spell ("..newname..")?"
	else
		return "Do you want to overwrite the spell?\rOld: "..oldname.."\rNew: "..newname
	end
end

StaticPopupDialogs["SCFORGE_CONFIRM_OVERWRITE"] = {
	text = "Spell with CommID %s already exists.\n\r%s",
	OnAccept = function(self, data, data2)
		data.callback(true, (data.fromPhaseVaultID and data.fromPhaseVaultID or nil), (data.manualData and data.manualData or nil))
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
local function showPersonalVaultOverwritePopup(newSpellData, oldSpellData, fromPhaseVaultID, manualData, callback)
	local text1, text2 = Tooltip.genContrastText(newSpellData.commID), genOverwriteString(newSpellData.fullName, oldSpellData.fullName)
	local data = {fromPhaseVaultID = fromPhaseVaultID, manualData = manualData, callback = callback}
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
hotkeyModInsertFrame:SetSize(300,68)
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
hotkeyModInsertFrame.OverrideAlertText:SetPoint("TOPLEFT", hotkeyModInsertFrame.KeyBindText, "BOTTOMLEFT", 0, 0)
hotkeyModInsertFrame.OverrideAlertText:SetPoint("TOPRIGHT", hotkeyModInsertFrame.KeyBindText, "BOTTOMRIGHT", 0, 0)
hotkeyModInsertFrame.OverrideAlertText:SetHeight(22)
local overrideFormatText = "ALERT: %s is currently bound to %s. This will be overwritten."
hotkeyModInsertFrame.OverrideAlertText:SetText(overrideFormatText)

hotkeyModInsertFrame:Hide()

hotkeyModInsertFrame.Update = function(self)

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
	if keyAlreadyBoundTo then
		self.OverrideAlertText:SetText(string.format(overrideFormatText, key, keyAlreadyBoundTo));
		self.OverrideAlertText:Show();
	else
		self.OverrideAlertText:Hide();
	end

end
hotkeyModInsertFrame:SetScript("OnShow", hotkeyModInsertFrame.Update)

hotkeyModInsertFrame:SetScript("OnHide", function(self)
	self.hotkey = nil
end)

local function hotkeyModInsertFrame_OnKeyDown(self, keyOrButton)
	local parent = self:GetParent()
    if keyOrButton == "ESCAPE" then
        StaticPopup_Hide("SCFORGE_LINK_HOTKEY")
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
        keyPressed = "SHIFT-"..keyPressed
    end

    if IsControlKeyDown() then
        keyPressed = "CTRL-"..keyPressed
    end

    if IsAltKeyDown() then
        keyPressed = "ALT-"..keyPressed
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

StaticPopupDialogs["SCFORGE_NEW_PROFILE"] = {
	text = "Assign %s to a new Profile",
	closeButton = true,
	hasEditBox = true,
	enterClicksFirstButton = true,
	editBoxInstructions = "New Profile Name",
	--editBoxWidth = 310,
	maxLetters = 50,
	OnButton1 = function(self, data)
		local text = self.editBox:GetText();
		data.onNewProfileSave(data.comm, text)
	end,
	EditBoxOnTextChanged = function (self)
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
	OnShow = function (self, data)
		self.button1:Disable()
		if data and data.subText then
			self.SubText:SetText(data.subText)
		end
	end,
}

---@param spellCommID CommID
---@param onNewProfileSave fun(commID: CommID, newProfileName: string)
local function showNewProfilePopup(spellCommID, onNewProfileSave)
	local dialog = StaticPopup_Show("SCFORGE_NEW_PROFILE", Tooltip.genContrastText(Vault.personal.findSpellByID(spellCommID).fullName))
	dialog.data = {
		comm = spellCommID,
		onNewProfileSave = onNewProfileSave,
	}
end

StaticPopupDialogs["SCFORGE_ATTIC_PROFILE"] = {
	text = "Set a New Profile:",
	closeButton = true,
	hasEditBox = true,
	enterClicksFirstButton = true,
	editBoxInstructions = "New Profile Name",
	--editBoxWidth = 310,
	maxLetters = 50,
	OnButton1 = function(self, data)
		local text = self.editBox:GetText();
		Attic.selectEditorProfile(text)
	end,
	EditBoxOnTextChanged = function (self)
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
	OnShow = function (self, data)
		self.button1:Disable()
		if data and data.subText then
			self.SubText:SetText(data.subText)
		end
	end,
}

local gossipAddMenuInsert = CreateFrame("FRAME")
gossipAddMenuInsert:SetSize(300,68)
gossipAddMenuInsert:Hide()

gossipAddMenuInsert.vertDivLine = gossipAddMenuInsert:CreateTexture(nil, "ARTWORK")
	gossipAddMenuInsert.vertDivLine:SetPoint("TOP", -30, -4)
	gossipAddMenuInsert.vertDivLine:SetPoint("BOTTOM", -30, 18)
	gossipAddMenuInsert.vertDivLine:SetWidth(2)
	gossipAddMenuInsert.vertDivLine:SetColorTexture(1,1,1,0.2)

gossipAddMenuInsert.horizDivLine = gossipAddMenuInsert:CreateTexture(nil, "ARTWORK")
	gossipAddMenuInsert.horizDivLine:SetPoint("BOTTOMLEFT", 26, 16)
	gossipAddMenuInsert.horizDivLine:SetPoint("BOTTOMRIGHT", -26, 16)
	gossipAddMenuInsert.horizDivLine:SetHeight(2)
	gossipAddMenuInsert.horizDivLine:SetColorTexture(1,1,1,0.2)

gossipAddMenuInsert.hideButton = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
	gossipAddMenuInsert.hideButton:SetSize(26,26)
	gossipAddMenuInsert.hideButton:SetPoint("BOTTOM", -50, -12)
	gossipAddMenuInsert.hideButton.text:SetText("Hide after Casting")
	gossipAddMenuInsert.hideButton:SetHitRectInsets(0,-gossipAddMenuInsert.hideButton.text:GetWidth(),0,0)
	Tooltip.set(gossipAddMenuInsert.hideButton, "Hide the Gossip menu after Casting/Saving", "\n\rFor On Click: The Gossip menu will close after you click, and then the spell will be casted or saved.\n\rFor On Open: The Gossip menu will close immediately after opening, usually before it can be seen, and the spell will be casted or saved." )
	gossipAddMenuInsert.hideButton:SetScript("OnShow", function(self)
		self:SetChecked(false)
		self.text:SetText("Hide after Casting")
	end)

gossipAddMenuInsert.RadioOption = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
	gossipAddMenuInsert.RadioOption.text:SetText("..On Click (Option)")
	gossipAddMenuInsert.RadioOption:SetSize(26,26)
	gossipAddMenuInsert.RadioOption:SetChecked(true)
	gossipAddMenuInsert.RadioOption:SetHitRectInsets(0,-gossipAddMenuInsert.RadioOption.text:GetWidth(),0,0)
	gossipAddMenuInsert.RadioOption:SetPoint("TOPLEFT", gossipAddMenuInsert, "TOP", -13, 0)
	gossipAddMenuInsert.RadioOption.CheckedTex = gossipAddMenuInsert.RadioOption:GetCheckedTexture()
	gossipAddMenuInsert.RadioOption.CheckedTex:SetAtlas("common-checkbox-partial")
	gossipAddMenuInsert.RadioOption.CheckedTex:ClearAllPoints()
	gossipAddMenuInsert.RadioOption.CheckedTex:SetPoint("CENTER", -1, 0)
	gossipAddMenuInsert.RadioOption.CheckedTex:SetSize(12,12)
	Tooltip.set(gossipAddMenuInsert.RadioOption, "..OnClick", "\nAdds the ArcSpell & Tag to a Gossip Option. When that option is clicked, the spell will be cast.\n\rRequires Gossip Text, otherwise it's un-clickable.")
	gossipAddMenuInsert.RadioOption:SetScript("OnShow", function(self)
		self:SetChecked(true)
	end)

gossipAddMenuInsert.RadioBody = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
	gossipAddMenuInsert.RadioBody.text:SetText("..On Open (Auto/Text)")
	gossipAddMenuInsert.RadioBody:SetSize(26,26)
	gossipAddMenuInsert.RadioBody:SetChecked(false)
	gossipAddMenuInsert.RadioBody:SetHitRectInsets(0,-gossipAddMenuInsert.RadioBody.text:GetWidth(),0,0)
	gossipAddMenuInsert.RadioBody:SetPoint("TOPLEFT", gossipAddMenuInsert.RadioOption, "BOTTOMLEFT", 0, 4)
	gossipAddMenuInsert.RadioBody.CheckedTex = gossipAddMenuInsert.RadioBody:GetCheckedTexture()
	gossipAddMenuInsert.RadioBody.CheckedTex:SetAtlas("common-checkbox-partial")
	gossipAddMenuInsert.RadioBody.CheckedTex:ClearAllPoints()
	gossipAddMenuInsert.RadioBody.CheckedTex:SetPoint("CENTER", -1, 0)
	gossipAddMenuInsert.RadioBody.CheckedTex:SetSize(12,12)
	Tooltip.set(gossipAddMenuInsert.RadioBody, "..On Open (Auto)", "\nAdds the ArcSpell & Tag to the Gossip main menu, casting them atuotmaically from the Phase Vault when it is shown.\n\rDoes not require Gossip Text, you can add a tag without any additional text.")
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
	gossipAddMenuInsert.RadioCast:SetSize(26,26)
	gossipAddMenuInsert.RadioCast:SetChecked(true)
	gossipAddMenuInsert.RadioCast:SetHitRectInsets(0,-gossipAddMenuInsert.RadioCast.text:GetWidth(),0,0)
	gossipAddMenuInsert.RadioCast:SetPoint("TOPLEFT", 26, 0)
	gossipAddMenuInsert.RadioCast.CheckedTex = gossipAddMenuInsert.RadioCast:GetCheckedTexture()
	gossipAddMenuInsert.RadioCast.CheckedTex:SetAtlas("common-checkbox-partial")
	gossipAddMenuInsert.RadioCast.CheckedTex:ClearAllPoints()
	gossipAddMenuInsert.RadioCast.CheckedTex:SetPoint("CENTER", -1, 0)
	gossipAddMenuInsert.RadioCast.CheckedTex:SetSize(12,12)
	Tooltip.set(gossipAddMenuInsert.RadioCast, "Cast Spell", "\nCasts the ArcSpell from the Phase Vault.")
	gossipAddMenuInsert.RadioCast:SetScript("OnShow", function(self)
		self:SetChecked(true)
	end)

gossipAddMenuInsert.RadioSave = CreateFrame("CHECKBUTTON", nil, gossipAddMenuInsert, "UICheckButtonTemplate")
	gossipAddMenuInsert.RadioSave.text:SetText("Save Spell")
	gossipAddMenuInsert.RadioSave:SetSize(26,26)
	gossipAddMenuInsert.RadioSave:SetChecked(false)
	gossipAddMenuInsert.RadioSave:SetHitRectInsets(0,-gossipAddMenuInsert.RadioSave.text:GetWidth(),0,0)
	gossipAddMenuInsert.RadioSave:SetPoint("TOPLEFT", gossipAddMenuInsert.RadioCast, "BOTTOMLEFT", 0, 4)
	gossipAddMenuInsert.RadioSave.CheckedTex = gossipAddMenuInsert.RadioSave:GetCheckedTexture()
	gossipAddMenuInsert.RadioSave.CheckedTex:SetAtlas("common-checkbox-partial")
	gossipAddMenuInsert.RadioSave.CheckedTex:ClearAllPoints()
	gossipAddMenuInsert.RadioSave.CheckedTex:SetPoint("CENTER", -1, 0)
	gossipAddMenuInsert.RadioSave.CheckedTex:SetSize(12,12)
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
	maxLetters = 255-25-20-25, -- 255 minus 25 for the max <arcanum> tag size, minus '.ph fo np go op ad ' size, minus spellCommID size.
	EditBoxOnTextChanged = function (self, data)
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
		if self.insertedFrame.RadioCast:GetChecked() then tag = tag.."cast"; elseif self.insertedFrame.RadioSave:GetChecked() then tag = tag.."save"; end
		if self.insertedFrame.hideButton:GetChecked() then tag = tag.."_hide" end
		tag = tag..":"
		local command
		if self.insertedFrame.RadioOption:GetChecked() then command = "ph fo np go op ad "; elseif self.insertedFrame.RadioBody:GetChecked() then command = "ph fo np go te ad "; end

		local finalCommand = command..text.." "..tag..data.commID..">"
		ns.Cmd.cmd(finalCommand)

		--if self.insertedFrame.hideButton:GetChecked() then cmd("ph fo np go op ad "..text.."<arcanum_cast_hide:"..savedSpellFromVault[data].commID..">") else cmd("ph fo np go op ad "..text.."<arcanum_cast:"..savedSpellFromVault[data].commID..">") end
		--savedSpellFromVault[data].commID
	end,
	button1 = ADD,
	button2 = CANCEL,
	hideOnEscape = true,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end,
	whileDead = true,
	OnShow = function (self, data)
		self.button1:Disable()
		self.SubText:SetText(string.format(self.SubText:GetText(), Tooltip.genContrastText(data.fullName), Tooltip.genContrastText(data.commID)))
		self.editBox:SetMaxLetters(255-25-20-#data.commID) -- 255 minus 25 for the max <arcanum> tag size, minus '.ph fo np go op ad ' size, minus spellCommID size.
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
	button1 = "Delete",
	button2 = "Cancel",
	OnAccept = function(self, data, data2)
		if data2 == VAULT_TYPE.PERSONAL then
			Vault.personal.deleteSpell(data)
			ns.MainFuncs.updateSpellLoadRows()
			Hotkeys.deregisterHotkeyByComm(data)
		elseif data2 == VAULT_TYPE.PHASE then
			dprint("Deleting '"..data.."' from Phase Vault.")
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
	dialog.data2 = {...}
end

local function checkAndShowResetForgeConfirmation(text, callback, ...)
	if Attic.getEditorSavedState() then return false end
	showResetForgeConfirmation(text, callback, ...)
	return true
end

StaticPopupDialogs["SCFORGE_ASSIGN_AUTHOR"] = {
	text = "Assign Author to spell "..Tooltip.genContrastText("%s"),
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
	EditBoxOnTextChanged = function (self)
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
	OnShow = function (self, data)
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
	local data = {commID = spellCommID, author = author}
	StaticPopup_Show("SCFORGE_ASSIGN_AUTHOR", spellCommID, nil, data)
end

---@class UI_Popups
ns.UI.Popups = {
	showPersonalVaultOverwritePopup = showPersonalVaultOverwritePopup,
	showCommOverwritePopup = showCommOverwritePopup,
	showPhaseVaultOverwritePopup = showPhaseVaultOverwritePopup,
	showLinkHotkeyDialog = showLinkHotkeyDialog,
	showNewProfilePopup = showNewProfilePopup,
	showAddGossipPopup = showAddGossipPopup,
	checkAndShowResetForgeConfirmation = checkAndShowResetForgeConfirmation,
	showAssignPersonalSpellAuthorPopup = showAssignPersonalSpellAuthorPopup,
}
