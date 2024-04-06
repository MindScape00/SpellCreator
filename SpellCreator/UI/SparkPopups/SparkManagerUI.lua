---@class ns
local ns = select(2, ...)
local addonName = ...

local DataUtils = ns.Utils.Data
local AceGUI = ns.Libs.AceGUI
local SparkPopups = ns.UI.SparkPopups
local Tooltip = ns.Utils.Tooltip
local Popups = ns.UI.Popups
local Permissions = ns.Permissions

local ADDON_COLORS = ns.Constants.ADDON_COLORS

local cmd = ns.Cmd.cmd
local round = DataUtils.roundToNthDecimal
local orderedPairs = DataUtils.orderedPairs
local getPlayerPositionData = C_Epsilon.GetPosition or function() return UnitPosition("player") end

local mapNameReplacers = {
	["Pocket Dimension Akazamzaraks Hat Scenario"] = "Dranosh Valley",
	["ep_scarletsanctuaryarmoryandlibrary - infinite - 28_29"] = "Infinite Flatlands",
	["ep_azeroth - infinite - 35_58"] = "Infinite Oceans",
}

---@param num integer
---@return number
local function getPosData(num)
	return DataUtils.roundToNthDecimal(select(num, getPlayerPositionData()), 4)
end

--------------------------------
--- NEW AceGUI Powered UI
--------------------------------
local curMapID
local sparkManagerUI

---@param mapID integer
---@param index integer
local function sparkEditButtonClick(mapID, index)
	local phaseSparkTriggers = SparkPopups.SparkPopups.getPhaseSparkTriggersCache()
	local commID = phaseSparkTriggers[mapID][index][1]
	SparkPopups.CreateSparkUI.openSparkCreationUI(commID, index, mapID)
end

---@param mapID integer
---@return AceGUITreeGroup
local function genSparkManagerMapItem(mapID)
	local isCurrentMap = mapID == curMapID
	local mapName = isCurrentMap and GetZoneText() or GetRealZoneText(mapID)
	if mapNameReplacers[mapName] then mapName = mapNameReplacers[mapName] end
	return {
		text = mapName .. " (" .. tostring(mapID) .. ")",
		value = mapID,
		icon = (isCurrentMap and "interface/minimap/tracking/poiarrow" or nil),
	}
end

local function getSparkManagerMapTree()
	local sparkManagerMapTree = {}
	curMapID = getPosData(4)
	local phaseSparkTriggers = SparkPopups.SparkPopups.getPhaseSparkTriggersCache()
	if not phaseSparkTriggers then phaseSparkTriggers = { [curMapID] = {} } end
	for k, v in orderedPairs(phaseSparkTriggers) do
		local mapItem = genSparkManagerMapItem(k)
		tinsert(sparkManagerMapTree, mapItem)
	end
	return sparkManagerMapTree
end

---@param num number
---@return number
local function verifyNumber(num)
	if num then return num else return 99999999 end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@param group AceGUIContainer
