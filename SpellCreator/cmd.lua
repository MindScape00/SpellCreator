local _, ns = ...

local eprint = ns.logging.eprint

local MacroEditBox = MacroEditBox

local function cmd(text)
	SendChatMessage("."..text, "GUILD");
end

local function cmdNoDot(text)
	SendChatMessage(text, "GUILD");
end

local function cmdWithDotCheck(text)
	if text:sub(1, 1) == "." then cmdNoDot(text) else cmd(text) end
end

local dummy = function() end

local function runMacroText(command)
	MacroEditBox:SetText(command)
	local ran = xpcall(ChatEdit_SendText, dummy, MacroEditBox)
	if not ran then
		eprint("This command failed: "..command)
	end
end

ns.cmd = {
    cmd = cmd,
    cmdNoDot = cmdNoDot,
    cmdWithDotCheck = cmdWithDotCheck,
    runMacroText = runMacroText,
}