---@class ns
local ns = select(2, ...)

local eprint = ns.Logging.eprint
local dprint = ns.Logging.dprint

local MacroEditBox = MacroEditBox

local function cmd(text)
	SendChatMessage("." .. text, "GUILD");
end

local function cmdNoDot(text)
	SendChatMessage(text, "GUILD");
end

local function cmdWithDotCheck(text)
	if text:sub(1, 1) == "." then cmdNoDot(text) else cmd(text) end
end

local dummy = function() end

local function runMacroText(command)
	if command:match("^/") then
		if command:match("^/run ") then
			local newCommand = command:gsub("/run ", "", 1)
			dprint("Had a /run command, it was..")
			dprint(newCommand)
			RunScript(newCommand)
		elseif command:match("^/script ") then
			local newCommand = command:gsub("/script ", "", 1)
			dprint("Had a /script command, it was..")
			dprint(newCommand)
			RunScript(newCommand)
		else
			MacroEditBox:SetText(command)
			local ran = xpcall(ChatEdit_SendText, dummy, MacroEditBox)
			if not ran then
				eprint("This command failed: " .. command)
			end
		end
	else
		dprint("Had a non-slash script command, it was..")
		dprint(command)
		RunScript(command)
	end
end

ns.Cmd = {
	cmd = cmd,
	cmdNoDot = cmdNoDot,
	cmdWithDotCheck = cmdWithDotCheck,
	runMacroText = runMacroText,
}
