---@class ns
local ns = select(2, ...)

local C_Timer = C_Timer
local pairs = pairs

local Constants = ns.Constants
local Permissions = ns.Permissions
local Vault = ns.Vault
local DataUtils = ns.Utils.Data
local StringSubs = ns.Utils.StringSubs
local Cooldowns = ns.Actions.Cooldowns

local parseStringToArgs = ns.Utils.Data.parseStringToArgs

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

local Conditions = ns.Actions.ConditionsData

---@param conditions ConditionDataTable
local function checkConditions(conditions)
	if not conditions then return true end
	if conditions and #conditions == 0 then return true end -- No Conditions, pass the check!

	local continueGroup
	for _, groupData in ipairs(conditions) do
		local continueRow = true
		for _, rowData in ipairs(groupData) do
			local conditionData = Conditions.getByKey(rowData.Type)
			local func = conditionData.script
			local condInputTable, numInputs = parseStringToArgs(rowData.Input)
			continueRow = func(unpack(condInputTable, 1, numInputs))
			if rowData.IsNot then continueRow = not (continueRow) end
			if not continueRow then break end -- row failed, break the current group
		end
		if continueRow then return true end -- group passed, return true
	end
	return false                      -- All groups failed, return false
end

---@param varTable any
---@param actionData any
---@param selfOnly any
---@param isRevert any
---@param conditions ConditionDataTable
---@param runningActionID any|table Could be the Timer Reference..
local function executeAction(varTable, actionData, selfOnly, isRevert, conditions, runningActionID)
	if not checkConditions(conditions) then return dprint(nil, "Execute Action Failed Conditions Check, Action Skipped!") end

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

local function checkReqString(text)
	if not text then return true end -- No string is technically nil which is technically.. true? or .. not true? IDFK.
	local textTable = strsplittable(".", text)
	local lastVar = true
	for i = 1, #textTable do
		local str = textTable[i]
		if i == 1 then
			lastVar = _G[str]
		else
			lastVar = lastVar[str]
		end
		if not lastVar then return false end
	end

	if lastVar then return true end
end

---@param actionData FunctionActionTypeData|ServerActionTypeData
---@param doNotWarn boolean Disable the eprint warning. So that the function is usable between both passive checks and active checks.
local function checkDepAndReq(actionData, doNotWarn)
	if actionData.dependency and not (IsAddOnLoaded(actionData.dependency) or IsAddOnLoaded(actionData.dependency .. "-dev")) then
		if not doNotWarn then
			if not actionData.softDependency then
				eprint("AddOn " .. actionData.dependency .. " required for action " .. actionData.name);
			else
				dprint("AddOn " .. actionData.dependency .. " required for action " .. actionData.name .. ". Soft dependency, no visible error.");
			end
		end
		return false;
	end
	local req = actionData.requirement
	local reqMet = true
	if req then
		if type(req) == "function" then
			reqMet = req()
		elseif type(req) == "string" then
			reqMet = checkReqString(req)
		end
		if not reqMet then -- requirements not met
			if not doNotWarn then -- give a warning
				eprint(("Action '%s' has additional script requirements that are not met: %s"):format(actionData.name, actionData.reqError or "Seek additional help in Epsilon Discord -> #tech-support."))
			end
			return reqMet
		end
	end

	-- if we get here, we had no valid dep or req
	return true
end

