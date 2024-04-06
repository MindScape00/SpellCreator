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

---@param text string string to parse into csv arguments, returned as an array of args.
---@return string[]|table
local null = {}
local function getCSVArgsFromString(text)
	local _csvTable = {}
	if not text then return _csvTable end
	text = text:gsub(', "', ',"') -- replace , " with ,"
	text = text:gsub('" ,', '",') -- replace " , with ",
	text = text:gsub(",,", ",nil,") -- replace blanks with a nil, to switch to a true nil when adding to the table later
	if not text then return _csvTable end

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
			if arg == "nil" then arg = null end
			tinsert(_csvTable, arg)
		end
	end
	if buf then ns.Logging.eprint("Error Parsing CSV: Missing matching end quote for " .. buf .. "\rCheck your ArcSpell!") end

	-- convert nulls back to nils
	local trueLength = #_csvTable
	for k,v in ipairs(_csvTable) do
		if v == null then
			_csvTable[k] = nil
		end
	end

	return _csvTable, trueLength
end

local function loadStringToTable(text)
	local t = assert(loadstring("return {" .. text .. "}"))()
	return unpack(t)
end

local parseStringToArgs = getCSVArgsFromString

---------------------------------------------------------
--- Link Helpers
---------------------------------------------------------

local function getSpellInfoFromHyperlink(link)
	local strippedSpellLink, spellID = link:match("|Hspell:((%d+).-)|h");
	if spellID then
		return tonumber(spellID), strippedSpellLink;
	end
end

local function getItemInfoFromHyperlink(link)
	local strippedItemLink, itemID = link:match("|Hitem:((%d+).-)|h");
	if itemID then
		return tonumber(itemID), strippedItemLink;
	end
end

local ITEM_LINK_FORMATS = {
	--item = { format = "|cff......|Hitem:((%d+).-)|h|r", replacement = "%2", handler = getItemInfoFromHyperlink },
	--spell = { format = "|cff......|Hspell:((%d+).-)|h|r", replacement = "%2", handler = getSpellInfoFromHyperlink },
	other = { format = "|cff......|H%w+:((%d+).-)|h|r", replacement = "%2", handler = getSpellInfoFromHyperlink },
}
local ITEM_LINK_FORMATS_TUPLE = {}
for k, v in pairs(ITEM_LINK_FORMATS) do
	local tuple = CopyTable(v)
	tuple.type = k
	tinsert(ITEM_LINK_FORMATS_TUPLE, tuple)
end

local function convertLinksToIDs(text)
	for i = 1, #ITEM_LINK_FORMATS_TUPLE do
		text = text:gsub(ITEM_LINK_FORMATS_TUPLE[i].format, ITEM_LINK_FORMATS_TUPLE[i].replacement)
	end
	return text
end

local function convertSpellIDsToLinks(text)
	local finalText = gsub(text, "%d+", function(id)
		id = tonumber(id)
		local link = GetSpellLink(id)
		return link and link or id
	end)
	return finalText
end

local function convertItemIDsToLinks(text)
	local finalText = gsub(text, "%d+", function(id)
		id = tonumber(id)
		local _id, link = GetItemInfo(id)
		return link and link or id
	end)
	return finalText
end

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

local function getDiffInTimeTable(t1, t2)
	local timeDiff = time(t2) - time(t1)
	local isPast = (timeDiff < 0)
	timeDiff = math.abs(timeDiff)

	local days = floor(timeDiff / 86400); if isPast then days = 0 - days end
	local hours = floor(mod(timeDiff, 86400) / 3600); if isPast then hours = 0 - hours end
	local minutes = floor(mod(timeDiff, 3600) / 60); if isPast then minutes = 0 - minutes end

	if isPast then timeDiff = 0 - timeDiff end -- convert back to negative

	return timeDiff, { days = days, hours = hours, minutes = minutes }
end

local function getDiffInTimeHM(h1, m1, h2, m2)
	local t1, t2 = date("*t"), date("*t")
	t1.hour = h1
	t1.min = m1
	t1.sec = 0
	t2.hour = h2
	t2.min = m2
	t2.sec = 0

	return getDiffInTimeTable(t1, t2)
end

---Checks if a given time is within X minutes, >, or < current Game Time.
---@param time string|osdateparam The time to test against game time
---@param mod? number|string The number of minutes on either side to test, or ">" or "<" to check respectively. If not given, checks if time is exactly
---@return boolean
local function getNormalizedGameTimeDiff(time, mod)
	if not time then return false end
	local testH, testM = 0, 0

	-- convert time
	if type(time) == "string" then
		testH, testM = strsplit(":", time, 2)
	elseif type(time) == "table" then
		testH = time.hour and time.hour or 0 --[[@as integer]]
		testM = time.min and time.min or 0 --[[@as integer]]
	end

	-- convert mod if able
	if not mod then mod = 0 end
	if tonumber(mod) then mod = tonumber(mod) --[[@as number]] end

	local minInDay = 1440
	local curH, curM = GetGameTime()
	local curT = curM + (curH * 60) -- time in minutes after midnight
	testH = tonumber(testH) --[[@as integer]]
	testM = tonumber(testM) --[[@as integer]]
	if not testH or not testM then return false end
	local testT = testM + (testH * 60)

	if type(mod) == "number" then
		local timeMin = (testT - mod % minInDay)
		local timeMax = (testT + mod % minInDay)
		if curT > timeMin and curT < timeMax then -- time is greater than min, less than max
			return true
		else
			return false
		end
	elseif type(mod) == "string" then
		if mod == ">" then -- check time greater
			return curT >= testT
		elseif mod == "<" then -- check time less
			return curT <= testT
		end
	end
	return false -- you made it to the end, that's a fail!
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
	caseInsensitiveCompare = caseInsensitiveCompare,
	firstToUpper = firstToUpper,
	wordToProperCase = wordToProperCase,
	sanitizeNewlinesToCSV = sanitizeNewlinesToCSV,
	--getCSVArgsFromString = getCSVArgsFromString,
	parseStringToArgs = parseStringToArgs,

	getSpellInfoFromHyperlink = getSpellInfoFromHyperlink,
	getItemInfoFromHyperlink = getItemInfoFromHyperlink,
	convertLinksToIDs = convertLinksToIDs,
	convertItemIDsToLinks = convertItemIDsToLinks,
	convertSpellIDsToLinks = convertSpellIDsToLinks,

	keys = keys,
	values = values,
	entries = entries,
	filter = filter,
	indexOf = indexOf,

	getDistanceBetweenPoints = getDistanceBetweenPoints,
	roundToNthDecimal = roundToNthDecimal,
	isTodayAfterOrEqualDate = isTodayAfterOrEqualDate,
	getDiffInTimeHM = getDiffInTimeHM,
	getDiffInTimeTable = getDiffInTimeTable,
	getNormalizedGameTimeDiff = getNormalizedGameTimeDiff,

	getRandomArg = getRandomArg,
	getRandomWeightedArg = getRandomWeightedArg,
}
