---@class ns
local ns = select(2, ...)

local checkForAuraIDPredicate = function(wantedID, _, _, ...)
	local spellID = select(10, ...)
	return spellID == wantedID
end

local function checkForAuraID(wantedID)
	return AuraUtil.FindAura(checkForAuraIDPredicate, "player", nil, wantedID)
end

---@class Utils_Aura
ns.Utils.Aura = {
    checkForAuraID = checkForAuraID,
}
