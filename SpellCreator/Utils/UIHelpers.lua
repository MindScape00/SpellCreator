---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

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

---------------
--#region Texture & Button Helpers
---------------

local function setTextureOffset(frameTexture, x, y)
	frameTexture:SetVertexOffset(UPPER_LEFT_VERTEX, x, y)
	frameTexture:SetVertexOffset(UPPER_RIGHT_VERTEX, x, y)
	frameTexture:SetVertexOffset(LOWER_LEFT_VERTEX, x, y)
	frameTexture:SetVertexOffset(LOWER_RIGHT_VERTEX, x, y)
end

local function setHighlightToOffsetWithPushed(frame, x, y)
	if not x then x = 1 end
	if not y then y = -1 end
	local highlight = frame:GetHighlightTexture()
	frame:HookScript("OnMouseDown", function(self) setTextureOffset(highlight, x, y) end)
	frame:HookScript("OnMouseUp", function(self) setTextureOffset(highlight, 0, 0) end)
end

---@param button BUTTON|Button
---@param path string
---@param useAtlas? boolean
local function setupCoherentButtonTextures(button, path, useAtlas)
	if useAtlas then
		button:SetNormalAtlas(path)
		button:SetHighlightAtlas(path, "ADD")
		button:SetDisabledAtlas(path)
		button:SetPushedAtlas(path)
	else
		button:SetNormalTexture(path)
		button:SetHighlightTexture(path, "ADD")
		button:SetDisabledTexture(path)
		button:SetPushedTexture(path)
	end
	button.NormalTexture = button:GetNormalTexture()
	button.HighlightTexture = button:GetHighlightTexture()
	button.DisabledTexture = button:GetDisabledTexture()
	button.PushedTexture = button:GetPushedTexture()

	button.HighlightTexture:SetAlpha(0.33)

	setHighlightToOffsetWithPushed(button)
	button.DisabledTexture:SetDesaturated(true)
	button.DisabledTexture:SetVertexColor(.6, .6, .6)
	setTextureOffset(button.PushedTexture, 1, -1)
end

-- "|TfilePath:height:width:xOffset:yOffset:texWidth:texHeight:lTxl:rTxl:tTxl:bTxl:r:g:b|t "
---@param filePath string
---@param fileWidth integer
---@param fileHeight integer
---@param width integer
---@param height integer
---@param left number
---@param right number
---@param top number
---@param bottom number
---@param xOffset integer
---@param yOffset integer
---@param rVertexColor integer
---@param gVertexColor integer
---@param bVertexColor integer
---@return string
local function CreateTextureMarkupWithColor(filePath, fileWidth, fileHeight, width, height, left, right, top, bottom, xOffset, yOffset, rVertexColor, gVertexColor, bVertexColor)
	return ("|T%s:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d|t"):format(
		filePath
		, height
		, width
		, xOffset or 0
		, yOffset or 0
		, fileWidth
		, fileHeight
		, left * fileWidth
		, right * fileWidth
		, top * fileHeight
		, bottom * fileHeight
		, rVertexColor
		, gVertexColor
		, bVertexColor
	);
end

local function CreateSimpleTextureMarkup(filePath, height, width)
	local stringToUse = "|T%s:%d|t"
	if not height then
		height = 0
	end

	if width then
		stringToUse = "|T%s:%d:%d|t"
	end

	return stringToUse:format(filePath, height, width)
end

local function getAddonAssetFilePath(fileName)
	return Constants.ASSETS_PATH .. "/" .. fileName
end

---@class Utils_UIHelpers
ns.Utils.UIHelpers = {
	getCursorDistanceFromFrame = getCursorDistanceFromFrame,
	CustomUIFrameFadeOut = CustomUIFrameFadeOut,

	setTextureOffset = setTextureOffset,
	setHighlightToOffsetWithPushed = setHighlightToOffsetWithPushed,
	setupCoherentButtonTextures = setupCoherentButtonTextures,
	
	CreateTextureMarkupWithColor = CreateTextureMarkupWithColor,
	CreateSimpleTextureMarkup = CreateSimpleTextureMarkup,

	getAddonAssetFilePath = getAddonAssetFilePath,
}
