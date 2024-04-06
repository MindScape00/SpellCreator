---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local ProfileFilter = ns.ProfileFilter
local SavedVariables = ns.SavedVariables
local VaultFilter = ns.VaultFilter

local Dropdown = ns.UI.Dropdown

local ADDON_COLORS = Constants.ADDON_COLORS

local changeDefaultProfileMenu
local PLAYER_NAME = Constants.CHARACTER_NAME --[[@as string]]
local onProfileFilterChanged = VaultFilter.onProfileFilterChanged

---@param profile DefaultProfileOption
---@return DropdownItem
local function createDefaultProfileMenuListItem(profile)
	return Dropdown.radio(profile, {
		get = function()
			return SavedVariables.getDefaultProfile() == profile
		end,
		set = function()
			SavedVariables.setDefaultProfile(profile)
		end,
	})
end

---@return DropdownItem[]
local function createChangeDefaultProfileMenu()
	if not changeDefaultProfileMenu then
		changeDefaultProfileMenu = {
			Dropdown.header("Change Default Profile"),
			createDefaultProfileMenuListItem("Account"),
			createDefaultProfileMenuListItem("Character"),
			createDefaultProfileMenuListItem("All")
		}
	end
	return changeDefaultProfileMenu
end

---@return DropdownItem
local function genToggleAllItem()
	return Dropdown.execute(
		function()
			local name = not ProfileFilter.isAllEnabled() and "Show All" or "Reset"
			return ADDON_COLORS.GAME_GOLD:WrapTextInColorCode(name)
		end,
		function()
			if not ProfileFilter.isAllEnabled() then
				ProfileFilter.enableAll()
			else
				ProfileFilter.reset()
			end

			onProfileFilterChanged()
		end,
		{
			keepShownOnClick = true,
		}
	)
end

---@param profileName string
---@return DropdownItem
local function genFilterItem(profileName)
	return Dropdown.checkbox(profileName, {
		get = function()
			return ProfileFilter.isShown(profileName)
		end,
		set = function(self, value)
			ProfileFilter.toggleFilter(profileName, value)
			onProfileFilterChanged()
		end,
	})
end

---@param profileNames string[]
---@return DropdownItem[]
local function getMenuItems(profileNames)
	local items = {
		Dropdown.header("Select Profiles to Show"),
		genFilterItem("Account"),
		genFilterItem(PLAYER_NAME),
	}

	for _, profileName in ipairs(profileNames) do
		tinsert(items, genFilterItem(profileName))
	end

	tinsert(items, Dropdown.divider())
	tinsert(items, genToggleAllItem())

	return items
end

---@return string[]
local function getProfileNames()
	local profileNames = SavedVariables.getProfileNames(true, true)
	sort(profileNames)
	return profileNames
end

---@return DropdownItem[]
local function createProfileFilterMenu()
	local profileNames = getProfileNames()

	return getMenuItems(profileNames)
end

---@class UI_ProfileFilterMenu
ns.UI.ProfileFilterMenu = {
	createChangeDefaultProfileMenu = createChangeDefaultProfileMenu,
	createProfileFilterMenu = createProfileFilterMenu,
}
