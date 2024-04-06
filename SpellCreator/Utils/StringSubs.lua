---@class ns
local ns = select(2, ...)

local Cmd = ns.Cmd
local runMacroText = Cmd.runMacroText

local TRP_Loaded = IsAddOnLoaded("TotalRP3")
local TRP3_API = TRP3_API

--#region Replace Chat Substitutions (Blizz Style)

local subsBuild = {}
local subsBase = {
	["%%[Nn]"] = function() return UnitName("player") end,
	["%%[Zz]"] = GetRealZoneText,
	["%%[Ss][Zz]"] = function()
		local subZ
		if GetSubZoneText() ~= "" then
			subZ = GetSubZoneText()
		else
			subZ = GetRealZoneText()
		end
		return subZ
	end,

	["%%[Ll][Oo][Cc]"] = function()
		local x, y, z, mapID = C_Epsilon.GetPosition()
		return ("%0.4f, %0.4f, %0.4f, %i"):format(x, y, z, mapID)
	end,

	["%%[Rr][Tt]"] = function()
		local datetime = C_DateAndTime.GetCurrentCalendarTime()
		if datetime == nil then
			return;
		else
			local hours = datetime.hour
			local minutes = datetime.minute
			if hours < 10 then
				hours = "0" .. hours
			end
			if minutes < 10 then
				minutes = "0" .. minutes
			end
			return hours .. ":" .. minutes
		end
	end,

	["%%[Ll][Tt]"] = function()
		local datetime = date("%H:%M")
		if datetime == nil then
			return;
		else
			return datetime
		end
	end,

	--[[
	You can add straight text substitutions
	to this table. See the example below. Remove the -- from the front to use
	it. Note also that it's case sensitive unless you write both upper- and
	lower-case letters inside brackets like the substitutions above.]]

	--["%%tsinfo"] = "TeamSpeak info: Server: host.domain.com, Password: 12345",
}

local subModifiers = {
	["[Ll][Oo][Ww][Ee][Rr]"] = function(text) return string.lower(text) end,
	["[Uu][Pp][Pp][Ee][Rr]"] = function(text) return string.upper(text) end,
	["[Bb]"] = function(text)
		text = tostring(text)
		text = text:gsub("<[Nn][Oo].*>", "")
		return text
	end,
}

for code, func in pairs(subsBase) do
	subsBuild[code] = func
	for modifier, modFunc in pairs(subModifiers) do
		local code = code .. modifier
		if subsBuild[code] then
			error("StringSubs: Conflicting substitutions: " .. code)
		else
			subsBuild[code] = function()
				return modFunc(func())
			end
		end
	end
end

local sexes = {
	("<no %s>"):format("gender"),
	MALE,
	FEMALE
}

local unitInfoUnits = {
	[""] = "player",
	["[Tt]"] = "target",
	["[Ff]"] = "focus",
	["[Mm]"] = "mouseover",
	["[Pp]"] = "pet",
	["[Tt][Tt]"] = "targettarget",
}

