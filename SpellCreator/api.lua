---@class ns
local ns = select(2, ...)

local Cmd = ns.Cmd
local Constants = ns.Constants
local Execute = ns.Actions.Execute
local HTML = ns.Utils.HTML
local Logging = ns.Logging
local Vault = ns.Vault
local phaseVault = Vault.phase
local SavedVariables = ns.SavedVariables

local cmdWithDotCheck = Cmd.cmdWithDotCheck
local ADDON_COLORS = Constants.ADDON_COLORS
local ADDON_COLOR = Constants.ADDON_COLOR
local cprint, dprint, eprint = Logging.cprint, Logging.dprint, Logging.eprint
local executeSpell, executePhaseSpell = Execute.executeSpell, Execute.executePhaseSpell

ARC = {}
ARC.VAR = {}

---@param key string
function ARC:UNLOCK(key)
	SavedVariables.unlocks.unlock(key)
end

-- SYNTAX: ARC:COMM("command here") - i.e., ARC:COMM("cheat fly") -- KEPT THIS VERSION FOR LEGACY SUPPORT
---@param text string
function ARC:COMM(text)
	if text and text ~= "" then
		cmdWithDotCheck(text)
	else
		cprint('ARC:API SYNTAX - COMM - Sends a Command to the Server.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:COMM("command here")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:COMM("cheat fly")')
	end
end

-- SYNTAX: ARC:CMD("command here") - i.e., ARC:CMD("cheat fly")
---@param text string
function ARC:CMD(text)
	if text and text ~= "" then
		cmdWithDotCheck(text)
	else
		cprint('ARC:API SYNTAX - CMD - Sends a Command to the Server.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:CMD("command here")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:CMD("cheat fly")')
	end
end

-- SYNTAX: ARC:COPY("text to copy, like a URL") - i.e., ARC:COPY("https://discord.gg/C8DZ7AxxcG")
---@param text string
function ARC:COPY(text)
	if text and text ~= "" then
		HTML.copyLink(nil, text)
	else
		cprint('ARC:API SYNTAX - COPY - Opens a Dialog to copy the given text.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:COPY("text to copy, like a URL")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:COPY("https://discord.gg/C8DZ7AxxcG")')
	end
end

-- SYNTAX: ARC:GETNAME() - Gets the Name of the Target and prints it to chat, with MogIt Link Filtering. This allows MogIt links to be copied easily.
function ARC:GETNAME()
	local unitName = GetUnitName("target")
	if unitName:match("MogIt") then
		if unitName:match("%[(MogItNPC[^%]]+)%]") then
			unitName = unitName:gsub("%[(MogIt[^%]]+)%]", "|cff00ccff|H%1|h[MogIt NPC]|h|r");
		else
			unitName = unitName:gsub("%[(MogIt[^%]]+)%]", "|cffcc99ff|H%1|h[MogIt]|h|r");
		end
		print("MogIt Link: " .. unitName)
	else
		print("Unit Name: " .. unitName)
	end
	--SendChatMessage(GetUnitName("target", false), "WHISPER", nil, UnitName("player"))
end

---SYNTAX: ARC:CAST("commID") - i.e., ARC:CAST("teleportEffectsSpell") -- Casts an ArcSpell from Personal Vault
---@param commID CommID
function ARC:CAST(commID)
	if commID and commID ~= "" then
		local spell = Vault.personal.findSpellByID(commID)
		if spell then
			executeSpell(spell.actions, nil, spell.fullName, spell)
		else
			cprint("No spell found with commID '" .. commID .. "' in your Personal Vault.")
		end
	else
		cprint('ARC:API SYNTAX - CAST - Casts a Spell from your Personal Vault.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:CAST("commID")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:CAST("teleportEffectsSpell")')
		print(ADDON_COLOR .. 'Silently Fails if there is no spell by that commID in your personal vault.')
	end
end

-- SYNTAX: ARC:CASTP("commID") - i.e., ARC:CASTP("teleportEffectsSpell") -- Casts an ArcSpell from Phase Vault
---@param commID CommID
function ARC:CASTP(commID) -- Kept for backwards compatibility
	ARC.PHASE:CAST(commID)
end

