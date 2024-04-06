---@class ns
local ns = select(2, ...)

local MainFrame = ns.UI.MainFrame.MainFrame

local columnWidths = MainFrame.size.columnWidths

local titleBar = CreateFrame("Frame", nil, SCForgeMainFrame.Inset)
titleBar:SetPoint("TOPLEFT", SCForgeMainFrame.Inset, "TOPLEFT", 25, -8)
titleBar:SetSize(MainFrame.size.x - 50, 24)
--titleBar:SetHeight(20)

local background = titleBar:CreateTexture(nil, "BACKGROUND", nil, 5)
background:SetAllPoints()
--background:SetColorTexture(0,0,0,1)
background:SetAtlas("Rewards-Shadow") -- AftLevelup-ToastBG; Garr_BuildingInfoShadow; Rewards-Shadow
background:SetAlpha(0.5)
background:SetPoint("TOPLEFT", -20, 0)
background:SetPoint("BOTTOMRIGHT", 10, -3)

titleBar.Background = background

local overlay = titleBar:CreateTexture(nil, "BACKGROUND", nil, 6)
--overlay:SetAllPoints(titleBar.Background)
overlay:SetPoint("TOPLEFT", -3, 0)
overlay:SetPoint("BOTTOMRIGHT", -8, -3)
--overlay:SetTexture(ADDON_PATH.."/assets/SpellForgeMainPanelRow2")
overlay:SetAtlas("search-select") -- Garr_CostBar
overlay:SetDesaturated(true)
overlay:SetVertexColor(0.35, 0.7, 0.85)
overlay:SetTexCoord(0.075, 0.925, 0, 1)
--overlay:SetTexCoord(0.208,1-0.209,0,1-0)

titleBar.Overlay = overlay

local mainDelay = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
mainDelay:SetWidth(columnWidths.delay)
mainDelay:SetJustifyH("CENTER")
mainDelay:SetPoint("LEFT", titleBar, "LEFT", 25, 0)
mainDelay:SetText("Delay")

titleBar.MainDelay = mainDelay

local action = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
action:SetWidth(columnWidths.action + 50)
action:SetJustifyH("CENTER")
action:SetPoint("LEFT", titleBar.MainDelay, "RIGHT", 0, 0)
action:SetText("Action")

titleBar.Action = action

local self = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
self:SetWidth(columnWidths.self + 10)
self:SetJustifyH("CENTER")
self:SetPoint("LEFT", titleBar.Action, "RIGHT", -9, 0)
self:SetText("Self")

titleBar.Self = self

local inputEntry = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
inputEntry:SetWidth(columnWidths.inputEntry)
inputEntry:SetJustifyH("CENTER")
inputEntry:SetPoint("LEFT", titleBar.Self, "RIGHT", 5, 0)
inputEntry:SetText("Input")

titleBar.InputEntry = inputEntry

local revertDelay = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
revertDelay:SetWidth(columnWidths.revertDelay)
revertDelay:SetJustifyH("CENTER")
revertDelay:SetPoint("LEFT", titleBar.InputEntry, "RIGHT", 25, 0)
revertDelay:SetText("Revert")

titleBar.RevertDelay = revertDelay

local conditional = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
conditional:SetWidth(columnWidths.conditional)
conditional:SetJustifyH("CENTER")
conditional:SetPoint("LEFT", titleBar.RevertDelay, "RIGHT", 5, 0)
conditional:SetText("If")

titleBar.Conditional = conditional

SCForgeMainFrame.TitleBar = titleBar
