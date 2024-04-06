---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local ProfileFilter = ns.ProfileFilter
local SavedVariables = ns.SavedVariables
local Tooltip = ns.Utils.Tooltip

local Dropdown = ns.UI.Dropdown

local ADDON_COLORS = Constants.ADDON_COLORS
local DEFAULT_PROFILE_NAME = ProfileFilter.DEFAULT_PROFILE_NAME

local markEditorUnsaved
local profileDropdown
local PLAYER_NAME = UnitName("player") --[[@as string]]

---@return string profileName
local function getSelectedProfile()
	return profileDropdown.Text:GetText()
end

---@param profileName? string
local function setSelectedProfile(profileName)
	if not profileName then
		profileName = DEFAULT_PROFILE_NAME
	end

	profileDropdown.Text:SetText(profileName)
	markEditorUnsaved()
end

---@param profileName string
---@return DropdownItem
local function genFilterItem(profileName)
	return Dropdown.radio(profileName, {
		get = function()
			return getSelectedProfile() == profileName
		end,
		set = function()
			setSelectedProfile(profileName)
		end,
	})
end

---@param profileNames string[]
---@return DropdownItem[]
local function createMenu(profileNames)
	local dropdownItems = {
		Dropdown.header("Select a Profile"),
		genFilterItem("Account"),
		genFilterItem(PLAYER_NAME),
	}

	for _, profileName in ipairs(profileNames) do
		tinsert(dropdownItems, genFilterItem(profileName))
	end

	tinsert(dropdownItems, Dropdown.input(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Add New"), {
		tooltipTitle = "New Profile",
		tooltipText = "Set the spell you are currently editing to a new profile when saved.\n\r" ..
			Tooltip.genTooltipText("norevert", "Profiles added here will not show in menus until the spell is created/saved."),
		placeholder = "New Profile Name",
		get = function() end,
		set = function(self, text)
			setSelectedProfile(text)
		end,
	}))

	return dropdownItems
end

---@return string[]
local function getProfileNames()
	local profileNames = SavedVariables.getProfileNames(true, true)
	sort(SavedVariables.getProfileNames(true, true))
	return profileNames
end

---@param inject { mainFrame: SCForgeMainFrame, markEditorUnsaved: fun() }
local function createDropdown(inject)
	markEditorUnsaved = inject.markEditorUnsaved

	profileDropdown = Dropdown.create(inject.mainFrame, "SCForgeAtticProfileButton"):WithAppearance(75)
	profileDropdown:SetPoint("BOTTOMRIGHT", inject.mainFrame.Inset, "TOPRIGHT", 16, 0)
	profileDropdown:SetText(DEFAULT_PROFILE_NAME)

	profileDropdown.Button:SetScript("OnClick", function(self)
		Dropdown.open(createMenu(getProfileNames()), profileDropdown)
	end)

	-- Fixes error when opening, clicking outside, then opening again
	profileDropdown.Button:SetScript("OnMouseDown", nil)


	Tooltip.set(profileDropdown.Button,
		"Assign Profile",
		"Assign this spell to the selected profile when created or saved.",
		{ delay = 0.3 }
	)

	return profileDropdown
end

---@class UI_MainFrame_AtticProfileDropdown
ns.UI.MainFrame.AtticProfileDropdown = {
	createDropdown = createDropdown,
	getSelectedProfile = getSelectedProfile,
	setSelectedProfile = setSelectedProfile,
}
