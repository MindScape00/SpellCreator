---@class ns
local ns = select(2, ...)

local ProfileFilter = ns.ProfileFilter
local SavedVariables = ns.SavedVariables

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
		disablecolor = (isCurrent and ns.Constants.ADDON_COLORS.MENU_SELECTED:GenerateHexColorMarkup() or nil),
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
---@param updateUICallback function
---@return MenuItem
local function genFilterItem(text, filteredEnabled, updateUICallback)
	return {
		text = text,
		isNotRadio=true,
		checked = (filteredEnabled or ProfileFilter.isAllShown()),
		keepShownOnClick = true,
		arg1 = updateUICallback,
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

---@param updateUICallback function
---@return MenuItem
local function genShowAllItem(updateUICallback)
	return {
		text = "Show All",
		notCheckable = true,
		fontObject = GameFontNormalSmallLeft,
		func = function()
			ProfileFilter.enableAll()
			updateUICallback()
		end,
	}
end

---@param updateUICallback function
---@return MenuItem
local function genResetItem(updateUICallback)
	return {
		text = "Reset",
		notCheckable = true,
		fontObject = GameFontNormalSmallLeft,
		func = function()
			ProfileFilter.reset()
			updateUICallback()
		end,
	}
end

---@param updateUICallback function
---@return MenuItem[]
local function genProfileFilterDropDown(updateUICallback)
	local playerName = GetUnitName("player")
	local isNotAllChecked
	local menuList = {
		{
			text = "Select Profiles to Show",
			notCheckable = true,
			isTitle = true,
		},
		genFilterItem("Account", ProfileFilter.isAccountShown(), updateUICallback),
		genFilterItem(playerName, ProfileFilter.isPlayerShown(), updateUICallback),
	}

	local profileNames = SavedVariables.getProfileNames(true, true)
	sort(profileNames)

	for _, profileName in ipairs(profileNames) do
		if not ProfileFilter.isShown(profileName) then
			isNotAllChecked = true
		end
		menuList[#menuList + 1] = genFilterItem(profileName, ProfileFilter.isShown(profileName), updateUICallback)
	end

	menuList[#menuList + 1] = genDivider()

	if isNotAllChecked and (not ProfileFilter.isAllShown()) then
		menuList[#menuList + 1] = genShowAllItem(updateUICallback)
	else
		menuList[#menuList + 1] = genResetItem(updateUICallback)
	end

	return menuList
end


---@class UI_ProfileFilterMenu
ns.UI.ProfileFilterMenu = {
	genChangeDefaultProfileDropDown = genChangeDefaultProfileDropDown,
	genProfileFilterDropDown = genProfileFilterDropDown,
}
