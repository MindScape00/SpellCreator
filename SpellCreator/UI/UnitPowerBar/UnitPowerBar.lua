---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local ASSETS_PATH = Constants.ASSETS_PATH .. "/"

-------------------------------------------------------------------------------
--
-- Unit Power Bar interface.
--

local altPowerBars = {
	["Air"] = {
		path = "Interface/UNITPOWERBARALT/Air_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["Alliance"] = {
		path = "Interface/UNITPOWERBARALT/Alliance_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["Amber"] = {
		path = "Interface/UNITPOWERBARALT/Amber_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = false,
		flash = true,
		inset = 0.14,
	},
	["ArdenwealdAnima"] = {
		path = "Interface/UNITPOWERBARALT/ArdenwealdAnima_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.14,
	},
	["Arsenal"] = {
		path = "Interface/UNITPOWERBARALT/Arsenal_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = false,
		flash = true,
		inset = 0.135,
	},
	["Azerite"] = {
		path = "Interface/UNITPOWERBARALT/Azerite_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.14,
	},
	["Bamboo"] = {
		path = "Interface/UNITPOWERBARALT/Bamboo_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.12,
	},
	["BastionAnima"] = {
		path = "Interface/UNITPOWERBARALT/BastionAnima_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.14,
	},
	["BrewingStorm"] = {
		path = "Interface/UNITPOWERBARALT/BrewingStorm_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.135,
	},
	["BulletBar"] = {
		path = "Interface/UNITPOWERBARALT/BulletBar_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = false,
		flash = true,
		inset = 0.14,
	},
	["Chogall"] = {
		path = "Interface/UNITPOWERBARALT/Chogall_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.23,
	},
	["Darkmoon"] = {
		path = "Interface/UNITPOWERBARALT/Darkmoon_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.21,
	},
	["DeathwingBlood"] = {
		path = "Interface/UNITPOWERBARALT/DeathwingBlood_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.14,
	},
	["Druid"] = {
		path = "Interface/UNITPOWERBARALT/Druid_Horizontal_",
		frame = true,
		background = false,
		fill = true,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["FancyPanda"] = {
		path = "Interface/UNITPOWERBARALT/FancyPanda_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.135,
	},
	["FelCorruption"] = {
		path = "Interface/UNITPOWERBARALT/FelCorruption_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.14,
	},
	["Fire"] = {
		path = "Interface/UNITPOWERBARALT/Fire_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["FuelGauge"] = {
		path = "Interface/UNITPOWERBARALT/FuelGauge_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.135,
	},
	["GarroshEnergy"] = {
		path = "Interface/UNITPOWERBARALT/GarroshEnergy_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.2,
	},
	["Generic1Player"] = {
		path = "Interface/UNITPOWERBARALT/Generic1Player_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.135,
	},
	["Horde"] = {
		path = "Interface/UNITPOWERBARALT/Horde_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["Ice"] = {
		path = "Interface/UNITPOWERBARALT/Ice_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["InquisitionTorment"] = {
		path = "Interface/UNITPOWERBARALT/InquisitionTorment_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.18,
	},
	["Jaina"] = {
		path = "Interface/UNITPOWERBARALT/Jaina_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.14,
	},
	["KargathRoarCrowd"] = {
		path = "Interface/UNITPOWERBARALT/KargathRoarCrowd_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.14,
	},
	["LightningCharges"] = {
		path = "Interface/UNITPOWERBARALT/LightningCharges_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.14,
	},
	["MaldraxxusAnima"] = {
		path = "Interface/UNITPOWERBARALT/MaldraxxusAnima_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.14,
	},
	["Map"] = {
		path = "Interface/UNITPOWERBARALT/Map_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = false,
		flash = true,
		inset = 0.1,
		insetRight = 0.125,
	},
	["Meat"] = {
		path = "Interface/UNITPOWERBARALT/Meat_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = true,
		inset = 0.14,
	},
	["Mechanical"] = {
		path = "Interface/UNITPOWERBARALT/Mechanical_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["Meditation"] = {
		path = "Interface/UNITPOWERBARALT/Meditation_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = true,
		flash = false,
		inset = 0.14,
	},
	["MoltenRock"] = {
		path = "Interface/UNITPOWERBARALT/MoltenRock_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["Murozond"] = {
		path = "Interface/UNITPOWERBARALT/Murozond_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = false,
		flash = false,
		inset = 0.05,
	},
	["NaaruCharge"] = {
		path = "Interface/UNITPOWERBARALT/NaaruCharge_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.15,
	},
	["NZoth"] = {
		path = "Interface/UNITPOWERBARALT/Nzoth_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.135,
	},
	["Onyxia"] = {
		path = "Interface/UNITPOWERBARALT/Onyxia_Horizontal_",
		frame = true,
		background = false,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.135,
	},
	["Pride"] = {
		path = "Interface/UNITPOWERBARALT/Pride_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.15,
	},
	["RevendrethAnima"] = {
		path = "Interface/UNITPOWERBARALT/RevendrethAnima_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.14,
	},
	["Rhyolith"] = {
		path = "Interface/UNITPOWERBARALT/Rhyolith_Horizontal_",
		frame = true,
		background = true,
		fill = true,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["Rock"] = {
		path = "Interface/UNITPOWERBARALT/Rock_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["ShadowPaladinBar"] = {
		path = "Interface/UNITPOWERBARALT/ShadowPaladinBar_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = false,
		flash = false,
		inset = 0.2,
	},
	["StoneDesign"] = {
		path = "Interface/UNITPOWERBARALT/StoneDesign_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["UndeadMeat"] = {
		path = "Interface/UNITPOWERBARALT/UndeadMeat_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["Water"] = {
		path = "Interface/UNITPOWERBARALT/Water_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["WoodPlank"] = {
		path = "Interface/UNITPOWERBARALT/WoodPlank_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["WoodWithMetal"] = {
		path = "Interface/UNITPOWERBARALT/WoodWithMetal_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["WoWUI"] = {
		path = "Interface/UNITPOWERBARALT/WoWUI_Horizontal_",
		frame = true,
		background = false,
		fill = false,
		spark = false,
		flash = false,
		inset = 0.14,
	},
	["Xavius"] = {
		path = "Interface/UNITPOWERBARALT/Xavius_Horizontal_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.2,
	},
	["sanctum-bar"] = {
		path = ASSETS_PATH .. "UnitPowerBar/sanctum-bar_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = true,
		inset = 0.08,
	},
	["warden-bar"] = {
		path = ASSETS_PATH .. "UnitPowerBar/warden-bar_",
		frame = false,
		background = true,
		fill = true,
		spark = false,
		flash = true,
		inset = 0.18,
	},
	["archer-bar"] = {
		path = ASSETS_PATH .. "UnitPowerBar/archer-bar_",
		frame = false,
		background = true,
		fill = true,
		spark = false,
		flash = false,
		inset = 0.26,
	},
	["mana-gems-bar"] = {
		path = ASSETS_PATH .. "UnitPowerBar/mana-gems-bar_",
		frame = false,
		background = true,
		fill = true,
		spark = false,
		flash = true,
		inset = 0.05,
	},
	["phoenix-bar"] = {
		path = ASSETS_PATH .. "UnitPowerBar/phoenix-bar_",
		frame = false,
		background = true,
		fill = true,
		spark = false,
		flash = true,
		inset = 0.24,
	},
	["holy-power-bar"] = {
		path = ASSETS_PATH .. "UnitPowerBar/holy-power-bar_",
		frame = false,
		background = true,
		fill = true,
		spark = false,
		flash = true,
		inset = 0.2,
	},
	["balance-bar"] = {
		path = ASSETS_PATH .. "UnitPowerBar/balance-bar_",
		frame = false,
		background = true,
		fill = true,
		spark = true,
		flash = false,
		inset = 0,
	},
}

local availablePowerBars = {}
local _altPowerBarsCopy = CopyTable(altPowerBars)
for k, v in pairs(_altPowerBarsCopy) do
	tinsert(availablePowerBars, k)

	-- replace it with a lowercase version, so we can make it case insensitive
	altPowerBars[k] = nil
	altPowerBars[string.lower(k)] = v
end
table.sort(availablePowerBars)
_altPowerBarsCopy = nil

local altPowerBarTextures = {
	frame = "Frame",
	background = "Bgnd",
	fill = "Fill",
	spark = "Spark",
	flash = "Flash",
}

-------------------------------------------------------------------------------
-- Handler for Unit Power Bar tooltips.
--
local function OnEnter(self)
	if not self.powerName then
		return
	end

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(self.powerName or "", 1, 1, 1);
	if self.powerTooltip then
		GameTooltip:AddLine(self.powerTooltip, nil, nil, nil, true);
	end
	GameTooltip:Show();

	if self.isPercentage then
		self.text:SetText(self.powerName .. " " .. self.displayedValue .. "%")
	else
		self.text:SetText(self.displayedValue .. "/" .. self.range)
	end
	self.text:Show()
end

local function OnLeave(self)
	GameTooltip:Hide();
	self.text:Hide()
end

local function SetDisplayedPower(self, value)
	self.displayedValue = value;
	--UnitPowerBarAltStatus_UpdateText(self.statusFrame);
	self:UpdateFill();
end

local function OnUpdate(self, elapsed)
	if (self.value and self.displayedValue and self.value ~= self.displayedValue) then
		SetDisplayedPower(self, GetSmoothProgressChange(self.value, self.displayedValue, self.range, elapsed));
	end
end

-------------------------------------------------------------------------------
local methods = {
	ApplyTextures = function(self, texturePath, powerName, powerTooltip, displayedValue, color, onFinished, isPercentage, flashEnabled)
		self:ClearTextures()
		texturePath = string.lower(texturePath) -- always lower for case insensitive

		self.powerName = powerName;
		self.powerTooltip = powerTooltip;
		if displayedValue then
			if not self.displayedValue then self.displayedValue = displayedValue end
			self.value = displayedValue;
		end
		self.startInset = altPowerBars[texturePath].inset or 0;
		self.endInset = altPowerBars[texturePath].inset or 0;

		if altPowerBars[texturePath].insetRight then
			self.endInset = altPowerBars[texturePath].insetRight
		end

		self.background:SetTexture("Interface/UNITPOWERBARALT/Generic1Player_Horizontal_Bgnd")
		self.fill:SetTexture("Interface/UNITPOWERBARALT/Generic1_Horizontal_Fill")
		self.fill:SetVertexColor(1, 1, 1)

		for textureName, textureIndex in pairs(altPowerBarTextures) do
			local texture = self[textureName];
			if altPowerBars[texturePath][textureName] then
				texture:SetTexture(altPowerBars[texturePath].path .. textureIndex);
			end
			if not altPowerBars[texturePath].fill and color then
				self.fill:SetVertexColor(color[1], color[2], color[3])
			end
		end

		if onFinished then
			self.onFinished = onFinished;
		else
			self.onFinished = nil;
		end

		if isPercentage then
			self.isPercentage = true;
		else
			self.isPercentage = false;
		end

		if flashEnabled then
			self.flashEnabled = true;
		else
			self.flashEnabled = false;
		end

		--self:UpdateFill();
	end,
	---------------------------------------------------------------------------
	--
	--
	ClearTextures = function(self)
		self.flashAnim:Stop()
		self.flashOutAnim:Stop()
		self.flashEnabled = false;

		for textureName, textureIndex in pairs(altPowerBarTextures) do
			local texture = self[textureName];
			texture:SetTexture(nil);
			--texture:Hide();
		end
		self:UpdateFill();
	end,
	---------------------------------------------------------------------------
	--
	--
	SetMinMaxPower = function(self, minPower, maxPower)
		self.range = maxPower - minPower;
		self.maxPower = maxPower;
		self.minPower = minPower;

		self:UpdateFill();
	end,
	---------------------------------------------------------------------------
	--
	--
	SetUp = function(self)
		self.startInset = 0;
		self.endInset = 0;

		self.frame:Show();
		self.background:Show();
		self.fill:Show();
		self.spark:Show();

		self.spark:ClearAllPoints();
		self.spark:SetHeight(self:GetHeight());
		self.spark:SetWidth(self:GetHeight() / 8);
		self.spark:SetPoint("LEFT", self.fill, "RIGHT", -5, 0);

		self.fill:ClearAllPoints();
		self.fill:SetPoint("TOPLEFT");
		self.fill:SetPoint("BOTTOMLEFT");
		self.fill:SetWidth(self:GetWidth());

		--self:SetMinMaxPower( 0, 100 )
	end,
	---------------------------------------------------------------------------
	--
	--
	UpdateFill = function(self)
		if (not self.range or self.range == 0 or not self.displayedValue) then
			return;
		end
		local ratio = self.displayedValue / self.range;
		local fillAmount = self.startInset + ratio * ((1 - self.endInset) - self.startInset);
		self.fill:SetWidth(max(self:GetWidth() * fillAmount, 1));
		self.fill:SetTexCoord(0, fillAmount, 0, 1);

		if not self.flashEnabled then
			self.flash:SetAlpha(0)
		end

		if self.displayedValue == self.range then
			self.spark:Hide();
			if (not self.flash:IsShown() and self.flashEnabled) then
				self.flash:Show();
				self.flash:SetAlpha(1);
				self.flashAnim:Play();
			elseif (not self.flashAnim:IsPlaying() and self.flashEnabled) then
				self.flash:SetAlpha(1);
			end
		else
			if self.displayedValue == 0 then
				self.spark:Hide();
			else
				self.spark:Show();
			end
			self.flashAnim:Stop();
			if (self.flash:IsShown() and not self.flashOutAnim:IsPlaying() and self.flashEnabled) then
				self.flashOutAnim:Play();
			end
		end
	end,
}

-------------------------------------------------------------------------------
-- Initialize a new Unit Power Bar.
--
function SCForge_UnitPowerBar_Init(self)
	for k, v in pairs(methods) do
		self[k] = v
	end

	self:SetClampedToScreen(true)
	self:SetMovable(true)
	self:EnableMouse(true)
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	self:SetUserPlaced(true)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self:SetScript("OnUpdate", OnUpdate)

	self:SetUp();
end

---@class UI_TalkingHead_TalkingHead
ns.UI.TalkingHead.TalkingHead = {
	availablePowerBars = availablePowerBars,
}
