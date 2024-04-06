---@class ns
local ns = select(2, ...)

local cmdWithDotCheck = ns.Cmd.cmdWithDotCheck
local ADDON_COLOR = ns.Constants.ADDON_COLOR
local ADDON_COLORS = ns.Constants.ADDON_COLORS
local cprint = ns.Logging.cprint

local AceConsole = ns.Libs.AceConsole
local DataUtils = ns.Utils.Data

local slashCommands = {
	arcanum = {
		cmd = "arcanum [$commID]",
		desc = {
			"Cast an ArcSpell by it's command ID you gave it (aka CommID),",
			"or open the Spell Forge UI if left blank.",
		},
	},
	sf = {
		cmd = "sf [$commID]",
		desc = "Shorter Alternative to /arcanum.",
	},
	arc = {
		cmd = "arc ..",
	},
	debug = {
		cmd = "sfdebug",
		desc = "List all the Debug Commands. WARNING: These are for DEBUG, not to play with and complain something broke.",
	}
}

local arcCommands = {
	phase = {
		cmd = "phase ...",
		desc = ("ARC:API Phase Commands - Use %s to see more."):format(ADDON_COLORS.TOOLTIP_CONTRAST:WrapTextInColorCode("/arc phase")),
		subcommands = {
			["if"] = {
				cmd = "phase if $key $commandTrue [$commandFalse] [$varTrue] [$varFalse]",
				desc = {
					"Checks if the $key, in Phase ArcVars, is true and runs the $commandTrue (with $varTrue added if given),",
					"or $commandFalse if not true and $commandFalse was given. (with $varFalse added ",
					"if given, or $varTrue added if given and $varFalse was not). ",
				},
				fnTable = "PHASE",
				fn = "IF",
				numArgs = 5,
			},
			ifs = {
				cmd = "phase ifs $key $check $commandTrue [$commandFalse] [$varTrue] [$varFalse]",
				desc = {
					"Same as ARC:IF but checks if the $key is equal to $check instead of just testing if it's true.",
				},
				fnTable = "PHASE",
				fn = "IFS",
				numArgs = 6,
			},
			tog = {
				cmd = "phase tog $key",
				desc = "Toggles the $key in the Phase ArcVars between true & false, used with ARC.PHASE:IF (/arc phase if).",
				fn = "TOG",
				fnTable = "PHASE",
				numArgs = 1,
			},
			set = {
				cmd = "phase set $key $value",
				desc = "Sets the $key, in Phase ArcVars, to a specific \"$value\". Use with ARC.PHASE:GET or ARC.PHASE:IFS.",
				fn = "SET",
				fnTable = "PHASE",
				numArgs = 2,
			},
		}
	},
	cast = {
		cmd = "cast $commID, $input1, $input2, ... $input8",
		desc = "Cast from your personal vault, same as /arcanum or /sf, with optional Spell Inputs.",
		fn = "CAST",
		numArgs = 1,
	},
	castp = {
		cmd = "castp $commID, $input1, $input2, ... $input8",
		desc = "Cast a spell from the Phase Vault if it exists, with optional Spell Inputs.",
		fn = "CASTP",
		numArgs = 1,
	},
	cmd = {
		cmd = "cmd $command",
		desc = "Runs the server $command specified (i.e., 'cheat fly').",
		fn = "CMD",
		numArgs = 1,
	},
	["if"] = {
		cmd = "if $key $commandTrue [$commandFalse] [$varTrue] [$varFalse]",
		desc = {
			"Checks if the $key is true and runs the $commandTrue (with $varTrue added if given),",
			"or $commandFalse if not true and $commandFalse was given. (with $varFalse added ",
			"if given, or $varTrue added if given and $varFalse was not). ",
		},
		fn = "IF",
		numArgs = 5,
	},
	ifs = {
		cmd = "ifs $key $check $commandTrue [$commandFalse] [$varTrue] [$varFalse]",
		desc = {
			"Same as ARC:IF but checks if the $key is equal to $check instead of just testing if it's true.",
		},
		fn = "IFS",
		numArgs = 6,
	},
	tog = {
		cmd = "tog $key",
		desc = "Toggles the $key between true & false, used with ARC:IF (/arc if).",
		fn = "TOG",
		numArgs = 1,
	},
	set = {
		cmd = "set $key $value",
		desc = "Sets the $key to a specific \"$value\". Use with GET or IFS.",
		fn = "SET",
		numArgs = 2,
	},
	copy = {
		cmd = "copy $URL/Text",
		desc = "Shows a pop-up box to copy the URL / Text given.",
		fn = "COPY",
		numArgs = 1,
	},
	getname = {
		cmd = "getname",
		desc = "Gets the name of the target - if it is a MogIt name, it will give you the MogIt Link.",
		fn = "GETNAME",
		numArgs = 0,
	},
	rand = {
		cmd = "rand",
		desc = "Returns a random argument from those supplied.",
		fn = "RAND",
		numArgs = 0,
	},
}

