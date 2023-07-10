---@class ns
local ns = select(2, ...)

local Aura = ns.Utils.Aura
local Cmd = ns.Cmd
local Logging = ns.Logging
local Vault = ns.Vault

local Constants = ns.Constants
local AceConsole = ns.Libs.AceConsole

local cmd, cmdWithDotCheck = Cmd.cmd, Cmd.cmdWithDotCheck
local runMacroText = Cmd.runMacroText
local cprint = Logging.cprint
local eprint = Logging.eprint
local isNotDefined = ns.Utils.Data.isNotDefined

local next = next
local tinsert = tinsert
local tremove = tremove

local actionVars = {}
local keybindFrame = CreateFrame("Button", "SCFORGE_ACTION_KEYBIND_HOLDER")

--------------------
--#region General?
--------------------
local ui = {}

function ui.ToggleUIShown(shown)
	-- UI Error Frame & Raid Message Frame are hooked to stay visible when the UI is hidden in SpellCreator.lua AddOn Loaded handler.
	SetUIVisibility(shown)
end

--------------------
--#endregion
--------------------

--------------------
--#region Keybinds
--------------------

---@class KeyBindItem
---@type function[]

---@class KeyBindTable
---@type table { [Hotkey]: KeyBindItem}
keybindFrame.bindings = {}

---@param key Hotkey
---@param func function callback function when the hotkey is triggered
function keybindFrame:RegisterKeybindScript(key, func)
	if not key or not func then return end
	if self.bindings[key] then
		tinsert(self.bindings[key], func)
	else
		self.bindings[key] = {
			func
		}
	end
	SetOverrideBindingClick(self, true, key, "SCFORGE_ACTION_KEYBIND_HOLDER", key)
end

---@param key Hotkey
function keybindFrame:UnregisterKeybindKey(key)
	self.bindings[key] = nil
	SetOverrideBinding(self, true, key, nil)
end

---@param key Hotkey
---@param func function
function keybindFrame:UnregisterKeybindScript(key, func)
	if self.bindings[key] then
		tDeleteItem(self.bindings[key], func)

		if #self.bindings[key] == 0 then -- This key has no more binding scripts, clear it from the holding table
			self:UnregisterKeybindKey(key)
		end
	end
end

keybindFrame:SetScript("OnClick", function(self, key)
	local bindingFuncs = self.bindings[key]
	if bindingFuncs then
		for i = 1, #bindingFuncs do
			local func = bindingFuncs[i]
			if func then
				func(key, func) -- Called with key & itself as the reference, so it's easy to use a UnregisterKeybindScript
			end
		end
	end
end)
------------------------
--#endregion
------------------------

------------------------
--#region Camera Scripts
------------------------
local camera = {}
function camera.SetZoom(zoomAmount)
	local curZoom = GetCameraZoom()
	actionVars.ZoomCameraSet_PreviousZoom = curZoom
	local newZoom = zoomAmount - curZoom
	if newZoom > 0 then CameraZoomOut(newZoom) else CameraZoomIn(math.abs(newZoom)) end
end

function camera.RevertZoom()
	if actionVars.ZoomCameraSet_PreviousZoom then
		local curZoom = GetCameraZoom()
		local newZoom = actionVars.ZoomCameraSet_PreviousZoom - curZoom
		if newZoom > 0 then CameraZoomOut(newZoom) else CameraZoomIn(math.abs(newZoom)) end
	end
end

function camera.SaveZoom()
	actionVars.ZoomCameraSaveCurrent_SavedZoom = GetCameraZoom()
end

function camera.RestoreSavedZoom()
	if actionVars.ZoomCameraSaveCurrent_SavedZoom then
		camera.SetZoom(actionVars.ZoomCameraSaveCurrent_SavedZoom)
	end
end

local function _disableMouselookAndUnregisterSelf(key, func)
	if not IsMouselooking() then return end
	MouselookStop()
	keybindFrame:UnregisterKeybindScript(key, func)
end

function camera.DisableMouselook(key)
	key = string.upper(key)
	_disableMouselookAndUnregisterSelf(key, _disableMouselookAndUnregisterSelf)
end

function camera.EnableMouselook(key)
	if isNotDefined(key) then
		return eprint("Mouselook mode must have an Exit Key given.")
	end
	key = string.upper(key)
	keybindFrame:RegisterKeybindScript(key, _disableMouselookAndUnregisterSelf)
	MouselookStart()
end

--------------------
--#endregion
--------------------

ARC._DEBUG.DATA_SCRIPTS = {
	keybindings = keybindFrame.bindings
}

---@class Actions_Data_Scripts
ns.Actions.Data_Scripts = {
	camera = camera,
	keybind = keybindFrame,
	ui = ui,
}
