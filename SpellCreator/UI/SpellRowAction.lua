---@class ns
local ns = select(2, ...)

local ActionsData = ns.Actions.Data
local Tooltip = ns.Utils.Tooltip

local Attic = ns.UI.MainFrame.Attic
local Dropdown = ns.UI.Dropdown

local ACTION_TYPE = ActionsData.ACTION_TYPE
local actionTypeData = ActionsData.actionTypeData

local ACTION = ACTION_TYPE

local header = Dropdown.header
local radio = Dropdown.radio
local selectmenu = Dropdown.selectmenu
local submenu = Dropdown.submenu
local spacer = Dropdown.spacer

local rowHelperTable = {}
rowHelperTable.currentRow = nil

---@type fun(row: integer, selectedAction: ActionType)
local callback

---@param dependency string?
---@return (fun(): boolean) ?
local function isDependencyLoaded(dependency)
	return dependency and function()
		return not (IsAddOnLoaded(dependency) or IsAddOnLoaded(dependency .. "-dev"))
	end or nil
end
local function isDepAndReqMet(actionData)
	return not ns.Actions.Execute.checkDepAndReq(actionData, true)
end

---@param actionType ActionType
---@return DropdownItem
local function createAction(actionType)
	local actionData = actionTypeData[actionType]

	return radio(actionData.name, {
		tooltipTitle = actionData.name,
		tooltipText = function()
			local tooltipText = actionData.description

			if actionData.selfAble then
				tooltipText = tooltipText .. "\n\r" .. "Enable the " .. Tooltip.genContrastText("Self") .. " checkbox to always apply to yourself."
			end

			if actionData.example then
				tooltipText = tooltipText .. "\n\r" .. (Tooltip.genTooltipText("example", actionData.example))
			end

			if actionData.revert and actionData.revertDesc then
				tooltipText = tooltipText .. "\n\r" .. (Tooltip.genTooltipText("revert", actionData.revertDesc))
			elseif actionData.revert == nil then
				if actionData.revertAlternative == true then
					tooltipText = tooltipText .. "\n\r" .. (Tooltip.genTooltipText("norevert", "Cannot be reverted directly."))
				elseif actionData.revertAlternative then
					tooltipText = tooltipText .. "\n\r" .. (Tooltip.genTooltipText("norevert", "Cannot be reverted directly, use " .. actionData.revertAlternative .. "."))
				end
			end

			return tooltipText
		end,
		disabled = isDepAndReqMet(actionData),
		disabledWarning = actionData.disabledWarning,
		get = function(self)
			local row = rowHelperTable.currentRow

			if not row then return false end -- failsafe

			return row.SelectedAction == actionType
		end,
		set = function(self, checked)
			local row = rowHelperTable.currentRow

			if not row then return false, error("Dropdown Set Failed to Detect Row") end

			row.actionSelectButton:SetText(actionData.name)
			callback(row.rowNum, actionType)
			Attic.markEditorUnsaved()
			SCForgeMainFrame.SaveSpellButton:UpdateIfValid()
		end
	})
end

---@param dependency string
---@param dropdownItem DropdownItem
---@return DropdownItem
local function withDependency(dependency, dropdownItem)
	dropdownItem.disabled = isDependencyLoaded(dependency)
	return dropdownItem
end

---@param actionType ActionType
---@return DropdownItem
local function action(actionType)
	local item = createAction(actionType)
	-- item.menuItem.arg1 = row
	return item
end

