---@class ns
local ns = select(2, ...)
local addonName = ...

local Constants = ns.Constants
local Icons = ns.UI.Icons
local Logging = ns.Logging

local eprint = Logging.eprint

--#region ActionButton Stuff -- POC ONLY ATM

local QUICK_SLOT = "Interface\\Buttons\\UI-Quickslot"
local QUICK_SLOT_2 = "Interface\\Buttons\\UI-Quickslot2"
local QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"

local savedActionButtons = {}
local SHOW_GRID_REASON_EVENT = 2


local mainActionButtons = {}
for i = 1, 12 do
	mainActionButtons["ActionButton" .. i] = true
end

local ActionBarActionButtonMixin = ActionButton1 -- Hack

local function retargetSavedActionButtons(target)
	savedActionButtons = target
end

local function saveActionButtonToRegister(button, commID)
	local actionButtonName, page = button:GetName(), GetActionBarPage()
	if button:GetParent():GetName() == "MainMenuBarArtFrame" then
		actionButtonName = actionButtonName .. string.char(31) .. page
	end
	savedActionButtons[actionButtonName] = commID
end

local function clearActionButtonFromRegister(button)
	local actionButtonName, page = button:GetName(), GetActionBarPage()
	if button:GetParent():GetName() == "MainMenuBarArtFrame" then
		actionButtonName = actionButtonName .. string.char(31) .. page
	end

	savedActionButtons[actionButtonName] = nil
end

local function forceShowGridOnButton(button, reason)
	assert(button and reason);

	button:SetAttribute("showgrid", bit.bor(button:GetAttribute("showgrid"), reason));

	if (button.NormalTexture) then
		button.NormalTexture:SetVertexColor(1.0, 1.0, 1.0, 1.0);
	end
	if (button:GetAttribute("showgrid") > 0 and not button:GetAttribute("statehidden")) then
		button:Show();
	end
end


local function hideGridHook(button, reason)
	if button:GetAttribute("type") == "arcSpell" and button.command then button:Show(); end
end

local function hideGridOnButton(button, reason)
	assert(button and reason);
	local showgrid = button:GetAttribute("showgrid");

	if InCombatLockdown() then
		eprint("You're currently in combat. Arcanum cannot manipulate ActionBars while in combat.")
		return
	end

	if (showgrid > 0) then
		button:SetAttribute("showgrid", bit.band(showgrid, bit.bnot(reason)));
	end

	if (button:GetAttribute("showgrid") == 0 and not HasAction(button.action)) then
		button:Hide();
	end

	hideGridHook(button, reason)
end
--hooksecurefunc("ActionButton_HideGrid", hideGridHook)
hooksecurefunc(ActionBarActionButtonMixin, "HideGrid", hideGridHook)

local function updateTexture(self)
	local icon = self.icon
	if not icon then return end

	if not (self.command) then
		icon:Hide()
		self.cooldown:Hide()
		self:SetNormalTexture(QUICK_SLOT)
		self.NormalTexture:SetVertexColor(1.0, 1.0, 1.0, 0.5);
		return
	end

	local texture = self.iconTex

	if (texture) then
		icon:SetTexture(texture)
		icon:SetVertexColor(1.0, 1.0, 1.0, 1.0)
		icon:SetAlpha(1)
		icon:Show()
		self:SetNormalTexture(QUICK_SLOT_2)
		self.NormalTexture:SetVertexColor(0.90, 0.7, 1, 1.0); -- Make 'em purple-ish
	else
		icon:SetTexture(QUESTION_MARK)
		icon:SetVertexColor(1.0, 1.0, 1.0, 0.5)
		icon:Show()
		self:SetNormalTexture(QUICK_SLOT_2)
		self.NormalTexture:SetVertexColor(1.0, 1.0, 1.0, 0.5);
	end
end

local function updateCooldown(self)
	--print(self:GetName())
	local commID = self.command
	if commID then
		local spell = ns.Vault.personal.findSpellByID(self.command)
		if not spell then
			self.cooldown:Clear()
			return
		end

		if spell.cooldown then
			local remainingTime, cooldownTime = ns.Actions.Cooldowns.isSpellOnCooldown(commID)
			if remainingTime then
				self.cooldown:SetCooldown(GetTime() - (cooldownTime - remainingTime), cooldownTime)
			else
				self.cooldown:Clear()
			end
		else
			self.cooldown:Clear()
		end
	end
