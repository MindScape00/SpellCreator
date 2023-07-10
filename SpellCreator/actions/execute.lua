---@class ns
local ns = select(2, ...)

local C_Timer = C_Timer
local pairs = pairs

local Constants = ns.Constants
local Permissions = ns.Permissions
local Vault = ns.Vault
local DataUtils = ns.Utils.Data
local Cooldowns = ns.Actions.Cooldowns

local actionTypeData = ns.Actions.Data.actionTypeData
local cmd = ns.Cmd.cmd
local cprint = ns.Logging.cprint
local eprint = ns.Logging.eprint
local dprint = ns.Logging.dprint
local START_ZONE_NAME = Constants.START_ZONE_NAME

local sfCmd_ReplacerChar = "@N@"

---@class RunningAction
---@field id number
---@field timer table|function

---@class RunningRevert: RunningAction
---@field func function

---@class RunningSpells
local runningSpells = {}

---@class RunningActions
---@type RunningAction[]
local runningActions = {}

---@class RunningReverts
---@type RunningRevert[]
local runningReverts = {}

local spellCastID = 0

local addSpellCooldown = Cooldowns.addSpellCooldown

--local stoppedRevertsToRemove = {}
---@param spellCastedID integer?
---@return boolean didSomethingStop
local function stopRunningReverts(spellCastedID)
	local didStopSomething = false
	for k, v in pairs(runningReverts) do
		if spellCastedID then
			if v.id == spellCastedID then
				v.timer:Cancel()
				v.func()
				runningReverts[k] = nil
				didStopSomething = true
			end
		else
			v.timer:Cancel()
			v.func()
			runningReverts[k] = nil
			didStopSomething = true
		end
	end

	return didStopSomething
end

--local stoppedActionsToRemove = {}
---@param spellCastedID integer?
---@return boolean didSomethingStop if any actions stopped
local function stopRunningActions(spellCastedID)
	local didStopSomething = false
	for k, v in pairs(runningActions) do
		if spellCastedID then
			if v.id == spellCastedID then
				v.timer:Cancel()
				runningActions[k] = nil
				didStopSomething = true
			end
		else
			v.timer:Cancel()
			runningActions[k] = nil
			didStopSomething = true
		end
	end
	local didStopReverts = stopRunningReverts(spellCastedID)
	didStopSomething = didStopSomething or didStopReverts
	if spellCastedID then
		for _, v in ipairs(runningSpells) do
			if v.spellCastedID == spellCastedID and v.commID then
				ns.UI.Castbar.stopCastingBars(v.commID)
			end
		end
	else
		ns.UI.Castbar.stopCastingBars()
	end
	ns.UI.Animation.stopFrameFlicker(SCForgeMainFrame.Inset.Bg.Overlay, 0.05, 0.25)

	return didStopSomething
end

---Add a spell to the Running Spells tracker
---@param commID CommID
---@param spellCastedID integer?
---@param maxDelay number
local function addSpellToRunningSpells(commID, spellCastedID, maxDelay)
	local numRunningSpells = #runningSpells + 1
	tinsert(runningSpells, {
		spellCastedID = spellCastedID,
		commID = commID,
		timer = C_Timer.NewTimer(maxDelay, function() C_Timer.After(0, function() tremove(runningSpells, numRunningSpells) end) end),
	})
end

---Cancel the remaining actions of any currently running spell by CommID; only cancels those spells.
---@param commID CommID
local function cancelSpellByCommID(commID)
	local cancelledSpells = {}
	for i = 1, #runningSpells do
		local v = runningSpells[i]
		if v.commID == commID then
			stopRunningActions(v.spellCastedID)
			ns.UI.Castbar.stopCastingBars(commID)
			v.timer:Cancel()
			tinsert(cancelledSpells, i)
		end
	end
	for i = 1, #cancelledSpells do
		tremove(runningSpells, cancelledSpells[i])
	end
end

