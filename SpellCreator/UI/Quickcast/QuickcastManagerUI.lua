---@class ns
local ns = select(2, ...)

local DataUtils = ns.Utils.Data
local AceGUI = ns.Libs.AceGUI
local Quickcast = ns.UI.Quickcast
local Tooltip = ns.Utils.Tooltip
local Popups = ns.UI.Popups
local Dropdown = ns.UI.Dropdown

local ADDON_COLORS = ns.Constants.ADDON_COLORS

local cmd = ns.Cmd.cmd
local round = DataUtils.roundToNthDecimal
local orderedPairs = DataUtils.orderedPairs

local function setTextureOffset(frameTexture, x, y)
	frameTexture:SetVertexOffset(UPPER_LEFT_VERTEX, x, y)
	frameTexture:SetVertexOffset(UPPER_RIGHT_VERTEX, x, y)
	frameTexture:SetVertexOffset(LOWER_LEFT_VERTEX, x, y)
	frameTexture:SetVertexOffset(LOWER_RIGHT_VERTEX, x, y)
end

local function setHighlightToOffsetWithPushed(frame, x, y)
	if not x then x = 1 end
	if not y then y = -1 end
	local highlight = frame:GetHighlightTexture()
	frame:HookScript("OnMouseDown", function(self) setTextureOffset(highlight, x, y) end)
	frame:HookScript("OnMouseUp", function(self) setTextureOffset(highlight, 0, 0) end)
end

---@param button table ace3gui button table
---@param path string
local function setupCoherentAceIconButtonTextures(button, path)
	local frame = button.frame

	-- force hide the shitty AceGUI Highlight ... that they didn't name, or expose..
	local regions = { frame:GetRegions() }
	for i, child in ipairs(regions) do
		if child.GetTexture then
			if child:GetTexture() == 136580 then
				child:Hide()
			end
		end
	end

	-- hide the AceGUI image, we're adding our own using the button's Set..Texture system
	local image = button.image
	image:Hide()

	frame:SetNormalTexture(path)
	frame:SetHighlightTexture(path, "ADD")
	frame:SetPushedTexture(path)

	frame.NormalTexture = frame:GetNormalTexture()
	frame.NormalTexture:SetAllPoints(image)
	frame.HighlightTexture = frame:GetHighlightTexture()
	frame.HighlightTexture:SetAllPoints(image)
	frame.PushedTexture = frame:GetPushedTexture()
	frame.PushedTexture:SetAllPoints(image)

	frame.HighlightTexture:SetAlpha(0.33)

	setHighlightToOffsetWithPushed(frame)
	setTextureOffset(frame.PushedTexture, 1, -1)
end

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

---@param group AceGUIContainer
---@param bookIndex integer
---@param callback function
local function drawBookGroup(group, bookIndex, callback)
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
	group.bookIndex = bookIndex

	-- Need to redraw again for when icon editbox/button are shown and hidden
	group:ReleaseChildren()

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- groupScrollContainer

	local groupScrollContainer = AceGUI:Create("SimpleGroup")
	groupScrollContainer:SetFullWidth(true)
	groupScrollContainer:SetFullHeight(true)
	groupScrollContainer:SetLayout("Fill")
	group:AddChild(groupScrollContainer)

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- groupScrollFrame

	local groupScrollFrame = AceGUI:Create("ScrollFrame")
	--groupScrollFrame:SetFullWidth(true)
	--groupScrollFrame:SetFullHeight(true)
	groupScrollFrame:SetLayout("List")
	groupScrollContainer:AddChild(groupScrollFrame)

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- gen our inline groups
	if numPages == 0 or not _pages then
		local noPagesLabel = AceGUI:Create("Label")
		noPagesLabel:SetText("There are no Pages in this Book.")
		noPagesLabel:SetRelativeWidth(1)
		groupScrollFrame:AddChild(noPagesLabel)
		return
	end

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
			local styleSelectButton = AceGUI:Create("Icon")
			styleSelectButton:SetLabel("Change Style")
			styleSelectButton:SetImage(bookStyleData.tex)
			setupCoherentAceIconButtonTextures(styleSelectButton, bookStyleData.tex)
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

	for k, pageData in ipairs(_pages) do
		local isDyanmicPage
		if pageData.profileName then isDyanmicPage = true end

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
			pageTypeLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Type: ") .. (isDyanmicPage and "Dynamic" or "Standard"))
			pageTypeLabel:SetRelativeWidth(1)
			pageInfoSection:AddChild(pageTypeLabel)

			if isDyanmicPage then
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
			local moveButton = AceGUI:Create("Button")
			moveButton:SetText("Move")
			moveButton:SetRelativeWidth(1)
			moveButton:SetDisabled(true)
			moveButton:SetCallback("OnClick", function() end)
			pageButtonsSection:AddChild(moveButton)

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
}
