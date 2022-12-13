---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local Execute = ns.Actions.Execute
local Tooltip = ns.Utils.Tooltip
local UIHelpers = ns.Utils.UIHelpers
local Vault = ns.Vault

local Gems = ns.UI.Gems
local Icons = ns.UI.Icons

local executeSpell = Execute.executeSpell
local ADDON_COLORS = Constants.ADDON_COLORS
local ASSETS_PATH = Constants.ASSETS_PATH
local ADDON_TITLE = Constants.ADDON_TITLE

local function getCursorDistanceFromFrame(frame)
	local uiScale, x1, y1 = UIParent:GetEffectiveScale(), GetCursorPosition()
	local x1, y1 = x1/uiScale, y1/uiScale
	local x2, y2 = frame:GetCenter()
	local dx = x1 - x2
	local dy = y1 - y2
	return math.sqrt ( dx * dx + dy * dy ) -- x * x is faster than x^2
end

local f = CreateFrame("Button", "SCForgeQuickcast", UIParent)
SCForgeQuickcast = f
--f:SetPoint("CENTER")
f:SetPoint("TOPRIGHT", -60, -220)
f:SetSize(50,50)
f:SetNormalTexture(ASSETS_PATH .. "/quick_cast_main")
f:SetHighlightTexture(ASSETS_PATH .. "/quick_cast_main")
f.highlight = f:GetHighlightTexture()
f.highlight:SetAlpha(0.3)

f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetClampedToScreen(true)
f:SetScript("OnDragStart", function(self, button)
	self:StartMoving()
end)
f:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
end)

f:SetScript("OnClick", function(self, button)
	if button == "RightButton" then
		InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE);
		InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE);
	else
		if not SCForgeMainFrame:IsShown() then
			SCForgeMainFrame:Show()
		else
			SCForgeMainFrame:Hide()
		end
	end
end)
f:RegisterForClicks("LeftButtonUp","RightButtonUp")

--[[
f.hitFrame = CreateFrame("Frame", nil, f)
f.hitFrame:SetSize(135,135)
f.hitFrame:SetPoint("CENTER")
f.hitFrame:SetFrameStrata("LOW")
--]]

f.castButtons = {}

local function CustomUIFrameFadeOut(frame, timeToFade, startAlpha, endAlpha)
	local fadeInfo = {};
	fadeInfo.mode = "OUT";
	fadeInfo.timeToFade = timeToFade;
	fadeInfo.startAlpha = startAlpha;
	fadeInfo.endAlpha = endAlpha;
	fadeInfo.finishedArg1 = frame
	if endAlpha == 0 then
		fadeInfo.finishedFunc = function(frame) if frame:GetAlpha() == 0 then frame:Hide() end end
	end
	UIFrameFade(frame, fadeInfo);
end

local function hideCastButtons(buttonToActivate)
	local frame = f
	f.areSpellsShown = false
	for i = 1, #frame.castButtons do
		local button = frame.castButtons[i]
		button.showTimer:Cancel()
		if UIFrameIsFading(button) then UIFrameFadeRemoveFrame(button) end

		if button == buttonToActivate then
			--button.anims:Play()
			UIFrameFadeOut(button, 0.35, 1, 0)
			C_Timer.After(0.5, function() if button:GetAlpha() == 0 then button:Hide() end end)
		else
			if button:IsShown() then
				CustomUIFrameFadeOut(button, 0.05, button:GetAlpha(), 0)
			else
				button:Hide()
			end
		end
	end
end

local function updateButtonTexs(self) -- you need to set the main texture first
	local pushedTex = self:GetPushedTexture()
	local normalTex = self:GetNormalTexture()
	pushedTex:SetTexture(normalTex:GetTexture())
	UIHelpers.setTextureOffset(pushedTex, 1, -1)
end

local function setButtonActorNormal(self)
	local self = self.scene
	self.Actor:SetSpellVisualKit(0)
	self.Actor:SetModelByFileID(166432)
	self.Actor:SetSpellVisualKit(0)
	self.Actor:SetModelByFileID(166432) -- sometimes you have to set it twice to remove it..
	self.Actor:SetAlpha(1)
	self.Actor:Hide()
end

local function setButtonActorExplode(self)
	local self = self.scene
	self.Actor:SetModelByFileID(166432)
	self.Actor:SetSpellVisualKit(30627)
	self.Actor:SetSpellVisualKit(7122)
	self.Actor:SetAlpha(1)
	self.Actor:Show()
end

