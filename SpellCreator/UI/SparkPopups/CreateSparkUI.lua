---@class ns
local ns = select(2, ...)

local SavedVariables = ns.SavedVariables
local Constants = ns.Constants

local DataUtils = ns.Utils.Data
local AceConfig = ns.Libs.AceConfig
local AceConfigDialog = ns.Libs.AceConfigDialog
local SparkPopups = ns.UI.SparkPopups
local ASSETS_PATH = ns.Constants.ASSETS_PATH
local ADDON_COLORS = ns.Constants.ADDON_COLORS
local SPARK_ASSETS_PATH = ASSETS_PATH .. "/Sparks/"
local Tooltip = ns.Utils.Tooltip

local getPlayerPositionData = C_Epsilon.GetPosition or function() return UnitPosition("player") end

local theUIDialogName = Constants.SPARK_CREATE_UI_NAME
local defaultSparkPopupStyle = 629199 -- "Interface\\ExtraButton\\Default";
local addNewSparkPopupStyleTex = 308477
local customStyleTexIter = 0

local event_unlock_dates = { -- add event unlock here, modify the function below
	--halloween2023 = Constants.eventUnlockDates.halloween2023
}

-- modify for next event lol
local function halloweenUnlockTest(key)
	return SavedVariables.unlocks.isUnlockedByKeyOrTime(key, event_unlock_dates.halloween2023)
end

