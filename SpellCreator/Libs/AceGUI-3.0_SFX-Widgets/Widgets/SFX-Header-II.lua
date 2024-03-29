--[[

	This file is part of 'AceGUI-3.0: SFX Widgets', an add-on for World of Warcraft. For bug reports,
	documentation and license information, visit https://github.com/SFX-WoW/AceGUI-3.0_SFX-Widgets.

	* File...: SFX-Header-II.lua
	* Author.: StormFX

]]

----------------------------------------
-- Locals
---

local Type, Version = "SFX-Header-II", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

-- Exit if a current or newer version is loaded.
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local function ClearPointByName(self, name)
	local numPoints = self:GetNumPoints()
	local previousPoints = {}
	for i = 1, numPoints do
		local point = {self:GetPoint(i)}
		if point[1] ~= name then
			tinsert(previousPoints, point)
		end
	end
	self:ClearAllPoints()
	for i = 1, #previousPoints do
		local point = previousPoints[i]
		self:SetPoint(unpack(point))
	end
end

----------------------------------------
-- Lua API
---

local gsub, pairs = string.gsub, pairs

----------------------------------------
-- WoW API
---

local CreateFrame, UIParent = CreateFrame, UIParent

----------------------------------------
-- Utililty
---

-- Updates the border's visibility.
local function UpdateBorder(self)
	local Height = 26

	if self.disabled then
		self.Border:Hide()
		Height = 18
	elseif self.Text == "" then
		self.Border:Show()
		Height = 18
	else
		self.Border:Show()
	end

	self:SetHeight(Height)
end

----------------------------------------
-- Widget Methods
---

local Methods = {

	-- Widget:OnAcquire()
	-- Fires when the widget is initialized.
	OnAcquire = function(self)
		-- Reset the widget.
		self.disabled = nil
		self:SetText()
		self:SetFullWidth(true)
	end,

	-- Widget:SetDisabled()
	-- Sets the text alignment.
	SetCenter = function(self, Center)
		Center = (Center and self.Text ~= "") or nil
		self.Center = Center

		local Label = self.Label

		if Center then
			Label:ClearAllPoints()
			Label:SetPoint("TOP", 0, -3)
		else
			Label:ClearAllPoints()
			Label:SetPoint("TOPLEFT", 0, -3)
		end

		UpdateBorder(self)
	end,

	-- Widget:SetDisabled()
	-- Toggles the border.
	SetDisabled = function(self, Disabled)
		self.disabled = Disabled
		UpdateBorder(self)
	end,

	-- Widget:SetText()
	-- Sets the header text.
	SetText = function(self, Text)
		local Text, Count = gsub(Text or "", ">>>", "")
		self.Text = Text

		local Label = self.Label
		Label:SetText(Text)

		if Text == "" then
			local Border = self.Border
			local ClearPoint = Border.ClearPoint or Border.ClearPointByName or ClearPointByName

			ClearPoint(Border, "TOP")
		else
			self.Border:SetPoint("TOP", Label, "BOTTOM", 0, 2)
		end

		self:SetCenter(Count > 0)
	end,

	-- Unused Methods
	-- OnRelease = nil,
	-- OnHeightSet = nil,
	-- OnWidthSet = nil,
}

----------------------------------------
-- Constructor
---

local function Constructor()
	local Frame = CreateFrame("Frame", nil, UIParent)
	Frame:Hide()

	local Label = Frame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	Label:SetJustifyH("CENTER")
	Label:SetPoint("TOPLEFT", 0, -3)

	local Border = Frame:CreateTexture(nil, "BACKGROUND")
	Border:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
	Border:SetTexCoord(0.81, 0.94, 0.5, 1)
	Border:SetVertexColor(0.6, 0.6, 0.6)
	Border:SetHeight(8)
	Border:SetPoint("TOP", Label, "BOTTOM", 0, 2)
	Border:SetPoint("RIGHT")
	Border:SetPoint("LEFT")

	local Widget = {
		type  = Type,
		frame = Frame,

		Label = Label,
		Border = Border,
	}

	for method, func in pairs(Methods) do
		Widget[method] = func
	end

	return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
