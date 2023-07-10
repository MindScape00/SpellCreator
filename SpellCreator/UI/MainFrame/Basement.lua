---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local Execute = ns.Actions.Execute
local Permissions = ns.Permissions
local Tooltip = ns.Utils.Tooltip
local UIHelpers = ns.Utils.UIHelpers

local Animation = ns.UI.Animation
local Attic = ns.UI.MainFrame.Attic
local Castbar = ns.UI.Castbar
local Icons = ns.UI.Icons

local START_ZONE_NAME = Constants.START_ZONE_NAME
local saveButton
local executeSpellButton

---@param mainFrame SCForgeMainFrame
local function flicker(mainFrame)
	Animation.setFrameFlicker(mainFrame.Inset.Bg.Overlay, 3, nil, nil, 0.05, 0.8)
end

---@param mainFrame SCForgeMainFrame
local function stopFlicker(mainFrame)
	Animation.stopFrameFlicker(mainFrame.Inset.Bg.Overlay, 0.05, 0.25)
end

---@param mainFrame SCForgeMainFrame
---@param duration number
local function doFlicker(mainFrame, duration)
	flicker(mainFrame)
	C_Timer.After(duration, function() stopFlicker(mainFrame) end)
end

local function isSaving()
	return Attic.getInfo().commID == Attic.getEditCommId()
end

local function updateExecutePermission()
	executeSpellButton:SetEnabled(Permissions.canExecuteSpells())
end

---@param mainFrame SCForgeMainFrame
---@param saveSpell fun(overwriteBypass: boolean?)
local function createSaveButton(mainFrame, saveSpell)
	saveButton = CreateFrame("BUTTON", nil, mainFrame, "UIPanelButtonTemplate")
	saveButton:SetPoint("BOTTOMLEFT", 20, 3)
	saveButton:SetSize(24 * 4, 24)
	saveButton:SetText(BATTLETAG_CREATE)
	saveButton:SetMotionScriptsWhileDisabled(true)
	saveButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	saveButton:SetScript("OnClick", function(self, button)
		local success = saveSpell(button == "RightClick" or isSaving())
		if success then Attic.markEditorSaved() end
		doFlicker(mainFrame, 1)
	end)

	Tooltip.set(saveButton,
		function(self)
			return (isSaving() and "Save" or "Create") .. " your ArcSpell!"
		end,
		function(self)
			local spellInfo = Attic.getInfo()

			if self:IsEnabled() then
				local castHelp = "\rYou can cast it using '/sf " .. (spellInfo.commID or "commID") .. "' for quick use!"

				if isSaving() then
					return {
						"Finish editing your spell and save your changes.",
						castHelp,
					}
				else
					return {
						"Finish your spell & save it to your Personal Vault.",
						castHelp,
						"\rRight-click to over-write a previous spell with the same Command ID without confirmation.",
					}
				end
			end

			return "\nYou must specify a Spell Name & Spell Command to Create / Save your spell."
		end
	)

	saveButton.UpdateIfValid = function(self)
		if Attic.isInfoValid() and ns.UI.SpellRow.isAnyActionRowValid() then
			self:SetEnabled(true)
		else
			self:SetEnabled(false)
		end
		if self:IsEnabled() then
			self:SetText(isSaving() and "Save" or "Create")
		end
	end

	saveButton:HookScript("OnShow", saveButton.UpdateIfValid)
	local callback = function() saveButton:UpdateIfValid() end
	Attic.onNameChange(callback)
	Attic.onCommandChange(callback)

	return saveButton
end

---@param mainFrame SCForgeMainFrame
---@param toggleVault fun()
local function createOpenVaultButton(mainFrame, toggleVault)
	local openVaultButton = CreateFrame("BUTTON", nil, mainFrame, "UIPanelButtonTemplate")
	openVaultButton:SetPoint("LEFT", saveButton, "RIGHT", 0, 0)
	openVaultButton:SetSize(24 * 4, 24)
	openVaultButton:SetText("Vault")

	openVaultButton:SetScript("OnClick", toggleVault)

	Tooltip.set(openVaultButton,
		"Access your Vaults",
		{
			"You can load, edit, and manage all of your created/saved ArcSpells from the Personal Vault.",
			"\nThe Phase Vault can also be accessed here for any ArcSpells saved to your current phase."
		}
	)

	return openVaultButton
