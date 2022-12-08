---@class ns
local ns = select(2, ...)

---@type VaultSpell[]
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

---@return VaultSpell[]
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

ns.Vault = {
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
