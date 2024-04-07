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

local Cooldowns                = ns.Actions.Cooldowns

local isOfficerPlus            = Permissions.isOfficerPlus
local getDistanceBetweenPoints = DataUtils.getDistanceBetweenPoints

local defaultSparkPopupStyle   = "Interface\\ExtraButton\\Default";

local phaseSparkTriggers       = {}

local getPlayerPositionData    = C_Epsilon.GetPosition or function() return UnitPosition("player") end

local multiMessageData         = ns.Comms.multiMessageData
local MSG_MULTI_FIRST          = multiMessageData.MSG_MULTI_FIRST
local MSG_MULTI_NEXT           = multiMessageData.MSG_MULTI_NEXT
local MSG_MULTI_LAST           = multiMessageData.MSG_MULTI_LAST
local MAX_CHARS_PER_SEGMENT    = multiMessageData.MAX_CHARS_PER_SEGMENT

---@class PopupTriggerOptions
---@field cooldownTime? integer
---@field trigSpellCooldown? boolean
---@field broadcastCooldown? boolean
---@field requirement? string
---@field inputs? string
---@field conditions? ConditionDataTable

local function genSparkCDNameOverride(commID, x, y, z)
	local sparkCDNameOverride = strjoin(string.char(31), commID, x, y, z)
	return sparkCDNameOverride
end

local sparkPopup           = CreateFrame("Frame", "SCForgePhaseCastPopup", UIParent, "SC_ExtraActionBarFrameTemplate")
sparkPopup.button          = CreateFrame("CheckButton", "SCForgePhaseCastPopupButton", sparkPopup, "SC_ExtraActionButtonTemplate")
sparkPopup.button.cooldown = CreateFrame("Cooldown", nil, sparkPopup.button, "CooldownFrameTemplate")
sparkPopup.button.cooldown:SetAllPoints()

-- make the sparkPopup able to be moved by dragging it; slightly smaller than the actual style frame to account for transparency on the edges
sparkPopup:SetSize(200, 100)
sparkPopup:SetMovable(true)
sparkPopup:EnableMouse(true)
sparkPopup:RegisterForDrag("LeftButton")
sparkPopup:SetScript("OnDragStart", function(self, button)
	self:StartMoving()
end)
sparkPopup:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
end)

