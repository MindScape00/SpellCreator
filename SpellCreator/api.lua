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

local Aura = ns.Utils.Aura

local cmdWithDotCheck = Cmd.cmdWithDotCheck
local cmd = Cmd.cmd
local ADDON_COLORS = Constants.ADDON_COLORS
local ADDON_COLOR = Constants.ADDON_COLOR
local cprint, dprint, eprint = Logging.cprint, Logging.dprint, Logging.eprint
local executeSpell, executePhaseSpell = Execute.executeSpell, Execute.executePhaseSpell


---Consumes the first variable of a vararg if it's a table, returning the rest as an array of the variables. Make sure to unpack them.
---@param ... unknown
---@return table
local function consumeSelfTable(...)
	local varTable = { ... }
	if #varTable > 1 then
		if type(varTable[1]) == "table" then
			tremove(varTable, 1)
		end
	end
	return (varTable)
end

local function consumeSomeTable(tab, ...)
	local varTable = { ... }
	if #varTable > 1 then
		local entryOne = varTable[1]
		if type(entryOne) == "table" then
			if entryOne == tab then
				tremove(varTable, 1)
			end
		end
	end
	return varTable
end

local function wrapToEvalFinalVal(callback, tableToEat)
	if not tableToEat then tableToEat = ARC end
	return function(self, ...)
		return callback(unpack(consumeSomeTable(tableToEat, self, ...)))
	end
end

-------------------
--#region ARC VARS & STANDARD ARC API
-------------------

---@param id number spell ID
local function TOGAURA(id)
	--id = unpack(consumeSelfTable(self, id))
	Aura.toggleAura(id)
end
ARC.TOGAURA = wrapToEvalFinalVal(TOGAURA)

---@param key string
local function UNLOCK(key)
	return SavedVariables.unlocks.unlock(key)
end
ARC.UNLOCK = wrapToEvalFinalVal(UNLOCK)

-- SYNTAX: ARC:CMD("command here") - i.e., ARC:CMD("cheat fly")
-- SYNTAX: ARC:COMM("command here") - i.e., ARC:COMM("cheat fly") -- KEPT THIS VERSION FOR LEGACY SUPPORT
---@param text string
local function CMD(text)
	if text and text ~= "" then
		cmdWithDotCheck(text)
	else
		cprint('ARC:API SYNTAX - COMM - Sends a Command to the Server.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:COMM("command here")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:COMM("cheat fly")')
	end
end
ARC.CMD = wrapToEvalFinalVal(CMD)
ARC.COMM = wrapToEvalFinalVal(CMD)

-- SYNTAX: ARC:COPY("text to copy, like a URL") - i.e., ARC:COPY("https://discord.gg/C8DZ7AxxcG")
---@param text string
local function COPY(text)
	if text and text ~= "" then
		HTML.copyLink(nil, text)
	else
		cprint('ARC:API SYNTAX - COPY - Opens a Dialog to copy the given text.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:COPY("text to copy, like a URL")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:COPY("https://discord.gg/C8DZ7AxxcG")')
	end
end
ARC.COPY = wrapToEvalFinalVal(COPY)

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

---SYNTAX: ARC:CAST("commID", input1, input2, ...) - i.e., ARC:CAST("teleportEffectsSpell", "TelePoint2") -- Casts an ArcSpell from Personal Vault, with the @input1@ as "TelePoint2".
---@param commID CommID
---@param ... any spell input args
local function CAST(commID, ...)
	local spell

	if type(commID) == "table" then
		-- we passed a real spell object, use that instead of a lookup
		spell = commID
	elseif type(commID) == "string" and commID ~= "" then
		spell = Vault.personal.findSpellByID(commID)
	else
		cprint('ARC:API SYNTAX - CAST - Casts a Spell from your Personal Vault.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:CAST("commID", input1, input2, ...)|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:CAST("teleportEffectsSpell")')
		return false
	end

	if spell then
		return executeSpell(spell.actions, nil, spell.fullName, spell, ...)
	else
		cprint("No spell found with commID '" .. commID .. "' in your Personal Vault.")
		return false
	end

end
ARC.CAST = wrapToEvalFinalVal(CAST)

