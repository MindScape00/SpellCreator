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

--[[ -- Old Table String-i-zer.. Replaced with Blizzard_DebugTools nice dump :)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
--]]
end

local function ddump(o)
	if SpellCreatorMasterTable.Options["debug"] then
		local line = strmatch(debugstack(2),":(%d+):")
		print(ADDON_COLOR..ADDON_TITLE.." DEBUG-DUMP "..line..":|r")
		dump(o)
	end
end

---@class Utils_Debug
ns.Utils.Debug = {
    dump = dump,
    ddump = ddump,
}
