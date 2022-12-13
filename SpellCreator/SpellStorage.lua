---@class ns
local ns = select(2, ...)

local Logging = ns.Logging
local ProfileFilter = ns.ProfileFilter
local Vault = ns.Vault

local Debug = ns.Utils.Debug
local DataUtils = ns.Utils.Data

local cprint, dprint, eprint = Logging.cprint, Logging.dprint, Logging.eprint
local isNotDefined = DataUtils.isNotDefined

---@param spellToLoad VaultSpell
local function loadSpell(spellToLoad)
	--dprint("Loading spell.. "..spellToLoad.commID)

	Attic.updateInfo(spellToLoad)

	---@type VaultSpellAction[]
	local localSpellActions = CopyTable(spellToLoad.actions)
	local numberOfActionsToLoad = #localSpellActions

	-- Adjust the number of available Action Rows
	SpellRow.setNumActiveRows(numberOfActionsToLoad)

	if SpellCreatorMasterTable.Options["loadChronologically"] then
		table.sort(localSpellActions, function(k1, k2) return k1.delay < k2.delay end)
	end

	-- Loop thru actions & set their data
	for rowNum, actionData in ipairs(localSpellActions) do
		SpellRow.setRowAction(rowNum, actionData)
	end
end

---@param fromPhaseVaultID integer?
local saveSpell = function(overwriteBypass, fromPhaseVaultID, manualData)
	local wasOverwritten = false
	local newSpellData = {}
	if fromPhaseVaultID then
		local phaseSpell = Vault.phase.getSpellByIndex(fromPhaseVaultID)
		newSpellData.commID = phaseSpell.commID
		newSpellData.fullName = phaseSpell.fullName
		newSpellData.description = phaseSpell.description or nil
		newSpellData.actions = phaseSpell.actions
		newSpellData.castbar = phaseSpell.castbar
		newSpellData.icon = phaseSpell.icon
		dprint("Saving Spell from Phase Vault, fake commID: " .. fromPhaseVaultID .. ", real commID: " .. newSpellData.commID)
	elseif manualData then
		newSpellData = manualData
		Debug.dump(manualData)
		dprint("Saving Manual Spell Data (Import): " .. newSpellData.commID)
	else
		newSpellData = Attic.getInfo()
		if newSpellData.castbar == 1 then newSpellData.castbar = nil end -- data space saving - default is castbar, so if it's 1 for castbar, let's save the storage and leave it nil
		newSpellData.actions = {}
	end

	ProfileFilter.ensureProfile(newSpellData)

	if isNotDefined(newSpellData.fullName) or isNotDefined(newSpellData.commID) then
		cprint("Spell Name and/or Spell Command cannot be blank.")
		return;
	end
	local existingSpell = Vault.personal.findSpellByID(newSpellData.commID)
	if existingSpell then
		if overwriteBypass then
			wasOverwritten = true
		else
			Popups.showPersonalVaultOverwritePopup(newSpellData, existingSpell, fromPhaseVaultID, manualData, saveSpell)
			return;
		end
	end

	if not fromPhaseVaultID and not manualData then
		for i = 1, SpellRow.getNumActiveRows() do
			local rowData = SpellRow.getRowAction(i)

			if rowData and rowData.delay >= 0 then
				if actionTypeData[rowData.actionType] then
					table.insert(newSpellData.actions, CopyTable(rowData))
					dprint(false, "Action Row " .. i .. " Captured successfully.. pending final save to data..")
				else
					dprint(false, "Action Row " .. i .. " Failed to save - invalid Action Type.")
				end
			else
				dprint(false, "Action Row " .. i .. " Failed to save - invalid Main Delay.")
			end
		end
	end

	if #newSpellData.actions >= 1 then
		Vault.personal.saveSpell(newSpellData)
		Attic.setEditCommId(Attic.getInfo().commID)
		SCForgeMainFrame.SaveSpellButton:UpdateIfValid()
		if wasOverwritten then
			cprint("Over-wrote spell with name: " ..
				newSpellData.fullName ..
				". Use command: '/sf " .. newSpellData.commID .. "' to cast it! (" .. #newSpellData.actions .. " actions).")
		else
			cprint("Saved spell with name: " ..
				newSpellData.fullName ..
				". Use command: '/sf " .. newSpellData.commID .. "' to cast it! (" .. #newSpellData.actions .. " actions).")
		end
	else
		cprint("Spell has no valid actions and was not saved. Please double check your actions & try again. You can turn on debug mode to see more information when trying to save (/sfdebug).")
	end
	if not fromPhaseVaultID then
		updateSpellLoadRows()
	end
end

local function saveSpellToPhaseVault(commID, overwrite, fromPhase, forcePrivate)
	local needToOverwrite = false
	local phaseVaultIndex
	if not commID then
		eprint("Invalid CommID.")
		return;
	end
	if fromPhase then
		phaseVaultIndex = commID
		commID = Vault.phase.getSpellByIndex(phaseVaultIndex).commID
	end
	if phaseVault.isSavingOrLoadingAddonData then eprint("Arcaum is already loading or saving a spell. To avoid data corruption, you can't do that right now. Try again in a moment."); return; end
	if isMemberPlus() then
		dprint("Trying to save spell to phase vault.")

		local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_KEYS")
		phaseVault.isSavingOrLoadingAddonData = true
		sendPhaseVaultIOLock(true)
		phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
		phaseAddonDataListener:SetScript("OnEvent", function(self, event, prefix, text, channel, sender, ...)
			if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
				phaseAddonDataListener:UnregisterEvent("CHAT_MSG_ADDON");

				--print(text)
				if (text ~= "" and #text > 0) then phaseVaultKeys = serializer.decompressForAddonMsg(text) else phaseVaultKeys = {} end

				dprint("Phase spell keys: ")
				Debug.ddump(phaseVaultKeys)

				for k, v in ipairs(phaseVaultKeys) do
					if v == commID then
						if not overwrite then
							-- phase already has this ID saved.. Handle over-write...
							dprint("Phase already has a spell saved by Command '" .. commID .. "'. Prompting to confirm over-write.")

							StaticPopupDialogs["SCFORGE_CONFIRM_POVERWRITE"] = {
								text = "Spell '" .. commID .. "' Already exists in the Phase Vault.\n\rDo you want to overwrite the spell?",
								OnAccept = function() saveSpellToPhaseVault(commID, true) end,
								button1 = "Overwrite",
								button2 = CANCEL,
								hideOnEscape = true,
								whileDead = true,
							}
							StaticPopup_Show("SCFORGE_CONFIRM_POVERWRITE")

							phaseVault.isSavingOrLoadingAddonData = false
							sendPhaseVaultIOLock(false)
							return;
						else
							needToOverwrite = true
						end
					end
				end

				-- Passed checking for duplicates. NOW we can save it.
				local _spellData
				if fromPhase then
					_spellData = Vault.phase.getSpellByIndex(phaseVaultIndex)
				else
					_spellData = Vault.personal.findSpellByID(commID)
				end
				if LoadSpellFrame.getUploadToPhaseVisibility() == SPELL_VISIBILITY.PRIVATE then
					_spellData.private = true
				else
					_spellData.private = nil
				end
				if not isNotDefined(forcePrivate) then
					_spellData.private = forcePrivate
					dprint(nil, "Force Vis was set to " .. tostring(forcePrivate))
				end
				local str = serializer.compressForAddonMsg(_spellData)

				local key = "SCFORGE_S_" .. commID
				C_Epsilon.SetPhaseAddonData(key, str)

				if not needToOverwrite then
					tinsert(phaseVaultKeys, commID)
					phaseVaultKeys = serializer.compressForAddonMsg(phaseVaultKeys)
					C_Epsilon.SetPhaseAddonData("SCFORGE_KEYS", phaseVaultKeys)
				end

				cprint("Spell '" .. commID .. "' saved to the Phase Vault.")
				phaseVault.isSavingOrLoadingAddonData = false
				sendPhaseVaultIOLock(false)
				getSpellForgePhaseVault()
			end
		end)
	else
		eprint("You must be a member, officer, or owner in order to save spells to the phase.")
	end
end

ns.SpellStorage = {
	loadSpell = loadSpell,
	saveSpell = saveSpell,
	saveSpellToPhaseVault = saveSpellToPhaseVault,
}
