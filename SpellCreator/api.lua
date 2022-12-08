---@class ns
local ns = select(2, ...)

local Execute = ns.Actions.Execute
local HTML = ns.Utils.HTML
local Vault = ns.Vault

local cmdWithDotCheck = ns.Cmd.cmdWithDotCheck
local ADDON_COLOR = ns.Constants.ADDON_COLOR
local cprint, dprint, eprint = ns.Logging.cprint, ns.Logging.dprint, ns.Logging.eprint
local executeSpell, executePhaseSpell = Execute.executeSpell, Execute.executePhaseSpell

ARC = {}
ARC.VAR = {}

-- SYNTAX: ARC:COMM("command here") - i.e., ARC:COMM("cheat fly") -- KEPT THIS VERSION FOR LEGACY SUPPORT
function ARC:COMM(text)
	if text and text ~= "" then
		cmdWithDotCheck(text)
	else
		cprint('ARC:API SYNTAX - COMM - Sends a Command to the Server.')
		print(ADDON_COLOR..'Function: |cffFFAAAAARC:COMM("command here")|r')
		print(ADDON_COLOR..'Example: |cffFFAAAAARC:COMM("cheat fly")')
	end
end

-- SYNTAX: ARC:CMD("command here") - i.e., ARC:CMD("cheat fly")
function ARC:CMD(text)
	if text and text ~= "" then
		cmdWithDotCheck(text)
	else
		cprint('ARC:API SYNTAX - CMD - Sends a Command to the Server.')
		print(ADDON_COLOR..'Function: |cffFFAAAAARC:CMD("command here")|r')
		print(ADDON_COLOR..'Example: |cffFFAAAAARC:CMD("cheat fly")')
	end
end

-- SYNTAX: ARC:COPY("text to copy, like a URL") - i.e., ARC:COPY("https://discord.gg/C8DZ7AxxcG")
function ARC:COPY(text)
	if text and text ~= "" then
		HTML.copyLink(nil, text)
	else
		cprint('ARC:API SYNTAX - COPY - Opens a Dialog to copy the given text.')
		print(ADDON_COLOR..'Function: |cffFFAAAAARC:COPY("text to copy, like a URL")|r')
		print(ADDON_COLOR..'Example: |cffFFAAAAARC:COPY("https://discord.gg/C8DZ7AxxcG")')
	end
end

-- SYNTAX: ARC:GETNAME() - Gets the Name of the Target and prints it to chat, with MogIt Link Filtering. This allows MogIt links to be copied easily.
function ARC:GETNAME()
	local unitName = GetUnitName("target")
	if unitName:match("MogIt") then
		if unitName:match("%[(MogItNPC[^%]]+)%]") then
			unitName = unitName:gsub("%[(MogIt[^%]]+)%]","|cff00ccff|H%1|h[MogIt NPC]|h|r");
		else
			unitName = unitName:gsub("%[(MogIt[^%]]+)%]","|cffcc99ff|H%1|h[MogIt]|h|r");
		end
		print("MogIt Link: "..unitName)
	else
		print("Unit Name: "..unitName)
	end
	--SendChatMessage(GetUnitName("target", false), "WHISPER", nil, UnitName("player"))
end

-- SYNTAX: ARC:CAST("commID") - i.e., ARC:CAST("teleportEffectsSpell") -- Casts an ArcSpell from Personal Vault
function ARC:CAST(text)
	if text and text ~= "" then
		if SpellCreatorSavedSpells[text] then
			executeSpell(SpellCreatorSavedSpells[text].actions, nil, SpellCreatorSavedSpells[text].fullName, SpellCreatorSavedSpells[text])
		else
			cprint("No spell found with commID '"..text.."' in your Personal Vault.")
		end
	else
		cprint('ARC:API SYNTAX - CAST - Casts a Spell from your Personal Vault.')
		print(ADDON_COLOR..'Function: |cffFFAAAAARC:CAST("commID")|r')
		print(ADDON_COLOR..'Example: |cffFFAAAAARC:CAST("teleportEffectsSpell")')
		print(ADDON_COLOR..'Silently Fails if there is no spell by that commID in your personal vault.')
	end
end

-- SYNTAX: ARC:CASTP("commID") - i.e., ARC:CASTP("teleportEffectsSpell") -- Casts an ArcSpell from Phase Vault
function ARC:CASTP(text)
	if text and text ~= "" then
		if Vault.phase.isSavingOrLoadingAddonData then eprint("Phase Vault was still loading. Try again in a moment."); return; end

		executePhaseSpell(text)
	else
		cprint('ARC:API SYNTAX - CASTP - Casts a Spell from the Phase Vault.')
		print(ADDON_COLOR..'Function: |cffFFAAAAARC:CASTP("commID")|r')
		print(ADDON_COLOR..'Example: |cffFFAAAAARC:CASTP("teleportEffectsSpell")')
		print(ADDON_COLOR..'Silently Fails if there is no spell by that commID in the vault.')
	end
end

