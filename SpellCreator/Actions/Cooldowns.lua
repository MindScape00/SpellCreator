---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

local spellCooldowns = { personal = {}, phase = {}, sparks = {} }

local cooldownFrameFuncs = {
	vaultFrame = function(commID, cooldownTime, phase)
		if SCForgeLoadFrame:IsShown() then
			if phase then
				if ns.UI.LoadSpellFrame.getCurrentVault() == Constants.VAULT_TYPE.PHASE then
					local vaultIndex = ns.Vault.phase.findSpellIndexByID(commID)
					if vaultIndex then
						ns.UI.SpellLoadRow.triggerCooldownVisual(vaultIndex, cooldownTime)
					end
				end
			else
				if ns.UI.LoadSpellFrame.getCurrentVault() == Constants.VAULT_TYPE.PERSONAL then
					ns.UI.SpellLoadRow.triggerCooldownVisual(commID, cooldownTime)
				end
			end
		end
	end,
	sparkFrame = function(commID, cooldownTime, phase)
		if not phase then return end
		ns.UI.SparkPopups.SparkPopups.triggerSparkCooldownVisual(commID, cooldownTime)
	end,
	qcFrame = function(commID, cooldownTime, phase)
		-- this is done manually in the quickcast book page buttons
	end,
	spellBookUI = function(commID, cooldownTime, phase)
		ns.UI.SpellBookUI.updateButtons()
	end,
	actionButtons = function(commID, cooldownTime, phase)
		ns.UI.ActionButton.updateArcActionButtonCooldowns()
	end,
}

---Trigger all spell icon cooldown frame visuals
---@param commID CommID
---@param cooldownTime number
---@param phase integer?
local function triggerCooldownVisuals(commID, cooldownTime, phase)
	for k, v in pairs(cooldownFrameFuncs) do v(commID, cooldownTime, phase) end
end

---Add a spell to the Cooldowns tracker
---@param commID CommID
---@param cooldownTime number
---@param phase integer? Phase ID if the spell is from the Phase Vault, leave off if personal vault.
---@param noVisual boolean? true to skip triggering the visual cooldown indicators
local function addSpellCooldown(commID, cooldownTime, phase, noVisual)
	local currentTime = GetTime()
	if phase then
		if not spellCooldowns.phase[phase] then spellCooldowns.phase[phase] = {} end
		spellCooldowns.phase[phase][commID] = { endTime = cooldownTime + currentTime, length = tonumber(cooldownTime) }

		if noVisual then return end
		triggerCooldownVisuals(commID, cooldownTime, phase)
	else
		spellCooldowns.personal[commID] = { endTime = cooldownTime + currentTime, length = tonumber(cooldownTime) }

		if noVisual then return end
		triggerCooldownVisuals(commID, cooldownTime)
	end
end

---manually removes a spell's cooldown timer - not needed normally. Maybe call this when we re-save a spell?
---@param commID CommID
---@param phase integer? Phase ID if the spell is from the Phase Vault, leave off if personal vault.
local function removeSpellCooldown(commID, phase)
	if phase then
		if spellCooldowns.phase[phase] then spellCooldowns.phase[phase][commID] = nil end
	else
		spellCooldowns.personal[commID] = nil
	end
end

---Check if a spell is on cooldown. Returns false if not on cooldown, or the time remaining & original length of cooldown if it's on cooldown
---@param commID CommID
---@param phase integer|boolean|string?
---@return false | number remainingTime, nil | number cooldownLength
local function isSpellOnCooldown(commID, phase)
	if phase == true then
		phase = C_Epsilon.GetPhaseId()
	elseif type(phase) == "number" then
		phase = tostring(phase)
	end
	local currentTime = GetTime()
	if phase then
		if spellCooldowns.phase[phase] then
			local cooldownInfo = spellCooldowns.phase[phase][commID]
			if cooldownInfo and cooldownInfo.endTime > currentTime then
				local remainingTime = cooldownInfo.endTime - currentTime
				return remainingTime, cooldownInfo.length
			end
		end
	else
		local cooldownInfo = spellCooldowns.personal[commID]
		if cooldownInfo and cooldownInfo.endTime > currentTime then
			local remainingTime = cooldownInfo.endTime - currentTime
			return remainingTime, cooldownInfo.length
		end
	end
	return false
end

-- -- -- -- -- -- --
--#region Sparks
-- -- -- -- -- -- --