local baseMenuList = {
	header("Spells & Effects"),
	selectmenu("Aura", {
		action(ACTION.SpellAura),
		action(ACTION.ToggleAura),
		action(ACTION.ToggleAuraSelf),

		spacer(),

		action(ACTION.RemoveAura),
		action(ACTION.RemoveAllAuras),

		spacer(),

		action(ACTION.PhaseAura),
		action(ACTION.PhaseUnaura),
		action(ACTION.GroupAura),
		action(ACTION.GroupUnaura),
	}),
	selectmenu("Cast", {
		header("Server (.cast)"),
		action(ACTION.SpellCast),
		action(ACTION.SpellTrig),
		spacer(),
		header("Client (Macro)"),
		action(ACTION_TYPE.secCast),
		action(ACTION_TYPE.secCastID),
		spacer(),
		action(ACTION_TYPE.secStopCasting),
	}),
	selectmenu("Morph", {
		action(ACTION.Morph),
		action(ACTION.Native),

		spacer(),

		action(ACTION.Unmorph),
	}),

	header("Character"),
	selectmenu("Animation", {
		header("Animation"),
		action(ACTION.Anim),
		action(ACTION.Standstate),

		spacer(),

		action(ACTION.ResetAnim),
		action(ACTION.ResetStandstate),

		header("Weapon"),
		action(ACTION.ToggleSheath),
	}),
	selectmenu("Items", {
		header("Inventory"),
		action(ACTION.AddItem),
		action(ACTION.RemoveItem),
		action(ACTION.AddRandomItem),
		spacer(),
		action(ACTION.secUseItem),
		header("Equipment"),
		action(ACTION.Equip),
		action(ACTION.EquipSet),
		action(ACTION.MogitEquip),
		spacer(),
		action(ACTION.Unequip),
	}),
	action(ACTION.Scale),
	selectmenu("Speed", {
		header("All types"),
		action(ACTION.Speed),

		header("Per mode"),
		action(ACTION.SpeedWalk),
		action(ACTION.SpeedBackwalk),
		action(ACTION.SpeedFly),
		action(ACTION.SpeedSwim),
	}),
	withDependency("totalRP3", selectmenu("Total RP 3", {
		header("Profile"),
		action(ACTION.TRP3Profile),

		header("Status"),
		action(ACTION.TRP3StatusToggle),
		action(ACTION.TRP3StatusIC),
		action(ACTION.TRP3StatusOOC),
	})),

	header("Commands / Other"),
	selectmenu("Target", {
		action(ACTION.secTarget),								-- TargetUnit([name, exactMatch]) #protected - Targets the specified unit.
		action(ACTION.secAssist),								-- AssistUnit([name, exactMatch]) #protected - Assists the unit by targeting the same target.
		action(ACTION.secClearTarg),							-- ClearTarget() : willMakeChange #protected - Clears the selected target
		spacer(),
		action(ACTION.secTargLTarg),							-- TargetLastTarget() #protected - Selects the last target as the current target.
		action(ACTION.secTargLEnemy),							-- TargetLastEnemy() #protected - Targets the previously targeted enemy.
		action(ACTION.secTargLFriend),							-- TargetLastFriend
		spacer(),
		action(ACTION.secTargNAny),								-- TargetNearest([reverse]) #protected
		action(ACTION.secTargNEnemy),							-- TargetNearestEnemy([reverse]) #protected - Selects the nearest enemy as the current target.
		action(ACTION.secTargNEnPlayer),						-- TargetNearestEnemyPlayer([reverse]) #protected - Selects the nearest enemy player as the current target.
		action(ACTION.secTargNFriend),							-- TargetNearestFriend([reverse]) #protected - Targets the nearest friendly unit.
		action(ACTION.secTargNFrPlayer),						-- TargetNearestFriendPlayer([reverse]) #protected - Selects the nearest friendly player as the current target.
		action(ACTION.secTargNParty),							-- TargetNearestPartyMember([reverse]) #protected - Selects the nearest Party member as the current target.
		action(ACTION.secTargNRaid),							-- TargetNearestRaidMember([reverse]) #protected - Selects the nearest Raid member as the current target.
		spacer(),
		action(ACTION.secFocus),								-- FocusUnit([name]) #protected - Sets the focus target.
		action(ACTION.secClearFocus),							-- ClearFocus() #protected - Clears the focus target.
	}),
	selectmenu("Movement", {
		action(ACTION.FollowUnit),
		action(ACTION.StopFollow),
		spacer(),
		action(ACTION.ToggleRun),
		spacer(),
		action(ACTION.ToggleAutoRun),
		action(ACTION.StartAutoRun),
		action(ACTION.StopAutoRun),
	}),
	selectmenu("Cheat", {
		action(ACTION.CheatOn),
		action(ACTION.CheatOff),
	}),
	selectmenu("Location / Tele", {
		header("Temporary Locations"),
		action(ACTION.SaveARCLocation),
		action(ACTION.GotoARCLocation),
		header("Permanent Locations"),
		action(ACTION.TeleCommand),
		action(ACTION.PhaseTeleCommand),
		action(ACTION.WorldportCommand),
	}),
	selectmenu("Camera", {
		header("Constant Movement"),
		action(ACTION.RotateCameraLeftStart),
		action(ACTION.RotateCameraRightStart),
		action(ACTION.RotateCameraUpStart),
		action(ACTION.RotateCameraDownStart),
		action(ACTION.ZoomCameraOutStart),
		action(ACTION.ZoomCameraInStart),
		spacer(),
		action(ACTION.RotateCameraStop),
		header("Set Movement / Zoom"),
		action(ACTION.ZoomCameraSet),
		action(ACTION.ZoomCameraOutBy),
		action(ACTION.ZoomCameraInBy),
		spacer(),
		action(ACTION.ZoomCameraSaveCurrent),
		action(ACTION.ZoomCameraLoadSaved),
		header("Mouse"),
		action(ACTION.MouselookModeStart),
	}),
	selectmenu("Sounds", {
		header("Normal"),
		action(ACTION.PlayLocalSoundKit),
		action(ACTION.PlayLocalSoundFile),
		action(ACTION.PlayPhaseSound),
		header("TRP3 Extended"),
		action(ACTION.TRP3e_Sound_playLocalSoundID),
		action(ACTION.TRP3e_Sound_playLocalMusic),
		spacer(),
		action(ACTION.TRP3e_Sound_stopLocalSoundID),
		action(ACTION.TRP3e_Sound_stopLocalMusic),
	}),
	selectmenu("Text / Messages", {
		action(ACTION.PrintMsg),
		action(ACTION.RaidMsg),
		action(ACTION.ErrorMsg),
		action(ACTION.BoxMsg),
		spacer(),
		action(ACTION.ARCCopy),
	}),
	selectmenu("UI / Prompts", {
		header("Prompt with Input"),
		action(ACTION.BoxPromptCommand),
		action(ACTION.BoxPromptScript),
		header("Prompt, No Input (Confirmation)"),
		action(ACTION.BoxPromptCommandNoInput),
		action(ACTION.BoxPromptScriptNoInput),
		header("User Interface (UI)"),
		action(ACTION.HideMostUI),
		action(ACTION.UnhideMostUI),
		action(ACTION.FadeOutMainUI),
		action(ACTION.FadeInMainUI),
		spacer(),
		action(ACTION.OpenSendMail),
		action(ACTION.SendMail),
		spacer(),
		action(ACTION.TalkingHead),
		action(ACTION.UnitPowerBar),
		spacer(),
		action(ACTION.TRP3e_Cast_showCastingBar)
	}),
	action(ACTION.Command),
	header("Scripts & AddOns"),
	action(ACTION.MacroText),
	selectmenu("ARC:API", {
		header("Personal Variables"),
		action(ACTION.ARCSet),
		action(ACTION.ARCTog),
		header("Phase Variables"),
		action(ACTION.ARCPhaseSet),
		action(ACTION.ARCPhaseTog),
	}),
	selectmenu("Arcanum", {
		header("ArcSpells"),
		action(ACTION.ArcSpell),
		action(ACTION.ArcSpellPhase),
		action(ACTION.ArcSpellCastImport),
		action(ACTION.ArcCastbar),
		action(ACTION.ArcStopSpells),
		action(ACTION.ArcStopThisSpell),
		action(ACTION.ArcStopSpellByName),

		header("Quickcast"),
		action(ACTION.QCBookToggle),
		action(ACTION.QCBookStyle),
		action(ACTION.QCBookSwitchPage),
		action(ACTION.QCBookNewBook),
		action(ACTION.QCBookNewPage),
		action(ACTION.QCBookAddSpell),

		header("Miscellaneous"),
		action(ACTION.ArcSaveFromPhase),
		action(ACTION.ArcImport),
		action(ACTION.SpawnBlueprint),
		action(ACTION.ArcTrigCooldown),
	}),
	withDependency("Kinesis", selectmenu("Kinesis", {
		header("Flight Controls"),
		action(ACTION.Kinesis_FlyEnable),
		action(ACTION.Kinesis_EFDEnable),
		spacer(),
		action(ACTION.Kinesis_LandJumpSet),
		action(ACTION.Kinesis_AutoLandDelay),
		header("Flight Spells"),
		action(ACTION.Kinesis_ToggleFlightSpells),
		action(ACTION.Kinesis_FlightSetSpells),
		action(ACTION.Kinesis_FlightLoadSpellSet),
		spacer(),
		action(ACTION.Kinesis_FlightArcEnabled),
		action(ACTION.Kinesis_FlightArcStart),
		action(ACTION.Kinesis_FlightArcStop),

		spacer(),
		header("Sprint / Speeds"),
		action(ACTION.Kinesis_SprintEnabled),
		action(ACTION.Kinesis_SprintGround),
		action(ACTION.Kinesis_SprintFly),
		action(ACTION.Kinesis_SprintSwim),
		action(ACTION.Kinesis_SprintReturnOrig),

		header("Sprint Emote"),
		action(ACTION.Kinesis_SprintEmoteAll),
		action(ACTION.Kinesis_SprintEmoteText),
		action(ACTION.Kinesis_SprintEmoteRate),

		header("Sprint Spells"),
		action(ACTION.Kinesis_SprintSpellAll),
		action(ACTION.Kinesis_SprintSetSpells),
		action(ACTION.Kinesis_SprintLoadSpellSet),
		spacer(),
		action(ACTION.Kinesis_SprintArcEnabled),
		action(ACTION.Kinesis_SprintArcStart),
		action(ACTION.Kinesis_SprintArcStop),
	})),
	withDependency("totalRP3_Extended", selectmenu("TRP3 Extended", {
		header("Items"),
		action(ACTION.TRP3e_Item_QuickImport),
		action(ACTION.TRP3e_Item_AddToInventory),
		header("UI"),
		action(ACTION.TRP3e_Cast_showCastingBar),
		header("Sounds"),
		action(ACTION.TRP3e_Sound_playLocalSoundID),
		action(ACTION.TRP3e_Sound_playLocalMusic),
		spacer(),
		action(ACTION.TRP3e_Sound_stopLocalSoundID),
		action(ACTION.TRP3e_Sound_stopLocalMusic),
	})),
}
local modifiableMenuList = CopyTable(baseMenuList)