-- SYNTAX: ARC:IF(tag, Command if True, Command if False, [Variables for True], [Variables for False])
function ARC:IF(tag, command1, command2, var1, var2)
	if tag then
		if (command1 and command2) and (tag ~= "" and command1 ~= "" and command2 ~= "") then
			if var1 == "" then var1 = nil end
			if var2 == "" then var2 = nil end
			command1 = command1..(var1 and " "..var1 or "")
			command2 = command2..((var2 and " "..var2) or (var1 and " "..var1) or "")
			if ARC.VAR[tag] then cmdWithDotCheck(command1) else cmdWithDotCheck(command2) end
		elseif (command1) and (tag ~= "" and command1 ~= "") then
			if ARC.VAR[tag] then cmdWithDotCheck(command1) end
		else
			if ARC.VAR[tag] then return true; else return false; end
		end
	else
		cprint('ARC:API SYNTAX - IF - Checks if "tag" is true, and runs CommandTrue if so, or CommandFalse if not. Optionally you can define a "Var1" to append to both commands.')
		print(ADDON_COLOR..'Function: |cffFFAAAAARC:IF("tag", "CommandTrue", "CommandFalse", "Var1")|r')
		print(ADDON_COLOR..'Example 1: |cffFFAAAAARC:IF("ToggleLight","aura 243893", "unau 243893")|r')
		print(ADDON_COLOR..'Example 2: |cffFFAAAAARC:IF("ToggleLight","aura", "unau", "243893")|r')
		print(ADDON_COLOR.."Both of these will result in the same outcome - If ToggleLight is true, then apply the aura, else unaura.|r")
	end
end

-- SYNTAX: ARC:IFS(tag, value to equal, Command if True, Command if False, [Variables for True], [Variables for False])
function ARC:IFS(tag, toEqual, command1, command2, var1, var2)
	if tag and toEqual then
		if (command1 and command2) and (command1 ~= "" and command2 ~= "") then
			if var1 == "" then var1 = nil end
			if var2 == "" then var2 = nil end
			command1 = command1..(var1 and " "..var1 or "")
			command2 = command2..(var2 and " "..var2 or var1 and " "..var1 or "")
			if ARC.VAR[tag] == toEqual then cmdWithDotCheck(command1) else cmdWithDotCheck(command2) end
		elseif (command1) and (tag ~= "" and command1 ~= "") then
			if ARC.VAR[tag] then cmdWithDotCheck(command1) end
		else
			if ARC.VAR[tag] == toEqual then return true; else return false; end
		end
	else
		cprint('ARC:API SYNTAX - IFS - Checks if "tag" is equal to "valueToEqual", and runs CommandTrue if so, or CommandFalse if not. Optionally you can define a "Var1" to append to both commands, the same as ARC:IF.')
		print(ADDON_COLOR..'Function: |cffFFAAAAARC:IFS("tag", "valueToEqual", "CommandTrue", "CommandFalse", "Var1")|r')
		print(ADDON_COLOR..'Example 1: |cffFFAAAAARC:IFS("WhatFruit", "apple", "aura 243893", "unau 243893")|r')
		print(ADDON_COLOR..'This example will check if WhatFruit is "apple" and will apply the aura if so.|r')
	end
end

-- SYNTAX: ARC:TOG(tag) -- Flips the ArcVar between true and false.
function ARC:TOG(tag)
	if tag and tag ~= "" then
		if ARC.VAR[tag] then ARC.VAR[tag] = false else ARC.VAR[tag] = true end
		dprint(false, tag, "= "..tostring(ARC.VAR[tag]))
	else
		cprint('ARC:API SYNTAX - TOG - Toggles an ArcTag (ARC.VAR) between true and false.')
		print(ADDON_COLOR..'Function: |cffFFAAAAARC:TOG("tag")|r')
		print(ADDON_COLOR..'Example: |cffFFAAAAARC:TOG("ToggleLight")|r')
		print(ADDON_COLOR.."Use alongside ARC:IF to make toggle spells.|r")
	end
end

-- SYNTAX: ARC:TOG(tag) -- Sets the ArcVar to the specified string.
function ARC:SET(tag, str)
	if tag == "" then tag = nil end
	if str == "" then str = nil end
	if tag and str then
		ARC.VAR[tag] = str
		dprint(false, tag, "= "..tostring(ARC.VAR[tag]))
	else
		cprint('ARC:API SYNTAX - SET - Set an ArcTag (ARC.VAR) to a specific value.')
		print(ADDON_COLOR..'Function: |cffFFAAAAARC:SET("tag", "value")|r')
		print(ADDON_COLOR..'Example 1: |cffFFAAAAARC:SET("ToggleLight","2")|r')
		print(ADDON_COLOR..'Example 2: |cffFFAAAAARC:SET("ToggleLight","3")|r')
		print(ADDON_COLOR.."This is likely only useful for power-users and super specific spells.|r")
	end
end

function ARC:GET(tag)
	if tag and tag ~= nil then
		return ARC.VAR[tag];
	else
		cprint("ARC:API SYNTAX - GET - Get the value of an ArcTag (ARC.VAR).")
		print(ADDON_COLOR..'Function: |cffFFAAAAARC:GET("tag")|r')
		print(ADDON_COLOR..'Example 1: |cffFFAAAAARC:GET("ToggleLight")|r')
	end
end

function ARC:RAND(...)
	if ... then
		return (select(random(select("#", ...)), ...));
	else
		cprint("ARC:API SYNTAX - RAND - Return a random variable.")
		print(ADDON_COLOR..'Function: |cffFFAAAAARC:RAND(...)|r')
		print(ADDON_COLOR..'Example 1: |cffFFAAAAARC:RAND("Apple","Banana","Cherry")|r')
	end
end
