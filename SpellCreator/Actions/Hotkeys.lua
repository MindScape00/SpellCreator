---@class ns
local ns = select(2, ...)

local Actions = ns.Actions
local Logging = ns.Logging
local Vault = ns.Vault

local pairs = pairs

local eprint = Logging.eprint
local dprint = Logging.dprint

---@alias Hotkey string

---@type table<Hotkey, CommID>
local hotkeysCache = {}

local hotKeyListenerButton = CreateFrame("Button", "SCForgeHotkeyButton")	-- Call this with SCForgeHotkeyButton:Click(commID) to cast that spell - Frame must remain named in the global space for Blizzard's Binding to work..
hotKeyListenerButton:SetScript("OnClick", function(self, commID)
	local spell = Vault.personal.findSpellByID(commID)
	if spell then
		Actions.Execute.executeSpell(spell.actions, nil, spell.fullName, spell)
	else
		eprint("No Spell '"..commID.."' found in your vault. Seems your binding is an orphan, how sad. Use '/sfdebug clearbinding "..commID.."' to clear it.")
	end
end)

local function updateHotkeys(requireVaultRefresh)
	ClearOverrideBindings(hotKeyListenerButton)
	for k,v in pairs(hotkeysCache) do
		dprint(nil, "Binding "..v.." to key: "..k)
		SetOverrideBindingClick(hotKeyListenerButton, false, k, "SCForgeHotkeyButton", v)
	end
	if requireVaultRefresh then
		ns.MainFuncs.updateSpellLoadRows()
	end
end

---@param commID CommID
---@return Hotkey?
local function getHotkeyByCommID(commID)
	for k, v in pairs(hotkeysCache) do
		if v == commID then return k end
	end
	return nil
end

---@param key Hotkey
local function deregisterHotkeyByKey(key)
	hotkeysCache[key] = nil
	updateHotkeys(true)
end

---@param commID CommID
local function deregisterHotkeyByComm(commID)
	for k, v in pairs(hotkeysCache) do
		if v == commID then
			hotkeysCache[k] = nil
			updateHotkeys(true)
			dprint("Deregistered hotkey for "..commID)
			return
		end
	end
end

---@param key Hotkey
---@param commID CommID
local function registerHotkey(key, commID)
	local oldBinding = getHotkeyByCommID(commID)
	if oldBinding ~= nil then
		deregisterHotkeyByComm(commID)
	end

	hotkeysCache[key] = commID
	updateHotkeys(true)
end

local function getHotkeys()
	return hotkeysCache
end

---@param key Hotkey
local function getHotkeyByKey(key)
	return hotkeysCache[key]
end

local function deregisterOrphanedCommIDs()
	for k,v in pairs(hotkeysCache) do
		if not Vault.personal.findSpellByID(v) then
			hotkeysCache[k] = nil
		end
	end
	updateHotkeys()
end

local function retargetHotkeysCache(target)
	hotkeysCache = target
end

---@class Actions_Hotkeys
ns.Actions.Hotkeys = {
	retargetHotkeysCache = retargetHotkeysCache,
	updateHotkeys = updateHotkeys,
	deregisterHotkeyByComm = deregisterHotkeyByComm,
	deregisterHotkeyByKey = deregisterHotkeyByKey,
	deregisterOrphanedCommIDs = deregisterOrphanedCommIDs,
	registerHotkey = registerHotkey,
	getHotkeys = getHotkeys,
	getHotkeyByCommID = getHotkeyByCommID,
	getHotkeyByKey = getHotkeyByKey,
}
