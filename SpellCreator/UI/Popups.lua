---@class ns
local ns = select(2, ...)

local Comms = ns.Comms
local Tooltip = ns.Utils.Tooltip
local Vault = ns.Vault

local function genOverwriteString(newname, oldname)
	if newname == oldname then
		return "Do you want to overwrite the spell ("..newname..")?"
	else
		return "Do you want to overwrite the spell?\rOld: "..oldname.."\rNew: "..newname
	end
end

local function showPersonalVaultOverwritePopup(newSpellData, oldSpellData, fromPhaseVaultID, manualData, callback)

	StaticPopupDialogs["SCFORGE_CONFIRM_OVERWRITE"] = {
		text = "Spell with CommID "..Tooltip.genContrastText(newSpellData.commID).." already exists.\n\r"..genOverwriteString(newSpellData.fullName, oldSpellData.fullName),
		OnAccept = function() callback(true, (fromPhaseVaultID and fromPhaseVaultID or nil), (manualData and manualData or nil)) end,
		button1 = "Overwrite",
		button2 = "Cancel",
		hideOnEscape = true,
		whileDead = true,
	}
	StaticPopup_Show("SCFORGE_CONFIRM_OVERWRITE")

end

local function showCommOverwritePopup(data, charName, callback)
	local spell = Vault.personal.findSpellByID(data.commID)
	if not spell then return end

	StaticPopupDialogs["SCFORGE_CONFIRM_OVERWRITE"] = {
		text = "Spell with CommID "..Tooltip.genContrastText(data.commID).." already exists.\n\r"..genOverwriteString(data.fullName, spell.fullName),
		OnAccept = function()
			Comms.saveReceivedSpell(data, charName)
			if callback then callback() end
		end,
		button1 = "Overwrite",
		button2 = "Cancel",
		hideOnEscape = true,
		whileDead = true,
	}
	StaticPopup_Show("SCFORGE_CONFIRM_OVERWRITE")
end

---@class UI_Popups
ns.UI.Popups = {
	showPersonalVaultOverwritePopup = showPersonalVaultOverwritePopup,
	showCommOverwritePopup = showCommOverwritePopup,
}
