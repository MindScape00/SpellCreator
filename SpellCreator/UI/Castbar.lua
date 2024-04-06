local addonName = ...
---@class ns
local ns = select(2, ...)

local isNotDefined = ns.Utils.Data.isNotDefined

local addonPath = "Interface/AddOns/" .. tostring(addonName)
local arcaneGemPath = addonPath .. "/assets/gem-icons/Gem"
local addonIcon = arcaneGemPath .. "Violet"
local castingBarFillTexture = addonPath .. "/assets/castingbar-fill"
local castingBarShieldBorder = addonPath .. "/assets/castingbar-border-icon"

local function CustomCastingBarFrame_OnUpdate(self, elapsed)
	if (self.casting) then
		self.value = self.value + elapsed;
		if (self.value >= self.maxValue) then
			self:SetValue(self.maxValue);
			CastingBarFrame_FinishSpell(self, self.Spark, self.Flash);
			return;
		end
		self:SetValue(self.value);
		if (self.Flash) then
			self.Flash:Hide();
		end
		if (self.Spark) then
			local sparkPosition = (self.value / self.maxValue) * self:GetWidth();
			self.Spark:SetPoint("CENTER", self, "LEFT", sparkPosition, self.Spark.offsetY or 2);
		end
	elseif (self.channeling) then
		self.value = self.value - elapsed;
		if (self.value <= 0) then
			CastingBarFrame_FinishSpell(self, self.Spark, self.Flash);
			return;
		end
		self:SetValue(self.value);
		if (self.Flash) then
			self.Flash:Hide();
		end
		if (self.Spark) then
			local sparkPosition = (self.value / self.maxValue) * self:GetWidth();
			self.Spark:SetPoint("CENTER", self, "LEFT", sparkPosition, self.Spark.offsetY or 2);
		end
	elseif (self.flash) then
		local alpha = 0;
		if (self.Flash) then
			alpha = self.Flash:GetAlpha() + CASTING_BAR_FLASH_STEP;
		end
		if (alpha < 1) then
			if (self.Flash) then
				self.Flash:SetAlpha(alpha);
			end
		else
			if (self.Flash) then
				self.Flash:SetAlpha(1.0);
			end
			self.flash = nil;
		end
	elseif (self.fadeOut) then
		local alpha = self:GetAlpha() - CASTING_BAR_ALPHA_STEP;
		if (alpha > 0) then
			CastingBarFrame_ApplyAlpha(self, alpha);
		else
			self.fadeOut = nil;
			self:Hide();
		end
	end
end

local availableCastBars = {}

local function genNewCastBar()
	local castBarNum = #availableCastBars + 1
	local castBarName = "SCForgeCastingBar" .. castBarNum
	local castStatusBar = CreateFrame("StatusBar", castBarName, nil, "CastingBarFrameTemplate")
	castStatusBar:SetScale(UIParent:GetScale())

	if castBarNum == 1 then
		castStatusBar:SetPoint("BOTTOM", CastingBarFrame, "TOP", 0, 20)
	else
		castStatusBar:SetPoint("BOTTOM", "SCForgeCastingBar" .. castBarNum - 1, "TOP", 0, 20)
	end
	castStatusBar:SetWidth(195)
	castStatusBar:SetHeight(13)

	castStatusBar:Hide()
	castStatusBar.Icon:SetPoint("RIGHT", castStatusBar, "LEFT", 0, 4)
	castStatusBar.Icon:SetSize(20, 20)
	--castStatusBar.BorderShield:SetVertexColor(0.35,0.7,0.85)
	castStatusBar.BorderShield:SetVertexColor(0.35, 0.9, 0.95)
	castStatusBar.Border:SetVertexColor(0.5, 1, 1)
	--SCForgeCastingBar.BorderShield:SetVertexColor(0.35,0.9,0.95)

	castStatusBar.IconBG = castStatusBar:CreateTexture(nil, "BACKGROUND")
	castStatusBar.IconBG:SetTexture(addonPath .. "/assets/CircularBG")
	castStatusBar.IconBG:SetTexCoord(0.25, 1 - 0.25, 0, 1)
	castStatusBar.IconBG:SetPoint("CENTER", castStatusBar.Icon)
	castStatusBar.IconBG:SetSize(24, 24)


	castStatusBar:SetScript("OnShow", nil)
	CastingBarFrame_OnLoad(castStatusBar, nil, false, true)

	--castStatusBar:SetStatusBarColor(206/255, 46/255, 255/255)
	CastingBarFrame_SetStartCastColor(castStatusBar, 206 / 255, 46 / 255, 255 / 255)
	CastingBarFrame_SetStartChannelColor(castStatusBar, 0 / 255, 255 / 255, 255 / 255);
	castStatusBar.Spark:SetVertexColor(206 / 255, 46 / 255, 255 / 255)

	castStatusBar:SetStatusBarTexture(castingBarFillTexture)
	castStatusBar.BorderShield:SetTexture(castingBarShieldBorder)

	castStatusBar:SetScript("OnUpdate", CustomCastingBarFrame_OnUpdate)

	tinsert(availableCastBars, castStatusBar)

	return castStatusBar
