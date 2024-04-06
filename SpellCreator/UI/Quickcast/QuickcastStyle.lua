---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

local ADDON_COLORS = Constants.ADDON_COLORS
local ASSETS_PATH = Constants.ASSETS_PATH
local GEM_BOOK_COLORS = ADDON_COLORS.GEM_BOOK
local QUICKCAST_ASSETS_PATH = ASSETS_PATH .. "/Quickcast"

local event_unlock_dates = {
	--halloween2023 = Constants.eventUnlockDates.halloween2023
}

local QC_COLORS = {
	SPECTRAL_BLUE = CreateColorFromHexString("FF28d8f8"),
	SPECTRAL_PURPLE = CreateColorFromHexString("FFb804f0"),
	SPECTRAL_CYAN = CreateColorFromHexString("FF4df0f8"),
}

---@enum BookStyle
local BOOK_STYLE = {
	DEFAULT = 1,

	-- Spell Books
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

	-- Arc Spirits
	ARCFOX = 12,
	ARCANOWL = 13,
	TEACUP = 14,

	-- Spell Pages
	PAGE_PRISMATIC = 15,
	PAGE_PINK = 16,
	PAGE_VIOLET = 17,
	PAGE_INDIGO = 18,
	PAGE_BLUE = 19,
	PAGE_JADE = 20,
	PAGE_GREEN = 21,
	PAGE_YELLOW = 22,
	PAGE_ORANGE = 23,
	PAGE_RED = 24,

	-- Orbs
	ORB_PRISMATIC = 25,
	ORB_PINK = 26,
	ORB_VIOLET = 27,
	ORB_INDIGO = 28,
	ORB_BLUE = 29,
	ORB_JADE = 30,
	ORB_GREEN = 31,
	ORB_YELLOW = 32,
	ORB_ORANGE = 33,
	ORB_RED = 34,

	-- Halloween 2023
	HALLOWEEN_SPELLBOOK = 35,
	HALLOWEEN_EPSINOMICON = 36,
	HALLOWEEN_ORB = 37,
	HALLOWEEN_CANDY1 = 38,
	HALLOWEEN_CANDY2 = 39,
	HALLOWEEN_CUPCAKE = 40,
	HALLOWEEN_PUMPKIN = 41,
}

---@alias ColorGradient { min: ColorMixin, max: ColorMixin }
---@alias IconData {tex: string, width: integer, height?: integer}

---@class BookStyleData
---@field name string
---@field tex string file path
---@field category string?
---@field color ColorMixin?
---@field colorGradient ColorGradient?
---@field useTexForIcon? boolean
---@field iconData? IconData
---@field tooltipTitle? string
---@field tooltipText? string
---@field requirement? string
---@field requirementDate? {year: integer, month: integer, day: integer}
---@field requirementTipTitle? string
---@field requirementTipText? string

