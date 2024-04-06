local addonName = ...
---@class ns
local ns = select(2, ...)

local Animation = ns.UI.Animation
local ADDON_COLORS = ns.Constants.ADDON_COLORS
local ADDON_TITLE = ns.Constants.ADDON_TITLE
local ASSETS_PATH = ns.Constants.ASSETS_PATH
local Gems, Models = ns.UI.Gems, ns.UI.Models
local Dropdown = ns.UI.Dropdown

local addonVersion, addonAuthor = GetAddOnMetadata(addonName, "Version"), GetAddOnMetadata(addonName, "Author")

local callback

local minimapButton = CreateFrame("Button", "SpellCreatorMinimapButton", Minimap)
minimapButton:SetMovable(true)
minimapButton:EnableMouse(true)
minimapButton:SetSize(33, 33)
minimapButton:SetFrameStrata("MEDIUM");
minimapButton:SetFrameLevel(62);
minimapButton:SetClampedToScreen(true);
minimapButton:SetClampRectInsets(5, -5, -5, 5)
minimapButton:SetPoint("TOPLEFT")
minimapButton:RegisterForDrag("LeftButton", "RightButton")
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local minimapShapes = {
	["ROUND"] = { true, true, true, true },
	["SQUARE"] = { false, false, false, false },
	["CORNER-TOPLEFT"] = { false, false, false, true },
	["CORNER-TOPRIGHT"] = { false, false, true, false },
	["CORNER-BOTTOMLEFT"] = { false, true, false, false },
	["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
	["SIDE-LEFT"] = { false, true, false, true },
	["SIDE-RIGHT"] = { true, false, true, false },
	["SIDE-TOP"] = { false, false, true, true },
	["SIDE-BOTTOM"] = { true, true, false, false },
	["TRICORNER-TOPLEFT"] = { false, true, true, true },
	["TRICORNER-TOPRIGHT"] = { true, false, true, true },
	["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
	["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local RadialOffset = 10; --minimapbutton offset
local function updateAngle(radian)
	local x, y, q = math.cos(radian), math.sin(radian), 1;
	if x < 0 then q = q + 1 end
	if y > 0 then q = q + 2 end
	local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND";
	local quadTable = minimapShapes[minimapShape];
	local w = (Minimap:GetWidth() / 2) + RadialOffset --10
	local h = (Minimap:GetHeight() / 2) + RadialOffset
	if quadTable[q] then
		x, y = x * w, y * h
	else
		local diagRadiusW = sqrt(2 * (w) ^ 2) - RadialOffset --  -10
		local diagRadiusH = sqrt(2 * (h) ^ 2) - RadialOffset
		x = max(-w, min(x * diagRadiusW, w));
		y = max(-h, min(y * diagRadiusH, h));
	end
	minimapButton:ClearAllPoints()
	minimapButton:SetPoint("CENTER", "Minimap", "CENTER", x, y);
end

local function minimap_OnUpdate(self)
	local radian;

	local mx, my = Minimap:GetCenter();
	local px, py = GetCursorPosition();
	local scale = Minimap:GetEffectiveScale();
	px, py = px / scale, py / scale;
	radian = math.atan2(py - my, px - mx);

	updateAngle(radian);
	SpellCreatorMasterTable.Options["mmLoc"] = radian;
	if not self.highlight.anim:IsPlaying() then self.highlight.anim:Play() end
end

minimapButton.Flash = minimapButton:CreateTexture("$parentFlash", "OVERLAY")
minimapButton.Flash:SetAtlas("Azerite-Trait-RingGlow")
minimapButton.Flash:SetAllPoints()
minimapButton.Flash:SetPoint("TOPLEFT", -4, 4)
minimapButton.Flash:SetPoint("BOTTOMRIGHT", 4, -4)
minimapButton.Flash:SetDesaturated(true)
minimapButton.Flash:SetVertexColor(1, 1, 0)
minimapButton.Flash:Hide()

minimapButton.bg = minimapButton:CreateTexture("$parentBg", "BACKGROUND")
minimapButton.bg:SetTexture(ASSETS_PATH .. "/CircularBG")
minimapButton.bg:SetSize(24, 24)
minimapButton.bg:SetPoint("CENTER")
minimapButton.bg.mask = minimapButton:CreateMaskTexture()
minimapButton.bg.mask:SetAllPoints(minimapButton.bg)
minimapButton.bg.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
minimapButton.bg:AddMaskTexture(minimapButton.bg.mask)

local mmIcon = Gems.gemPath("Violet")
minimapButton.icon = minimapButton:CreateTexture("$parentIcon", "ARTWORK")
minimapButton.icon:SetTexture(mmIcon)
minimapButton.icon:SetSize(22, 22)
minimapButton.icon:SetPoint("CENTER")

minimapButton.Model = CreateFrame("PLAYERMODEL", nil, minimapButton, "MouseDisabledModelTemplate")
minimapButton.Model:SetAllPoints()
minimapButton.Model:SetFrameStrata("MEDIUM")
minimapButton.Model:SetFrameLevel(minimapButton:GetFrameLevel())
minimapButton.Model:SetModelDrawLayer("BORDER")
minimapButton.Model:SetKeepModelOnHide(true)
Models.modelFrameSetModel(minimapButton.Model, 2, Models.minimapModels)
Models.modelFrameSetModel(minimapButton.Model, fastrandom(#Models.minimapModels), Models.minimapModels)

--SpellCreatorMinimapButton.Model
--SpellCreatorMinimapButton.Model:SetCamDistanceScale()

--[[
minimapButton.rune = minimapButton:CreateTexture(nil, "OVERLAY", nil, 7)
if runeIconOverlay.atlas then
	minimapButton.rune:SetAtlas(runeIconOverlay.atlas)
else
	minimapButton.rune:SetTexture(runeIconOverlay.tex)
end

minimapButton.rune:SetDesaturated(true)
minimapButton.rune:SetVertexColor(1,1,1)
minimapButton.rune:SetBlendMode("ADD")
minimapButton.rune:SetPoint("CENTER")
minimapButton.rune:SetSize(12,12)
--minimapButton.rune:SetPoint("TOPLEFT", minimapButton, 8, -8)
--minimapButton.rune:SetPoint("BOTTOMRIGHT", minimapButton, -8, 8)
--]]

-- Minimap Border Ideas (Atlas):
local mmBorders = {
	{ atlas = "Artifacts-PerkRing-Final",            size = 0.58, posx = 1,  posy = -1 },                                  -- 1 -- Thin Gold Border with gloss over the icon area like glass
	{ atlas = "auctionhouse-itemicon-border-purple", size = 0.62, posx = -1, posy = 0, hilight = "Relic-Arcane-TraitGlow", }, -- 2 -- purple ring w/ arcane highlight
	{ atlas = "legionmission-portraitring-epicplus", size = 0.65, posx = -1, posy = 0, hilight = "Relic-Arcane-TraitGlow", }, -- 2 -- thicker purple ring w/ gold edges & decor
	{ tex = ASSETS_PATH .. "/Icon_Ring_Border",      size = 0.62, posx = -1, posy = 0, hilight = "Relic-Arcane-TraitGlow", }, -- 2 -- purple ring w/ arcane highlight
}

local mmBorder = mmBorders[4] -- put your table choice here
minimapButton.border = minimapButton:CreateTexture("$parentBorder", "BORDER")
if mmBorder.atlas then minimapButton.border:SetAtlas(mmBorder.atlas, false) else minimapButton.border:SetTexture(mmBorder.tex) end
minimapButton.border:SetSize(56 * mmBorder.size, 56 * mmBorder.size)
minimapButton.border:SetPoint("TOPLEFT", mmBorder.posx, mmBorder.posy)
if mmBorder.hilight then minimapButton:SetHighlightAtlas(mmBorder.hilight) else minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight") end
minimapButton.highlight = minimapButton:GetHighlightTexture()

minimapButton.highlight.anim = minimapButton.highlight:CreateAnimationGroup()
minimapButton.highlight.anim:SetLooping("REPEAT")
minimapButton.highlight.anim.rot = minimapButton.highlight.anim:CreateAnimation("Rotation")
minimapButton.highlight.anim.rot:SetDegrees(-360)
minimapButton.highlight.anim.rot:SetDuration(5)
minimapButton.highlight.anim:SetScript("OnPlay", function(self)
	Animation.setFrameFlicker(self:GetParent(), 2, 0.1, 0.5, 1, 0.33)
end)
minimapButton.highlight.anim:SetScript("OnPause", function(self)
	Animation.stopFrameFlicker(self:GetParent(), 1)
end)

--[[
SpellCreatorMinimapButton.border:SetSize(56*0.6,56*0.6)
SpellCreatorMinimapButton.border:SetPoint("TOPLEFT",2,-1)
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
		-- kept these here for ez copy-paste in-game lol
--]]

minimapButton.contextMenu = Dropdown.create(minimapButton, "SCForgeMinimapContextMenu")

local function createMenu()
	local menuArgs = {
		Dropdown.execute("Open Arcanum", function() callback() end),
		Dropdown.divider(),
		Dropdown.execute("Quickcast Manager", ns.UI.Quickcast.ManagerUI.showQCManagerUI),
		Dropdown.execute("Sparks Manager", ns.UI.SparkPopups.SparkManagerUI.showSparkManagerUI, {
			disabled = function() return not (ns.Permissions.isOfficerPlus() or SpellCreatorMasterTable.Options["debug"]) end,
		}),
		Dropdown.divider(),
		Dropdown.execute("Settings", function() callback("options") end),
		Dropdown.execute("Changelog", function() ns.UI.WelcomeUI.WelcomeMenu.showWelcomeScreen(true) end),
		--Dropdown.divider(),
		--ns.UI.Quickcast.ContextMenu.genShowBookMenu("Toggle Quickcast Books"),
	}
	return menuArgs
end

minimapButton:SetScript("OnDragStart", function(self)
	self:LockHighlight()
	self:SetScript("OnUpdate", minimap_OnUpdate)
end)
minimapButton:SetScript("OnDragStop", function(self)
	self:UnlockHighlight()
	self.highlight.anim:Pause()
	self:SetScript("OnUpdate", nil)
end)
minimapButton:SetScript("OnMouseUp", function(self, button)
	if button == "LeftButton" then
		callback()
		Models.modelFrameSetModel(minimapButton.Model, fastrandom(#Models.minimapModels), Models.minimapModels)
	elseif button == "RightButton" then
		--callback("options")
		Dropdown.open(createMenu(), self.contextMenu, self, 0, 0, "MENU")
		GameTooltip:Hide()
	end
end)

minimapButton:SetScript("OnEnter", function(self)
	self.highlight.anim:Play()
	SetCursor("Interface/CURSOR/voidstorage.blp");
	-- interface/cursor/argusteleporter.blp , interface/cursor/trainer.blp ,
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(ADDON_TITLE)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("/arcanum - Toggle UI", 1, 1, 1, true)
	GameTooltip:AddLine("/sf - Shortcut Command!", 1, 1, 1, true)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("" .. ADDON_COLORS.GAME_GOLD:GenerateHexColorMarkup() .. "Left-Click|r to toggle the main UI!", 1, 1, 1, true)
	GameTooltip:AddLine("" .. ADDON_COLORS.GAME_GOLD:GenerateHexColorMarkup() .. "Right-Click|r for Options.", 1, 1, 1, true)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Mouse over most UI Elements to see tooltips for help! (Like this one!)", 0.9, 0.75, 0.75, true)
	GameTooltip:AddDoubleLine(" ", ADDON_TITLE .. " v" .. addonVersion, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8);
	GameTooltip:AddDoubleLine(" ", "by " .. addonAuthor, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8);
	GameTooltip:Show()

	if self.Flash:IsShown() then UIFrameFlashStop(self.Flash) end
	Animation.stopRainbowVertex(self.Flash)
end)
minimapButton:SetScript("OnLeave", function(self)
	self.highlight.anim:Pause()
	ResetCursor();
	GameTooltip:Hide()
end)

minimapButton:SetScript("OnShow", function(self)
	if not self.Flash:IsShown() then UIFrameFlash(self.Flash, 0.75, 0.75, 4.5, false, 0, 0); end
	Animation.setRainbowVertex(minimapButton.Flash, minimapButton)
end)

local function onEnabled()
	UIFrameFlash(minimapButton.Flash, 1.0, 1.0, -1, false, 0, 0);
	minimapButton:SetShown(true)
	UIFrameFadeIn(minimapButton, 0.5)
end

local function setCallback(cb)
	callback = cb
end

local function setRadialOffset(offset)
	RadialOffset = offset
end

local function setShown(buttonShown)
	minimapButton:SetShown(buttonShown)
end

---@class UI_MinimapButton
ns.UI.MinimapButton = {
	onEnabled = onEnabled,
	setCallback = setCallback,
	setRadialOffset = setRadialOffset,
	setShown = setShown,
	updateAngle = updateAngle,
}