local arcCommandsList = {
	"cast",
	"castp",
	"cmd",
	"if",
	"ifs",
	"tog",
	"set",
	"copy",
	"getname",
	"rand",
	"phase",
}

local function printMsg(msg)
	print(ADDON_COLOR .. msg)
end

local function printCmd(command)
	local cmd = "/" .. command.cmd
	local desc = command.desc

	if type(desc) == "table" then
		printMsg(cmd)

		for _, line in ipairs(desc) do
			print("     " .. line)
		end
	elseif desc then
		printMsg(cmd .. "|r - " .. desc)
	else
		printMsg(cmd)
	end
end

local function printArcCmd(command)
	local cmd, desc, fn, fnTable = command.cmd, command.desc, command.fn, command.fnTable

	if type(desc) == "table" then
		printMsg("     .. " .. cmd)

		for _, line in ipairs(desc) do
			print("          " .. line)
		end
	else
		printMsg("     .. " .. cmd .. "|r - " .. desc)
	end

	if fn and fnTable then
		print("               Direct Function: " .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. "/run ARC." .. fnTable .. ":" .. fn .. "()|r")
	elseif fn then
		print("               Direct Function: " .. ADDON_COLORS.TOOLTIP_CONTRAST:GenerateHexColorMarkup() .. "/run ARC:" .. fn .. "()|r")
	end
end

local function printArcSubCmd(command)
	for k, v in pairs(command.subcommands) do
		printArcCmd(v)
	end
end

local function arcSlashCommandHandler(msg)
	local command, subcommand = AceConsole:GetArgs(msg, 2)
	local args
	if command and arcCommands[command] then
		local arcCommand = arcCommands[command]
		if arcCommand.subcommands then
			local arcSubCommand = arcCommand.subcommands[subcommand]
			if not arcSubCommand then
				--arcSlashCommandHandler("")
				cprint("ARC:API - " .. DataUtils.wordToProperCase(command) .. " Commands")
				printMsg('NOTE: If you want to use a space, wrap your $variable in quotes (i.e., "command with spaces").')
				printCmd(slashCommands.arc)
				printArcSubCmd(arcCommands[command])
				return
			end
			local numArgs = math.max(arcSubCommand.numArgs + 2, 10)
			args = { AceConsole:GetArgs(msg, numArgs) }
			table.remove(args, 1) -- remove the base
			table.remove(args, numArgs-1) -- remove the nextposition. Nils are dropped once we unpack
			ARC[arcSubCommand.fnTable][arcSubCommand.fn](unpack(args))
		else
			local numArgs = math.max(arcCommand.numArgs + 2, 10)
			args = { AceConsole:GetArgs(msg, numArgs) }
			table.remove(args, 1) -- remove the base
			table.remove(args, numArgs-1) -- remove the nextposition. Nils are dropped once we unpack
			ARC[arcCommand.fn](unpack(args))
		end
	else -- need to make this a general else instead of just a capture of nil because otherwise we miss if they do an invalid command also
		cprint("Commands & API")
		printMsg("Main Commands:")
		printMsg('NOTE: If you want to use a space, wrap your $variable in quotes (i.e., "command with spaces").')
		printCmd(slashCommands.arcanum)
		printCmd(slashCommands.sf)
		print(" ")
		printMsg("ARC:API Commands:")
		printCmd(slashCommands.arc)
		for _, cmd in pairs(arcCommandsList) do
			printArcCmd(arcCommands[cmd])
		end
		printCmd(slashCommands.debug)
	end
end

AceConsole:RegisterChatCommand("arc", arcSlashCommandHandler)