---SYNTAX: ARC:CASTIMPORT("importString", input1, input2, ...) -- Casts an ArcSpell from an Import String.
---@param importString string
---@param ... any spell input args
local function CAST_IMPORT(importString, ...)
	local spell

	if type(importString) == "string" and importString ~= "" then
		spell = ns.UI.ImportExport.getDataFromImportString(importString)
	else
		cprint('ARC:API SYNTAX - CASTIMPORT - Casts a Spell from an Import String.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:CAST("importString", input1, input2, ...)|r')
		return false
	end

	if spell then
		return executeSpell(spell.actions, nil, spell.fullName, spell, ...)
	else
		cprint("ARC:API - Cast_Import Error: Invalid ArcSpell data.")
		return false
	end

end
ARC.CASTIMPORT = wrapToEvalFinalVal(CAST_IMPORT)

---Stop currently running instances of a spell by CommID
---@param commID any
local function STOP(commID)
	if commID and commID ~= "" then
		ns.Actions.Execute.cancelSpellByCommID(commID)
	else
		cprint('ARC:API SYNTAX - STOP - Stops all currently running instances of a spell by CommID.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:STOP("commID")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:STOP("teleportEffectsSpell")')
		print(ADDON_COLOR .. 'Silently fails if there is no spell by that commID currently running.')
	end
end
ARC.STOP = wrapToEvalFinalVal(STOP)

-- SYNTAX: ARC:IF(key, Command if True, Command if False, [Variables for True], [Variables for False])
---@param key string
---@param command1 string
---@param command2 string
---@param var1 string
---@param var2 string
---@return boolean?
local function IF(key, command1, command2, var1, var2)
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
ARC.IF = wrapToEvalFinalVal(IF)

-- SYNTAX: ARC:IFS(key, value to equal, Command if True, Command if False, [Variables for True], [Variables for False])
---@param key string
---@param toEqual string
---@param command1 string
---@param command2 string
---@param var1 string
---@param var2 string
---@return boolean?
local function IFS(key, toEqual, command1, command2, var1, var2)
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
		cprint(
			'ARC:API SYNTAX - IFS - Checks if "key" is equal to "valueToEqual", and runs CommandTrue if so, or CommandFalse if not. Optionally you can define a "Var1" to append to both commands, the same as ARC:IF.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:IFS("key", "valueToEqual", "CommandTrue", "CommandFalse", "Var1")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:IFS("WhatFruit", "apple", "aura 243893", "unau 243893")|r')
		print(ADDON_COLOR .. 'This example will check if WhatFruit is "apple" and will apply the aura if so.|r')
	end
end
ARC.IFS = wrapToEvalFinalVal(IFS)

-- SYNTAX: ARC:TOG(key) -- Flips the ArcVar between true and false.
---@param key string
local function TOG(key)
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
ARC.TOG = wrapToEvalFinalVal(TOG)

-- SYNTAX: ARC:SET(key, string) -- Sets the ArcVar to the specified string.
---@param key string
---@param str string
local function SET(key, str)
	if key == "" then key = nil end
	if str == "" then str = nil end
	if str == "false" then str = false end
	if str == "nil" then str = nil end
	if key then
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
ARC.SET = wrapToEvalFinalVal(SET)

---SYNTAX: ARC:GET(key) -- Gets the value of an ArcVar by key.
---@param key string
---@return string?
local function GET(key)
	if key and key ~= nil then
		return ARC.VAR[key];
	else
		cprint("ARC:API SYNTAX - GET - Get the value of an ArcKey (ARC.VAR).")
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:GET("key")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:GET("ToggleLight")|r')
	end
end
ARC.GET = wrapToEvalFinalVal(GET)

---Get random argument from varargs
---@param ... any vararg list of arguments
---@return any randomArgument
local function RAND(...)
	if ... then
		return (select(random(select("#", ...)), ...));
	else
		cprint("ARC:API SYNTAX - RAND - Return a random variable.")
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:RAND(...)|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC:RAND("Apple","Banana","Cherry")|r')
	end
end
ARC.RAND = wrapToEvalFinalVal(RAND)

