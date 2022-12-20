---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

local size = {
	["x"] = 700,
	["y"] = 700,
	["Xmin"] = 550,
	["Ymin"] = 550,
	["Xmax"] = math.min(1100,UIParent:GetHeight()), -- Don't let them resize it bigger than their screen is.. then you can't resize it down w/o using hidden right-click on X button
	["Ymax"] = math.min(1100,UIParent:GetHeight()),

	columnWidths = {
		delay = 100,
		action = 100,
		self = 32,
		inputEntry = 140 + 42,
		revertDelay = 80,

	}
}

local framesToResizeWithMainFrame = {}

---@param frame Frame
local function setResizeWithMainFrame(frame)
	table.insert(framesToResizeWithMainFrame, frame)
end

---@param frame SCForgeMainFrame
---@return number
local function updateFrameChildScales(frame)
	local n = frame:GetWidth()
	frame:SetHeight(n)
	frame.DragBar:SetWidth(n)
	local n = n / size.x
	local childrens = {frame.Inset:GetChildren()}
	for _,child in ipairs(childrens) do
		child:SetScale(n)
	end
	for _,child in pairs(framesToResizeWithMainFrame) do
		child:SetScale(n)
	end
	return n;
end

---@class SCForgeMainFrame : ButtonFrameTemplate, Frame
SCForgeMainFrame = CreateFrame("Frame", "SCForgeMainFrame", UIParent, "ButtonFrameTemplate")
SCForgeMainFrame:SetPoint("CENTER")
SCForgeMainFrame:SetSize(size.x, size.y)
SCForgeMainFrame:SetMaxResize(size.Xmax, size.Ymax)
SCForgeMainFrame:SetMinResize(size.Xmin, size.Ymin)
SCForgeMainFrame:SetMovable(true)
SCForgeMainFrame:SetResizable(true)
SCForgeMainFrame:SetToplevel(true);
SCForgeMainFrame:EnableMouse(true)
SCForgeMainFrame:SetClampedToScreen(true)
SCForgeMainFrame:SetClampRectInsets(300, -300, 0, 500)

SCForgeMainFrame:SetTitle("Arcanum - Spell Forge")

SCForgeMainFrame.TitleBgColor = SCForgeMainFrame:CreateTexture(nil, "BACKGROUND")
local _frame = SCForgeMainFrame.TitleBgColor
	_frame:SetPoint("TOPLEFT", SCForgeMainFrame.TitleBg)
	_frame:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.TitleBg)
	_frame:SetColorTexture(0.30,0.10,0.40,0.5)

SCForgeMainFrame.SettingsButton = CreateFrame("BUTTON", nil, SCForgeMainFrame, "UIPanelButtonNoTooltipTemplate")
local _frame = SCForgeMainFrame.SettingsButton
	_frame:SetSize(24,24)
	_frame:SetPoint("RIGHT", SCForgeMainFrame.CloseButton, "LEFT", 4, 0)
	_frame.icon = _frame:CreateTexture(nil, "ARTWORK")
	_frame.icon:SetTexture("interface/buttons/ui-optionsbutton")
	_frame.icon:SetSize(16,16)
	_frame.icon:SetPoint("CENTER")
	_frame:SetScript("OnClick", function(self)
		InterfaceOptionsFrame_OpenToCategory(Constants.ADDON_TITLE);
		InterfaceOptionsFrame_OpenToCategory(Constants.ADDON_TITLE);
	end)
	_frame:SetScript("OnMouseDown", function(self)
		local point, relativeTo, relativePoint, xOfs, yOfs = self.icon:GetPoint(1)
		self.icon:SetPoint(point, relativeTo, relativePoint, xOfs+2, yOfs-2)
	end)
	_frame:SetScript("OnMouseUp", function(self)
		local point, relativeTo, relativePoint, xOfs, yOfs = self.icon:GetPoint(1)
		self.icon:SetPoint(point, relativeTo, relativePoint, xOfs-2, yOfs+2)
	end)
	_frame:SetScript("OnDisable", function(self)
		self.icon:GetDisabledTexture():SetDesaturated(true)
	end)
	_frame:SetScript("OnEnable", function(self)
		self.icon:GetDisabledTexture():SetDesaturated(false)
	end)

SCForgeMainFrame.DragBar = CreateFrame("Frame", nil, SCForgeMainFrame)
local dragBar = SCForgeMainFrame.DragBar
	dragBar:SetPoint("TOPLEFT")
	dragBar:SetSize(size.x, 20)
	dragBar:EnableMouse(true)
	dragBar:RegisterForDrag("LeftButton")
	dragBar:SetScript("OnMouseDown", function(self)
		self:GetParent():Raise()
	end)
	dragBar:SetScript("OnDragStart", function(self)
		self:GetParent():StartMoving()
	end)
	dragBar:SetScript("OnDragStop", function(self)
		self:GetParent():StopMovingOrSizing()
	end)

---@class UI_MainFrame_MainFrame
ns.UI.MainFrame.MainFrame = {
    size = size,

    setResizeWithMainFrame = setResizeWithMainFrame,
    updateFrameChildScales = updateFrameChildScales,
}
