---@class ns
local ns = select(2, ...)
local addonName = ...

local Constants = ns.Constants
local ADDON_TITLE = Constants.ADDON_TITLE
local HTML = ns.Utils.HTML
local MinimapButton = ns.UI.MinimapButton
local Popups = ns.UI.Popups
local Quickcast = ns.UI.Quickcast
local Tooltip = ns.Utils.Tooltip

local Libs = ns.Libs
local AceConfig = Libs.AceConfig

local cprint = ns.Logging.cprint
local Debug = ns.Utils.Debug
local ddump = Debug.ddump

local addonVersion, addonAuthor = GetAddOnMetadata(addonName, "Version"), GetAddOnMetadata(addonName, "Author")
local addonCredits = GetAddOnMetadata(addonName, "X-Credits")

---------------------------
-- Changelog Frame
---------------------------
local changelogFrame = CreateFrame("FRAME", nil, UIParent)
changelogFrame:SetFrameStrata("DIALOG")
changelogFrame.border = CreateFrame("FRAME", nil, changelogFrame, "DialogBorderTranslucentTemplate")
changelogFrame.header = CreateFrame("FRAME", nil, changelogFrame, "DialogHeaderTemplate")
changelogFrame.header:Setup("Arcanum - Changelog")
changelogFrame.close = CreateFrame("Button", nil, changelogFrame, "UIPanelCloseButton")
changelogFrame.close:SetPoint("TOPRIGHT", -5.6, -4)
changelogFrame.close:SetSize(32, 32)
changelogFrame.close.border = changelogFrame.close:CreateTexture()
changelogFrame.close.border:SetTexture("Interface/DialogFrame/UI-DialogBox-Corner")
changelogFrame.close.border:SetPoint("TOPLEFT", -4, -4)
changelogFrame.close.border:SetPoint("BOTTOMRIGHT", -4, -4)
changelogFrame:SetPoint("CENTER")
changelogFrame:SetSize(622, 622)
changelogFrame:EnableMouse(true)
changelogFrame:Hide()

local function genChangelogScrollFrame(parent)
	local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 25, -32)
	scrollFrame:SetPoint("BOTTOMRIGHT", -35, 12)

	-- TODO : 9.2.7 : This frame needs to inherit BackdropTemplate in order to work // removed this anyways
	-- scrollFrame.backdrop = CreateFrame("FRAME", nil, scrollFrame, "BackdropTemplate")
	--[[
	scrollFrame.backdrop = CreateFrame("FRAME", nil, scrollFrame)
	scrollFrame.backdrop:SetPoint("TOPLEFT", scrollFrame, -15, 3)
	scrollFrame.backdrop:SetPoint("BOTTOMRIGHT", scrollFrame, 26, -3)
	scrollFrame.backdrop:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 14,
		insets = {
			left = 4,
			right = 4,
			top = 4,
			bottom = 4,
		},
	})
	scrollFrame.backdrop:SetBackdropColor(0, 0, 0, 0.25)
	scrollFrame.backdrop:SetFrameLevel(2)
	--]]

	--[[
	scrollFrame.Title = scrollFrame.backdrop:CreateFontString(nil, 'ARTWORK')
	scrollFrame.Title:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
	scrollFrame.Title:SetTextColor(1, 1, 1)
	scrollFrame.Title:SetText("Spell Forge")
	scrollFrame.Title:SetPoint('TOP', scrollFrame.backdrop, 0, 5)

	scrollFrame.Title.Backdrop = scrollFrame.backdrop:CreateTexture(nil, "BORDER", nil, 6)
	scrollFrame.Title.Backdrop:SetColorTexture(0, 0, 0)
	scrollFrame.Title.Backdrop:SetPoint("CENTER", scrollFrame.Title, "CENTER", -1, -1)
	scrollFrame.Title.Backdrop:SetSize(scrollFrame.Title:GetWidth() - 4, scrollFrame.Title:GetHeight() / 2)
	--]]

	-- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
	scrollFrame.scrollChild = CreateFrame("SimpleHTML")

	local scrollChild = scrollFrame.scrollChild
	--scrollChild:SetWidth(InterfaceOptionsFramePanelContainer:GetWidth() - 56)
	scrollChild:SetWidth(scrollFrame:GetWidth() - 5)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetScript("OnHyperlinkClick", HTML.copyLink)
	scrollChild:SetFontObject("p", GameFontHighlight);
	scrollChild:SetFontObject("h1", GameFontNormalHuge2);
	scrollChild:SetFontObject("h2", GameFontNormalLarge);
	scrollChild:SetFontObject("h3", GameFontNormalMed2);

	C_Timer.After(0, function() scrollChild:SetText(HTML.stringToHTML(ns.ChangelogText)); end) -- TODO: Check if this is efficient? For now I've wrapped it in a C_Timer because that no longer waits for the function to finish before continuing.

	--[[  -- Testing/example to force the scroll frame to have a bunch to scroll
	local footer = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	footer:SetPoint("TOP", 0, -5000)
	footer:SetText("This is 5000 below the top, so the scrollChild automatically expanded.")
	--]]
	return scrollFrame
