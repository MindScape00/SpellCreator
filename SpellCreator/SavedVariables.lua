local addonName = ...
---@class ns
local ns = select(2, ...)

local DataUtils = ns.Utils.Data
local Vault = ns.Vault
local Constants = ns.Constants

local isNotDefined = DataUtils.isNotDefined

local addonVersion = GetAddOnMetadata(addonName, "Version")

----------------------
-- // Init Baseline Tables
----------------------

SpellCreatorMasterTable = {}
SpellCreatorMasterTable.Options = {}
SpellCreatorMasterTable.quickCastSpells = {}

SpellCreatorCharacterTable = {}

SpellCreatorMasterTable.quickcast = {}
---@class QCSavedBooks
---@field savedBookTable table<QuickcastBook, QuickcastPage[]>
SpellCreatorMasterTable.quickcast.books = {}

----------------------
-- // Simple Unlocks Tracker, could avoid functions since it's all just table but this will make it easier to track / use
----------------------

---@param key string
---@return boolean
local function isUnlocked(key)
	if SpellCreatorMasterTable.Unlocks[key] then return true else return false end
end

---@param key string
---@param dateData {year: integer, month: integer, day: integer, hour: integer?, min: integer?, sec: integer?}
local function isUnlockedByKeyOrTime(key, dateData)
	if isUnlocked(key) then
		return true
	elseif DataUtils.isTodayAfterOrEqualDate(dateData) then
		return true
	else
		return false
	end
end

---@param key string
---@return boolean success only false if it was already unlocked
local function unlock(key)
	if isUnlocked(key) then return false end
	SpellCreatorMasterTable.Unlocks[key] = true
	return true
end

---@param key string
local function clearUnlock(key) -- used to clean unlocks after their time gate.
	SpellCreatorMasterTable.Unlocks[key] = nil
end

----------------------
-- // Profiles
----------------------

---@return DefaultProfileOption
local function getDefaultProfile()
	return SpellCreatorMasterTable.Options.defaultProfile
end

---@param defaultProfile DefaultProfileOption
local function setDefaultProfile(defaultProfile)
	SpellCreatorMasterTable.Options.defaultProfile = defaultProfile
end

---@param filterAccount? boolean
---@param filterPlayer? boolean
---@return string[] profileNames A list of profile names
local function getProfileNames(filterAccount, filterPlayer)
	local profileNames = {}
	local profilesMap = {}

	for _, v in pairs(Vault.personal.getSpells()) do
		if v.profile
			and (not filterAccount or v.profile ~= "Account")
			and (not filterPlayer or v.profile ~= Constants.CHARACTER_NAME) then
			profilesMap[v.profile] = true
		end
	end

	for profile in pairs(profilesMap) do
		tinsert(profileNames, profile)
	end

	return profileNames
end

----------------------
-- // Init Saved Variables & Master Tables from Saved Variables
----------------------

