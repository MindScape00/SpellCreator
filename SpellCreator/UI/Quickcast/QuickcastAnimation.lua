---@class ns
local ns = select(2, ...)

---@param frame frame
---@return number
local function getCursorDistanceFromFrame(frame)
	local uiScale, x1, y1 = UIParent:GetEffectiveScale(), GetCursorPosition()
	local x1, y1 = x1 / uiScale, y1 / uiScale
	local x2, y2 = frame:GetCenter()
	local dx = x1 - x2
	local dy = y1 - y2
	return math.sqrt(dx * dx + dy * dy) -- x * x is faster than x^2
end

---@param frame frame
---@param timeToFade integer
---@param startAlpha integer
---@param endAlpha integer
local function CustomUIFrameFadeOut(frame, timeToFade, startAlpha, endAlpha)
	-- TODO : Move this to UIHelpers or something like that, since this is more generic and not really animation related
	local fadeInfo = {}
	fadeInfo.mode = "OUT"
	fadeInfo.timeToFade = timeToFade
	fadeInfo.startAlpha = startAlpha
	fadeInfo.endAlpha = endAlpha
	fadeInfo.finishedArg1 = frame

	if UIFrameIsFading(frame) then UIFrameFadeRemoveFrame(frame) end

	if endAlpha == 0 then
		fadeInfo.finishedFunc = function(f)
			if f:GetAlpha() == 0 then
				f:Hide()
			end
		end
	end

	UIFrameFade(frame, fadeInfo)
end

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
