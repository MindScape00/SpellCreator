---@class ns
local ns = select(2, ...)

local DataUtils = ns.Utils.Data
local Constants = ns.Constants

local Popups = ns.UI.Popups
local Quickcast = ns.UI.Quickcast
local QuickcastAnimation = ns.UI.Quickcast.Animation
local QuickcastContextMenu = ns.UI.Quickcast.ContextMenu
local QuickcastStyle = ns.UI.Quickcast.Style

local Tooltip = ns.Utils.Tooltip

local BOOK_STYLE = QuickcastStyle.BOOK_STYLE

local getCursorDistanceFromFrame = QuickcastAnimation.getCursorDistanceFromFrame

---@type QuickcastBook[]
local _booksDB = {}

-- // Character Memory

---@param bookName string
local function addBookToCharacterMemory(bookName)
	SpellCreatorMasterTable.quickcast.shownByChar[Constants.CHARACTER_NAME][bookName] = true
end

---@param bookName string
local function removeBookFromCharacterMemory(bookName)
	SpellCreatorMasterTable.quickcast.shownByChar[Constants.CHARACTER_NAME][bookName] = nil
end

---@param bookName string
local function isBookInCharMemory(bookName)
	return SpellCreatorMasterTable.quickcast.shownByChar[Constants.CHARACTER_NAME][bookName] or nil
end

---@param oldName string
---@param newName string
local function renameBookInCharMemory(oldName, newName)
	for k, v in pairs(SpellCreatorMasterTable.quickcast.shownByChar) do
		if v[oldName] then
			v[oldName] = nil
			v[newName] = true
		end
	end
end

---@param bookName string
---@param val boolean
local function directSetBookInCharMemory(bookName, val)
	SpellCreatorMasterTable.quickcast.shownByChar[Constants.CHARACTER_NAME][bookName] = val and val or nil
end

-- //

local function getNumBooks()
	return #_booksDB
end

---@param self QuickcastBook
---@return BookStyle
local function Book_GetStyle(self)
	return self.savedData.style
end

---@param self QuickcastBook
---@return BookStyleData
local function Book_GetStyleData(self)
	return QuickcastStyle.getStyleData(self.savedData.style)
end

---@param self QuickcastBook
---@param style BookStyle
local function Book_SetStyle(self, style)
	self.savedData.style = style
	local bookStyle = self:GetStyleData()

	self:SetNormalTexture(bookStyle.tex)
	self:SetHighlightTexture(bookStyle.tex)
	self:GetHighlightTexture():SetAlpha(0.3)
	Quickcast.ManagerUI.refreshQCManagerUI(self)

	for _, page in ipairs(self.savedData._pages) do
		page:SetStyle(style)
	end
end

---@param self QuickcastBook
local function onBookClick(self, button)
	if button == "RightButton" then
		QuickcastContextMenu.open(self)
	else
		SCForgeMainFrame:SetShown(not SCForgeMainFrame:IsShown())
	end
end

---@param self QuickcastBook
---@param delta integer
local function onBookScroll(self, delta)
	if QuickcastContextMenu.isOpen() then return end

	if delta > 0 then
		self:NextPage()
	else
		self:PreviousPage()
	end
end

