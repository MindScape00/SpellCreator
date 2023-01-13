---@class ns
local ns = select(2, ...)

local SavedVariables = ns.SavedVariables

local Constants = ns.Constants
local Logging = ns.Logging

local Dropdown = ns.UI.Dropdown
local Popups = ns.UI.Popups
local Quickcast = ns.UI.Quickcast
local QuickcastStyle = ns.UI.Quickcast.Style

local UIHelpers = ns.Utils.UIHelpers
local Tooltip = ns.Utils.Tooltip

local ASSETS_PATH = Constants.ASSETS_PATH
local BOOK_STYLE = QuickcastStyle.BOOK_STYLE
local BOOK_STYLE_DATA = QuickcastStyle.BOOK_STYLE_DATA

local numMenus = 0

--[[
Concept:

Rename Book											// DONE
Change Style										// DONE
  --> Book
    --> List of styles
  --> Page
    --> List of styles
Switch Page											// DONE
  --> List of available pages in this book

--divider--

Manage Books
  --> Create New Book (gens a new book icon on the UI)		// DONE
  --> Toggle Shown Books
    --> List of books with toggle check state
  --> Hide all book menus (shortcut to toggle shown books -> clicking them all)
  --> Permanently Delete a Book (prompt confirmation warning, all pages in this book become 'Free Pages')

Manage Pages
  --> Add New Page									// DONE
    --> Standard									// DONE
    --> Dynamic										// DONE
  --> Permanently Delete Page (prompt confirmation warning)		// DONE
    --> List of this books pages
  --> Claim Free Page
    --> List of unassigned pages
  --> Claim page from other book
    --> List of other books
      --> List of that books pages
  --> Copy Page from Other Book

--]]


---@param style BookStyle
local function formatName(style)
	local data = QuickcastStyle.getStyleData(style)
	local texMarkup
	if data.useTexForIcon then
		local tex = data.tex
		texMarkup = CreateTextureMarkup(
			tex,
			1,
			1,
			22,
			22,
			0,
			1,
			0,
			1,
			-6,
			-1
		)
		texMarkup = "  " .. texMarkup .. "      "
	elseif data.iconData then
		local tex = data.iconData.tex
		local w = data.iconData.width
		local h = data.iconData.height or 0
		texMarkup = CreateTextureMarkup(
			tex,
			w and w or 1,
			1,
			w and w or 0,
			h,
			0,
			1,
			0,
			1,
			-8,
			-1
		)
	elseif data.color then
		local r, g, b = data.color:GetRGBAsBytes()
		texMarkup = UIHelpers.CreateTextureMarkupWithColor(
			ASSETS_PATH .. "/InterfaceSwatch",
			4,
			1,
			4,
			0,
			0,
			1,
			0,
			1,
			-8,
			-1,
			r,
			g,
			b
		)
	else
		texMarkup = "•    "
	end

	return texMarkup .. data.name
end

---@param book QuickcastBook
---@param style BookStyle
---@return DropdownItem
local function genStyleItem(book, style)
	return Dropdown.radio(formatName(style), {
		get = function()
			return book:GetStyle() == style
		end,
		set = function()
			book:SetStyle(style)
		end,
	})
end

---@param book QuickcastBook
---@return DropdownItem
local function genStyleMenu(book)
	local menuArgs = {}

	for style in ipairs(BOOK_STYLE_DATA) do
		menuArgs[style] = genStyleItem(book, style)
	end

	return Dropdown.submenu("Change Style", menuArgs)
end

---@param book QuickcastBook
---@param page QuickcastPage
---@param pageNumber integer
---@return DropdownItem
local function genPageItem(book, page, pageNumber)
	local profileName = page.profileName

	return Dropdown.radio(("Page " .. pageNumber .. (profileName and "* (" .. profileName .. ")" or "")), {
		-- TODO : Switch to page names? don't think we need this? I think page numbers are fine.
		get = function()
			return book:GetCurrentPageNumber() == pageNumber
		end,
		set = function()
			book:GoToPageNumber(pageNumber)
		end,
	})
end

---@param book QuickcastBook
---@return DropdownItem
local function genPageMenu(book)
	local menuArgs = {}
	for i = 1, book:GetNumPages() do
		menuArgs[i] = genPageItem(book, book.savedData._pages[i], i)
	end

	return Dropdown.submenu("Switch Page", menuArgs, {
		disabled = book:GetNumPages() == 0
	})
