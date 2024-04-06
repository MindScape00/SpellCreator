---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

local TITLE = Constants.ADDON_TITLE
local TITLE_WITH_CHANGES = Constants.ADDON_TITLE .. "*"

local size = {
	["x"] = 700,
	["y"] = 700,
	["Xmin"] = 550,
	["Ymin"] = 550,
	["Xmax"] = math.min(1100, UIParent:GetHeight()), -- Don't let them resize it bigger than their screen is.. then you can't resize it down w/o using hidden right-click on X button
	["Ymax"] = math.min(1100, UIParent:GetHeight()),

	columnWidths = {
		delay = 80,
		action = 100,
		self = 32,
		inputEntry = 140 + 42,
		revertDelay = 80,
		conditional = 32
	},

	rowHeight = 60,
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
	n = n / size.x
	local childrens = { frame.Inset:GetChildren() }
	for _, child in ipairs(childrens) do
		child:SetScale(n)
	end
	for _, child in pairs(framesToResizeWithMainFrame) do
		child:SetScale(n)
	end
	return n;
end

---@param hasChanges boolean
local function markTitleChanges(hasChanges)
	SCForgeMainFrame:SetTitle(hasChanges and TITLE_WITH_CHANGES or TITLE)
end

---@class SCForgeMainFrame : ButtonFrameTemplate, Frame
---@field conditionsData ConditionDataTable
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

markTitleChanges(false)

local titleBgColor = SCForgeMainFrame:CreateTexture(nil, "BACKGROUND")
titleBgColor:SetPoint("TOPLEFT", SCForgeMainFrame.TitleBg)
titleBgColor:SetPoint("BOTTOMRIGHT", SCForgeMainFrame.TitleBg)
titleBgColor:SetColorTexture(0.30, 0.10, 0.40, 0.5)

SCForgeMainFrame.TitleBgColor = titleBgColor

local settingsButton = CreateFrame("BUTTON", nil, SCForgeMainFrame, "UIPanelButtonNoTooltipTemplate")
settingsButton:SetSize(24, 24)
settingsButton:SetPoint("RIGHT", SCForgeMainFrame.CloseButton, "LEFT", 4, 0)
settingsButton.icon = settingsButton:CreateTexture(nil, "ARTWORK")
settingsButton.icon:SetTexture("interface/buttons/ui-optionsbutton")
settingsButton.icon:SetSize(16, 16)
settingsButton.icon:SetPoint("CENTER")
settingsButton:SetScript("OnClick", function()
	-- Needs to be called twice because of a bug in Blizzard's frame - the first call will initialize the frame if it's not initialized
	InterfaceOptionsFrame_OpenToCategory(Constants.ADDON_TITLE)
	InterfaceOptionsFrame_OpenToCategory(Constants.ADDON_TITLE)
end)
settingsButton:SetScript("OnMouseDown", function(self)
	local point, relativeTo, relativePoint, xOfs, yOfs = self.icon:GetPoint(1)
	self.icon:SetPoint(point, relativeTo, relativePoint, xOfs + 2, yOfs - 2)
end)
settingsButton:SetScript("OnMouseUp", function(self)
	local point, relativeTo, relativePoint, xOfs, yOfs = self.icon:GetPoint(1)
	self.icon:SetPoint(point, relativeTo, relativePoint, xOfs - 2, yOfs + 2)
end)
settingsButton:SetScript("OnDisable", function(self)
	self.icon:GetDisabledTexture():SetDesaturated(true)
end)
settingsButton:SetScript("OnEnable", function(self)
	self.icon:GetDisabledTexture():SetDesaturated(false)
end)

SCForgeMainFrame.SettingsButton = settingsButton

local dragBar = CreateFrame("Frame", nil, SCForgeMainFrame)
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

SCForgeMainFrame.DragBar = dragBar

local scrollFrame = CreateFrame("ScrollFrame", nil, SCForgeMainFrame.Inset, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 0, -35)
scrollFrame:SetPoint("BOTTOMRIGHT", -24, 0)

SCForgeMainFrame.Inset.scrollFrame = scrollFrame

local scrollChild = CreateFrame("Frame")
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(SCForgeMainFrame.Inset:GetWidth() - 18)
scrollChild:SetHeight(1)

scrollFrame.scrollChild = scrollChild

scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, 18)
scrollFrame.ScrollBar.scrollStep = size.rowHeight

local resizeDragger = CreateFrame("BUTTON", nil, SCForgeMainFrame)
resizeDragger:SetSize(16, 16)
resizeDragger:SetPoint("BOTTOMRIGHT", -2, 2)
resizeDragger:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeDragger:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeDragger:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeDragger:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" then
		local parent = self:GetParent()
		self.isScaling = true
		parent:StartSizing("BOTTOMRIGHT")
	end
end)
resizeDragger:SetScript("OnMouseUp", function(self, button)
	if button == "LeftButton" then
		local parent = self:GetParent()
		self.isScaling = false
		parent:StopMovingOrSizing()
	end
end)

SCForgeMainFrame.ResizeDragger = resizeDragger

SCForgeMainFrame:SetScript("OnSizeChanged", function(self)
	updateFrameChildScales(self)
	local newHeight = self:GetHeight()
	local ratio = newHeight / size.y
	SCForgeMainFrame.LoadSpellFrame:SetSize(280 * ratio, self:GetHeight())
end)

---@param callback fun(width: integer)
local function onSizeChanged(callback)
	SCForgeMainFrame:HookScript("OnSizeChanged", function()
		callback(SCForgeMainFrame:GetWidth())
	end)
end

---@class UI_MainFrame_MainFrame
ns.UI.MainFrame.MainFrame = {
	size = size,

	setResizeWithMainFrame = setResizeWithMainFrame,
	updateFrameChildScales = updateFrameChildScales,
	markTitleChanges = markTitleChanges,
	onSizeChanged = onSizeChanged,
}
