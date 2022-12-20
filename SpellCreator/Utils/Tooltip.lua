---@class ns
local ns = select(2, ...)

local ADDON_COLORS = ns.Constants.ADDON_COLORS

local timer

---@param title string
local function setTitle(title)
	GameTooltip:SetText(title, nil, nil, nil, nil, true)
end

---@param line string
local function addLine(line)
	if line:match(strchar(31)) then
		--GameTooltip:AddLine(line, 1, 1, 1, true)
		local line1, line2 = strsplit(strchar(31), line, 2)
		GameTooltip:AddDoubleLine(line1, line2, 1, 1, 1, 1, 1, 1)
	else
		GameTooltip:AddLine(line, 1, 1, 1, true)
	end
end

---@alias TooltipStyle "contrast" | "example" | "norevert" | "revert" | "lpurple"

---@class TooltipStyleData
---@field color string
---@field tag string? text that shows up before the given text
---@field tagColor string?
---@field texture string? path
---@field atlas string? atlasName
---@field iconH integer?
---@field iconW integer?

---@type { [TooltipStyle]: TooltipStyleData }
local tooltipTextStyles = {
	contrast = {
		color = ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColor(),
	},
	example = {
		color = ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColor(),
		tag = "Example: ",
	},
	norevert = {
		color = ADDON_COLORS.TOOLTIP_NOREVERT:GenerateHexColor(),
	},
	revert = {
		color = ADDON_COLORS.GAME_GOLD:GenerateHexColor(),
		tag = "Revert: ",
		tagColor = ADDON_COLORS.TOOLTIP_REVERT:GenerateHexColor(),
		atlas = "transmog-icon-revert",
		iconH = 16,
	},
	lpurple = {
		color = ADDON_COLORS.LIGHT_PURPLE:GenerateHexColor(),
	}
}

---@param style TooltipStyle
---@param text string
local function genTooltipText(style, text)
	local styledata = tooltipTextStyles[style]

	local color = styledata.color and "|c" .. styledata.color or nil
	local iconH, iconW = styledata.iconH and styledata.iconH or 0,
		(styledata.iconW and styledata.iconW) or (styledata.iconH and styledata.iconH) or 0

	local icon
	if styledata.texture then
		icon = "|T" .. styledata.texture .. ":" .. iconH .. ":" .. iconW .. "|t "
	elseif styledata.atlas then
		icon = "|A:" .. styledata.atlas .. ":" .. iconH .. ":" .. iconW .. "|a "
	end

	local tag = styledata.tag
	if tag and styledata.tagColor then
		tag = WrapTextInColorCode(tag, styledata.tagColor)
	end

	if styledata.color then
		text = text:gsub("|r", "|r" .. color) -- until SL makes it so colors pop in order instead of all, this will always add our color back, including after the tag!
	end

	text = (icon and icon or "") .. (color and color or "") .. (tag and tag or "") .. text .. (color and "|r" or "")

	return text
end

---@param text string
local function genContrastText(text)
	if type(text) == "table" then
		local finalText
		for i = 1, #text do
			local string = text[i]
			if finalText then
				finalText = finalText .. ", " .. genTooltipText("contrast", string)
			else
				finalText = genTooltipText("contrast", string)
			end
		end
		return finalText
	else
		return genTooltipText("contrast", text)
	end
end

---@param title string | fun(self): string
---@param lines? string[] | string | fun(self): (string[] | string)
local function setTooltip(self, title, lines)
	local _title = title
	local _lines = lines


	if type(_title) == "function" then
		_title = _title(self)
	end

	if not _title then return end -- nil checking incase we are passed a nil tooltip title
	setTitle(_title)

	if _lines then
		if type(_lines) == "function" then
			_lines = _lines(self)
		end

		if type(_lines) == "string" then
			addLine(_lines)
		else
			for _, line in ipairs(_lines) do
				addLine(line)
			end
		end
	end

	GameTooltip:Show()
end

---@param title string | fun(self): string
---@param lines? string[] | string | fun(self): (string[] | string)
local function onEnter(title, lines, delay)
	if not delay then delay = 0.7 end
	return function(self)
		if not SpellCreatorMasterTable.Options["showTooltips"] and not self.tooltipForced then return end

		if timer then timer:Cancel() end

		GameTooltip:SetOwner(self, self.tooltipAnchor or "ANCHOR_LEFT")

		timer = C_Timer.NewTimer(delay, function()
			setTooltip(self, title, lines)
		end)
	end
end

local function onLeave(self)
	if not SpellCreatorMasterTable.Options["showTooltips"] and not self.tooltipForced then return end
	GameTooltip_Hide()
	timer:Cancel()
end

---@generic F
---@param frame F | Frame | Button
---@param title string | fun(self: F): string | nil
---@param lines? string[] | string | fun(self: F): (string[] | string)
---@param options? { updateOnClick?: boolean, delay?: integer, forced?: boolean, anchor?: string}
local function set(frame, title, lines, options)
	frame:HookScript("OnEnter", onEnter(title, lines, options and options.delay or nil))

	if options then
		if options.updateOnClick then
			frame:HookScript("OnClick", function(self)
				setTooltip(self, title, lines)
			end)
		end
		if options.forced then
			frame.tooltipForced = true
		end
		if options.anchor then
			frame.tooltipAnchor = options.anchor
		end
	end

	frame:HookScript("OnLeave", onLeave)
end

---@class Utils_Tooltip
ns.Utils.Tooltip = {
	set = set,
	genTooltipText = genTooltipText,
	genContrastText = genContrastText,
}
