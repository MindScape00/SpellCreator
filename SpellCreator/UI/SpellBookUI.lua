---@class ns
local ns = select(2, ...)

local SKILL_LINE_TAB = MAX_SKILLLINE_TABS - 1
local SPELL_BOOK_TAB = 5
local MaxSpellBookTypes = 5

local Constants = ns.Constants
local Cooldowns = ns.Actions.Cooldowns
local Execute = ns.Actions.Execute
local Gossip = ns.Gossip
local Hotkeys = ns.Actions.Hotkeys
local Logging = ns.Logging
local Permissions = ns.Permissions
local UIHelpers = ns.Utils.UIHelpers
local Vault = ns.Vault

local DataUtils = ns.Utils.Data
local Tooltip = ns.Utils.Tooltip

local ChatLink = ns.UI.ChatLink
local Dropdown = ns.UI.Dropdown
local LoadSpellFrame = ns.UI.LoadSpellFrame
local Icons = ns.UI.Icons
local Popups = ns.UI.Popups

local ADDON_COLORS = Constants.ADDON_COLORS
local ASSETS_PATH = Constants.ASSETS_PATH
local VAULT_TYPE = Constants.VAULT_TYPE

local TAB_TEXTURE = ns.UI.Gems.gemPath("Violet")
local LEFT_BG_TEXTURE = GetFileIDFromPath("Interface\\Spellbook\\Spellbook-Page-1")
local RIGHT_BG_TEXTURE = GetFileIDFromPath("Interface\\Spellbook\\Spellbook-Page-2")
local FULL_BG_TEXTURE = UIHelpers.getAddonAssetFilePath("spellbook-page-arcanum")

-- Create the main frame we will show ontop of the Spell Book, made to look like another spellbook page
local mainFrame = CreateFrame("FRAME", "Arcanum_SpellBook", SpellBookFrame)
mainFrame:SetPoint("TOPLEFT", SpellBookFrame, "TOPLEFT", 0, 0)
mainFrame:SetPoint("BOTTOMRIGHT", SpellBookFrame, "BOTTOMRIGHT", 0, 0)
mainFrame:SetFrameStrata("MEDIUM")
mainFrame:SetFrameLevel(200)
--mainFrame:EnableMouse(true)
mainFrame:Hide()

-- create the texture for the background
local background = mainFrame:CreateTexture(nil, "ARTWORK")
background:SetTexture(FULL_BG_TEXTURE)
background:SetPoint("TOPLEFT", 7, -25)
background:SetPoint("TOPRIGHT", -10, -25)

-- create the holder frame of our spell icons & page data
local spellIconsFrame = CreateFrame("Frame", nil, mainFrame)
mainFrame.iconsFrame = spellIconsFrame
spellIconsFrame:SetAllPoints(mainFrame)
--spellIconsFrame:EnableMouse(true)

spellIconsFrame.maxPages = 1
spellIconsFrame.currentPage = 1

local prevButton = CreateFrame("Button", nil, mainFrame)
prevButton:SetSize(32, 32)
prevButton:SetPoint("BOTTOMRIGHT", -66, 26)
prevButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
prevButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
prevButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
prevButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
--OnClick set later

local nextButton = CreateFrame("Button", nil, mainFrame)
nextButton:SetSize(32, 32)
nextButton:SetPoint("BOTTOMRIGHT", -31, 26)
nextButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
nextButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
nextButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
nextButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
--OnClick set later

local pageText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontBlack")
pageText:SetJustifyH("RIGHT")
pageText:SetSize(102, 0)
pageText:SetPoint("BOTTOMRIGHT", -110, 38)
--pageText:SetTextColor(0.25, 0.12, 0, 1)
pageText:SetTextColor(ADDON_COLORS.LIGHT_BLUE_ALMOST_WHITE:GetRGB())
pageText:SetText("Page 1")

--[[ -- Simple Open Forge Button, deprecated
local openForgeButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
openForgeButton:SetText("Open Forge")
openForgeButton:SetSize(100, 22)
openForgeButton:SetPoint("RIGHT", SpellBookPrevPageButton, "LEFT", -320, 0)
openForgeButton.tooltipText = "Open the Spell Forge Interface to Create & Edit Spells."
openForgeButton:SetScript("OnClick", function()
	ns.MainFuncs.scforge_showhide()
end)
--]]

