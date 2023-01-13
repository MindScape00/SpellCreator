---@class ns
local ns = select(2, ...)

local DataUtils = ns.Utils.Data
local AceConfig = ns.Libs.AceConfig
local AceConfigDialog = ns.Libs.AceConfigDialog
local SparkPopups = ns.UI.SparkPopups
local ASSETS_PATH = ns.Constants.ASSETS_PATH
local ADDON_COLORS = ns.Constants.ADDON_COLORS

local getPlayerPositionData = C_Epsilon.GetPosition or function() return UnitPosition("player") end

local theUIDialogName = "ARCANUM_SPARK_CREATE"
local defaultSparkPopupStyle = 629199 -- "Interface\\ExtraButton\\Default";

local sparkPopupStyles = { -- You can still use one not listed here, but this is for giving them UI to choose one easier later
	{ 629199, "Default" },
	{ 629198, "Champion Light" },
	{ 629200, "Feng Barrier" },
	{ 629201, "Feng Shroud" },
	{ 629202, "Ultra Xion" },
	{ 629203, "Ysera" },
	{ 629479, "Green Keg" },
	{ 629480, "Smash" },
	{ 629738, "Brown Keg" },
	{ 653590, "Lightning Keg" },
	{ 654130, "Hozu Bar" },
	{ 667434, "Airstrike" },
	{ 774879, "Engineering" },
	{ 796702, "Soulswap" },
	{ 876185, "Amber" },
	{ 1016651, "Garrison Armory" },
	{ 1016652, "Garrison Alliance" },
	{ 1016653, "Garrison Horde" },
	{ 1016654, "Garrison Inn (Hearthstone)" },
	{ 1016655, "Garrison Lumbermill" },
	{ 1016656, "Garrison Mage Tower" },
	{ 1016657, "Garrison Stables" },
	{ 1016658, "Garrison Trading Post" },
	{ 1016659, "Garrison Training Pit" },
	{ 1016660, "Garrison Workshop" },
	{ 1129687, "Eye of Terrok" },
	{ 1466424, "Fel" },
	{ 1589183, "Soulcage" },
	{ 2203955, "Heart of Azeroth (Active)" },
	{ 2203956, "Heart of Azeroth (Min)" },
	-- 	{ ASSETS_PATH .. "/CustomFrame", "Custom Frame 1"}
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
					set = function(info, val) sparkUI_Helper.style = val end,
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
				stylePreview = {
					name = "",
					type = "description",
					width = "full",
					order = autoOrder(),
					image = function() return sparkUI_Helper.style, 64 * 2, 32 * 2 end,
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
					validate = function(info, val) return tonumber(val) end,
					order = autoOrder(),
					set = function(info, val) sparkUI_Helper.x = (tonumber(val) and tonumber(val) or tonumber(getPosData(1))) end,
					get = function(info) return sparkUI_Helper.x and tostring(sparkUI_Helper.x) or tostring(getPosData(1)) end,
				},
				yPos = {
					name = "Y",
					desc = "The Y Coordinate of the Trigger. Default is your current location.",
					type = "input",
					validate = function(info, val) if tonumber(val) then return true else return "You need to supply a valid number!" end end,
					order = autoOrder(),
					set = function(info, val) sparkUI_Helper.y = (tonumber(val) and tonumber(val) or tonumber(getPosData(2))) end,
					get = function(info) return sparkUI_Helper.y and tostring(sparkUI_Helper.y) or tostring(getPosData(2)) end,
				},
				zPos = {
					name = "Z",
					desc = "The Z Coordinate of the Trigger. Default is your current location.",
					type = "input",
					validate = function(info, val) if tonumber(val) then return true else return "You need to supply a valid number!" end end,
					order = autoOrder(),
					set = function(info, val) sparkUI_Helper.z = (tonumber(val) and tonumber(val) or tonumber(getPosData(3))) end,
					get = function(info) return sparkUI_Helper.z and tostring(sparkUI_Helper.z) or tostring(getPosData(3)) end,
				},
				mapID = {
					name = "Map ID",
					desc = "The X Coordinate of the Trigger. Default is your current location.",
					type = "input",
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
				SparkPopups.SparkPopups.addPopupTriggerToPhaseData(sparkUI_Helper.commID, sparkUI_Helper.radius, sparkUI_Helper.style, sparkUI_Helper.x, sparkUI_Helper.y, sparkUI_Helper.z, sparkUI_Helper.color,
					sparkUI_Helper.mapID,
					sparkUI_Helper.overwriteIndex)
				AceConfigDialog:Close(theUIDialogName)
			end,
		},
	}
}

AceConfig:RegisterOptionsTable(theUIDialogName, uiOptionsTable)
AceConfigDialog:SetDefaultSize(theUIDialogName, 600, 420)

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

	local x, y, z, mapID, radius, style, colorHex
	if editIndex then
		local phaseSparkTriggers = SparkPopups.SparkPopups.getPhaseSparkTriggersCache()
		local triggerData = phaseSparkTriggers[editMapID][editIndex]
		x, y, z, mapID, radius, style, colorHex = triggerData[2], triggerData[3], triggerData[4], editMapID, triggerData[5], triggerData[6], triggerData[7]
	else
		radius = 5
		x, y, z, mapID = getPlayerPositionData()
		style = defaultSparkPopupStyle
		colorHex = "ffffffff"
	end

	x, y, z = DataUtils.roundToNthDecimal(verifyNumber(x), 4), DataUtils.roundToNthDecimal(verifyNumber(y), 4), DataUtils.roundToNthDecimal(verifyNumber(z), 4)
	sparkUI_Helper.x, sparkUI_Helper.y, sparkUI_Helper.z, sparkUI_Helper.mapID, sparkUI_Helper.radius, sparkUI_Helper.style, sparkUI_Helper.color = x, y, z, mapID, radius, style, colorHex
	AceConfigDialog:Open(theUIDialogName)
end

---@class UI_SparkPopups_CreateSparkUI
ns.UI.SparkPopups.CreateSparkUI = {
	openSparkCreationUI = openSparkCreationUI,
	sparkPopupStyles = sparkPopupStylesKVTable,
}
