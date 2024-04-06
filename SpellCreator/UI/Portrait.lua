---@class ns
local ns = select(2, ...)

local ASSETS_PATH = ns.Constants.ASSETS_PATH
local dprint = ns.Logging.dprint
local Gems = ns.UI.Gems
local minimapModels, modelFrameSetModel = ns.UI.Models.minimapModels, ns.UI.Models.modelFrameSetModel

local runeIconOverlay
local minimapModelID
local gemToUse

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
	minimapModelID = fastrandom(#minimapModels)
	gemToUse = Gems.randomLimitedGem()
end

---@param frame frame frame to assign the table accessor (i.e., SCForgeMainFrame.portrait (which creates SCForgeMainFrame.portrait.icon))
---@param parent frame the actual parent the texture is created on (i.e., SCForgeMainFrame)
local function createIcon(frame, parent)
	frame.icon = parent:CreateTexture(nil, "OVERLAY", nil, 6)
	frame.icon:SetTexture(gemToUse)
	frame.icon:SetAllPoints(frame)
	frame.icon:SetAlpha(0.93)
	--frame.icon:SetBlendMode("ADD")
end

---@param frame frame frame to assign the table accessor (i.e., SCForgeMainFrame.portrait.icon)
---@param parent frame the actual parent the texture is created on (i.e., SCForgeMainFrame)
local function createModel(frame, parent)
	frame.Model = CreateFrame("PLAYERMODEL", nil, parent, "MouseDisabledModelTemplate")
	frame.Model:SetAllPoints(frame)
	frame.Model:SetFrameStrata("MEDIUM")
	frame.Model:SetFrameLevel(parent:GetFrameLevel())
	frame.Model:SetModelDrawLayer("OVERLAY")
	frame.Model:SetKeepModelOnHide(true)
	modelFrameSetModel(frame.Model, minimapModelID, minimapModels)
	frame.Model:SetScript("OnMouseDown", function()
		local randID = fastrandom(#minimapModels)
		modelFrameSetModel(frame.Model, randID, minimapModels)
		dprint("Portrait Icon BG Model Set to ID "..randID)
	end)
end

---@param frame frame frame to assign the table accessor (i.e., SCForgeMainFrame.portrait.icon)
---@param parent frame the actual parent the texture is created on (i.e., SCForgeMainFrame)
local function createRune(frame, parent)
	frame.rune = parent:CreateTexture(nil, "OVERLAY", nil, 7)

	local function setRuneTex(texInfo)
		if texInfo.atlas then
			frame.rune:SetAtlas(texInfo.atlas)
		else
			frame.rune:SetTexture(texInfo.tex)
		end
		if texInfo.desat then
			frame.rune:SetDesaturated(true)
			frame.rune:SetVertexColor(0.9,0.9,0.9)
		else
			frame.rune:SetDesaturated(false)
			frame.rune:SetVertexColor(1,1,1)
		end
		frame.rune:SetPoint("CENTER", frame)
		frame.rune:SetSize(texInfo.x or 28, texInfo.y or 28)
		frame.rune:SetBlendMode(texInfo.blend or "ADD")
		frame.rune:SetAlpha(texInfo.alpha or 1)
	end

	setRuneTex(runeIconOverlay)
end

---@param frame frame frame to assign the table accessor (i.e., SCForgeMainFrame.portrait.icon)
---@param parent frame the actual parent the texture is created on (i.e., SCForgeMainFrame)
local function initPortrait(frame, parent)
	frame:SetTexture(ASSETS_PATH .. "/CircularBG")
	frame:SetTexCoord(0.25,1-0.25,0,1)
	frame.mask = parent:CreateMaskTexture()
	frame.mask:SetAllPoints(frame)
	frame.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	frame:AddMaskTexture(frame.mask)
end

---@param frame frame frame reference to set the portrait data on - this will likely be a texture unit, so you need a real parent to use also
---@param parent frame the parent frame since the frame frame is likely a texture
local function createGemPortraitOnFrame(frame, parent)
	if not runeIconOverlay then
		initRuneIcon()
	end

	initPortrait(frame, parent)

	createIcon(frame, parent)

	createRune(frame, parent)

	createModel(frame, parent)
end

local function init()
	local frameToUse = SCForgeMainFrame.portrait
	local parent = SCForgeMainFrame

	createGemPortraitOnFrame(frameToUse, parent)
end

---@class UI_Portrait
ns.UI.Portrait = {
	init = init,
	createGemPortraitOnFrame = createGemPortraitOnFrame,
}
