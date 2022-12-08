---@class ns
local ns = select(2, ...)

local cmdWithDotCheck = ns.Cmd.cmdWithDotCheck
local ADDON_COLOR = ns.Constants.ADDON_COLOR
local cprint = ns.Logging.cprint

local AceConsole = ns.Libs.AceConsole

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
	cast = {
		cmd = "cast $commID",
		desc = "Cast from your personal vault, same as /arcanum or /sf",
		fn = "CAST",
		numArgs = 1,
	},
	castp = {
		cmd = "castp $commID",
		desc = "Cast a spell from the Phase Vault if it exists.",
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
		cmd = "if $tag $commandTrue $commandFalse [$varTrue] [$varFalse]",
		desc = {
			"Checks if the $tag is true and runs the $commandTrue (with $var1 added if given),",
			"or $commandFalse if not true (with $varTrue/$varFalse added if given).",
		},
		fn = "IF",
		numArgs = 5,
	},
	ifs = {
		cmd = "ifs $tag $check $commandTrue $commandFalse [$varTrue] [$varFalse]",
		desc = {
			"Same as ARC:IF but checks if the $tag is equal to $check instead of just testing if it's true.",
		},
		fn = "IF",
		numArgs = 6,
	},
	tog = {
		cmd = "tog $tag",
		desc = "Toggles the $tag between true & false, used with ARC:IF (/arc if).",
		fn = "TOG",
		numArgs = 1,
	},
	set = {
		cmd = "set $tag $value",
		desc = "Sets the $tag to a specific \"$value\". Use with GET or IFS.",
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
	"rand"
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
	local cmd, desc, fn = command.cmd, command.desc, command.fn

	if type(desc) == "table" then
		printMsg("     .. " .. cmd)

		for _, line in ipairs(desc) do
			print("          " .. line)
		end
	else
		printMsg("     .. " .. cmd .. "|r - " .. desc)
	end

	if fn then
		print("               Direct Function: |cffFFAAAA/run ARC:" .. fn .. "()|r")
	end
end

local function arcSlashCommandHandler(msg)
	local command = AceConsole:GetArgs(msg)
	if not command or command == "" then
		cprint("Commands & API")
		printMsg("Main Commands:")
		printMsg('NOTE: If you want to use a space, wrap your $variable in quotes (i.e., "command with spaces").')
		printCmd(slashCommands.arcanum)
		printCmd(slashCommands.sf)
		print(" ")
		printMsg("ARC:API Commands:")
		printCmd(slashCommands.arc)
		for _, cmd in pairs(arcCommandsList) do printArcCmd(arcCommands[cmd]) end
		printCmd(slashCommands.debug)
	elseif arcCommands[command] then
		local arcCommand = arcCommands[command]

		local args = {AceConsole:GetArgs(msg, arcCommand.numArgs + 1)}
		args = {unpack(args, 1, arcCommand.numArgs + 1)} -- drop the command and nextposition

		ARC[arcCommand.fn](unpack(args))
	end
end

AceConsole:RegisterChatCommand("arc", arcSlashCommandHandler)
