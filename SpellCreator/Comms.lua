---@class ns
local ns = select(2, ...)

local Libs = ns.Libs
local Logging = ns.Logging
local Serializer = ns.Serializer
local Constants = ns.Constants
local Vault = ns.Vault

local AceComm = Libs.AceComm
local cprint, dprint, eprint = Logging.cprint, Logging.dprint, Logging.eprint

local PREFIX = "SCFORGE"

---@param playerName string
---@param commID CommID
local function requestSpellFromPlayer(playerName, commID)
	AceComm:SendCommMessage(PREFIX.."REQ", commID, "WHISPER", playerName)
	dprint("Request Spell '"..commID.."' from "..playerName)
end

---@param playerName string
---@param commID CommID
local function sendSpellToPlayer(playerName, commID)
	dprint("Sending Spell '"..commID.."' to "..playerName)
	local spell = Vault.personal.findSpellByID(commID)
	if spell then
		local message = Serializer.compressForAddonMsg(spell)
		AceComm:SendCommMessage(PREFIX.."SPELL", message, "WHISPER", playerName)
	end
end

local function sendSpellForCache(commID, charOrPhase, chatType, target)
	dprint("Sending Spell '"..commID.."', from "..charOrPhase.."'s vault, to Cache Message, via "..chatType)
	local vault = tonumber(charOrPhase) and Vault.phase or Vault.personal
	local theSpell = vault.findSpellByID(commID)

	if theSpell then
		local data = charOrPhase..":"..Serializer.compressForAddonMsg(theSpell)
		if chatType == "EPSI_ANNOUNCE" then
			AceComm:SendCommMessage(PREFIX.."_CACHE", data, "CHANNEL", Constants.ADDON_CHANNEL)
		elseif chatType == "SAY" or chatType == "YELL" or chatType == "EMOTE" then
			local myPosY, myPosX, myPosZ, myInstanceID = UnitPosition("player");
			local myPhase = C_Epsilon.GetPhaseId()
			local radius = 60
			if (chatType == "SAY" or chatType == "EMOTE") then radius = 60 elseif chatType=="YELL" then radius = 400 end
			local localAreaData = myPhase..":"..myPosY..":"..myPosX..":"..myInstanceID..":"..radius
			AceComm:SendCommMessage(PREFIX.."_LCACHE", localAreaData..strchar(31)..data, "CHANNEL", Constants.ADDON_CHANNEL)
		else
			AceComm:SendCommMessage(PREFIX.."_CACHE", data, chatType, target)
		end
	else
		eprint("No spell '"..commID.."' found in your vault to share. Did you delete it and then re-send that ArcSpell link? Don't do that!")
	end
end

---@param spell VaultSpell
---@param charName string
local function saveReceivedSpell(spell, charName)
	Vault.personal.saveSpell(spell)
	cprint("Saved Spell from "..charName..": "..spell.commID)
end

---@param data table
---@param charName string
---@param callback fun()
local function tryToSaveReceivedSpell(data, charName, callback)
	if data.commID then
		if Vault.personal.findSpellByID(data.commID) then
			dprint("The spell already exists, prompting to confirm over-write.")
			ns.UI.Popups.showCommOverwritePopup(data, charName, callback)
			return
		end
		saveReceivedSpell(data, charName)
		if callback then callback() end
	else
		eprint("SpellData did not contain a valid CommID.")
	end
end

---@param msg string
---@param charName string
---@param callback fun()
local function receiveSpellData(msg, charName, callback)
	msg = Serializer.decompressForAddonMsg(msg)
	msg.profile = "From: "..charName
	dprint("Received Arcanum Spell '"..msg.commID.."' from "..charName)
	tryToSaveReceivedSpell(msg, charName, callback)
end

local function receiveSpellCache(msg, charName)
	local spellCharOrPhase, spellData = strsplit(":", msg, 2)
	spellData = Serializer.decompressForAddonMsg(spellData)
	spellData.profile = "From: "..spellCharOrPhase
	dprint("Received Arcanum Spell '"..spellData.commID.."' from "..spellCharOrPhase.." & stored it in the ChatLinkCache.")
	ns.Utils.ChatLinkCache.addSpellToCache(spellData, spellCharOrPhase)
end

local function isLocal(phase, posY, posX, instanceID, radius)
	if tonumber(phase) == tonumber(C_Epsilon.GetPhaseId()) then -- same phase

		posY = tonumber(posY)
		posX = tonumber(posX)
		instanceID = tonumber(instanceID)
		radius = tonumber(radius)

		local myPosY, myPosX, myPosZ, myInstanceID = UnitPosition("player");
		myPosY = floor(myPosY + 0.5);
		myPosX = floor(myPosX + 0.5);

		if myInstanceID == instanceID then -- same zone
			local distance = sqrt((posY - myPosY) ^ 2 + (posX - myPosX) ^ 2);
			return distance <= radius;
		else
			dprint(nil, "Failed isLocal by instanceID: "..instanceID.." v "..myInstanceID)
			return nil
		end
	else
		dprint(nil, "Failed isLocal by Phase: "..phase.." v "..tonumber(C_Epsilon.GetPhaseId()))
		return nil
	end
end

---@class Comms
ns.Comms = {
    PREFIX = PREFIX,
    requestSpellFromPlayer = requestSpellFromPlayer,
	receiveSpellData = receiveSpellData,
	tryToSaveReceivedSpell = tryToSaveReceivedSpell,
	saveReceivedSpell = saveReceivedSpell,
	sendSpellToPlayer = sendSpellToPlayer,
	sendSpellForCache = sendSpellForCache,
	receiveSpellCache = receiveSpellCache,
	isLocal = isLocal,
}
