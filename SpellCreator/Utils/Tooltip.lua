---@class ns
local ns = select(2, ...)

local timer

---@param title string
local function setTitle(title)
	GameTooltip:SetText(title, nil, nil, nil, nil, true)
end


---@param line string
local function addLine(line)
	GameTooltip:AddLine(line, 1, 1, 1, true)
end


local tooltipTextStyles = {
--	["styleName"] = {color = "FFFFFF", tag = "text that shows up before the given text", tagColor = "AAAAAA", atlas|texture = "path or atlasName", iconH = height, iconW = width}
	["example"] = {color = "85FF85", tag = "Example: "},
	["revert"] = {color = "FFD100", tag="Revert: ", tagColor = "FFA600", atlas = "transmog-icon-revert", iconH = 16},
	["norevert"] = {color = "AAAAAA"},
}

---@param style string
---@param text string
local function genTooltipText(style, text)
	local styledata = tooltipTextStyles[style]
	if styledata then
		local color = styledata.color and "|cff"..styledata.color or nil
		local iconH, iconW = styledata.iconH and styledata.iconH or 0, (styledata.iconW and styledata.iconW) or (styledata.iconH and styledata.iconH) or 0
		local icon
		if styledata.texture then
			icon = "|T"..styledata.texture..":"..iconH..":"..iconW.."|t "
		elseif styledata.atlas then
			icon = "|A:"..styledata.atlas..":"..iconH..":"..iconW.."|a "
		end
		--local tag = icon and " "..styledata.tag or styledata.tag
		local tag = styledata.tag
		if styledata.tagColor then
			tag = WrapTextInColorCode(tag, "ff"..styledata.tagColor) .. (color and color or "")
		end

		text = (icon and icon or "") .. (color and color or "") .. (tag and tag or "") .. text .. (color and "|r" or "")
	end
	return text
end

---@param title string | fun(self): string
---@param lines string[] | string | fun(self): (string[] | string)
local function setTooltip(self, title, lines)
	local _title = title
	local _lines = lines


	if type(_title) == "function" then
		_title = _title(self)
	end

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
---@param lines string[] | string | fun(self): (string[] | string)
local function onEnter(title, lines, delay)
	if not delay then delay = 0.7 end
	return function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")

		timer = C_Timer.NewTimer(delay, function()
			setTooltip(self, title, lines)
		end)
	end
end

local function onLeave()
	GameTooltip_Hide()
	timer:Cancel()
end

---@generic F
---@param frame F | Frame | Button
---@param title string | fun(self: F): string
---@param lines string[] | string | fun(self: F): (string[] | string)
---@param options? { updateOnClick?: boolean, delay?: integer }
local function set(frame, title, lines, options)
	frame:HookScript("OnEnter", onEnter(title, lines, options and options.delay or nil))

	if options and options.updateOnClick then
		frame:HookScript("OnClick", function(self)
			setTooltip(self, title, lines)
		end)
	end

	frame:HookScript("OnLeave", onLeave)
end

---@class Utils_Tooltip
ns.Utils.Tooltip = {
	set = set,
	genTooltipText = genTooltipText,
}
