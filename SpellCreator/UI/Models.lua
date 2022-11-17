---@class ns
local ns = select(2, ...)

local minimapModels = {
    {disp = 58836, camScale = 1}, -- Purple Missle
    {disp = 71960, camScale = 1}, -- Nightborne Missle
    --{disp = 91994, camScale = 1}, -- Void Sporadic
    {disp = 92827, camScale = 0.95}, -- Void Scrolling
    {disp = 31497, camScale = 5, alpha=0.7}, -- Arcane Portal
    --{disp = 39581, camScale = 5}, -- Blue Portalish - not great
    {disp = 61420, camScale = 2.5}, -- Purple Portal
    {disp = 66092, camScale = 3, alpha=0.2}, -- Thick Purple Magic Ring
    {disp = 74190, camScale = 3, alpha=0.25}, -- Thick Blue Magic Ring
    {disp = 88991, camScale = 6.5}, -- Void Ring
}

local function modelFrameSetModel(frame, id, list)
    id = tonumber(id)
    frame:SetDisplayInfo(list[id].disp)
    frame:SetCamDistanceScale(list[id].camScale)
    frame:SetRotation(0)
    frame:SetModelAlpha(list[id].alpha or 1)
end

---@class UI_Models
ns.UI.Models = {
    minimapModels = minimapModels,
    modelFrameSetModel = modelFrameSetModel,
}
