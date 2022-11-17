---@class ns
local ns = select(2, ...)

local executeSpell = ns.Actions.Execute.executeSpell
local cmdWithDotCheck = ns.Cmd.cmdWithDotCheck
local ADDON_COLOR = ns.Constants.ADDON_COLOR
local ASSETS_PATH = ns.Constants.ASSETS_PATH
local cprint, dprint, eprint = ns.Logging.cprint, ns.Logging.dprint, ns.Logging.eprint
local phaseVault = ns.Vault.phase

local f = CreateFrame("Button", "SCForgeQuickcast", UIParent)
--f:SetPoint("CENTER")
f:SetPoint("TOPRIGHT", -60, -220)
f:SetSize(50,50)

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

f.hitFrame = CreateFrame("Frame", nil, f)
f.hitFrame:SetSize(135,135)
f.hitFrame:SetPoint("CENTER")
f.hitFrame:SetFrameStrata("LOW")

f.icon = f:CreateTexture(nil, "ARTWORK")
f.icon:SetAllPoints()
f.icon:SetTexture(ASSETS_PATH .. "/BookIcon")
f.castButtons = {}

local function CustomUIFrameFadeOut(frame, timeToFade, startAlpha, endAlpha)
	local fadeInfo = {};
	fadeInfo.mode = "OUT";
	fadeInfo.timeToFade = timeToFade;
	fadeInfo.startAlpha = startAlpha;
	fadeInfo.endAlpha = endAlpha;
	fadeInfo.finishedArg1 = frame
	if endAlpha == 0 then
		fadeInfo.finishedFunc = function(frame) frame:Hide() end
	end
	UIFrameFade(frame, fadeInfo);
end

local function hideCastButtons(buttonToActivate)
	local frame = f
	for i = 1, #frame.castButtons do
		local button = frame.castButtons[i]
		button.showTimer:Cancel()
		if UIFrameIsFading(button) then UIFrameFadeRemoveFrame(button) end

		if button == buttonToActivate then
			button.anims:Play()
			CustomUIFrameFadeOut(button, 0.5, 1, 0)
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
	pushedTex:SetVertexOffset(UPPER_LEFT_VERTEX, 1, -1)
	pushedTex:SetVertexOffset(UPPER_RIGHT_VERTEX, 1, -1)
	pushedTex:SetVertexOffset(LOWER_LEFT_VERTEX, 1, -1)
	pushedTex:SetVertexOffset(LOWER_RIGHT_VERTEX, 1, -1)
end

--local quickCastSpells = {"arcsmash", "drunk","drunk","drunk","drunk","drunk","drunk","drunk","drunk","drunk","drunk",}
local function genQuickCastButtons(self)
	local quickCastSpells = SpellCreatorMasterTable.quickCastSpells
	local numSpells = #quickCastSpells
	local radius = 42+(2*numSpells)
	self.radius = radius
	for i = 1, #quickCastSpells do
		local v = quickCastSpells[i]
		local spellData = SpellCreatorSavedSpells[v]
		if not self.castButtons[i] then
			self.castButtons[i] = CreateFrame("Button", nil, self)
			local button = self.castButtons[i]
			button:Hide()
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button.index = i
			--button.icon = button:CreateTexture(nil, "ARTWORK")
			--button.icon:SetAllPoints()
			local someIcon = ns.UI.Gems.randomGem()
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
			local ringPadding = 3
			button.ring:SetPoint("TOPLEFT",-ringPadding,ringPadding)
			button.ring:SetPoint("BOTTOMRIGHT",ringPadding,-ringPadding)
			button.ring:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
			button:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")
			button.anims = button:CreateAnimationGroup()
			button.anims.move = button.anims:CreateAnimation("Translation")
			button.anims.move:SetOffset(0, 10)
			button.anims.move:SetDuration(0.5)

			button:SetScript("OnEnter", function(self)
				if self.tooltipText ~= nil then
					if self.tooltipTitle then
						GameTooltip:SetOwner(self, "ANCHOR_LEFT")
						self.Timer = C_Timer.NewTimer(0.35,function()
							GameTooltip:SetText(self.tooltipTitle, nil, nil, nil, nil, true)
							GameTooltip:AddLine(self.tooltipText,1,1,1,true)
							GameTooltip:Show()
						end)
					end
				end
			end)
			button:SetScript("OnLeave", function(self)
				if self.tooltipText ~= nil then
					GameTooltip:Hide();
				end
			end)
		end
		local x = radius * math.cos(((i-1)/numSpells)*(2*math.pi));
		local y = radius * math.sin(((i-1)/numSpells)*(2*math.pi));
		local button = self.castButtons[i]
		button:SetPoint("CENTER", self, "CENTER", x, y)
		button:SetSize(30,30)

		if spellData == nil then
			button.tooltipTitle = "Error Loading Spell"
			button.tooltipText = "Spell "..i.." does not exist in your vault."
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
			button.tooltipText = "Cast '"..spellData.commID.."' ("..#spellData.actions.." actions)."
			button.commID = spellData.commID
			if spellData.icon then
				--button.icon:SetTexture(ns.UI.Icons.getIcon(spellData.icon))
				button:SetNormalTexture(ns.UI.Icons.getIcon(spellData.icon))
			else
				local iconNum = ((i-1) % (#ns.UI.Gems.arcaneGemIcons)) + 1
				--button.icon:SetTexture(ns.UI.Gems.gemPath(ns.UI.Gems.arcaneGemIcons[iconNum]))
				button:SetNormalTexture(ns.UI.Gems.gemPath(ns.UI.Gems.arcaneGemIcons[iconNum]))
			end
			button:SetScript("OnClick", function(self, button)
				if button == "RightButton" then
					tremove(quickCastSpells, i)
					hideCastButtons()
					C_Timer.After(0.1, function() genQuickCastButtons(self:GetParent()) end)
				else
					executeSpell(spellData.actions, nil, spellData.fullName)
					hideCastButtons(self)
				end
			end)
		end
		updateButtonTexs(button)
		--button:Show()
		if not button:IsShown() then button.showTimer = C_Timer.NewTimer(0.05*i, function() UIFrameFadeIn(button, 0.05, 0, 1) end) end
	end

end

f:SetScript("OnEnter", function(self)
	genQuickCastButtons(self)
	self.hitFrame:SetSize((self.radius+35)*2, (self.radius+35)*2)

	if #SpellCreatorMasterTable.quickCastSpells == 0 then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("Quickcast Book", nil, nil, nil, nil, true)
		GameTooltip:AddLine("You can add Arcanum Spells to your Quickcast Book by right-clicking them in your vault!\n\rClick & Drag to move your book anywhere.",1,1,1,true)
		GameTooltip:Show()
	end
end)
f:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
end)

f.hitFrame:SetScript("OnLeave", function(self)
	if self:IsMouseOver() then return end
	self:SetSize(50, 50)
	hideCastButtons()
end)

--local quickCastHotkeys = { {key = "A", commID = "drunk"} }
f:SetScript("OnKeyDown", function(self, button)
	local quickCastHotkeys = SpellCreatorMasterTable.quickCastHotkeys
	for i = 1, #quickCastHotkeys do
		local v = quickCastHotkeys[i]
		if v.key == button then
			ns.Actions.Execute.executeSpell(SpellCreatorSavedSpells[v.commID].actions, nil, SpellCreatorSavedSpells[v.commID].fullName)
		end
	end
end)
f:SetPropagateKeyboardInput(true)

---@class UI_Quickcast
ns.UI.Quickcast = {
	hideCastCuttons = hideCastButtons
}
