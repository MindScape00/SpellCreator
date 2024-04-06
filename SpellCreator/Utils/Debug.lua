---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

local ADDON_COLOR, ADDON_TITLE = Constants.ADDON_COLOR, Constants.ADDON_TITLE

--local dump = DevTools_Dump
local function dump(o)
	if not DevTools_Dump then
		UIParentLoadAddOn("Blizzard_DebugTools");
	end
	if type(o) == "table" then
		DevTools_Dump(o);
		--DisplayTableInspectorWindow(o)
	else
		DevTools_Dump(o);
	end
	--[[
	-- Old Table String-i-zer.. Replaced with Blizzard_DebugTools nice dump :)
	if type(o) == 'table' then
		local s = '{ '
		for k, v in pairs(o) do
			if type(k) ~= 'number' then k = '"' .. k .. '"' end
			s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
	--]]
	if SpellCreatorMasterTable.Options["debugTableInspector"] and type(o) == "table" then DisplayTableInspectorWindow(o) end
end

local function ddump(o)
	if SpellCreatorMasterTable.Options["debug"] then
		local line = strmatch(debugstack(2), ":(%d+):")
		print(ADDON_COLOR .. ADDON_TITLE .. " DEBUG-DUMP " .. line .. ":|r")
		dump(o)
	end
end

---@class Utils_Debug
ns.Utils.Debug = {
	dump = dump,
	ddump = ddump,
}


local enable_eTrace_on_load = false
if enable_eTrace_on_load and not EventTraceFrame then
	UIParentLoadAddOn("Blizzard_DebugTools")

	EventTraceFrame:HookScript("OnShow", function(self)
		self.ignoredEvents = {
			CHAT_MSG_ADDON = false,
			CHAT_MSG_ADDON_LOGGED = false,
			CHAT_MSG_CHANNEL_JOIN = true,
			CHAT_MSG_CHANNEL_LEAVE = true,
			CHAT_MSG_SAY = true,
			CHAT_MSG_SYSTEM = true,
			COMBAT_LOG_EVENT = true,
			COMBAT_LOG_EVENT_UNFILTERED = true,
			GLOBAL_MOUSE_DOWN = true,
			GLOBAL_MOUSE_UP = true,
			NAME_PLATE_UNIT_REMOVED = true,
			PLAYER_STARTED_LOOKING = true,
			PLAYER_STOPPED_LOOKING = true,
			STREAMING_ICON = true,
			UNIT_HEALTH_FREQUENT = true,
			UNIT_POWER_FREQUENT = true,
			UNIT_POWER_UPDATE = true,
			UPDATE_MOUSEOVER_UNIT = true,
			VARIABLES_LOADED = false,
		}
	end)
	EventTraceFrame:Show()
	EventTraceFrame_StartEventCapture()
end
