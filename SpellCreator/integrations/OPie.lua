if not IsAddOnLoaded("OPie") then return end

---@class ns
local ns = select(2, ...)

local OneRingLib = _G["OneRingLib"]

local ADDON_COLORS = ns.Constants.ADDON_COLORS

local Constants = ns.Constants
local DataUtils = ns.Utils.Data
local Execute = ns.Actions.Execute
local Permissions = ns.Permissions
local Vault = ns.Vault
local Cooldowns = ns.Actions.Cooldowns

local Icons = ns.UI.Icons

local ADDON_TITLE = Constants.ADDON_TITLE
local executeSpell = Execute.executeSpell
local orderedPairs = DataUtils.orderedPairs

local ActionBook = OneRingLib.ext.ActionBook
local AB = assert(ActionBook:compatible(2, 21), "A compatible version of ActionBook is required")

local spellMap = {}
local CATEGORY_ID = "arcanum"

---@param self GameTooltip
---@param commID CommID
---@return false | nil
local function OPieTooltip(self, commID)
	local spell = Vault.personal.findSpellByID(commID)
	if not spell then return false end

	self:AddLine(spell.fullName, ADDON_COLORS.GAME_GOLD:GetRGB())
	self:AddLine("Cast '" .. spell.commID .. "' (" .. #spell.actions .. " actions).", 1, 1, 1)
	if spell.cooldown then self:AddLine(("Cooldown: %ss"):format(spell.cooldown), 0.7, 0.7, 0.7) end
end

local function addCategory()
	AB:AugmentCategory(ADDON_TITLE, function(_, add)
		for _, spell in orderedPairs(Vault.personal.getSpells()) do
			add(CATEGORY_ID, spell.commID)
		end
	end)
end

---@param commID CommID
local function castSpell(commID)
	local spell = Vault.personal.findSpellByID(commID)
	if not spell then return end

	executeSpell(spell.actions, nil, spell.fullName, spell)
end

---@param commID CommID
---@return boolean usable
---@return nil state
---@return string icon
---@return string caption
---@return nil charges
---@return number cooldownRemaining
---@return number cooldownLength
---@return function tipFunc
---@return CommID tipArg
local function spellHint(commID)
	local spell = Vault.personal.findSpellByID(commID)

	local usable = spell and Permissions.canExecuteSpells() or false
	local icon = spell and Icons.getFinalIcon(spell.icon) or Icons.FALLBACK_ICON

	local cooldownRemaining, cooldownLength = Cooldowns.isSpellOnCooldown(commID)
	return usable, nil, icon, (spell and spell.fullName or commID), nil, (cooldownRemaining and cooldownRemaining or 0), (cooldownLength and cooldownLength or 0), OPieTooltip, commID
end

local function createActionSlot(commID)
	local spell = Vault.personal.findSpellByID(commID)
	if not spell then return end
	if not spellMap[commID] then
		spellMap[commID] = AB:CreateActionSlot(spellHint, commID, "func", castSpell, commID)
	end
	return spellMap[commID]
end

---@param commID CommID
---@return string typeName
---@return string actionName
---@return string icon
---@return nil ext
---@return function tipFunc
---@return CommID tipArg
local function describeSpell(commID)
	local spell = Vault.personal.findSpellByID(commID)

	if not spell then
		return "Deleted Arcanum Spell", commID, Icons.FALLBACK_ICON, nil, OPieTooltip, commID
	end

	return "Arcanum Spell", spell.fullName, Icons.getFinalIcon(spell.icon), nil, OPieTooltip, commID
end

addCategory()
AB:RegisterActionType(CATEGORY_ID, createActionSlot, describeSpell)