-- SYNTAX: ARC:IF(key, Command if True, Command if False, [Variables for True], [Variables for False])
---@param key string
---@param command1 string
---@param command2 string
---@param var1 string
---@param var2 string
---@return boolean?
function ARC:IF(key, command1, command2, var1, var2)
	if key then
		if (command1 and command2) and (key ~= "" and command1 ~= "" and command2 ~= "") then
			if var1 == "" then var1 = nil end
			if var2 == "" then var2 = nil end
			command1 = command1 .. (var1 and " " .. var1 or "")
			command2 = command2 .. ((var2 and " " .. var2) or (var1 and " " .. var1) or "")
			if ARC.VAR[key] then cmdWithDotCheck(command1) else cmdWithDotCheck(command2) end
		elseif (command1) and (key ~= "" and command1 ~= "") then
			if ARC.VAR[key] then cmdWithDotCheck(command1) end
		else
			if ARC.VAR[key] then return true; else return false; end
		end
	else
		cprint('ARC:API SYNTAX - IF - Checks if "key" is true, and runs CommandTrue if so, or CommandFalse if not. Optionally you can define a "Var1" to append to both commands.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:IF("key", "CommandTrue", "CommandFalse", "Var1")|r')
		print(ADDON_COLOR .. 'Example 1: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:IF("ToggleLight","aura 243893", "unau 243893")|r')
		print(ADDON_COLOR .. 'Example 2: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:IF("ToggleLight","aura", "unau", "243893")|r')
		print(ADDON_COLOR .. "Both of these will result in the same outcome - If ToggleLight is true, then apply the aura, else unaura.|r")
	end
end

-- SYNTAX: ARC:IFS(key, value to equal, Command if True, Command if False, [Variables for True], [Variables for False])
---@param key string
---@param toEqual string
---@param command1 string
---@param command2 string
---@param var1 string
---@param var2 string
---@return boolean?
function ARC:IFS(key, toEqual, command1, command2, var1, var2)
	if key and toEqual then
		if (command1 and command2) and (command1 ~= "" and command2 ~= "") then
			if var1 == "" then var1 = nil end
			if var2 == "" then var2 = nil end
			command1 = command1 .. (var1 and " " .. var1 or "")
			command2 = command2 .. (var2 and " " .. var2 or var1 and " " .. var1 or "")
			if ARC.VAR[key] == toEqual then cmdWithDotCheck(command1) else cmdWithDotCheck(command2) end
		elseif (command1) and (key ~= "" and command1 ~= "") then
			if ARC.VAR[key] == toEqual then cmdWithDotCheck(command1) end
		else
			if ARC.VAR[key] == toEqual then return true; else return false; end
		end
	else
		cprint('ARC:API SYNTAX - IFS - Checks if "key" is equal to "valueToEqual", and runs CommandTrue if so, or CommandFalse if not. Optionally you can define a "Var1" to append to both commands, the same as ARC:IF.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:IFS("key", "valueToEqual", "CommandTrue", "CommandFalse", "Var1")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:IFS("WhatFruit", "apple", "aura 243893", "unau 243893")|r')
		print(ADDON_COLOR .. 'This example will check if WhatFruit is "apple" and will apply the aura if so.|r')
	end
end

-- SYNTAX: ARC:TOG(key) -- Flips the ArcVar between true and false.
---@param key string
function ARC:TOG(key)
	if key and key ~= "" then
		if ARC.VAR[key] then ARC.VAR[key] = false else ARC.VAR[key] = true end
		dprint(false, key, "= " .. tostring(ARC.VAR[key]))
	else
		cprint('ARC:API SYNTAX - TOG - Toggles an ArcKey (ARC.VAR) between true and false.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:TOG("key")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:TOG("ToggleLight")|r')
		print(ADDON_COLOR .. "Use alongside ARC:IF to make toggle spells.|r")
	end
end

-- SYNTAX: ARC:TOG(key) -- Sets the ArcVar to the specified string.
---@param key string
---@param str string
function ARC:SET(key, str)
	if key == "" then key = nil end
	if str == "" then str = nil end
	if str == "false" then str = false end
	if str == "nil" then str = nil end
	if key and str then
		ARC.VAR[key] = str
		dprint(false, key, "= " .. tostring(ARC.VAR[key]))
	else
		cprint('ARC:API SYNTAX - SET - Set an ArcKey (ARC.VAR) to a specific value.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:SET("key", "value")|r')
		print(ADDON_COLOR .. 'Example 1: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:SET("ToggleLight","2")|r')
		print(ADDON_COLOR .. 'Example 2: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:SET("ToggleLight","3")|r')
		print(ADDON_COLOR .. "This is likely only useful for power-users and super specific spells.|r")
	end
end

---SYNTAX: ARC.PHASE:GET(key) -- Gets the value of an ArcVar by key.
---@param key string
---@return string?
function ARC:GET(key)
	if key and key ~= nil then
		return ARC.VAR[key];
	else
		cprint("ARC:API SYNTAX - GET - Get the value of an ArcKey (ARC.VAR).")
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:GET("key")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:GET("ToggleLight")|r')
	end