end

---@param mainFrame SCForgeMainFrame
---@param getForgeActions fun(): VaultSpellAction[]
local function createExecuteSpellButton(mainFrame, getForgeActions)
	executeSpellButton = CreateFrame("BUTTON", nil, mainFrame, "UIPanelButtonTemplate")
	executeSpellButton:SetPoint("BOTTOM", 0, 3)
	executeSpellButton:SetSize(24 * 4, 24)
	executeSpellButton:SetText(ACTION_SPELL_CAST_SUCCESS:gsub("^%l", string.upper))
	executeSpellButton:SetMotionScriptsWhileDisabled(true)

	executeSpellButton:SetScript("OnClick", function()
		local maxDelay = 0
		local actionsToCommit = getForgeActions()
		for _, actionData in ipairs(actionsToCommit) do
			maxDelay = max(actionData.delay, actionData.revertDelay or 0, maxDelay)
		end

		doFlicker(mainFrame, maxDelay)

		local spellInfo = Attic.getInfo()
		local spellName = spellInfo.fullName
		local spellData = { ["icon"] = Icons.getFinalIcon(spellInfo.icon), commID = spellInfo.commID, castbar = spellInfo.castbar } ---@as VaultSpell

		Execute.executeSpell(actionsToCommit, nil, spellName, spellData)

		local castBarStatus = spellInfo.castbar

		--[[
		if castBarStatus ~= 0 then
			Castbar.showCastBar(maxDelay, spellName, spellData, castBarStatus == 2, nil, nil)
		end
		--]]
	end)

	Tooltip.set(executeSpellButton,
		"Cast the above Actions!",
		function(self)
			if self:IsEnabled() then
				return "Useful to test your spell before saving."
			end
			return "You cannot cast spells in main-phase " .. START_ZONE_NAME .. "."
		end
	)

	updateExecutePermission()

	return executeSpellButton
end

---@param mainFrame SCForgeMainFrame
---@param resetUI fun(resetButton: BUTTON)
local function createResetButton(mainFrame, resetUI)
	local resetButton = CreateFrame("BUTTON", nil, mainFrame)
	resetButton:SetPoint("BOTTOMRIGHT", -40, 2)
	resetButton:SetSize(24, 24)

	UIHelpers.setupCoherentButtonTextures(resetButton, "transmog-icon-revert", true)
	resetButton:SetMotionScriptsWhileDisabled(true)

	resetButton:SetScript("OnClick", function(self)
		if not ns.UI.Popups.checkAndShowResetForgeConfirmation("reset", resetUI, self) then
			resetUI(self)
		end
	end)

	Tooltip.set(resetButton,
		"Clear & Reset the Forge UI!", {
			"Use this to clear the action rows & spell info, and start a fresh new spell!",
			"\nWARNING: You'll lose any data that hasn't been saved yet using 'Create' or 'Save'!",
		}
	)

	return resetButton
end

---@param mainFrame SCForgeMainFrame
---@param callbacks { getForgeActions: (fun(): VaultSpellAction[]), toggleVault: fun(), saveSpell: fun(overwriteBypass: boolean?), resetUI: fun(resetButton: BUTTON) }
local function init(mainFrame, callbacks)
	mainFrame.ExecuteSpellButton = createExecuteSpellButton(mainFrame, callbacks.getForgeActions)
	mainFrame.SaveSpellButton = createSaveButton(mainFrame, callbacks.saveSpell)
	mainFrame.OpenVaultButton = createOpenVaultButton(mainFrame, callbacks.toggleVault)
	mainFrame.ResetUIButton = createResetButton(mainFrame, callbacks.resetUI)
end

---@class UI_MainFrame_Basement
ns.UI.MainFrame.Basement = {
	init = init,
	updateExecutePermission = updateExecutePermission,
}