--local quickCastSpells = {"arcsmash", "drunk","drunk","drunk","drunk","drunk","drunk","drunk","drunk","drunk","drunk",}
local function genQuickCastButtons(self)
	local quickCastSpells = SpellCreatorMasterTable.quickCastSpells
	local numSpells = #quickCastSpells
	if numSpells == 0 then return end
	self.areSpellsShown = true
	local radius = 38+(2*numSpells)
	self.radius = radius
	for i = 1, #quickCastSpells do
		local v = quickCastSpells[i]
		local spellData = Vault.personal.findSpellByID(v)
		if not self.castButtons[i] then
			self.castButtons[i] = CreateFrame("Button", "$parentButton"..i, self)
			local button = self.castButtons[i]
			button:Hide()
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button.index = i
			--button.icon = button:CreateTexture(nil, "ARTWORK")
			--button.icon:SetAllPoints()
			local someIcon = Gems.randomGem()
			--SetPortraitToTexture(button.icon, someIcon)
			button:SetNormalTexture(someIcon)
			button:SetPushedTexture(someIcon)
			updateButtonTexs(button)
			button.mask = button:CreateMaskTexture()
			button.mask:SetAllPoints()
			button.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
			button:GetNormalTexture():AddMaskTexture(button.mask)
			button:GetPushedTexture():AddMaskTexture(button.mask)
			button.ring = button:CreateTexture(nil, "OVERLAY")
			--button.ring:SetAllPoints()
			local ringPadding = 0
			local ringAnimPadding = 6
			button.ring:SetPoint("TOPLEFT",-ringPadding,ringPadding)
			button.ring:SetPoint("BOTTOMRIGHT",ringPadding,-ringPadding)
			button.ring:SetTexture(ASSETS_PATH .. "/quick_cast_ring_border")
			button:SetHighlightAtlas("Artifacts-PerkRing-Highlight")
			button.highlightFX = button:CreateTexture(nil, "OVERLAY")
			button.highlightFX:SetAllPoints()
			button.highlightFX:SetAtlas("ArtifactsFX-SpinningGlowys")
			button.highlightFX.anims = button.highlightFX:CreateAnimationGroup()
			button.highlightFX.anims.spin = button.highlightFX.anims:CreateAnimation("Rotation")
			button.highlightFX.anims.spin:SetDegrees(-360)
			button.highlightFX.anims.spin:SetDuration(2)
			button.highlightFX:Hide()
			button.highlightFX.anims:SetScript("OnPlay", function(self) self:GetParent():Show() end)
			button.highlightFX.anims:SetScript("OnStop", function(self) self:GetParent():Hide() end)
			button.highlightFX.anims:SetLooping("REPEAT")
			button.anims = button:CreateAnimationGroup()
			button.anims.move = button.anims:CreateAnimation("Translation")
			button.anims.move:SetOffset(0, 10)
			button.anims.move:SetDuration(0.5)

			button.scene = CreateFrame("MODELSCENE", nil, button)
			do
				local self = button.scene

				self:SetPoint("TOPLEFT",-ringAnimPadding,ringAnimPadding)
				self:SetPoint("BOTTOMRIGHT",ringAnimPadding,-ringAnimPadding)
				Mixin(self, ModelSceneMixin)

				self.cameras = {}
				self.actorTemplate = "ModelSceneActorTemplate"
				self.tagToActor = {}
				self.tagToCamera = {}

				if self.reversedLighting then
					local lightPosX, lightPosY, lightPosZ = self:GetLightPosition();
					self:SetLightPosition(-lightPosX, -lightPosY, lightPosZ);

					local lightDirX, lightDirY, lightDirZ = self:GetLightDirection();
					self:SetLightDirection(-lightDirX, -lightDirY, lightDirZ);
				end

				self:SetCameraNearClip(0.01)
				self:SetCameraFarClip(2 ^ 64)

				local camera = CameraRegistry:CreateCameraByType("OrbitCamera")
				camera.panningXOffset = 0
				camera.panningYOffset = 0
				camera.modelSceneCameraInfo = {
				flags = 0,
				}
				self:AddCamera(camera)
				camera:SetTarget(0, 0, 0)
				camera:SnapToTargetInterpolationTarget()
				camera:SetPitch(math.rad(0))
				camera:SetYaw(math.rad(180))
				camera:SetMinZoomDistance(1)
				camera:SetZoomDistance(0)

				self.Actor = self:GetActorAtIndex(1) or self:CreateActor()
				--self.Actor:SetUseCenterForOrigin(true, true, true)
				self.Actor:SetPosition(10,0,-1)
				self.Actor:Hide()
				--setButtonActorExplode(self:GetParent())
			end

			Tooltip.set(button, function(self) return self.tooltipTitle end, function(self) return self.tooltipText end, {delay = 0.5})
			button:HookScript("OnEnter", function(self)
				self.highlightFX.anims:Play()
			end)
			button:HookScript("OnLeave", function(self)
				self.highlightFX.anims:Stop()
			end)
		end
		local x = radius * math.cos(((i-1)/numSpells)*(2*math.pi));
		local y = radius * math.sin(((i-1)/numSpells)*(2*math.pi));
		local button = self.castButtons[i]
		button:SetPoint("CENTER", self, "CENTER", x, y)
		button:SetSize(30,30)

		if spellData == nil then
			button.tooltipTitle = "Error Loading Spell"
			button.tooltipText = "Spell '"..v.."' does not exist in your vault.\n\rRight-Click to remove this from your Quickcast."
			--button.icon:SetTexture("interface/icons/inv_misc_questionmark")
			button:SetNormalTexture("interface/icons/inv_misc_questionmark")
			button:SetScript("OnClick", function(self, button)
				if button == "RightButton" then
					tremove(quickCastSpells, i)
					hideCastButtons()
					C_Timer.After(0.1, function() genQuickCastButtons(self:GetParent()) end)
				end
			end)
		else
			button.tooltipTitle = spellData.fullName
			button.tooltipText = "Cast '"..spellData.commID.."' ("..#spellData.actions.." actions).\n"..ADDON_COLORS.QC_DARKRED:GenerateHexColorMarkup().."Shift+Right-Click to remove.|r"
			button.commID = spellData.commID
			if spellData.icon then
				--button.icon:SetTexture(Icons.getFinalIcon(spellData.icon))
				button:SetNormalTexture(Icons.getFinalIcon(spellData.icon))
			else
				local iconNum = ((i-1) % (#Gems.arcaneGemIcons)) + 1
				--button.icon:SetTexture(Gems.gemPath(Gems.arcaneGemIcons[iconNum]))
				button:SetNormalTexture(Gems.gemPath(Gems.arcaneGemIcons[iconNum]))
			end
			button:SetScript("OnClick", function(self, button)
				if button == "RightButton" and IsShiftKeyDown() then
					tremove(quickCastSpells, i)
					hideCastButtons()
					C_Timer.After(0.1, function() genQuickCastButtons(self:GetParent()) end)
				else
					executeSpell(spellData.actions, nil, spellData.fullName, spellData)
					hideCastButtons(self)
					setButtonActorExplode(self)
					C_Timer.After(0.5, function() setButtonActorNormal(self) end)
				end
			end)
		end
		updateButtonTexs(button)
		--button:Show()
		local maxSequenceTime = 0.5
		local maxSequenceDelay = 0.1
		local sequenceDelay = maxSequenceTime / numSpells
		sequenceDelay = math.min(sequenceDelay, maxSequenceDelay)
		if numSpells < 4 then sequenceDelay = 0 end
		if not button:IsShown() then button.showTimer = C_Timer.NewTimer(sequenceDelay*i, function() UIFrameFadeIn(button, 0.05, 0, 1) end) else UIFrameFadeIn(button, 0, 0, 1) end
	end

end

f:SetScript("OnEnter", function(self)

	--self.hitFrame:SetSize((self.radius+35)*2, (self.radius+35)*2)

	if #SpellCreatorMasterTable.quickCastSpells == 0 then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("Quickcast Book", nil, nil, nil, nil, true)
		GameTooltip:AddLine("You can add Arcanum Spells to your Quickcast Book by right-clicking them in your vault!\n\rClick & Drag to move your book anywhere.",1,1,1,true)
		GameTooltip:Show()
	end

	if self.areSpellsShown then return end

	genQuickCastButtons(self)

	local rad = (self.radius+35)
	self:SetScript("OnUpdate", function(self)
		--if not self:IsMouseOver(rad, -rad, -rad, rad) then
		if getCursorDistanceFromFrame(self) > rad+15 then -- manually overriding rad to 50 offset from self.radius (that is: 50 'pixels' outside of the cast button's center)
			hideCastButtons()
			self:SetScript("OnUpdate", nil)
		end
	end)
end)

f:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
end)

--[[
f.hitFrame:SetScript("OnLeave", function(self)
	if self:IsMouseOver() then return end
	self:SetSize(50, 50)
	hideCastButtons()
end)
--]]

local function setShown(shown)
	SCForgeQuickcast:SetShown(shown)
end


---@class UI_Quickcast
ns.UI.Quickcast = {
	hideCastCuttons = hideCastButtons,
	setShown = setShown,
}
