---@class ns
local ns = select(2, ...)
local addonName = ...
local Constants = ns.Constants
--local ver = ns.semver

--[[
Add ## at the start of a line to make it a header style line. Uses SFX Header II widget, so add >>> after ## if you want to center it.
Wrap a section in {} to indent each string inside the array. Indents are only supported to one level, don't try multiple indents.
Use a blank " " for a spacer.
--]]

local versions = {
	{
		ver = "1.3.5",
		changes = {
			"##>>>Arcanum v1.3.5 - July 10th, 2023",
			" ",
			"##Spark Requirements & Cooldowns:",
			"Sparks can now have requirements via scripts!",
			{ "Spark Requirement scripts must return with a true value in order for the Spark to display." },
			"Sparks can have individual cooldowns, and can be broadcast/synced to other players!",
			{ "A Spark's individual cooldown will override the Spell's cooldown, unless Trigger Spell Cooldown is enabled also." },
			"Spark Creator UI's Border Preview now shows tint!",
			" ",
			"##New Actions:",
			"UI Fade In/Out Actions & more Camera Actions",
			"Teleport Actions (Mark & Recall anyone?)",
			"Kinesis Toggle EFD Action - Revert returns it to the user's setting",
			"New ARC.XAPI.HasItem() function for advanced scripts",
			" ",
			"##Bug Fixes & QOL:",
			"Fixed Phase Vault trying to double-load in certain circumstances, spamming your chat with 'already loading!' messages.",
			"QC Manager now shows book controls even if there's 0 pages, so you can add a page or delete the book.",
			"The 'Move' button in the QC Manager has been enabled & renamed as 'Spells', allowing you to re-arrange & remove spells from a QC Page.",
		}
	},
}

---------------------- AceConfig table generation
local orderGroup = 1
local orderItem = 1
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

local function spacer(width)
	local item = {
		name = "",
		type = "description",
		order = autoOrder(),
		width = width or nil
	}
	return item
end

local function genChangeItem(change, subItem)
	local changeItem = {
		order = autoOrder(),
		width = subItem and 1.5 or "full",
	}
	if change:find("^##") then
		changeItem.name = change:gsub("^##", "")
		changeItem.type = "header"
		changeItem.dialogControl = "SFX-Header-II"
	else
		changeItem.name = change
		changeItem.type = "description"
		changeItem.fontSize = "medium"
		if strtrim(change) ~= "" then
			changeItem.image = "interface/questframe/ui-quest-bulletpoint.blp"
			changeItem.imageWidth = 12
			changeItem.imageHeight = 12
		end
	end
	return changeItem
end

local function genOlderVersionsEntry()
	local versionTable = {
		name = "Older Versions",
		type = "group",
		order = autoOrder(),
		args = {
			header = genChangeItem("##Looking for older changes?"),
			description = genChangeItem("Check out the Forums for a full Changelog history!"),
			spacer = spacer(),
			forums = {
				type = "input",
				name = "Forums",
				dialogControl = "SFX-Info-URL",
				order = autoOrder(),
				get = function() return "https://forums.epsilonwow.net/topic/3413-addon-arcanum-spell-forge-user-guide/" end,
				set = function() end,
			},
		}
	}
	return versionTable
end

local argsTable = {}
local function genChangeLogArgs()
	for k, v in ipairs(versions) do
		local versionTable = {
			name = "v" .. v.ver,
			type = "group",
			order = autoOrder(),
			args = {}
		}
		for i, change in ipairs(v.changes) do
			if type(change) == "table" then
				for j, subchange in ipairs(change) do
					versionTable.args["indent" .. tostring(i) .. "+" .. tostring(j)] = {
						type = "description",
						name = " ",
						order = autoOrder(),
						width = 0.1
					}
					versionTable.args[tostring(i) .. "+" .. tostring(j)] = genChangeItem(subchange, true)
				end
			else
				versionTable.args[tostring(i)] = genChangeItem(change)
			end
		end
		argsTable[v.ver] = versionTable
	end
	argsTable["Older"] = genOlderVersionsEntry()
	return argsTable
end

---@class UI_WelcomeUI_ChangelogMenu
ns.UI.WelcomeUI.ChangelogMenu = {
	genChangeLogArgs = genChangeLogArgs,
}
