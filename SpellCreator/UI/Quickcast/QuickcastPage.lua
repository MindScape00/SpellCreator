---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

local QuickcastAnimation = ns.UI.Quickcast.Animation
local QuickcastButton = ns.UI.Quickcast.Button
local QuickcastStyle = ns.UI.Quickcast.Style

local DataUtils = ns.Utils.Data

local ADDON_COLORS = Constants.ADDON_COLORS
local ASSETS_PATH = Constants.ASSETS_PATH

local CustomUIFrameFadeOut = QuickcastAnimation.CustomUIFrameFadeOut
local createButton = QuickcastButton.createButton

local enableSatanicLines = false

---@param self QuickcastPage
---@return BookStyle
local function Page_GetStyle(self)
	return self.style
end

---@param self QuickcastPage
---@return BookStyleData
local function Page_GetStyleData(self)
	return QuickcastStyle.getStyleData(self:GetStyle())
end

---@param self QuickcastPage
---@param style BookStyle
local function Page_SetStyle(self, style)
	self.style = style
	local bookStyle = self:GetStyleData()

	local r1, b1, g1, r2, b2, g2

	if bookStyle.colorGradient then
		self.lineFrame.border:SetVertexColor(1, 1, 1, 1)
		r1, b1, g1 = bookStyle.colorGradient.min:GetRGB()
		r2, b2, g2 = bookStyle.colorGradient.max:GetRGB()
		self.lineFrame.border:SetGradient("HORIZONTAL", r1, b1, g1, r2, b2, g2)
	else
		self.lineFrame.border:SetVertexColor(bookStyle.color:GetRGBA())
	end

	if enableSatanicLines then
		for i = 1, #self.lineFrame.lines do
			local v = self.lineFrame.lines[i]
			if bookStyle.colorGradient then
				v:SetColorTexture(1, 1, 1, 1)
				v:SetGradient("HORIZONTAL", r1, b1, g1, r2, b2, g2)
			else
				r1, b1, g1 = bookStyle.color:GetRGB()
				v:SetColorTexture(r1, b1, g1)
			end
		end
	end

	for i = 1, #self.castButtons do
		local button = self.castButtons[i]
		button:_SetStyle()
	end
end

---@param page QuickcastPage
local function createLineFrame(page)
	local lineFrame = CreateFrame("Frame", nil, page)
	lineFrame:Hide()
	lineFrame:SetSize(10, 10)
	lineFrame:SetPoint("CENTER")
	lineFrame:SetFrameStrata("LOW")

	lineFrame.border = lineFrame:CreateTexture(nil, "BORDER")
	lineFrame.border:SetAllPoints()
	lineFrame.border:SetTexture(ASSETS_PATH .. "/quickcast_runes")
	lineFrame.border:SetVertexColor(ADDON_COLORS.GAME_GOLD:GetRGBA())
	lineFrame.lines = {}

	return lineFrame
end

---@param self QuickcastPage
local function Page_HideSpellLines(self, fadeTime)
	for i = 1, #self.lineFrame.lines do
		local line = self.lineFrame.lines[i]
		UIFrameFadeRemoveFrame(line)
		if line.fadeWait then line.fadeWait:Cancel() end
		if fadeTime then
			-- do the fading here
		else
			line:Hide()
		end
	end
	if self.lineFrame:IsShown() then
		UIFrameFadeRemoveFrame(self.lineFrame)
		CustomUIFrameFadeOut(self.lineFrame, 0.25, self.lineFrame:GetAlpha(), 0)
	end
end

---@param self QuickcastPage
local function Page_DrawSpellLines(self, num)
	self:HideSpellLines()
	UIFrameFadeIn(self.lineFrame, 0.25, 0, 1)

	if not enableSatanicLines then return end

	if num < 5 then return end
	local buttonStep                                    = 2
	local finishDrawing, finishOnNext, finishOnNextNext = false, false, false
	local line                                          = 0

	if num > 8 then buttonStep = 3 end

	while finishDrawing == false do
		if finishOnNext then finishDrawing = true end
		if finishOnNextNext then finishOnNext = true end

		line = line + 1

		local buttonStart = mod(line - 1, num) + 1
		local buttonEnd = mod(line - 1 + buttonStep, num) + 1

		if not self.lineFrame.lines[line] then
			local newLine = self.lineFrame:CreateLine()

			newLine:SetThickness(1)
			newLine:Hide()

			self.lineFrame.lines[line] = newLine
		end

		local thisLine = self.lineFrame.lines[line]
		thisLine:ClearAllPoints()
		thisLine:SetStartPoint("CENTER", self.castButtons[buttonStart])
		thisLine:SetEndPoint("CENTER", self.castButtons[buttonEnd])

		local styleData = self:GetStyleData()
		if styleData.colorGradient then
			thisLine:SetColorTexture(1, 1, 1)

			local r1, b1, g1 = styleData.colorGradient.min:GetRGB()
			local r2, b2, g2 = styleData.colorGradient.max:GetRGB()
			if (line % 2 == 0) then
				thisLine:SetGradient("HORIZONTAL", r1, b1, g1, r2, b2, g2)
			else
				thisLine:SetGradient("HORIZONTAL", r2, b2, g2, r1, b1, g1)
			end
		else
			local r1, b1, g1 = styleData.color:GetRGB()
			thisLine:SetColorTexture(r1, b1, g1)
		end

		thisLine.fadeWait = C_Timer.NewTimer(0.2, function() UIFrameFadeIn(thisLine, 0.25, 0, 1) end);

		if buttonEnd == 1 then
			if buttonStep == 2 then
				finishOnNext = true
			elseif buttonStep == 3 then
				finishOnNextNext = true
			end
		end
	end
