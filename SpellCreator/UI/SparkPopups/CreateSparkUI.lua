---@class ns
local ns = select(2, ...)

local DataUtils = ns.Utils.Data
local AceConfig = ns.Libs.AceConfig
local AceConfigDialog = ns.Libs.AceConfigDialog
local SparkPopups = ns.UI.SparkPopups
local ASSETS_PATH = ns.Constants.ASSETS_PATH
local ADDON_COLORS = ns.Constants.ADDON_COLORS
local SPARK_ASSETS_PATH = ASSETS_PATH .. "/Sparks/"
local Tooltip = ns.Utils.Tooltip

local getPlayerPositionData = C_Epsilon.GetPosition or function() return UnitPosition("player") end

local theUIDialogName = "ARCANUM_SPARK_CREATE"
local defaultSparkPopupStyle = 629199 -- "Interface\\ExtraButton\\Default";
local addNewSparkPopupStyleTex = 308477
local customStyleTexIter = 0

local sparkPopupStyles = { -- You can still use one not listed here technically, but these are the ones supported in the UI.
	{ 629199,                                          "Default" },
	{ 629198,                                          "Champion Light" },
	{ 629200,                                          "Feng Barrier" },
	{ 629201,                                          "Feng Shroud" },
	{ 629202,                                          "Ultra Xion" },
	{ 629203,                                          "Ysera" },
	{ 629479,                                          "Green Keg" },
	{ 629480,                                          "Smash" },
	{ 629738,                                          "Brown Keg" },
	{ 653590,                                          "Lightning Keg" },
	{ 654130,                                          "Hozu Bar" },
	{ 667434,                                          "Airstrike" },
	{ 774879,                                          "Engineering" },
	{ 796702,                                          "Soulswap" },
	{ 876185,                                          "Amber" },
	{ 1016651,                                         "Garr. Armory" },
	{ 1016652,                                         "Garr. Alliance" },
	{ 1016653,                                         "Garr. Horde" },
	{ 1016654,                                         "Garr. Inn (Hearthstone)" },
	{ 1016655,                                         "Garr. Lumbermill" },
	{ 1016656,                                         "Garr. Mage Tower" },
	{ 1016657,                                         "Garr. Stables" },
	{ 1016658,                                         "Garr. Trading Post" },
	{ 1016659,                                         "Garr. Training Pit" },
	{ 1016660,                                         "Garr. Workshop" },
	{ 1129687,                                         "Eye of Terrok" },
	{ 1466424,                                         "Fel" },
	{ 1589183,                                         "Soulcage" },
	{ 2203955,                                         "Heart of Az. Active" },
	{ 2203956,                                         "Heart of Az. Minimal" },
	{ SPARK_ASSETS_PATH .. "1Simple",                  "Arcanum - Simple" },
	{ SPARK_ASSETS_PATH .. "1Ornate",                  "Arcanum - Ornate" },
	{ SPARK_ASSETS_PATH .. "1OrnateBG",                "Arcanum - Aurora" },
	{ SPARK_ASSETS_PATH .. "2Simple",                  "Arc Lens - Simple" },
	{ SPARK_ASSETS_PATH .. "2CustomRed",               "Arc Lens - Red" },
	{ SPARK_ASSETS_PATH .. "2CustomOrange",            "Arc Lens - Orange" },
	{ SPARK_ASSETS_PATH .. "2CustomYellow",            "Arc Lens - Yellow" },
	{ SPARK_ASSETS_PATH .. "2CustomGreen",             "Arc Lens - Green" },
	{ SPARK_ASSETS_PATH .. "2CustomJade",              "Arc Lens - Jade" },
	{ SPARK_ASSETS_PATH .. "2CustomBlue",              "Arc Lens - Blue" },
	{ SPARK_ASSETS_PATH .. "2CustomIndigo",            "Arc Lens - Indigo" },
	{ SPARK_ASSETS_PATH .. "2CustomViolet",            "Arc Lens - Violet" },
	{ SPARK_ASSETS_PATH .. "2CustomPink",              "Arc Lens - Pink" },
	{ SPARK_ASSETS_PATH .. "2CustomPrismatic",         "Arc Lens - Prismatic" },
	{ SPARK_ASSETS_PATH .. "dicemaster_sanctum",       "DiceMaster Sanctum" },
	{ SPARK_ASSETS_PATH .. "ethereal-xtrabtn",         "Arc+Dice - Ethereal" },
	{ SPARK_ASSETS_PATH .. "nzoth-xtrabtn",            "Arc+Dice - Nzoth" },
	{ SPARK_ASSETS_PATH .. "forsaken-xtrabtn",         "Arc+Dice - Forsaken" },
	{ SPARK_ASSETS_PATH .. "worgen-xtrabtn",           "Arc+Dice - Worgen" },

	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_metal",    "SF Dragon - Metal" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_arcane",   "SF Dragon - Arcane" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_black",    "SF Dragon - Black" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_blue",     "SF Dragon - Blue" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_bronze",   "SF Dragon - Bronze" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_brown",    "SF Dragon - Brown" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_darkblue", "SF Dragon - Darkblue" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_emerald",  "SF Dragon - Emerald" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_green",    "SF Dragon - Green" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_infinite", "SF Dragon - Infinite" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_jade",     "SF Dragon - Jade" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_orange",   "SF Dragon - Orange" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_phoenix",  "SF Dragon - Phoenix" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_pink",     "SF Dragon - Pink" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_purple",   "SF Dragon - Purple" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_red",      "SF Dragon - Red" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_ruby",     "SF Dragon - Ruby" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_white",    "SF Dragon - White" },
	{ SPARK_ASSETS_PATH .. "sf_dragon_frame_yellow",   "SF Dragon - Yellow" },

	-- always last
	{ addNewSparkPopupStyleTex,                        "Add Other/Custom" },
	-- 	{ SPARK_ASSETS_PATH .. "CustomFrameFile", "Custom Frame 1"},
}

