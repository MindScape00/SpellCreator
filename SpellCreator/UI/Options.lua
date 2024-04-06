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
--[=[
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

	-- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
	scrollFrame.scrollChild = CreateFrame("SimpleHTML")

	local scrollChild = scrollFrame.scrollChild
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
--]=]

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

local function inlineHeader(text)
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
		order = order or autoOrder(),
		fontSize = size or "medium",
	}
	return item
end

local function divider(order)
	local item = {
		name = " ",
		type = "header",
		order = order or autoOrder(),
	}
	return item
end

--[[ -- Prep for a Book Manager table. This needs to be switched to a AceGUI instead though?
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
				optionsHeader = {
					name = "Options",
					type = "header",
					order = autoOrder(),
				},
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
					set = function(info, val)
						genericSet(info, val,
							function()
								Popups.showCustomGenericConfirmation(
									{
										text = "A UI Reload is Required to change any current input boxes.\n\rReload Now?\n\r" ..
											Tooltip.genTooltipText("warning", "All un-saved data in the Forge will be wiped.\r"),
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
			name = "Quickcast & Spark Settings",
			type = "group",
			order = autoOrder(true),
			args = {
				qcheader = {
					name = "Quickcast",
					type = "header",
					order = autoOrder(),
				},
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
					desc =
					"Overscrolling allows you to scroll past the first/last page in a Quickcast Book, looping back to the other side.\n\rIf disabled, when you reach the first/last page, you cannot scroll any further.",
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
				spacer1 = spacer(autoOrder(), "large"),
				sparkheader = {
					name = "Sparks",
					type = "header",
					order = autoOrder(),
				},
				showSparkManagerUI = {
					name = "Spark Manager",
					order = autoOrder(),
					disabled = function() return not (ns.Permissions.isOfficerPlus() or SpellCreatorMasterTable.Options["debug"]) end,
					type = "execute",
					func = function(info)
						ns.UI.SparkPopups.SparkManagerUI.showSparkManagerUI()
					end,
				},
				exportCurrentPhaseSparks = {
					name = "Export Sparks",
					desc = "Export Sparks from the current Phase to a copyable text string, so you can back them up or copy to another phase.",
					disabled = function() return not (ns.Permissions.isOfficerPlus() or SpellCreatorMasterTable.Options["debug"]) end,
					order = autoOrder(),
					type = "execute",
					func = function(info)
						ns.UI.ImportExport.exportAllSparks()
					end,
				},
				importSparksToCurrentPhase = {
					name = "Import Sparks",
					desc = "Import Sparks to the current Phase.\n\r" .. Tooltip.genTooltipText("warning", "This will overwrite any sparks currently in the phase."),
					disabled = function() return not ns.Permissions.isOfficerPlus() end,
					order = autoOrder(),
					type = "execute",
					func = function(info)
						ns.UI.ImportExport.showImportSparksMenu()
					end,
				},
				sparkClickKeybind = {
					type = "keybinding",
					name = "Activate Spark Keybind",
					desc =
					"When set, this key can be used to activate a currently shown Spark via the keypress instead of clicking with the mouse. This will override any other bindings on this key, until you unset it. Once unset, your original keybind will be returned.\n\rDefault: F",
					get = function() return ns.UI.SparkPopups.SparkPopups.getSparkKeybind() end,
					set = function(info, val)
						ns.UI.SparkPopups.SparkPopups.setSparkKeybind(val)
					end,
					order = autoOrder(),
				},
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
					name = inlineHeader("Version: ") .. addonVersion,
					type = "description",
					order = autoOrder(),
					fontSize = "large",
				},
				author = {
					name = inlineHeader("Author: ") .. addonAuthor,
					type = "description",
					order = autoOrder(),
					fontSize = "large",
				},
				credits = {
					name = inlineHeader("Credits: ") .. addonCredits,
					type = "description",
					order = autoOrder(),
					fontSize = "large",
				},
				spacer1 = spacer(autoOrder(), "large"),
				changeLogText = {
					name = inlineHeader("Show Changelog: "),
					type = "description",
					order = autoOrder(),
					fontSize = "large",
				},
				showChangelog = {
					name = "Show Changelog",
					type = "execute",
					func = function()
						ns.UI.WelcomeUI.WelcomeMenu.showWelcomeScreen(true)
						--changelogFrame:SetShown(not changelogFrame:IsShown());
						--changelogFrame:Raise()
					end,
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
				spacer3 = spacer(autoOrder()),
				toggleDebugTableInspector = {
					name = "Debug Table Window",
					order = autoOrder(),
					desc = "Toggle Debug Table Window when Debug Dumps occur. Debug Mode must be one for this to have any effect.",
					type = "toggle",
					width = 1.5,
					arg = "debugTableInspector",
					set = genericSet,
					get = genericGet,
				},
				toolSpacer = spacer(),
				miscToolsHeader = {
					name = "Miscellaneous Tools",
					type = "header",
					order = autoOrder(),
				},
				refreshActionBars = {
					name = "Refresh Action Bars",
					order = autoOrder(),
					desc =
					"Refreshes your Arcanum Action Button Overrides from your saved cache.\n\rThis should only be used if your Action Bars did not load the Arcanum Spells onto them when reloading/logging in.",
					type = "execute",
					func = ns.UI.ActionButton.loadActionButtonsFromRegister,
					width = 1,
				},
				dataSalvager = {
					name = "Data Salvager",
					order = autoOrder(),
					desc =
					"Show a large edit box with Data Salvaging Tools to convert exported Arc data to readable format.",
					type = "execute",
					func = ns.UI.DataSalvager.showSalvagerMenu,
					width = 1,
				},
			},
		},
	}
}

local function newOptionsInit()
	Libs.AceConfig:RegisterOptionsTable(ADDON_TITLE, myOptionsTable)
	local frame = Libs.AceConfigDialog:AddToBlizOptions(ADDON_TITLE, ADDON_TITLE)
	myOptionsExtraTable.theFrame = frame
	--genChangelogScrollFrame(changelogFrame)
end

---@class UI_Options
ns.UI.Options = {
	--createSpellCreatorInterfaceOptions = createSpellCreatorInterfaceOptions,
	newOptionsInit = newOptionsInit,
	--changelogFrame = changelogFrame,
}
