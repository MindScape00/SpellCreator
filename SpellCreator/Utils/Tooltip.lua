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

---@param title string | fun(self): string
---@param lines string[] | string | fun(self): (string[] | string)
local function setTooltip(self, title, lines)
	local _title = title
	local _lines = lines


	if type(_title) == "function" then
		_title = _title(self)
	end

	setTitle(_title)


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

	GameTooltip:Show()
end

---@param title string | fun(self): string
---@param lines string[] | string | fun(self): (string[] | string)
local function onEnter(title, lines)
	return function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")

		timer = C_Timer.NewTimer(0.7, function()
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
---@param options? { updateOnClick?: boolean }
local function set(frame, title, lines, options)
	frame:SetScript("OnEnter", onEnter(title, lines))

	if options and options.updateOnClick then
		frame:HookScript("OnClick", function(self)
			setTooltip(self, title, lines)
		end)
	end

	frame:SetScript("OnLeave", onLeave)
end

---@class Utils_Tooltip
ns.Utils.Tooltip = {
	set = set,
}