---Get random argument from a weighted pool
---@param pool WeightedArgPool
---@return any randomArgument
local function RANDW(pool)
	if not pool or type(pool) ~= "table" then
		cprint("ARC:API SYNTAX - RANDW - Return a random variable from a WeightedArgPool Table/Array.")
		cprint(
			"WeightedArgPool should be an array with sub-arrays for each item. Each item should have position 1 as the number for weighting, and position 2 as the return value/variable if selected.")
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC:RANDW(WeightedArgPool)|r')
		print(ADDON_COLOR ..
			'Example: ' ..
			ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() ..
			'ARC:RANDW({{1,"Apple"},{5,"Banana"},{1,"Cherry"}})|r' .. ADDON_COLOR .. ' to select a random fruit, but weighted to select Banana usually.')
		return
	else
		return ns.Utils.Data.getRandomWeightedArg(pool)
	end
end
ARC.RANDW = wrapToEvalFinalVal(RANDW)

---Globally accessible function to stop currently running spells for users to use in scripts.
function ARC:STOPSPELLS()
	ns.Actions.Execute.stopRunningActions()
end

-------------------
--#endregion
-------------------

-------------------
--#region ARC PHASE
-------------------

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

-- holder for the phase funcs so they don't name conflict lol - #lazy
local PHASE = {}

---Save a spell from the phase vault to personal vault. So you can make spells that save other spells.
---@param commID CommID
---@param vocal boolean|string? technically a boolean but string works because we only test if vocal is
function PHASE.SAVE(commID, vocal)
	if phaseVault.isSavingOrLoadingAddonData then
		eprint("Phase Vault was still loading. Please try again in a moment."); return;
	end
	dprint("Scanning Phase Vault for Spell to Save: " .. commID)
	local spell = phaseVault.findSpellByID(commID)
	local spellIndex = phaseVault.findSpellIndexByID(commID)
	if not spell or not spellIndex then return eprint(("No Spell with CommID %s found in the Phase Vault"):format(ADDON_COLORS.TOOLTIP_CONTRAST:WrapTextInColorCode(commID))) end

	dprint("Found & Saving Spell '" .. commID .. "' (Index: " .. spellIndex .. ") to your Personal Vault.")
	-- convert vocal to true boolean
	if vocal then vocal = true end

	--Vault.personal.saveSpell(spell)
	ns.MainFuncs.downloadToPersonal(spellIndex, vocal)
	ns.MainFuncs.updateSpellLoadRows(true)
end

ARC.PHASE.SAVE = wrapToEvalFinalVal(PHASE.SAVE, ARC.PHASE)

-- For backwards compatibility, keeping ARC.SAVE around.
ARC.SAVE = ARC.PHASE.SAVE

---SYNTAX: ARC.PHASE:CAST("commID", bypassCD, ...) - i.e., ARC.PHASE:CAST("teleportEffectsSpell", true) -- Casts an ArcSpell from Phase Vault, bypassing cooldowns
---@param commID CommID
---@param bypassCD boolean? true to bypass triggering the spell's cooldown
---@param ... any spell inputs
function PHASE.CAST(commID, bypassCD, ...)
	if commID and commID ~= "" then
		if phaseVault.isSavingOrLoadingAddonData then
			eprint("Phase Vault was still loading. Try again in a moment."); return;
		end

		executePhaseSpell(commID, bypassCD, ...)
	else
		cprint('ARC.PHASE:API SYNTAX - CAST - Casts a Spell from the Phase Vault.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC.PHASE:CASTP("commID")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:CASTP("teleportEffectsSpell")')
		print(ADDON_COLOR .. 'Silently Fails if there is no spell by that commID in the vault.')
	end
end

ARC.PHASE.CAST = wrapToEvalFinalVal(PHASE.CAST, ARC.PHASE)

---SYNTAX: ARC:CASTP("commID", bypassCD, ...) - i.e., ARC.PHASE:CAST("teleportEffectsSpell", true) -- Casts an ArcSpell from Phase Vault, bypassing cooldowns; Kept for backwards compatibility
ARC.CASTP = wrapToEvalFinalVal(PHASE.CAST, ARC)

