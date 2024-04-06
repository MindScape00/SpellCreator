---@class ns
local ns = select(2, ...)

--#region Personal
local Libs = ns.Libs

---@return table<CommID, VaultSpell>
local function getPersonalSpells()
	return SpellCreatorSavedSpells
end

---@return CommID[]
local function getPersonalSpellIDs()
	local keys = {}
	for key in pairs(SpellCreatorSavedSpells) do
		table.insert(keys, key)
	end
	return keys
end

---@param commID CommID
---@return VaultSpell?
local function findPersonalSpellByID(commID)
	return SpellCreatorSavedSpells[commID]
end

---@param spell VaultSpell
local function savePersonalSpell(spell)
	SpellCreatorSavedSpells[spell.commID] = spell
	if spell.profile then
		ns.ProfileFilter.toggleFilter(spell.profile, true)
	end
	ns.UI.ItemIntegration.scripts.updateCache(true)
end

---@param commID CommID
local function deletePersonalSpell(commID)
	SpellCreatorSavedSpells[commID] = nil
end

local function assignPersonalSpellAuthor(commID, author)
	SpellCreatorSavedSpells[commID].author = author
end

--#endregion
--#region Phase

---@type table<integer, VaultSpell>
local phaseSpells = {}

---@param commID CommID
---@return VaultSpell?
local function findPhaseSpellByID(commID)
	for _, spell in ipairs(phaseSpells) do
		if spell.commID == commID then
			return spell
		end
	end
end

---@param commID CommID
---@return integer?
local function findPhaseSpellIndexByID(commID)
	for i, spell in ipairs(phaseSpells) do
		if spell.commID == commID then
			return i
		end
	end
end

---@param index integer
---@return VaultSpell
local function getPhaseSpellByIndex(index)
	return phaseSpells[index]
end

---@return table<integer, VaultSpell>
local function getPhaseSpells()
	return phaseSpells
end

local tIndexOf = tIndexOf
---@param spell VaultSpell
local function addPhaseSpell(spell)
	local index = findPhaseSpellIndexByID(spell.commID)
	if index then
		phaseSpells[index] = spell
	else
		tinsert(phaseSpells, spell)
	end
end

local function clearPhaseSpells()
	phaseSpells = {}
end

--#endregion

--[[ -- Change isSavingOrLoadingAddonData to a function toggle or val returner. Mostly for debug, switched back for release.
local addonDataLoadingOrSaving
local function isSavingOrLoadingAddonData(val)
	if val == true then
		--print("loading status changed, = true")
		addonDataLoadingOrSaving = true
	elseif val == false then
		--print("loading status changed, = false")
		addonDataLoadingOrSaving = false
	else
		--print("loading tested, came back as .. " .. tostring(addonDataLoadingOrSaving))
	end
	return addonDataLoadingOrSaving
end
--]]

---@param commID CommID
local function notifyPhaseOfSpellUpdate(commID)
	local addonMsgPrefix = ns.Comms.PREFIX
	local scforge_ChannelID = ns.Constants.ADDON_CHANNEL
	local phaseID = tostring(C_Epsilon.GetPhaseId())
	Libs.AceComm:SendCommMessage(addonMsgPrefix .. "_PSUP", phaseID .. string.char(31) .. commID, "CHANNEL", tostring(scforge_ChannelID))
	ns.Logging.dprint("Sending Phase Spell Update Message for phase " .. phaseID .. " & Spell " .. commID)
end

local function uploadSingleSpellAndNotifyUsers(commID, spell)
	ns.MainFuncs.uploadSpellDataToPhaseData(commID, spell)
	notifyPhaseOfSpellUpdate(commID)
end

ns.Vault = {
	personal = {
		getSpells = getPersonalSpells,
		getIDs = getPersonalSpellIDs,
		findSpellByID = findPersonalSpellByID,
		saveSpell = savePersonalSpell,
		deleteSpell = deletePersonalSpell,
		assignPersonalSpellAuthor = assignPersonalSpellAuthor,
	},
	phase = {
		isLoaded = false,
		isSavingOrLoadingAddonData = false,
		--isSavingOrLoadingAddonData = isSavingOrLoadingAddonData,
		getSpellByIndex = getPhaseSpellByIndex,
		findSpellByID = findPhaseSpellByID,
		findSpellIndexByID = findPhaseSpellIndexByID,
		getSpells = getPhaseSpells,
		addSpell = addPhaseSpell,
		clearSpells = clearPhaseSpells,

		uploadSingleSpellAndNotifyUsers = uploadSingleSpellAndNotifyUsers,
	},
}