---Handle processing an action - either executing it, or creating the timer to execute on delay, as well as tracking it.
---@param delay number
---@param actionType ActionType
---@param revertDelay number
---@param selfOnly boolean
---@param conditions ConditionDataTable
---@param vars any
local function processAction(delay, actionType, revertDelay, selfOnly, conditions, vars)
	if not actionType then return; end
	local actionData = actionTypeData[actionType]
	if revertDelay then revertDelay = tonumber(revertDelay) end

	--[[ -- // Replaced with checkDepAndReq
	if actionData.dependency and not (IsAddOnLoaded(actionData.dependency) or IsAddOnLoaded(actionData.dependency .. "-dev")) then
		if not actionData.softDependency then
			eprint("AddOn " .. actionData.dependency .. " required for action " .. actionData.name);
		else
			dprint("AddOn " .. actionData.dependency .. " required for action " .. actionData.name .. ". Soft dependency, no visible error.");
		end
		return;
	end
	--]]
	if not checkDepAndReq(actionData) then return end

	local varTable

	if vars then
		if actionData.convertLinks then
			vars = ns.Utils.Data.convertLinksToIDs(vars)
		end
		if actionData.doNotDelimit then
			varTable = { vars }
		else
			varTable = { strsplit(",", vars) }
		end
	end

	if actionType == ns.Actions.Data.ACTION_TYPE.ArcStopThisSpell then -- taking over this Action for special case handling.
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
		executeAction(varTable, actionData, selfOnly, nil, conditions, nil)
		if revertDelay and revertDelay > 0 then
			createRevertTimer(revertDelay, function(self) executeAction(varTable, actionData, selfOnly, true, conditions, self) end)
		end
	else
		local timer = C_Timer.NewTimer(delay, function(self)
			executeAction(varTable, actionData, selfOnly, nil, conditions, self)
			if revertDelay and revertDelay > 0 then
				createRevertTimer(revertDelay, function(self) executeAction(varTable, actionData, selfOnly, true, conditions, self) end)
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
---@param ... any spell inputs
local function executeSpellFinal(actionsToCommit, bypassCheck, spellName, spellData, ...)
	local longestDelay = 0

	spellCastID = spellCastID + 1
	for index, action in pairs(actionsToCommit) do
		local vars = action.vars

		if actionTypeData[action.actionType] then
			if not actionTypeData[action.actionType].doNotSanitizeNewLines then
				vars = DataUtils.sanitizeNewlinesToCSV(action.vars)
			end
			--vars = replaceInputPlaceholders(vars, ...)
			if vars:find("@.-@") or vars:find("%%") then -- only spend the energy to parse substitutions if we actually see there might be one..
				vars = StringSubs.parseStringForAllSubs(vars, ...)
			end
			processAction(action.delay, action.actionType, action.revertDelay, action.selfOnly, action.conditions, vars)
			if action.delay > longestDelay then
				longestDelay = action.delay
			end
			if action.revertDelay then
				local fixedRevertDelay = action.revertDelay + action.delay
				if fixedRevertDelay > longestDelay then
					longestDelay = fixedRevertDelay
				end
			end
		else
			-- error handle that the action type didn't exist
			local errorMessage = ("Action Error (Action #%s): Action Type does not exist. This Action may require another AddOn.\n\rAction ID: %s"):format(index,
				ns.Utils.Tooltip.genContrastText(action.actionType))
			ns.Logging.arcWarning(errorMessage)
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
---@param ... any spell inputs
local function executeSpell(actionsToCommit, bypassCheck, spellName, spellData, ...)
	if ((not bypassCheck) and (not SpellCreatorMasterTable.Options["debug"])) then
		if not Permissions.canExecuteSpells() then
			print("Casting Arcanum Spells in Main Phase Start Zone is Disabled. Trying to test the Main Phase Vault spells? Head somewhere other than " .. START_ZONE_NAME .. ".")
			return
		end
	end

	if spellData then
		if spellData.conditions and #spellData.conditions > 0 then
			if not checkConditions(spellData.conditions) then
				PlayVocalErrorSoundID(48);
				local cooldownMessage = Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode(("You can't cast that ArcSpell (%s) right now."):format(spellData.fullName))
				UIErrorsFrame:AddMessage(cooldownMessage, Constants.ADDON_COLORS.ADDON_COLOR:GetRGB(), 1)
				return dprint(nil, "Execute Action Failed Conditions Check, Spell Skipped!")
			end
		end

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

	executeSpellFinal(actionsToCommit, bypassCheck, spellName, spellData, ...);
	return true
end

---@param commID CommID
---@param bypassCD boolean? true to bypass triggering spell's cooldown
---@param ... any spell inputs
local function executePhaseSpell(commID, bypassCD, ...)
	local spell = Vault.phase.findSpellByID(commID)
	local currentPhase = C_Epsilon.GetPhaseId()
	if spell then
		local spellCooldownRemaining, spellCooldownLength = Cooldowns.isSpellOnCooldown(commID, currentPhase)
		if spellCooldownRemaining then
			local cooldownMessage = Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode(("Phase ArcSpell %s (%s) is currently on cooldown (%ss remaining)."):format(spell.fullName, spell
				.commID, ns.Utils.Data.roundToNthDecimal(spellCooldownRemaining, 2)))
			UIErrorsFrame:AddMessage(cooldownMessage, Constants.ADDON_COLORS.ADDON_COLOR:GetRGB(), 1)
			PlayVocalErrorSoundID(12);
			return false
		else
			executeSpellFinal(spell.actions, true, spell.fullName, spell, ...);
			if spell.cooldown and not bypassCD then
				addSpellCooldown(spell.commID, spell.cooldown, currentPhase)
			end
			return true
		end
	else
		cprint("No spell with command " .. commID .. " found in the Phase Vault (or vault was not loaded). Please let a phase officer know.")
		return false
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

	checkConditions = checkConditions,
	checkDepAndReq = checkDepAndReq,
}
