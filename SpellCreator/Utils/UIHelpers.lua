---@class ns
local ns = select(2, ...)

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

---@param button BUTTON
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

---@class Utils_UIHelpers
ns.Utils.UIHelpers = {
	setTextureOffset = setTextureOffset,
	setHighlightToOffsetWithPushed = setHighlightToOffsetWithPushed,
	setupCoherentButtonTextures = setupCoherentButtonTextures,
	CreateTextureMarkupWithColor = CreateTextureMarkupWithColor,
}
