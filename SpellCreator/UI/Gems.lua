---@class ns
local ns = select(2, ...)

local ASSETS_PATH = ns.Constants.ASSETS_PATH

local arcaneGemPath = ASSETS_PATH .. "/gem-icons/Gem"
local arcaneGemIcons = {
    "Blue",
    --"Green",
    "Indigo",
    "Jade",
    "Orange",
    "Pink",
    "Prismatic",
    "Red",
    "Violet",
    --"Yellow",
}

local function gemPath(gem)
    return arcaneGemPath .. gem
end

local function randomGem()
    return gemPath(arcaneGemIcons[fastrandom(#arcaneGemIcons)])
end

---@class UI_Gems
ns.UI.Gems = {
    arcaneGemIcons = arcaneGemIcons,

    gemPath = gemPath,
    randomGem = randomGem,
}
