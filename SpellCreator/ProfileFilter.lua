---@class ns
local ns = select(2, ...)

local Logging = ns.Logging
local SavedVariables = ns.SavedVariables

local DEFAULT_PROFILE_NAME = GetUnitName("player")

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

	toggleFilter("Account", nil)
	togglePlayer(nil)
    toggleShowAll(nil)

    local defaultProfile = SavedVariables.getDefaultProfile()

    if defaultProfile then
		if defaultProfile == "Character" then
        	togglePlayer(true)
--		elseif defaultProfile == "All" then -- disabled because uh - well - then you can't ever reset to none, and while technically correct, it's annoying..
--			toggleShowAll(true)
		else
			selectedProfileFilter[defaultProfile] = true
		end
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
        setSpellProfile(spell, DEFAULT_PROFILE_NAME)
        Logging.dprint("Spell '".. spell.commID .."' didn't have a profile. Set to " .. DEFAULT_PROFILE_NAME)
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
	DEFAULT_PROFILE_NAME = DEFAULT_PROFILE_NAME,

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
