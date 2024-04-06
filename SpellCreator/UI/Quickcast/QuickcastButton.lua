---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local Cooldowns = ns.Actions.Cooldowns
local Execute = ns.Actions.Execute
local Tooltip = ns.Utils.Tooltip
local UIHelpers = ns.Utils.UIHelpers
local Vault = ns.Vault

local Gems = ns.UI.Gems
local Icons = ns.UI.Icons
local QuickcastAnimation = ns.UI.Quickcast.Animation
local QuickcastStyle = ns.UI.Quickcast.Style

local ADDON_COLORS = Constants.ADDON_COLORS
local ASSETS_PATH = Constants.ASSETS_PATH

local executeSpell = Execute.executeSpell
local animateButtonClick = QuickcastAnimation.animateButtonClick
local CustomUIFrameFadeOut = QuickcastAnimation.CustomUIFrameFadeOut

---@param self QuickcastButton
---@param style? BookStyle if undefined, will use the pages style
local function _Button_SetStyle(self, style)
	if not style then style = self:GetParent().style end
	local ring = self.ring
	local styleData = QuickcastStyle.getStyleData(style)

	if style == 1 then
		ring:SetDesaturated(false)
		ring:SetVertexColor(1, 1, 1, 1)
	elseif styleData.colorGradient then
		local r1, g1, b1 = styleData.colorGradient.max:GetRGB()
		local r2, g2, b2 = styleData.colorGradient.min:GetRGB()
		ring:SetDesaturated(true)
		ring:SetVertexColor(1, 1, 1, 1)
		ring:SetGradient("HORIZONTAL", r1, g1, b1, r2, g2, b2)
	elseif styleData.color then
		local color = styleData.color
		ring:SetDesaturated(true)
		ring:SetVertexColor(color:GetRGBA())
	end
end

---@param self QuickcastButton
---@return QuickcastPage
local function _Button_GetPage(self)
	return self:GetParent() --[[@as QuickcastPage]]
end

---@param self QuickcastButton
local function _Button_UpdateTextures(self) -- you need to set the main texture first
	local pushedTex = self:GetPushedTexture()
	local normalTex = self:GetNormalTexture()
	pushedTex:SetTexture(normalTex:GetTexture())
	UIHelpers.setTextureOffset(pushedTex, 1, -1)
end

---@param self QuickcastButton
---@param commID CommID
local function _Button_setNotFound(self, commID)
	-- use Tooltip util? -- no need, letting the button handle it is fine, since the codebase is already there from blizzard, and we do not need it on a delay
	self.tooltipTitle = "Error Loading Spell"
	self.tooltipText = {
		("Spell %s does not exist in your vault."):format(Tooltip.genContrastText(commID)),
		"\nRight-Click to remove this from your Quickcast.",
	}
	self:SetNormalTexture("interface/icons/inv_misc_questionmark")
	self:SetScript("OnClick", function(_, btn)
		if btn == "RightButton" then
			self:Remove()
		end
	end)
end

