local _, ns = ...

local C_Epsilon = C_Epsilon

local function isDMEnabled()
	if C_Epsilon.IsDM and (C_Epsilon.IsOfficer() or C_Epsilon.IsOwner()) then return true; else return false; end
end

local function isOfficerPlus()
	if C_Epsilon.IsOfficer() or C_Epsilon.IsOwner() then return true; else return false; end
end

local function isMemberPlus()
	if C_Epsilon.IsMember() or C_Epsilon.IsOfficer() or C_Epsilon.IsOwner() then return true; else return false; end
end

ns.permissions = {
    isDMEnabled = isDMEnabled,
    isOfficerPlus = isOfficerPlus,
    isMemberPlus = isMemberPlus,
}