---@return boolean hadUpdate Whether the addon was updated since last load
local function init()
	local hadUpdate, lastAddonVersion

	if isNotDefined(SpellCreatorMasterTable.Options) then SpellCreatorMasterTable.Options = {} end
	if isNotDefined(SpellCreatorMasterTable.quickCastSpells) then SpellCreatorMasterTable.quickCastSpells = {} end
	if isNotDefined(SpellCreatorMasterTable.hotkeys) then SpellCreatorMasterTable.hotkeys = {} end
	ns.Actions.Hotkeys.retargetHotkeysCache(SpellCreatorMasterTable.hotkeys)

	if isNotDefined(SpellCreatorMasterTable.quickcast) then SpellCreatorMasterTable.quickcast = {} end
	if isNotDefined(SpellCreatorMasterTable.quickcast.books) then SpellCreatorMasterTable.quickcast.books = {} end
	if isNotDefined(SpellCreatorMasterTable.quickcast.shownByChar) then SpellCreatorMasterTable.quickcast.shownByChar = {} end
	if isNotDefined(SpellCreatorMasterTable.quickcast.shownByChar[Constants.CHARACTER_NAME]) then
		SpellCreatorMasterTable.quickcast.shownByChar[Constants.CHARACTER_NAME] = {
			[string.format(Constants.DEFAULT_QC_BOOK_NAME, 1)] = true
		}
	end
	--if isNotDefined(SpellCreatorMasterTable.quickcastBooks) then SpellCreatorMasterTable.quickcastBooks = {} end

	--if isNotDefined(SpellCreatorMasterTable.Options.sparkKeybind) then SpellCreatorMasterTable.Options.sparkKeybind = "F" end -- Moved to Delayed Init
	if isNotDefined(SpellCreatorMasterTable.Options["debug"]) then SpellCreatorMasterTable.Options["debug"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["locked"]) then SpellCreatorMasterTable.Options["locked"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["mmLoc"]) then SpellCreatorMasterTable.Options["mmLoc"] = 2.7 end
	if isNotDefined(SpellCreatorMasterTable.Options["minimapIcon"]) then SpellCreatorMasterTable.Options["minimapIcon"] = true end

	if isNotDefined(SpellCreatorMasterTable.Options["showTooltips"]) then SpellCreatorMasterTable.Options["showTooltips"] = true end
	if isNotDefined(SpellCreatorMasterTable.Options["biggerInputBox"]) then SpellCreatorMasterTable.Options["biggerInputBox"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["showVaultOnShow"]) then SpellCreatorMasterTable.Options["showVaultOnShow"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["clearRowOnRemove"]) then SpellCreatorMasterTable.Options["clearRowOnRemove"] = false end
	if isNotDefined(SpellCreatorMasterTable.Options["loadChronologically"]) then SpellCreatorMasterTable.Options["loadChronologically"] = false end

	if isNotDefined(SpellCreatorMasterTable.Options["keepQCOpen"]) then SpellCreatorMasterTable.Options["keepQCOpen"] = true end
	if isNotDefined(SpellCreatorMasterTable.Options["allowQCOverscrolling"]) then SpellCreatorMasterTable.Options["allowQCOverscrolling"] = true end

	if isNotDefined(SpellCreatorMasterTable.arcVarLocations) then SpellCreatorMasterTable.arcVarLocations = {} end
	ns.API.retargetSavedLocationsTable(SpellCreatorMasterTable.arcVarLocations)

	-- Per-Character Vars

	if isNotDefined(SpellCreatorCharacterTable.phaseArcVars) then SpellCreatorCharacterTable.phaseArcVars = {} end
	ns.API.retargetPhaseArcVarTable(SpellCreatorCharacterTable.phaseArcVars)

	if isNotDefined(SpellCreatorCharacterTable.cooldownsTable) then SpellCreatorCharacterTable.cooldownsTable = { phase = {}, personal = {}, sparks = {} } end
	ns.Actions.Cooldowns.retargetCooldownsTable(SpellCreatorCharacterTable.cooldownsTable)

	if isNotDefined(SpellCreatorCharacterTable.actionButtonsRegister) then SpellCreatorCharacterTable.actionButtonsRegister = {} end
	ns.UI.ActionButton.retargetSavedActionButtons(SpellCreatorCharacterTable.actionButtonsRegister)

	-- // Unlocks Tracker table
	if isNotDefined(SpellCreatorMasterTable.Unlocks) then SpellCreatorMasterTable.Unlocks = {} end

	-- // Version & Update Tracking
	lastAddonVersion = SpellCreatorMasterTable.Options["lastAddonVersion"]
	if not lastAddonVersion then
		hadUpdate = false
	else
		hadUpdate = (addonVersion ~= lastAddonVersion)
	end
	SpellCreatorMasterTable.Options["lastAddonVersion"] = addonVersion

	-- // Saved Spells Table Init
	if not SpellCreatorSavedSpells then
		SpellCreatorSavedSpells = {}
	end

	-- reset these so we are not caching debug data longer than a single reload.
	SpellCreatorMasterTable.Options["debugPhaseData"] = nil
	SpellCreatorMasterTable.Options["debugPhaseKeys"] = nil

	return hadUpdate
end

local function delayed_init() -- These are variables that need to be delayed because blizzard variables need to be loaded first
	if isNotDefined(SpellCreatorMasterTable.Options.sparkKeybind) then
		ns.UI.SparkPopups.SparkPopups.setSparkDefaultKeybind()
	end
end

ns.SavedVariables = {
	init = init,
	delayed_init = delayed_init,
	getProfileNames = getProfileNames,
	getDefaultProfile = getDefaultProfile,
	setDefaultProfile = setDefaultProfile,

	unlocks = {
		isUnlocked = isUnlocked,
		unlock = unlock,
		clearUnlock = clearUnlock,
		isUnlockedByKeyOrTime = isUnlockedByKeyOrTime,
	},
}