local sparkPopupStylesKVTable = {}
local sparkPopupStylesSortTable = {}
for k, v in ipairs(sparkPopupStyles) do
	local newKey = v[1]
	local newVal = CreateTextureMarkup(v[1], 48, 24, 48, 24, 0, 1, 0, 1) .. " " .. v[2]
	sparkPopupStylesKVTable[newKey] = newVal
	tinsert(sparkPopupStylesSortTable, newKey)
end

local sparkUI_Helper = {
	commID = "Type a CommID",
	radius = 5,
	style = defaultSparkPopupStyle,
	x = 0,
	y = 0,
	z = 0,
	mapID = 0,
	overwriteIndex = nil,
	cooldownTime = false,
	cooldownTriggerSpellCooldown = false,
	cooldownBroadcastToPhase = false,
}

---@param num integer
---@return number
local function getPosData(num)
	return DataUtils.roundToNthDecimal(select(num, getPlayerPositionData()), 4)
end

local orderGroup = 0
local orderItem = 0
---Auto incrementing order number. Use isGroup true to increment the orderGroup and reset the orderItem counter.
---@param isGroup boolean?
---@return integer
local function autoOrder(isGroup)
	if isGroup then
		orderGroup = orderGroup + 1
		orderItem = 0
		return orderGroup
	else
		orderItem = orderItem + 1
		return orderItem
	end
end

