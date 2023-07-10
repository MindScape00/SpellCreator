---@class ns
local ns = select(2, ...)

local UIHelpers = ns.Utils.UIHelpers

local getCursorDistanceFromFrame = UIHelpers.getCursorDistanceFromFrame
local CustomUIFrameFadeOut = UIHelpers.CustomUIFrameFadeOut

---@param button QuickcastButton
local function setButtonActorNormal(button)
	local scene = button.scene
	scene.Actor:SetSpellVisualKit(0)
	scene.Actor:SetModelByFileID(166432)
	scene.Actor:SetSpellVisualKit(0)
	scene.Actor:SetModelByFileID(166432) -- sometimes you have to set it twice to remove it..
	scene.Actor:SetAlpha(1)
	scene.Actor:Hide()
end

---@param button QuickcastButton
local function setButtonActorExplode(button)
	local scene = button.scene
	scene.Actor:SetModelByFileID(166432)
	scene.Actor:SetSpellVisualKit(30627)
	scene.Actor:SetSpellVisualKit(7122)
	scene.Actor:SetAlpha(1)
	scene.Actor:Show()
end

---@param button QuickcastButton
local function animateButtonClick(button)
	setButtonActorExplode(button)

	C_Timer.After(0.5, function()
		setButtonActorNormal(button)
	end)
end

---@class UI_Quickcast_Animation
ns.UI.Quickcast.Animation = {
	getCursorDistanceFromFrame = getCursorDistanceFromFrame,
	CustomUIFrameFadeOut = CustomUIFrameFadeOut,
	animateButtonClick = animateButtonClick,
}