---Add a spell to the Cooldowns tracker
---@param commID CommID
---@param cooldownTime number
---@param origCommID CommID
---@param phaseOverride number?
local function addSparkCooldown(commID, cooldownTime, origCommID, phaseOverride)
	local currentTime = GetTime()
	local phase

	local curPhase = C_Epsilon.GetPhaseId()
	if phaseOverride then phase = phaseOverride else phase = curPhase end

	if not spellCooldowns.sparks[phase] then spellCooldowns.sparks[phase] = {} end
	spellCooldowns.sparks[phase][commID] = { endTime = cooldownTime + currentTime, length = tonumber(cooldownTime) }

	--triggerCooldownVisuals(commID, cooldownTime, phase)
	if phaseOverride then
		if curPhase == phaseOverride then -- phase override is the phase we are in, trigger cooldown visuals
			ns.UI.SparkPopups.SparkPopups.triggerSparkCooldownVisual(origCommID, cooldownTime)
		end
	else
		ns.UI.SparkPopups.SparkPopups.triggerSparkCooldownVisual(origCommID, cooldownTime)
	end
end

---manually removes a spell's cooldown timer - not needed normally. Maybe call this when we re-save a spell?
---@param commID CommID
local function removeSparkCooldown(commID)
	local phase = C_Epsilon.GetPhaseId()
	if spellCooldowns.sparks[phase] then spellCooldowns.sparks[phase][commID] = nil end
end

---Check if a spell is on cooldown. Returns false if not on cooldown, or the time remaining & original length of cooldown if it's on cooldown
---@param commID CommID
---@return false | number, nil | number
local function isSparkOnCooldown(commID)
	local currentTime = GetTime()
	local phase = C_Epsilon.GetPhaseId()
	if spellCooldowns.sparks[phase] then
		local cooldownInfo = spellCooldowns.sparks[phase][commID]
		if cooldownInfo and cooldownInfo.endTime > currentTime then
			local remainingTime = cooldownInfo.endTime - currentTime
			return remainingTime, cooldownInfo.length
		end
	end
	return false
end

-- -- -- -- -- -- --
--#endregion
-- -- -- -- -- -- --

local function clearOldCooldowns(forceReset)
	local currentTime = GetTime()

	-- If debug, wipe all cooldowns
	if forceReset or SpellCreatorMasterTable.Options["debug"] then
		spellCooldowns = { phase = {}, personal = {}, sparks = {} }
	else
		if not spellCooldowns.phase then spellCooldowns.phase = {} end
		if not spellCooldowns.personal then spellCooldowns.personal = {} end
		if not spellCooldowns.sparks then spellCooldowns.sparks = {} end
		-- otherwise check & remove expired ones, or ones that clearly don't make sense due to PC restart.
		--personal
		for commID, cooldownInfo in pairs(spellCooldowns.personal) do
			local remainingTime = cooldownInfo.endTime - currentTime
			if remainingTime > 0 and remainingTime < cooldownInfo.length then
				return
			else
				spellCooldowns.personal[commID] = nil
			end
		end
		--phase
		for phaseID, cooldowns in pairs(spellCooldowns.phase) do
			for commID, cooldownInfo in pairs(cooldowns) do
				local remainingTime = cooldownInfo.endTime - currentTime
				if remainingTime > 0 and remainingTime < cooldownInfo.length then
					return
				else
					spellCooldowns.phase[phaseID][commID] = nil
				end
			end
		end
		--sparks
		for phaseID, cooldowns in pairs(spellCooldowns.sparks) do
			for commID, cooldownInfo in pairs(cooldowns) do
				local remainingTime = cooldownInfo.endTime - currentTime
				if remainingTime > 0 and remainingTime < cooldownInfo.length then
					return
				else
					spellCooldowns.sparks[phaseID][commID] = nil
				end
			end
		end
	end
end

local function getCooldownsTable()
	return spellCooldowns
end

local function retargetCooldownsTable(table)
	spellCooldowns = table
	clearOldCooldowns()
end

---@class Actions_Cooldowns
ns.Actions.Cooldowns = {
	addSpellCooldown = addSpellCooldown,
	removeSpellCooldown = removeSpellCooldown,
	isSpellOnCooldown = isSpellOnCooldown,
	triggerCooldownVisuals = triggerCooldownVisuals,
	retargetCooldownsTable = retargetCooldownsTable,
	getCooldownsTable = getCooldownsTable,
	clearOldCooldowns = clearOldCooldowns,

	addSparkCooldown = addSparkCooldown,
	removeSparkCooldown = removeSparkCooldown,
	isSparkOnCooldown = isSparkOnCooldown,
}