local buttonSize = 32
local openForgeButton = CreateFrame("Button", nil, mainFrame)
openForgeButton:SetSize(buttonSize, buttonSize * 2)
openForgeButton:SetPoint("BOTTOMLEFT", 27, 30)
openForgeButton:SetScript("OnClick", function()
	ns.MainFuncs.scforge_showhide()
end)

openForgeButton.iconArea = CreateFrame("Frame", nil, openForgeButton)
openForgeButton.iconArea:SetFrameLevel(openForgeButton:GetFrameLevel() - 1)
openForgeButton.iconArea:SetPoint("TOPLEFT")
openForgeButton.iconArea:SetSize(buttonSize, buttonSize)
openForgeButton.iconArea.icon = openForgeButton.iconArea:CreateTexture(nil, "OVERLAY", nil, -1)
openForgeButton.iconArea.icon:SetAllPoints()
ns.UI.Portrait.createGemPortraitOnFrame(openForgeButton.iconArea.icon, openForgeButton.iconArea)
local runeX, runeY = openForgeButton.iconArea.icon.rune:GetSize()
openForgeButton.iconArea.icon.rune:SetSize((runeX / 61) * buttonSize, (runeY / 61) * buttonSize) -- fix rune scaling since it's setup only for the size of a real portrait hah

openForgeButton.iconArea:EnableMouse(false)
openForgeButton.iconArea.icon.Model:EnableMouse(false)

UIHelpers.setupCoherentButtonTextures(openForgeButton, UIHelpers.getAddonAssetFilePath("icon_portrait_gold_ring_border"), false)
openForgeButton.normal = openForgeButton:GetNormalTexture()
openForgeButton.pushed = openForgeButton:GetPushedTexture()
openForgeButton.normal:SetAllPoints(openForgeButton.iconArea)
openForgeButton.pushed:SetAllPoints(openForgeButton.iconArea)

openForgeButton:SetHighlightAtlas("Artifacts-PerkRing-Highlight")
openForgeButton.highlight = openForgeButton:GetHighlightTexture()
openForgeButton.highlight:SetAllPoints(openForgeButton.iconArea)

openForgeButton.Text = openForgeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
openForgeButton:SetFontString(openForgeButton.Text)
openForgeButton.Text:SetPoint("TOP", openForgeButton.iconArea, "BOTTOM", 0, -2)
openForgeButton.Text:SetTextColor(ADDON_COLORS.LIGHT_BLUE_ALMOST_WHITE:GetRGB())
openForgeButton:SetText("Open\nForge")
openForgeButton:SetPushedTextOffset(0, 0) -- looks weird when the text spasms

mainFrame.OpenForgeButton = openForgeButton

local mainFrameMouseBlocker = CreateFrame("FRAME", nil, mainFrame)
mainFrame.mouseBlocker = mainFrameMouseBlocker
mainFrameMouseBlocker:SetPoint("TOPLEFT", 7, -25)
mainFrameMouseBlocker:SetPoint("BOTTOMRIGHT", -10, 5)
mainFrameMouseBlocker:EnableMouse(true)

-- holding table for our buttons to easier iterate them
local arcSpellFrameButtons = {}
local lastOddButton -- easier memory of the last odd button for positioning

-- default mixin for easier creation of buttons that all do the same stuff
local spellButtonMixin = {}
spellButtonMixin.OnEnter = function() end
spellButtonMixin.OnLeave = function() end
spellButtonMixin.OnEvent = function() end
spellButtonMixin.PreClick = function(self)
	self:SetChecked(false)
end
spellButtonMixin.OnClick = function(self, button)
	if not self.commID then
		SCForgeMainFrame:Show()
		local resetUI = ns.MainFuncs.resetEditorUI
		if not ns.UI.Popups.checkAndShowResetForgeConfirmation("reset", resetUI, SCForgeMainFrame.ResetUIButton) then
			resetUI(SCForgeMainFrame.ResetUIButton)
		end
		return
	end

	local spell = Vault.personal.findSpellByID(self.commID)
	if not spell then return Logging.eprint("OnClick - No spell found with commID in personal vault: ", self.commID) end

	if button == "LeftButton" then
		if IsModifiedClick("CHATLINK") then
			ChatLink.linkSpell(spell, VAULT_TYPE.PERSONAL)
			return;
		end
		ARC:CAST(self.commID)
	end
