---@class ns
local ns = select(2, ...)
local addonName = ...

local Constants = ns.Constants
local ADDON_TITLE = Constants.ADDON_TITLE
local HTML = ns.Utils.HTML
local MinimapButton = ns.UI.MinimapButton
local Quickcast = ns.UI.Quickcast
local cprint, dprint, eprint = ns.Logging.cprint, ns.Logging.dprint, ns.Logging.eprint
local Tooltip = ns.Utils.Tooltip

local addonVersion, addonAuthor = GetAddOnMetadata(addonName, "Version"), GetAddOnMetadata(addonName, "Author")

-------------------------------------------------------------------------------
-- Interface Options - Addon section
-------------------------------------------------------------------------------

local function createSpellCreatorInterfaceOptions()
	SpellCreatorInterfaceOptions = {};
	SpellCreatorInterfaceOptions.panel = CreateFrame( "Frame", "SpellCreatorInterfaceOptionsPanel", UIParent );
	SpellCreatorInterfaceOptions.panel.name = ADDON_TITLE;

	local SpellCreatorInterfaceOptionsHeader = SpellCreatorInterfaceOptions.panel:CreateFontString("HeaderString", "OVERLAY", "GameFontNormalLarge")
	SpellCreatorInterfaceOptionsHeader:SetPoint("TOPLEFT", 15, -15)
	SpellCreatorInterfaceOptionsHeader:SetText(ADDON_TITLE.." v"..addonVersion.." by "..addonAuthor)


	SpellCreatorInterfaceOptions.panel.scrollFrame = CreateFrame("ScrollFrame", nil, SpellCreatorInterfaceOptions.panel, "UIPanelScrollFrameTemplate")
	local scrollFrame = SpellCreatorInterfaceOptions.panel.scrollFrame
		scrollFrame:SetPoint("TOPLEFT", 20, -160)
		scrollFrame:SetPoint("BOTTOMRIGHT", -35, 25)

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

		scrollFrame.Title = scrollFrame.backdrop:CreateFontString(nil,'ARTWORK')
			scrollFrame.Title:SetFont(STANDARD_TEXT_FONT,12,'OUTLINE')
			scrollFrame.Title:SetTextColor(1,1,1)
			scrollFrame.Title:SetText("Spell Forge")
			scrollFrame.Title:SetPoint('TOP',scrollFrame.backdrop,0,5)

		scrollFrame.Title.Backdrop = scrollFrame.backdrop:CreateTexture(nil, "BORDER", nil, 6)
			scrollFrame.Title.Backdrop:SetColorTexture(0,0,0)
			scrollFrame.Title.Backdrop:SetPoint("CENTER", scrollFrame.Title, "CENTER", -1, -1)
			scrollFrame.Title.Backdrop:SetSize(scrollFrame.Title:GetWidth()-4, scrollFrame.Title:GetHeight()/2)

	-- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
	SpellCreatorInterfaceOptions.panel.scrollFrame.scrollChild = CreateFrame("SimpleHTML")
	local scrollChild = SpellCreatorInterfaceOptions.panel.scrollFrame.scrollChild
	scrollChild:SetWidth(InterfaceOptionsFramePanelContainer:GetWidth()-56)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetScript("OnHyperlinkClick", HTML.copyLink)
	scrollChild:SetFontObject("p", GameFontHighlight);
	scrollChild:SetFontObject("h1", GameFontNormalHuge2);
	scrollChild:SetFontObject("h2", GameFontNormalLarge);
	scrollChild:SetFontObject("h3", GameFontNormalMed2);
	scrollChild:SetText(HTML.stringToHTML(ns.ChangelogText));
	-- Add widgets to the scrolling child frame as desired