-- SYNTAX: ARC.PHASE:IF(key, Command if True, Command if False, [Variables for True], [Variables for False])
---@param key string
---@param command1 string
---@param command2 string
---@param var1 string
---@param var2 string
---@return boolean?
function PHASE.IF(key, command1, command2, var1, var2)
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
		cprint(
			'ARC.PHASE:API SYNTAX - IF - Checks if "key", in Phase ARCVARS, is true, and runs CommandTrue if so, or CommandFalse if not. Optionally you can define a "Var1" to append to both commands.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC.PHASE:IF("key", "CommandTrue", "CommandFalse", "Var1")|r')
		print(ADDON_COLOR .. 'Example 1: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:IF("ToggleLight","aura 243893", "unau 243893")|r')
		print(ADDON_COLOR .. 'Example 2: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:IF("ToggleLight","aura", "unau", "243893")|r')
		print(ADDON_COLOR .. "Both of these will result in the same outcome - If ToggleLight is true, then apply the aura, else unaura.|r")
	end
end

ARC.PHASE.IF = wrapToEvalFinalVal(PHASE.IF, ARC.PHASE)


---SYNTAX: ARC:IFS(key, value to equal, Command if True, [Command if False], [Variables for True], [Variables for False])
---@param key string
---@param toEqual string
---@param command1 string
---@param command2 string
---@param var1 string
---@param var2 string
---@return boolean?
function PHASE.IFS(key, toEqual, command1, command2, var1, var2)
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
		cprint(
			'ARC.PHASE:API SYNTAX - IFS - Checks if "key", in Phase ARCVARS, is equal to "valueToEqual", and runs CommandTrue if so, or CommandFalse if not. Optionally you can define a "Var1" to append to both commands, the same as ARC:IF.')
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC.PHASE:IFS("key", "valueToEqual", "CommandTrue", "CommandFalse", "Var1")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:IFS("WhatFruit", "apple", "aura 243893", "unau 243893")|r')
		print(ADDON_COLOR .. 'This example will check if WhatFruit is "apple" and will apply the aura if so.|r')
	end
end

ARC.PHASE.IFS = wrapToEvalFinalVal(PHASE.IFS, ARC.PHASE)

---SYNTAX: ARC.PHASE:TOG(key) -- Flips the ArcVar between true and false.
---@param key string
function PHASE.TOG(key)
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

ARC.PHASE.TOG = wrapToEvalFinalVal(PHASE.TOG, ARC.PHASE)

---SYNTAX: ARC.PHASE:SET(key, str) -- Sets the ArcVar to the specified string.
---@param key string
---@param str string
function PHASE.SET(key, str)
	if key == "" then key = nil end
	if str == "" then str = nil end
	if str == "false" then str = false end
	if str == "nil" then str = nil end
	if key then
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

ARC.PHASE.SET = wrapToEvalFinalVal(PHASE.SET, ARC.PHASE)

---SYNTAX: ARC.PHASE:GET(key) -- Gets the value of a Phase ArcVar by key.
---@param key string
---@return string?
function PHASE.GET(key)
	if key and key ~= "" then
		return safeGetPhaseVar(key);
	else
		cprint("ARC.PHASE:API SYNTAX - GET - Get the value of a Phase ArcVar (ARC.PHASEVAR).")
		print(ADDON_COLOR .. 'Function: ' .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. 'ARC.PHASE:GET("key")|r')
		print(ADDON_COLOR .. 'Example: ' .. ADDON_COLORS.TOOLTIP_EXAMPLE:GenerateHexColorMarkup() .. 'ARC.PHASE:GET("ToggleLight")|r')
	end
end

ARC.PHASE.GET = wrapToEvalFinalVal(PHASE.GET, ARC.PHASE)

local function retargetPhaseArcVarTable(table)
	ARC.PHASEVAR = table
end

-- alias for Epsi functions
ARC.PHASE.IsMember = C_Epsilon.IsMember
ARC.PHASE.IsOfficer = C_Epsilon.IsOfficer
ARC.PHASE.IsOwner = C_Epsilon.IsOwner
ARC.PHASE.GetPhaseId = C_Epsilon.GetPhaseId
ARC.PHASE.IsDM = function() return C_Epsilon.IsDM end

-------------------
--#endregion
-------------------

-------------------
--#region ARC LOCATIONS
-------------------

local LOCATIONS = {}

ARC.LOCATIONS = {}
ARC.LOCATIONS.locs = {}

local function retargetSavedLocationsTable(table)
	ARC.LOCATIONS.locs = table
end

function LOCATIONS.SAVE(key)
	ARC.LOCATIONS.locs[key] = { C_Epsilon.GetPosition() }
