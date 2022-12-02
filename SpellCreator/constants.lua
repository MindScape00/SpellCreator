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
ns.Constants = {
    ADDON_COLOR = "|cff" .. "ce2eff", -- options: 7e1af0 (hard to read) -- 7814ea -- 8a30f1 -- 9632ff
    ADDON_PATH = addonPath,
    ADDON_TITLE = GetAddOnMetadata(addonName, "Title"),
    ASSETS_PATH = addonPath .. "/assets",
	SPELL_VISIBILITY = SPELL_VISIBILITY,
    VAULT_TYPE = VAULT_TYPE,
}
