---@class ns
local ns = select(2, ...)

local function isNotDefined(s)
	return s == nil or s == '';
end

local function toboolean(str) return strlower(str) == "true" end

---@class Utils_Data
ns.Utils.Data = {
    isNotDefined = isNotDefined,
    toboolean = toboolean,
}