end

local function updateArcActionButtonCooldowns()
	for buttonName, commID in pairs(savedActionButtons) do
		local actionBarPage
		buttonName, actionBarPage = strsplit(string.char(31), buttonName, 2)

		local realButton = _G[buttonName]
		if realButton then
			updateCooldown(realButton)
		end
	end
end

local function _ABHook_SetTooltip(self)
	if self:GetAttribute("type") ~= "arcSpell" then return end

	local spell = ns.Vault.personal.findSpellByID(self.command)
	if not spell then
		GameTooltip:SetText("No Spell Found")
		return
	end
	local icon = Icons.getFinalIcon(spell.icon)
	GameTooltip:SetText(CreateTextureMarkup(icon, 24, 24, 24, 24, 0, 1, 0, 1) .. spell.fullName, 0.81, 0.18, 1, 1, true)

	if spell.cooldown then
		GameTooltip:AddDoubleLine(" ", WrapTextInColorCode(("Cooldown: %ss"):format(spell.cooldown), "FFFFFFFF"))
	end
	if spell.description then
		GameTooltip:AddLine(NORMAL_FONT_COLOR_CODE .. spell.description .. FONT_COLOR_CODE_CLOSE, 1, 1, 1, true)
		GameTooltip:AddLine(" ")
	end

	GameTooltip:AddDoubleLine("Arcanum ID:", WrapTextInColorCode(spell.commID, "FFFFFFFF"))
	GameTooltip:Show()
end
--hooksecurefunc("ActionButton_SetTooltip", _AB_SetTooltip)
hooksecurefunc(ActionBarActionButtonMixin, "SetTooltip", _ABHook_SetTooltip)

local function hookTooltip(self)
	if self.isTTHookedByArc then return end
	self.isTTHookedByArc = true
	hooksecurefunc(self, "SetTooltip", _ABHook_SetTooltip)
end

local function updateButton(self, spellData)
	updateTexture(self)
	updateCooldown(self)
	hookTooltip(self)

	if not spellData and self.command then
		spellData = ns.Vault.personal.findSpellByID(self.command)
	end
	if spellData then
		self.Name:SetText(Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode(spellData.fullName or spellData.commID))
	end
	--[[
	self:SetTooltip()
	self:UpdateTexture()
	self:UpdateCooldown()
	self:UpdateChecked()
	self:UpdateEquipped()
	self:UpdateUsable()
	self:UpdateText()
	self:UpdateCount()
	if self.command then
		self.rangeTimer = -1
	else
		self.rangeTimer = nil
	end
	--]]
end

local function castArcSpellFromAction(self, ...)
	ARC:CAST(self.command)
	updateCooldown(self)
end

local function cleanButton(self, doNotClearFromReg)
	if InCombatLockdown() then
		eprint("You're currently in combat. Arcanum cannot manipulate ActionBars while in combat.")
		return
	end

	--self.macroSpellName = nil
	--self.name:SetText("")
	--self.count:SetText("")
	self:SetAttribute("type", "action")
	self:SetAttribute("spell", "")
	self:SetAttribute("item", "")
	self:SetAttribute("macro", "")
	self:SetAttribute("macrotext", "")
	self:SetAttribute("clickbutton", "")
	self:SetAttribute("_onclick", "")
	self.Name:SetText("")

	self.command = nil

	if not doNotClearFromReg then
		clearActionButtonFromRegister(self)
	end

	if self.originalShowGrid then self:SetAttribute("showgrid", self.originalShowGrid) end
	forceShowGridOnButton(self, SHOW_GRID_REASON_EVENT)
end

