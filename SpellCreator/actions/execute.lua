local _, ns = ...

local actionTypeData = ns.actions.actionTypeData
local cmd = ns.cmd.cmd
local cprint = ns.logging.cprint
local isOfficerPlus = ns.permissions.isOfficerPlus

local sfCmd_ReplacerChar = "@N@"

local function executeAction(varTable, actionData, selfOnly, isRevert)
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
		executeAction(varTable, actionData, selfOnly, nil)
		if revertDelay and revertDelay > 0 then
			C_Timer.After(revertDelay, function() executeAction(varTable, actionData, selfOnly, true) end)
		end
	else
		C_Timer.After(delay, function()
			executeAction(varTable, actionData, selfOnly, nil)
			if revertDelay and revertDelay > 0 then
				C_Timer.After(revertDelay, function() executeAction(varTable, actionData, selfOnly, true) end)
			end
		end)
	end
end

local function executeSpell(actionsToCommit, byPassCheck)
	if ((not byPassCheck) and (not SpellCreatorMasterTable.Options["debug"])) then
		if tonumber(C_Epsilon.GetPhaseId()) == 169 and GetRealZoneText() == "Dranosh Valley" and not isOfficerPlus() then cprint("Casting Arcanum Spells in Main Phase Start Zone is Disabled. Trying to test the Main Phase Vault spells? Head somewhere other than Dranosh Valley.") return; end
	end
	for _,spell in pairs(actionsToCommit) do
		processAction(spell.delay, spell.actionType, spell.revertDelay, spell.selfOnly, spell.vars)
	end
end

ns.actions.executeSpell = executeSpell