end

-------------------------
-- // Book Manager Menu
-------------------------

local function isLastBookShown(book, menuOwnerBook)
	if book ~= menuOwnerBook then return false end
	local iter = 0
	for _, _ in pairs(SpellCreatorMasterTable.quickcast.shownByChar[Constants.CHARACTER_NAME]) do
		iter = iter + 1
		if iter > 1 then
			return false
		end
	end
	return true
end

---@param book QuickcastBook
---@param menuOwnerBook QuickcastBook? the book that owns the submenu, if any - used to detect if you're hiding the same book
---@return DropdownItem
local function genShowBookItem(book, menuOwnerBook)
	return Dropdown.checkbox(book.savedData.name,
		{
			get = function()
				return book:IsShown()
			end,
			set = function(value)
				local lastShown = isLastBookShown(book, menuOwnerBook)
				book:ToggleVisible(value)
				if book == menuOwnerBook then
					C_Timer.After(0, Dropdown.close)
				end
				if lastShown and value == false then
					Logging.cprint("Last Quickcast Book hidden. You can re-show Quickcast books at any time by via the Arcanum Settings -> Quickcast Manager!")
				end
			end,
		}
	)
end

---@param text string name of the submenu entry
---@param book QuickcastBook? book that owns the submenu, can be nil if none
---@return DropdownItem
local function genShowBookMenu(text, book)
	local menuArgs = {}
	for i = 1, #ns.UI.Quickcast.Book.booksDB do
		local v = ns.UI.Quickcast.Book.booksDB[i]
		tinsert(menuArgs, genShowBookItem(v, book))
	end
	return Dropdown.submenu(text, menuArgs)
end

---@param book QuickcastBook
---@return DropdownItem[]
local function genBookManagerMenu(book)
	return Dropdown.submenu("Manage Books", {
		Dropdown.execute("Create New Book", function()
			local numBooks = ns.UI.Quickcast.Book.getNumBooks()
			local newBook = ns.UI.Quickcast.Book.createBook(numBooks + 1)
			local newPage = ns.UI.Quickcast.Page.createPage(newBook)
			newBook:AddPage(newPage)
			newBook:GoToFirstPage()
			newBook:SetStyle(BOOK_STYLE.DEFAULT)
		end),
		--[[	-- Not sure which way we want to do this. It feels simpler to have it without the input, but then it's another step to rename..
		Dropdown.input("Create New Book",
			{
				placeholder = "New Book Name",
				set = function(name)
					local numBooks = ns.UI.Quickcast.Book.getNumBooks()
					local newBook = ns.UI.Quickcast.Book.createBook(numBooks + 1, name)
					local newPage = ns.UI.Quickcast.Page.createPage(newBook)
					newBook:AddPage(newPage)
					newBook:GoToFirstPage()
					newBook:SetStyle(BOOK_STYLE.DEFAULT)
				end,
			}
		),
		--]]

		genShowBookMenu("Toggle Books", book),

		Dropdown.divider(),
		Dropdown.execute("Delete this Book", function()
			---@type GenericConfirmationCustomData
			local popupData = {
				text = "Are you sure you want to delete\n%s?\n\r" .. Tooltip.genTooltipText("warning", "All pages in this book will also be deleted."),
				text_arg1 = Tooltip.genContrastText(book.savedData.name),
				callback = function()
					book:ToggleVisible(false)
					ns.UI.Quickcast.Book.deleteBook(book)
				end,
				showAlert = true,
			}
			Popups.showCustomGenericConfirmation(popupData)
		end),
	})
end

-------------------------
-- // Page Manager Menu
-------------------------

---@param book QuickcastBook
---@param profileName string
---@return DropdownItem
local function genDynamicPageItem(book, profileName)
	local _profileItem = Dropdown.execute(profileName,
		function()
			local _newPage = ns.UI.Quickcast.Page.createPage(book, nil, profileName)
			local newPageIndex = book:AddPage(_newPage)
			book:GoToPageNumber(newPageIndex)
		end,
		{
			disabled = function()
				for k, v in pairs(book.savedData._pages) do
					if v.profileName == profileName then return true end
				end
				return false
			end,
		}
	)
	return _profileItem
end