--hooksecurefunc("ActionButton_Update", function(self)
--hooksecurefunc(ActionBarActionButtonMixin, "Update", function(self)
hooksecurefunc("ActionButton_UpdateFlyout", function(self) -- trying a hook on a function that got left as a global and is called at the end of update anyways
	if self:GetAttribute("type") == "arcSpell" then
		updateButton(self)

		--local actionID = ActionButton_CalculateAction(self)
		local actionID = self:CalculateAction()
		if GetActionInfo(actionID) then
			-- has a real spell, likely dropped ontop, we need to remove our ArcSpell & update it again
			cleanButton(self)
			--ActionButton_Update(self)
			self:Update()
		end
	end
end)

--#endregion

-- DRAGGABLE FRAMES SETUP

local dragIcon = CreateFrame("Frame", nil, UIParent)
dragIcon:SetFrameStrata("DIALOG")
dragIcon:SetSize(32, 32)
dragIcon:SetPoint("CENTER")
dragIcon.Icon = dragIcon:CreateTexture(nil, "OVERLAY", nil, 7)
dragIcon.Icon:SetAllPoints()
dragIcon:SetMovable(true)
dragIcon:Hide()
dragIcon:EnableMouse(false)

local function pickupSpell(commID)
	if InCombatLockdown() then
		eprint("You're currently in combat. Arcanum cannot manipulate ActionBars while in combat.")
		return
	end

	local spell = ns.Vault.personal.findSpellByID(commID) --[[@as VaultSpell]]
	if not spell then return end

	dragIcon.commID = commID
	dragIcon.spell = spell

	local texturePath = Icons.getFinalIcon(spell.icon)
	local uiScale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()

	--print(texturePath)
	dragIcon.Icon:SetTexture(texturePath)
	dragIcon:Show()
	dragIcon:ClearAllPoints()
	dragIcon:SetPoint("CENTER", nil, "BOTTOMLEFT", x / uiScale, y / uiScale)
	dragIcon:StartMoving()

	GameTooltip:Hide()

	for k, frame in ipairs(ActionBarButtonEventsFrame.frames) do
		forceShowGridOnButton(frame, SHOW_GRID_REASON_EVENT);
	end

	PlaySound(1186, "SFX")
end

local function dropSpell(slotFrom)
	dragIcon:StopMovingOrSizing()
	dragIcon:Hide()
	PlaySound(1203, "SFX")


	if InCombatLockdown() then
		eprint("You're currently in combat. Arcanum cannot manipulate ActionBars while in combat.")
		return
	end

	for k, frame in ipairs(ActionBarButtonEventsFrame.frames) do
		hideGridOnButton(frame, SHOW_GRID_REASON_EVENT);
	end
end

local function clearButton(self, fromLoad)
--	local actionID = ActionButton_CalculateAction(self)
	local actionID = self:CalculateAction()

	PickupAction(actionID)
	if fromLoad then
		PutItemInBackpack()
		ClearCursor()
	end
end

---@param actionButtonFrame frame
---@param commID CommID
---@param fromLoad boolean? if it's from the loading, not manual placement. Only used to handle if we clear the button or just pickup that action
local function assignActionButtonArcSpell(actionButtonFrame, commID, fromLoad)
	if InCombatLockdown() then
		eprint("You're currently in combat. Arcanum cannot manipulate ActionBars while in combat.")
		return
	end

	if not actionButtonFrame then return end
	local spell = ns.Vault.personal.findSpellByID(commID)
	if not spell then return end
	local oldType, oldCommand = actionButtonFrame:GetAttribute("type"), actionButtonFrame.command

	cleanButton(actionButtonFrame)
	clearButton(actionButtonFrame, fromLoad)

	actionButtonFrame.iconTex = Icons.getFinalIcon(spell.icon)
	actionButtonFrame.command = commID

	actionButtonFrame:SetAttribute("type", "arcSpell")
	actionButtonFrame:SetAttribute("_arcSpell", castArcSpellFromAction)

	updateButton(actionButtonFrame, spell)

	if not actionButtonFrame.originalShowGrid then
		actionButtonFrame.originalShowGrid = actionButtonFrame:GetAttribute("showgrid")
	end
	actionButtonFrame:SetAttribute("showgrid", 1)
	actionButtonFrame:Show()

	actionButtonFrame:HookScript("OnDragStart", function(self)
		if self:GetAttribute("type") ~= "arcSpell" then return end
		if (LOCK_ACTIONBAR ~= "1" or IsModifiedClick("PICKUPACTION")) then
			pickupSpell(self.command)
			cleanButton(self)
		end
	end)
	actionButtonFrame:HookScript("OnDragStop", function()
		if dragIcon:IsShown() then
			dropSpell()
		end
	end)

	saveActionButtonToRegister(actionButtonFrame, commID)

	-- handle picking up the old ArcSpell if there was one.
	--[[ -- Disabled until I can figure out how to fix the issue of placing it again while not dragging a frame.
	if oldType == "arcSpell" and oldCommand then
		print("PICKUP THE SPELL " .. oldCommand)
		pickupSpell(oldCommand)
	end
	--]]
end
--AssignActionButtonAction = assignActionButtonArcSpell

dragIcon:SetScript("OnHide", function()
	C_Timer.After(0, function()
		local slotTo = GetMouseFocus();

		for k, frame in ipairs(ActionBarButtonEventsFrame.frames) do
			if MouseIsOver(frame) then
				slotTo = frame
				--print(frame:GetName())
			end
		end

		if not SecureButton_GetModifiedAttribute(slotTo, "type") then return end -- not an action bar button
		--if not ActionButton_CalculateAction(slotTo) then return end        -- not an action bar button
		if not slotTo.CalculateAction or not slotTo:CalculateAction() then return end        -- not an action bar button

		--print(slotTo:GetName(), slotTo)
		assignActionButtonArcSpell(slotTo, dragIcon.commID)
	end)
end)
dragIcon:SetScript("OnMouseUp", function()
	dropSpell()
end)
dragIcon:SetScript("OnMouseDown", function()
	dropSpell()
end)
--[[ -- Attempt at making it so you can click to drop when not dragging. This works but still lets you click the spell under, so it places it.. then.. casts... UGH. Disabling this system for now.
dragIcon:SetScript("OnEvent", function(self, event)
	if event == "GLOBAL_MOUSE_UP" then
		if self:IsShown() then
			dropSpell()
		end
	end
end)
dragIcon:RegisterEvent("GLOBAL_MOUSE_UP")
--]]

local function _onDragStart(self)
	pickupSpell(self.commID)
end

local function _onDragStop(slotFrom)
	dropSpell(slotFrom)
end

local function makeButtonDraggableToActionBar(button)
	button:RegisterForDrag("LeftButton")
	button:HookScript("OnDragStart", _onDragStart)
	button:HookScript("OnDragStop", _onDragStop)
end

local function loadActionButtonsFromRegister()

	for buttonName, commID in pairs(savedActionButtons) do

		if InCombatLockdown() then               -- wait to load until out of combat
			eprint("WARNING: You are in Combat. Arcanum cannot load ActionBar overrides while in combat and will attempt to load them again once you exit combat.")
			local f = CreateFrame("frame")
			f:RegisterEvent("PLAYER_LEAVE_COMBAT")
			f:SetScript("OnEvent", function(event)
				if event == "PLAYER_LEAVE_COMBAT" then
					f:UnregisterEvent("PLAYER_LEAVE_COMBAT")
					C_Timer.After(0, loadActionButtonsFromRegister)
				end
			end)
			return
		end

		local actionBarPage
		buttonName, actionBarPage = strsplit(string.char(31), buttonName, 2)

		if actionBarPage then
			if tonumber(actionBarPage) == GetActionBarPage() then
				local realButton = _G[buttonName]
				assignActionButtonArcSpell(realButton, commID, true)
			else
				ns.Logging.dprint("Didn't assign the following ActionButton: " .. commID, buttonName, actionBarPage, GetActionBarPage())
			end
		else
			local realButton = _G[buttonName]
			assignActionButtonArcSpell(realButton, commID, true)
		end
	end
end

local pageChangeListener = dragIcon -- reusing dragIcon since it's a free frame we can steal the OnEvent from.
pageChangeListener:HookScript("OnEvent", function(self, event)
	if event == "ACTIONBAR_PAGE_CHANGED" then
		for buttonName in pairs(mainActionButtons) do
			local realButton = _G[buttonName]
			if realButton then
				cleanButton(realButton, true)
			end
		end
	end
	loadActionButtonsFromRegister()
end)
pageChangeListener:RegisterEvent("ACTIONBAR_PAGE_CHANGED")

---@class UI_ActionButton
ns.UI.ActionButton = {
	retargetSavedActionButtons = retargetSavedActionButtons,

	assignArcSpell = assignActionButtonArcSpell,
	makeButtonDraggableToActionBar = makeButtonDraggableToActionBar,
	updateArcActionButtonCooldowns = updateArcActionButtonCooldowns,

	loadActionButtonsFromRegister = loadActionButtonsFromRegister,
}