end
spellButtonMixin.OnDragStart = function() end
spellButtonMixin.OnDragStop = function() end
spellButtonMixin.OnReceiveDrag = function() end
spellButtonMixin.UpdateCooldown = function(self)
	local cooldown = self.cooldown;
	local commID = self.commID

	local remainingTime, cooldownTime = Cooldowns.isSpellOnCooldown(commID)
	if remainingTime then
		self.cooldown:SetCooldown(GetTime() - (cooldownTime - remainingTime), cooldownTime)
	else
		self.cooldown:Clear()
	end


	--[[ -- blizzard's cooldown updater, but idk if this is needed, or we can use the easier SetCooldown & Clear? hm..
	if (commID) then
		local start, duration, enable, modRate = GetSpellCooldown(slot, SpellBookFrame.bookType);
		if (cooldown and start and duration) then
			if (enable) then
				cooldown:Hide();
			else
				cooldown:Show();
			end
			CooldownFrame_Set(cooldown, start, duration, enable, false, modRate);
		else
			cooldown:Hide();
		end
	end
	--]]
end
spellButtonMixin.UpdateButton = function(self)
	local iconTexture = _G[self:GetName() .. "IconTexture"]
	local slotFrameTexture = _G[self:GetName() .. "SlotFrame"]

	if self.commID then
		local spell = Vault.personal.findSpellByID(self.commID)
		if not spell then Logging.eprint("UpdateButton - No spell found with commID in personal vault: ", self.commID) end

		--icon
		iconTexture:SetTexture(Icons.getFinalIcon(spell.icon))
		iconTexture:Show()
		slotFrameTexture:Show()

		self.SpellName:SetText(spell.fullName); self.SpellName:Show()
		self.SpellSubName:SetText(spell.commID); self.SpellSubName:Show()
		self:Enable()
		self:UpdateCooldown()
	else
		if self.id == 1 or arcSpellFrameButtons[self.id - 1].commID then
			-- no spell, but first ID, or the button before this has a spell - let's show a fun "Create Spell" button here instead!
			self:Enable()
			slotFrameTexture:Show()
			iconTexture:Show()
			iconTexture:SetAtlas("communities-chat-icon-plus")
			self.SpellName:Show()
			self.SpellName:SetText("Create New Spell")
			self.SpellSubName:SetText()
			self.SpellSubName:Hide()
		else
			self:Disable()
			slotFrameTexture:Hide()
			iconTexture:Hide()
			self.SpellSubName:Hide()
			self.SpellName:Hide()
		end
	end
end