local getUnitInfoSuffixResult
local unitInfoSuffixes = {
	[""] = UnitName,

	["[Ll]"] = function(unit)
		local level = UnitLevel(unit)
		return level > 0 and level or level < 0 and "??"
	end,

	["[Cc]"] = UnitClass,

	["[Cc][Ll]"] = UnitClassification,


	["[Gg]"] = function(unit)
		return sexes[UnitSex(unit)]
	end,

	["[Rr]"] = function(unit)
		local race
		if UnitIsPlayer(unit) then
			race = UnitRace(unit)
		else
			race = UnitCreatureType(unit)
		end
		return race or ("<no %s>"):format(RACE:lower())
	end,

	["[Gg][Uu]"] = function(unit)
		local guild
		guild = GetGuildInfo(unit)
		return guild or "<no guild>"
	end,

	--[[
	["[Rr][Mm]"] = function(unit)
		local name, realm
		name, realm = UnitName(unit)
		return realm or GetRealmName()
	end,
	--]]

	["[Hh]"] = function(unit)
		return UnitHealth(unit)
	end,

	["[Hh][Mm]"] = function(unit)
		return UnitHealthMax(unit)
	end,

	["[Hh][Aa]"] = function(unit)
		return UnitHealth(unit) .. "/" .. UnitHealthMax(unit)
	end,

	["[Hh][Pp]"] = function(unit)
		return ("%.0f%%%%"):format(UnitHealth(unit) / UnitHealthMax(unit) * 100)
	end,

	["[Pp][Ww]"] = function(unit)
		local pwType, pwTypeTxt = UnitPowerType(unit)
		local max = UnitPowerMax(unit, pwType)
		if max > 0 then
			return UnitPower(unit, pwType)
		else
			return ("<no %s>"):format(pwTypeTxt:lower())
		end
	end,

	["[Pp][Ww][Mm]"] = function(unit)
		local pwType, pwTypeTxt = UnitPowerType(unit)
		local max = UnitPowerMax(unit, pwType)
		if max > 0 then
			return max
		else
			return ("<no %s>"):format(pwTypeTxt:lower())
		end
	end,

	["[Pp][Ww][Aa]"] = function(unit)
		local pwType, pwTypeTxt = UnitPowerType(unit)
		local max = UnitPowerMax(unit, pwType)
		if max > 0 then
			return UnitPower(unit, pwType) .. "/" .. max
		else
			return ("<no %s>"):format(pwTypeTxt:lower())
		end
	end,

	["[Pp][Ww][Pp]"] = function(unit)
		local pwType, pwTypeTxt = UnitPowerType(unit)
		local max = UnitPowerMax(unit, 0)
		if max > 0 then
			return ("%.0f%%%%"):format(max > 0 and UnitPower(unit, pwType) / max * 100 or 0)
		else
			return ("<no %s>"):format(pwTypeTxt:lower())
		end
	end,

	["[Pp][Ww][Tt]"] = function(unit)
		local pwType, pwTypeTxt = UnitPowerType(unit)
		if pwType == nil then
			return "<no power type>"
		else
			return pwTypeTxt:lower()
		end
	end,


	["[Ii][Cc]"] = function(unit)
		local index = GetRaidTargetIndex(unit)
		return index and "{" .. (_G["RAID_TARGET_" .. index]):lower() .. "}" or
			("<no %s>"):format(EMBLEM_SYMBOL:lower())
	end,

	["[Gg][Nn]"] = function(unit)
		local raidN = UnitInRaid(unit)
		if raidN == nil then
			if unit == "player" then
				return "<not in raid>"
			else
				local name, realm = UnitName(unit)
				if realm == nil then
					return "< " .. name .. " is not in your raid>"
				else
					return "< " .. name .. "-" .. realm .. " is not in your raid>"
				end
			end
		else
			local name, rank, subgroup = GetRaidRosterInfo(raidN)
			return subgroup
		end
	end,

	["[Nn][Tt]"] = function(unit)
		if UnitIsVisible(unit) == nil then
			return ""
		else
			local titleName = UnitPVPName(unit)
			return titleName or ""
		end
	end,

	["[Uu][Tt]"] = function(unit)
		if UnitIsVisible(unit) == nil then
			return ""
		else
			local titleName = UnitPVPName(unit)
			if titleName == nil then
				return ""
			end
			local name = UnitName(unit)
			if name == nil then
				return ""
			end
			if name == titleName then
				return "<no title>"
			end
			local title = string.gsub(titleName, name, "")
			title = string.gsub(title, ",", "")
			if string.sub(title, 1, 1) == " " then
				title = string.sub(title, 2)
			end
			if string.sub(title, string.len(title)) == " " then
				title = string.sub(title, 1, string.len(title) - 1)
			end
			return title
		end
	end,

	["[Rr][Pp][Nn]"] = function(unit) -- TRP3 RP Name (Full)
		if not TRP_Loaded then return end
		return TRP3_API.register.getUnitRPName(unit)
	end,
	["[Rr][Pp][Nn][Ff]"] = function(unit) -- TRP3 RP Name (First)
		if not TRP_Loaded then return end
		return TRP3_API.register.getUnitRPFirstName(unit)
	end,
	["[Rr][Pp][Nn][Ll]"] = function(unit) -- TRP3 RP Name (Last)
		if not TRP_Loaded then return end
		return TRP3_API.register.getUnitRPLastName(unit)
	end,

	["[Rr][Pp][Rr]"] = function(targetType) -- TRP3 RP Race
		if not TRP_Loaded then return end

		local unitID = TRP3_API.utils.str.getUnitID(targetType);

		if unitID == TRP3_API.globals.player_id then
			-- is player self, fallback
			return TRP3_API.profile.getData("player/characteristics").RA or "<no rp race-self>"
		end

		if not TRP3_API.register.isUnitKnown(targetType) then
			-- no profile found, fallback
			return getUnitInfoSuffixResult("[Rr]", targetType) or "<no rp race-unknown>"
		end

		local profile = TRP3_API.register.getUnitIDProfile(unitID)
		return profile.characteristics.RA or "<no rp race>"
	end,

	["[Rr][Pp][Cc]"] = function(targetType) -- TRP3 RP Race
		if not TRP_Loaded then return end
		if not TRP3_API.register.isUnitKnown(targetType) then
			return getUnitInfoSuffixResult("[Cc]", targetType)
		end
		local unitID = TRP3_API.utils.str.getUnitID(targetType);
		local profile = TRP3_API.register.getUnitIDProfile(unitID)
		return profile.characteristics.CL
	end,
}
getUnitInfoSuffixResult = function(suffix, ...)
	if unitInfoSuffixes[suffix] then
		return unitInfoSuffixes[suffix](...)
	end
