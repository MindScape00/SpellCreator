---@class ns
local ns = select(2, ...)

local Logging = ns.Logging
local SavedVariables = ns.SavedVariables

---@class ActiveProfileFilter
---@field showAll boolean
---@field Account boolean
local selectedProfileFilter = {}

---@param name string
---@param enabled true | nil
local function toggleFilter(name, enabled)
    selectedProfileFilter[name] = enabled
end

---@param enabled true | nil
local function togglePlayer(enabled)
    toggleFilter(GetUnitName("player"), enabled)
end

---@param showAll true | nil
local function toggleShowAll(showAll)
    toggleFilter("showAll", showAll)
end

---@param filter string
---@return boolean isShown
local function isShown(filter)
    return selectedProfileFilter[filter]
end

---@return boolean isShown
local function isPlayerShown()
    return selectedProfileFilter[GetUnitName("player")]
end

local function isAllShown()
    return selectedProfileFilter.showAll
end

local function isAccountShown()
    return selectedProfileFilter.Account
end

local function enableAll()
    toggleShowAll(true)

	for _, profileName in ipairs(SavedVariables.getProfileNames()) do
        selectedProfileFilter[profileName] = true
	end

    togglePlayer(true)
end

local function reset()
	for _, profileName in ipairs(SavedVariables.getProfileNames()) do
        selectedProfileFilter[profileName] = nil
	end

    toggleShowAll(nil)

    local defaultProfile = SavedVariables.getDefaultProfile()

    if defaultProfile and defaultProfile ~= "All" then
        selectedProfileFilter[defaultProfile] = true
    else
        togglePlayer(true)
    end
end

---@param spell VaultSpell
---@param profileName string
local function setSpellProfile(spell, profileName)
    spell.profile = profileName
end

---@param spell VaultSpell
local function ensureProfile(spell)
    if not spell.profile then
        setSpellProfile(spell, GetUnitName("player"))
        Logging.dprint("Spell '".. spell.commID .."' didn't have a profile. Set to character.")
    end
end

---@param spell VaultSpell
local function shouldFilterFromPersonalVault(spell)
    return not selectedProfileFilter.showAll and not selectedProfileFilter[spell.profile]
end

local function init()
    local defaultProfile = SavedVariables.getDefaultProfile()
	if defaultProfile == "Character" then
        togglePlayer(true)
	elseif defaultProfile == "Account" then
        selectedProfileFilter.Account = true
	elseif defaultProfile == "All" then
		enableAll()
	else -- default filter -- REMINDER: CHANGE THIS TO THE CHARACTER SETTINGS AFTER NEXT UPDATE
        --SpellCreatorMasterTable.Options.defaultProfile = "Character"
		--selectedProfileFilter[GetUnitName("player")] = true
        SavedVariables.setDefaultProfile("All")
        toggleShowAll(true)
	end
end

---@class ProfileFilter
ns.ProfileFilter = {
    isShown = isShown,
    isAllShown = isAllShown,
    isAccountShown = isAccountShown,
    isPlayerShown = isPlayerShown,
    enableAll = enableAll,
    reset = reset,
    toggleFilter = toggleFilter,
    toggleShowAll = toggleShowAll,


    ensureProfile = ensureProfile,
    shouldFilterFromPersonalVault = shouldFilterFromPersonalVault,
    init = init,
}