---@param spell VaultSpell
local function formatCastText(spell)
	local actionsLabel = #spell.actions > 1 and "actions" or "action"
	return ("Cast '%s' (%d %s)."):format(spell.commID, #spell.actions, actionsLabel)
end

---@param self QuickcastButton
---@param spell VaultSpell
local function _Button_setSpell(self, spell)
	self.tooltipTitle = spell.fullName
	self.tooltipText = {
		formatCastText(spell),
		ADDON_COLORS.QC_DARKRED:GenerateHexColorMarkup() .. "Shift+Right-Click to remove.|r",
	}
	self.commID = spell.commID

	if spell.icon then
		self:SetNormalTexture(Icons.getFinalIcon(spell.icon))
	else
		local iconNum = ((self.index - 1) % (#Gems.arcaneGemIcons)) + 1
		self:SetNormalTexture(Gems.gemPath(Gems.arcaneGemIcons[iconNum]))
	end

	self:SetScript("OnClick", function(_, btn)
		if btn == "RightButton" and IsShiftKeyDown() then
			self:Remove()
		else
			-- trigger cooldown visual. This SHOULD be moved to the Cooldowns module and triggered by that, but honestly it was a lot of work to expose Books & Pages to check if a commID is currently shown?
			if spell.cooldown and not Cooldowns.isSpellOnCooldown(spell.commID) then self.cooldown:SetCooldown(GetTime(), spell.cooldown) end
			executeSpell(spell.actions, nil, spell.fullName, spell)

			if not SpellCreatorMasterTable.Options.keepQCOpen then
				self:_GetPage():HideCastButtons(self)
			end

			animateButtonClick(self)
		end
	end)
end

---@param self QuickcastButton
---@param commID CommID
local function Button_Update(self, commID)
	local spellData = Vault.personal.findSpellByID(commID)

	self:SetSize(30, 30)

	if spellData == nil then
		self:_setNotFound(commID)
	else
		self:_setSpell(spellData)
		if spellData.cooldown then
			local remainingTime = Cooldowns.isSpellOnCooldown(commID)
			if remainingTime then
				self.cooldown:SetCooldown(GetTime() - (spellData.cooldown - remainingTime), spellData.cooldown)
			else
				self.cooldown:Clear()
			end
		end
	end

	self:_UpdateTextures()
end

---@param button QuickcastButton
local function Button_Remove(button)
	local page = button:_GetPage()
	if type(page.spells) ~= "table" then return end

	tremove(page.spells, button.index)
	page:HideCastButtons()
	C_Timer.After(0.1, function()
		page:UpdateButtons()
	end)
end

---@param self QuickcastButton
---@param delay number
local function Button_FadeIn(self, delay)
	if not self:IsShown() then
		self.showTimer = C_Timer.NewTimer(delay, function()
			UIFrameFadeIn(self, 0.05, 0, 1)
		end)
	else
		UIFrameFadeIn(self, 0, 0, 1)
	end
end

---@param self QuickcastButton
---@param wasActivated boolean
local function Button_FadeOut(self, wasActivated)
	if self.showTimer then
		self.showTimer:Cancel()
	end

	if UIFrameIsFading(self) then
		UIFrameFadeRemoveFrame(self)
	end

	if wasActivated then
		--self.anims:Play()
		UIFrameFadeOut(self, 0.35, 1, 0)

		C_Timer.After(0.5, function()
			if self:GetAlpha() == 0 then
				self:Hide()
			end
		end)
	else
		if self:IsShown() then
			CustomUIFrameFadeOut(self, 0.05, self:GetAlpha(), 0)
		else
			self:Hide()
		end
	end
end

---@param page QuickcastPage
---@param index integer
---@return QuickcastButton
local function createButton(page, index)
	---@class QuickcastButton: Button
	local button = CreateFrame("Button", "$parentButton" .. index, page)
	button:Hide()
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button.index = index
	button.showTimer = nil

	button.FadeIn = Button_FadeIn
	button.FadeOut = Button_FadeOut
	button.Update = Button_Update
	button.Remove = Button_Remove
	button._GetPage = _Button_GetPage
	button._UpdateTextures = _Button_UpdateTextures
	button._SetStyle = _Button_SetStyle
	button._setNotFound = _Button_setNotFound
	button._setSpell = _Button_setSpell

	local someIcon = Gems.randomGem()
	button:SetNormalTexture(someIcon)
	button:SetPushedTexture(someIcon)
	button:_UpdateTextures()
	button.mask = button:CreateMaskTexture()
	button.mask:SetAllPoints()
	button.mask:SetTexture(
		"Interface/CHARACTERFRAME/TempPortraitAlphaMask",
		"CLAMPTOBLACKADDITIVE",
		"CLAMPTOBLACKADDITIVE"
	)
	button:GetNormalTexture():AddMaskTexture(button.mask)
	button:GetPushedTexture():AddMaskTexture(button.mask)

	button.ring = button:CreateTexture(nil, "OVERLAY")
	local ringPadding = 0
	local ringAnimPadding = 6
	button.ring:SetPoint("TOPLEFT", -ringPadding, ringPadding)
	button.ring:SetPoint("BOTTOMRIGHT", ringPadding, -ringPadding)
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

	button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	button.cooldown:SetAllPoints()
	button.cooldown:SetUseCircularEdge(true)
	button.cooldown:SetSwipeTexture(1307164)
	button.cooldown:SetSwipeColor(0, 0, 0, 0.5)

	---@class QuickcastButtonScene: MODELSCENE
	---@field Actor ModelSceneActor
	button.scene = CreateFrame("MODELSCENE", nil, button)

	do
		local scene = button.scene

		scene:SetPoint("TOPLEFT", -ringAnimPadding, ringAnimPadding)
		scene:SetPoint("BOTTOMRIGHT", ringAnimPadding, -ringAnimPadding)
		Mixin(scene, ModelSceneMixin)

		scene.cameras = {}
		scene.actorTemplate = "ModelSceneActorTemplate"
		scene.tagToActor = {}
		scene.tagToCamera = {}

		if scene.reversedLighting then
			local lightPosX, lightPosY, lightPosZ = scene:GetLightPosition();
			scene:SetLightPosition(-lightPosX, -lightPosY, lightPosZ);

			local lightDirX, lightDirY, lightDirZ = scene:GetLightDirection();
			scene:SetLightDirection(-lightDirX, -lightDirY, lightDirZ);
		end

		scene:SetCameraNearClip(0.01)
		scene:SetCameraFarClip(2 ^ 64)

		local camera = CameraRegistry:CreateCameraByType("OrbitCamera")
		camera.panningXOffset = 0
		camera.panningYOffset = 0
		camera.modelSceneCameraInfo = {
			flags = 0,
		}
		scene:AddCamera(camera)
		camera:SetTarget(0, 0, 0)
		camera:SnapToTargetInterpolationTarget()
		camera:SetPitch(math.rad(0))
		camera:SetYaw(math.rad(180))
		camera:SetMinZoomDistance(1)
		camera:SetZoomDistance(0)

		scene.Actor = scene:GetActorAtIndex(1) or scene:CreateActor()
		--scene.Actor:SetUseCenterForOrigin(true, true, true)
		scene.Actor:SetPosition(10, 0, -1)
		scene.Actor:Hide()
		--setButtonActorExplode(self:GetParent())
	end

	Tooltip.set(
		button,
		function(self)
			return self.tooltipTitle
		end,
		function(self)
			return self.tooltipText
		end,
		{ delay = 0.5 }
	)

	button:HookScript("OnEnter", function(self)
		self.highlightFX.anims:Play()
	end)

	button:HookScript("OnLeave", function(self)
		self.highlightFX.anims:Stop()
	end)

	button:_SetStyle()

	return button
end

---@class UI_Quickcast_Button
ns.UI.Quickcast.Button = {
	createButton = createButton,
}