end

-------------------------------------------------------------------------------
-- Interface Options - Addon section
-------------------------------------------------------------------------------

---@param info table
local function genericGet(info)
	local key = info.arg
	return SpellCreatorMasterTable.Options[key]
end

---@param info table
---@param val string|boolean
---@param func function callback function to add on after doing the set
local function genericSet(info, val, func)
	local key = info.arg
	SpellCreatorMasterTable.Options[key] = val
	if func then func(val) end
end

local function inlineHeadher(text)
	return WrapTextInColorCode(text, "ffFFD700")
end

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

local function spacer(order, size)
	local item = {
		name = " ",
		type = "description",
		order = order,
		fontSize = size or "medium",
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

--[[ -- Prep for a Boook Manager table. This needs to be switched to a AceGUI instead though?
local function genQuickcastSubTable(tableToInsert)
	for k, v in ipairs(ns.UI.Quickcast.Book.booksDB) do
		tableToInsert[k] = {
			name = v.name,
			type = "group",
			args = {},
		}
		for i = 1, #v._pages do
			local data = v._pages[i]
			tinsert(tableToInsert[k].args, {
				name = "Page " .. i .. data.profileName and "* (" .. data.profileName .. ")" or "",
				type = "execute",
				func = function() end,
			})
		end
	end
end
--]]

local myOptionsExtraTable = {}
local Dropdown = ns.UI.Dropdown

local myOptionsTable = {
	name = ADDON_TITLE .. " (v" .. addonVersion .. ")",
	type = "group",
	childGroups = "tab",
	args = {
		generalOptions = {
			name = "General Settings",
			type = "group",
			order = autoOrder(true),
			args = {
				enableMMButton = {
					name = "Enable Minimap Button",
					order = autoOrder(),
					desc = "Enables / disables the Minimap Button",
					type = "toggle",
					width = 1.5,
					arg = "minimapIcon",
					set = function(info, val) genericSet(info, val, function() MinimapButton.setShown(val) end) end,
					get = genericGet,
				},
				inputBoxSize = {
					name = "Use Larger Input Box",
					order = autoOrder(),
					desc = "Switches the 'Input' entry box with a larger, scrollable editbox.\n\rRequires /reload to take affect after changing it.",
					type = "toggle",
					width = 1.5,
					arg = "biggerInputBox",
					set = function(info, val) genericSet(info, val,
							function()
								Popups.showCustomGenericConfirmation(
									{
										text = "A UI Reload is Required to change any current input boxes.\n\rReload Now?\n\r" .. Tooltip.genTooltipText("warning", "All un-saved data in the Forge will be wiped.\r"),
										callback = function() ReloadUI(); end,
										showAlert = true,
									}
								)
							end)
					end,
					get = genericGet,
				},
				autoShowVault = {
					name = "AutoShow Vault",
					order = autoOrder(),
					desc = "Automatically show the Vault when you open the Forge.",
					type = "toggle",
					width = 1.5,
					arg = "showVaultOnShow",
					set = genericSet,
					get = genericGet,
				},
				showTooltips = {
					name = "Show Help Tooltips",
					order = autoOrder(),
					desc = "Show Helpful Tooltips when you mouse-over UI elements like buttons, editboxes, and spells in the vault, just like this one!",
					type = "toggle",
					width = 1.5,
					arg = "showTooltips",
					set = genericSet,
					get = genericGet,
				},
				loadChronologically = {
					name = "Load Actions Chronologically",
					order = autoOrder(),
					desc = "When loading a spell, actions will be loaded in order of their delays, despite the order they were saved in.",
					type = "toggle",
					width = 1.5,
					arg = "loadChronologically",
					set = genericSet,
					get = genericGet,
				},
			},
		},
		quickcastOptions = {
			name = "Quickcast Settings",
			type = "group",
			order = autoOrder(true),
			args = {
				keepOpen = {
					name = "Keep Quickcast Open after Casting",
					order = autoOrder(),
					desc = "Keeps the Quickcast ring open after casting a spell from it. Some might call it.. Quickquickcast!",
					type = "toggle",
					width = 1.5,
					arg = "keepQCOpen",
					set = genericSet,
					get = genericGet,
				},
				overscroll = {
					name = "Allow Overscrolling",
					order = autoOrder(),
					desc = "Overscrolling allows you to scroll past the first/last page in a Quickcast Book, looping back to the other side.\n\rIf disabled, when you reach the first/last page, you cannot scroll any further.",
					type = "toggle",
					width = 1.5,
					arg = "allowQCOverscrolling",
					set = genericSet,
					get = genericGet,
				},
				toggleQCBooks = {
					name = "Toggle QC Books",
					order = autoOrder(),
					type = "execute",
					func = function(info)
						local menuArgs = {}
						for i = 1, #Quickcast.Book.booksDB do
							local v = Quickcast.Book.booksDB[i]
							tinsert(menuArgs, Quickcast.ContextMenu.genShowBookItem(v))
						end
						Dropdown.open(menuArgs, Dropdown.genericDropdownHolder, "cursor", 0, 0, "MENU")
					end,
				},
				showQCManagerUI = {
					name = "Quickcast Manager",
					order = autoOrder(),
					type = "execute",
					func = function(info)
						ns.UI.Quickcast.ManagerUI.showQCManagerUI()
					end,
				},
				showSparkManagerUI = {
					name = "Spark Manager",
					order = autoOrder(),
					type = "execute",
					func = function(info)
						ns.UI.SparkPopups.SparkManagerUI.showSparkManagerUI()
					end,
				}
			},
		},
		aboutTab = {
			name = "About",
			type = "group",
			order = autoOrder(true),
			args = {
				header = {
					--name = function() genChangelogFrame(postLoadData.frame.obj.children[1].children[1].frame) end,
					name = ADDON_TITLE,
					type = "header",
					order = autoOrder(),

				},
				version = {
					name = inlineHeadher("Version: ") .. addonVersion,
					type = "description",
					order = autoOrder(),
					fontSize = "large",
				},
				author = {
					name = inlineHeadher("Author: ") .. addonAuthor,
					type = "description",
					order = autoOrder(),
					fontSize = "large",
				},
				credits = {
					name = inlineHeadher("Credits: ") .. addonCredits,
					type = "description",
					order = autoOrder(),
					fontSize = "large",
				},
				spacer1 = spacer(autoOrder(), "large"),
				changeLogText = {
					name = inlineHeadher("Show Changelog: "),
					type = "description",
					order = autoOrder(),
					fontSize = "large",
				},
				showChangelog = {
					name = "Show Changelog",
					type = "execute",
					func = function() changelogFrame:SetShown(not changelogFrame:IsShown()); changelogFrame:Raise() end,
					order = autoOrder(),
				},
				spacer2 = spacer(autoOrder()),
				toggleDebug = {
					name = "Debug",
					order = autoOrder(),
					desc = "Toggle Debug Mode",
					type = "toggle",
					width = 1.5,
					arg = "debug",
					set = genericSet,
					get = genericGet,
				},
			},
		},
	}
}

local function newOptionsInit()
	Libs.AceConfig:RegisterOptionsTable(ADDON_TITLE, myOptionsTable)
	local frame = Libs.AceConfigDialog:AddToBlizOptions(ADDON_TITLE, ADDON_TITLE)
	myOptionsExtraTable.theFrame = frame
	genChangelogScrollFrame(changelogFrame)
end

---@class UI_Options
ns.UI.Options = {
	--createSpellCreatorInterfaceOptions = createSpellCreatorInterfaceOptions,
	newOptionsInit = newOptionsInit,
	changelogFrame = changelogFrame,
}
