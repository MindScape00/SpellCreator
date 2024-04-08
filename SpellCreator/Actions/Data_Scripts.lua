---@class ns
local ns = select(2, ...)

local Aura = ns.Utils.Aura
local Cmd = ns.Cmd
local Logging = ns.Logging
local Vault = ns.Vault
local libs = ns.Libs

local Constants = ns.Constants
local AceConsole = ns.Libs.AceConsole

local cmd, cmdWithDotCheck = Cmd.cmd, Cmd.cmdWithDotCheck
local runMacroText = Cmd.runMacroText
local cprint = Logging.cprint
local eprint = Logging.eprint
local isNotDefined = ns.Utils.Data.isNotDefined
local parseStringToArgs = ns.Utils.Data.parseStringToArgs

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

------------------------
--#region Nametag Scripts
------------------------

local nameCVars = {
	"UnitNameOwn",
	"UnitNameNPC",
	"UnitNamePlayerGuild",
	"UnitNamePlayerPVPTitle",
	"UnitNameFriendlyPlayerName",
	"UnitNameFriendlyPetName",
	"UnitNameFriendlyGuardianName",
	"UnitNameFriendlyTotemName",
	"UnitNameEnemyPlayerName",
	"UnitNameEnemyPetName",
	"UnitNameEnemyGuardianName",
	"UnitNameEnemyTotemName",
	"UnitNameNonCombatCreatureName",
	"UnitNameGuildTitle",
}
local savedNameCVars = {}
local areNamesShown = true
local namesAreToggled = false

local nametags = {}
function nametags.Enable()
	areNamesShown = true
	namesAreToggled = true
	for k, v in pairs(nameCVars) do
		SetCVar(v, 1)
	end
end

function nametags.Disable()
	areNamesShown = false
	namesAreToggled = true
	for k, v in pairs(nameCVars) do
		SetCVar(v, 0)
	end
end

function nametags.Restore()
	namesAreToggled = false
	areNamesShown = true -- might not be true but for toggle purposes let's assume they are
	for k, v in pairs(nameCVars) do
		SetCVar(v, savedNameCVars[v] or "0")
	end
end

function nametags.Toggle()
	--[[
	if namesAreToggled then -- Ignore what the current settings are, we are currently overriding, so toggle should just restore
		nametags.Restore()
		return
	end
	--]]
	if areNamesShown then
		nametags.Disable()
	else
		nametags.Enable()
	end
end

local function updateSavedNametagCVars()
	for k, v in pairs(nameCVars) do
		savedNameCVars[v] = GetCVar(v) or "0"
	end
end
-- Fix that annoying issue with using the interface menu.
InterfaceOptionsFrameOkay:HookScript("OnClick", updateSavedNametagCVars)
ns.AceEvent:RegisterEvent("VARIABLES_LOADED", updateSavedNametagCVars)

--------------------
--#endregion
--------------------

--------------------
--#region RunScript Priv
--------------------

---@param script string
local function runScriptPriv(script)
	if C_Epsilon and C_Epsilon.RunPrivileged then
		C_Epsilon.RunPrivileged(script)
	end
end

--------------------
--#endregion
--------------------

--------------------
--#region TRP3e
--------------------

local TRP3e = {}

-- Sounds
TRP3e.sound = {}
function TRP3e.sound.playLocalSoundID(vars)
	local soundID, channel, distance = unpack(parseStringToArgs(vars), 1, 3)
	if not tonumber(soundID) then
		soundID = TRP3_API.utils.music.convertPathToID(soundID)
	end
	TRP3_API.utils.music.playLocalSoundID(soundID, channel, distance)
end

function TRP3e.sound.stopLocalSoundID(vars)
	local soundID, channel = unpack(parseStringToArgs(vars), 1, 2)
	if not tonumber(soundID) then
		soundID = TRP3_API.utils.music.convertPathToID(soundID)
	end
	TRP3_API.utils.music.stopLocalSoundID(soundID, channel)
end

function TRP3e.sound.playLocalMusic(vars)
	local soundID, distance = unpack(parseStringToArgs(vars), 1, 2)
	if not tonumber(soundID) then
		soundID = TRP3_API.utils.music.convertPathToID(soundID)
	end
	TRP3_API.utils.music.playLocalMusic(soundID, distance)
end

function TRP3e.sound.stopLocalMusic(vars)
	local soundID, distance = unpack(parseStringToArgs(vars), 1, 2)
	if not tonumber(soundID) then
		soundID = TRP3_API.utils.music.convertPathToID(soundID)
	end
	TRP3_API.utils.music.stopLocalMusic(soundID)
end

-- Item Import
TRP3e.items = {}
function TRP3e.items.importItem(code)
	if not code then return end

	TRP3_ToolFrame.list.container.import.content.scroll.text:SetText(code)
	TRP3_ToolFrame.list.container.import.save:Click()
end

function TRP3e.items.addItem(id)
	if not id then return end
	if not TRP3_API.extended.classExists(id) then
		eprint("TRP3e Add Item to Inventory Error: Given class ID (" .. id .. ") does not exist in your TRP3 Extended Database.")
		return false
	end
	return TRP3_API.inventory.addItem(nil, id)
end

--------------------
--#endregion
--------------------
--------------------
--#region Mail
--------------------

local mail = {}

function mail.openMailCallback(name, subject, body)
	if not MailFrame:IsShown() then return end

	C_Timer.After(0, function()
		-- delayed so the frame is for sure shown and the click doesn't fail
		if not SendMailFrame:IsShown() then MailFrameTab2:Click() end

		SendMailNameEditBox:SetText(name or "")
		SendMailSubjectEditBox:SetText(subject or "")
		SendMailBodyEditBox:SetText(body or "")

		C_Timer.After(0, function()
			-- delayed so MailFrameTab2:Click finishes
			if subject then
				SendMailBodyEditBox:SetFocus()
			elseif name then
				SendMailSubjectEditBox:SetFocus()
			end
		end)
	end)
end

function mail.sendMailCallback(name, subject, body)
	SendMail(name, subject, body)
	CloseMail();
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
	nametags = nametags,
	keybind = keybindFrame,
	ui = ui,
	mail = mail,
	TRP3e_sound = TRP3e.sound,
	TRP3e_items = TRP3e.items,

	runScriptPriv = runScriptPriv
}