local uiOptionsTable = {
	type = "group",
	desc = "test",
	name = "Arcanum - Spark Creator",
	args = {
		spellInfo = {
			name = "Spark Info",
			type = "group",
			inline = true,
			order = autoOrder(true),
			args = {
				commID = {
					name = "ArcSpell",
					desc = "CommID of the ArcSpell from the Phase Vault",
					type = "input",
					dialogControl = "MAW-Editbox",
					order = autoOrder(),
					set = function(info, val) sparkUI_Helper.commID = val end,
					get = function(info) return sparkUI_Helper.commID end
				},
				style = {
					name = "Border Style",
					desc = "The decorative border around the Spark spell icon",
					type = "select",
					width = 1.2,
					values = sparkPopupStylesKVTable,
					sorting = sparkPopupStylesSortTable,
					order = autoOrder(),
					set = function(info, val)
						if val == addNewSparkPopupStyleTex then
							ns.UI.Popups.showCustomGenericInputBox({
								text = "Texture Path or FileID:",
								acceptText = ADD,
								maxLetters = 999,
								callback = function(texPath)
									if tonumber(texPath) then texPath = tonumber(texPath) end
									local newKey = texPath -- path
									if not sparkPopupStylesKVTable[newKey] then
										customStyleTexIter = customStyleTexIter + 1
										local newVal = CreateTextureMarkup(texPath, 48, 24, 48, 24, 0, 1, 0, 1) .. " Custom Texture " .. customStyleTexIter -- texture markup + name
										sparkPopupStylesKVTable[newKey] = newVal
										tinsert(sparkPopupStylesSortTable, newKey)
									end
									sparkUI_Helper.style = newKey
									AceConfigDialog:Open(theUIDialogName)
								end,
							})
							return
						end
						sparkUI_Helper.style = val
					end,
					get = function(info) return sparkUI_Helper.style end
				},
				styleColor = {
					name = ADDON_COLORS.GAME_GOLD:WrapTextInColorCode("Border Tint"),
					desc = "Tint the Border Style (Border Tint does not show in the Spark Creator preview, sorry)",
					type = "color",
					width = 0.66,
					order = autoOrder(),
					set = function(info, vR, vG, vB)
						if vR and vG and vB then
							sparkUI_Helper.color = CreateColor(vR, vG, vB):GenerateHexColor()
						else
							sparkUI_Helper.color = nil
						end
					end,
					get = function(info)
						if sparkUI_Helper.color then
							return CreateColorFromHexString(sparkUI_Helper.color):GetRGB()
						else
							return 1, 1, 1
						end
					end
				},
				cooldownTime = {
					name = "Spark Cooldown Override",
					dialogControl = "MAW-Editbox",
					desc = "Sets a cooldown on this Spark. Spark Cooldowns override spell cooldowns, and only apply for this instance of the Spell.",
					type = "input",
					order = autoOrder(),
					get = function()
						if sparkUI_Helper.cooldownTime then
							return sparkUI_Helper.cooldownTime
						else
							return 0
						end
					end,
					set = function(info, val)
						if val and val ~= "" then
							sparkUI_Helper.cooldownTime = val
						else
							sparkUI_Helper.cooldownTime = nil
						end
					end,
					width = 0.8,
				},
				cooldownTriggerSpellCooldown = {
					type = "toggle",
					name = "Trigger Spell Cooldown",
					desc = "When enabled, the Spark will still toggle both it's own Cooldown, and the Spells' cooldown.\nIf disabled, only this Spark's cooldown is triggered.",
					order = autoOrder(),
					get = function()
						if sparkUI_Helper.cooldownTriggerSpellCooldown ~= nil then
							return sparkUI_Helper.cooldownTriggerSpellCooldown
						else
							return false
						end
					end,
					set = function(info, val)
						sparkUI_Helper.cooldownTriggerSpellCooldown = val
					end,
					disabled = function() return not sparkUI_Helper.cooldownTime end,
					width = 1.2,
				},
				cooldownBroadcastToPhase = {
					type = "toggle",
					name = "Broadcast Cooldown",
					desc =
					"When enabled, the Spark Cooldown is sent to everyone in the phase, and they will have the same cooldown.\n\rNote: The main spells' cooldown is NOT triggered for them, ONLY this single Spark's!\n\rNote note: This is broadcast to the phase when triggered; if anyone joins the phase AFTER, they will NOT be subject to the cooldown. Deal with it.",
					order = autoOrder(),
					get = function()
						if sparkUI_Helper.cooldownBroadcastToPhase ~= nil then
							return sparkUI_Helper.cooldownBroadcastToPhase
						else
							return false
						end
					end,
					set = function(info, val)
						sparkUI_Helper.cooldownBroadcastToPhase = val
					end,
					disabled = function() return not sparkUI_Helper.cooldownTime end,
					width = 1,
				},
				requirementScript = {
					name = "Spark Requirement (Script)",
					dialogControl = "MAW-Editbox",
					desc =
						"Sets a requirement on this Spark via a script. If the script does not return a true value, then the Spark will not be shown.\n\rExample Scripts:\n" ..
						Tooltip.genContrastText("ARC.XAPI.HasItem(19222)") ..
						" to only show if they have atleast one \124cff1eff00\124Hitem:19222::::::::70:::::\124h[Cheap Beer]\124h\124r item." .. "\n\r" ..
						Tooltip.genContrastText("ARC.XAPI.HasAura(131437)") .. " to only show if they have \124cff71d5ff\124Hspell:131437\124h[See Quest Invis 9]\124h\124r aura." .. "\n\r" ..
						Tooltip.genContrastText("GetItemCount(108499) >= 23") ..
						" to only show if they have 23 or more \124cff1eff00\124Hitem:108499::::::::70:::::\124h[Soothepetal Flower]\124h\124r in their inventory." .. "\n\r" ..
						Tooltip.genContrastText("ARC.PHASE.IsMember()") .. " to only show if they are a Member of the Phase.",
					type = "input",
					order = autoOrder(),
					get = function()
						if sparkUI_Helper.requirement then
							return sparkUI_Helper.requirement
						else
							return 0
						end
					end,
					set = function(info, val)
						if val and val ~= "" then
							sparkUI_Helper.requirement = val
						else
							sparkUI_Helper.requirement = nil
						end
					end,
					width = "full",
				},
				stylePreviewTitle = {
					type = "description",
					name = "\nBorder Preview:",
					order = autoOrder(),
				},
				stylePreview = {
					--name = ""
					name = function()
						local vR, vG, vB = 255, 255, 255
						if sparkUI_Helper.color then vR, vG, vB = CreateColorFromHexString(sparkUI_Helper.color):GetRGBAsBytes() end
						return ns.Utils.UIHelpers.CreateTextureMarkupWithColor(sparkUI_Helper.style, 64 * 2, 32 * 2, 64 * 2, 32 * 2, 0, 1, 0, 1, 0, 0, vR, vG, vB)
					end,
					type = "header",
					width = "full",
					order = autoOrder(),
					--image = function() return sparkUI_Helper.style, 64 * 2, 32 * 2 end,
				},
				spacer = {
					name = " ",
					type = "description",
					width = "full",
					order = autoOrder(),
				},
			}
		},
		locationInfo = {
			name = "Trigger Location (Default: Your current location)",
			type = "group",
			inline = true,
			order = autoOrder(true),
			args = {
				xPos = {
					name = "X",
					desc = "The X Coordinate of the Trigger. Default is your current location.",
					type = "input",
					dialogControl = "MAW-Editbox",
					validate = function(info, val) return tonumber(val) end,
					order = autoOrder(),
					set = function(info, val) sparkUI_Helper.x = (tonumber(val) and tonumber(val) or tonumber(getPosData(1))) end,
					get = function(info) return sparkUI_Helper.x and tostring(sparkUI_Helper.x) or tostring(getPosData(1)) end,
				},
				yPos = {
					name = "Y",
					desc = "The Y Coordinate of the Trigger. Default is your current location.",
					type = "input",
					dialogControl = "MAW-Editbox",
					validate = function(info, val) if tonumber(val) then return true else return "You need to supply a valid number!" end end,
					order = autoOrder(),
					set = function(info, val) sparkUI_Helper.y = (tonumber(val) and tonumber(val) or tonumber(getPosData(2))) end,
					get = function(info) return sparkUI_Helper.y and tostring(sparkUI_Helper.y) or tostring(getPosData(2)) end,
				},
				zPos = {
					name = "Z",
					desc = "The Z Coordinate of the Trigger. Default is your current location.",
					type = "input",
					dialogControl = "MAW-Editbox",
					validate = function(info, val) if tonumber(val) then return true else return "You need to supply a valid number!" end end,
					order = autoOrder(),
					set = function(info, val) sparkUI_Helper.z = (tonumber(val) and tonumber(val) or tonumber(getPosData(3))) end,
					get = function(info) return sparkUI_Helper.z and tostring(sparkUI_Helper.z) or tostring(getPosData(3)) end,
				},
				mapID = {
					name = "Map ID",
					desc = "The X Coordinate of the Trigger. Default is your current location.",
					type = "input",
					dialogControl = "MAW-Editbox",
					pattern = "%d+",
					validate = function(info, val) if tonumber(val) then return true else return "You need to supply a valid number!" end end,
					order = autoOrder(),
					set = function(info, val) sparkUI_Helper.mapID = tonumber(val) end,
					get = function(info) return sparkUI_Helper.mapID and tostring(sparkUI_Helper.mapID) or tostring(getPosData(4)) end,
				},
				radius = {
					name = "Radius",
					desc = "How close to the point a player must be to show the Spark.",
					type = "range",
					dialogControl = "MAW-Slider",
					min = 0,
					max = 100,
					softMin = 0.25,
					softMax = 20,
					bigStep = 0.25,
					width = "double",
					order = autoOrder(),
					set = function(info, val) sparkUI_Helper.radius = val end,
					get = function(info) return sparkUI_Helper.radius end,
				},
			},
		},
		createButton = {
			type = "execute",
			name = function() if sparkUI_Helper.overwriteIndex then return "Save Spark" else return "Create Spark" end end,
			width = "full",
			func = function()
				SparkPopups.SparkPopups.addPopupTriggerToPhaseData(sparkUI_Helper.commID, sparkUI_Helper.radius, sparkUI_Helper.style, sparkUI_Helper.x, sparkUI_Helper.y, sparkUI_Helper.z,
					sparkUI_Helper.color,
					sparkUI_Helper.mapID,
					{
						cooldownTime = sparkUI_Helper.cooldownTime,
						trigSpellCooldown = sparkUI_Helper.cooldownTriggerSpellCooldown,
						broadcastCooldown = sparkUI_Helper.cooldownBroadcastToPhase,
						requirement = sparkUI_Helper.requirement
					},
					sparkUI_Helper.overwriteIndex)
				AceConfigDialog:Close(theUIDialogName)
			end,
		},
	}
}

