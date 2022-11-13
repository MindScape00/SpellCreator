local _, ns = ...

local checkForAuraIDPredicate = function(wantedID, _, _, ...)
	local spellID = select(10, ...)
	return spellID == wantedID
end

local function checkForAuraID(wantedID)
	return AuraUtil.FindAura(checkForAuraIDPredicate, "player", nil, wantedID)
end

ns.Utils.Aura = {
    checkForAuraID = checkForAuraID,
}