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

local addonChannel = GetChannelName("scforge_comm") -- This will be reset later in SpellCreator.lua, however we need to access it in other modules. It's not technically a constant but we can treat it as such because it will should never change in a session? That's my excuse for putting it here.

ns.Constants = {
    ADDON_COLOR = "|cff" .. "ce2eff", -- options: 7e1af0 (hard to read) -- 7814ea -- 8a30f1 -- 9632ff
    ADDON_PATH = addonPath,
	ADDON_CHANNEL = addonChannel,
    ADDON_TITLE = GetAddOnMetadata(addonName, "Title"),
    ASSETS_PATH = addonPath .. "/assets",
	SPELL_VISIBILITY = SPELL_VISIBILITY,
	START_ZONE_NAME = "Dranosh Valley",
    VAULT_TYPE = VAULT_TYPE,
}