end

ARC.LOCATIONS.SAVE = wrapToEvalFinalVal(LOCATIONS.SAVE, ARC.LOCATIONS)

function LOCATIONS.LOAD(key)
	return strjoin(" ", unpack(ARC.LOCATIONS.locs[key]))
end

ARC.LOCATIONS.LOAD = wrapToEvalFinalVal(LOCATIONS.LOAD, ARC.LOCATIONS)


function LOCATIONS.GOTO(key)
	Cmd.cmd("worldport " .. strjoin(" ", unpack(ARC.LOCATIONS.locs[key])))
end

ARC.LOCATIONS.GOTO = wrapToEvalFinalVal(LOCATIONS.GOTO, ARC.LOCATIONS)


ARC.LOCATIONS.GetPosition = C_Epsilon.GetPosition

-------------------
--#endregion
-------------------

-------------------
--#region Extended API
-------------------

ARC.XAPI = {}

ARC.XAPI.sparks = {}
ARC.XAPI.Sparks = ARC.XAPI.sparks -- alternative access for continuity but also keeping the old one for backwards compatibility
do
	-- function addPopupTriggerToPhaseData(commID: string, radius: number, style: integer, x: number, y: number, z: number, colorHex: any, mapID: integer, options: PopupTriggerOptions, overwriteIndex: any)
	ARC.XAPI.sparks.addPopupTriggerToPhaseData = wrapToEvalFinalVal(ns.UI.SparkPopups.SparkPopups.addPopupTriggerToPhaseData, ARC.XAPI.sparks)

	-- function getSparkLoadingStatus() -> boolean
	ARC.XAPI.sparks.getSparkLoadingStatus = ns.UI.SparkPopups.SparkPopups.getSparkLoadingStatus

	-- function removeTriggerFromPhaseDataByMapAndIndex(mapID: integer, index: integer, callback: function)
	ARC.XAPI.sparks.removeTriggerFromPhaseDataByMapAndIndex = wrapToEvalFinalVal(ns.UI.SparkPopups.SparkPopups.removeTriggerFromPhaseDataByMapAndIndex, ARC.XAPI.sparks)

	-- function savePopupTriggersToPhaseData()
	ARC.XAPI.sparks.savePopupTriggersToPhaseData = wrapToEvalFinalVal(ns.UI.SparkPopups.SparkPopups.savePopupTriggersToPhaseData, ARC.XAPI.sparks)

	-- function triggerSparkCooldownVisual(commID: string, cooldownTime: number)
	ARC.XAPI.sparks.triggerSparkCooldownVisual = wrapToEvalFinalVal(ns.UI.SparkPopups.SparkPopups.triggerSparkCooldownVisual, ARC.XAPI.sparks)
end

ARC.XAPI.UI = {}
do
	-- function raidWarning(text: any, r: any, g: any, b: any)
	ARC.XAPI.UI.raidWarning = wrapToEvalFinalVal(ns.Logging.raidWarning, ARC.XAPI.UI)

	-- function uiErrorMessage(text: any, r: any, g: any, b: any, voiceID: any, soundKitID: any)
	ARC.XAPI.UI.errorMessage = wrapToEvalFinalVal(ns.Logging.uiErrorMessage, ARC.XAPI.UI)

	-- function showGenericConfirmation(text: string, callback?: fun(), insertedFrame?: frame) -> dialogFrame
	ARC.XAPI.UI.showConfirmationDialog = wrapToEvalFinalVal(ns.UI.Popups.showGenericConfirmation, ARC.XAPI.UI)

	-- function showCustomGenericConfirmation(customData: GenericInputCustomData, insertedFrame?: frame)
	ARC.XAPI.UI.showCustomDialog = wrapToEvalFinalVal(ns.UI.Popups.showCustomGenericConfirmation, ARC.XAPI.UI)

	-- function showCustomGenericInputBox(customData: GenericInputCustomData, insertedFrame?: frame)
	ARC.XAPI.UI.showCustomInputBox = wrapToEvalFinalVal(ns.UI.Popups.showCustomGenericInputBox, ARC.XAPI.UI)

	--[[
		castbar: {
				function showCastBar(length: number, text: string, spellData: VaultSpell, channeled: boolean, showIcon: boolean, showShield: boolean)
				function stopCastingBars(commID: any)
			}
		--]]
	ARC.XAPI.UI.castbar = ns.UI.Castbar
