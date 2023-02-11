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
local spacer = Dropdown.spacer

---@type fun(row: integer, selectedAction: ActionType)
local callback

---@param dependency string?
---@return (fun(): boolean) ?
local function disabled(dependency)
	return dependency and function()
		return not IsAddOnLoaded(dependency)
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
			elseif actionData.revert == nil and actionData.revertAlternative then
				tooltipText = tooltipText .. "\n\r" .. (Tooltip.genTooltipText("norevert", "Cannot be reverted directly, use " .. actionData.revertAlternative .. "."))
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
		header("Spells and effects"),
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

		header("Other / Scripts"),
		selectmenu("Cheat", {
			action(ACTION.CheatOn),
			action(ACTION.CheatOff),
		}),
		selectmenu("Camera", {
			action(ACTION.RotateCameraLeftStart),
			action(ACTION.RotateCameraRightStart),
			action(ACTION.RotateCameraStop),
		}),
		selectmenu("Sounds", {
			action(ACTION.PlayLocalSoundKit),
			action(ACTION.PlayLocalSoundFile),
			action(ACTION.PlayPhaseSound),
		}),
		selectmenu("Text / Messages", {
			action(ACTION.PrintMsg),
			action(ACTION.RaidMsg),
			action(ACTION.BoxMsg),
			spacer(),
			action(ACTION.ARCCopy),
		}),
		action(ACTION.MacroText),
		action(ACTION.Command),
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

			header("Quickcast"),
			action(ACTION.QCBookToggle),
			action(ACTION.QCBookStyle),
			action(ACTION.QCBookSwitchPage),

			header("Miscellaneous"),
			action(ACTION.ArcSaveFromPhase),
			action(ACTION.SpawnBlueprint),
		}),
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
