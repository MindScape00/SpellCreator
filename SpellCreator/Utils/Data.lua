---@class ns
local ns = select(2, ...)

local tInsert = tinsert

---------------------------------------------------------
--- General
---------------------------------------------------------

local function isNotDefined(s)
	return s == nil or s == '';
end

local function getRandomArg(...)
	return (select(random(select("#", ...)), ...));
end

---@class WeightedArgItem
---@field [1] integer weight
---@field [2] string|table|any return item

---@class WeightedArgPool
---@type WeightedArgItem[]

---Get a random arg based on weighting
---@param pool WeightedArgPool
---@return WeightedArgItem<2>?
local function getRandomWeightedArg(pool)
	local poolsize = 0
	for i = 1, #pool do
		local v = pool[i]
		poolsize = poolsize + v[1]
	end
	local selection = math.random(1, poolsize)
	for i = 1, #pool do
		local v = pool[i]
		selection = selection - v[1]
		if (selection <= 0) then
			return v[2]
		end
	end
end

--[[ Example Pool
 pool = {
	{20, "foo"},
	{20, "bar"},
	{60, "baz"}
 }
--]]
---------------------------------------------------------
--- String Helpers
---------------------------------------------------------

local function toBoolean(str) return strlower(str) == "true" end

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

local function caseInsensitiveCompare(a, b)
	if type(a) == "number" and type(b) == "number" then
		return a < b
	else
		return string.lower(a) < string.lower(b)
	end
end

local _csvTable = {}
local function getCSVArgsFromString(text)
	wipe(_csvTable)
	local spat, epat, buf, quoted = [=[^(['"])]=], [=[(['"])$]=]
	for str in text:gmatch("[^,]+") do
		local squoted = str:match(spat)
		local equoted = str:match(epat)
		local escaped = str:match([=[(\*)['"]$]=])
		if squoted and not quoted and not equoted then
			buf, quoted = str, squoted
		elseif buf and equoted == quoted and #escaped % 2 == 0 then
			str, buf, quoted = buf .. ',' .. str, nil, nil
		elseif buf then
			buf = buf .. ',' .. str
		end
		if not buf then
			local arg = strtrim((str:gsub(spat, ""):gsub(epat, "")))
			tinsert(_csvTable, arg)
		end
	end
	if buf then ns.Logging.eprint("Error Parsing CSV: Missing matching end quote for " .. buf .. "\rCheck your ArcSpell!") end
	return _csvTable
end

local function loadStringToTable(text)
	local t = assert(loadstring("return {" .. text .. "}"))()
	return unpack(t)
end

local parseStringToArgs = getCSVArgsFromString

---------------------------------------------------------
--- Table Helpers
---------------------------------------------------------

---@generic T
---@param t T
---@return T
local function orderedPairs(t, f) -- get keys & sort them - default sort is alphabetically, case insensitive using our custom comparartor
	if not f then f = caseInsensitiveCompare end
	local keys = {}
	for k in pairs(t) do keys[#keys + 1] = k end
	table.sort(keys, f)
	local i = 0          -- iterator variable
	local iter = function() -- iterator function
		i = i + 1
		if keys[i] == nil then
			return nil
		else
			return keys[i], t[keys[i]]
		end
	end
	return iter
end

---@generic K, V
---@param tbl table<K, V>
---@return K[]
local function keys(tbl)
	local keysArray = {};
	for key in pairs(tbl) do
		tInsert(keysArray, key);
	end
	return keysArray;
end

---@generic K, V
---@param tbl table<K, V>
---@return V[]
local function values(tbl)
	local valuesArray = {};
	for key, value in pairs(tbl) do
		tInsert(valuesArray, value);
	end
	return valuesArray;
end

---@generic K, V
---@param tbl table<K, V>
---@return { key: K, value: V }[]
local function entries(tbl)
	local pairsArray = {};
	for key, value in pairs(tbl) do
		tInsert(pairsArray, { key = key, value = value, });
	end
	return pairsArray;
end

---@generic K, V
---@param tbl table<K, V>
---@param predicate fun(value: V): boolean
---@return table<K, V>
local function filter(tbl, predicate)
	local out = {}

	for k, v in pairs(tbl) do
		if predicate(v) then
			out[k] = v
		end
	end

	return out
end

---@generic V
---@param array V[]
---@param value V
---@return integer
local function indexOf(array, value)
	for i, v in ipairs(array) do
		if v == value then
			return i
		end
	end
	return -1
end

---------------------------------------------------------
--- Number Helpers
---------------------------------------------------------

---Get the distance between two numbers, or between two x,y points.
---@param x1 number
---@param y1 number
---@param x2? number
---@param y2? number
---@return number
local function getDistanceBetweenPoints(x1, y1, x2, y2)
	if x2 and y2 then
		local dx = x1 - x2
		local dy = y1 - y2
		return math.sqrt(dx * dx + dy * dy) -- x * x is faster than x^2
	else
		local d = math.abs(x1 - y1)
		return d
	end
end

---@param num number the number to round
---@param n integer number of decimal places
---@return number number the rounded number
local function roundToNthDecimal(num, n)
	local mult = 10 ^ (n or 0)
	return math.floor(num * mult + 0.5) / mult
end

---@param date {year: integer, month: integer, day: integer, hour: integer?, min: integer?, sec: integer?}
local function isTodayAfterOrEqualDate(date)
	local rightNow = time()
	local whatDate = time(date)
	if rightNow > whatDate then return true else return false end
end

---@class Utils_Data
ns.Utils.Data = {
	isNotDefined = isNotDefined,
	toBoolean = toBoolean,
	orderedPairs = orderedPairs,
	firstToUpper = firstToUpper,
	wordToProperCase = wordToProperCase,
	sanitizeNewlinesToCSV = sanitizeNewlinesToCSV,
	--getCSVArgsFromString = getCSVArgsFromString,
	parseStringToArgs = parseStringToArgs,

	keys = keys,
	values = values,
	entries = entries,
	filter = filter,
	indexOf = indexOf,

	getDistanceBetweenPoints = getDistanceBetweenPoints,
	roundToNthDecimal = roundToNthDecimal,
	isTodayAfterOrEqualDate = isTodayAfterOrEqualDate,

	getRandomArg = getRandomArg,
	getRandomWeightedArg = getRandomWeightedArg,
}
