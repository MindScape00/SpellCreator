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

---@class UI_Quickcast_Quickcast
ns.UI.Quickcast.Quickcast = {
	init = init,
	setShown = setShown,
}
