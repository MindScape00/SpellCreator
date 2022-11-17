local addonName = ...
---@class ns
local ns = select(2, ...)

---@type string
local addonPath = "Interface/AddOns/" .. tostring(addonName)

ns.Constants = {
    ADDON_COLOR = "|cff" .. "ce2eff", -- options: 7e1af0 (hard to read) -- 7814ea -- 8a30f1 -- 9632ff
    ADDON_PATH = addonPath,
    ADDON_TITLE = GetAddOnMetadata(addonName, "Title"),
    ASSETS_PATH = addonPath .. "/assets",
}
