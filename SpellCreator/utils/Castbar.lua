local addonName, ns = ...

local addonPath = "Interface/AddOns/"..tostring(addonName)
local arcaneGemPath = addonPath.."/assets/gem-icons/Gem"
local addonIcon = arcaneGemPath.."Violet"

local function CustomCastingBarFrame_OnUpdate(self, elapsed)

	if ( self.casting ) then
		self.value = self.value + elapsed;
		if ( self.value >= self.maxValue ) then
			self:SetValue(self.maxValue);
			CastingBarFrame_FinishSpell(self, self.Spark, self.Flash);
			return;
		end
        self:SetValue(self.value);
		if ( self.Flash ) then
			self.Flash:Hide();
		end
		if ( self.Spark ) then
			local sparkPosition = (self.value / self.maxValue) * self:GetWidth();
			self.Spark:SetPoint("CENTER", self, "LEFT", sparkPosition, self.Spark.offsetY or 2);
		end
    elseif ( self.channeling ) then
		self.value = self.value - elapsed;
		if ( self.value <= 0 ) then
			CastingBarFrame_FinishSpell(self, self.Spark, self.Flash);
			return;
		end
		self:SetValue(self.value);
		if ( self.Flash ) then
			self.Flash:Hide();
		end
        if ( self.Spark ) then
			local sparkPosition = (self.value / self.maxValue) * self:GetWidth();
			self.Spark:SetPoint("CENTER", self, "LEFT", sparkPosition, self.Spark.offsetY or 2);
		end
    elseif ( self.flash ) then
		local alpha = 0;
		if ( self.Flash ) then
			alpha = self.Flash:GetAlpha() + CASTING_BAR_FLASH_STEP;
		end
		if ( alpha < 1 ) then
			if ( self.Flash ) then
				self.Flash:SetAlpha(alpha);
			end
		else
			if ( self.Flash ) then
				self.Flash:SetAlpha(1.0);
			end
			self.flash = nil;
		end
	elseif ( self.fadeOut ) then
		local alpha = self:GetAlpha() - CASTING_BAR_ALPHA_STEP;
		if ( alpha > 0 ) then
			CastingBarFrame_ApplyAlpha(self, alpha);
		else
			self.fadeOut = nil;
			self:Hide();
		end
    end

end

local availableCastBars = {}

local function genNewCastBar()

    local castBarNum = #availableCastBars+1
    local castBarName = "SCForgeCastingBar"..castBarNum
    local castStatusBar = CreateFrame("StatusBar", castBarName, UIParent, "CastingBarFrameTemplate")

    if castBarNum == 1 then
        castStatusBar:SetPoint("BOTTOM", CastingBarFrame, "TOP", 0, 20)
    else
        castStatusBar:SetPoint("BOTTOM", "SCForgeCastingBar"..castBarNum-1, "TOP", 0, 20)
    end
    castStatusBar:SetWidth(195)
    castStatusBar:SetHeight(13)

    castStatusBar:Hide()
    castStatusBar.Icon:SetPoint("RIGHT", castStatusBar, "LEFT", -5, 3)
    --castStatusBar.BorderShield:SetVertexColor(0.35,0.7,0.85)
    castStatusBar.BorderShield:SetVertexColor(0.35,0.9,0.95)
    castStatusBar.Border:SetVertexColor(0.5,1,1)
    --SCForgeCastingBar.BorderShield:SetVertexColor(0.35,0.9,0.95)

    castStatusBar.IconBG = castStatusBar:CreateTexture(nil, "BACKGROUND")
        castStatusBar.IconBG:SetTexture(addonPath.."/assets/CircularBG")
        castStatusBar.IconBG:SetTexCoord(0.25,1-0.25,0,1)
        castStatusBar.IconBG:SetPoint("CENTER", castStatusBar.Icon)
        castStatusBar.IconBG:SetSize(24,24)


    castStatusBar:SetScript("OnShow", nil)
    CastingBarFrame_OnLoad(castStatusBar, nil, false, true)

    --castStatusBar:SetStatusBarColor(206/255, 46/255, 255/255)
    CastingBarFrame_SetStartCastColor(castStatusBar, 206/255, 46/255, 255/255)
    CastingBarFrame_SetStartChannelColor(castStatusBar, 0/255, 255/255, 255/255);
    castStatusBar.Spark:SetVertexColor(206/255, 46/255, 255/255)

    castStatusBar:SetScript("OnUpdate", CustomCastingBarFrame_OnUpdate)

    tinsert(availableCastBars, castStatusBar)
    
    print("Made a new cast bar.")
    return castStatusBar

end
genNewCastBar()

local function stopCastingBars()
    for i = 1, #availableCastBars do
        local self = availableCastBars[i]
        if ( not self:IsVisible() ) then
            self:Hide();
        end
        if ( self.casting or self.channeling ) then
            if ( self.Spark ) then
                self.Spark:Hide();
            end
            if ( self.Flash ) then
                self.Flash:SetAlpha(0.0);
                self.Flash:Show();
            end
            self:SetValue(self.maxValue);
            if self.casting then 
                if not self.finishedColorSameAsStart then
                    self:SetStatusBarColor(self.finishedCastColor:GetRGB());
                end
            end
            self.casting = nil;
            self.channeling = nil
            self.flash = true;
            self.fadeOut = true;
            self.holdTime = 0;
        end
    end
end

local function getFreeCastBar()
    for i = 1, #availableCastBars do
        local castbar = availableCastBars[i]
        if not castbar:IsShown() then return castbar end
    end
    return genNewCastBar()
end

local function showCastBar(length, text, spellData, channeled, showIcon, showShield)

    if length < 0.75 then return end; -- hard limit for no cast bars under 0.75 cuz it looks terrible
    
    local self = getFreeCastBar()
    local notInterruptible = false
    local startColor
    
    if not showIcon then showIcon = false end
    self.showShield = showShield or false
    if not text or text == "" then text = "Arcanum Spell" end
    local castIcon = addonIcon -- default icon, change it below if needed

    if spellData then 
        -- do stuff here to give more UI info, like setting the icon
    end

    startColor = CastingBarFrame_GetEffectiveStartColor(self, channeled, notInterruptible);
    self:SetStatusBarColor(startColor:GetRGB());

    self.maxValue = (length);
    if channeled then 
        if ( self.Spark ) then
            self.Spark:Show(); -- Blizzard style UI has this as :Hide(); I think it looks nicer shown
            self.Spark:SetVertexColor(startColor:GetRGB())
        end
        self.value = length;
        self.channeling = true;
        self.casting = nil;
    else
        if ( self.Spark ) then
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
    if ( self.Text ) then
        self.Text:SetText(text);
    end
    if ( self.Icon and showIcon ) then
        self.Icon:SetTexture(castIcon);
        self.Icon:SetShown(true);
    end
    CastingBarFrame_ApplyAlpha(self, 1.0);
    self.holdTime = 0;
    self.fadeOut = nil;
    if ( self.BorderShield and self.showShield ) then
        self.BorderShield:Show();
        self.Flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield");
        self.IconBG:Show();
        if ( self.Border ) then
            self.Border:Hide();
            self.Icon:SetPoint("RIGHT", self, "LEFT", -2.5, 4)
        end
    else
        self.BorderShield:Hide();
        self.Flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash");
        self.IconBG:Hide();
        if ( self.Border ) then
            self.Border:Show();
            self.Icon:SetPoint("RIGHT", self, "LEFT", -5, 3)
        end
    end
    self:Show();
end

ns.Utils.Castbar = {
    showCastBar = showCastBar,
    stopCastingBars = stopCastingBars,
}