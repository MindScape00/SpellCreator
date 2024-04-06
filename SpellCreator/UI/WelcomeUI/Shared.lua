---@class ns
local ns = select(2, ...)
local addonName = ...

local width = 700
local height = 620
local insetWidth = width - 271

-- this autoOrder system doesn't work right and I am too lazy to fix it
local function newAutoOrder()
	local autoOrderObject = {
		orderGroup = 0,
		groups = {
			[1] = 0
		},
	}

	function autoOrderObject:autoOrder(isGroup, directGroup)
		local orderGroup = self.orderGroup

		if isGroup then
			if type(isGroup) == "number" then
				if directGroup then
					orderGroup = isGroup
				else
					orderGroup = orderGroup + isGroup
				end
			else
				orderGroup = orderGroup + 1
			end

			self.groups[orderGroup] = 0
		else
			if self.orderGroup == 0 then self.orderGroup = 1 end
		end

		if not self.groups[orderGroup] then self.groups[orderGroup] = 0 end
		self.groups[orderGroup] = self.groups[orderGroup] + 1
		return self.groups[orderGroup]
	end

	return (function(isGroup, directGroup) return autoOrderObject:autoOrder(isGroup, directGroup) end), autoOrderObject
end

local width_multiplier = 170
local function getFullWidthPercentAdjusted(full, percent)
	local fullWidthScale = full / width_multiplier
	return (fullWidthScale * percent)
end

local function getFullWidthPixelOffset(full, adjustment)
	local fullWidthScaleOffset = full + adjustment
	local offsetScale = fullWidthScaleOffset / width_multiplier
	return offsetScale
end

local function getExactPixelWidth(actual)
	return actual / width_multiplier
end

---@class UI_WelcomeUI_Shared
ns.UI.WelcomeUI.Shared = {
	newAutoOrder = newAutoOrder,

	getFullWidthPercentAdjusted = getFullWidthPercentAdjusted,
	getFullWidthPixelOffset = getFullWidthPixelOffset,
	getExactPixelWidth = getExactPixelWidth,

	width = width,
	height = height,
	insetWidth = insetWidth,
}
