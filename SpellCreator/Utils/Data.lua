---@class ns
local ns = select(2, ...)

local function isNotDefined(s)
	return s == nil or s == '';
end

local function toboolean(str) return strlower(str) == "true" end

---@generic T
---@param t T
---@return T
local function orderedPairs (t, f) -- get keys & sort them - default sort is alphabetically
	local keys = {}
	for k in pairs(t) do keys[#keys+1] = k end
	table.sort(keys, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if keys[i] == nil then return nil
		else return keys[i], t[keys[i]]
		end
	end
	return iter
end

---@class Utils_Data
ns.Utils.Data = {
    isNotDefined = isNotDefined,
    toboolean = toboolean,
	orderedPairs = orderedPairs,
}