end

ARC.XAPI.Cooldowns = {}
do
	-- function addSpellCooldown(commID: string, cooldownTime: number, phase?: integer, noVisual?: boolean)
	ARC.XAPI.Cooldowns.addSpellCooldown = wrapToEvalFinalVal(ns.Actions.Cooldowns.addSpellCooldown, ARC.XAPI.Cooldowns)

	-- function isSpellOnCooldown(commID: string, phase?: integer) -> 1. number|false, 2. number|nil
	ARC.XAPI.Cooldowns.isSpellOnCooldown = wrapToEvalFinalVal(ns.Actions.Cooldowns.isSpellOnCooldown, ARC.XAPI.Cooldowns)

	-- function triggerCooldownVisuals(commID: string, cooldownTime: number, phase?: integer)
	ARC.XAPI.Cooldowns.triggerCooldownVisuals = wrapToEvalFinalVal(ns.Actions.Cooldowns.triggerCooldownVisuals, ARC.XAPI.Cooldowns)

	-- function clearOldCooldowns(forceReset: any)
	ARC.XAPI.Cooldowns.clearOldCooldowns = wrapToEvalFinalVal(ns.Actions.Cooldowns.clearOldCooldowns, ARC.XAPI.Cooldowns)
end

ARC.XAPI.Phase = {
	IsMember = ARC.PHASE.IsMember,
	IsOfficer = ARC.PHASE.IsOfficer,
	IsOwner = ARC.PHASE.IsOwner,
	GetPhaseId = ARC.PHASE.GetPhaseId,
	IsDM = ARC.PHASE.IsDM,
}

ARC.XAPI.Items = {}
ARC.XAPI.Items.LinkSpell = wrapToEvalFinalVal(function(commID, itemID, isPhase)
	local phaseType = (isPhase and Constants.VAULT_TYPE.PHASE or Constants.VAULT_TYPE.PERSONAL)
	local spell = ns.Vault[string.lower(phaseType)].findSpellByID(commID)
	if spell then
		ns.UI.ItemIntegration.scripts.LinkItemToSpell(spell, itemID, phaseType, true)
	else
		ns.Logging.uiErrorMessage(("ArcSpell %s not found in your %s Vault, could not link to item"):format(ns.Utils.Tooltip.genContrastText(commID), (isPhase and "Phase" or "Personal")))
	end
end, ARC.XAPI.Items)

ARC.XAPI.Items.UnlinkSpell = wrapToEvalFinalVal(function(commID, itemID, isPhase)
	local phaseType = (isPhase and Constants.VAULT_TYPE.PHASE or Constants.VAULT_TYPE.PERSONAL)
	local spell = ns.Vault[string.lower(phaseType)].findSpellByID(commID)
	if spell then
		ns.UI.ItemIntegration.scripts.LinkItemToSpell(spell, itemID, phaseType, true)
	else
		ns.Logging.uiErrorMessage(("ArcSpell %s not found in your %s Vault, could not unlink from item"):format(ns.Utils.Tooltip.genContrastText(commID), (isPhase and "Phase" or "Personal")))
	end
end, ARC.XAPI.Items)


ARC.XAPI.GetPosition = ARC.LOCATIONS.GetPosition                                   -- no wrap needed, only returns current position data (x, y, z, mapID)
ARC.XAPI.HasAuraID = wrapToEvalFinalVal(ns.Utils.Aura.checkPlayerAuraID, ARC.XAPI) -- function checkPlayerAuraID(wantedID: any)
ARC.XAPI.HasAura = wrapToEvalFinalVal(ns.Utils.Aura.checkPlayerAuraID, ARC.XAPI)   -- function checkPlayerAuraID(wantedID: any)
ARC.XAPI.HasItem = wrapToEvalFinalVal(function(itemID)
	local itemCount = GetItemCount(itemID)
	return (itemCount > 0 and itemCount or false)
end, ARC.XAPI)
ARC.XAPI.HasItems = wrapToEvalFinalVal(function(...)
	local items = { ... }
	for _, itemID in ipairs(items) do
		local itemCount = GetItemCount(itemID)
		if not itemCount or itemCount <= 0 then
			return false
		end
	end
	return true
end, ARC.XAPI)
ARC.XAPI.ToggleAura = wrapToEvalFinalVal(Aura.toggleAura, ARC.XAPI) -- function toggleAura(spellID: any)

