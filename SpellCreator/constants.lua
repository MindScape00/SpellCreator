local addonName = ...
---@class ns
local ns = select(2, ...)

---@type string
local addonPath = "Interface/AddOns/" .. tostring(addonName)

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

local ADDON_COLORS = {
	ADDON_COLOR = CreateColorFromHexString("ffce2eff"), -- ce2eff : Purple -- options: 7e1af0 (hard to read) -- 7814ea -- 8a30f1 -- 9632ff
	UPDATED = CreateColorFromHexString("ff57F287"), -- 57F287 : Green
	LIGHT_PURPLE = CreateColorFromHexString("ffAAAAFF"), -- AAAAFF : Light Purple
	GAME_GOLD = CreateColorFromHexString("ffFFD700"), -- FFD700 : Game Gold | Also used as FFD100 in some places?
	QC_DARKRED = CreateColorFromHexString("ffAA6F6F"), -- AA6F6F : Dark Red
	MENU_SELECTED = CreateColorFromHexString("ffFFA600"), -- FFA600 : Orange-Gold
	TOOLTIP_EXAMPLE = CreateColorFromHexString("ff85FF85"), -- 85FF85 : Mint Green
	TOOLTIP_REVERT = CreateColorFromHexString("ffFFA600"), -- FFA600 : Orange-Gold
	TOOLTIP_NOREVERT = CreateColorFromHexString("ffAAAAAA"), -- AAAAAA : Mid Grey
	TOOLTIP_CONTRAST = CreateColorFromHexString("FFFFAAAA"), -- FFAAAA : Light Red
}

local addonChannel = GetChannelName("scforge_comm") -- This will be reset later in SpellCreator.lua, however we need to access it in other modules. It's not technically a constant but we can treat it as such because it will should never change in a session? That's my excuse for putting it here.

ns.Constants = {
    ADDON_COLOR = ADDON_COLORS.ADDON_COLOR:GenerateHexColorMarkup(),
	ADDON_COLORS = ADDON_COLORS,
    ADDON_PATH = addonPath,
	ADDON_CHANNEL = addonChannel,
    ADDON_TITLE = GetAddOnMetadata(addonName, "Title"),
    ASSETS_PATH = addonPath .. "/assets",
	SPELL_VISIBILITY = SPELL_VISIBILITY,
	START_ZONE_NAME = "Dranosh Valley",
    VAULT_TYPE = VAULT_TYPE,
}
