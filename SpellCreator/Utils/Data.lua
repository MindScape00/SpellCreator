---@class ns
local ns = select(2, ...)

local function isNotDefined(s)
	return s == nil or s == '';
end

local function toboolean(str) return strlower(str) == "true" end

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

local function wordToProperCase(word)
	return firstToUpper(string.lower(word))
end

---@param input string
---@return string
local function sanitizeNewlinesToCSV(input)
	local output = strtrim(input) -- removes leading/trailing new lines (& spaces) since we don't want blanks
	output = output:gsub("\n", ",")
	return output
end

--[[ -- This was my first thought of cleaning up the table itself but realized after I can just sanitize the input before it gets tablized.
local function sanitizeInputTable(input)
	if type(input) ~= "table" then return input end
	for k,v in pairs(input) do
		if v:find("\n") then
			tremove(input, k)
			local _table = { strsplit("\n", v) }
			for i = 1, #_table do
				tinsert(input, k+i-1, _table[i])
			end
		end
	end
	return input
end
--]]

local function caseInsensitiveCompare(a, b)
	return string.lower(a) < string.lower(b) -- string:lower() errors if the var is not string type. string.lower does not and avoids needing to do checks to convert type.
end

---@generic T
---@param t T
---@return T
local function orderedPairs (t, f) -- get keys & sort them - default sort is alphabetically, case insensitive using our custom comparartor
	if not f then f = caseInsensitiveCompare end
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
	firstToUpper = firstToUpper,
	wordToProperCase = wordToProperCase,
	sanitizeNewlinesToCSV = sanitizeNewlinesToCSV,
}