---@type { [BookStyle]: BookStyleData }
local BOOK_STYLE_DATA = {
	[BOOK_STYLE.DEFAULT] = {
		name = "Default",
		tex = QUICKCAST_ASSETS_PATH .. "/quickcast_main",
		color = ADDON_COLORS.GAME_GOLD,
	},
	[BOOK_STYLE.PRISMATIC] = {
		name = "Prismatic Book",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook/Spellbook" .. "Prismatic",
		colorGradient = { min = ADDON_COLORS.ADDON_COLOR, max = ADDON_COLORS.LIGHT_PURPLE },
		iconData = { tex = ASSETS_PATH .. "/InterfaceSwatchPrismatic", width = 4 },
		category = "Spell Books",
	},
	[BOOK_STYLE.PINK] = {
		name = "Pink Book",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook/Spellbook" .. "Pink",
		color = GEM_BOOK_COLORS.PINK,
		category = "Spell Books",
	},
	[BOOK_STYLE.VIOLET] = {
		name = "Violet Book",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook/Spellbook" .. "Violet",
		color = GEM_BOOK_COLORS.VIOLET,
		category = "Spell Books",
	},
	[BOOK_STYLE.INDIGO] = {
		name = "Indigo Book",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook/Spellbook" .. "Indigo",
		color = GEM_BOOK_COLORS.INDIGO,
		category = "Spell Books",
	},
	[BOOK_STYLE.BLUE] = {
		name = "Blue Book",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook/Spellbook" .. "Blue",
		color = GEM_BOOK_COLORS.BLUE,
		category = "Spell Books",
	},
	[BOOK_STYLE.JADE] = {
		name = "Jade Book",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook/Spellbook" .. "Jade",
		color = GEM_BOOK_COLORS.JADE,
		category = "Spell Books",
	},
	[BOOK_STYLE.GREEN] = {
		name = "Green Book",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook/Spellbook" .. "Green",
		color = GEM_BOOK_COLORS.GREEN,
		category = "Spell Books",
	},
	[BOOK_STYLE.YELLOW] = {
		name = "Yellow Book",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook/Spellbook" .. "Yellow",
		color = GEM_BOOK_COLORS.YELLOW,
		category = "Spell Books",
	},
	[BOOK_STYLE.ORANGE] = {
		name = "Orange Book",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook/Spellbook" .. "Orange",
		color = GEM_BOOK_COLORS.ORANGE,
		category = "Spell Books",
	},
	[BOOK_STYLE.RED] = {
		name = "Red Book",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellbook/Spellbook" .. "Red",
		color = GEM_BOOK_COLORS.RED,
		category = "Spell Books",
	},

	-- Arc Spirits
	[BOOK_STYLE.ARCFOX] = {
		name = "Arcfox",
		tex = QUICKCAST_ASSETS_PATH .. "/Arcanum_Spirits" .. "/ArcFox",
		colorGradient = { min = GEM_BOOK_COLORS.BLUE, max = ADDON_COLORS.LIGHT_PURPLE },
		useTexForIcon = true,
		tooltipTitle = "The playful Fox goes unseen by the world..",
		tooltipText = "Because it's too good at hide and seek!\n\rFind the Fox's Shrine in Dranosh Valley!",
		category = "Arc Spirits",
	},
	[BOOK_STYLE.ARCANOWL] = {
		name = "Arcanowl",
		tex = QUICKCAST_ASSETS_PATH .. "/Arcanum_Spirits" .. "/Owl",
		colorGradient = { min = GEM_BOOK_COLORS.INDIGO, max = GEM_BOOK_COLORS.BLUE },
		useTexForIcon = true,
		tooltipTitle = "The Arcanowl knows many things..",
		tooltipText = "Fortunately, this owl is willing to share its knowledge.\n\rFind the Owl's Shrine in Dranosh Valley!",
		category = "Arc Spirits",
	},
	[BOOK_STYLE.TEACUP] = {
		name = "Teacup",
		tex = QUICKCAST_ASSETS_PATH .. "/Arcanum_Spirits" .. "/Teacup",
		colorGradient = { min = GEM_BOOK_COLORS.BLUE, max = GEM_BOOK_COLORS.INDIGO },
		useTexForIcon = true,
		tooltipTitle = "The Teacup holds the secrets of peace & spirit..",
		tooltipText = "Savor the moment, and embrace the tranquility contained within.\n\rFind the Tea Shrine in Dranosh Valley & have a drink!",
		category = "Arc Spirits",
	},

	-- Pages
	[BOOK_STYLE.PAGE_PRISMATIC] = {
		name = "Prismatic Page",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellpage/Spellpage" .. "Prismatic",
		colorGradient = { min = ADDON_COLORS.ADDON_COLOR, max = ADDON_COLORS.LIGHT_PURPLE },
		iconData = { tex = ASSETS_PATH .. "/InterfaceSwatchPrismatic", width = 4 },
		category = "Spell Pages",
	},
	[BOOK_STYLE.PAGE_PINK] = {
		name = "Pink Page",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellpage/Spellpage" .. "Pink",
		color = GEM_BOOK_COLORS.PINK,
		category = "Spell Pages",
	},
	[BOOK_STYLE.PAGE_VIOLET] = {
		name = "Violet Page",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellpage/Spellpage" .. "Violet",
		color = GEM_BOOK_COLORS.VIOLET,
		category = "Spell Pages",
	},
	[BOOK_STYLE.PAGE_INDIGO] = {
		name = "Indigo Page",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellpage/Spellpage" .. "Indigo",
		color = GEM_BOOK_COLORS.INDIGO,
		category = "Spell Pages",
	},
	[BOOK_STYLE.PAGE_BLUE] = {
		name = "Blue Page",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellpage/Spellpage" .. "Blue",
		color = GEM_BOOK_COLORS.BLUE,
		category = "Spell Pages",
	},
	[BOOK_STYLE.PAGE_JADE] = {
		name = "Jade Page",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellpage/Spellpage" .. "Jade",
		color = GEM_BOOK_COLORS.JADE,
		category = "Spell Pages",
	},
	[BOOK_STYLE.PAGE_GREEN] = {
		name = "Green Page",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellpage/Spellpage" .. "Green",
		color = GEM_BOOK_COLORS.GREEN,
		category = "Spell Pages",
	},
	[BOOK_STYLE.PAGE_YELLOW] = {
		name = "Yellow Page",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellpage/Spellpage" .. "Yellow",
		color = GEM_BOOK_COLORS.YELLOW,
		category = "Spell Pages",
	},
	[BOOK_STYLE.PAGE_ORANGE] = {
		name = "Orange Page",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellpage/Spellpage" .. "Orange",
		color = GEM_BOOK_COLORS.ORANGE,
		category = "Spell Pages",
	},
	[BOOK_STYLE.PAGE_RED] = {
		name = "Red Page",
		tex = QUICKCAST_ASSETS_PATH .. "/Spellpage/Spellpage" .. "Red",
		color = GEM_BOOK_COLORS.RED,
		category = "Spell Pages",
	},

	-- Orbs
	[BOOK_STYLE.ORB_PRISMATIC] = {
		name = "Prismatic Orb",
		tex = QUICKCAST_ASSETS_PATH .. "/Orb/Orb" .. "Prismatic",
		colorGradient = { min = ADDON_COLORS.ADDON_COLOR, max = ADDON_COLORS.LIGHT_PURPLE },
		iconData = { tex = ASSETS_PATH .. "/InterfaceSwatchPrismatic", width = 4 },
		category = "Orbs",
	},
	[BOOK_STYLE.ORB_PINK] = {
		name = "Pink Orb",
		tex = QUICKCAST_ASSETS_PATH .. "/Orb/Orb" .. "Pink",
		color = GEM_BOOK_COLORS.PINK,
		category = "Orbs",
	},
	[BOOK_STYLE.ORB_VIOLET] = {
		name = "Violet Orb",
		tex = QUICKCAST_ASSETS_PATH .. "/Orb/Orb" .. "Violet",
		color = GEM_BOOK_COLORS.VIOLET,
		category = "Orbs",
	},
	[BOOK_STYLE.ORB_INDIGO] = {
		name = "Indigo Orb",
		tex = QUICKCAST_ASSETS_PATH .. "/Orb/Orb" .. "Indigo",
		color = GEM_BOOK_COLORS.INDIGO,
		category = "Orbs",
	},
	[BOOK_STYLE.ORB_BLUE] = {
		name = "Blue Orb",
		tex = QUICKCAST_ASSETS_PATH .. "/Orb/Orb" .. "Blue",
		color = GEM_BOOK_COLORS.BLUE,
		category = "Orbs",
	},
	[BOOK_STYLE.ORB_JADE] = {
		name = "Jade Orb",
		tex = QUICKCAST_ASSETS_PATH .. "/Orb/Orb" .. "Jade",
		color = GEM_BOOK_COLORS.JADE,
		category = "Orbs",
	},
	[BOOK_STYLE.ORB_GREEN] = {
		name = "Green Orb",
		tex = QUICKCAST_ASSETS_PATH .. "/Orb/Orb" .. "Green",
		color = GEM_BOOK_COLORS.GREEN,
		category = "Orbs",
	},
	[BOOK_STYLE.ORB_YELLOW] = {
		name = "Yellow Orb",
		tex = QUICKCAST_ASSETS_PATH .. "/Orb/Orb" .. "Yellow",
		color = GEM_BOOK_COLORS.YELLOW,
		category = "Orbs",
	},
	[BOOK_STYLE.ORB_ORANGE] = {
		name = "Orange Orb",
		tex = QUICKCAST_ASSETS_PATH .. "/Orb/Orb" .. "Orange",
		color = GEM_BOOK_COLORS.ORANGE,
		category = "Orbs",
	},
	[BOOK_STYLE.ORB_RED] = {
		name = "Red Orb",
		tex = QUICKCAST_ASSETS_PATH .. "/Orb/Orb" .. "Red",
		color = GEM_BOOK_COLORS.RED,
		category = "Orbs",
	},

	-- Halloween 2023
	[BOOK_STYLE.HALLOWEEN_SPELLBOOK] = {
		name = "Spectral Spellbook",
		tex = QUICKCAST_ASSETS_PATH .. "/Holidays/" .. "SpellBookOpen",
		colorGradient = { min = QC_COLORS.SPECTRAL_CYAN, max = GEM_BOOK_COLORS.VIOLET },
		useTexForIcon = true,
		category = "Holidays",
	},
	[BOOK_STYLE.HALLOWEEN_PUMPKIN] = {
		name = "Eerie Pumpkin",
		tex = QUICKCAST_ASSETS_PATH .. "/Holidays/" .. "Pumpkin",
		colorGradient = { min = GEM_BOOK_COLORS.BLUE, max = GEM_BOOK_COLORS.VIOLET },
		useTexForIcon = true,
		category = "Holidays",
	},
	[BOOK_STYLE.HALLOWEEN_EPSINOMICON] = {
		name = "Epsinomicon",
		tex = QUICKCAST_ASSETS_PATH .. "/Holidays/" .. "HalloweenBook",
		colorGradient = { min = GEM_BOOK_COLORS.JADE, max = GEM_BOOK_COLORS.VIOLET },
		useTexForIcon = true,
		category = "Holidays",
		tooltipTitle = "Epsinomicon",
		tooltipText =
		"A sinister grimoire of untold power. Wield its forbidden knowledge at your own risk...\n\rUnlocked as part of the 2023 Epsilon Halloween Event!",
	},
	[BOOK_STYLE.HALLOWEEN_ORB] = {
		name = "Necromantic Orb",
		tex = QUICKCAST_ASSETS_PATH .. "/Holidays/" .. "HalloweenOrb",
		colorGradient = { min = GEM_BOOK_COLORS.VIOLET, max = GEM_BOOK_COLORS.GREEN },
		useTexForIcon = true,
		category = "Holidays",
		tooltipTitle = "Necromantic Orb",
		tooltipText =
		"The Orb's wailing depths of torment have ensnared the souls of countless adventurers who dared to peer too closely, sealing their grim fate.\n\rUnlocked as part of the 2023 Epsilon Halloween Event!",
	},
	[BOOK_STYLE.HALLOWEEN_CANDY1] = {
		name = "Boiled Sweets",
		tex = QUICKCAST_ASSETS_PATH .. "/Holidays/" .. "BoiledSweets",
		colorGradient = { min = QC_COLORS.SPECTRAL_BLUE, max = QC_COLORS.SPECTRAL_PURPLE },
		useTexForIcon = true,
		category = "Holidays",
		tooltipTitle = "Boiled Sweets",
		tooltipText =
		"A handful of spectral candy. It's safe to eat.. Probably!\n\rUnlocked as part of the 2023 Trail of Treats Event!",
	},
	[BOOK_STYLE.HALLOWEEN_CANDY2] = {
		name = "Caramel Candy",
		tex = QUICKCAST_ASSETS_PATH .. "/Holidays/" .. "Caramel",
		colorGradient = { min = QC_COLORS.SPECTRAL_PURPLE, max = QC_COLORS.SPECTRAL_BLUE },
		useTexForIcon = true,
		category = "Holidays",
		tooltipTitle = "Caramel Candy",
		tooltipText =
		"A sweet, chewy caramel. This particular kind is a delicacy among ghosts!\n\rUnlocked as part of the 2023 Trail of Treats Event!",
	},
	[BOOK_STYLE.HALLOWEEN_CUPCAKE] = {
		name = "Phantastic Cupcake",
		tex = QUICKCAST_ASSETS_PATH .. "/Holidays/" .. "Cupcake",
		colorGradient = { min = QC_COLORS.SPECTRAL_BLUE, max = GEM_BOOK_COLORS.INDIGO },
		useTexForIcon = true,
		category = "Holidays",
		tooltipTitle = "Phantastic Cupcake",
		tooltipText =
		"Vanilla Cupcake with a 'phantastic' buttercream frosting & topped with a prismatic gem candy. If ghosts could drool, it would be for this.\n\rUnlocked as part of the 2023 Trail of Treats Event!",
		--requirement = "halloween_qc_candy",
		--requirementDate = halloweenUnlockDate,
		--requirementTipTitle = "Phantastic Cupcake",
		--requirementTipText = "Vanilla Cupcake with a phantastic buttercream frosting & topped with a prismatic gem candy. If ghosts could drool, it would be for this.\n\rParticipate in the 2023 Trail of Treats Event to Unlock early! Unlocks for everyone on Halloween!",
	},
}

