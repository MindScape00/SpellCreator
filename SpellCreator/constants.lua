local addonName = ...
---@class ns
local ns = select(2, ...)

---@type string
local addonPath = "Interface/AddOns/" .. tostring(addonName)

local ADDON_TITLE = GetAddOnMetadata(addonName, "Title")

ARC = {}
ARC.VAR = {}
ARC._DEBUG = {}

---@enum SpellVisibility
local SPELL_VISIBILITY = {
	PRIVATE = "Private",
	PUBLIC = "Public"
}

---@enum VaultType
local VAULT_TYPE = {
	PERSONAL = "PERSONAL",
	PHASE = "PHASE",
}

local CONDITION_DATA_KEY = "_conditionData"

local SPARK_CREATE_UI_NAME = "ARCANUM_SPARK_CREATE"

local ADDON_COLORS = {
	ADDON_COLOR = CreateColorFromHexString("ffce2eff"),          -- ce2eff : Purple -- options: 7e1af0 (hard to read) -- 7814ea -- 8a30f1 -- 9632ff
	UPDATED = CreateColorFromHexString("ff57F287"),              -- 57F287 : Green
	LIGHT_PURPLE = CreateColorFromHexString("ffAAAAFF"),         -- AAAAFF : Light Purple
	GAME_GOLD = CreateColorFromHexString("FFFFD700"),            -- FFD700 : Game Gold | Also used as FFD100 in some places?
	QC_DARKRED = CreateColorFromHexString("ffAA6F6F"),           -- AA6F6F : Dark Red
	MENU_SELECTED = CreateColorFromHexString("ffFFA600"),        -- FFA600 : Orange-Gold
	TOOLTIP_EXAMPLE = CreateColorFromHexString("ff85FF85"),      -- 85FF85 : Mint Green
	TOOLTIP_REVERT = CreateColorFromHexString("ffFFA600"),       -- FFA600 : Orange-Gold
	TOOLTIP_NOREVERT = CreateColorFromHexString("ffAAAAAA"),     -- AAAAAA : Mid Grey
	TOOLTIP_CONTRAST = CreateColorFromHexString("FFFFAAAA"),     -- FFAAAA : Light Red
	TOOLTIP_WARNINGRED = CreateColorFromHexString("FFFF0000"),   -- FF0000 : Bright Red
	LIGHT_BLUE_ALMOST_WHITE = CreateColorFromHexString("FFd7eef1"), -- d7eef1 : Light Light Blue
	GEM_BOOK = {
		--PRISMATIC = CreateColorFromBytes(),
		PINK = CreateColorFromBytes(240, 24, 216, 255),
		INDIGO = CreateColorFromBytes(64, 48, 208, 255),
		VIOLET = CreateColorFromBytes(152, 24, 240, 255),
		BLUE = CreateColorFromBytes(40, 188, 216, 255),
		GREEN = CreateColorFromBytes(96, 216, 48, 255),
		JADE = CreateColorFromBytes(46, 216, 128, 255),
		YELLOW = CreateColorFromBytes(240, 212, 24, 255),
		ORANGE = CreateColorFromBytes(205, 123, 56, 255),
		RED = CreateColorFromBytes(224, 36, 32, 255),
	}
}

local eventUnlockDates = {
	halloween2023 = { year = 2023, month = 10, day = 31 },
}

--local broadcastChannelName = "xtensionxtooltip2"
local broadcastChannelName = "scforge_comm"               -- TODO: CHANGE THIS TO XTENSIONXTOOLTIP2 WHEN MOVING TO SL
local addonChannel = GetChannelName(broadcastChannelName) -- This will be reset later in SpellCreator.lua, however we need to access it in other modules. It's not technically a constant but we can treat it as such because it will should never change in a session? That's my excuse for putting it here.

ns.Constants = {
	ADDON_COLOR = ADDON_COLORS.ADDON_COLOR:GenerateHexColorMarkup(),
	ADDON_COLORS = ADDON_COLORS,
	ADDON_PATH = addonPath,
	ADDON_CHANNEL = addonChannel,
	---@cast ADDON_TITLE -nil
	ADDON_TITLE = ADDON_TITLE,
	ASSETS_PATH = addonPath .. "/assets",
	SPELL_VISIBILITY = SPELL_VISIBILITY,
	START_ZONE_NAME = "Dranosh Valley",
	DEFAULT_QC_BOOK_NAME = "Quickcast Book %s",
	VAULT_TYPE = VAULT_TYPE,
	CHARACTER_NAME = UnitName("player"),

	SPARK_DEFAULT_KEYBIND = "F",
	SPARK_CREATE_UI_NAME = SPARK_CREATE_UI_NAME,

	CONDITION_DATA_KEY = CONDITION_DATA_KEY,

	broadcastChannelName = broadcastChannelName,

	eventUnlockDates = eventUnlockDates,
}