-- helper function for the tooltip when you mouse-over a spell icon
local function genSpellTooltipLines(spell, isClickable)
	local strings = {}
	local hotkeyKey = Hotkeys.getHotkeyByCommID(spell.commID)

	if spell.description then tinsert(strings, spell.description) end
	tinsert(strings, " ")

	if spell.profile then tinsert(strings, Tooltip.createDoubleLine("Profile: ", spell.profile)) end

	if spell.cooldown then
		tinsert(strings, Tooltip.createDoubleLine("Actions: " .. #spell.actions, "Cooldown: " .. spell.cooldown .. "s"))
	else
		tinsert(strings, "Actions: " .. #spell.actions)
	end

	if spell.author then tinsert(strings, "Author: " .. spell.author); end
	if spell.items and next(spell.items) then tinsert(strings, "Items: " .. table.concat(spell.items, ", ")) end
	if hotkeyKey then tinsert(strings, "Hotkey: " .. hotkeyKey) end
	tinsert(strings, " ")

	if isClickable then
		tinsert(strings, Tooltip.genContrastText("Left-Click") .. " to cast " .. ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode(spell.commID))
	else
		tinsert(strings, "Command: " .. Tooltip.genContrastText("/sf " .. spell.commID))
	end
	return strings
end

-- create the spell buttons!
for i = 1, SPELLS_PER_PAGE do
	local spellButton = CreateFrame("CheckButton", "Arcanum_SpellBook_SpellButton" .. i, spellIconsFrame, "ArcanumSpellButtonTemplate")
	spellButton.id = i
	if i == 1 then
		spellButton:SetPoint("TOPLEFT", 100, -72)
		spellButton.commID = "drunk"
		lastOddButton = spellButton
	elseif (i % 2 == 0) then
		-- number is even
		spellButton:SetPoint("TOPLEFT", lastOddButton, "TOPLEFT", 225, 0)
	else
		-- number is odd
		spellButton:SetPoint("TOPLEFT", lastOddButton, "BOTTOMLEFT", 0, -29)
		lastOddButton = spellButton
	end
	if i == SPELLS_PER_PAGE then
		-- last button, trash our variable
		lastOddButton = nil
	end

	spellButton.TextBackground:SetPoint("TOPLEFT", spellButton.EmptySlot, "TOPRIGHT", -4, -5)
	spellButton.TextBackground2:SetPoint("TOPLEFT", spellButton.EmptySlot, "TOPRIGHT", -4, -5)

	local remapTextures = {
		"EmptySlot", "TextBackground", "TextBackground2", "UnlearnedFrame", "TrainFrame", "TrainTextBackground"
	}
	for k, v in ipairs(remapTextures) do
		spellButton[v]:SetTexture(UIHelpers.getAddonAssetFilePath("spellbook-parts-arcanum"))
	end

	local remapByNameTextures = {
		"SlotFrame",
	}
	for k, v in ipairs(remapByNameTextures) do
		_G[spellButton:GetName() .. v]:SetTexture(UIHelpers.getAddonAssetFilePath("spellbook-parts-arcanum"))
	end

	spellButton.SpellName:SetPoint("LEFT", spellButton, "RIGHT", 8, 3); -- Blizzard moves theres from the default of y-offset 0 to 4 for some reason. I can't decide which looks better.
	spellButton.SpellSubName:SetTextColor(ADDON_COLORS.LIGHT_BLUE_ALMOST_WHITE:GetRGB())
	spellButton.TextBackground:SetAlpha(0.75)
	spellButton.TextBackground2:SetAlpha(0.0)

	Mixin(spellButton, spellButtonMixin)
	for k, v in pairs(spellButtonMixin) do
		if spellButton:HasScript(k) then
			spellButton:SetScript(k, spellButton[k])
		end
	end

	local getSpell = Vault.personal.findSpellByID
	ns.Utils.Tooltip.set(
		spellButton,
		function(self)
			return getSpell(self.commID).fullName
		end,
		function(self)
			local spell = getSpell(self.commID)
			local strings = genSpellTooltipLines(spell, true)
			tinsert(strings, Tooltip.genContrastText("Shift-Click") .. " to link in chat.")
			return strings
		end,
		{
			-- we expect a tooltip on the spell even if tooltips are disabled
			forced = true,
			delay = 0,
			predicate = function(self) return self.commID end, -- make sure we have a commID to use lol
		}
	)

	ns.UI.ActionButton.makeButtonDraggableToActionBar(spellButton, spellButton.Icon)

	tinsert(arcSpellFrameButtons, spellButton)
end

local function updateButtons()
	for k, v in ipairs(arcSpellFrameButtons) do
		local spellIDs = ns.Vault.personal.getIDs()
		table.sort(spellIDs, DataUtils.caseInsensitiveCompare)

		local pageOffset = (12 * (spellIconsFrame.currentPage - 1))
		local commID = spellIDs[k + pageOffset]
		v.commID = commID
		v:UpdateButton()
	end
end

local function updatePage()
	local spellIDs = ns.Vault.personal.getIDs()
	local numSpells = #spellIDs
	spellIconsFrame.maxPages = ceil(numSpells / SPELLS_PER_PAGE)

	do
		local maxPages = spellIconsFrame.maxPages
		local currentPage = spellIconsFrame.currentPage

		if (maxPages == nil or maxPages == 0) then
			return;
		end
		if (currentPage > maxPages) then
			currentPage = maxPages;
		end
		if (currentPage == 1) then
			prevButton:Disable();
		else
			prevButton:Enable();
		end
		if (currentPage == maxPages) then
			nextButton:Disable();
		else
			nextButton:Enable();
		end
		pageText:SetText("Page " .. currentPage .. " / " .. maxPages);
	end

	updateButtons()
end

local function prevButtonOnClick(self)
	spellIconsFrame.currentPage = spellIconsFrame.currentPage - 1
	updatePage()
end
local function nextButtonOnClick(self)
	spellIconsFrame.currentPage = spellIconsFrame.currentPage + 1
	updatePage()
end
prevButton:SetScript("OnClick", prevButtonOnClick)
nextButton:SetScript("OnClick", nextButtonOnClick)

local function OnMouseWheel(self, value, scrollBar)
	--do nothing if not on an appropriate book type
	local currentPage = spellIconsFrame.currentPage
	local maxPages = spellIconsFrame.maxPages

	if (value > 0) then
		if (currentPage > 1) then
			prevButtonOnClick()
		end
	else
		if (currentPage < maxPages) then
			nextButtonOnClick()
		end
	end
end
mainFrame:SetScript("OnMouseWheel", OnMouseWheel)

mainFrame:SetScript("OnShow", function()
	updatePage()
end)

--[[
local skillLineTab = _G["SpellBookSkillLineTab" .. SKILL_LINE_TAB]
hooksecurefunc("SpellBookFrame_UpdateSkillLineTabs", function()
	skillLineTab:SetNormalTexture(TAB_TEXTURE)
	skillLineTab.tooltip = "Arcanum Spell Vault"
	skillLineTab:Show()
	if (SpellBookFrame.selectedSkillLine == SKILL_LINE_TAB) then
		skillLineTab:SetChecked(true)
		mainFrame:Show()
	else
		skillLineTab:SetChecked(false)
		mainFrame:Hide()
	end
end)
--]]



local customTabButton = CreateFrame("Button", "Arcanum_SpellBook_TabButton", SpellBookFrame, "SpellBookFrameTabButtonTemplate")
customTabButton:SetPoint("TOPRIGHT", SpellBookFrame, "BOTTOMRIGHT", 0, 2)
customTabButton:Show()
customTabButton:SetText( ns.Utils.UIHelpers.CreateSimpleTextureMarkup(TAB_TEXTURE, 20) .. " Arcanum")

local function showArcSpellBook()
	if not SpellBookFrame:IsShown() then 
		ShowUIPanel(SpellBookFrame);
	end
	mainFrame:Show()
	PanelTemplates_TabResize(customTabButton, 0, nil, 40);
	if mainFrame:IsShown() then
		PanelTemplates_SelectTab(customTabButton)
		SpellBookFrame.currentTab = customTabButton

		for i = 1, MaxSpellBookTypes do
			local tab = _G["SpellBookFrameTabButton" .. i];
			PanelTemplates_TabResize(tab, 0, nil, 40);
			PanelTemplates_DeselectTab(tab);
		end
	else
		PanelTemplates_DeselectTab(customTabButton)
	end
end

customTabButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText("Arcanum Spellbook", 1.0,1.0,1.0 );
end)
customTabButton:SetScript("OnClick", function(self)
	self:Disable();
	if SpellBookFrame.currentTab then
		SpellBookFrame.currentTab:Enable();
	end
	SpellBookFrame.currentTab = self;
	showArcSpellBook()
end)

hooksecurefunc("SpellBookFrame_Update", function()
	mainFrame:Hide()
	PanelTemplates_DeselectTab(customTabButton);
	--[[
	PanelTemplates_TabResize(customTabButton, 0, nil, 40);
	if mainFrame:IsShown() then
		PanelTemplates_SelectTab(customTabButton)
		SpellBookFrame.currentTab = customTabButton

		for i = 1, MaxSpellBookTypes do
			local tab = _G["SpellBookFrameTabButton" .. i];
			PanelTemplates_TabResize(tab, 0, nil, 40);
			PanelTemplates_DeselectTab(tab);
		end
	else
		PanelTemplates_DeselectTab(customTabButton)
	end
	--]]
end)

local function updateArcSpellBook()
	if mainFrame:IsShown() then
		updatePage()
	end
end

---@class UI_SpellBookUI
ns.UI.SpellBookUI = {
	updateArcSpellBook = updateArcSpellBook,
	updateButtons = updateButtons,

	open = showArcSpellBook,
}
