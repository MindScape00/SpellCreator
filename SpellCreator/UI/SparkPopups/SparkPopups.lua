---@class ns
local ns = select(2, ...)

local Vault = ns.Vault
local Icons = ns.UI.Icons
local Logging = ns.Logging
local Permissions = ns.Permissions
local serializer = ns.Serializer
local Tooltip = ns.Utils.Tooltip
local SparkPopups = ns.UI.SparkPopups

local AceConfigDialog = ns.Libs.AceConfigDialog

local DataUtils = ns.Utils.Data
local Debug = ns.Utils.Debug

local isOfficerPlus = Permissions.isOfficerPlus
local getDistanceBetweenPoints = DataUtils.getDistanceBetweenPoints

local defaultSparkPopupStyle = "Interface\\ExtraButton\\Default";

local phaseSparkTriggers = {}

local getPlayerPositionData = C_Epsilon.GetPosition or function() return UnitPosition("player") end

local sparkPopup = CreateFrame("Frame", "SCForgePhaseCastPopup", MainMenuBar, "SC_ExtraActionBarFrameTemplate")
sparkPopup.button = CreateFrame("CheckButton", "SCForgePhaseCastPopupButton", sparkPopup, "SC_ExtraActionButtonTemplate")
local castbutton = sparkPopup.button
castbutton:SetPoint("BOTTOM", 0, 80)
castbutton:SetScript("OnClick", function(self, button)
	self:SetChecked(false)
	if Permissions.isOfficerPlus() and button == "RightButton" then
		SparkPopups.SparkManagerUI.showSparkManagerUI()
		return
	end
	local spell = self.spell
	if not spell then Logging.eprint("No spell found on the button. Report this.") return end
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

		if Permissions.isOfficerPlus() then tinsert(strings, "Right-Click to Open " .. Tooltip.genContrastText("Sparks Manager")) end

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
local function updateSparkLoadingStatus(status)
	isGettingPopupData = status
	SCForgeMainFrame.LoadSpellFrame.SparkManagerButton:UpdateEnabled()
end

---@return boolean
local function getSparkLoadingStatus()
	return isGettingPopupData
end

local function noPopupsToLoad()
	Logging.dprint("Phase Has No Popup Triggers to load.");
	phaseAddonDataListener:UnregisterEvent("CHAT_MSG_ADDON");
	updateSparkLoadingStatus(false)
	phaseSparkTriggers = nil
end

---@param callback function?
local function getPopupTriggersFromPhase(callback)
	if isGettingPopupData then Logging.eprint("Arcanum is already loading or saving Spark data. To avoid data corruption, you can't do that right now. Try again in a moment."); return; end
	local messageTicketID = C_Epsilon.GetPhaseAddonData("SCFORGE_POPUPS")
	phaseSparkTriggers = {}
	updateSparkLoadingStatus(true)

	phaseAddonDataListener:RegisterEvent("CHAT_MSG_ADDON")
	phaseAddonDataListener:SetScript("OnEvent", function(self, event, prefix, text, channel, sender, ...)
		if event == "CHAT_MSG_ADDON" and prefix == messageTicketID and text then
			phaseAddonDataListener:UnregisterEvent("CHAT_MSG_ADDON")

			local noTriggers
			if not (#text < 1 or text == "") then
				phaseSparkTriggers = serializer.decompressForAddonMsg(text)
				if next(phaseSparkTriggers) then
					Logging.dprint("Phase Spark Triggers: ")
					Debug.ddump(phaseSparkTriggers)
				else
					noTriggers = true
				end
			else
				noTriggers = true
			end
			if noTriggers then noPopupsToLoad() end
			if callback then callback() end
			updateSparkLoadingStatus(false)
		end
	end)
end

---comment
---@param commID CommID
---@param radius number
---@param style integer
---@param x number
---@param y number
---@param z number
---@param mapID integer
local function addPopupTriggerToPhaseData(commID, radius, style, x, y, z, colorHex, mapID, overwriteIndex)
	getPopupTriggersFromPhase(function()
		local triggerData = createPopupEntry(commID, radius, style, x, y, z, colorHex)
		if not phaseSparkTriggers then phaseSparkTriggers = {} end
		if not phaseSparkTriggers[mapID] then phaseSparkTriggers[mapID] = {} end
		if overwriteIndex then
			phaseSparkTriggers[mapID][overwriteIndex] = triggerData
		else
			tinsert(phaseSparkTriggers[mapID], triggerData)
		end
		ns.Utils.Debug.ddump(phaseSparkTriggers)
		local str = serializer.compressForAddonMsg(phaseSparkTriggers)
		Logging.dprint(nil, "SCFORGE_POPUPS :: " .. str)
		C_Epsilon.SetPhaseAddonData("SCFORGE_POPUPS", str)

		SparkPopups.SparkManagerUI.refreshSparkManagerUI()
	end)
end

---comment
---@param mapID integer
---@param index integer
---@param callback function
local function removeTriggerFromPhaseDataByMapAndIndex(mapID, index, callback)
	getPopupTriggersFromPhase(function()
		if not phaseSparkTriggers then return Logging.dprint("No phaseSparkTriggers found. How?") end
		if not phaseSparkTriggers[mapID] then return Logging.dprint("No phaseSparkTriggers for map " .. mapID .. " found. How?") end
		tremove(phaseSparkTriggers[mapID], index)
		if not next(phaseSparkTriggers[mapID]) then
			phaseSparkTriggers[mapID] = nil
		end

		ns.Utils.Debug.ddump(phaseSparkTriggers)
		local str = serializer.compressForAddonMsg(phaseSparkTriggers)
		Logging.dprint(nil, "SCFORGE_POPUPS :: " .. str)
		C_Epsilon.SetPhaseAddonData("SCFORGE_POPUPS", str)

		if callback then callback(mapID, index) end
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
	updateSparkLoadingStatus = updateSparkLoadingStatus,
	getSparkLoadingStatus = getSparkLoadingStatus,
	removeTriggerFromPhaseDataByMapAndIndex = removeTriggerFromPhaseDataByMapAndIndex,
}