---@param self QuickcastBook
local function onBookEnter(self)
	-- TODO can we have pages without spells? book without pages?

	if self.isOpen then return end
	if self:GetNumPages() == 0 then return end

	self:Open()

	local rad = self:GetCurrentPage():GetRadius()
	self:SetScript("OnUpdate", function(self)
		if getCursorDistanceFromFrame(self) > rad + 35 then -- manually overriding rad to 50 (35+15) offset from self.radius (that is: 50 'pixels' outside of the cast button's center)
			self:Close()
			self:SetScript("OnUpdate", nil)
		end
	end)
end

---@param self QuickcastBook
local function Book_ToggleVisible(self, status)
	local currentVis = self:IsShown()
	if status == false or (currentVis) then
		self:SetShown(false)
	else
		self:SetShown(true)
	end

	directSetBookInCharMemory(self.savedData.name, self:IsShown())
	Quickcast.ManagerUI.refreshQCManagerUI(self)
end

---@param self QuickcastBook
---@param pageNumber integer
local function updatePageIndicator(self, pageNumber)
	local pageIndicator = self.pageIndicator
	pageIndicator:SetText(string.format("%s / %s", pageNumber, self:GetNumPages()))
end

local function showPageIndicator(self, pageNumber)
	if self:GetNumPages() == 1 then return end
	local pageIndicator = self.pageIndicator

	if pageNumber then updatePageIndicator(self, pageNumber) end

	if pageIndicator.timer then pageIndicator.timer:Cancel() end
	if pageIndicator:IsShown() then
		if UIFrameIsFading(pageIndicator) then
			UIFrameFadeRemoveFrame(pageIndicator)
		end
		pageIndicator:SetAlpha(1);
		pageIndicator:Show();
	else
		UIFrameFadeIn(pageIndicator, 0.2, 0, 1)
	end
end

---@param self QuickcastBook
local function hidePageIndicator(self)
	local pageIndicator = self.pageIndicator --[[@as frame]]
	if pageIndicator.timer then pageIndicator.timer:Cancel() end
	if pageIndicator:IsShown() then
		pageIndicator.timer = C_Timer.NewTimer(0.1, function() ns.UI.Quickcast.Animation.CustomUIFrameFadeOut(pageIndicator, 1, pageIndicator:GetAlpha(), 0) end) -- stored per indicator because multiple could be running
	end
end

---@param self QuickcastBook
---@param buttonToActivate QuickcastButton?
local function Book_Close(self, buttonToActivate)
	self:GetCurrentPage():HideCastButtons(buttonToActivate)
	self.isOpen = false
	hidePageIndicator(self)
end

---@param self QuickcastBook
local function Book_Open(self)
	local curPage = self:GetCurrentPage()
	if curPage:GetNumSpells() == 0 then return end
	curPage:UpdateButtons()
	showPageIndicator(self)
	self.isOpen = true
end

---@param self QuickcastBook
---@param page QuickcastPage
local function Book_AddPage(self, page)
	page:SetStyle(self:GetStyle())
	local lastParent = page:GetParent()
	tDeleteItem(lastParent.savedData._pages, page)
	page:SetParent(self)
	local ix = #self.savedData._pages + 1
	self.savedData._pages[ix] = page
	Quickcast.ManagerUI.refreshQCManagerUI(self)
	return ix
end

---@param self QuickcastBook
---@return QuickcastPage
local function Book_GetCurrentPage(self)
	return self.savedData._pages[self:GetCurrentPageNumber()]
end

---@param self QuickcastBook
---@param index integer
---@return QuickcastPage
local function Book_GetPageByIndex(self, index)
	return self.savedData._pages[index]
end

---@param self QuickcastBook
---@return integer
local function Book_GetCurrentPageNumber(self)
	return self._currentPage
end

---@param self QuickcastBook
---@param pageNumber integer
local function Book_GoToPageNumber(self, pageNumber)
	local wasOpen = self.isOpen

	if wasOpen then
		self:Close()
	end

	self._currentPage = pageNumber

	if wasOpen then
		self:Open()
	end

	updatePageIndicator(self, pageNumber)
end

---@param self QuickcastBook
---@param page QuickcastPage
local function Book_GoToPage(self, page)
	self:GoToPageNumber(DataUtils.indexOf(self.savedData._pages, page))
end

---@param self QuickcastBook
local function Book_GoToFirstPage(self)
	self:GoToPageNumber(1)
end

---@param self QuickcastBook
local function Book_GoToLastPage(self)
	self:GoToPageNumber(self:GetNumPages())
end

---@param self QuickcastBook
local function Book_PreviousPage(self)
	local currentNumber = self:GetCurrentPageNumber()
	local numPages = self:GetNumPages()
	if currentNumber > 1 then
		self:GoToPageNumber(currentNumber - 1)
	elseif currentNumber == 1 and numPages ~= 1 and SpellCreatorMasterTable.Options.allowQCOverscrolling then
		self:GoToLastPage()
	end
	if not self.isOpen then
		self:Open()
	end
end

---@param self QuickcastBook
local function Book_NextPage(self)
	local currentNumber = self:GetCurrentPageNumber()
	local numPages = self:GetNumPages()
	if currentNumber < numPages then
		self:GoToPageNumber(currentNumber + 1)
	elseif currentNumber == numPages and numPages ~= 1 and SpellCreatorMasterTable.Options.allowQCOverscrolling then
		self:GoToFirstPage()
	end
	if not self.isOpen then
		self:Open()
	end
end

local function Book_MovePage(self, currentIndex, newIndex)
	if currentIndex == newIndex then return end
	local numPages = self:GetNumPages()
	if newIndex > numPages then return error("Cannot move page outside bounds of the array (newIndex > number of Pages)") end

	local pages = self.savedData._pages
	local thePage = pages[currentIndex]
	if not thePage then return end
	tremove(pages, currentIndex)
	tinsert(pages, newIndex, thePage)
	Quickcast.ManagerUI.refreshQCManagerUI(self)
end

---@param self QuickcastBook
---@return integer
local function Book_GetNumPages(self)
	return #self.savedData._pages
end

---@param self QuickcastBook
---@param name string
local function Book_SetName(self, name)
	self.savedData.name = name
	Quickcast.ManagerUI.refreshQCManagerUI(self)
end

---@param self QuickcastBook
---@return boolean
local function bookTooltipPredicate(self)
	if self:GetNumPages() == 0 or self:GetCurrentPage():GetNumSpells() == 0 then
		return true
	end
	return false
end

---@param book QuickcastBook
---@param indexFromStorage integer
local function saveBookToDatabase(book, indexFromStorage)
	local savedData = book.savedData
	if indexFromStorage then
		SpellCreatorMasterTable.quickcast.books[indexFromStorage] = savedData
	else
		tinsert(SpellCreatorMasterTable.quickcast.books, savedData)
	end
end

---@param book QuickcastBook
local function getBookIndex(book)
	for i, v in ipairs(_booksDB) do
		if book == v then
			return i
		end
	end
end

---@param name string
---@return QuickcastBook|nil
local function findBookByName(name)
	for i, book in ipairs(_booksDB) do
		if book.savedData.name == name then
			return book
		end
	end
end

---@param self QuickcastBook
---@return integer
local function Book_GetIndex(self)
	return getBookIndex(self)
end

---@param index integer
---@param name? string
---@return QuickcastBook
local function createBook(index, name, indexFromStorage)
	---@class QuickcastBook: Button
	local book = CreateFrame("Button", "SCForgeQuickcast" .. index, UIParent)
	book:SetPoint("TOPRIGHT", -60, -220)
	book:SetSize(50, 50)

	book.savedData = {}
	book._currentPage = 0
	book.isOpen = false
	book.savedData.style = BOOK_STYLE.DEFAULT
	book.savedData._pages = {} ---@type QuickcastPage[]
	local tempName = name and name or string.format(Constants.DEFAULT_QC_BOOK_NAME, index) --("Quickcast Book " .. index)
	book.savedData.name = tempName

	local pageIndicator = book:CreateFontString(nil, nil, "SystemFont_Shadow_Large_Outline")
	pageIndicator:SetText("1 / 2")
	pageIndicator:SetPoint("CENTER", book, "BOTTOM", 0, 8)
	pageIndicator:SetShadowColor(0.2, 0.2, 0.2, 1)
	pageIndicator:SetShadowOffset(2, -2)
	pageIndicator:Hide()
	book.pageIndicator = pageIndicator

	book:SetMovable(true)
	book:EnableMouse(true)
	book:RegisterForDrag("LeftButton")
	book:SetClampedToScreen(true)

	book:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	book:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	book:SetScript("OnClick", onBookClick)
	book:SetScript("OnMouseWheel", onBookScroll)
	book:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	book:SetScript("OnEnter", onBookEnter)

	book.AddPage = Book_AddPage
	book.GetCurrentPageNumber = Book_GetCurrentPageNumber
	book.GetCurrentPage = Book_GetCurrentPage
	book.GetPageByIndex = Book_GetPageByIndex
	book.GoToPageNumber = Book_GoToPageNumber
	book.GoToPage = Book_GoToPage
	book.GoToFirstPage = Book_GoToFirstPage
	book.GoToLastPage = Book_GoToLastPage
	book.PreviousPage = Book_PreviousPage
	book.NextPage = Book_NextPage
	book.GetNumPages = Book_GetNumPages
	book.MovePage = Book_MovePage
	book.GetStyle = Book_GetStyle
	book.GetStyleData = Book_GetStyleData
	book.SetStyle = Book_SetStyle
	book.Close = Book_Close
	book.Open = Book_Open
	book.SetName = Book_SetName
	book.ToggleVisible = Book_ToggleVisible
	book.GetIndex = Book_GetIndex

	book.contextMenu = QuickcastContextMenu.createFor(book)

	Tooltip.set(book,
		function(self) return self.savedData.name end,
		function(self)
			if bookTooltipPredicate(self) then -- no pages or spells, let's show the bigger tooltip text for more info
				return "Welcome to Arcanum's Quickcast system! This is a Quickcast Book! You can add spells to pages in the book by " ..
					Tooltip.genContrastText("right-clicking") ..
					" a spell in your Personal Vault.\n\rYou can add multiple pages to your Quickcast Book as well, to fit more spells or organize them. Use your " ..
					Tooltip.genContrastText("mousewheel") .. " to switch between pages!\n\rYou can manage your books & pages, as well as change their looks, by "
					..
					Tooltip.genContrastText("right-clicking") ..
					" them.\n\rYou can also " ..
					Tooltip.genContrastText("left-click") ..
					" a Quickcast Book to open the full Arcanum menu.\n\r" .. Tooltip.genTooltipText("lpurple", "Click & Drag to move this book anywhere on your screen!")
			else -- they have pages and spells
				return "Add Arcanum Spells to your Quickcast Books by " ..
					Tooltip.genContrastText("right-clicking") ..
					" them in your vault!\n\r" .. Tooltip.genTooltipText("lpurple", "Click & Drag to move the book anywhere, " .. Tooltip.genContrastText("right-click") .. " to configure.")
			end
		end,
		{
			delay = function(self)
				if self:GetNumPages() == 0 or self:GetCurrentPage():GetNumSpells() == 0 then
					return 0
				else
					return 1
				end
			end,
			--predicate = bookTooltipPredicate -- Use this if we want to hide the tooltips when the book has a page & the page has spells
		}
	)

	if not indexFromStorage then
		addBookToCharacterMemory(tempName)
	end

	tinsert(_booksDB, book)
	saveBookToDatabase(book, indexFromStorage)

	Quickcast.ManagerUI.refreshQCManagerUI(book)

	return book
end

---@param book QuickcastBook
local function deleteBook(book)
	local index = getBookIndex(book)

	-- TODO : Move the pages from this book into a Free / Orphaned pages holding table (and update the delete confirmation)
	book:Hide()
	tremove(_booksDB, index)
	tremove(SpellCreatorMasterTable.quickcast.books, index)
	removeBookFromCharacterMemory(book.savedData.name)
	Quickcast.ManagerUI.refreshQCManagerUI(book)
end

---@param book QuickcastBook
---@param pageIndex number
local function deletePageFromBook(book, pageIndex)
	local popupData = {
		text = "Are you sure you want to delete\n%s from book %s?",
		text_arg1 = Tooltip.genContrastText("Page " .. pageIndex),
		text_arg2 = Tooltip.genContrastText(book.savedData.name),
		callback = function()
			tremove(book.savedData._pages, pageIndex)
			book:GoToFirstPage()
			Quickcast.ManagerUI.refreshQCManagerUI(book)
		end,
		showAlert = true,
	}
	Popups.showCustomGenericConfirmation(popupData)
end

--- // Stored Spell Cleaner, fired on Player Logout even right before Saved Variables are saved. This cleans out all the frame data from the _pages so we're not storing a bunch of excess data and risking the size of our Saved Variables. Rewriting page storage and accessing them was too much work, this is easy and rather efficient since it's only fired on logout.
local storedSpellCleaner = CreateFrame("Frame")
storedSpellCleaner:RegisterEvent("PLAYER_LOGOUT")
storedSpellCleaner:SetScript("OnEvent", function(self, event, arg1)
	for iB, book in ipairs(SpellCreatorMasterTable.quickcast.books) do
		for iP, page in ipairs(book._pages) do
			local spells = page.spells
			local profileName = page.profileName
			SpellCreatorMasterTable.quickcast.books[iB]._pages[iP] = { spells = spells, profileName = profileName }
		end
	end
end)

--- Toggle a Quickcast Book by it's name
---@param bookName string
local function toggleBookByName(bookName)
	for k, v in ipairs(_booksDB) do
		if v.savedData.name == bookName then
			v:ToggleVisible()
		end
	end
end

---Switch a Book by name to a specific page
---@param bookName string
---@param pageNum string|number
local function setPageInBook(bookName, pageNum)
	for k, v in ipairs(_booksDB) do
		if v.savedData.name == bookName then
			pageNum = tonumber(pageNum) --[[@as number]]
			if pageNum and pageNum <= v:GetNumPages() then
				v:GoToPageNumber(pageNum)
			end
		end
	end
end

---Switch a book by name to a specific style
---@param bookName string
---@param styleNameOrID string|integer
local function changeBookStyle(bookName, styleNameOrID)
	local theStyle = ns.UI.Quickcast.Style.getStyleIDFromNameOrID(styleNameOrID)
	if not theStyle then return false end

	for k, v in ipairs(_booksDB) do
		if v.savedData.name == bookName then
			v:SetStyle(theStyle)
			return true
		end
	end
end

---@class UI_Quickcast_Book
ns.UI.Quickcast.Book = {
	createBook = createBook,
	getNumBooks = getNumBooks,
	bookTooltipPredicate = bookTooltipPredicate,
	getBookIndex = getBookIndex,
	deleteBook = deleteBook,
	deletePageFromBook = deletePageFromBook,
	booksDB = _booksDB,

	findBookByName = findBookByName,

	addBookToCharacterMemory = addBookToCharacterMemory,
	removeBookFromCharacterMemory = removeBookFromCharacterMemory,
	isBookInCharMemory = isBookInCharMemory,
	renameBookInCharMemory = renameBookInCharMemory,
	directSetBookInCharMemory = directSetBookInCharMemory,

	toggleBookByName = toggleBookByName,
	setPageInBook = setPageInBook,
	changeBookStyle = changeBookStyle,
}
