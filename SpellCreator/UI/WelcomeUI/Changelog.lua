---@class ns
local ns = select(2, ...)
local addonName = ...
local Constants = ns.Constants
local ADDON_COLORS = Constants.ADDON_COLORS
local ADDON_COLOR = Constants.ADDON_COLOR

local Shared = ns.UI.WelcomeUI.Shared

local width = Shared.width
local height = Shared.height

--[[
Versions - AceConfig Options Table

Add ## at the start of a line to make it a header style line. Uses SFX Header II widget, so add >>> after ## if you want to center it.
Add URL's by formatting a line as "url:Name:link" - Note they are always indented by about 3 levels..., so might be worth just.. not indenting it.
Wrap a section in {} to indent each string inside the array. Indents are like - infinitely indent-able too.
Use a blank " " for a big spacer, or "" for a small spacer.
--]]

local versions = {
	{
		ver = "1.3.7",
		changes = {
			"##>>>Arcanum v1.3.7 - Sometime IDK",
			"##New Features!",
			"Arcanum Spell, Action, & Spark Conditions!",
			{
				"ArcSpells, and each action inside an ArcSpell, can now have conditions attached using our new Conditions Editor!",
				"Conditions allow you to control exactly what is required for that spell, or action, to be eligible to cast.",
				"Spell conditions limit the entire spell and are checked right when you cast the spell. If you fail a condition, you'll be shown a failed to cast message.",
				"Action conditions control that single action - these are checked when that actions delay is met, just before running that action. If you fail a condition here, it will silently fail and the rest of the spell will continue.",
				"",
				"Spells  - There's a new Conditions icon button in the Forge 'Attic', just to the right of the cast & cooldown.",
				"Actions - You'll find a new 'If' column in the Forge, simply click the condition icon to get started!",
				"These icons will show if they have any conditions set by lighting up the button, along with showing a quick preview of the conditions in the tooltip when mousing over it.",
				" ",
				"Sparks have also been updated to make use of the new Conditions system!",
				"When creating or editing a Spark, the 'Requirements' line has been replaced with a new Add/Edit Conditions button.",
				"Any Sparks that are using the Requirements system will continue to function the same as before!",
				"If you edit a Spark using Requirements, it will automatically convert the 'Requirement Script' into a Macro Script condition, which will work exactly the same.",
			},
			"",
			"Added new 'eat', 'drink', and 'consume' ArcTags for Item Integration. This allows you to quickly and easily make an item a consumable.",
			{
				"'eat' and 'drink' tags will automatically perform an eat or drink animation, respectively. Consume will consume the item, but performs no animation itself.",
				"Example: `.forge item set desc $item-link Use: Take a drink! <arc_drink>",
			},
			"",
			"##Bug Fixes & QOL Changes:",
			"Prevented Spark Keybinding from Overriding Non-Default Keybindings. Instead, Arcanum will provide a one-time warning that you should set it manually.",
			"Fixed ARC.PHASE:SAVE() function forcing the Phase Vault to hard-refresh in some cases.",
			"Added option to Shift-Click the + button on rows in the Forge Editor to copy that row instead of just making a blank row.",
			"Blocked error on item right-click if somehow the item ID did not get passed in.",
			"Macro Processor now handles | escapes better, allowing better use of WoW UI Escape Codes in Macro script actions",
			"Improved the help text of Add Random Item action to better explain input syntax and examples.",
			"Fix max characters of Input Prompts being limited to 24. Sorry! Now you can type to your hearts content!",
			"Action Bar loading now checks for Combat and delays loading if in combat to avoid errors.",
			"isSpellOnCooldown XAPI function now accepts 'true' as the phase value to use your current phase instead of specifying a phase ID specifically.",
			"Fix ArcSpell Actionbar Cooldowns not showing in some cases.",
			"Fix Vault Loading Errors sometimes occurring if you changed phases while the Phase Vault was still loading.",
			"Fixed the '/arc' slash commands being most non-functional. Now supports spell inputs in /arc cast as well.",
			"Arc's HasAura XAPI call, and thus the Toggle Aura function, now check for 'HARMFUL' auras as well, not just 'HELPFUL' ones. (NOTE: Still does not detect any 'hidden' auras).",
			"Added a 'Here' button to the Spark Creation UI that automatically updates the XYZ & Map ID to where you're standing.",
			"Fixed 'Remove Aura' action's revert - which didn't work and only said 'Invalid Syntax' or 'No Spell ID Found'..",
			" ",
		}
	},
	{
		ver = "1.3.6",
		changes = {
			"##>>>Arcanum v1.3.6 - October 18th, 2023",
			"##Highlights! (But really, you should read the full changelog!)",
			"Action Input Aliases / Substitutions (%t on steroids)!",
			"New Arcanum tab in your Spell Book!",
			"Arcanum Spells can now be placed on Action Bars!",
			"More & Improved TRP3 Extended Integrations for TRP3 Items & Workflows.",
			"ArcSpell Inputs (Minimize the number of duplicate spells with minor changes)!",
			"A bunch of new actions, bug fixes, and QOL changes.",
			"",
			"##Action Input Variables / Aliases / Substitutions:",
			"All actions now support token substitutions, including...",
			{
				("Blizz-like chat tokens, but heavily extended with way more options (Ex: %s, %s)"):format(
					ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode("%th") .. "- Target Health",
					ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode("%z") .. " - Zone Name"
				),
				("Dynamic inputs from Sparks, Items, and Script/Functions (Ex: %s, %s)."):format(ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode("@itemID@"),
					ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode("@input1@")),
				("ArcVar Values (Ex: %s, %s)"):format(
					ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode("@var:MyArcVar@") .. " (Personal)",
					ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode("@pvar:MyArcVar@") .. " (Phase)"
				),
				("Inline script resolving (Ex: %s - returns target health minus 15)"):format(ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode("%{return %th - 15}")),
			},
			"See the Arcanum Wiki for more information and a complete list of substitutions available:",
			"url:Wiki:https://github.com/MindScape00/SpellCreator/wiki/Input-Substitutions-and-Aliases",
			"",
			"##ArcSpell Inputs",
			"Powered by the token substitutions above, you can now provide inputs to an ArcSpell, via:",
			{
				"Sparks: A new option has been added to the Spark Creator / Editor UI for Spell Input(s); Spell inputs here should be separated by commas, and wrapped in \"quotes, if you want a comma\" inside the variable.",
				("Function: %s"):format(ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode("ARC:CAST(\"commID\", ...inputs...)")),
				("Function: %s"):format(ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode("ARC.PHASE:CAST(\"commID\", false, ...inputs...)")),
				"Items: Additionally, Items will pass their itemID, itemLink, and itemIcon as input when used to cast an ArcSpell. You can access these via their aliases noted above as well for easier reference.",
			},
			"",
			"##Improved TRP3 Extended Integrations:",
			"Arcanum Spells can now be cast directly in TRP3 Extended Workflows, using new effects added to the TRP3 Extended Workflow editor.",
			"Added an 'Import TRP3 Extended Item' action to Arcanum, allowing you to paste the import/export code of a TRP3 Extended item/object as the input & import the object when ran. Useful for storing & sharing items in the Phase Vault.",
			"Added an 'Add TRP3 Item to TRP3 Inventory' action, so you can also quickly add those imported items to your inventory.",
			"Moved TRP3 Extended actions into a new TRP3e sub-menu in the Actions selector. Some appear for now in two places so they're easy to find (i.e., TRP3e Sound actions in both Sound & TRP3e sub-menus)",
			"",
			"##Spell Book Integration",
			"Your default Spell Book now has an extra Arcanum tab! You can access all the spells in your Arcanum's Personal Vault.",
			"This acts more like a true Spell Book access for your spells, and less like a management tool like the actual vault inside the Spell Forge does.",
			"",
			"##Action Bar Support",
			"Arcanum Spells can now be dragged onto your Action Bar!",
			"Drag the icon from your Spell Book, or from your Personal Vault, and place it on an Action Button. That's it!",
			"",
			"##New Actions:",
			"Import ArcSpell Action, allowing you to save an exported ArcSpell code in a spell and import it directly.",
			"Import TRP3 Extended Item action (see above).",
			"Quickcast Management Actions (New Book, New Page, Add Spell, etc), and adjusted the old actions.",
			{
				"NOTE: Any spells using old Quickcast Actions may need to be adjusted, as the formatting has changed to comma separated. Space separated arguments are being phased out cuz they suck.",
			},
			"",
			"##Bug Fixes & QOL Improvements:",
			"Added more Quickcast Styles, and reworked the Quickcast Style selection menu to have categories to find what you want easier.",
			"Added a bunch of new Halloween inspired icons to use for your Arc Spells!",
			"Fixed Spark compatibility with ElvUI. (ElvUI is the worst..), and made the Spark frame movable by dragging from the border.",
			"Fixed Item Integrations being dropped from Spells when saved/downloaded from Phase Vault to Personal Vault.",
			"Added support for managing Quickcast books & pages thru ARC.XAPI functions. Full breakdown on the Arcanum API Wiki.",
			"Widened & Increased Character limit of the Prompt edit boxes, and also made the 'Cancel' button able to be removed/hidden.",
			"Added a new button next to Action Inputs to open a larger Input/Script Editor, with optional Lua syntax formatting (color highlighting & indenting).",
			"Added support for other addons to register custom Actions to use in ArcSpells! (ARC.RegisterAction)",
			"Fixed Spark Keybind not loading properly, meaning it wasn't working for.. anyone.. really.....",
		},
	},
	{
		ver = "1.3.5",
		changes = {
			"##>>>Arcanum v1.3.5c - August 2nd, 2023",
			"Bug Fixes:",
			{
				"Fix ARC.XAPI functions failing to return proper values (i.e., HasAura, HasItem).",
				"Fix the pop-up input prompts not disabling the accept button if no text is typed in yet.",
				"Allow multi-line scripts in script prompt actions.",
				"Convert Dropdowns to use a frame pool and hopefully release them. Maybe this will fix randomly having a dropdown in the background steal focus? Idk",
				"Blocked the 'You don't have the required proficiency' error message when using some items with ArcScripts."
			},
			"New Actions:",
			{
				"TRP3e Powered Sound Actions to play sounds to nearby players (Do not abuse.. This is your only warning)",
				"TRP3e Castbar UI action - mimics the normal WoW castbar more.",
				"Open & Send Mail actions."
			},
			" ",
			"##>>>Arcanum v1.3.5b - July 20th, 2023",
			"Bug Fixes:",
			{ "Fixed Chatlinks duplicating when being linked to normal chat. Sorry!" },
			" ",
			"##>>>Arcanum v1.3.5 - July 19th, 2023",
			"",
			"##Spark Requirements & Cooldowns:",
			"Sparks can now have requirements via scripts!",
			{ "Spark Requirement scripts must return with a true value in order for the Spark to display." },
			"Sparks can have individual cooldowns, which can be broadcast/synced to other players!",
			{ "A Spark's individual cooldown will override the Spell's cooldown, unless Trigger Spell Cooldown is enabled also, in which case both cooldowns are triggered." },
			"QOL: Spark Creator UI's Border Preview now shows tint, and Spark Radius no longer has a limit when typed in manually.",
			" ",
			"##Item Integration:",
			"ArcSpells can now be assigned to items! Connected items will cast that ArcSpell when used.",
			{
				"ArcSpells can be connected to any item, including: Forged Items, Items that do not have a Use, and Items that do already have a Use.",
				"You can connect multiple ArcSpells to an item - or one ArcSpell to multiple items.",
				"Connected items will have an Arc 'Use:' text added to their Tooltip, based on the ArcSpell's description!",
				ADDON_COLORS.TOOLTIP_EXAMPLE:WrapTextInColorCode("To connect an Item & ArcSpell, start by Right-Clicking a Spell in your Vault or Phase Vault!"),
			},
			" ",
			"Similar to Gossip, ArcTags may be used in Forged Item descriptions to link commands to them.",
			{
				"Items with an ArcTag will have an indicator (ArcCast) added to their Tooltip to let you know it has an ArcTag attached. Holding Shift or CTRL will preview the ArcTag in the item Tooltip.",
				"Note that unlike ArcSpell connections, these do not auto-generate 'Use:' text, and you should describe it in the description directly.",
				"Available ArcTags (<arc_" .. ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode("tag") .. ":command/text>):\n" .. (
					function()
						local tagString
						local tags = { "cmd", "macro", "cast|r (personal)", "pcast|r (phase)", "save", "copy" }
						for i = #tags, 1, -1 do
							tagString = ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode(tags[i]) .. (tagString and (", " .. tagString) or "")
						end
						return tagString
					end
				)(),
				"You may also specify an extension tag to trigger specific extra effects if the action succeeds. These are added as additional _xtag's after the main ArcTag. Currently, there's only one supported xtag: " ..
				ADDON_COLORS.TOOLTIP_WARNINGRED:WrapTextInColorCode("_del") .. ", which will delete that item on successful use. See example below.",
				"Examples: " ..
				ADDON_COLORS.TOOLTIP_CONTRAST:WrapTextInColorCode(
					".forge item set desc 14017550 ..." ..
					"\n\r   ... This stone glimmers like the night sky. Right-Click to Toggle it's Effects! <arc_macro:ARC.TOGAURA(291362)>" ..
					"\n\r   ... Right-Click to crush the stone and absorb the power inside. <arc_cmd_del:aura 277098>"
				),
			},
			" ",
			"##New Actions:",
			"UI Fade In/Out Actions & more Camera Actions",
			"Teleport Actions (Mark & Recall anyone?)",
			"Kinesis Toggle EFD Action - Revert returns it to the user's setting",
			"New ARC.XAPI.HasItem() function for advanced scripts",
			"Additional ARC & ARC.XAPI functions (do '/dump ARC.XAPI' for a list of functions available!)",
			" ",
			"##Bug Fixes & QOL:",
			"Fixed MacroScript not accepting multi-line scripts, because Newlines were sanitized to CSV.",
			"Fixed Phase Vault trying to double-load in certain circumstances, spamming your chat with 'already loading!' messages.",
			"Items, Spells, etc. can be shift-clicked to link into the Forge Editor in place of using the ID.",
			"Updating Visibility & Item connections for spells in the Phase Vault now only trigger that single spell to update for everyone, instead of a whole vault reload.",
			"QC Manager now shows book controls even if there's 0 pages, so you can add a page or delete the book.",
			"The 'Move' button in the QC Manager has been enabled & renamed as 'Spells', allowing you to re-arrange & remove spells from a QC Page.",
			"Reorganized / Cleaned Up the Action Select Dropdown - The main list was getting too big!",
			"Fixed Revert Delay not properly adjusting the length of the castbar in some cases.",
			"Right-Clicking on the Mini-Map Icon now has a new context menu to quickly access things, like the Spark & Quickcast Manager menus."
		}
	},
}

