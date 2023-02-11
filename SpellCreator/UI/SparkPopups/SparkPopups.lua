---@class ns
local ns                       = select(2, ...)
local addonName                = ...

local AceComm                  = ns.Libs.AceComm
local Comms                    = ns.Comms
local Vault                    = ns.Vault
local Icons                    = ns.UI.Icons
local Logging                  = ns.Logging
local Permissions              = ns.Permissions
local serializer               = ns.Serializer
local Tooltip                  = ns.Utils.Tooltip
local SparkPopups              = ns.UI.SparkPopups

local AceConfigDialog          = ns.Libs.AceConfigDialog

local addonMsgPrefix           = Comms.PREFIX
local DataUtils                = ns.Utils.Data
local Debug                    = ns.Utils.Debug

local isOfficerPlus            = Permissions.isOfficerPlus
local getDistanceBetweenPoints = DataUtils.getDistanceBetweenPoints

local defaultSparkPopupStyle   = "Interface\\ExtraButton\\Default";

local phaseSparkTriggers       = {}

local getPlayerPositionData    = C_Epsilon.GetPosition or function() return UnitPosition("player") end

local MSG_MULTI_FIRST          = "\001"
local MSG_MULTI_NEXT           = "\002"
local MSG_MULTI_LAST           = "\003"
local MAX_CHARS_PER_SEGMENT    = 3750

local sparkPopup               = CreateFrame("Frame", "SCForgePhaseCastPopup", MainMenuBar, "SC_ExtraActionBarFrameTemplate")
sparkPopup.button              = CreateFrame("CheckButton", "SCForgePhaseCastPopupButton", sparkPopup, "SC_ExtraActionButtonTemplate")
local castbutton               = sparkPopup.button
castbutton:SetPoint("BOTTOM", 0, 80)
castbutton:SetScript("OnClick", function(self, button)
	self:SetChecked(false)
	if (isOfficerPlus() or SpellCreatorMasterTable.Options["debug"]) and button == "RightButton" then
		SparkPopups.SparkManagerUI.showSparkManagerUI()
		return
	end
	local spell = self.spell
	if not spell then
		Logging.eprint("No spell found on the button. Report this.")
		return
	end
	ARC:CASTP(spell.commID)
end)

