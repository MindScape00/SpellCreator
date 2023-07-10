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

local orderGroup = 0
local orderItem = 0
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

local COLORS = Constants.ADDON_COLORS

local WhatIs__ = [[
Arcanum is a UI for creating timed macros, similar to using /in, but with a UI & extra features, such as easy sharing, Gossip integration, Pop-up Buttons, and more!

Arcanum allows you to easily create timed-sequences of 'actions'. Actions can range from casting default spells, performing animations/emotes, and even spawning game objects - technically speaking, there's almost no limit to what actions can be!
]]

local shiftSprintDesc = [[
- Ditch the macros & stop typing '.mod speed'! Tap or Hold SHIFT to start sprinting!
- Customize your Sprint to anything from a simple run, to an ominous hover, complete with Aura & Arcanum functionality.
- Set your speeds for ground, flight and swim separately, & switch between hold and toggle options!

]] .. COLORS.UPDATED:WrapTextInColorCode("TL;DR: Tap or Hold SHIFT to start sprinting! Use '/kn' to configure Sprint Speeds & Spells!")

local flightDesc = [[
- Double or triple Jump to enable/disable fly mode, also complete with Aura/Arcanum functionality!
- Complete with auto-land to disable flying, you can customize how long it takes before auto-land takes effect - or disable it entirely!
- Customize how fast your double/triple jumps will need to connect to enable/disable flight.

]] .. COLORS.UPDATED:WrapTextInColorCode("TL;DR: Double/Triple Jump to Fly, Double/Triple Jump again to land! Use '/kn' to configure Flight Toggle customization options & Spells!")

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
							get = function() return "https://forums.epsilonwow.net/topic/3413-addon-arcanum-spell-forge-user-guide/" end,
							set = function() end,
						},
						spacer = spacer(),
						buildersHaven = {
							type = "input",
							name = "Builder's Haven",
							dialogControl = "SFX-Info-URL",
							order = autoOrder(),
							get = function() return "https://discord.com/channels/718813797611208788/1031832007031930880/1032773498600439898" end,
							set = function() end,
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
ACD:SetDefaultSize(addonName .. "-Welcome", 600, 620)

local function showWelcomeScreen(showChangelog)
	ACD:Open(addonName .. "-Welcome")
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