end

---Get random argument from varargs
---@param ... any vararg list of arguments
---@return any randomArgument
function ARC:RAND(...)
	if ... then
		return (select(random(select("#", ...)), ...));
	else
		cprint("ARC:API SYNTAX - RAND - Return a random variable.")
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:RAND(...)|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:RAND("Apple","Banana","Cherry")|r')
	end
end

---Save a spell from the phase vault to personal vault. So you can make spells that save other spells.
---@param commID CommID
---@param vocal boolean|string? technically a boolean but string works because we only test if vocal is
function ARC:SAVE(commID, vocal)
	if phaseVault.isSavingOrLoadingAddonData then eprint("Phase Vault was still loading. Please try again in a moment."); return; end
	dprint("Scanning Phase Vault for Spell to Save: " .. commID)
	local spell = phaseVault.findSpellByID(commID)
	local spellIndex = phaseVault.findSpellIndexByID(commID)
	if not spell or not spellIndex then return eprint(("No Spell with CommID %s found in the Phase Vault"):format(ADDON_COLORS.TOOLTIP_CONTRAST:WrapTextInColorCode(commID))) end

	dprint("Found & Saving Spell '" .. commID .. "' (Index: " .. spellIndex .. ") to your Personal Vault.")
	--Vault.personal.saveSpell(spell)
	ns.MainFuncs.downloadToPersonal(spellIndex, vocal)
	ns.MainFuncs.updateSpellLoadRows()
end

---Globally accessible function to stop currently running spells for users to use in scripts.
function ARC:STOPSPELLS()
	ns.Actions.Execute.stopRunningActions()
end

----------- // Phase Variables
ARC.PHASE = {}

---@param var string
---@return string|nil
local function safeGetPhaseVar(var)
	local curPhase = C_Epsilon.GetPhaseId()
	if not SpellCreatorCharacterTable.phaseArcVars[curPhase] then return nil end
	return SpellCreatorCharacterTable.phaseArcVars[curPhase][var]
end

---@param var string
---@param set string
local function safeSetPhaseVar(var, set)
	local curPhase = C_Epsilon.GetPhaseId()
	if not SpellCreatorCharacterTable.phaseArcVars[curPhase] then SpellCreatorCharacterTable.phaseArcVars[curPhase] = {} end
	SpellCreatorCharacterTable.phaseArcVars[curPhase][var] = set
end

---SYNTAX: ARC.PHASE:CAST("commID") - i.e., ARC.PHASE:CAST("teleportEffectsSpell") -- Casts an ArcSpell from Phase Vault
---@param commID CommID
function ARC.PHASE:CAST(commID)
	if commID and commID ~= "" then
		if Vault.phase.isSavingOrLoadingAddonData then eprint("Phase Vault was still loading. Try again in a moment."); return; end

		executePhaseSpell(commID)
	else
		cprint('ARC.PHASE:API SYNTAX - CAST - Casts a Spell from the Phase Vault.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC.PHASE:CASTP("commID")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:CASTP("teleportEffectsSpell")')
		print(ADDON_COLOR .. 'Silently Fails if there is no spell by that commID in the vault.')
	end
end

-- SYNTAX: ARC.PHASE:IF(key, Command if True, Command if False, [Variables for True], [Variables for False])
---@param key string
---@param command1 string
---@param command2 string
---@param var1 string
---@param var2 string
---@return boolean?
function ARC.PHASE:IF(key, command1, command2, var1, var2)
	if key then
		if (command1 and command2) and (key ~= "" and command1 ~= "" and command2 ~= "") then
			if var1 == "" then var1 = nil end
			if var2 == "" then var2 = nil end
			command1 = command1 .. (var1 and " " .. var1 or "")
			command2 = command2 .. ((var2 and " " .. var2) or (var1 and " " .. var1) or "")
			if safeGetPhaseVar(key) then cmdWithDotCheck(command1) else cmdWithDotCheck(command2) end
		elseif (command1) and (key ~= "" and command1 ~= "") then
			if safeGetPhaseVar(key) then cmdWithDotCheck(command1) end
		else
			if safeGetPhaseVar(key) then return true; else return false; end
		end
	else
		cprint('ARC.PHASE:API SYNTAX - IF - Checks if "key", in Phase ARCVARS, is true, and runs CommandTrue if so, or CommandFalse if not. Optionally you can define a "Var1" to append to both commands.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC.PHASE:IF("key", "CommandTrue", "CommandFalse", "Var1")|r')
		print(ADDON_COLOR .. 'Example 1: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:IF("ToggleLight","aura 243893", "unau 243893")|r')
		print(ADDON_COLOR .. 'Example 2: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:IF("ToggleLight","aura", "unau", "243893")|r')
		print(ADDON_COLOR .. "Both of these will result in the same outcome - If ToggleLight is true, then apply the aura, else unaura.|r")
	end
