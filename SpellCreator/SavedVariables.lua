local addonName = ...
---@class ns
local ns = select(2, ...)

local DataUtils = ns.Utils.Data
local Vault = ns.Vault
local Constants = ns.Constants

local isNotDefined = DataUtils.isNotDefined

local addonVersion = GetAddOnMetadata(addonName, "Version")

SpellCreatorMasterTable = {}
SpellCreatorMasterTable.Options = {}
SpellCreatorMasterTable.quickCastSpells = {}

SpellCreatorCharacterTable = {}

SpellCreatorMasterTable.quickcast = {}
---@class QCSavedBooks
---@field savedBookTable table<QuickcastBook, QuickcastPage[]>
SpellCreatorMasterTable.quickcast.books = {}

---@return DefaultProfileOption
local function getDefaultProfile()
	return SpellCreatorMasterTable.Options.defaultProfile
end

---@param defaultProfile DefaultProfileOption
local function setDefaultProfile(defaultProfile)
	SpellCreatorMasterTable.Options.defaultProfile = defaultProfile
end

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
	if isNotDefined(SpellCreatorMasterTable.quickcast.shownByChar[Constants.CHARACTER_NAME]) then SpellCreatorMasterTable.quickcast.shownByChar[Constants.CHARACTER_NAME] = { [string.format(Constants.DEFAULT_QC_BOOK_NAME
			, 1)] = true }
	end
	--if isNotDefined(SpellCreatorMasterTable.quickcastBooks) then SpellCreatorMasterTable.quickcastBooks = {} end

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

	if isNotDefined(SpellCreatorCharacterTable.phaseArcVars) then SpellCreatorCharacterTable.phaseArcVars = {} end
	ns.API.retargetPhaseArcVarTable(SpellCreatorCharacterTable.phaseArcVars)

	lastAddonVersion = SpellCreatorMasterTable.Options["lastAddonVersion"] or "0"
	hadUpdate = (addonVersion ~= lastAddonVersion)

	SpellCreatorMasterTable.Options["lastAddonVersion"] = addonVersion

	if not SpellCreatorSavedSpells then
		SpellCreatorSavedSpells = {}
	end

	-- reset these so we are not caching debug data longer than a single reload.
	SpellCreatorMasterTable.Options["debugPhaseData"] = nil
	SpellCreatorMasterTable.Options["debugPhaseKeys"] = nil

	return hadUpdate
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

ns.SavedVariables = {
	init = init,
	getProfileNames = getProfileNames,
	getDefaultProfile = getDefaultProfile,
	setDefaultProfile = setDefaultProfile,
}
