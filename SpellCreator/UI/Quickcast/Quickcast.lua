---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

local QuickcastBook = ns.UI.Quickcast.Book
local QuickcastPage = ns.UI.Quickcast.Page
local QuickcastStyle = ns.UI.Quickcast.Style

local BOOK_STYLE = QuickcastStyle.BOOK_STYLE

local books = {} ---@type QuickcastBook[]

local function setShown(shown)
	for _, book in ipairs(books) do
		book:SetShown(shown)
	end
end

local function init()
	-- Just one book for now.

	if #SpellCreatorMasterTable.quickcast.books == 0 then -- no quickcast.books saved - let's create one and make it from quickCastSpells - This will convert their Quickcast Spells into the new system also!
		local book = QuickcastBook.createBook(1)
		book:SetStyle(BOOK_STYLE.PRISMATIC)

		local page = QuickcastPage.createPage(book, SpellCreatorMasterTable.quickCastSpells)
		book:AddPage(page)

		-- Don't know if we automatically want to change pages when we add one. TBD?
		--book:GoToFirstPage()
		book:GoToPage(page)
		return
	end

	local booksFromStorage = CopyTable(SpellCreatorMasterTable.quickcast.books)
	for bookIndex, bookData in ipairs(booksFromStorage) do
		local book = QuickcastBook.createBook(bookIndex, bookData.name, bookIndex)
		book:SetStyle(bookData.style)
		for pageIndex, pageData in ipairs(bookData._pages) do
			local page = QuickcastPage.createPageFromStorage(book, pageData, pageIndex)
			book:AddPage(page)
			book:GoToFirstPage()
		end
		book:SetShown(SpellCreatorMasterTable.quickcast.shownByChar[Constants.CHARACTER_NAME][bookData.name])
	end

end

local API = {
	FindBook = QuickcastBook.findBookByName,

	---@param name string
	---@param style string|integer|number? style name or ID
	---@return QuickcastBook
	---@return QuickcastPage
	NewBook = function(name, style)
		local numBooks = ns.UI.Quickcast.Book.getNumBooks()
		local newBook = ns.UI.Quickcast.Book.createBook(numBooks + 1, name)
		local newPage = ns.UI.Quickcast.Page.createPage(newBook)
		newBook:AddPage(newPage)
		newBook:GoToFirstPage()
		local finalStyle = ns.UI.Quickcast.Style.getStyleIDFromNameOrID(style)
		newBook:SetStyle(finalStyle or ns.UI.Quickcast.Style.BOOK_STYLE.DEFAULT)
		ns.UI.Quickcast.ManagerUI.refreshQCManagerUI(numBooks + 1)
		return newBook, newPage
	end,

	---@param book QuickcastBook|string
	---@param spells CommID[]
	---@param profile string? profile name for a dynamic page
	---@return QuickcastPage|nil
	---@return number? newPageIndex
	NewPage = function(book, spells, profile)
		if type(book) == "string" then
			-- find book by string name first
			book = ns.UI.Quickcast.Book.findBookByName(book)
		end
		if not book then return end
		local newPage = ns.UI.Quickcast.Page.createPage(book, spells, profile)
		local index = book:AddPage(newPage)
		book:GoToPage(newPage)
		ns.UI.Quickcast.ManagerUI.refreshQCManagerUI(book)
		return newPage, index
	end,

	---@param book QuickcastBook|string
	---@param index any
	---@return QuickcastPage|nil
	GetPage = function(book, index)
		if type(book) == "string" then
			-- find book by string name first
			book = ns.UI.Quickcast.Book.findBookByName(book)
		end
		if not book or not index then return end
		return book:GetPageByIndex(index)
	end,

	---@param book QuickcastBook|string
	---@param styleNameOrID string|integer?
	SetBookStyle = function(book, styleNameOrID)
		if type(book) == "string" then
			-- find book by string name first
			book = ns.UI.Quickcast.Book.findBookByName(book)
		end
		if not book or not styleNameOrID then return end

		local theStyle = ns.UI.Quickcast.Style.getStyleIDFromNameOrID(styleNameOrID)
		if theStyle then
			book:SetStyle(theStyle)
		end
	end,

	---@param book QuickcastBook|string
	---@param pageNum integer
	GotoPage = function(book, pageNum)
		if type(book) == "string" then
			-- find book by string name first
			book = ns.UI.Quickcast.Book.findBookByName(book)
		end
		if not book or not pageNum then return end

		book:GoToPageNumber(pageNum)
	end,

	---Add a Spell to a book by name & page number. This is really only because I needed a function to use for an action.
	---@param book QuickcastBook|string
	---@param pageNum integer
	---@param commID CommID
	AddSpell = function(book, pageNum, commID)
		if type(book) == "string" then
			-- find book by string name first
			book = ns.UI.Quickcast.Book.findBookByName(book)
		end
		if not book or not pageNum then return end
		if not commID then return end
		local page = book:GetPageByIndex(pageNum)
		if not page then return end
		page:AddSpell(commID)
	end,
}

---@class UI_Quickcast_Quickcast
ns.UI.Quickcast.Quickcast = {
	init = init,
	setShown = setShown,
	API = API,
}
