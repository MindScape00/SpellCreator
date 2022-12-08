---@class ns
local ns = select(2, ...)

local pairs = pairs

local eprint = ns.Logging.eprint
local dprint = ns.Logging.dprint

local hotkeysCache = {}

local hotKeyListenerButton = CreateFrame("Button", "SCForgeHotkeyButton")	-- Call this with SCForgeHotkeyButton:Click(commID) to cast that spell - Frame must remain named in the global space for Blizzard's Binding to work..
hotKeyListenerButton:SetScript("OnClick", function(self, button)
	if SpellCreatorSavedSpells[button] then
		ns.Actions.Execute.executeSpell(SpellCreatorSavedSpells[button].actions, nil, SpellCreatorSavedSpells[button].fullName, SpellCreatorSavedSpells[button])
	else
		eprint("No Spell '"..button.."' found in your vault. Seems your binding is an orphan, how sad. Use '/sfdebug clearbinding "..button.."' to clear it.")
	end
end)

local function updateHotkeys(requireVaultRefresh)
	ClearOverrideBindings(hotKeyListenerButton)
	for k,v in pairs(hotkeysCache) do
		dprint(nil, "Binding "..v.." to key: "..k)
		SetOverrideBindingClick(hotKeyListenerButton, false, k, "SCForgeHotkeyButton", v)
	end
	if requireVaultRefresh then
		ns.MainFuncs.updateSpellLoadRows()
	end
end

local function getHotkeyByCommID(commID)
	for k,v in pairs(hotkeysCache) do
		if v == commID then return k end
	end
	return nil
end

local function deregisterHotkeyByKey(key)
	hotkeysCache[key] = nil
	updateHotkeys(true)
end

local function deregisterHotkeyByComm(commID)
	for k,v in pairs(hotkeysCache) do
		if v == commID then hotkeysCache[k] = nil; updateHotkeys(true); dprint("Deregistered hotkey for "..commID) return end
	end
end

local function registerHotkey(key, commID)
	local oldBinding = getHotkeyByCommID(commID)
	if oldBinding ~= nil then
		deregisterHotkeyByComm(commID)
	end

	hotkeysCache[key] = commID
	updateHotkeys(true)
end

local function getHotkeys()
	return hotkeysCache
end

local function getHotkeyByKey(key)
	return hotkeysCache[key]
end

local function deregisterOrphanedCommIDs()
	for k,v in pairs(hotkeysCache) do
		if not SpellCreatorSavedSpells[v] then
			hotkeysCache[k] = nil
		end
	end
	updateHotkeys()
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

	local commID = self:GetParent().data -- pulled from the StaticPopupDialog parent frame
	local key = self.hotkey

	if key then
		hotkeyModInsertFrame.KeyBindText:SetText(key)
	else
		hotkeyModInsertFrame.KeyBindText:SetText("Press Any Key...")
	end

	local commIDAlreadyBoundTo = getHotkeyByCommID(commID)
	if commIDAlreadyBoundTo then self.CurrentKeyText:SetText(string.format(currentKeybindFormatText, commIDAlreadyBoundTo)); else self.CurrentKeyText:SetText(string.format(currentKeybindFormatText, "Unbound")); end

	local keyAlreadyBoundTo = getHotkeyByKey(key)
	if keyAlreadyBoundTo then self.OverrideAlertText:SetText(string.format(overrideFormatText, key, keyAlreadyBoundTo)); self.OverrideAlertText:Show(); else self.OverrideAlertText:Hide(); end

end
hotkeyModInsertFrame:SetScript("OnShow", hotkeyModInsertFrame.Update)

hotkeyModInsertFrame:SetScript("OnHide", function(self)
	self.hotkey = nil
end)

local function hotkeyModInsertFrame_OnKeyDown(self, keyOrButton)
    if keyOrButton == "ESCAPE" then
        StaticPopup_Hide("SCFORGE_LINK_HOTKEY")
        return
    end

    if GetBindingFromClick(keyOrButton) == "SCREENSHOT" then
        RunBinding("SCREENSHOT");
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
	text = "Press Key to Bind to ArcSpell '%s'",
	button1 = "Set Binding",
	button2 = CANCEL,
	button3 = "Unbind",
	OnAccept = function(self, data, data2)
		registerHotkey(self.insertedFrame.hotkey, data)
	end,
	OnAlt = function(self, data, data2)
		deregisterHotkeyByComm(data)
	end,
	timeout = 0,
	cancels = true,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

local function showLinkHotkeyDialog(commID)
	StaticPopup_Hide("SCFORGE_LINK_HOTKEY")
	local dialog = StaticPopup_Show("SCFORGE_LINK_HOTKEY", commID, nil, nil, hotkeyModInsertFrame)
	dialog.data = commID
	dialog.insertedFrame:Update()
	dialog.button3:SetText("Unbind spell")
end

local function retargetHotkeysCache(target)
	hotkeysCache = target
end

---@class Actions_Hotkeys
ns.Actions.Hotkeys = {
	retargetHotkeysCache = retargetHotkeysCache,
	updateHotkeys = updateHotkeys,
	deregisterHotkeyByComm = deregisterHotkeyByComm,
	deregisterHotkeyByKey = deregisterHotkeyByKey,
	deregisterOrphanedCommIDs = deregisterOrphanedCommIDs,
	registerHotkey = registerHotkey,
	getHotkeys = getHotkeys,
	getHotkeyByCommID = getHotkeyByCommID,
	getHotkeyByKey = getHotkeyByKey,
	showLinkHotkeyDialog = showLinkHotkeyDialog,
}