-- ArcSpell Helpers
ARC.XAPI.HasArcSpell = wrapToEvalFinalVal(function(commID)
	local spell = Vault.personal.findSpellByID(commID)
	if spell then return true else return false end
end, ARC.XAPI)

ARC.XAPI.GetArcSpell = wrapToEvalFinalVal(function(commID, isPhase)
	local phaseType = (isPhase and Constants.VAULT_TYPE.PHASE or Constants.VAULT_TYPE.PERSONAL)
	local spell = ns.Vault[string.lower(phaseType)].findSpellByID(commID)
	return spell
end, ARC.XAPI)

-- Not wrapping eval final val because these are dev functions for other addons, and not really for general player use. Incorrect usage should just be slapped instead.
ARC.XAPI.Actions = {
	registerActionData = ns.Actions.Data.registerActionData,

	-- AddOns should normally use ARC.RegisterAction() instead. This is for abnormal usages.
	getActionList = ns.UI.SpellRowAction.getActionList,
	addNewAction = ns.UI.SpellRowAction.addNewAction,
	addMenuCategoryFull = ns.UI.SpellRowAction.addMenuFullCategory
}

-- Not wrapping because too much work. Meh.
ARC.XAPI.Quickcast = ns.UI.Quickcast.Quickcast.API
--[[
		function FindBook(name: string) -> QuickcastBook|nil
		function NewBook(name: string, style: string) -> QuickcastBook, QuickcastPage
		function NewPage(book: string|QuickcastBook, spells: string[], profile: string) -> QuickcastPage|nil, newPageIndex: number?
		function GetPage(book: string|QuickcastBook, index: any) -> QuickcastPage|nil
		function SetBookStyle(book: string|QuickcastBook, styleName: string)
		function GotoPage(book: string|QuickcastBook, pageNum: integer)
	--]]

---@param category string
---@param key string
---@param commandType "server"|string|any
---@param name string
---@param actionData FunctionActionTypeData|ServerActionTypeData
---@return boolean|nil
ARC.RegisterAction = function(category, key, commandType, name, actionData)
	if not category or not key or not commandType or not name or not actionData then
		error(
			[[Usage Syntax: ARC.RegisterAction("category name", "action_key", "script|server", "Action Display Name", actionData) - See Models\ActionType.lua for table class structure, and Actions\Data.lua for baseline actions as examples.]])
	end
	if ns.Actions.Data.registerActionData(key, commandType, name, category, actionData) then
		ns.UI.SpellRowAction.addNewAction(category, key)
		return true
	else
		return false
	end
end

ARC.ImportSpell = ns.UI.ImportExport.importSpell

--[[
	--ARC.RegisterAction Examples:

	ARC.RegisterAction("DiceMaster (Example)", "dm_RollDice1", "script", "Roll Dice 1", {
		command = function(vars) print("Roll a dice with " .. vars .. " sides") end,
		description = "Example DiceMaster to roll a dm dice idk.",
		dataName = "Number of Sides",
		inputDescription = "how many number of sides you want the dice to have.",
		example = "Roll some Dicey Master Dice idk",
		revert = nil,
		selfAble = false,
	})
	ARC.RegisterAction("DiceMaster (Example)", "dm_RollDice2", "script", "Roll Dice 2", {
		command = function(vars) print("2-Roll a dice with " .. vars .. " sides") end,
		description = "Example2 DiceMaster to roll a dm dice idk.",
		dataName = "Number of Sides2",
		inputDescription = "2how many number of sides you want the dice to have.",
		example = "2Roll some Dicey Master Dice idk",
		revert = nil,
		selfAble = false,
	})
--]]

-------------------
--#endregion
-------------------

ns.API = {
	retargetPhaseArcVarTable = retargetPhaseArcVarTable,
	retargetSavedLocationsTable = retargetSavedLocationsTable,

	safeSetPhaseVar = safeSetPhaseVar,
	safeGetPhaseVar = safeGetPhaseVar,
}
