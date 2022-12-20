---@class ns
local ns = select(2, ...)

--#region Personal

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

---@param spell VaultSpell
local function addPhaseSpell(spell)
	tinsert(phaseSpells, spell)
end

local function clearPhaseSpells()
	phaseSpells = {}
end

--#endregion

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
		getSpellByIndex = getPhaseSpellByIndex,
		findSpellByID = findPhaseSpellByID,
		findSpellIndexByID = findPhaseSpellIndexByID,
		getSpells = getPhaseSpells,
		addSpell = addPhaseSpell,
		clearSpells = clearPhaseSpells,
	},
}
