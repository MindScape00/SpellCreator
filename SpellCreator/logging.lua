local _, ns = ...

local ADDON_COLOR, ADDON_TITLE = ns.constants.ADDON_COLOR, ns.constants.ADDON_TITLE

local prefix = ADDON_COLOR .. ADDON_TITLE

local function cprint(text)
	print(prefix..": "..(text and text or "ERROR").."|r")
end

local function dprint(force, text, ...)
	if text then
		if force == true or SpellCreatorMasterTable.Options["debug"] then
			local rest = ... or ""
			local line = strmatch(debugstack(2),":(%d+):")
			if line then
				print(prefix.." DEBUG "..line..": "..text, rest, " |r")
			else
				print(prefix.." DEBUG: "..text, rest, " |r")
				print(debugstack(2))
			end
		end
	elseif SpellCreatorMasterTable.Options["debug"] then
		local line = strmatch(debugstack(2),":(%d+):")
		if line then
			print(prefix.." DEBUG "..line..": "..force.." |r")
		else
			print(prefix.." DEBUG: "..force.." |r")
			print(debugstack(2))
		end
	end
end

local function eprint(text,rest)
	local line = strmatch(debugstack(2),":(%d+):")
	if line then
		print(prefix.." Error @ "..line..": "..text..""..(rest and " | "..rest or "").." |r")
	else
		print(prefix.." @ ERROR: "..text.." | "..rest.." |r")
		print(debugstack(2))
	end
end

ns.logging = {
    cprint = cprint,
    dprint = dprint,
    eprint = eprint,
}