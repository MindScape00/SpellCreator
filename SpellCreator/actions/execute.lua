---@class ns
local ns = select(2, ...)

local C_Timer = C_Timer
local pairs = pairs

local Permissions = ns.Permissions

local actionTypeData = ns.Actions.Data.actionTypeData
local cmd = ns.Cmd.cmd
local cprint = ns.Logging.cprint
local eprint = ns.Logging.eprint

local sfCmd_ReplacerChar = "@N@"

local runningActions = {}

local function stopRunningActions()
	local didStopSomething = false
	for i = 1, #runningActions do
		if runningActions[i] then
			runningActions[i]:Cancel()
			runningActions[i]=nil
			didStopSomething = true
		end
	end
	ns.UI.Castbar.stopCastingBars()
	return didStopSomething
end

local function executeAction(varTable, actionData, selfOnly, isRevert, runningActionID)
	if runningActionID then runningActions[runningActionID] = nil end
	local comTarget = actionData.comTarget
	for i = 1, #varTable do
		local v = varTable[i]
		if string.byte(v,1) == 32 then v = strtrim(v, " ") end
		if comTarget == "func" then
			if isRevert then
				actionData.revert(v)
			else
				actionData.command(v)
			end
		else
			if isRevert then
				local finalCommand = tostring(actionData.revert)
				finalCommand = finalCommand:gsub(sfCmd_ReplacerChar, v)
				if selfOnly then finalCommand = finalCommand.." self" end
				cmd(finalCommand)
			else
				local finalCommand = tostring(actionData.command)
				finalCommand = finalCommand:gsub(sfCmd_ReplacerChar, v)
				if selfOnly then finalCommand = finalCommand.." self" end
				cmd(finalCommand)
			end
		end
	end
end

local function processAction(delay, actionType, revertDelay, selfOnly, vars)
	if not actionType then return; end
	local actionData = actionTypeData[actionType]
	if revertDelay then revertDelay = tonumber(revertDelay) end
	if actionData.dependency and not IsAddOnLoaded(actionData.dependency) then eprint("AddOn " .. actionData.dependency .. " required for action "..actionData.name); return; end
	local varTable

	if vars then
		if actionData.doNotDelimit then
			varTable = { vars }
		else
			varTable = { strsplit(",", vars) }
		end
	end

	if delay == 0 then
		executeAction(varTable, actionData, selfOnly, nil, nil)
		if revertDelay and revertDelay > 0 then
			local runningActionID = #runningActions+1
			runningActions[runningActionID] = C_Timer.NewTimer(revertDelay, function() executeAction(varTable, actionData, selfOnly, true, runningActionID) end)
		end
	else
		local runningActionID = #runningActions+1
		runningActions[runningActionID] = C_Timer.NewTimer(delay, function()
			executeAction(varTable, actionData, selfOnly, nil, runningActionID)
			if revertDelay and revertDelay > 0 then
				runningActionID = #runningActions+1
				runningActions[runningActionID] = C_Timer.NewTimer(revertDelay, function() executeAction(varTable, actionData, selfOnly, true, runningActionID) end)
			end
		end)
	end
end

local function executeSpell(actionsToCommit, bypassCheck, spellName, spellData)
	local longestDelay = 0
	if ((not bypassCheck) and (not SpellCreatorMasterTable.Options["debug"])) then
		if not Permissions.canExecuteSpells() then
			cprint("Casting Arcanum Spells in Main Phase Start Zone is Disabled. Trying to test the Main Phase Vault spells? Head somewhere other than Dranosh Valley.")
			return
		end
	end
	for _,spell in pairs(actionsToCommit) do
		processAction(spell.delay, spell.actionType, spell.revertDelay, spell.selfOnly, spell.vars)
		if spell.delay > longestDelay then
			longestDelay = spell.delay
		end
		if spell.revertDelay and spell.revertDelay > longestDelay then
			longestDelay = spell.revertDelay
		end
	end

	if not spellName then spellName = "Arcanum Spell" end

	if spellData then
		if spellData.castbar == 0 then return;
		elseif spellData.castbar == 2 then
			ns.UI.Castbar.showCastBar(longestDelay, spellName, spellData, true, nil, nil)
		else
			ns.UI.Castbar.showCastBar(longestDelay, spellName, spellData, false, nil, nil)
		end
	end
end

hooksecurefunc("ToggleGameMenu", function()
	if stopRunningActions() then HideUIPanel(GameMenuFrame); end
end)

---@class Actions_Execute
ns.Actions.Execute = {
	executeSpell = executeSpell,
	stopRunningActions = stopRunningActions,
}
