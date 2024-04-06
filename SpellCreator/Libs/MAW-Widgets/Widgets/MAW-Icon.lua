--[=[

    MindScape's AceGUI-3.0 Widgets
    * Icon with Better Click Visuals

    This Icon copies the default AceGUI-3.0 Icon Implementation but
    modifies the icon to react to Clicks with better visuals.

--]=]

-- Create a new AceGUI widget type
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local Type = "MAW-Icon"
local Version = 1

-- Exit if a current or newer version is loaded.
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local function setTextureOffset(frameTexture, x, y)
	frameTexture:SetVertexOffset(UPPER_LEFT_VERTEX, x, y)
	frameTexture:SetVertexOffset(UPPER_RIGHT_VERTEX, x, y)
	frameTexture:SetVertexOffset(LOWER_LEFT_VERTEX, x, y)
	frameTexture:SetVertexOffset(LOWER_RIGHT_VERTEX, x, y)
end

local function setHighlightToOffsetWithPushed(frame, highlight, normal, x, y)
	if not x then x = 1 end
	if not y then y = -1 end
	frame:HookScript("OnMouseDown", function(self)
		normal:Hide(); setTextureOffset(highlight, x, y)
	end)
	frame:HookScript("OnMouseUp", function(self)
		normal:Show(); setTextureOffset(highlight, 0, 0)
	end)
end

-- Constructor function
local function Constructor()
	local object = AceGUI:Create("Icon") -- Create an instance of the AceGUI widget
	local frame = object.frame
	local label = object.label
	local image = object.image

	local regions = { frame:GetRegions() }
	for i, child in ipairs(regions) do
		if child.GetTexture then
			if child:GetTexture() == 136580 then
				object.highlight = child
			end
		end
	end
	local highlight = object.highlight

	frame:SetPushedTexture(136580)
	object.pushed = frame:GetPushedTexture()
	local pushed = object.pushed
	setTextureOffset(pushed, 1, -1)

	--[[
	local original_OnAcquire = object["OnAcquire"]
	object["OnAcquire"] = function(...)
		original_OnAcquire(...)
	end
	--]]

	local original_SetImage = object["SetImage"]
	object["SetImage"] = function(self, path, ...)
		original_SetImage(self, path, ...)

		local pushed = self.pushed
		pushed:SetTexture(path)
		pushed:SetAllPoints(image)
		if pushed:GetTexture() then
			local n = select("#", ...)
			if n == 4 or n == 8 then
				pushed:SetTexCoord(...)
			else
				pushed:SetTexCoord(0, 1, 0, 1)
			end
		end
		setTextureOffset(object.pushed, 1, -1)

		local highlight = self.highlight
		highlight:SetTexture(path)
		highlight:SetAllPoints(image)
		if highlight:GetTexture() then
			local n = select("#", ...)
			if n == 4 or n == 8 then
				highlight:SetTexCoord(...)
			else
				highlight:SetTexCoord(0, 1, 0, 1)
			end
		end
		highlight:SetAlpha(0.33)
	end

	pushed:SetAllPoints(image)
	highlight:SetAllPoints(image)
	setHighlightToOffsetWithPushed(frame, highlight, image)

	-- Register the custom widget type with AceGUI
	AceGUI:RegisterAsWidget(object)
	return object
end

-- Register the custom widget type with AceGUI
AceGUI:RegisterWidgetType(Type, Constructor, Version)