end

---SYNTAX: ARC:IFS(key, value to equal, Command if True, [Command if False], [Variables for True], [Variables for False])
---@param key string
---@param toEqual string
---@param command1 string
---@param command2 string
---@param var1 string
---@param var2 string
---@return boolean?
function ARC.PHASE:IFS(key, toEqual, command1, command2, var1, var2)
	if key and toEqual then
		if (command1 and command2) and (command1 ~= "" and command2 ~= "") then
			if var1 == "" then var1 = nil end
			if var2 == "" then var2 = nil end
			command1 = command1 .. (var1 and " " .. var1 or "")
			command2 = command2 .. (var2 and " " .. var2 or var1 and " " .. var1 or "")
			if safeGetPhaseVar(key) == toEqual then cmdWithDotCheck(command1) else cmdWithDotCheck(command2) end
		elseif (command1) and (key ~= "" and command1 ~= "") then
			if safeGetPhaseVar(key) == toEqual then cmdWithDotCheck(command1) end
		else
			if safeGetPhaseVar(key) == toEqual then return true; else return false; end
		end
	else
		cprint('ARC.PHASE:API SYNTAX - IFS - Checks if "key", in Phase ARCVARS, is equal to "valueToEqual", and runs CommandTrue if so, or CommandFalse if not. Optionally you can define a "Var1" to append to both commands, the same as ARC:IF.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC.PHASE:IFS("key", "valueToEqual", "CommandTrue", "CommandFalse", "Var1")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:IFS("WhatFruit", "apple", "aura 243893", "unau 243893")|r')
		print(ADDON_COLOR .. 'This example will check if WhatFruit is "apple" and will apply the aura if so.|r')
	end
end

---SYNTAX: ARC.PHASE:TOG(key) -- Flips the ArcVar between true and false.
---@param key string
function ARC.PHASE:TOG(key)
	if key and key ~= "" then
		if safeGetPhaseVar(key) then safeSetPhaseVar(key, false) else safeSetPhaseVar(key, true) end
		dprint(false, "Phase Key Set: " .. key, "= " .. tostring(safeGetPhaseVar(key)))
	else
		cprint('ARC.PHASE:API SYNTAX - TOG - Toggles a Phase ArcVar (ARC.PHASEVAR) between true and false.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC.PHASE:TOG("key")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:TOG("ToggleLight")|r')
		print(ADDON_COLOR .. "Use alongside ARC:IF to make toggle spells.|r")
	end
end

---SYNTAX: ARC.PHASE:SET(key, str) -- Sets the ArcVar to the specified string.
---@param key string
---@param str string
function ARC.PHASE:SET(key, str)
	if key == "" then key = nil end
	if str == "" then str = nil end
	if str == "false" then str = false end
	if str == "nil" then str = nil end
	if key and str then
		safeSetPhaseVar(key, str)
		dprint(false, "Phase Key Set: " .. key, "= " .. tostring(safeGetPhaseVar(key)))
	else
		cprint('ARC.PHASE:API SYNTAX - SET - Set a Phase ArcVar (ARC.PHASEVAR) to a specific value.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC.PHASE:SET("key", "value")|r')
		print(ADDON_COLOR .. 'Example 1: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:SET("ToggleLight","2")|r')
		print(ADDON_COLOR .. 'Example 2: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:SET("ToggleLight","3")|r')
		print(ADDON_COLOR .. "This is likely only useful for power-users and super specific spells.|r")
	end
end

---SYNTAX: ARC.PHASE:GET(key) -- Gets the value of a Phase ArcVar by key.
---@param key string
---@return string?
function ARC.PHASE:GET(key)
	if key and key ~= "" then
		return safeGetPhaseVar(key);
	else
		cprint("ARC.PHASE:API SYNTAX - GET - Get the value of a Phase ArcVar (ARC.PHASEVAR).")
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC.PHASE:GET("key")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:GET("ToggleLight")|r')
	end
end

local function retargetPhaseArcVarTable(table)
	ARC.PHASEVAR = table
end

ns.API = {
	retargetPhaseArcVarTable = retargetPhaseArcVarTable,
}
