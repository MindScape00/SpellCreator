---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

local C_Epsilon = C_Epsilon
local START_ZONE_NAME = Constants.START_ZONE_NAME

local function isDMEnabled()
	if C_Epsilon.IsDM and (C_Epsilon.IsOfficer() or C_Epsilon.IsOwner()) then return true; else return false; end
end

local function isOfficerPlus()
	if C_Epsilon.IsOfficer() or C_Epsilon.IsOwner() then return true; else return false; end
end

local function isMemberPlus()
	if C_Epsilon.IsMember() or C_Epsilon.IsOfficer() or C_Epsilon.IsOwner() then return true; else return false; end
end

local function isStart()
	return tonumber(C_Epsilon.GetPhaseId()) == 169 and GetRealZoneText() == START_ZONE_NAME
end

local function canExecuteSpells()
	return not isStart() or isOfficerPlus() or SpellCreatorMasterTable.Options.debug
end

ns.Permissions = {
	isDMEnabled = isDMEnabled,
    isOfficerPlus = isOfficerPlus,
    isMemberPlus = isMemberPlus,
	canExecuteSpells = canExecuteSpells,
}