local categoryOrder = {
	"Spell Books",
	"Spell Pages",
	"Orbs",
	"Arc Spirits",
	"Holidays",
}

---@param style BookStyle
---@return BookStyleData
local function getStyleData(style)
	return BOOK_STYLE_DATA[style]
end

---Search & return a style data by style name, case in-sensitive
---@param styleName string
---@return BookStyle|nil, BookStyleData|nil
local function findStyleByName(styleName)
	for index, data in ipairs(BOOK_STYLE_DATA) do
		if string.lower(data.name) == string.lower(styleName) then
			return index, data
		end
	end
end

---@param styleNameOrID any
---@return (BookStyle|nil)?
local function getStyleIDFromNameOrID(styleNameOrID)
	local theStyle

	-- if number, assume style ID, else convert string to style ID
	if tonumber(styleNameOrID) then
		theStyle = tonumber(styleNameOrID)
	else
		---@cast styleNameOrID string
		-- check if the style exists by direct name, otherwise try and search it up by Style Name.
		theStyle = BOOK_STYLE[strupper(styleNameOrID)]
		if not theStyle then
			theStyle = findStyleByName(styleNameOrID)
		end
	end

	return theStyle
end

---@class UI_Quickcast_Style
ns.UI.Quickcast.Style = {
	BOOK_STYLE = BOOK_STYLE,
	BOOK_STYLE_DATA = BOOK_STYLE_DATA,
	getStyleData = getStyleData,
	findStyleByName = findStyleByName,

	getStyleIDFromNameOrID = getStyleIDFromNameOrID,

	categoryOrder = categoryOrder,
}