end

---@param self QuickcastPage
---@param buttonToActivate QuickcastButton?
local function Page_HideCastButtons(self, buttonToActivate)
	self.areSpellsShown = false

	for i = 1, #self.castButtons do
		local button = self.castButtons[i]
		button:FadeOut(button == buttonToActivate)
	end

	self:HideSpellLines()
end

---@generic K, V
---@param profileName string
---@return table<K, V>
local function getProfileSpells(profileName)
	local spells = DataUtils.filter(ns.Vault.personal.getSpells(), function(spell)
		return spell.profile == profileName
	end)
	return spells
end

---@param profileName string
---@return CommID[]
local function getDynamicSpells(profileName)
	return DataUtils.keys(getProfileSpells(profileName))
end

---@param self QuickcastPage
---@return CommID[]
local function Page_GetSpells(self)
	local spells
	if self.profileName then
		spells = getDynamicSpells(self.profileName)
	else
		spells = self.spells
	end
	return spells
end

---@param self QuickcastPage
---@param commID CommID
local function Page_AddSpell(self, commID)
	if not self.spells then
		self.spells = {}
	end
	tinsert(self.spells, commID)
	self:UpdateButtons()
end

---@param self QuickcastPage
---@param commID CommID
local function Page_RemoveSpell(self, commID)
	if not self.spells then return end
	tDeleteItem(self.spells, commID)
	self:UpdateButtons()
end

local function Page_ReorderSpell(self, curIndex, newIndex)
	if not self.spells then return end
	local theSpell = self.spells[curIndex]
	tremove(self.spells, curIndex)
	tinsert(self.spells, newIndex, theSpell)
end

---@param self QuickcastPage
local function Page_UpdateButtons(self)
	local _spells = self:GetSpells()
	local numSpells = #_spells
	local radius = 38 + (2 * numSpells)
	self.radius = radius

	if numSpells == 0 then return end
	self.areSpellsShown = true

	self.lineFrame:SetSize((radius) * 2, (radius) * 2)

	local maxSequenceTime = 0.5
	local maxSequenceDelay = 0.1
	local sequenceDelay = maxSequenceTime / numSpells
	sequenceDelay = math.min(sequenceDelay, maxSequenceDelay)
	if numSpells < 4 then sequenceDelay = 0 end

	for i = 1, #_spells do
		if not self.castButtons[i] then
			self.castButtons[i] = createButton(self, i)
		end

		local button = self.castButtons[i]

		local x = radius * math.cos(((i - 1) / numSpells) * (2 * math.pi));
		local y = radius * math.sin(((i - 1) / numSpells) * (2 * math.pi));

		button:SetPoint("CENTER", self, "CENTER", x, y)
		button:SetSize(30, 30)

		button:Update(_spells[i])

		button:FadeIn(sequenceDelay * i)
	end

	self:DrawSpellLines(numSpells)
end

---@param self QuickcastPage
local function Page_GetRadius(self)
	return self.radius + 15 -- this is the radius to the EDGE of the quick cast buttons, not their center
end

---@param self QuickcastPage
local function Page_GetNumSpells(self)
	return #self:GetSpells()
end

---@param self QuickcastPage
local function Page_SetProfile(self, text)
	self.profileName = text
	self:UpdateButtons()
end

---@param self QuickcastPage
local function Page_GetProfile(self)
	return self.profileName
end

---@param book QuickcastBook This is just used for defining the parent from the start
---@param spells? CommID[]
---@param profileName? string
---@return QuickcastPage
local function createPage(book, spells, profileName)
	if not spells then spells = {} end
	---@class QuickcastPage: Frame
	local page = CreateFrame("Frame", nil, book) -- Do we need to name this? If we re-assign the page to another book, it would be the wrong name, should just access thru the _pages table
	page:SetAllPoints(book)
	page:SetSize(50, 50)

	page.areSpellsShown = false
	page.castButtons = {} ---@type QuickcastButton[]
	page.lineFrame = createLineFrame(page)
	page.radius = 0
	page.spells = spells
	page.profileName = profileName

	page.GetStyle = Page_GetStyle
	page.GetStyleData = Page_GetStyleData
	page.SetStyle = Page_SetStyle
	page.GetRadius = Page_GetRadius
	page.HideSpellLines = Page_HideSpellLines
	page.DrawSpellLines = Page_DrawSpellLines
	page.HideCastButtons = Page_HideCastButtons
	page.UpdateButtons = Page_UpdateButtons
	page.GetNumSpells = Page_GetNumSpells
	page.GetSpells = Page_GetSpells
	page.ReorderSpell = Page_ReorderSpell
	page.AddSpell = Page_AddSpell
	page.RemoveSpell = Page_RemoveSpell
	page.SetProfile = Page_SetProfile
	page.GetProfile = Page_GetProfile

	return page
end

---@param book QuickcastBook
---@param page QuickcastPage
---@param pageIndexFromBookDB? integer
---@return QuickcastPage
local function createPageFromStorage(book, page, pageIndexFromBookDB)
	local newPage = createPage(book, ((type(page.spells) == "table") and CopyTable(page.spells) or nil), page.profileName)
	return newPage
end

---@class UI_Quickcast_Page
ns.UI.Quickcast.Page = {
	createPage = createPage,
	createPageFromStorage = createPageFromStorage,
}