local castbutton = sparkPopup.button
castbutton:SetPoint("CENTER")
castbutton:SetScript("OnClick", function(self, button)
	self:SetChecked(false)
	if (isOfficerPlus() or SpellCreatorMasterTable.Options["debug"]) and button == "RightButton" then
		SparkPopups.SparkManagerUI.showSparkManagerUI()
		return
	end
	local spell = self.spell
	if button == "keybind" and not sparkPopup:IsShown() then
		Logging.dprint("SparkPopups Keybind Pressed, but not shown so skipped.")
		return
	end
	if not spell then
		Logging.eprint("No spell found on the button. Report this.")
		return
	end

	--spark cooldown overrides
	local cdData = self.cdData
	--local sparkCDNameOverride = spell.commID .. cdData.loc[1] .. cdData.loc[2] .. cdData.loc[3]
	local sparkCDNameOverride = genSparkCDNameOverride(spell.commID, cdData.loc[1], cdData.loc[2], cdData.loc[3])
	local sparkCdTimeRemaining, sparkCdLength = Cooldowns.isSparkOnCooldown(sparkCDNameOverride)
	local spellCdTimeRemaining, spellCdLength = Cooldowns.isSpellOnCooldown(spell.commID, C_Epsilon.GetPhaseId())
	if sparkCdTimeRemaining then
		return print(("This spark (%s) is on cooldown (%ss)."):format(sparkCDNameOverride, sparkCdTimeRemaining))
	elseif spellCdTimeRemaining then
		return print(("This Spark's Spell (%s) is on Cooldown (%ss)."):format(spell.commID, spellCdTimeRemaining))
	end

	local bypassCD = false
	if cdData[1] then
		Cooldowns.addSparkCooldown(sparkCDNameOverride, cdData[1], spell.commID)
		bypassCD = true
		if cdData[2] then
			bypassCD = false
		end
		if cdData[3] then
			ns.Comms.sendSparkCooldown(sparkCDNameOverride, cdData[1])
			-- send something to the comms to trigger that cd on the phase.. ick..
		end
	end
	if cdData.inputs then
		ARC.PHASE:CAST(spell.commID, bypassCD, unpack(DataUtils.parseStringToArgs(cdData.inputs)))
	else
		ARC.PHASE:CAST(spell.commID, bypassCD)
	end
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
		local cooldownTime
		if spell.cooldown then
			cooldownTime = spell.cooldown
		end
		if self.cdData[1] then
			local sparkCdTime = tonumber(self.cdData[1])
			if self.cdData[2] then
				if cooldownTime then
					if sparkCdTime > cooldownTime then
						cooldownTime = sparkCdTime
					end
				else
					cooldownTime = sparkCdTime
				end
			else
				cooldownTime = sparkCdTime
			end
		end
		if cooldownTime then
			tinsert(strings, Tooltip.createDoubleLine("Actions: " .. #spell.actions, "Cooldown: " .. cooldownTime .. "s"));
			if spell.author then
				tinsert(strings, Tooltip.createDoubleLine(" ", "Author: " .. spell.author));
			end
		else
			if spell.author then
				tinsert(strings, Tooltip.createDoubleLine("Actions: " .. #spell.actions, "Author: " .. spell.author));
			else
				tinsert(strings, "Actions: " .. #spell.actions)
			end
		end

		tinsert(strings, " ")
		tinsert(strings, "Click to cast " .. Tooltip.genContrastText(spell.commID) .. "!")

		if isOfficerPlus() then tinsert(strings, "Right-Click to Open " .. Tooltip.genContrastText("Sparks Manager")) end

		return strings
	end,
	{ delay = 0 }
)

---comment
---@param commID CommID commID of the spell, to check if that spark is even shown
---@param cooldownTime number time in seconds for the cooldown
local function triggerSparkCooldownVisual(commID, cooldownTime)
	local bar = sparkPopup
	if not bar:IsShown() then return end -- quick exit if no sparks are shown
	local sparkSpell = bar.button.spell -- grab the spell
	if sparkSpell.commID == commID then -- check if our commID matches the current shown spark spell
		local currTime = GetTime()
		bar.button.cooldown:SetCooldown(currTime, cooldownTime)
	end
end

---@param commID CommID
---@param barTex string|integer
---@param index integer
---@param colorHex string
---@param sparkData table
---@return boolean
local function showCastPopup(commID, barTex, index, colorHex, sparkData)
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

	-- spark cooldown overrides
	local sparkOptions = sparkData[8] or {} --[[@as PopupTriggerOptions]]
	local sparkCdTime, sparkCdTrigger, sparkCdBroadcast, sparkRequirement, sparkConditions
	if sparkOptions then
		sparkCdTime, sparkCdTrigger, sparkCdBroadcast = sparkOptions.cooldownTime, sparkOptions.trigSpellCooldown, sparkOptions.broadcastCooldown
		sparkRequirement = sparkOptions.requirement
		sparkConditions = sparkOptions.conditions
	end
	bar.button.cdData = {
		sparkCdTime,
		sparkCdTrigger,
		sparkCdBroadcast,
		loc = { sparkData[2], sparkData[3], sparkData[4] },
		inputs = (sparkOptions.inputs or nil)
	}

	--local sparkCDNameOverride = spell.commID .. sparkData[2] .. sparkData[3] .. sparkData[4]
	local sparkCDNameOverride = genSparkCDNameOverride(spell.commID, sparkData[2], sparkData[3], sparkData[4])

	-- check if the spell is currently on cooldown so we can show the correct cooldown timer visual, or clear it if there's one running from another spell
	local cooldownTime, cooldownLength = Cooldowns.isSpellOnCooldown(spell.commID, C_Epsilon.GetPhaseId())
	local remainingSparkCdTime, sparkCdLength = Cooldowns.isSparkOnCooldown(sparkCDNameOverride)
	if remainingSparkCdTime then
		if cooldownTime then
			if (remainingSparkCdTime > cooldownTime) then
				cooldownTime = remainingSparkCdTime
				cooldownLength = sparkCdLength
			end
		else
			cooldownTime = remainingSparkCdTime
			cooldownLength = sparkCdLength
		end
	end
	if cooldownTime then
		bar.button.cooldown:SetCooldown(GetTime() - (cooldownLength - cooldownTime), cooldownLength)
	else
		bar.button.cooldown:Clear()
	end

	return true
end

local function hideCastPopup()
	local bar = sparkPopup;
	bar.intro:Stop();
	bar.outro:Play();
	bar.button.cooldown:Clear()
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
			local sparkOptions = v[8] --[[@as PopupTriggerOptions]]
			if commID and sX and sY and sZ and sR and barTex then
				if getDistanceBetweenPoints(sX, sY, x, y) < sR then
					if getDistanceBetweenPoints(z, sZ) <= sR then
						if sparkOptions then
							local shouldShowSpark = true
							if sparkOptions.conditions then
								shouldShowSpark = ns.Actions.Execute.checkConditions(sparkOptions.conditions)
							elseif sparkOptions.requirement then
								local script = sparkOptions.requirement
								if not script:match("return") then
									script = "return " .. script
								end
								if ns.Cmd.runMacroText(script) then
									shouldShowSpark = true
								end
							end
							if shouldShowSpark then
								shouldHideCastbar = not showCastPopup(commID, barTex, i, colorHex, v)
							end
						else
							shouldHideCastbar = not showCastPopup(commID, barTex, i, colorHex, v)
						end
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

---comment
---@param commID CommID
---@param radius number
---@param style integer
---@param x number
---@param y number
---@param z number
---@param colorHex string
---@param options PopupTriggerOptions?
---@return triggerData
local function createPopupEntry(commID, radius, style, x, y, z, colorHex, options)
	if colorHex == "ffffffff" then colorHex = nil end
	return { commID, x, y, z, radius, style, colorHex, options }
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

---@param toggle boolean
local function sendPhaseSparkIOLock(toggle)
	local phaseID = tostring(C_Epsilon.GetPhaseId())
	local scforge_ChannelID = ns.Constants.ADDON_CHANNEL
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
				Logging.dprint("First, or Mid- Popup Data Received, Asking for Next Segment!")
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
			else
				Logging.dprint("Spark Popup Data was not a multi-part tagged string, continuing to load normally.")
			end

			local noTriggers
			if not (#text < 1 or text == "") then
				local loaded
				--phaseSparkTriggers = serializer.decompressForAddonMsg(text)
				loaded, phaseSparkTriggers = pcall(serializer.decompressForAddonMsg, text)
				if not loaded then
					message("Arcanum Failed to Load Phase Sparks Data. Report this.")
					return
				end
				if next(phaseSparkTriggers) then
					--Logging.dprint("Phase Spark Triggers: ")
					--Debug.ddump(phaseSparkTriggers)
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
		Logging.dprint("Sparks Exceeded MAX_CHARS_PER_SEGMENT : " .. sparksLength)
		local numEntriesRequired = math.ceil(sparksLength / MAX_CHARS_PER_SEGMENT)
		for i = 1, numEntriesRequired do
			local strSub = string.sub(str, (MAX_CHARS_PER_SEGMENT * (i - 1)) + 1, (MAX_CHARS_PER_SEGMENT * i))
			if i == 1 then
				strSub = MSG_MULTI_FIRST .. strSub
				--Logging.dprint(nil, "SCFORGE_POPUPS :: " .. strSub)
				Logging.dprint(nil, "SCFORGE_POPUPS :: " .. "<trimmed - bulk/first>")
				C_Epsilon.SetPhaseAddonData("SCFORGE_POPUPS", strSub)
			else
				local controlChar = MSG_MULTI_NEXT
				if i == numEntriesRequired then controlChar = MSG_MULTI_LAST end
				strSub = controlChar .. strSub
				--Logging.dprint(nil, "SCFORGE_POPUPS_" .. i .. " :: " .. strSub)
				Logging.dprint(nil, "SCFORGE_POPUPS_" .. i .. " :: " .. "<trimmed - bulk/mid or last>")
				C_Epsilon.SetPhaseAddonData("SCFORGE_POPUPS_" .. i, strSub)
			end
		end
	else
		--Logging.dprint(nil, "SCFORGE_POPUPS :: " .. str)
		Logging.dprint(nil, "SCFORGE_POPUPS :: " .. "<trimmed - solo>")
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
---@param options PopupTriggerOptions
local function addPopupTriggerToPhaseData(commID, radius, style, x, y, z, colorHex, mapID, options, overwriteIndex)
	sendPhaseSparkIOLock(true)
	getPopupTriggersFromPhase(function()
		local triggerData = createPopupEntry(commID, radius, style, x, y, z, colorHex, options)
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
		--ns.Utils.Debug.ddump(phaseSparkTriggers)
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

		--ns.Utils.Debug.ddump(phaseSparkTriggers)
		savePopupTriggersToPhaseData()

		if callback then callback(mapID, index) end
		--sendPhaseSparkIOLock(false) --// called in savePopupTriggersToPhaseData instead
	end)
end

local function getPhaseSparkTriggersCache()
	return phaseSparkTriggers
end

local function setPhaseSparkTriggersCache(data)
	phaseSparkTriggers = data
end

---------------------
--#region Keybinding
---------------------

local default_spark_keybind = ns.Constants.SPARK_DEFAULT_KEYBIND
local sparkKeybindHolder = CreateFrame("Frame")
local function setSparkKeybind(key)
	if key then
		if key == "" then
			SpellCreatorMasterTable.Options.sparkKeybind = false
			ClearOverrideBindings(sparkKeybindHolder)
		else
			SpellCreatorMasterTable.Options.sparkKeybind = key
			SetOverrideBindingClick(sparkKeybindHolder, true, key, "SCForgePhaseCastPopupButton", "keybind")
		end
	else
		SpellCreatorMasterTable.Options.sparkKeybind = false
		ClearOverrideBindings(sparkKeybindHolder)
	end
end

local function getSparkKeybind()
	return SpellCreatorMasterTable.Options.sparkKeybind
end

local function setSparkDefaultKeybind()
	local fBinding = GetBindingAction(default_spark_keybind)
	if (fBinding == "") or (fBinding == "ASSISTTARGET") then -- f was not bound or was default binding, we can override it.
		setSparkKeybind("F")
	else                                                  -- player uses F for something else, dumb. Fine, we won't override, but give them a warning.
		ns.Logging.cprint(("Arcanum defaults to using the %s keybind for Spark activation. You currently have this bound to something other than default (Current Bound Action: '%s'). We recommend opening your Arcanum settings ( %s ) and setting this to something that works for you.")
			:format(ns.Utils.Tooltip.genContrastText("'" .. default_spark_keybind .. "'"), ns.Utils.Tooltip.genContrastText(GetBindingAction("F")),
				ns.Utils.Tooltip.genContrastText("'/sf options' -> Spark Settings")))
		setSparkKeybind()
	end
end

---------------------
--#endregion
---------------------

---@class UI_SparkPopups_SparkPopups
ns.UI.SparkPopups.SparkPopups = {
	getPopupTriggersFromPhase = getPopupTriggersFromPhase,
	addPopupTriggerToPhaseData = addPopupTriggerToPhaseData,
	getPhaseSparkTriggersCache = getPhaseSparkTriggersCache,
	setPhaseSparkTriggersCache = setPhaseSparkTriggersCache,
	setSparkLoadingStatus = setSparkLoadingStatus,
	getSparkLoadingStatus = getSparkLoadingStatus,
	removeTriggerFromPhaseDataByMapAndIndex = removeTriggerFromPhaseDataByMapAndIndex,
	sendPhaseSparkIOLock = sendPhaseSparkIOLock,
	savePopupTriggersToPhaseData = savePopupTriggersToPhaseData,
	triggerSparkCooldownVisual = triggerSparkCooldownVisual,

	setSparkKeybind = setSparkKeybind,
	getSparkKeybind = getSparkKeybind,
	setSparkDefaultKeybind = setSparkDefaultKeybind,

	genSparkCDNameOverride = genSparkCDNameOverride,
}
