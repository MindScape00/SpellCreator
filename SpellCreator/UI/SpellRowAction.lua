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

---@type fun(row: integer, selectedAction: ActionType)
local callback

---@param dependency string?
---@return (fun(): boolean) ?
local function disabled(dependency)
	return dependency and function()
		return not (IsAddOnLoaded(dependency) or IsAddOnLoaded(dependency .. "-dev"))
	end or nil
end

---@param actionType ActionType
---@param row SpellRowFrame
---@return DropdownItem
local function createAction(actionType, row)
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
		disabled = disabled(actionData.dependency),
		get = function()
			return row.SelectedAction == actionType
		end,
		set = function()
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
	dropdownItem.disabled = disabled(dependency)
	return dropdownItem
end

---@param row SpellRowFrame
---@return DropdownItem[]
local function createMenu(row)
	---@param actionType ActionType
	---@return DropdownItem
	local function action(actionType)
		local item = createAction(actionType, row)
		-- item.menuItem.arg1 = row
		return item
	end

	return {
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
			action(ACTION.SpellCast),
			action(ACTION.SpellTrig),
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
			action(ACTION.PlayLocalSoundKit),
			action(ACTION.PlayLocalSoundFile),
			action(ACTION.PlayPhaseSound),
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
			action(ACTION.ArcCastbar),
			action(ACTION.ArcStopSpells),
			action(ACTION.ArcStopThisSpell),
			action(ACTION.ArcStopSpellByName),

			header("Quickcast"),
			action(ACTION.QCBookToggle),
			action(ACTION.QCBookStyle),
			action(ACTION.QCBookSwitchPage),

			header("Miscellaneous"),
			action(ACTION.ArcSaveFromPhase),
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
	}
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
}