AceConfig:RegisterOptionsTable(theUIDialogName, uiOptionsTable)
AceConfigDialog:SetDefaultSize(theUIDialogName, 600, 495)

---@param num number the number to verify if it's a number
---@return number
local function verifyNumber(num)
	if num then return num else return 99999999 end
end

---comment
---@param commID CommID
---@param editIndex integer?
---@param editMapID integer?
local function openSparkCreationUI(commID, editIndex, editMapID)
	sparkUI_Helper.overwriteIndex = editIndex or nil
	sparkUI_Helper.commID = commID

	local x, y, z, mapID, radius, style, colorHex, cooldownTime, cooldownTriggerSpellCooldown, cooldownBroadcastToPhase, requirement
	if editIndex then
		local phaseSparkTriggers = SparkPopups.SparkPopups.getPhaseSparkTriggersCache()
		local triggerData = phaseSparkTriggers[editMapID][editIndex]
		x, y, z, mapID, radius, style, colorHex = triggerData[2], triggerData[3], triggerData[4], editMapID, triggerData[5], triggerData[6], triggerData[7]
		local sparkOptions = triggerData[8] --[[@as PopupTriggerOptions]]
		if sparkOptions ~= nil then
			cooldownTime, cooldownTriggerSpellCooldown, cooldownBroadcastToPhase = sparkOptions.cooldownTime, sparkOptions.trigSpellCooldown, sparkOptions.broadcastCooldown
			requirement = sparkOptions.requirement
		end
	else
		radius = 5
		x, y, z, mapID = getPlayerPositionData()
		style = defaultSparkPopupStyle
		colorHex = "ffffffff"
		cooldownTime = false
		cooldownTriggerSpellCooldown = false
		cooldownBroadcastToPhase = false
		requirement = nil
	end

	x, y, z = DataUtils.roundToNthDecimal(verifyNumber(x), 4), DataUtils.roundToNthDecimal(verifyNumber(y), 4), DataUtils.roundToNthDecimal(verifyNumber(z), 4)
	sparkUI_Helper.x, sparkUI_Helper.y, sparkUI_Helper.z, sparkUI_Helper.mapID, sparkUI_Helper.radius, sparkUI_Helper.style, sparkUI_Helper.color = x, y, z, mapID, radius, style, colorHex
	sparkUI_Helper.cooldownTime, sparkUI_Helper.cooldownTriggerSpellCooldown, sparkUI_Helper.cooldownBroadcastToPhase = cooldownTime, cooldownTriggerSpellCooldown, cooldownBroadcastToPhase
	sparkUI_Helper.requirement = requirement
	AceConfigDialog:Open(theUIDialogName)
end

local function closeSparkCreationUI()
	AceConfigDialog:Close(theUIDialogName)
end

---@class UI_SparkPopups_CreateSparkUI
ns.UI.SparkPopups.CreateSparkUI = {
	openSparkCreationUI = openSparkCreationUI,
	closeSparkCreationUI = closeSparkCreationUI,
	sparkPopupStyles = sparkPopupStylesKVTable,
}
