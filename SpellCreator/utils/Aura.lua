---@class ns
local ns = select(2, ...)

local checkForAuraIDPredicate = function(wantedID, _, _, ...)
	local spellID = select(10, ...)
	return spellID == wantedID
end

-- SL 927 TODO: Convert to GetPlayerAuraBySpellID(id) for player.
local function checkForAuraID(wantedID, unit)
	local helpful = { AuraUtil.FindAura(checkForAuraIDPredicate, unit, nil, tonumber(wantedID)) }
	if #helpful > 0 then
		return unpack(helpful)
	else
		return AuraUtil.FindAura(checkForAuraIDPredicate, unit, "HARMFUL", tonumber(wantedID))
	end
end

local function checkPlayerAuraID(wantedID)
	return checkForAuraID(wantedID, "player")
end

local function checkTargetAuraID(wantedID)
	return checkForAuraID(wantedID, "target")
end

local function toggleAura(spellID)
	if checkPlayerAuraID(tonumber(spellID)) then
		ns.Cmd.cmd("unaura " .. spellID)
	else
		ns.Cmd.cmd("aura " .. spellID)
	end
end

---@class Utils_Aura
ns.Utils.Aura = {
	checkForAuraID = checkForAuraID,
	checkPlayerAuraID = checkPlayerAuraID,
	checkTargetAuraID = checkTargetAuraID,
	toggleAura = toggleAura
}