local function addOtherHeaderIfNeeded()
	local hasOtherHeader
	for k, v in ipairs(modifiableMenuList) do
		if v.text == "Other Addons" then
			hasOtherHeader = true
		end
	end

	if not hasOtherHeader then
		tinsert(modifiableMenuList, header("Other Addons"))
	end
end

---comment
---@param name string
---@param menuItems DropdownItem[]
---@param options DropdownItemCreationOptions?
local function addMenuFullCategory(name, menuItems, options)
	addOtherHeaderIfNeeded()
	tinsert(modifiableMenuList, selectmenu(name, menuItems, options))
end

local function addNewAction(category, actionTypeKey)
	local alreadyExists
	for k, v in ipairs(modifiableMenuList) do
		if v.text == category then
			alreadyExists = k
			break
		end
	end
	if alreadyExists then
		-- use the category already there
		tinsert(modifiableMenuList[alreadyExists].menuItem.menuList, action(actionTypeKey))
	else
		addMenuFullCategory(category, { action(actionTypeKey) })
	end
end

local function getMenuList()
	return modifiableMenuList
end

---@param row SpellRowFrame
---@return DropdownItem[]
local function createMenu(row)
	return modifiableMenuList
end

---@param row SpellRowFrame
local function initialize(row)
	Dropdown.init(createMenu(row), row.actionSelectButton)
end

---@param cb fun(row: integer, selectedAction: ActionType)
local function setCallback(cb)
	callback = cb
end

---@class UI_SpellRowAction
ns.UI.SpellRowAction = {
	initialize = initialize,
	setCallback = setCallback,

	getActionList = getMenuList,
	addNewAction = addNewAction,
	addMenuFullCategory = addMenuFullCategory, -- this is a helper function but could be used to add a whole block at once by another addon if they know what they're doing

	rowHelperTable = rowHelperTable,
}