local sparkPopupStyles = { -- You can still use one not listed here technically, but these are the ones supported in the UI.

	-- Blizzard Extra Buttons
	{ tex = 629199,                                               name = "Default" },
	{ tex = 629198,                                               name = "Champion Light" },
	{ tex = 629200,                                               name = "Feng Barrier" },
	{ tex = 629201,                                               name = "Feng Shroud" },
	{ tex = 629202,                                               name = "Ultra Xion" },
	{ tex = 629203,                                               name = "Ysera" },
	{ tex = 629479,                                               name = "Green Keg" },
	{ tex = 629480,                                               name = "Smash" },
	{ tex = 629738,                                               name = "Brown Keg" },
	{ tex = 653590,                                               name = "Lightning Keg" },
	{ tex = 654130,                                               name = "Hozu Bar" },
	{ tex = 667434,                                               name = "Airstrike" },
	{ tex = 774879,                                               name = "Engineering" },
	{ tex = 796702,                                               name = "Soulswap" },
	{ tex = 876185,                                               name = "Amber" },
	{ tex = 1016651,                                              name = "Garr. Armory" },
	{ tex = 1016652,                                              name = "Garr. Alliance" },
	{ tex = 1016653,                                              name = "Garr. Horde" },
	{ tex = 1016654,                                              name = "Garr. Inn (Hearthstone)" },
	{ tex = 1016655,                                              name = "Garr. Lumbermill" },
	{ tex = 1016656,                                              name = "Garr. Mage Tower" },
	{ tex = 1016657,                                              name = "Garr. Stables" },
	{ tex = 1016658,                                              name = "Garr. Trading Post" },
	{ tex = 1016659,                                              name = "Garr. Training Pit" },
	{ tex = 1016660,                                              name = "Garr. Workshop" },
	{ tex = 1129687,                                              name = "Eye of Terrok" },
	{ tex = 1466424,                                              name = "Fel" },
	{ tex = 1589183,                                              name = "Soulcage" },
	{ tex = 2203955,                                              name = "Heart of Az. Active" },
	{ tex = 2203956,                                              name = "Heart of Az. Minimal" },

	-- SL
	{ tex = 3850736,                                              name = "Ardenweald Ability" },
	{ tex = 3853103,                                              name = "Ardenweald Button" },
	{ tex = 3850737,                                              name = "Ardenweald (Wide)" },
	{ tex = 3850738,                                              name = "Bastion Ability" },
	{ tex = 3853104,                                              name = "Bastion Button" },
	{ tex = 3850739,                                              name = "Bastion (Wide)" },
	{ tex = 3850740,                                              name = "Maldraxxus Ability" },
	{ tex = 3853105,                                              name = "Maldraxxus Button" },
	{ tex = 3850741,                                              name = "Maldraxxus (Wide)" },
	{ tex = 3850742,                                              name = "Revendreth Ability" },
	{ tex = 3853106,                                              name = "Revendreth Button" },
	{ tex = 3850743,                                              name = "Revendreth (Wide)" },
	{ tex = 4191854,                                              name = "Torghast" },
	{ tex = 4391622,                                              name = "Shadowlands Generic" },

	-- Start Custom Ones
	{ tex = SPARK_ASSETS_PATH .. "1Simple",                       name = "Arcanum - Simple" },
	{ tex = SPARK_ASSETS_PATH .. "1Ornate",                       name = "Arcanum - Ornate" },
	{ tex = SPARK_ASSETS_PATH .. "1OrnateBG",                     name = "Arcanum - Aurora" },
	{ tex = SPARK_ASSETS_PATH .. "2Simple",                       name = "Arc Lens - Simple" },
	{ tex = SPARK_ASSETS_PATH .. "2CustomRed",                    name = "Arc Lens - Red" },
	{ tex = SPARK_ASSETS_PATH .. "2CustomOrange",                 name = "Arc Lens - Orange" },
	{ tex = SPARK_ASSETS_PATH .. "2CustomYellow",                 name = "Arc Lens - Yellow" },
	{ tex = SPARK_ASSETS_PATH .. "2CustomGreen",                  name = "Arc Lens - Green" },
	{ tex = SPARK_ASSETS_PATH .. "2CustomJade",                   name = "Arc Lens - Jade" },
	{ tex = SPARK_ASSETS_PATH .. "2CustomBlue",                   name = "Arc Lens - Blue" },
	{ tex = SPARK_ASSETS_PATH .. "2CustomIndigo",                 name = "Arc Lens - Indigo" },
	{ tex = SPARK_ASSETS_PATH .. "2CustomViolet",                 name = "Arc Lens - Violet" },
	{ tex = SPARK_ASSETS_PATH .. "2CustomPink",                   name = "Arc Lens - Pink" },
	{ tex = SPARK_ASSETS_PATH .. "2CustomPrismatic",              name = "Arc Lens - Prismatic" },
	{ tex = SPARK_ASSETS_PATH .. "dicemaster_sanctum",            name = "DiceMaster Sanctum" },
	{ tex = SPARK_ASSETS_PATH .. "ethereal-xtrabtn",              name = "Arc+Dice - Ethereal" },
	{ tex = SPARK_ASSETS_PATH .. "nzoth-xtrabtn",                 name = "Arc+Dice - Nzoth" },
	{ tex = SPARK_ASSETS_PATH .. "forsaken-xtrabtn",              name = "Arc+Dice - Forsaken" },
	{ tex = SPARK_ASSETS_PATH .. "worgen-xtrabtn",                name = "Arc+Dice - Worgen" },

	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_metal",         name = "SF Dragon - Metal" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_arcane",        name = "SF Dragon - Arcane" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_black",         name = "SF Dragon - Black" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_blue",          name = "SF Dragon - Blue" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_bronze",        name = "SF Dragon - Bronze" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_brown",         name = "SF Dragon - Brown" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_darkblue",      name = "SF Dragon - Darkblue" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_emerald",       name = "SF Dragon - Emerald" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_green",         name = "SF Dragon - Green" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_infinite",      name = "SF Dragon - Infinite" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_jade",          name = "SF Dragon - Jade" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_orange",        name = "SF Dragon - Orange" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_phoenix",       name = "SF Dragon - Phoenix" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_pink",          name = "SF Dragon - Pink" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_purple",        name = "SF Dragon - Purple" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_red",           name = "SF Dragon - Red" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_ruby",          name = "SF Dragon - Ruby" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_white",         name = "SF Dragon - White" },
	{ tex = SPARK_ASSETS_PATH .. "sf_dragon_frame_yellow",        name = "SF Dragon - Yellow" },

	--halloween 2023
	{ tex = SPARK_ASSETS_PATH .. "halloween/" .. "halloween",     name = "Soulfire (Halloween 2023)" },
	{ tex = SPARK_ASSETS_PATH .. "halloween/" .. "halloweentint", name = "Soulfire (Tint)" },

	-- example for next event
	--{ tex = SPARK_ASSETS_PATH .. "halloween/" .. "halloween",     name = "Soulfire (Halloween 2023)", requirement = function() return halloweenUnlockTest("halloween_spark_01") end },
	--{ tex = SPARK_ASSETS_PATH .. "halloween/" .. "halloweentint", name = "Soulfire (Tint)",           requirement = function() return halloweenUnlockTest("halloween_spark_01") end },

	-- always last
	{ tex = addNewSparkPopupStyleTex,                             name = "Add Other/Custom" },
	-- 	{ tex = SPARK_ASSETS_PATH .. "CustomFrameFile", name = "Custom Frame 1", requirement = func -> bool (true: Show, false: Hide) },
}

