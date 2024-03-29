---@class ns
local ns = select(2, ...)

local addonName = ...
local addonNameSearch = string.gsub(addonName, "%p", "%%%1")

local ADDON_COLOR, ADDON_TITLE = ns.Constants.ADDON_COLOR, ns.Constants.ADDON_TITLE

local prefix = ADDON_COLOR .. ADDON_TITLE

local function cprint(text)
	text = text:gsub("|r", "|r" .. ADDON_COLOR)
	print(prefix .. ": " .. (text and text or "ERROR") .. "|r")
end

local function dprint(force, text, ...)
	if text then
		if force == true or SpellCreatorMasterTable.Options["debug"] then
			local rest = ... or ""
			local line = strmatch(debugstack(2), ":(%d+):")
			local file = strmatch(debugstack(2), "AddOns\\" .. addonNameSearch .. "\\(.-%.lua)") or ""
			if line then
				print(prefix .. " DEBUG " .. file .. ":" .. line .. " | " .. text, rest, " |r")
			else
				print(prefix .. " DEBUG: " .. text, rest, " |r")
				print(debugstack(2))
			end
		end
	elseif SpellCreatorMasterTable.Options["debug"] then
		local line = strmatch(debugstack(2), ":(%d+):")
		local file = strmatch(debugstack(2), "AddOns\\" .. addonNameSearch .. "\\(.-%.lua)") or ""
		if line then
			print(prefix .. " DEBUG " .. file .. ":" .. line .. " | " .. force .. " |r")
		else
			print(prefix .. " DEBUG: " .. force .. " |r")
			print(debugstack(2))
		end
	end
end

local function eprint(text, rest)
	local line = strmatch(debugstack(2), ":(%d+):")
	local file = strmatch(debugstack(2), "AddOns\\" .. addonNameSearch .. "\\(.-)%.lua") or ""
	if line then
		print(prefix .. " Error @ " .. file .. ":" .. line .. " | " .. text .. "" .. (rest and " | " .. rest or "") .. " |r")
	else
		print(prefix .. " @ ERROR: " .. text .. " | " .. rest .. " |r")
		print(debugstack(2))
	end
end

local function raidWarning(text, r, g, b)
	RaidNotice_AddMessage(RaidWarningFrame, CreateColor(r, g, b, 1):WrapTextInColorCode(text), ChatTypeInfo["RAID_WARNING"])
end

local function uiErrorMessage(text, r, g, b, voiceID, soundKitID)
	UIErrorsFrame:AddMessage(text, r, g, b, 1)
	if voiceID then
		PlayVocalErrorSoundID(voiceID);
	elseif soundKitID then
		PlaySound(soundKitID);
	end
end

ns.Logging = {
	cprint = cprint,
	dprint = dprint,
	eprint = eprint,
	raidWarning = raidWarning,
	uiErrorMessage = uiErrorMessage,
}
