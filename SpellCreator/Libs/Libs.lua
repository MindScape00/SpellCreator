---@class ns
local ns = select(2, ...)

local LibDeflate
local AceSerializer
local AceComm
local AceConsole
local LibRPMedia
local AceConfig
local AceConfigDialog
local AceGUI

if LibStub then
    LibDeflate = LibStub:GetLibrary("LibDeflate")
	AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
    AceGUI = LibStub:GetLibrary("AceGUI-3.0")
	AceComm = LibStub:GetLibrary("AceComm-3.0")
    AceConsole = LibStub:GetLibrary("AceConsole-3.0")
    AceConfig = LibStub:GetLibrary("AceConfig-3.0")
    AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0")
    LibRPMedia = LibStub:GetLibrary("LibRPMedia-1.0");
end

---@class Libs
ns.Libs = {
    AceComm = AceComm,
    AceConsole = AceConsole,
    AceConfig = AceConfig,
    AceConfigDialog = AceConfigDialog,
    LibDeflate = LibDeflate,
    AceSerializer = AceSerializer,
    LibRPMedia = LibRPMedia,
    AceGUI = AceGUI,
}
