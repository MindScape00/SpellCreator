---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

local ADDON_COLORS = Constants.ADDON_COLORS
local ASSETS_PATH = Constants.ASSETS_PATH
local GEM_BOOK_COLORS = ADDON_COLORS.GEM_BOOK
local QUICKCAST_ASSETS_PATH = ASSETS_PATH .. "/Quickcast"

---@enum BookStyle
local BOOK_STYLE = {
	DEFAULT = 1,
	PRISMATIC = 2,
	PINK = 3,
	VIOLET = 4,
	INDIGO = 5,
	BLUE = 6,
	JADE = 7,
	GREEN = 8,
	YELLOW = 9,
	ORANGE = 10,
	RED = 11,
	ARCWOLF = 12,
	ARCANOWL = 13,
	TEACUP = 14,
}

---@alias ColorGradient { min: ColorMixin, max: ColorMixin }
---@alias IconData {tex: string, width: integer, height?: integer}

---@class BookStyleData
---@field name string
---@field tex string file path
---@field color ColorMixin?
---@field colorGradient ColorGradient?
---@field useTexForIcon boolean
---@field iconData? IconData

---@type { [BookStyle]: BookStyleData }
local BOOK_STYLE_DATA = {
	[BOOK_STYLE.DEFAULT] = {
		name = "Default",
		tex = ASSETS_PATH .. "/quick_cast_main",
		color = ADDON_COLORS.GAME_GOLD,
	},
	[BOOK_STYLE.PRISMATIC] = {
		name = "Prismatic",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook" .. "Prismatic",
		colorGradient = { min = ADDON_COLORS.ADDON_COLOR, max = ADDON_COLORS.LIGHT_PURPLE },
		iconData = { tex = ASSETS_PATH .. "/InterfaceSwatchPrismatic", width = 4 },
	},
	[BOOK_STYLE.VIOLET] = {
		name = "Violet",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook" .. "Violet",
		color = GEM_BOOK_COLORS.VIOLET,
	},
	[BOOK_STYLE.BLUE] = {
		name = "Blue",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook" .. "Blue",
		color = GEM_BOOK_COLORS.BLUE,
	},
	[BOOK_STYLE.GREEN] = {
		name = "Green",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook" .. "Green",
		color = GEM_BOOK_COLORS.GREEN,
	},
	[BOOK_STYLE.INDIGO] = {
		name = "Indigo",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook" .. "Indigo",
		color = GEM_BOOK_COLORS.INDIGO,
	},
	[BOOK_STYLE.JADE] = {
		name = "Jade",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook" .. "Jade",
		color = GEM_BOOK_COLORS.JADE,
	},
	[BOOK_STYLE.ORANGE] = {
		name = "Orange",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook" .. "Orange",
		color = GEM_BOOK_COLORS.ORANGE,
	},
	[BOOK_STYLE.PINK] = {
		name = "Pink",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook" .. "Pink",
		color = GEM_BOOK_COLORS.PINK,
	},
	[BOOK_STYLE.RED] = {
		name = "Red",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook" .. "Red",
		color = GEM_BOOK_COLORS.RED,
	},
	[BOOK_STYLE.YELLOW] = {
		name = "Yellow",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook" .. "Yellow",
		color = GEM_BOOK_COLORS.YELLOW,
	},
	[BOOK_STYLE.ARCWOLF] = {
		name = "Arcwolf",
		tex = QUICKCAST_ASSETS_PATH .. "/ArcWolf",
		colorGradient = { min = GEM_BOOK_COLORS.BLUE, max = ADDON_COLORS.LIGHT_PURPLE },
		useTexForIcon = true,
	},
	[BOOK_STYLE.ARCANOWL] = {
		name = "Arcanowl",
		tex = QUICKCAST_ASSETS_PATH .. "/Owl",
		colorGradient = { min = GEM_BOOK_COLORS.INDIGO, max = GEM_BOOK_COLORS.BLUE },
		useTexForIcon = true,
	},
	[BOOK_STYLE.TEACUP] = {
		name = "Teacup",
		tex = QUICKCAST_ASSETS_PATH .. "/Teacup",
		colorGradient = { min = GEM_BOOK_COLORS.BLUE, max = GEM_BOOK_COLORS.INDIGO },
		useTexForIcon = true,
	},
}

---@param style BookStyle
---@return BookStyleData
local function getStyleData(style)
	return BOOK_STYLE_DATA[style]
end

---@class UI_Quickcast_Style
ns.UI.Quickcast.Style = {
	BOOK_STYLE = BOOK_STYLE,
	BOOK_STYLE_DATA = BOOK_STYLE_DATA,
	getStyleData = getStyleData,
}