end
genNewCastBar()

local function hideCastBar(castbar)
	if (not castbar:IsVisible()) then
		castbar:Hide();
	end
	if (castbar.casting or castbar.channeling) then
		if (castbar.Spark) then
			castbar.Spark:Hide();
		end
		if (castbar.Flash) then
			castbar.Flash:SetAlpha(0.0);
			castbar.Flash:Show();
		end
		castbar:SetValue(castbar.maxValue);
		if castbar.casting then
			if not castbar.finishedColorSameAsStart then
				castbar:SetStatusBarColor(castbar.finishedCastColor:GetRGB());
			end
		end
		castbar.casting = nil;
		castbar.channeling = nil;
		castbar.flash = true;
		castbar.fadeOut = true;
		castbar.holdTime = 0;
		castbar.arcCommID = nil;
	end
end

---Stop Current Casting Bars, or all casting bars with commID.
---@param commID any
local function stopCastingBars(commID)
	for i = 1, #availableCastBars do
		local self = availableCastBars[i]
		if commID then
			if self.arcCommID == commID then
				hideCastBar(self)
			end
		else
			hideCastBar(self)
		end
	end
end

local function getFreeCastBar()
	for i = 1, #availableCastBars do
		local castbar = availableCastBars[i]
		if not castbar:IsShown() then
			castbar.arcCommID = nil
			return castbar
		end
	end
	return genNewCastBar()
end

---Show a visual castbar for our spell
---@param length number
---@param text string
---@param spellData VaultSpell
---@param channeled boolean
---@param showIcon boolean
---@param showShield boolean
local function showCastBar(length, text, spellData, channeled, showIcon, showShield)
	length = tonumber(length) -- somehow we got a string one time and it was weird.. might've been a me being dumb but..
	if length < 0.25 then return end  -- hard limit for no cast bars under 0.25 cuz it looks terrible

	local self = getFreeCastBar()
	local notInterruptible = false
	local startColor

	if isNotDefined(showShield) then showShield = true end
	if isNotDefined(showIcon) or showShield == true then showIcon = true end
	self.showShield = showShield

	if not text or text == "" then text = "Arcanum Spell" end
	local castIcon = addonIcon -- default icon, change it below if needed

	if spellData then
		if not ns.Utils.Data.isNotDefined(spellData.icon) then castIcon = ns.UI.Icons.getFinalIcon(spellData.icon) end

		self.arcCommID = spellData.commID
	end

	startColor = CastingBarFrame_GetEffectiveStartColor(self, channeled, notInterruptible);
	self:SetStatusBarColor(startColor:GetRGB());

	self.maxValue = (length);
	if channeled then
		if (self.Spark) then
			self.Spark:Show(); -- Blizzard style UI has this as :Hide(); I think it looks nicer shown
			self.Spark:SetVertexColor(startColor:GetRGB())
		end
		self.value = length;
		self.channeling = true;
		self.casting = nil;
	else
		if (self.Spark) then
			self.Spark:Show();
			self.Spark:SetVertexColor(startColor:GetRGB())
		end
		self.value = 0;
		self.casting = true;
		self.channeling = nil;
	end

	if self.flashColorSameAsStart then
		self.Flash:SetVertexColor(startColor:GetRGB());
	else
		self.Flash:SetVertexColor(1, 1, 1);
	end

	self:SetMinMaxValues(0, self.maxValue);
	self:SetValue(self.value);
	if (self.Text) then
		self.Text:SetText(text);
	end
	if (self.Icon and showIcon) then
		self.Icon:SetTexture(castIcon);
		self.Icon:SetShown(true);
	end
	CastingBarFrame_ApplyAlpha(self, 1.0);
	self.holdTime = 0;
	self.fadeOut = nil;
	if (self.BorderShield and self.showShield) then
		self.BorderShield:Show();
		self.Flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield");
		self.IconBG:Show();
		if (self.Border) then
			self.Border:Hide();
			self.Icon:SetPoint("RIGHT", self, "LEFT", 0, 4)
		end
	else
		self.BorderShield:Hide();
		self.Flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash");
		self.IconBG:Hide();
		if (self.Border) then
			self.Border:Show();
			self.Icon:SetPoint("RIGHT", self, "LEFT", -5, 3)
		end
	end
	self:Show();
end

---@class UI_Castbar
ns.UI.Castbar = {
	showCastBar = showCastBar,
	stopCastingBars = stopCastingBars,
}
