---@class ns
local ns = select(2, ...)

local DataUtils = ns.Utils.Data
local AceGUI = ns.Libs.AceGUI
local AceConfig = ns.Libs.AceConfig
local AceConfigDialog = ns.Libs.AceConfigDialog
local AceConfigRegistry = ns.Libs.AceConfigRegistry
local Quickcast = ns.UI.Quickcast
local Tooltip = ns.Utils.Tooltip
local Popups = ns.UI.Popups
local Dropdown = ns.UI.Dropdown

local ADDON_COLORS = ns.Constants.ADDON_COLORS

local cmd = ns.Cmd.cmd
local round = DataUtils.roundToNthDecimal
local orderedPairs = DataUtils.orderedPairs

--------------------------------
--- Ew, an AceGUI Powered UI
--------------------------------
local qcManagerUI

---@param bookIndex integer
---@return AceGUITreeGroup
local function genBookMangerBookItem(bookIndex)
	local book = Quickcast.Book.booksDB[bookIndex]
	local bookStyle = Quickcast.Style.BOOK_STYLE_DATA[book.savedData.style]

	return {
		text = "Book: " .. book.savedData.name,
		value = bookIndex,
		icon = (bookStyle.tex)
	}
end

local function getBookManagerBookTree()
	local qcManagerBookTree = {}
	local numBooks = Quickcast.Book.getNumBooks()
	for i = 1, numBooks do
		local bookItem = genBookMangerBookItem(i)
		tinsert(qcManagerBookTree, bookItem)
	end
	tinsert(qcManagerBookTree, {
		text = "Add New Book",
		value = -1,
		icon = "interface/paperdollinfoframe/character-plus",
	})
	return qcManagerBookTree
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Spells Manager (Edit Spells in a Page)
local showSpellsManager -- forward defined to use in genSpellManagerMenu to refresh easily
local refreshSpellsManager

local _spellManagerData = {}