--[[
local sparkPopupStylesKVTable = {}
local sparkPopupStylesSortTable = {}
for k, v in ipairs(sparkPopupStyles) do
	local newKey = v.tex
	local newVal = CreateTextureMarkup(v.tex, 48, 24, 48, 24, 0, 1, 0, 1) .. " " .. v.name
	sparkPopupStylesKVTable[newKey] = newVal
	tinsert(sparkPopupStylesSortTable, newKey)
end
--]]

local function getSparkPopupStylesKV()
	local style_KV_Table = {}
	for k, v in ipairs(sparkPopupStyles) do
		if not v.requirement or v.requirement() then
			local newKey = v.tex
			local newVal = CreateTextureMarkup(v.tex, 48, 24, 48, 24, 0, 1, 0, 1) .. " " .. v.name
			style_KV_Table[newKey] = newVal
		end
	end
	return style_KV_Table
end

local function getSparkPopupStylesSorted()
	local style_Sort_Table = {}
	for k, v in ipairs(sparkPopupStyles) do
		if not v.requirement or v.requirement() then
			local newKey = v.tex
			tinsert(style_Sort_Table, newKey)
		end
	end
	return style_Sort_Table
end

---@class SparkUIHelper
---@field commID string
---@field radius number
---@field style integer|string
---@field x number
---@field y number
---@field z number
---@field mapID number
---@field overwriteIndex? number
---@field spellInputs? string
---@field cooldownTime? number|false
---@field cooldownTriggerSpellCooldown? boolean
---@field cooldownBroadcastToPhase? boolean
---@field requirement? string
---@field conditionsData? ConditionData