---@param book QuickcastBook
local function genDynamicPageMenu(book)
	local _menuArgs = {
		Dropdown.header("Select a Profile"),
		genDynamicPageItem(book, "Account"),
		genDynamicPageItem(book, Constants.CHARACTER_NAME),
	}
	for k, v in ipairs(SavedVariables.getProfileNames(true, true)) do
		local _profileItem = genDynamicPageItem(book, v)
		tinsert(_menuArgs, _profileItem)
	end
	return Dropdown.submenu("Create Dynamic Page", _menuArgs, { tooltipTitle = "Dynamic Page", tooltipText = "Dyanmic pages will show all ArcSpells assigned to the chosen profile." })
end

---@param book QuickcastBook
---@param pageIndex integer
---@return DropdownItem
local function genDeletePageItem(book, pageIndex)
	local page = book.savedData._pages[pageIndex]
	local profileName = page.profileName
	return Dropdown.execute(
		"Page " .. pageIndex .. (profileName and "* (" .. profileName .. ")" or ""),
		function()
			ns.UI.Quickcast.Book.deletePageFromBook(book, pageIndex)
		end
	)
end

---@param book QuickcastBook
---@return DropdownItem[]
local function genDeletePageMenu(book)
	local menuArgs = {}
	for k, v in ipairs(book.savedData._pages) do
		tinsert(menuArgs, genDeletePageItem(book, k))
	end
	return Dropdown.submenu("Delete Page", menuArgs, nil)
end

---@param book QuickcastBook
local function genPageManagerMenu(book)
	local _menuArgs = {
		Dropdown.execute("Create Page", function()
			local page = ns.UI.Quickcast.Page.createPage(book, {})
			local newPageIndex = book:AddPage(page)
			book:GoToPageNumber(newPageIndex) -- more efficient than calling GoToPage by using the index directly
		end),
		genDynamicPageMenu(book),
		genDeletePageMenu(book),
	}
	return Dropdown.submenu("Manage Pages", _menuArgs, nil)
end

---@param book QuickcastBook
local function genNewAddPageMenu(book)
	local _menuArgs = {
		Dropdown.execute("Standard Page", function()
			local page = ns.UI.Quickcast.Page.createPage(book, {})
			local newPageIndex = book:AddPage(page)
			book:GoToPageNumber(newPageIndex) -- more efficient than calling GoToPage by using the index directly
		end),
		Dropdown.spacer(),
		Dropdown.header("Dynamic Page:"),
		genDynamicPageItem(book, "Account"),
		genDynamicPageItem(book, Constants.CHARACTER_NAME),
	}
	for k, v in ipairs(SavedVariables.getProfileNames(true, true)) do
		local _profileItem = genDynamicPageItem(book, v)
		tinsert(_menuArgs, _profileItem)
	end
	return Dropdown.submenu("Add New Page", _menuArgs, nil)
end

-------------------------
-- // Main Context Menu
-------------------------

---@param book QuickcastBook
---@return DropdownItem[]
local function createMenu(book)
	return {
		Dropdown.header(book.savedData.name),
		Dropdown.input("Rename Book", {
			tooltipTitle = "Rename " .. book.savedData.name,
			get = function() end,
			set = function(text)
				ns.UI.Quickcast.Book.renameBookInCharMemory(book.savedData.name, text)
				book:SetName(text)
			end,
			placeholder = book.savedData.name
		}),
		genStyleMenu(book),
		genPageMenu(book),
		Dropdown.divider(),
		--genBookManagerMenu(book),
		--genPageManagerMenu(book),
		genNewAddPageMenu(book),
		Dropdown.execute("Hide Book", function()
			book:ToggleVisible(false)
		end),
		Dropdown.divider(),
		Dropdown.execute("Quickcast Manager", function()
			Quickcast.ManagerUI.showQCManagerUI(book)
		end),
	}
end

---@param book QuickcastBook
local function createFor(book)
	numMenus = numMenus + 1
	return Dropdown.create(book, "QuickcastContextMenu" .. numMenus)
end

---@param book QuickcastBook
local function open(book)
	Dropdown.open(createMenu(book), book.contextMenu, "cursor", 0, 0, "MENU")
end

---@return boolean
local function isOpen()
	return Dropdown.isOpen()
end

---@class UI_Quickcast_ContextMenu
ns.UI.Quickcast.ContextMenu = {
	createFor = createFor,
	open = open,
	isOpen = isOpen,
	genShowBookMenu = genShowBookMenu,
	genShowBookItem = genShowBookItem,
	genStyleItem = genStyleItem,
	genDynamicPageMenu = genDynamicPageMenu,
}