---@param container AceGUIFrame
---@param isRefresh boolean?
local function genSpellManagerMenu(container, isRefresh)
	local page = _spellManagerData.thePageToEdit --[[@as QuickcastPage]]
	local bookIndex = _spellManagerData.bookIndex

	local _spells = page:GetSpells()
	local numSpells = #_spells

	local spellsScrollContainer = AceGUI:Create("InlineGroup")
	spellsScrollContainer:SetFullHeight(true)
	spellsScrollContainer:SetFullWidth(true)
	spellsScrollContainer:SetLayout("Fill")
	spellsScrollContainer:SetTitle("Spells in this Page")
	container:AddChild(spellsScrollContainer)

	local spellsScrollFrame = AceGUI:Create("ScrollFrame")
	spellsScrollFrame:SetLayout("List")
	spellsScrollContainer:AddChild(spellsScrollFrame)
	spellsScrollFrame:SetCallback("OnRelease", function(self, value)
		_spellManagerData.lastScrollVal = self.scrollbar:GetValue()
	end)
	if isRefresh then
		C_Timer.After(0, function()
			if _spellManagerData.lastScrollVal then
				spellsScrollFrame:SetScroll(_spellManagerData.lastScrollVal)
				spellsScrollFrame:FixScroll()
			end
		end)
	end

	if not page then
		local noPageLabel = AceGUI:Create("Label")
		noPageLabel:SetText("This page does not exist. Wtf?")
		noPageLabel:SetRelativeWidth(1)
		spellsScrollFrame:AddChild(noPageLabel)
		return
	end

	if numSpells == 0 or not _spells then
		local noSpellsLabel = AceGUI:Create("Label")
		noSpellsLabel:SetText("There are no Spells in this page.")
		noSpellsLabel:SetRelativeWidth(1)
		spellsScrollFrame:AddChild(noSpellsLabel)
		return
	end

	for i = 1, #_spells do
		local commID = _spells[i]
		local spellData = ns.Vault.personal.findSpellByID(commID)
		if spellData then
			local spellGroup = AceGUI:Create("InlineGroup")
			spellGroup:SetAutoAdjustHeight(false)
			spellGroup:SetLayout("Flow")
			spellGroup:SetFullWidth(true)
			spellGroup:SetHeight(82)
			spellGroup:SetTitle(spellData.fullName)
			spellsScrollFrame:AddChild(spellGroup)

			local spellIconSection = AceGUI:Create("SimpleGroup")
			spellIconSection:SetLayout("List")
			spellIconSection:SetRelativeWidth(0.15)
			spellGroup:AddChild(spellIconSection)

			do
				local spellIconLabel = AceGUI:Create("InteractiveLabel")
				spellIconLabel:SetImage(ns.UI.Icons.getFinalIcon(spellData.icon))
				spellIconLabel:SetImageSize(32, 32)
				spellIconLabel:SetRelativeWidth(1)
				spellIconSection:AddChild(spellIconLabel)

				Tooltip.setAceTT(
					spellIconLabel,
					function(self)
						return spellData.fullName
					end,
					function(self)
						local spell = spellData
						local strings = {}

						if spell.description then
							tinsert(strings, spell.description)
						end

						tinsert(strings, " ")

						if spell.cooldown then
							tinsert(strings, Tooltip.createDoubleLine("Actions: " .. #spell.actions, "Cooldown: " .. spell.cooldown .. "s"))
						else
							tinsert(strings, "Actions: " .. #spell.actions)
						end

						if spell.author and spell.profile then
							tinsert(strings, Tooltip.createDoubleLine("Author: " .. spell.author, "Profile: " .. spell.profile))
						elseif spell.author then
							tinsert(strings, "Author: " .. spell.author);
						elseif spell.profile then
							tinsert(strings, Tooltip.createDoubleLine(" ", "Profile: " .. spell.profile))
							--tinsert(strings, "Profile: " .. spell.profile);
						end

						return strings
					end,
					{
						-- we expect a tooltip on the spell even if tooltips are disabled
						forced = true
					}
				)
			end

			local spellInfoSection = AceGUI:Create("SimpleGroup")
			spellInfoSection:SetLayout("List")
			spellInfoSection:SetRelativeWidth(0.53)
			spellGroup:AddChild(spellInfoSection)

			do
				local spellNameLabel = AceGUI:Create("Label")
				spellNameLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Name: ") .. spellData.fullName)
				spellNameLabel:SetRelativeWidth(1)
				spellInfoSection:AddChild(spellNameLabel)

				local spellCommIDLabel = AceGUI:Create("Label")
				spellCommIDLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("CommID: ") .. spellData.commID)
				spellCommIDLabel:SetRelativeWidth(1)
				spellInfoSection:AddChild(spellCommIDLabel)
			end

			local removeButton = AceGUI:Create("Button")
			removeButton:SetText("Remove")
			--removeButton:SetRelativeWidth(0.60)
			removeButton:SetWidth(80)
			removeButton:SetHeight(32)
			removeButton:SetCallback("OnClick", function()
				if type(page.spells) ~= "table" then return end
				tremove(page.spells, i)
				refreshSpellsManager(container, page, bookIndex)
			end)
			Tooltip.setAceTT(removeButton, "Remove Spell from Page", "This will remove it from the Quickcast. The spell will remain in your vault.", { delay = 0.3 })
			spellGroup:AddChild(removeButton)

			local spellButtonsSection = AceGUI:Create("SimpleGroup")
			spellButtonsSection:SetLayout("Flow")
			--spellButtonsSection:SetRelativeWidth(0.1)
			spellButtonsSection:SetWidth(43)
			spellGroup:AddChild(spellButtonsSection)

			do
				local moveUpButton = AceGUI:Create("Button")
				moveUpButton:SetText(CreateTextureMarkup("Interface/Azerite/Azerite", 62 * 4, 44 * 4, 1.4, 0, 0.51953125, 0.76171875, 0.416015625, 0.373046875))
				--moveUpButton:SetRelativeWidth(0.4)
				moveUpButton:SetWidth(43)
				moveUpButton:SetHeight(16)
				moveUpButton:SetDisabled(i == 1 and true or false)
				moveUpButton:SetCallback("OnClick", function()
					page:ReorderSpell(i, i - 1)
					refreshSpellsManager(container, page, bookIndex)
				end)
				Tooltip.setAceTT(moveUpButton, "Move Spell Up", "This will re-arrange it's order in the Quickcast as well.", { delay = 0.3 })
				spellButtonsSection:AddChild(moveUpButton)

				local moveDownButton = AceGUI:Create("Button")
				moveDownButton:SetText(CreateAtlasMarkup("Azerite-PointingArrow"))
				--moveDownButton:SetRelativeWidth(0.4)
				moveDownButton:SetWidth(43)
				moveDownButton:SetHeight(16)
				moveDownButton:SetDisabled(i == numSpells and true or false)
				moveDownButton:SetCallback("OnClick", function()
					page:ReorderSpell(i, i + 1)
					refreshSpellsManager(container, page, bookIndex)
				end)
				Tooltip.setAceTT(moveDownButton, "Move Spell Down", "This will re-arrange it's order in the Quickcast as well.", { delay = 0.3 })
				spellButtonsSection:AddChild(moveDownButton)
			end
			spellGroup:DoLayout() -- fixes layouts that randomly break for no reason..
		end
	end
end

---Show the Spells Manager for a Page
---@param page QuickcastPage
---@param bookIndex integer? Book index to refresh
---@param isRefresh boolean?
showSpellsManager = function(page, bookIndex, isRefresh)
	_spellManagerData.thePageToEdit = page
	_spellManagerData.bookIndex = bookIndex

	local _spells = page:GetSpells()
	local numSpells = #_spells

	local spellManagerContainer = AceGUI:Create("Frame")
	spellManagerContainer:SetTitle("Arcanum - Page Spells Manager")
	spellManagerContainer:SetLayout("Flow")
	spellManagerContainer:SetWidth(500)
	spellManagerContainer:SetHeight(math.min(GetScreenHeight(), math.max(math.min(8 * 82, numSpells * 82), 5 * 82) + 105))
	spellManagerContainer:EnableResize(false)

	spellManagerContainer:SetCallback("OnClose", function(widget)
		if widget:GetUserData("isRefreshing") then
			AceGUI:Release(widget)
		else
			AceGUI:Release(widget)
			if qcManagerUI and qcManagerUI.IsShown and qcManagerUI:IsShown() then
				C_Timer.After(0, function() ns.UI.Quickcast.ManagerUI.showQCManagerUI(_spellManagerData.bookIndex) end)
			end
		end
	end)

	genSpellManagerMenu(spellManagerContainer, isRefresh)
end

refreshSpellsManager = function(container, page, bookIndex)
	container:SetUserData("isRefreshing", true)
	container:Release()
	showSpellsManager(page, bookIndex, true)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@param containerFrame AceGUIContainer
---@param bookIndex integer
---@param callback function
local function drawBookGroup(containerFrame, bookIndex, callback)
	if bookIndex == -1 then
		local numBooks = ns.UI.Quickcast.Book.getNumBooks()
		local newBook = ns.UI.Quickcast.Book.createBook(numBooks + 1)
		local newPage = ns.UI.Quickcast.Page.createPage(newBook)
		newBook:AddPage(newPage)
		newBook:GoToFirstPage()
		newBook:SetStyle(Quickcast.Style.BOOK_STYLE.DEFAULT)
		callback(numBooks + 1)
		return
	end

	local book = Quickcast.Book.booksDB[bookIndex]
	local bookStyleData = Quickcast.Style.getStyleData(book.savedData.style)
	local numPages = book:GetNumPages()
	local _pages = book.savedData._pages
	containerFrame.bookIndex = bookIndex

	-- Need to redraw again for when icon editbox/button are shown and hidden
	containerFrame:ReleaseChildren()

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- groupScrollContainer

	local groupScrollContainer = AceGUI:Create("SimpleGroup")
	groupScrollContainer:SetFullWidth(true)
	groupScrollContainer:SetFullHeight(true)
	groupScrollContainer:SetLayout("Fill")
	containerFrame:AddChild(groupScrollContainer)

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- groupScrollFrame

	local groupScrollFrame = AceGUI:Create("ScrollFrame")
	--groupScrollFrame:SetFullWidth(true)
	--groupScrollFrame:SetFullHeight(true)
	groupScrollFrame:SetLayout("List")
	groupScrollContainer:AddChild(groupScrollFrame)

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- gen our inline groups

	local bookDataGroup = AceGUI:Create("InlineGroup")
	bookDataGroup:SetLayout("Flow")
	bookDataGroup:SetRelativeWidth(1)
	bookDataGroup:SetTitle("Book: " .. book.savedData.name)
	groupScrollFrame:AddChild(bookDataGroup)

	do
		local styleSection = AceGUI:Create("SimpleGroup")
		styleSection:SetLayout("Fill")
		styleSection:SetFullHeight(true)
		styleSection:SetRelativeWidth(0.33)

		do
			local styleSelectButton = AceGUI:Create("MAW-Icon")
			styleSelectButton:SetLabel("Change Style")
			styleSelectButton:SetImage(bookStyleData.tex)
			--setupCoherentAceIconButtonTextures(styleSelectButton, bookStyleData.tex)

			styleSelectButton:SetCallback("OnClick", function()
				local menuList = {}
				for style in ipairs(Quickcast.Style.BOOK_STYLE_DATA) do
					menuList[style] = Quickcast.ContextMenu.genStyleItem(book, style)
				end
				Dropdown.open(menuList, Dropdown.genericDropdownHolder, "cursor")
			end)
			styleSection:AddChild(styleSelectButton)
		end
		bookDataGroup:AddChild(styleSection)

		local bookButtonsSection = AceGUI:Create("SimpleGroup")
		bookButtonsSection:SetLayout("List")
		bookButtonsSection:SetRelativeWidth(0.5)
		bookButtonsSection:SetFullHeight(true)

		do
			local renameButton = AceGUI:Create("Button")
			renameButton:SetText("Rename")
			renameButton:SetRelativeWidth(1)
			renameButton:SetCallback("OnClick", function()
				Popups.showCustomGenericInputBox({
					text = "Rename %s",
					text_arg1 = ADDON_COLORS.TOOLTIP_CONTRAST:WrapTextInColorCode(book.savedData.name),
					callback = function(text) book:SetName(text) end,
					inputText = book.savedData.name,
				})
			end)
			bookButtonsSection:AddChild(renameButton)

			local toggleVisButton = AceGUI:Create("Button")
			toggleVisButton:SetText(book:IsShown() and "Hide" or "Show")
			toggleVisButton:SetRelativeWidth(1)
			toggleVisButton:SetCallback("OnClick", function()
				book:ToggleVisible()
			end)
			bookButtonsSection:AddChild(toggleVisButton)

			local addPageButton = AceGUI:Create("Button")
			addPageButton:SetText("Add New Page")
			addPageButton:SetRelativeWidth(1)
			addPageButton:SetCallback("OnClick", function()
				local menuList = {
					Dropdown.execute("Create Standard Page", function()
						local page = ns.UI.Quickcast.Page.createPage(book, {})
						local newPageIndex = book:AddPage(page)
						book:GoToPageNumber(newPageIndex) -- more efficient than calling GoToPage by using the index directly
					end),
					Quickcast.ContextMenu.genDynamicPageMenu(book),
				}
				Dropdown.open(menuList, Dropdown.genericDropdownHolder, "cursor")
			end)
			bookButtonsSection:AddChild(addPageButton)

			local deleteBookButton = AceGUI:Create("Button")
			deleteBookButton:SetText("Delete")
			deleteBookButton:SetRelativeWidth(1)
			deleteBookButton:SetCallback("OnClick", function()
				Popups.showGenericConfirmation(
					("Are you sure you want to delete %s?"):format(ADDON_COLORS.TOOLTIP_CONTRAST:WrapTextInColorCode(book.savedData.name)),
					function()
						Quickcast.Book.deleteBook(book)
					end
				)
			end)
			bookButtonsSection:AddChild(deleteBookButton)
		end
		bookDataGroup:AddChild(bookButtonsSection)
	end

	local pagesScrollContainer = AceGUI:Create("InlineGroup")
	pagesScrollContainer:SetAutoAdjustHeight(false)
	pagesScrollContainer:SetHeight(275)
	--pagesScrollContainer:SetFullHeight(true) -- this doesn't work, manually set it instead...
	pagesScrollContainer:SetFullWidth(true)
	pagesScrollContainer:SetLayout("Fill")
	pagesScrollContainer:SetTitle("Pages")
	groupScrollFrame:AddChild(pagesScrollContainer)

	local pagesScrollFrame = AceGUI:Create("ScrollFrame")
	pagesScrollFrame:SetLayout("List")
	pagesScrollContainer:AddChild(pagesScrollFrame)

	if numPages == 0 or not _pages then
		local noPagesLabel = AceGUI:Create("Label")
		noPagesLabel:SetText("There are no Pages in this Book. Add a page above.")
		noPagesLabel:SetRelativeWidth(1)
		pagesScrollFrame:AddChild(noPagesLabel)
		return
	end

	for k, pageData in ipairs(_pages) do
		local isDynamicPage
		if pageData.profileName then isDynamicPage = true end

		local pageGroup = AceGUI:Create("InlineGroup")
		pageGroup:SetAutoAdjustHeight(false)
		pageGroup:SetLayout("Flow")
		pageGroup:SetFullWidth(true)
		pageGroup:SetHeight(90)
		pageGroup:SetTitle("Page " .. k)
		pagesScrollFrame:AddChild(pageGroup)

		local pageInfoSection = AceGUI:Create("SimpleGroup")
		pageInfoSection:SetLayout("List")
		pageInfoSection:SetRelativeWidth(0.33)
		pageGroup:AddChild(pageInfoSection)

		do
			local pageTypeLabel = AceGUI:Create("Label")
			pageTypeLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Type: ") .. (isDynamicPage and "Dynamic" or "Standard"))
			pageTypeLabel:SetRelativeWidth(1)
			pageInfoSection:AddChild(pageTypeLabel)

			if isDynamicPage then
				local dynamicProfileLabel = AceGUI:Create("Label")
				dynamicProfileLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Profile: ") .. pageData.profileName)
				dynamicProfileLabel:SetRelativeWidth(1)
				pageInfoSection:AddChild(dynamicProfileLabel)
			end

			local numSpellsLabel = AceGUI:Create("Label")
			numSpellsLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Spells: ") .. pageData:GetNumSpells())
			numSpellsLabel:SetRelativeWidth(1)
			pageInfoSection:AddChild(numSpellsLabel)
		end

		local pageButtonsSection = AceGUI:Create("SimpleGroup")
		pageButtonsSection:SetLayout("List")
		pageButtonsSection:SetRelativeWidth(0.3)
		pageGroup:AddChild(pageButtonsSection)

		do
			-- TODO: Add Spells Manager Menu
			local spellsButton = AceGUI:Create("Button")
			spellsButton:SetText("Spells")
			spellsButton:SetRelativeWidth(1)
			spellsButton:SetDisabled(isDynamicPage)
			spellsButton:SetCallback("OnClick", function() showSpellsManager(pageData, bookIndex) end)
			pageButtonsSection:AddChild(spellsButton)

			local deleteButton = AceGUI:Create("Button")
			deleteButton:SetText("Delete")
			deleteButton:SetRelativeWidth(1)
			deleteButton:SetCallback("OnClick", function()
				Quickcast.Book.deletePageFromBook(book, k)
			end)
			pageButtonsSection:AddChild(deleteButton)
		end

		local pageReorderButtonsSection = AceGUI:Create("SimpleGroup")
		pageReorderButtonsSection:SetLayout("List")
		pageReorderButtonsSection:SetRelativeWidth(0.3)
		pageGroup:AddChild(pageReorderButtonsSection)

		do
			local moveUpButton = AceGUI:Create("Button")
			moveUpButton:SetText(CreateTextureMarkup("Interface/Azerite/Azerite", 62 * 4, 44 * 4, 1.4, 0, 0.51953125, 0.76171875, 0.416015625, 0.373046875))
			moveUpButton:SetRelativeWidth(0.5)
			moveUpButton:SetDisabled(k == 1 and true or false)
			moveUpButton:SetCallback("OnClick", function()
				book:MovePage(k, k - 1)
			end)
			pageReorderButtonsSection:AddChild(moveUpButton)

			local moveDownButton = AceGUI:Create("Button")
			moveDownButton:SetText(CreateAtlasMarkup("Azerite-PointingArrow"))
			moveDownButton:SetRelativeWidth(0.5)
			moveDownButton:SetDisabled(k == numPages and true or false)
			moveDownButton:SetCallback("OnClick", function()
				book:MovePage(k, k + 1)
			end)
			pageReorderButtonsSection:AddChild(moveDownButton)
		end
		pageGroup:DoLayout() -- fixes layouts that randomly break for no reason..
	end
end

local function hideQCManagerUI()
	if qcManagerUI then qcManagerUI:Release() end
end

---@param bookIndexOverride integer|QuickcastBook? The Book Index to open the UI to
local function showQCManagerUI(bookIndexOverride)
	if qcManagerUI and qcManagerUI:IsShown() then hideQCManagerUI() end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("Arcanum - Quickcast Manager")
	frame:SetWidth(600)
	frame:SetHeight(525)
	frame:SetLayout("List")
	frame:SetCallback("OnClose", hideQCManagerUI)
	frame:EnableResize(false)
	qcManagerUI = frame

	local sectionTitles = AceGUI:Create("SimpleGroup")
	sectionTitles:SetFullWidth(true)
	sectionTitles:SetLayout("Flow")
	do
		local bookTreeTitle = AceGUI:Create("Label")
		bookTreeTitle:SetText("Books")
		sectionTitles:AddChild(bookTreeTitle)

		local pageTreeTitle = AceGUI:Create("Label")
		pageTreeTitle:SetText("Information")
		sectionTitles:AddChild(pageTreeTitle)
	end
	frame:AddChild(sectionTitles)

	local bookSelectTree = AceGUI:Create("TreeGroup")
	bookSelectTree:SetAutoAdjustHeight(false)
	bookSelectTree:SetHeight(450)
	--bookSelectTree:SetFullHeight(true) -- this is broken, doesn't apply correctly after changing frames...
	bookSelectTree:SetFullWidth(true)
	bookSelectTree:SetLayout("Flow")
	bookSelectTree:SetTree(getBookManagerBookTree())
	bookSelectTree:SetTreeWidth(200, false)
	frame:AddChild(bookSelectTree)

	local resetMeCallback = function(shownBook)
		local shownBookIndex = shownBook
		if type(shownBook) == "table" then
			shownBookIndex = Quickcast.Book.booksDB[Quickcast.Book.getBookIndex(shownBook)]
		end
		hideQCManagerUI();
		showQCManagerUI(shownBookIndex);
	end

	bookSelectTree:SetCallback("OnGroupSelected", function(container, _, selectedBookIndex)
		container:ReleaseChildren()
		drawBookGroup(container, selectedBookIndex, resetMeCallback)
	end)

	if type(bookIndexOverride) == "table" then bookIndexOverride = Quickcast.Book.getBookIndex(bookIndexOverride) end
	local bookToSelect = (Quickcast.Book.booksDB[bookIndexOverride] and bookIndexOverride or 1)
	if bookToSelect then
		bookSelectTree:SelectByPath(bookToSelect)
	end
end

---@param shownBook integer|QuickcastBook? The Book Index to re-open the UI to
local function refreshQCManagerUI(shownBook)
	local shownBookIndex = shownBook
	if type(shownBook) == "table" then
		shownBookIndex = Quickcast.Book.getBookIndex(shownBook)
	end
	if qcManagerUI and qcManagerUI:IsShown() then
		hideQCManagerUI();
		showQCManagerUI(shownBookIndex);
	end
end

---@class UI_Quickcast_ManagerUI
ns.UI.Quickcast.ManagerUI = {
	showQCManagerUI = showQCManagerUI,
	refreshQCManagerUI = refreshQCManagerUI,

	showSpellsManager = showSpellsManager,
	refreshSpellsManager = refreshSpellsManager,
}