---@type SparkUIHelper
local sparkUI_Helper = {
	commID = "Type a CommID",
	radius = 5,
	style = defaultSparkPopupStyle,
	x = 0,
	y = 0,
	z = 0,
	mapID = 0,
	overwriteIndex = nil,
	spellInputs = nil,
	cooldownTime = false,
	cooldownTriggerSpellCooldown = false,
	cooldownBroadcastToPhase = false,
	requirement = nil,
	conditionsData = nil,
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
				arcSpellInputs = {
					name = "Spell Input(s)",
					dialogControl = "MAW-Editbox",
					desc =
					"Set your spell inputs, separated by commas. Wrap an input in \"quotes, if you want to include a comma\" in it.\n\rInput values can be used dynamically in an ArcSpell by using it's alias (@input#@) in an action's input.",
					type = "input",
					order = autoOrder(),
					get = function()
						return sparkUI_Helper.spellInputs
					end,
					set = function(info, val)
						if val and val ~= "" then
							sparkUI_Helper.spellInputs = val
						else
							sparkUI_Helper.spellInputs = nil
						end
					end,
					width = 2,
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
				--[[
				requirementScript = {
					name = "Spark Requirement (Script)",
					dialogControl = "MAW-Editbox",
					desc =
						"Sets a requirement on this Spark via a script. If the script does not return a true value, then the Spark will not be shown. Leave blank to not have any requirement.\n\rExample Scripts:\n" ..
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
							return false
						end
					end,
					set = function(info, val)
						if val and val ~= "" then
							sparkUI_Helper.requirement = val
						else
							sparkUI_Helper.requirement = nil
						end
					end,
					width = "half",
				},
				--]]
				conditionsEditor = {
					type = "execute",
					name = function()
						if (sparkUI_Helper.requirement and #sparkUI_Helper.requirement > 0) or (sparkUI_Helper.conditionsData and #sparkUI_Helper.conditionsData > 0) then
							return "Edit Conditions"
						else
							return "Add Conditions"
						end
					end,
					desc = function()
						local lines = {
							"Sets conditions on this Spark. If the conditions are not met, then the Spark will not be shown at all.",
							" ",
						}
						if sparkUI_Helper.conditionsData and #sparkUI_Helper.conditionsData > 0 then
							tinsert(lines, "Current Conditions:")
							for gi, groupData in ipairs(sparkUI_Helper.conditionsData) do
								local groupString = (gi == 1 and "If") or "..Or"
								for ri, rowData in ipairs(groupData) do
									local continueStatement = (ri ~= 1 and "and ") or ""
									local condName = ns.Actions.ConditionsData.getByKey(rowData.Type).name
									groupString = string.join(" ", groupString, continueStatement .. condName)
								end
								tinsert(lines, groupString)
							end
						else
							tinsert(lines, "This Spark has no conditions. Click to add some!")
						end
						local str = ""
						local numLines = #lines
						for k, v in ipairs(lines) do
							str = str .. v .. (k ~= numLines and "\n" or "")
						end
						return str
					end,
					order = autoOrder(),
					width = 1,
					func = function()
						ns.UI.ConditionsEditor.open(sparkUI_Helper, "spark", sparkUI_Helper.conditionsData)
					end,
				},
				spacer2 = {
					name = " ",
					type = "description",
					width = "full",
					order = autoOrder(),
				},
				style = {
					name = "Border Style",
					desc = "The decorative border around the Spark spell icon",
					type = "select",
					width = 1.5,
					values = getSparkPopupStylesKV,
					sorting = getSparkPopupStylesSorted,
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

									customStyleTexIter = customStyleTexIter + 1
									tinsert(sparkPopupStyles, {
										tex = texPath,
										name = "Custom Texture " .. customStyleTexIter
									})

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
					desc = "Tint the Border Style",
					type = "color",
					width = 0.75,
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
				resetColor = {
					type = "execute",
					name = "Reset Tint",
					order = autoOrder(),
					width = 0.75,
					func = function()
						sparkUI_Helper.color = nil
					end,
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
					width = 0.85,
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
					width = 0.85,
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
					width = 0.85,
					validate = function(info, val) if tonumber(val) then return true else return "You need to supply a valid number!" end end,
					order = autoOrder(),
					set = function(info, val) sparkUI_Helper.z = (tonumber(val) and tonumber(val) or tonumber(getPosData(3))) end,
					get = function(info) return sparkUI_Helper.z and tostring(sparkUI_Helper.z) or tostring(getPosData(3)) end,
				},
				hereButton = {
					type = "execute",
					name = "Here",
					desc = "Set the X, Y, Z, and Map ID to your current position.",
					order = autoOrder(),
					width = 0.5,
					func = function()
						local posX = tonumber(getPosData(1))
						local posY = tonumber(getPosData(2))
						local posZ = tonumber(getPosData(3))
						local mapID = tonumber(getPosData(4))
						sparkUI_Helper.x = posX
						sparkUI_Helper.y = posY
						sparkUI_Helper.z = posZ
						sparkUI_Helper.mapID = mapID
					end,
				},
				mapID = {
					name = "Map ID",
					desc = "The Map ID to place the Trigger on. Default is your current map.",
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
					desc = "How close to the point a player must be to show the Spark.\n\rYou can manually input numbers bigger than 20 if you need a larger radius.",
					type = "range",
					dialogControl = "MAW-Slider",
					min = 0,
					max = 99999999999,
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
						--requirement = sparkUI_Helper.requirement,
						inputs = sparkUI_Helper.spellInputs,
						conditions = sparkUI_Helper.conditionsData
					},
					sparkUI_Helper.overwriteIndex)
				AceConfigDialog:Close(theUIDialogName)
			end,
		},
	}
}

