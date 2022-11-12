local _, ns = ...

local LibDeflate
local AceSerializer

if LibStub then
	LibDeflate = LibStub:GetLibrary("LibDeflate")
	AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
end

local function compressForAddonMsg(str)
	str = AceSerializer:Serialize(str)
	str = LibDeflate:CompressDeflate(str, {level = 9})
	--str = LibDeflate:EncodeForWoWAddonChannel(str)
	str = LibDeflate:EncodeForWoWChatChannel(str)
	return str;
end

local function decompressForAddonMsg(str)
	--str = LibDeflate:DecodeForWoWAddonChannel(str)
	str = LibDeflate:DecodeForWoWChatChannel(str)
	str = LibDeflate:DecompressDeflate(str)
	_, str = AceSerializer:Deserialize(str)
	return str;
end

local function compressForExport(str)
	str = AceSerializer:Serialize(str)
	str = LibDeflate:CompressDeflate(str, {level = 9})
	--str = LibDeflate:EncodeForWoWChatChannel(str)
	str = LibDeflate:EncodeForPrint(str)
	return str;
end

local function decompressForImport(str)
	str = LibDeflate:DecodeForPrint(str)
	str = LibDeflate:DecompressDeflate(str)
	_, str = AceSerializer:Deserialize(str)
	return str;
end

ns.serializer = {
	compressForAddonMsg = compressForAddonMsg,
	decompressForAddonMsg = decompressForAddonMsg,
	compressForExport = compressForExport,
	decompressForImport = decompressForImport,
}