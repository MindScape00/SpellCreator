local _, ns = ...

local C_Timer = C_Timer
local pairs = pairs

local actionTypeData = ns.actions.actionTypeData
local cmd = ns.cmd.cmd
local cprint = ns.logging.cprint
local isOfficerPlus = ns.permissions.isOfficerPlus

local sfCmd_ReplacerChar = "@N@"

local runningActions = {}

local function stopRunningActions()
	local didStopSomething = false
	for i = 1, #runningActions do
		if runningActions[i] then
			runningActions[i]:Cancel()
			runningActions[i]=nil
			didStopSomething = true
			--print("Timer ", i, "Cancelled")
		end
	end
	ns.Utils.Castbar.stopCastingBars()
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
				local runningActionID = #runningActions+1
				runningActions[runningActionID] = C_Timer.NewTimer(revertDelay, function() executeAction(varTable, actionData, selfOnly, true, runningActionID) end)
			end
		end)
	end
end

local function executeSpell(actionsToCommit, bypassCheck, spellName, spellData)
	local longestDelay = 0
	local channeled
	if ((not bypassCheck) and (not SpellCreatorMasterTable.Options["debug"])) then
		if tonumber(C_Epsilon.GetPhaseId()) == 169 and GetRealZoneText() == "Dranosh Valley" and not isOfficerPlus() then cprint("Casting Arcanum Spells in Main Phase Start Zone is Disabled. Trying to test the Main Phase Vault spells? Head somewhere other than Dranosh Valley.") return; end
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
	
	if spellData then 
		local spellOptions = spellData["options"]
		channeled = tContains(spellOptions, "channeled")
	end

	if not spellName then spellName = "Arcanum Spell" end
	ns.Utils.Castbar.showCastBar(longestDelay, spellName, nil, channeled, nil, nil)
end

ns.actions.executeSpell = executeSpell
ns.actions.stopRunningActions = stopRunningActions

hooksecurefunc("SpellStopCasting", function() return stopRunningActions() end)
--[[
local f  = CreateFrame("Frame", nil, UIParent)
local function onKeyInput(self, key)
	if key == "ESCAPE" then
		stopRunningActions()
	end
end 
f:SetScript("OnKeyDown", onKeyInput)
f:SetPropagateKeyboardInput(true)
--]]