AceConfig:RegisterOptionsTable(theUIDialogName, uiOptionsTable)
AceConfigDialog:SetDefaultSize(theUIDialogName, 600, 495 + 50)

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

	local x, y, z, mapID, radius, style, colorHex, cooldownTime, cooldownTriggerSpellCooldown, cooldownBroadcastToPhase, requirement, spellInputs, conditions
	if editIndex then
		local phaseSparkTriggers = SparkPopups.SparkPopups.getPhaseSparkTriggersCache()
		local triggerData = phaseSparkTriggers[editMapID][editIndex]
		x, y, z, mapID, radius, style, colorHex = triggerData[2], triggerData[3], triggerData[4], editMapID, triggerData[5], triggerData[6], triggerData[7]
		local sparkOptions = triggerData[8] --[[@as PopupTriggerOptions]]
		if sparkOptions ~= nil then
			cooldownTime, cooldownTriggerSpellCooldown, cooldownBroadcastToPhase = sparkOptions.cooldownTime, sparkOptions.trigSpellCooldown, sparkOptions.broadcastCooldown
			requirement = sparkOptions.requirement -- Kept for back compatibility, should not be used going forward
			conditions = sparkOptions.conditions
			spellInputs = sparkOptions.inputs
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
		spellInputs = nil
	end

	x, y, z = DataUtils.roundToNthDecimal(verifyNumber(x), 4), DataUtils.roundToNthDecimal(verifyNumber(y), 4), DataUtils.roundToNthDecimal(verifyNumber(z), 4)
	sparkUI_Helper.x, sparkUI_Helper.y, sparkUI_Helper.z, sparkUI_Helper.mapID, sparkUI_Helper.radius, sparkUI_Helper.style, sparkUI_Helper.color = x, y, z, mapID, radius, style, colorHex
	sparkUI_Helper.cooldownTime, sparkUI_Helper.cooldownTriggerSpellCooldown, sparkUI_Helper.cooldownBroadcastToPhase = cooldownTime, cooldownTriggerSpellCooldown, cooldownBroadcastToPhase
	sparkUI_Helper.requirement = requirement
	sparkUI_Helper.conditionsData = conditions
	sparkUI_Helper.spellInputs = spellInputs

	if (sparkUI_Helper.requirement and #sparkUI_Helper.requirement > 0) then
		-- convert old requirement
		local newData = {
			Type = "script",
			Input = sparkUI_Helper.requirement
		}
		sparkUI_Helper.conditionsData = { { newData } }
		sparkUI_Helper.requirement = nil
	end

	AceConfigDialog:Open(theUIDialogName)
end

local function closeSparkCreationUI()
	AceConfigDialog:Close(theUIDialogName)
end

---@class UI_SparkPopups_CreateSparkUI
ns.UI.SparkPopups.CreateSparkUI = {
	openSparkCreationUI = openSparkCreationUI,
	closeSparkCreationUI = closeSparkCreationUI,

	sparkPopupStyles = sparkPopupStyles,
	getSparkStyles = getSparkPopupStylesKV,
	--sparkPopupStyles = sparkPopupStylesKVTable,
}