---@param mapID integer
---@param callback function
local function drawMapGroup(group, mapID, callback)
	local phaseSparkTriggers = SparkPopups.SparkPopups.getPhaseSparkTriggersCache()

	group.mapID = mapID

	-- Need to redraw again for when icon editbox/button are shown and hidden
	group:ReleaseChildren()

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- groupScrollContainer

	local groupScrollContainer = AceGUI:Create("SimpleGroup") --[[@as AceGUISimpleGroup]]
	groupScrollContainer:SetFullWidth(true)
	groupScrollContainer:SetFullHeight(true)
	groupScrollContainer:SetLayout("Fill")
	group:AddChild(groupScrollContainer)

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- groupScrollFrame

	local groupScrollFrame = AceGUI:Create("ScrollFrame") --[[@as AceGUIScrollFrame]]
	groupScrollFrame:SetFullWidth(true)
	groupScrollFrame:SetFullHeight(true)
	groupScrollFrame:SetLayout("Flow")
	groupScrollContainer:AddChild(groupScrollFrame)

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- gen our inline groups
	if not phaseSparkTriggers or not phaseSparkTriggers[mapID] then
		local noSparksLabel = AceGUI:Create("Label") --[[@as AceGUILabel]]
		noSparksLabel:SetText("There are no Sparks on this map.")
		noSparksLabel:SetRelativeWidth(1)
		groupScrollFrame:AddChild(noSparksLabel)
		return
	end
	for k, triggerData in ipairs(phaseSparkTriggers[mapID]) do
		local triggerGroup = AceGUI:Create("InlineGroup") --[[@as AceGUIInlineGroup]]
		triggerGroup:SetLayout("Flow")
		triggerGroup:SetRelativeWidth(1)
		triggerGroup:SetAutoAdjustHeight(false)
		triggerGroup:SetHeight(115)
		triggerGroup:SetTitle(k .. ". " .. Tooltip.genContrastText(triggerData[1]) .. " Trigger")
		groupScrollFrame:AddChild(triggerGroup)

		local triggerInfoSection = AceGUI:Create("SimpleGroup") --[[@as AceGUISimpleGroup]]
		triggerInfoSection:SetLayout("List")
		triggerInfoSection:SetRelativeWidth(0.3)
		triggerInfoSection:SetAutoAdjustHeight(false)
		triggerInfoSection:SetHeight(50)
		triggerGroup:AddChild(triggerInfoSection)
		local numExtraLines = 0

		do
			local xLabel = AceGUI:Create("Label") --[[@as AceGUILabel]]
			xLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("X: ") .. round(verifyNumber(triggerData[2]), 4))
			xLabel:SetRelativeWidth(1)
			triggerInfoSection:AddChild(xLabel)

			local yLabel = AceGUI:Create("Label") --[[@as AceGUILabel]]
			yLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Y: ") .. round(verifyNumber(triggerData[3]), 4))
			yLabel:SetRelativeWidth(1)
			triggerInfoSection:AddChild(yLabel)

			local zLabel = AceGUI:Create("Label") --[[@as AceGUILabel]]
			zLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Z: ") .. round(verifyNumber(triggerData[4]), 4))
			zLabel:SetRelativeWidth(1)
			triggerInfoSection:AddChild(zLabel)

			local radiusLabel = AceGUI:Create("Label") --[[@as AceGUILabel]]
			radiusLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Radius: ") .. round(triggerData[5], 4))
			radiusLabel:SetRelativeWidth(1)
			triggerInfoSection:AddChild(radiusLabel)

			local tintLabel = AceGUI:Create("Label") --[[@as AceGUILabel]]
			local colorHex = triggerData[7]
			tintLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Tint: ") .. (colorHex and WrapTextInColorCode(colorHex, colorHex) or "None"))
			tintLabel:SetRelativeWidth(1)
			triggerInfoSection:AddChild(tintLabel)

			local popupOptions = triggerData[8] --[[@as PopupTriggerOptions]]
			if popupOptions then
				if popupOptions.cooldownTime then
					local cdTimeLabel = AceGUI:Create("Label") --[[@as AceGUILabel]]
					cdTimeLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("CD: ") .. tostring((popupOptions.cooldownTime) .. "s"))
					cdTimeLabel:SetRelativeWidth(1)
					triggerInfoSection:AddChild(cdTimeLabel)
					numExtraLines = numExtraLines + 1
				end
				if (popupOptions.conditions and #popupOptions.conditions > 0) or popupOptions.requirement then
					local requirementLabel = AceGUI:Create("InteractiveLabel") --[[@as AceGUIInteractiveLabel]]
					requirementLabel:SetText(ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Has Conditions"))
					requirementLabel:SetRelativeWidth(1)
					Tooltip.setAceTT(requirementLabel, "Conditions:", function()
						local lines = {
							" "
						}
						if popupOptions.conditions and #popupOptions.conditions > 0 then
							for gi, groupData in ipairs(popupOptions.conditions) do
								local groupString = (gi == 1 and "If") or "..Or"
								for ri, rowData in ipairs(groupData) do
									local continueStatement = (ri ~= 1 and "and ") or ""
									local condName = ns.Actions.ConditionsData.getByKey(rowData.Type).name
									groupString = string.join(" ", groupString, continueStatement .. condName)
								end
								tinsert(lines, groupString)
							end
						else
							tinsert(lines, "This Spark has Legacy Requirements. Edit & Resave to convert to Conditions!")
						end
						return lines
					end, { forced = true, delay = 0 })
					triggerInfoSection:AddChild(requirementLabel)
					numExtraLines = numExtraLines + 1
				end
			end
		end

		triggerInfoSection:SetHeight(50 + (numExtraLines * 10))

		local triggerIconSection = AceGUI:Create("SimpleGroup") --[[@as AceGUISimpleGroup]]
		triggerIconSection:SetLayout("Flow")
		triggerIconSection:SetRelativeWidth(0.39)
		--triggerIconSection:SetFullHeight(true)
		triggerGroup:AddChild(triggerIconSection)

		do
			local styleBorder = AceGUI:Create("Label") --[[@as AceGUILabel]]
			local styleBorderImage = triggerData[6]
			if type(styleBorderImage) == "string" then styleBorderImage = styleBorderImage:gsub("SpellCreator%-dev", "SpellCreator"):gsub("SpellCreator", addonName) end
			styleBorder:SetImage(styleBorderImage)
			styleBorder:SetImageSize(128, 64)
			styleBorder:SetRelativeWidth(1)
			if triggerData[7] then -- if there's a color hex code
				styleBorder.image:SetVertexColor(CreateColorFromHexString(triggerData[7]):GetRGB())
			else          -- reset it to white if not, because it will not do that automatically
				styleBorder.image:SetVertexColor(1, 1, 1, 1)
			end
			styleBorder:SetCallback("OnRelease", function(widget) widget.image:SetVertexColor(1, 1, 1, 1) end)
			triggerIconSection:AddChild(styleBorder)
			triggerIconSection:SetAutoAdjustHeight(false)

			local spellIcon = AceGUI:Create("Label") --[[@as AceGUILabel]]
			local theSpell = ns.Vault.phase.findSpellByID(triggerData[1])
			if theSpell then
				spellIcon:SetImage(ns.UI.Icons.getFinalIcon(theSpell.icon))
				spellIcon:SetImageSize(24, 24)
			end
			spellIcon:SetHeight(0)
			spellIcon:SetRelativeWidth(1)
			triggerIconSection:AddChild(spellIcon)
			--triggerIconSection:PauseLayout()

			triggerIconSection:DoLayout()

			C_Timer.After(0, function()
				spellIcon.image:ClearAllPoints()
				spellIcon.image:SetPoint("CENTER", styleBorder.image, "CENTER")
				spellIcon.image:SetSize(24, 24)
				local layer, sublayer = styleBorder.image:GetDrawLayer()
				spellIcon.image:SetDrawLayer(layer, sublayer - 1)
			end)
		end

		local triggerButtonsSection = AceGUI:Create("SimpleGroup") --[[@as AceGUISimpleGroup]]
		triggerButtonsSection:SetLayout("List")
		triggerButtonsSection:SetAutoAdjustHeight(false)
		triggerButtonsSection:SetHeight(70)
		triggerButtonsSection:SetRelativeWidth(0.3)
		triggerGroup:AddChild(triggerButtonsSection)

		do
			local editButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
			editButton:SetText("Edit")
			editButton:SetRelativeWidth(1)
			editButton:SetCallback("OnClick", function() sparkEditButtonClick(mapID, k) end)
			editButton:SetDisabled((not Permissions.isOfficerPlus() and not SpellCreatorMasterTable.Options["debug"]))
			triggerButtonsSection:AddChild(editButton)

			local gotoButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
			gotoButton:SetText("Go To")
			gotoButton:SetRelativeWidth(1)
			gotoButton:SetDisabled((not Permissions.isMemberPlus() and not SpellCreatorMasterTable.Options["debug"]))
			gotoButton:SetCallback("OnClick", function()
				cmd(string.format("worldport %s %s %s %s", triggerData[2], triggerData[3], triggerData[4], mapID))
			end)
			triggerButtonsSection:AddChild(gotoButton)

			local deleteButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
			deleteButton:SetText("Delete")
			deleteButton:SetRelativeWidth(1)
			deleteButton:SetDisabled((not Permissions.isOfficerPlus() and not SpellCreatorMasterTable.Options["debug"]))
			deleteButton:SetCallback("OnClick", function()
				Popups.showGenericConfirmation(
					("Are you sure you want to delete this Spark Trigger for %s?"):format(Tooltip.genContrastText(triggerData[1])),
					function() SparkPopups.SparkPopups.removeTriggerFromPhaseDataByMapAndIndex(mapID, k, callback) end
				)
			end)
			triggerButtonsSection:AddChild(deleteButton)
		end
		triggerButtonsSection:DoLayout()
		triggerGroup:DoLayout()
	end
end

local function hideSparkManagerUI()
	if sparkManagerUI and sparkManagerUI:IsShown() then sparkManagerUI:Release() end
end

---@param mapSelectOverride integer? The map ID to open the UI to
local function showSparkManagerUI(mapSelectOverride)
	hideSparkManagerUI()

	local frame = AceGUI:Create("Frame") --[[@as AceGUIFrame]]
	frame:SetTitle("Arcanum - Spark Manager")
	frame:SetWidth(600)
	frame:SetHeight(525)
	frame:SetLayout("Fill")
	frame:SetCallback("OnClose", hideSparkManagerUI)
	frame:EnableResize(false)
	sparkManagerUI = frame

	local mapSelectTree = AceGUI:Create("TreeGroup") --[[@as AceGUITreeGroup]]
	mapSelectTree:SetFullHeight(true)
	mapSelectTree:SetLayout("Flow")
	mapSelectTree:SetTree(getSparkManagerMapTree())
	mapSelectTree:SetTreeWidth(200, false)
	frame:AddChild(mapSelectTree)

	local resetMeCallback = function(shownMap)
		hideSparkManagerUI();
		showSparkManagerUI(shownMap);
	end

	mapSelectTree:SetCallback("OnGroupSelected", function(container, _, selectedMap)
		container:ReleaseChildren()
		drawMapGroup(container, selectedMap, resetMeCallback)
	end)

	local phaseSparkTriggers = SparkPopups.SparkPopups.getPhaseSparkTriggersCache()
	if not phaseSparkTriggers then phaseSparkTriggers = { [curMapID] = {} } end

	local mapToSelect = (phaseSparkTriggers[mapSelectOverride] and mapSelectOverride or (phaseSparkTriggers[curMapID] and curMapID or next(phaseSparkTriggers)))
	mapSelectTree:SelectByPath(mapToSelect)
end

---@param shownMap integer? The map ID to re-open the UI to
local function refreshSparkManagerUI(shownMap)
	if sparkManagerUI and sparkManagerUI:IsShown() then
		hideSparkManagerUI();
		showSparkManagerUI(shownMap);
	end
end

---@class UI_SparkPopups_SparkManagerUI
ns.UI.SparkPopups.SparkManagerUI = {
	showSparkManagerUI = showSparkManagerUI,
	refreshSparkManagerUI = refreshSparkManagerUI,
	hideSparkManagerUI = hideSparkManagerUI,
}
