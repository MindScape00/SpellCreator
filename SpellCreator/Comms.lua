---@class ns
local ns = select(2, ...)

local Libs = ns.Libs
local Logging = ns.Logging
local Serializer = ns.Serializer

local AceComm = Libs.AceComm
local cprint, dprint = Logging.cprint, Logging.dprint

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
	if SpellCreatorSavedSpells[commID] then
		local message = Serializer.compressForAddonMsg(SpellCreatorSavedSpells[commID])
		AceComm:SendCommMessage(PREFIX.."SPELL", message, "WHISPER", playerName)
	end
end

local function savedReceivedSpell(msg, charName)
	SpellCreatorSavedSpells[msg.commID] = msg
	cprint("Saved Spell from "..charName..": "..msg.commID)
end

---@param msg string
---@param charName string
---@param callback fun()
local function receiveSpellData(msg, charName, callback)
	msg = Serializer.decompressForAddonMsg(msg)
	msg.profile = "From: "..charName
	dprint("Received Arcanum Spell '"..msg.commID.."' from "..charName)
	if msg.commID then
		if SpellCreatorSavedSpells[msg.commID] then
			dprint("The spell already exists, prompting to confirm over-write.")
			StaticPopupDialogs["SCFORGE_CONFIRM_OVERWRITE"] = {
				text = "Spell '"..msg.commID.."' Already exists.\n\rDo you want to overwrite the spell ("..msg.fullName..")".."?",
				OnAccept = function()
					savedReceivedSpell(msg, charName)
					callback()
				end,
				button1 = "Overwrite",
				button2 = "Cancel",
				hideOnEscape = true,
				whileDead = true,
			}
			StaticPopup_Show("SCFORGE_CONFIRM_OVERWRITE")
			return;
		end
		savedReceivedSpell(msg, charName)
		callback()
	end
end

---@class Comms
ns.Comms = {
    PREFIX = PREFIX,
    requestSpellFromPlayer = requestSpellFromPlayer,
	receiveSpellData = receiveSpellData,
	sendSpellToPlayer = sendSpellToPlayer,
}