---@param varTable any
---@param actionData any
---@param selfOnly any
---@param isRevert any
---@param runningActionID any|table Could be the Timer Reference..
local function executeAction(varTable, actionData, selfOnly, isRevert, runningActionID)
	local comTarget = actionData.comTarget
	for i = 1, #varTable do
		local v = varTable[i]
		if string.byte(v, 1) == 32 then v = strtrim(v, " ") end
		v = v:gsub(string.char(124) .. string.char(124), string.char(124)) -- replace escaped || with | to allow escape codes.
		if comTarget == "func" then
			if isRevert then
				if actionData.revert then
					actionData.revert(v)
				end
			else
				actionData.command(v)
			end
		else
			if isRevert then
				local finalCommand = tostring(actionData.revert)
				finalCommand = finalCommand:gsub(sfCmd_ReplacerChar, v)
				if selfOnly then finalCommand = finalCommand .. " self" end
				cmd(finalCommand)
			else
				local finalCommand = tostring(actionData.command)
				finalCommand = finalCommand:gsub(sfCmd_ReplacerChar, v)
				if selfOnly then finalCommand = finalCommand .. " self" end
				cmd(finalCommand)
			end
		end
	end
	if isRevert then
		--if runningActionID then tremove(runningReverts, runningActionID) end
		if runningActionID then runningReverts[runningActionID] = nil end
	else
		--if runningActionID then tremove(runningActions, runningActionID) end
		if runningActionID then runningActions[runningActionID] = nil end
	end
end

---Create a revert timer and add it to the runningReverts tracking table
---@param revertDelay number?
---@param revertFunction function
local function createRevertTimer(revertDelay, revertFunction)
	if revertDelay and revertDelay > 0 then
		local timer = C_Timer.NewTimer(revertDelay, revertFunction)
		runningReverts[timer] = {
			id = spellCastID,
			timer = timer,
			func = revertFunction,
		}
	end
end

---Handle processing an action - either executing it, or creating the timer to execute on delay, as well as tracking it.
---@param delay number
---@param actionType ActionType
---@param revertDelay number
---@param selfOnly boolean
---@param vars any
local function processAction(delay, actionType, revertDelay, selfOnly, vars)
	if not actionType then return; end
	local actionData = actionTypeData[actionType]
	if revertDelay then revertDelay = tonumber(revertDelay) end
	if actionData.dependency and not (IsAddOnLoaded(actionData.dependency) or IsAddOnLoaded(actionData.dependency .. "-dev")) then
		if not actionData.softDependency then
			eprint("AddOn " .. actionData.dependency .. " required for action " .. actionData.name);
		else
			dprint("AddOn " .. actionData.dependency .. " required for action " .. actionData.name .. ". Soft dependency, no visible error.");
		end
		return;
	end
	local varTable

	if vars then
		if actionData.doNotDelimit then
			varTable = { vars }
		else
			varTable = { strsplit(",", vars) }
		end
	end

	if actionType == ns.Actions.Data.ACTION_TYPE.SecureMacro then
		-- insert Secure Macro handler here? No? Just avoid doing anything here I guess?
		-- This should be defined onto a SecureMacro handler as soon as it is clicked, from the click action, on the actual button being clicked. I.e., "OnClick for k,v in actions do if action==secureMacro then do macro end"
	elseif actionType == ns.Actions.Data.ACTION_TYPE.ArcStopThisSpell then -- taking over this Action for special case handling.
		local timer = C_Timer.NewTimer(delay, function(self)
			if actionData.command(vars) then
				dprint("ArcStopThisSpell triggered, true - Stopping Spell..")
				stopRunningActions(spellCastID)
			end
		end)
		runningActions[timer] = {
			id = spellCastID,
			timer = timer,
		}
	elseif delay == 0 then
		executeAction(varTable, actionData, selfOnly, nil, nil)
		if revertDelay and revertDelay > 0 then
			createRevertTimer(revertDelay, function(self) executeAction(varTable, actionData, selfOnly, true, self) end)
		end
	else
		local timer = C_Timer.NewTimer(delay, function(self)
			executeAction(varTable, actionData, selfOnly, nil, self)
			if revertDelay and revertDelay > 0 then
				createRevertTimer(revertDelay, function(self) executeAction(varTable, actionData, selfOnly, true, self) end)
			end
		end)
		runningActions[timer] = {
			id = spellCastID,
			timer = timer,
		}
	end
end

