---@class ns
local ns = select(2, ...)
local addonName = ...

local Constants = ns.Constants

--local addonVersion, addonAuthor, addonTitle = Constants.addonVersion, Constants.addonAuthor, Constants.addonTitle
local addonVersion, addonAuthor, addonTitle = GetAddOnMetadata(addonName, "Version"), GetAddOnMetadata(addonName, "Author"), GetAddOnMetadata(addonName, "Title")
local addonCredits = GetAddOnMetadata(addonName, "X-Credits")

local Libs = ns.Libs
local AC = Libs.AceConfig
local ACD = Libs.AceConfigDialog
local AceGUI = Libs.AceGUI

local COLORS = Constants.ADDON_COLORS

local Shared = ns.UI.WelcomeUI.Shared

-- -- -- -- -- -- -- -- -- -- -- --
-- Helper Functions
-- -- -- -- -- -- -- -- -- -- -- --

local orderGroup = 0
local orderItem = 0
---Auto incrementing order number. Use isGroup true to increment the orderGroup and reset the orderItem counter. Only use on top level groups (ignoring root).
---@param isGroup boolean?
---@return integer
local function autoOrder(isGroup)
	if isGroup then
		orderGroup = orderGroup + 1
		orderItem = 0
		return orderGroup
	else
		orderItem = orderItem + 1
		return orderItem
	end
end

local function spacer(width)
	local item = {
		name = "",
		type = "description",
		order = autoOrder(),
		width = width or nil
	}
	return item
end

local function divider(order)
	local item = {
		name = "",
		type = "header",
		order = order,
	}
	return item
end

-- Get Function
local function getArgFunc(Info)
	return Info.arg
end

-- Set Function
local function setNullFunc() end

local function credLine(text)
	local line = {
		type = "input",
		name = "",
		--desc = "Tooltip",
		arg = text,
		get = getArgFunc,
		set = setNullFunc,
		order = autoOrder(),
		disabled = true,
		dialogControl = "SFX-Info",
	}
	return line
end

-- -- -- -- -- -- -- -- -- -- -- --
-- Menu Data / Options Table
-- -- -- -- -- -- -- -- -- -- -- --

local width = Shared.width
local height = Shared.height

local WhatIs__ = [[
Arcanum is a UI for creating timed sequences, similar to making macros using /in, but with a UI & extra features, such as easy sharing, Gossip & Item integration, Pop-up Buttons, and  way, way more!

Arcanum allows you to easily create timed-sequences of 'actions'. Actions can range from casting default spells, performing animations/emotes, and even spawning game objects - technically speaking, there's almost no limit to what actions can be - if an AddOn, Script, or Command can do it, it can be put into an ArcSpell!
]]

local welcomeMenu = {
	name = "Welcome to Arcanum!" .. " (v" .. addonVersion .. ")",
	type = "group",
	childGroups = "tab",
	args = {
		welcomeTab = {
			type = "group",
			name = "Welcome!",
			order = autoOrder(true),
			args = {
				overview = {
					name = "What is Arcanum?",
					type = "group",
					inline = true,
					order = autoOrder(),
					args = {
						addonDesc = {
							type = "description",
							fontSize = "medium",
							name = WhatIs__,
							order = autoOrder(),
						},
					},
				},
				links = {
					name = "User Guides",
					type = "group",
					inline = true,
					order = autoOrder(),
					args = {
						forums = {
							type = "input",
							name = "Epsilon Forums",
							dialogControl = "SFX-Info-URL",
							order = autoOrder(),
							arg = "https://forums.epsilonwow.net/topic/3413-addon-arcanum-spell-forge-user-guide/",
							get = getArgFunc,
							set = setNullFunc,
						},
						spacer = spacer(),
						buildersHaven = {
							type = "input",
							name = "Builder's Haven",
							dialogControl = "SFX-Info-URL",
							order = autoOrder(),
							arg = "https://discord.com/channels/718813797611208788/1031832007031930880/1032773498600439898",
							get = getArgFunc,
							set = setNullFunc,
						},
						API_Wiki = {
							type = "input",
							name = "Arcanum Wiki",
							dialogControl = "SFX-Info-URL",
							order = autoOrder(),
							arg = "https://github.com/MindScape00/SpellCreator/wiki",
							get = getArgFunc,
							set = setNullFunc,
						},
					},
				},
				creditsRows = {
					type = "input",
					name = "Credits",
					--desc = "Tooltip",
					arg = "MindScape (|cff5865F2@mindscape|r)",
					get = getArgFunc,
					set = setNullFunc,
					order = autoOrder(),
					disabled = true,
					dialogControl = "SFX-Info",
				},
				cred1 = credLine("'T' (|cff5865F2@ajt|r) - Artwork, Assets, Ideas, and Inspiration"),
				cred2 = credLine("Iyadriel (|cff5865F2@iyadriel|r) - Coding & Support"),
				cred3 = credLine("skylar (|cff5865F2@sunkencastles|r) - IconPicker & ExtraButtons borrowed from DiceMaster, & Support"),
				spacer1 = spacer(),
				cred4 = credLine("Thank you to Azarchius & Razmatas for Epsilon, and Executable / Server support!"),
				spacer2 = spacer(),
				cred5 = credLine("|cff57F287And thank YOU, the players of Epsilon, for being the drive behind this server, community, and the amazing things you have, and will, create.|r")

			},
		},
		changelogTab = {
			type = "group",
			name = "Changelog",
			childGroups = "tree",
			order = autoOrder(true),
			args = ns.UI.WelcomeUI.ChangelogMenu.genChangeLogArgs(), -- generated in Changelog.lua! Edit there!
		},
	},
}
AC:RegisterOptionsTable(addonName .. "-Welcome", welcomeMenu)
ACD:SetDefaultSize(addonName .. "-Welcome", width, height)

-- -- -- -- -- -- -- -- -- -- -- --
-- Control Functions
-- -- -- -- -- -- -- -- -- -- -- --

local function showWelcomeScreen(showChangelog)
	local self = ACD
	local f
	local appName = addonName .. "-Welcome"
	if not self.OpenFrames[appName] then
		f = AceGUI:Create("Frame")
		self.OpenFrames[appName] = f
	else
		f = self.OpenFrames[appName]
	end
	f:ReleaseChildren()
	f:SetCallback("OnClose", function()
		local appName = f:GetUserData("appName")
		ACD.OpenFrames[appName] = nil
		AceGUI:Release(f)
	end)
	f:SetUserData("appName", appName)

	f:SetWidth(width)
	f:SetHeight(height)
	f:EnableResize(false)

	ACD:Open(addonName .. "-Welcome", f)
	if showChangelog then
		ACD:SelectGroup(addonName .. "-Welcome", "changelogTab")
	end
end
local function hideWelcomeScreen()
	ACD:Close(addonName .. "-Welcome")
end

---@class UI_WelcomeUI_WelcomeMenu
ns.UI.WelcomeUI.WelcomeMenu = {
	showWelcomeScreen = showWelcomeScreen,
	hideWelcomeScreen = hideWelcomeScreen,
}