end

for initial, unit in pairs(unitInfoUnits) do
	local noUnit = ("<no %s>"):format(unit)
	for suffix, func in pairs(unitInfoSuffixes) do
		if initial ~= "" or suffix ~= "" then
			local code = "%%" .. initial .. suffix
			if subsBuild[code] then
				error("StringSubs: Conflicting substitutions: " .. code)
			end
			subsBuild[code] = function()
				return UnitExists(unit) and func(unit) or noUnit
			end

			for modifier, modFunc in pairs(subModifiers) do
				local code = code .. modifier
				if subsBuild[code] then
					error("StringSubs: Conflicting substitutions: " .. code)
				else
					subsBuild[code] = function()
						return UnitExists(unit) and modFunc(func(unit)) or modFunc(noUnit)
					end
				end
			end
		end
	end
end

local substitutions = {}
do
	local i = 1
	for k, v in pairs(subsBuild) do
		substitutions[i] = { code = k, func = v }
		i = i + 1
	end
end

sort(substitutions, function(subs1, subs2)
	return subs2.code:len() < subs1.code:len()
end)

local function replaceSubstitutions(text)
	for i = 1, #substitutions do
		local substitution = substitutions[i]
		local func = substitution.func
		text = text:gsub(substitution.code,
			type(func) == "function" and func() or func)
	end
	return text
end

-- Arc Alias Input Subs

local inputAliases = {
	["@itemID@"] = "@input1@",
	["@itemName@"] = "@input2@",
	["@itemLink@"] = "@input3@",
	["@itemIcon@"] = "@input4@",
	["@target@"] = function() return UnitName("target") end,
	["@player@"] = function() return UnitName("player") end,

	["@var:(.*)@"] = function(var) return tostring(ARC:GET(var)) end,
	["@pvar:(.*)@"] = function(var) return tostring(ARC.PHASE:GET(var)) end,
}
local function replaceArcAliases(string)
	for k, v in pairs(inputAliases) do
		string = string:gsub(k, v)
	end
	return string
end

local function scriptSubstitution(script)
	if script then
		script = script:gsub("(<[Nn][Oo].*>)", "'%1'") -- ensure we string-ify any '<no %s>' error from unit token substitutions

		if not script:match("return") then
			script = "return " .. script
		end
		return runMacroText(script)
	else
		return "<no script given!>"
	end
end
local function replaceScriptInput(text)
	return text:gsub("%%{(.*)}", scriptSubstitution)
end

---Replace Input Placeholder strings (@input1@, etc) with corresponding varargs; returns the new string with substitutions complete
---@param text string
---@param ... any
---@return string text
local function replaceInputPlaceholders(text, ...)
	local inputs = { ... }

	for i = 1, #inputs do
		local input = inputs[i]
		local inputString = ("@input%s@"):format(i)
		text = text:gsub(inputString, input)
	end
	return text
end

---Parse a string to do all three major string sub types
---@param text string
---@param ... any replacements
---@return string text the string with all substitutions complete
local function parseStringForAllSubs(text, ...)
	text = replaceSubstitutions(text)
	text = replaceScriptInput(text)
	text = text:gsub("@.-@", replaceArcAliases)
	text = replaceInputPlaceholders(text, ...)
	return text
end

---@class Utils_StringSubs
ns.Utils.StringSubs = {
	replaceSubstitutions = replaceSubstitutions,
	replaceArcAliases = replaceArcAliases,
	replaceInputPlaceholders = replaceInputPlaceholders,
	replaceScriptInput = replaceScriptInput,

	parseStringForAllSubs = parseStringForAllSubs,
}
