---@class ns
local ns = select(2, ...)

local rowHeight = 45

---@param frame Frame
---@return SpellVaultFrame
local function createScrollFrame(frame)
	---@class SpellVaultFrame: ScrollFrame, UIPanelScrollFrameTemplate
	local spellVaultFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")

	spellVaultFrame:SetPoint("TOPLEFT", 0, -28)
	spellVaultFrame:SetPoint("BOTTOMRIGHT", -24, 0)

	spellVaultFrame.ScrollBar.scrollStep = rowHeight + 5
	spellVaultFrame.ScrollBar:SetPoint("TOPLEFT", spellVaultFrame, "TOPRIGHT", 6, 10)

	spellVaultFrame.LoadingText = spellVaultFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	spellVaultFrame.LoadingText:SetPoint("TOP", 0, -100)
	spellVaultFrame.LoadingText:SetText("Loading...")

	local scrollChild = CreateFrame("Frame")
	spellVaultFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(SCForgeMainFrame.LoadSpellFrame.Inset:GetWidth() - 12)
	scrollChild:SetHeight(1)
	spellVaultFrame.scrollChild = scrollChild

	return spellVaultFrame
end

---@param loadSpellFrame LoadSpellFrame
local function init(loadSpellFrame)
	return createScrollFrame(loadSpellFrame.Inset)
end

---@class UI_SpellVaultFrame
ns.UI.SpellVaultFrame = {
	init = init,
}
