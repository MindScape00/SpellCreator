---@class ns
local ns = select(2, ...)

local ASSETS_PATH = ns.Constants.ASSETS_PATH
local dprint = ns.Logging.dprint
local Gems = ns.UI.Gems
local minimapModels, modelFrameSetModel = ns.UI.Models.minimapModels, ns.UI.Models.modelFrameSetModel

local runeIconOverlay

local function initRuneIcon()
	local runeIconOverlays = {
		{atlas = "Rune-0"..fastrandom(6).."-purple", desat = false, x = 30, y = 30, alpha=0.8},
		{atlas = "Rune-"..string.format("%02d",fastrandom(11)).."-light", desat = true, x = 30, y = 30, alpha=0.8},
		{atlas = "ChallengeMode-Runes-BL-Glow", desat = true, x = 32, y = 32},
		{atlas = "ChallengeMode-Runes-BR-Glow", desat = true, x = 32, y = 32},
		{atlas = "ChallengeMode-Runes-L-Glow", desat = true, x = 34, y = 34},
		{atlas = "ChallengeMode-Runes-R-Glow", desat = true, x = 32, y = 32},
		{atlas = "ChallengeMode-Runes-T-Glow", desat = true, x = 32, y = 32},
		{atlas = "heartofazeroth-slot-minor-unactivated-rune", desat = true, x = 44, y = 44, alpha=0.8},
		{atlas = "Darklink-active", desat = true},
		{tex = ASSETS_PATH .. "/BookIcon", desat = false, x = 26, y = 26},
	}
	runeIconOverlay = runeIconOverlays[fastrandom(#runeIconOverlays)]
end

local function createIcon()
	SCForgeMainFrame.portrait.icon = SCForgeMainFrame:CreateTexture(nil, "OVERLAY", nil, 6)
	SCForgeMainFrame.portrait.icon:SetTexture(Gems.randomGem())
	SCForgeMainFrame.portrait.icon:SetAllPoints(SCForgeMainFrame.portrait)
	SCForgeMainFrame.portrait.icon:SetAlpha(0.93)
	--SCForgeMainFrame.portrait.icon:SetBlendMode("ADD")
end

local function createModel()
	SCForgeMainFrame.portrait.Model = CreateFrame("PLAYERMODEL", nil, SCForgeMainFrame, "MouseDisabledModelTemplate")
	SCForgeMainFrame.portrait.Model:SetAllPoints(SCForgeMainFrame.portrait)
	SCForgeMainFrame.portrait.Model:SetFrameStrata("MEDIUM")
	SCForgeMainFrame.portrait.Model:SetFrameLevel(SCForgeMainFrame:GetFrameLevel())
	SCForgeMainFrame.portrait.Model:SetModelDrawLayer("OVERLAY")
	SCForgeMainFrame.portrait.Model:SetKeepModelOnHide(true)
	modelFrameSetModel(SCForgeMainFrame.portrait.Model, fastrandom(#minimapModels), minimapModels)
	SCForgeMainFrame.portrait.Model:SetScript("OnMouseDown", function()
		local randID = fastrandom(#minimapModels)
		modelFrameSetModel(SCForgeMainFrame.portrait.Model, randID, minimapModels)
		dprint("Portrait Icon BG Model Set to ID "..randID)
	end)
end

local function createRune()
	SCForgeMainFrame.portrait.rune = SCForgeMainFrame:CreateTexture(nil, "OVERLAY", nil, 7)

	local function setRuneTex(texInfo)
		if texInfo.atlas then
			SCForgeMainFrame.portrait.rune:SetAtlas(texInfo.atlas)
		else
			SCForgeMainFrame.portrait.rune:SetTexture(texInfo.tex)
		end
		if texInfo.desat then
			SCForgeMainFrame.portrait.rune:SetDesaturated(true)
			SCForgeMainFrame.portrait.rune:SetVertexColor(0.9,0.9,0.9)
		else
			SCForgeMainFrame.portrait.rune:SetDesaturated(false)
			SCForgeMainFrame.portrait.rune:SetVertexColor(1,1,1)
		end
		SCForgeMainFrame.portrait.rune:SetPoint("CENTER", SCForgeMainFrame.portrait)
		SCForgeMainFrame.portrait.rune:SetSize(texInfo.x or 28, texInfo.y or 28)
		SCForgeMainFrame.portrait.rune:SetBlendMode(texInfo.blend or "ADD")
		SCForgeMainFrame.portrait.rune:SetAlpha(texInfo.alpha or 1)
	end

	setRuneTex(runeIconOverlay)
end

local function initPortrait()
	--local SC_randomFramePortrait = frameIconOptions[fastrandom(#frameIconOptions)] -- Old Random Icon Stuff
	--SCForgeMainFrame:SetPortraitToAsset(SC_randomFramePortrait) -- Switched to using our version.
	--SCForgeMainFrame.portrait:SetTexture(ASSETS_PATH .. "/arcanum_icon")
	SCForgeMainFrame.portrait:SetTexture(ASSETS_PATH .. "/CircularBG")
	SCForgeMainFrame.portrait:SetTexCoord(0.25,1-0.25,0,1)
	SCForgeMainFrame.portrait.mask = SCForgeMainFrame:CreateMaskTexture()
	SCForgeMainFrame.portrait.mask:SetAllPoints(SCForgeMainFrame.portrait)
	SCForgeMainFrame.portrait.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	SCForgeMainFrame.portrait:AddMaskTexture(SCForgeMainFrame.portrait.mask)
end

local function init()
	initPortrait()

	createIcon()

	initRuneIcon()
	-- debug over-ride, comment out when done
	-- runeIconOverlay = {tex = "Interface/AddOns/SpellCreator/assets/BookIcon"}
	createRune()

	createModel()
end

---@class UI_Portrait
ns.UI.Portrait = {
	init = init,
}