---The final step in executing a spell, distributing it's actions and data to the necessary functions.
---@param actionsToCommit VaultSpellAction[]
---@param bypassCheck boolean | nil
---@param spellName string
---@param spellData VaultSpell?
local function executeSpellFinal(actionsToCommit, bypassCheck, spellName, spellData)
	local longestDelay = 0

	spellCastID = spellCastID + 1
	for _, spell in pairs(actionsToCommit) do
		processAction(spell.delay, spell.actionType, spell.revertDelay, spell.selfOnly, DataUtils.sanitizeNewlinesToCSV(spell.vars))
		if spell.delay > longestDelay then
			longestDelay = spell.delay
		end
		if spell.revertDelay and spell.revertDelay > longestDelay then
			longestDelay = spell.revertDelay
		end
	end

	if not spellName then spellName = "Arcanum Spell" end

	if spellData then
		if spellData.commID then
			addSpellToRunningSpells(spellData.commID, spellCastID, longestDelay)
		end

		if spellData.castbar == 0 then
			return;
		elseif spellData.castbar == 2 then
			ns.UI.Castbar.showCastBar(longestDelay, spellName, spellData, true, nil, nil)
		else
			ns.UI.Castbar.showCastBar(longestDelay, spellName, spellData, false, nil, nil)
		end
	end
end

---@param actionsToCommit VaultSpellAction[]
---@param bypassCheck boolean | nil
---@param spellName string
---@param spellData VaultSpell?
local function executeSpell(actionsToCommit, bypassCheck, spellName, spellData)
	if ((not bypassCheck) and (not SpellCreatorMasterTable.Options["debug"])) then
		if not Permissions.canExecuteSpells() then
			print("Casting Arcanum Spells in Main Phase Start Zone is Disabled. Trying to test the Main Phase Vault spells? Head somewhere other than " .. START_ZONE_NAME .. ".")
			return
		end
	end

	if spellData then
		local spellCooldownRemaining, spellCooldownLength = Cooldowns.isSpellOnCooldown(spellData.commID)
		if spellCooldownRemaining then
			local cooldownMessage = Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode(("ArcSpell %s (%s) is currently on cooldown (%ss remaining)."):format(spellData.fullName, spellData
				.commID, ns.Utils.Data.roundToNthDecimal(spellCooldownRemaining, 2)))
			UIErrorsFrame:AddMessage(cooldownMessage, Constants.ADDON_COLORS.ADDON_COLOR:GetRGB(), 1)
			PlayVocalErrorSoundID(12);
			return
		elseif spellData.cooldown then
			addSpellCooldown(spellData.commID, spellData.cooldown)
		end
	end

	executeSpellFinal(actionsToCommit, bypassCheck, spellName, spellData);
end

---@param commID CommID
---@param bypassCD boolean? true to bypass triggering spell's cooldown
local function executePhaseSpell(commID, bypassCD)
	local spell = Vault.phase.findSpellByID(commID)
	local currentPhase = C_Epsilon.GetPhaseId()
	local currentTime = GetTime()
	if spell then
		local spellCooldownRemaining, spellCooldownLength = Cooldowns.isSpellOnCooldown(commID, currentPhase)
		if spellCooldownRemaining then
			local cooldownMessage = Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode(("Phase ArcSpell %s (%s) is currently on cooldown (%ss remaining)."):format(spell.fullName, spell
				.commID, ns.Utils.Data.roundToNthDecimal(spellCooldownRemaining, 2)))
			UIErrorsFrame:AddMessage(cooldownMessage, Constants.ADDON_COLORS.ADDON_COLOR:GetRGB(), 1)
			PlayVocalErrorSoundID(12);
		else
			executeSpellFinal(spell.actions, true, spell.fullName, spell);
			if spell.cooldown and not bypassCD then
				addSpellCooldown(spell.commID, spell.cooldown, currentPhase)
			end
		end
	else
		cprint("No spell with command " .. commID .. " found in the Phase Vault (or vault was not loaded). Please let a phase officer know.")
	end
end

hooksecurefunc("ToggleGameMenu", function()
	if stopRunningActions() then HideUIPanel(GameMenuFrame); end
	ARC._DEBUG.RUNNINGACTIONS = {
		runningSpells = runningSpells,
		runningActions = runningActions,
		runningReverts = runningReverts,
	}
end)

---@class Actions_Execute
ns.Actions.Execute = {
	executeSpell = executeSpell,
	executePhaseSpell = executePhaseSpell,
	stopRunningActions = stopRunningActions,
	cancelSpellByCommID = cancelSpellByCommID,
}