Tooltip.set(sparkPopup.button,
	function(self)
		return self.spell.fullName
	end,
	function(self)
		local spell = self.spell
		local strings = {}

		if spell.description then
			tinsert(strings, spell.description)
		end
		if spell.author then
			tinsert(strings, Tooltip.createDoubleLine("Actions: " .. #spell.actions, "Author: " .. spell.author));
		else
			tinsert(strings, "Actions: " .. #spell.actions)
		end

		tinsert(strings, " ")
		tinsert(strings, "Click to cast " .. Tooltip.genContrastText(spell.commID) .. "!")

		if isOfficerPlus() then tinsert(strings, "Right-Click to Open " .. Tooltip.genContrastText("Sparks Manager")) end

		return strings
	end,
	{ delay = 0 }
)

---@param commID CommID
---@param barTex string|integer
---@param index integer
---@param colorHex string
---@return boolean
local function showCastPopup(commID, barTex, index, colorHex)
	local bar = sparkPopup;
	local spell = Vault.phase.findSpellByID(commID)
	if not spell then return false end -- spell not found in vault, return false which will hide the sparkPopup

	local icon = Icons.getFinalIcon(spell.icon)
	bar.button.icon:SetTexture(icon)
	local texture = barTex or defaultSparkPopupStyle;
	if type(texture) == "string" then
		texture = texture:gsub("SpellCreator%-dev", "SpellCreator"):gsub("SpellCreator", addonName)
	end
	bar.button.style:SetTexture(texture);
	if colorHex then
		bar.button.style:SetVertexColor(CreateColorFromHexString(colorHex):GetRGB())
	else
		bar.button.style:SetVertexColor(1, 1, 1, 1)
	end

	bar.button.spell = spell
	bar.button.index = index
	--UIParent_ManageFramePositions(); -- wtf does this do?
	if not bar:IsShown() then
		bar:Show();
		bar.outro:Stop();
		bar.intro:Play();
	end
	return true
end

local function hideCastPopup()
	local bar = sparkPopup;
	bar.intro:Stop();
	bar.outro:Play();
end

local CoordinateListener = CreateFrame("Frame")
local throttle, counter = 1, 0
CoordinateListener:SetScript("OnUpdate", function(self, elapsed)
	counter = counter + elapsed
	if counter < throttle then
		return
	end
	counter = 0

	if not phaseSparkTriggers then return end

	local shouldHideCastbar = true
	local x, y, z, mapID = getPlayerPositionData()

	local phaseSpellsOnThisMap = phaseSparkTriggers[mapID]
	if phaseSpellsOnThisMap then
		for i = 1, #phaseSpellsOnThisMap do
			local v = phaseSpellsOnThisMap[i]
			local commID, sX, sY, sZ, sR, barTex, colorHex = v[1], v[2], v[3], v[4], v[5], v[6], v[7]
			if commID and sX and sY and sZ and sR and barTex then
				if getDistanceBetweenPoints(sX, sY, x, y) < sR then
					if getDistanceBetweenPoints(z, sZ) <= sR then
						shouldHideCastbar = not showCastPopup(commID, barTex, i, colorHex)
					end
				end
			else
				Logging.dprint(nil,
					string.format("Invalid Spark Trigger (Map: %s | Index: %s) - You can manually remove it using %s", mapID, i,
						Tooltip.genContrastText(string.format("/sfdebug removeTriggerByMapAndIndex %s %s", mapID, i))))
			end
		end
	end
	if shouldHideCastbar then hideCastPopup() end
end)

-----------------------------------
-- // Popup Trigger Save/Load System
-----------------------------------

local phaseAddonDataListener = CoordinateListener -- reusing the frame - since it only listens for OnUpdate, we can steal it's OnEvent
local isGettingPopupData

---Value Order: 1=CommID, 2=x, 3=y, 4=z, 5=radius, 6=style, 7=colorHex
---@alias triggerData { [1]: CommID, [2]: number, [3]: number, [4]: number, [5]: number, [6]: number, [7]: string }

---@param commID CommID
---@param radius number
---@param style integer
---@return triggerData
local function createPopupEntry(commID, radius, style, x, y, z, colorHex)
	if colorHex == "ffffffff" then colorHex = nil end
	return { commID, x, y, z, radius, style, colorHex }
end

---@param status boolean
local function setSparkLoadingStatus(status)
	isGettingPopupData = status
	SCForgeMainFrame.LoadSpellFrame.SparkManagerButton:UpdateEnabled()
end

---@return boolean
local function getSparkLoadingStatus()
	return isGettingPopupData
end

local scforge_ChannelID = ns.Constants.ADDON_CHANNEL
---@param toggle boolean
local function sendPhaseSparkIOLock(toggle)
	local phaseID = C_Epsilon.GetPhaseId()
	if toggle == true then
		AceComm:SendCommMessage(addonMsgPrefix .. "_SLOCK", phaseID, "CHANNEL", tostring(scforge_ChannelID))
		Logging.dprint("Sending Lock Spark IO Message for phase " .. phaseID)
	elseif toggle == false then
		AceComm:SendCommMessage(addonMsgPrefix .. "_SUNLOCK", phaseID, "CHANNEL", tostring(scforge_ChannelID))
		Logging.dprint("Sending Unlock Spark Vault IO Message for phase " .. phaseID)
	end
end

local function noPopupsToLoad()
	Logging.dprint("Phase Has No Popup Triggers to load.");
	phaseAddonDataListener:UnregisterEvent("CHAT_MSG_ADDON");
	setSparkLoadingStatus(false)
	phaseSparkTriggers = nil
end

local sparkStrings = {}
local multipartIter = 0

---@param callback function?
---@param iter integer?
local function getPopupTriggersFromPhase(callback, iter)
	if isGettingPopupData and not iter then
		Logging.eprint("Arcanum is already loading or saving Spark data. To avoid data corruption, you can't do that right now. Try again in a moment.");
		return;
	end
	setSparkLoadingStatus(true)

	phaseSparkTriggers = {}

	local dataKey = "SCFORGE_POPUPS"
	if iter then dataKey = "SCFORGE_POPUPS_" .. iter + 1 end
	local messageTicketID = C_Epsilon.GetPhaseAddonData(dataKey)
	phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
	phaseAddonDataListener:SetScript("OnEvent", function(self, event, prefix, text, channel, sender, ...)
		if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
			phaseAddonDataListener:UnregisterEvent("CHAT_MSG_ADDON")

			if string.match(text, "^[\001-\002]") then -- if first character is a multi-part identifier - \001 = first, \002 = middle, then we can add it to the strings table, and return with a call to get the next segment
				multipartIter = multipartIter + 1 -- progress the iterator tracker
				text = text:gsub("^[\001-\002]", "") -- remove the control character
				sparkStrings[multipartIter] = text -- add to the table
				return getPopupTriggersFromPhase(callback, multipartIter)
			elseif string.match(text, "^[\003]") then -- if first character is a last identifier - \003 = last, then we can add it to our table, then concat into a final string to use and continue
				multipartIter = multipartIter + 1 -- progress the iterator tracker
				text = text:gsub("^[\003]", "") -- remove the control character
				Logging.dprint("Last Popup Data Received, Concat & Save coming up!")
				sparkStrings[multipartIter] = text -- add to the table
				text = table.concat(sparkStrings, "")

				-- reset our temp data
				wipe(sparkStrings) -- wipe it so we can just reuse the table instead of always making new ones
				multipartIter = 0
			end

			local noTriggers
			if not (#text < 1 or text == "") then
				phaseSparkTriggers = serializer.decompressForAddonMsg(text)
				if next(phaseSparkTriggers) then
					Logging.dprint("Phase Spark Triggers: ")
					Debug.ddump(phaseSparkTriggers)
				else
					noTriggers = true
					Logging.dprint("Failed a next check on phaseSparkTriggers")
				end
			else
				noTriggers = true
				Logging.dprint("Failed text length or blank string validation on phaseSparkTriggers")
			end
			if noTriggers then noPopupsToLoad() end
			if callback then callback() end
			setSparkLoadingStatus(false)
		end
	end)
end

local function savePopupTriggersToPhaseData()
	local str = serializer.compressForAddonMsg(phaseSparkTriggers)
	local sparksLength = #str
	if sparksLength > MAX_CHARS_PER_SEGMENT then
		local numEntriesRequired = math.ceil(sparksLength / MAX_CHARS_PER_SEGMENT)
		for i = 1, numEntriesRequired do
			local strSub = string.sub(str, (MAX_CHARS_PER_SEGMENT * (i - 1)) + 1, (MAX_CHARS_PER_SEGMENT * i))
			if i == 1 then
				strSub = MSG_MULTI_FIRST .. strSub
				Logging.dprint(nil, "SCFORGE_POPUPS :: " .. strSub)
				C_Epsilon.SetPhaseAddonData("SCFORGE_POPUPS", strSub)
			else
				local controlChar = MSG_MULTI_NEXT
				if i == numEntriesRequired then controlChar = MSG_MULTI_LAST end
				strSub = controlChar .. strSub
				Logging.dprint(nil, "SCFORGE_POPUPS_" .. i .. " :: " .. strSub)
				C_Epsilon.SetPhaseAddonData("SCFORGE_POPUPS_" .. i, strSub)
			end
		end
	else
		Logging.dprint(nil, "SCFORGE_POPUPS :: " .. str)
		C_Epsilon.SetPhaseAddonData("SCFORGE_POPUPS", str)
	end

	SparkPopups.SparkManagerUI.refreshSparkManagerUI()
	sendPhaseSparkIOLock(false)
end

---@param commID CommID
---@param radius number
---@param style integer
---@param x number
---@param y number
---@param z number
---@param mapID integer
local function addPopupTriggerToPhaseData(commID, radius, style, x, y, z, colorHex, mapID, overwriteIndex)
	sendPhaseSparkIOLock(true)
	getPopupTriggersFromPhase(function()
		local triggerData = createPopupEntry(commID, radius, style, x, y, z, colorHex)
		if not phaseSparkTriggers then
			phaseSparkTriggers = {}
			Logging.dprint("Phase Spark Triggers was Blank")
		end
		if not phaseSparkTriggers[mapID] then
			phaseSparkTriggers[mapID] = {}
			Logging.dprint("PhaseSparkTriggers for map " .. mapID .. " was blank.")
		end
		if overwriteIndex then
			phaseSparkTriggers[mapID][overwriteIndex] = triggerData
		else
			tinsert(phaseSparkTriggers[mapID], triggerData)
		end
		ns.Utils.Debug.ddump(phaseSparkTriggers)
		savePopupTriggersToPhaseData()
		--sendPhaseSparkIOLock(false) --// called in savePopupTriggersToPhaseData instead
	end)
end

---@param mapID integer
---@param index integer
---@param callback function
local function removeTriggerFromPhaseDataByMapAndIndex(mapID, index, callback)
	sendPhaseSparkIOLock(true)
	getPopupTriggersFromPhase(function()
		if not phaseSparkTriggers then return Logging.dprint("No phaseSparkTriggers found. How?") end
		if not phaseSparkTriggers[mapID] then return Logging.dprint("No phaseSparkTriggers for map " .. mapID .. " found. How?") end
		tremove(phaseSparkTriggers[mapID], index)
		if not next(phaseSparkTriggers[mapID]) then
			phaseSparkTriggers[mapID] = nil
		end

		ns.Utils.Debug.ddump(phaseSparkTriggers)
		savePopupTriggersToPhaseData()

		if callback then callback(mapID, index) end
		--sendPhaseSparkIOLock(false) --// called in savePopupTriggersToPhaseData instead
	end)
end

local function getPhaseSparkTriggersCache()
	return phaseSparkTriggers
end

---@class UI_SparkPopups_SparkPopups
ns.UI.SparkPopups.SparkPopups = {
	getPopupTriggersFromPhase = getPopupTriggersFromPhase,
	addPopupTriggerToPhaseData = addPopupTriggerToPhaseData,
	getPhaseSparkTriggersCache = getPhaseSparkTriggersCache,
	setSparkLoadingStatus = setSparkLoadingStatus,
	getSparkLoadingStatus = getSparkLoadingStatus,
	removeTriggerFromPhaseDataByMapAndIndex = removeTriggerFromPhaseDataByMapAndIndex,
	sendPhaseSparkIOLock = sendPhaseSparkIOLock,
}
