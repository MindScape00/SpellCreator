--[=[

    MindScape's AceGUI-3.0 Widgets
    * Label that always has a height of 0 for creating newline effects that don't create excessive space

    This is a copy of the default AceGUIWidget-Label but with most of the label stripped back.
	Does not support images, or actually having text / font etc, because that's not the point.

--]=]

-- Create a new AceGUI widget type
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local Type = "MAW-Newline"
local Version = 1

-- Exit if a current or newer version is loaded.
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local max, select, pairs = math.max, select, pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

local function UpdateImageAnchor(self)
	if self.resizing then return end
	local frame = self.frame
	local width = frame.width or frame:GetWidth() or 0
	local image = self.image
	local label = self.label
	local height = 0

	label:ClearAllPoints()
	image:ClearAllPoints()

	-- no image shown
	label:SetPoint("TOPLEFT")
	label:SetWidth(width)

	self.resizing = true
	frame:SetHeight(height)
	frame.height = height
	self.resizing = nil
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- set the flag to stop constant size updates
		self.resizing = true
		-- height is set dynamically by the text and image size
		self:SetWidth(200)
		self:SetText()
		self:SetImage(nil)
		self:SetImageSize(16, 16)
		self:SetColor()
		self:SetFontObject()
		self:SetJustifyH("LEFT")
		self:SetJustifyV("TOP")

		-- reset the flag
		self.resizing = nil
		-- run the update explicitly
		UpdateImageAnchor(self)
	end,

	-- ["OnRelease"] = nil,

	["OnWidthSet"] = function(self, width)
		UpdateImageAnchor(self)
	end,

	["SetText"] = function(self, text)

	end,

	["SetColor"] = function(self, r, g, b)

	end,

	["SetImage"] = function(self, path, ...)
		UpdateImageAnchor(self)
	end,

	["SetFont"] = function(self, font, height, flags)
	end,

	["SetFontObject"] = function(self, font)
	end,

	["SetImageSize"] = function(self, width, height)
		UpdateImageAnchor(self)
	end,

	["SetJustifyH"] = function(self, justifyH)
	end,

	["SetJustifyV"] = function(self, justifyV)
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	local image = frame:CreateTexture(nil, "BACKGROUND")

	-- create widget
	local widget = {
		label = label,
		image = image,
		frame = frame,
		type  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

-- Register the custom widget type with AceGUI
AceGUI:RegisterWidgetType(Type, Constructor, Version)