---------------------- AceConfig table generation

local orderGroup = 0
local orderItem = 0
---Auto incrementing order number. Use isGroup true to increment the orderGroup and reset the orderItem counter. Only use on top level groups (ignoring root).
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

local function spacer(width)
	local item = {
		name = "",
		type = "description",
		order = autoOrder(),
		width = width or nil,
		dialogControl = "MAW-Newline",
	}
	return item
end

local function genericGetArgFunc(info)
	return info.arg
end

---@param change string
---@param subItemDepth integer?
---@return table
---@return boolean
local function genChangeItem(change, subItemDepth)
	local subItemWidth = Shared.getFullWidthPixelOffset(Shared.insetWidth, -17 * (subItemDepth or 0))
	local wasHeader = false
	local changeItem = {
		order = autoOrder(),
		width = subItemDepth and subItemWidth or "full",
	}

	if change:find("^##") then
		changeItem.name = change:gsub("^##", "")
		changeItem.type = "header"
		changeItem.dialogControl = "SFX-Header-II"
		wasHeader = true
	elseif change:find("^url:") then
		local _, name, url = strsplit(":", change, 3)
		changeItem.name = name
		changeItem.arg = url
		changeItem.type = "input"
		changeItem.dialogControl = "SFX-Info-URL"
		changeItem.get = genericGetArgFunc
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
	return changeItem, wasHeader
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
				arg = "https://forums.epsilonwow.net/topic/3413-addon-arcanum-spell-forge-user-guide/",
				dialogControl = "SFX-Info-URL",
				order = autoOrder(),
				get = genericGetArgFunc,
			},
		}
	}
	return versionTable
