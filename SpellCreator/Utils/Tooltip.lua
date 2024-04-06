---@class ns
local ns = select(2, ...)

local ADDON_COLORS = ns.Constants.ADDON_COLORS

local timer

---@param title string
local function setTitle(title)
	GameTooltip:SetText(title, nil, nil, nil, nil, true)
end

local function clearLines()
	GameTooltip:ClearLines()
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

---Concat the two texts together with a strchar(31) as a delimiter to create a double line.
---@param text1 string
---@param text2 string
---@return string
local function createDoubleLine(text1, text2)
	return text1 .. strchar(31) .. text2
end

---@alias TooltipStyle "contrast" | "example" | "norevert" | "revert" | "lpurple" | "warning"

---@class TooltipStyleData
---@field color string
---@field tag string? text that shows up before the given text
---@field tagColor string?
---@field texture string? path
---@field atlas string? atlasName
---@field iconH integer?
---@field iconW integer?
---@field additionalParsing function? additional parsing function

---@type { [TooltipStyle]: TooltipStyleData }
local tooltipTextStyles = {
	contrast = {
		color = ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColor(),
	},
	example = {
		color = ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColor(),
		tag = "Example: ",
		additionalParsing = function(text)
			if text:find("<.*>") then
				-- convert < > to contrast text
				text = text:gsub("<(.-)>", ns.Utils.Tooltip.genContrastText("%1"))
			end
			return text
		end
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
	},
	warning = {
		tag = "Warning: ",
		color = ADDON_COLORS.TOOLTIP_WARNINGRED:GenerateHexColor(),
	},
}

---@param style TooltipStyle
---@param text string
local function genTooltipText(style, text)
	local styledata = tooltipTextStyles[style]

	if styledata.additionalParsing then
		text = styledata.additionalParsing(text)
	end

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

---@param text string | table
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

	if _title then
		setTitle(_title)
	else
		clearLines()
	end

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

---Call to directly show a tooltip; this is mostly so you can update / redraw a tooltip live if needed.
---@param title string | fun(self): string
---@param lines? string[] | string | fun(self): (string[] | string)
local function rawSetTooltip(self, title, lines)
	GameTooltip:SetOwner(self, self.tooltipAnchor or "ANCHOR_LEFT")
	setTooltip(self, title, lines)
end

---@class TooltipOptions
---@field updateOnClick boolean?
---@field delay (integer | function)?
---@field forced boolean?
---@field anchor string?
---@field predicate function?

---@param title string | fun(self): string
---@param lines? string[] | string | fun(self): (string[] | string)
---@param options? TooltipOptions
local function onEnter(title, lines, options)
	return function(self)
		local delay = options and options.delay or 0.7
		if type(delay) == "function" then delay = delay(self) end
		if not SpellCreatorMasterTable.Options["showTooltips"] and not self.tooltipForced then return end
		if options and options.predicate then
			if not options.predicate(self) then return end
		end

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
	if timer then
		timer:Cancel()
	end
end

---@generic F
---@param frame F | Frame | Button
---@param title string | fun(self: F): string | nil
---@param lines? string[] | string | fun(self: F): (string[] | string)
---@param options? TooltipOptions
local function set(frame, title, lines, options)
	frame:HookScript("OnEnter", onEnter(title, lines, options))

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

---Set a Tooltip on an AceGui Frame since we need to use their custom callbacks instead of hookscripts
---@param frame AceGUIFrame|AceGUIWidget
---@param title string | fun(self: F): string | nil
---@param lines? string[] | string | fun(self: F): (string[] | string)
---@param options? TooltipOptions
local function setAceTT(frame, title, lines, options)
	frame:SetCallback("OnEnter", function(widget)
		onEnter(title, lines, options)(widget.frame)
	end)

	frame:SetCallback("OnLeave", function(widget)
		onLeave(widget.frame)
	end)
end

---@class Utils_Tooltip
ns.Utils.Tooltip = {
	set = set,
	genTooltipText = genTooltipText,
	genContrastText = genContrastText,
	createDoubleLine = createDoubleLine,

	setAceTT = setAceTT,

	rawSetTooltip = rawSetTooltip,
}