--[[  -- Testing/example to force the scroll frame to have a bunch to scroll
	local footer = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	footer:SetPoint("TOP", 0, -5000)
	footer:SetText("This is 5000 below the top, so the scrollChild automatically expanded.")
--]]

	local function genOptionsCheckbutton(buttonData, parent)

		--[[
		local buttonData = {
		["anchor"] = {point = , relativeTo = , relativePoint = , x = , y = ,},
		["title"] = ,
		["tooltipTitle"] = ,
		["tooltipText"] = ,
		["optionKey"] = ,
		["onClickHandler"] = , -- extra OnClick function
		["customOnLoad"] = , -- extra OnLoad function
		}
		--]]
		local button = CreateFrame("CHECKBUTTON", nil, parent, "InterfaceOptionsCheckButtonTemplate")
		if buttonData.anchor.relativePoint then
			button:SetPoint(buttonData.anchor.point, buttonData.anchor.relativeTo, buttonData.anchor.relativePoint, buttonData.anchor.x, buttonData.anchor.y)
		else
			button:SetPoint(buttonData.anchor.point, buttonData.anchor.x, buttonData.anchor.y)
		end
		button.Text:SetText(buttonData.title)
		button:SetScript("OnShow", function(self)
			if SpellCreatorMasterTable.Options[buttonData.optionKey] == true then
				self:SetChecked(true)
			else
				self:SetChecked(false)
			end
		end)
		button:SetScript("OnClick", function(self)
			SpellCreatorMasterTable.Options[buttonData.optionKey] = not SpellCreatorMasterTable.Options[buttonData.optionKey]
			if buttonData.onClickHandler then buttonData.onClickHandler(button); end
		end)

		button._tooltipTitle = buttonData.tooltipTitle
		button._tooltipText = buttonData.tooltipText
		Tooltip.set(button, function(self) return self._tooltipTitle end, function(self) return self._tooltipText end)

		if SpellCreatorMasterTable.Options[buttonData.optionKey] == true then -- handle default checking of the box
			button:SetChecked(true)
		else
			button:SetChecked(false)
		end
		if buttonData.customOnLoad then buttonData.customOnLoad(); end
		button:SetMotionScriptsWhileDisabled(true)

		return button;
	end

	--Minimap Icon Toggle
	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = nil, relativePoint = nil, x = 20, y = -40,},
		["title"] = "Enable Minimap Button",
		["tooltipTitle"] = "Enable Minimap Button",
		["tooltipText"] = nil,
		["optionKey"] = "minimapIcon",
		["onClickHandler"] = function(self) if SpellCreatorMasterTable.Options["minimapIcon"] then MinimapButton.setShown(true) else MinimapButton.setShown(false) end end,
		}
	SpellCreatorInterfaceOptions.panel.MinimapIconToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.MinimapIconToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -3,},
		["title"] = "Use Larger Scrollable Input Box",
		["tooltipTitle"] = "Use Larger Input Box.",
		["tooltipText"] = "Switches the 'Input' entry box with a larger, scrollable editbox.\n\rRequires /reload to take affect after changing it.",
		["optionKey"] = "biggerInputBox",
		["onClickHandler"] = function() StaticPopup_Show("SCFORGE_RELOADUI_REQUIRED") end,
		}
	SpellCreatorInterfaceOptions.panel.BiggerInputBoxToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.BiggerInputBoxToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -3,},
		["title"] = "AutoShow Vault",
		["tooltipTitle"] = "AutpShow Vault",
		["tooltipText"] = "Automatically show the Vault when you open the Forge.",
		["optionKey"] = "showVaultOnShow",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.showVaultToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.showVaultToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -3,},
		["title"] = "Enable QuickCast Book",
		["tooltipTitle"] = "Enable the QuickCast Book",
		["tooltipText"] = "You can assign ArcSpells to Quickcast from your vault, and cast them quickly using the Quickcast Book on your screen.",
		["optionKey"] = "quickcastToggle",
		["onClickHandler"] = function(self) if SpellCreatorMasterTable.Options["quickcastToggle"] then Quickcast.setShown(true) else Quickcast.setShown(false) end end,
		}
	SpellCreatorInterfaceOptions.panel.MinimapIconToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	--[[
	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.showVaultToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -5,},
		["title"] = "Clear Action Data when Removing Row",
		["tooltipTitle"] = "Clear Action Data when Removing Row",
		["tooltipText"] = "When an Action Row is removed using the |cffFFAAAA—|r button, the data is wiped. If off, you can use the |cff00AAFF+|r button and the data will still be there again.",
		["optionKey"] = "clearRowOnRemove",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.clearRowOnRemoveToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)
	--]]

	local buttonData = {
		["anchor"] = {point = "TOP", relativeTo = nil, relativePoint = nil, x = 20, y = -40,},
		["title"] = "Load Actions Chronologically",
		["tooltipTitle"] = "Load Chronologically by Delay",
		["tooltipText"] = "When loading a spell, actions will be loaded in order of their delays, despite the order they were saved in.",
		["optionKey"] = "loadChronologically",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.loadChronologicallyToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.loadChronologicallyToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -3,},
		["title"] = "A future option",
		["tooltipTitle"] = "Something later",
		["tooltipText"] = "This used to the the fast reset toggle, but it was already fast enough, so we got rid of it. TBD what we add here next!",
		["optionKey"] = "idkyet",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.fastResetToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)
	SpellCreatorInterfaceOptions.panel.fastResetToggle:Disable()

	local buttonData = {
		["anchor"] = {point = "TOPLEFT", relativeTo = SpellCreatorInterfaceOptions.panel.fastResetToggle, relativePoint = "BOTTOMLEFT", x = 0, y = -3,},
		["title"] = "Show Tooltips",
		["tooltipTitle"] = "Show Tooltips",
		["tooltipText"] = "Show Tooltips when you mouse-over UI elements like buttons, editboxes, and spells in the vault, just like this one!\nYou can't currently toggle these off, maybe later.",
		["optionKey"] = "showTooltips",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.showTooltipsToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	-- UAC Control - Not in line with the rest, in the bottom left
	local buttonData = {
		["anchor"] = {point = "BOTTOMLEFT", relativeTo = SpellCreatorInterfaceOptions.panel, relativePoint = "BOTTOMLEFT", x = 0, y = 0,},
		["title"] = "Disable UAC",
		["tooltipTitle"] = "Disable UAC",
		["tooltipText"] = "Disables the User Arcanum Control security feature\n\rWARNING: ArcSpells can run scripts & commands, which may be malicious, automatically in some situations, like opening an NPC gossip, or activating a GOb tele. Disabling UAC accepts the risks involved.",
		["optionKey"] = "disableUAC",
		["onClickHandler"] = nil,
		}
	SpellCreatorInterfaceOptions.panel.showTooltipsToggle = genOptionsCheckbutton(buttonData, SpellCreatorInterfaceOptions.panel)

	-- Debug Checkbox
	local SpellCreatorInterfaceOptionsDebug = CreateFrame("CHECKBUTTON", "SC_DebugToggleOption", SpellCreatorInterfaceOptions.panel, "OptionsSmallCheckButtonTemplate")
	SpellCreatorInterfaceOptionsDebug:SetPoint("BOTTOMRIGHT", 0, 0)
	SpellCreatorInterfaceOptionsDebug:SetHitRectInsets(-35,0,0,0)
	SpellCreatorInterfaceOptionsDebug.Text = SC_DebugToggleOptionText -- This is defined by $parentText and is never made a child by the template, smfh, so it's a defined global when the frame is created.
	SpellCreatorInterfaceOptionsDebug.Text:SetTextColor(1,1,1,1)
	SpellCreatorInterfaceOptionsDebug.Text:SetText("Debug")
	SpellCreatorInterfaceOptionsDebug.Text:SetPoint("LEFT", -30, 0)
	SpellCreatorInterfaceOptionsDebug:SetScript("OnShow", function(self)
		if SpellCreatorMasterTable.Options["debug"] == true then SpellCreatorInterfaceOptionsDebug:SetChecked(true) else SpellCreatorInterfaceOptionsDebug:SetChecked(false) end
	end)
	SpellCreatorInterfaceOptionsDebug:SetScript("OnClick", function(self)
		SpellCreatorMasterTable.Options["debug"] = not SpellCreatorMasterTable.Options["debug"]
		if SpellCreatorMasterTable.Options["debug"] then
			cprint("Toggled Debug (VERBOSE) Mode")
		end
	end)

	InterfaceOptions_AddCategory(SpellCreatorInterfaceOptions.panel);
	if SpellCreatorMasterTable.Options["debug"] == true then SpellCreatorInterfaceOptionsDebug:SetChecked(true) else SpellCreatorInterfaceOptionsDebug:SetChecked(false) end
end


---@class UI_Options
ns.UI.Options = {
	createSpellCreatorInterfaceOptions = createSpellCreatorInterfaceOptions
}