end

local argsTable = {}

---@param versionTable table
---@param iter1 integer
---@param iter2 integer
---@param change table|string
---@param depth integer
local function genSubChange(versionTable, iter1, iter2, change, depth)
	if type(change) == "table" then
		depth = depth + 1
		for j, subChange in ipairs(change) do
			-- enter into recursive loop over sub-tables
			genSubChange(versionTable, iter1, j, subChange, depth)
		end
	else
		if depth > 0 then
			local depthScore = string.rep("_", depth)
			versionTable.args["indent" .. tostring(iter1) .. depthScore .. tostring(iter2)] = {
				type = "description",
				name = " ",
				order = autoOrder(),
				width = Shared.getExactPixelWidth(17 * depth)
			}
			local changeLogItem, header = genChangeItem(change, depth)
			versionTable.args[tostring(iter1) .. depthScore .. tostring(iter2)] = changeLogItem
			versionTable.args[tostring(iter1) .. depthScore .. tostring(iter2) .. "_NewLine"] = spacer()
		else
			local changeLogItem, header = genChangeItem(change)
			versionTable.args[tostring(iter1)] = changeLogItem
			if not header then
				versionTable.args[tostring(iter1) .. "_NewLine"] = spacer()
			end
		end
	end
end

local function genChangeLogArgs()
	for k, v in ipairs(versions) do
		local versionTable = {
			name = "v" .. v.ver,
			type = "group",
			order = autoOrder(),
			args = {}
		}
		for i, change in ipairs(v.changes) do
			genSubChange(versionTable, i, 0, change, 0)
			--[[
			if type(change) == "table" then
				for j, subchange in ipairs(change) do
					versionTable.args["indent" .. tostring(i) .. "+" .. tostring(j)] = {
						type = "description",
						name = " ",
						order = autoOrder(),
						width = Shared.getExactPixelWidth(17)
					}
					versionTable.args[tostring(i) .. "+" .. tostring(j)] = genChangeItem(subchange, true)
					versionTable.args[tostring(i) .. "+" .. tostring(j) .. "NewLine"] = spacer()
				end
			else
				local changeLogItem, header = genChangeItem(change)
				versionTable.args[tostring(i)] = changeLogItem
				if not header then
					versionTable.args[tostring(i) .. "+" .. "NewLine"] = spacer()
				end
			end
			--]]
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
