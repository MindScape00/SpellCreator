---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local ProfileFilter = ns.ProfileFilter
local SavedVariables = ns.SavedVariables
local VaultFilter = ns.VaultFilter

local ADDON_COLORS = Constants.ADDON_COLORS

local onProfileFilterChanged = VaultFilter.onProfileFilterChanged
local regenProfileFilterDropdown

---@param profile DefaultProfileOption
local function setDefaultProfile(self, profile)
	SavedVariables.setDefaultProfile(profile)
end

---@param profile DefaultProfileOption
---@param currentDefaultProfile DefaultProfileOption
---@return MenuItem
local function createDefaultProfileMenuListItem(profile, currentDefaultProfile)
	local isCurrent = currentDefaultProfile == profile

	return {
		text = profile,
		isNotRadio = isCurrent,
		checked = isCurrent,
		notClickable = isCurrent,
		disablecolor = (isCurrent and ADDON_COLORS.MENU_SELECTED:GenerateHexColorMarkup() or nil),
		arg1= profile,
		func = setDefaultProfile,
	}
end

---@return MenuItem[]
local function genChangeDefaultProfileDropDown()
	local currentDefault = SpellCreatorMasterTable.Options.defaultProfile
	return {
		{
			text = "Change Default Profile",
			notCheckable = true,
			isTitle=true,
		},
		{
			notCheckable = true,
			isTitle=true,
		},
		createDefaultProfileMenuListItem("Account", currentDefault),
		createDefaultProfileMenuListItem("Character", currentDefault),
		createDefaultProfileMenuListItem("All", currentDefault)
	}
end

---@param arg1 function
local function selectProfile(self, arg1, arg2, checked)
	local profileName
	if self.value then
		profileName = self.value
	else
		profileName = self
	end
	if checked or checked == false then
		ProfileFilter.toggleFilter(profileName, checked)
	else
		ProfileFilter.toggleFilter(profileName, not ProfileFilter.isShown(profileName))
	end
	ProfileFilter.toggleShowAll(nil)
	arg1();
end

---@param text string
---@param filteredEnabled boolean
---@return MenuItem
local function genFilterItem(text, filteredEnabled)
	return {
		text = text,
		isNotRadio=true,
		checked = (filteredEnabled or ProfileFilter.isAllShown()),
		keepShownOnClick = true,
		arg1 = onProfileFilterChanged,
		func = selectProfile,
	}
end

---@return MenuItem
local function genDivider()
	return {
		text = "----",
		notCheckable = true,
		disabled = true,
		justifyH = "CENTER",
	}
end

---@return MenuItem
local function genShowAllItem()
	return {
		text = "Show All",
		notCheckable = true,
		fontObject = GameFontNormalSmallLeft,
		func = function()
			ProfileFilter.enableAll()
			regenProfileFilterDropdown()
			onProfileFilterChanged()
		end,
	}
end

---@return MenuItem
local function genResetItem()
	return {
		text = "Reset",
		notCheckable = true,
		fontObject = GameFontNormalSmallLeft,
		func = function()
			ProfileFilter.reset()
			regenProfileFilterDropdown()
			onProfileFilterChanged()
		end,
	}
end

---@return MenuItem[]
local function genProfileFilterDropDown()
	local playerName = GetUnitName("player")
	local isNotAllChecked
	local menuList = {
		{
			text = "Select Profiles to Show",
			notCheckable = true,
			isTitle = true,
		},
		genFilterItem("Account", ProfileFilter.isAccountShown()),
		genFilterItem(playerName, ProfileFilter.isPlayerShown()),
	}

	local profileNames = SavedVariables.getProfileNames(true, true)
	sort(profileNames)

	for _, profileName in ipairs(profileNames) do
		if not ProfileFilter.isShown(profileName) then
			isNotAllChecked = true
		end
		menuList[#menuList + 1] = genFilterItem(profileName, ProfileFilter.isShown(profileName))
	end

	menuList[#menuList + 1] = genDivider()

	if isNotAllChecked and (not ProfileFilter.isAllShown()) then
		menuList[#menuList + 1] = genShowAllItem()
	else
		menuList[#menuList + 1] = genResetItem()
	end

	return menuList
end

regenProfileFilterDropdown = function()
	EasyMenu(genProfileFilterDropDown(), ARCProfileContextMenu, SCForgeMainFrame.LoadSpellFrame.profileButton, 0 , 0, "DROPDOWN"); -- that global ARCProfileContextMenu gets defined later, but still before we'll ever call this..
end

---@class UI_ProfileFilterMenu
ns.UI.ProfileFilterMenu = {
	genChangeDefaultProfileDropDown = genChangeDefaultProfileDropDown,
	genProfileFilterDropDown = genProfileFilterDropDown,
}
