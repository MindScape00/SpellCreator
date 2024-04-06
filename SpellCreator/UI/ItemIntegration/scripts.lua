---@class ns
local ns = select(2, ...)
local addonName = ...

local Cmd = ns.Cmd
local Constants = ns.Constants
local Execute = ns.Actions.Execute
local Vault = ns.Vault
local VAULT_TYPE = Constants.VAULT_TYPE
local Dropdown = ns.UI.Dropdown
local HTML = ns.Utils.HTML
local phaseVault = Vault.phase
local Logging = ns.Logging

local cprint, dprint, eprint = Logging.cprint, Logging.dprint, Logging.eprint
local cmdWithDotCheck = Cmd.cmdWithDotCheck
local cmd = Cmd.cmd
local runMacroText = Cmd.runMacroText
local executePhaseSpell = Execute.executePhaseSpell

local tContains = tContains
local tDeleteItem = tDeleteItem
local tWipe = table.wipe

local match = string.match
local strsplit = strsplit
local strtrim = strtrim
local find = string.find
local next = next

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
--#region ArcSpell <-> Item System - Direct Links Management
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local itemsWithSpellsCache = {
	[19222] = { phase = { "some test?" }, personal = { "drunk" } } -- example default, gets overwritten when updateCache is called.
}

---@param itemID number
---@param spellCommID CommID
---@param vaultType VaultType
---@param refreshUI boolean?
local function addItemSpellLink(itemID, spellCommID, vaultType, refreshUI)
	vaultType = string.lower(vaultType)
	if not itemsWithSpellsCache[itemID] then
		itemsWithSpellsCache[itemID] = { phase = {}, personal = {} }
	end
	tinsert(itemsWithSpellsCache[itemID][vaultType], spellCommID)
	if refreshUI and SCForgeLoadFrame:IsShown() then
		ns.MainFuncs.updateSpellLoadRows(true)
	end
end

local function deleteItemLink(itemID)
	itemsWithSpellsCache[itemID] = nil
end

local function deleteSpellFromItem(itemID, spellCommID, vaultType, refreshUI)
	vaultType = string.lower(vaultType)
	if not itemsWithSpellsCache[itemID] then return end

	if itemsWithSpellsCache[itemID] and itemsWithSpellsCache[itemID][vaultType] then
		tDeleteItem(itemsWithSpellsCache[itemID][vaultType], spellCommID)
	end

	if not next(itemsWithSpellsCache[itemID].phase) and not next(itemsWithSpellsCache[itemID].personal) then
		deleteItemLink(itemID) -- all spells removed, delete the connection
	end

	if refreshUI and SCForgeLoadFrame:IsShown() then
		ns.MainFuncs.updateSpellLoadRows(true)
	end
end

---@param vaultType VaultType
---@return table
local function getSpellsWithItemLinks(vaultType)
	vaultType = string.lower(vaultType)
	local spellsWithItems = {}
	for k, spell in pairs(Vault[vaultType].getSpells()) do
		if spell.items then
			tinsert(spellsWithItems, spell)
		end
	end
	return spellsWithItems
end

---@param refreshUI boolean? should the UI need refreshed
local function updateCache(refreshUI)
	tWipe(itemsWithSpellsCache)
	local vaults = { Constants.VAULT_TYPE.PERSONAL, Constants.VAULT_TYPE.PHASE }
	for k, vaultType in ipairs(vaults) do
		local spellsWithItems = getSpellsWithItemLinks(vaultType)
		for i, spell in ipairs(spellsWithItems) do
			for _, item in ipairs(spell.items) do
				addItemSpellLink(item, spell.commID, vaultType, refreshUI)
			end
		end
	end
end

---@param spell VaultSpell
---@param itemID integer
---@param vaultType VaultType
---@param refreshUI boolean?
---@return boolean success
local function safeAddItemToSpell(spell, itemID, vaultType, refreshUI)
	if not spell.items then spell.items = {} end
	itemID = tonumber(itemID)
	if not itemID then ns.Logging.uiErrorMessage("Invalid Item. Could not link Item & ArcSpell.", Constants.ADDON_COLORS.TOOLTIP_WARNINGRED:GetRGB()) end
	if tContains(spell.items, itemID) then
		ns.Logging.uiErrorMessage("This ArcSpell is already connected to this item (" .. itemID .. ").", Constants.ADDON_COLORS.ADDON_COLOR:GetRGB())
		return false
	end
	tinsert(spell.items, itemID)
	addItemSpellLink(itemID, spell.commID, vaultType, refreshUI)
	return true
end

---@param spell VaultSpell
---@param itemID integer|number
---@param vaultType VaultType
---@param refreshUI boolean?
---@return boolean success
local function safeRemoveItemFromSpell(spell, itemID, vaultType, refreshUI)
	if not spell.items then return false end
	itemID = tonumber(itemID)
	if not itemID then ns.Logging.uiErrorMessage("Invalid Item. Could not remove Item connection from ArcSpell.", Constants.ADDON_COLORS.TOOLTIP_WARNINGRED:GetRGB()) end

	if tContains(spell.items, itemID) then
		tDeleteItem(spell.items, itemID)
		if not next(spell.items) then
			spell.items = nil -- remove the table, save some space
		end
		deleteSpellFromItem(itemID, spell.commID, vaultType, refreshUI)
		return true
	end
	return false
end

--#endregion

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
--#region Item Description Hooking
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local itemTag_ExtTags = {

	---@param payload itemTag_ScriptPayload
	del = function(payload)
		cmd("additem " .. payload.itemID .. " -1")
	end,
}

---@param payload itemTag_ScriptPayload
local function runExtensionChecks(payload)
	if not payload.extTags then return end
	for k, v in pairs(itemTag_ExtTags) do
		if payload.extTags:match(k) then
			v(payload)
		end
	end
end

local itemTag_Scripts = {

	---@param payload itemTag_ScriptPayload
	personal_cast = function(payload)
		if ARC:CAST(payload.arg) then
			runExtensionChecks(payload)
		end
	end,

	---@param payload itemTag_ScriptPayload
	phase_cast = function(payload)
		-- TODO : Reimplement Auto-Cast upon Phase Vault Loaded? See Gossip System for Reference.
		if phaseVault.isSavingOrLoadingAddonData then
			eprint("Phase Vault was still loading. Please try again in a moment."); return;
		end
		if executePhaseSpell(payload.arg) then
			runExtensionChecks(payload)
		end
	end,

	---@param payload itemTag_ScriptPayload
	save = function(payload)
		if phaseVault.isSavingOrLoadingAddonData then
			eprint("Phase Vault was still loading. Please try again in a moment."); return;
		end
		dprint("Scanning Phase Vault for Spell to Save: " .. payload.arg)

		local index = Vault.phase.findSpellIndexByID(payload.arg)
		if index ~= nil then
			dprint("Found & Saving Spell '" .. payload.arg .. "' (" .. index .. ") to your Personal Vault.")
			ns.MainFuncs.downloadToPersonal(index, true, function() runExtensionChecks(payload) end)
		end
	end,

	---@param payload itemTag_ScriptPayload
	copy = function(payload)
		HTML.copyLink(nil, payload.arg)
		runExtensionChecks(payload)
	end,

	---@param payload itemTag_ScriptPayload
	cmd = function(payload)
		cmdWithDotCheck(payload.arg)
		runExtensionChecks(payload)
	end,

	---@param payload itemTag_ScriptPayload
	macro = function(payload)
		runMacroText(payload.arg)
		runExtensionChecks(payload)
	end,

	---@param payload itemTag_ScriptPayload
	food = function(payload)
		cmd("cast 168117")

		-- Force add _del extension tag, then run extension checks - if it's there twice, it still only gets ran once anyways.
		if not payload.extTags then
			payload.extTags = ""
		end
		payload.extTags = payload.extTags .. "_del"
		runExtensionChecks(payload)
	end,

	---@param payload itemTag_ScriptPayload
	drink = function(payload)
		cmd("cast 263434")

		-- Force add _del extension tag, then run extension checks - if it's there twice, it still only gets ran once anyways.
		if not payload.extTags then
			payload.extTags = ""
		end
		payload.extTags = payload.extTags .. "_del"
		runExtensionChecks(payload)
	end,

	---@param payload itemTag_ScriptPayload
	consume = function(payload)
		cmd("cast 165290")

		-- Force add _del extension tag, then run extension checks - if it's there twice, it still only gets ran once anyways.
		if not payload.extTags then
			payload.extTags = ""
		end
		payload.extTags = payload.extTags .. "_del"
		runExtensionChecks(payload)
	end,
}

local itemTag_Tags = {
	default = "%s?<arc[anum]-_.->",
	capture = "<arc[anum]-_(.-)>",
	preview = " <arc::",
	option = {
		cmd = { script = itemTag_Scripts.cmd },
		macro = { script = itemTag_Scripts.macro },
		cast = { script = itemTag_Scripts.personal_cast },
		pcast = { script = itemTag_Scripts.phase_cast },
		save = { script = itemTag_Scripts.save },
		copy = { script = itemTag_Scripts.copy },
		eat = { script = itemTag_Scripts.food },
		drink = { script = itemTag_Scripts.drink },
		consume = { script = itemTag_Scripts.consume },
	},
}

local itemDescARC_Cache = {}

---@param itemID integer|number
---@param fontStringObject FontString
local function testAndReplaceArcLinks(itemID, fontStringObject)
	itemID = tonumber(itemID)
	if itemDescARC_Cache[itemID] then -- reset our cache for that item
		tWipe(itemDescARC_Cache[itemID]) -- already existed, reuse the table
	else
		itemDescARC_Cache[itemID] = {}
	end

	local description = fontStringObject:GetText()
	if description and description ~= "" then
		while description and description:match(itemTag_Tags.default) do
			local itemDescPayload = description:match(itemTag_Tags.capture) -- capture the tag
			local strTag, strArg = strsplit(":", itemDescPayload, 2) -- split the tag from the data
			local mainTag, extTags = strsplit("_", strTag, 2)      -- split the main tag from the extension tags

			---@class itemTag_ScriptPayload
			---@field arg string the arg passed
			---@field itemID integer the item ID used
			---@field extTags string the extension tags
			local payload = {
				arg = strArg,
				itemID = itemID,
				extTags = extTags,
			}

			if itemTag_Tags.option[mainTag] then -- Checking Main Tags & Adding to our item-use cache
				tinsert(itemDescARC_Cache[itemID], function()
					itemTag_Tags.option[mainTag].script(payload)
					dprint("Item Desc Hook clicked for Item " .. itemID .. ": <" .. mainTag .. ":" .. (strArg or "") .. ">")
				end)
			end

			if (IsShiftKeyDown() or IsControlKeyDown()) then -- Update the text
				fontStringObject:SetText(description:gsub(itemTag_Tags.default, Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode(itemTag_Tags.preview .. itemDescPayload .. ">"), 1));
			else
				fontStringObject:SetText(description:gsub(itemTag_Tags.default, "", 1));
			end
			dprint("Saw an Item Desc Tag, Item: " .. itemID .. " | Tag: " .. mainTag .. " | Spell: " .. (strArg or "none"))
			description = fontStringObject:GetText()
		end
	end
end

-- hook setitem to override
-- done below in Tooltips region

--#endregion

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
--#region Item Use & Cooldown Handlers
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---Trigger Item Integration Cooldowns
---@param itemID integer
local function triggerCooldowns(itemID)
	-- bag frames
	for i = 1, NUM_CONTAINER_FRAMES do
		local containerFrame = _G["ContainerFrame" .. i]
		if containerFrame:IsShown() then
			ContainerFrame_UpdateCooldowns(containerFrame)
		end
	end

	-- action bars
	for k, frame in pairs(ActionBarButtonEventsFrame.frames) do
		--ActionButton_Update(frame);
		frame:Update()
	end
end

-- Handler for checking & casting spells if connected
local function tryArcSpellsFromItem(itemID)
	if not itemID then return end -- shouldnt be possible but someone got it somehow...
	local itemName, itemLink, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)

	local didCast = false
	local itemFromCache = itemsWithSpellsCache[itemID]
	if itemFromCache then
		if itemFromCache.phase then
			for k, commID in ipairs(itemFromCache.phase) do
				ARC.PHASE:CAST(commID, nil, itemID, itemName, itemLink, "|T" .. itemTexture .. ":0|t")
				didCast = true
			end
		end
		if itemFromCache.personal then
			for k, commID in ipairs(itemFromCache.personal) do
				if not tContains(itemFromCache.phase, commID) then -- Skip if exists in both Phase & Personal, Prioritize Phase
					ARC:CAST(commID, itemID, itemName, itemLink, "|T" .. itemTexture .. ":0|t")
					didCast = true
				end
			end
		end
	end
	if itemDescARC_Cache[itemID] then
		for k, script in ipairs(itemDescARC_Cache[itemID]) do
			if type(script) == "function" then
				script()
				didCast = true
			end
		end
	end
	if didCast then triggerCooldowns(itemID) end
	return didCast
end

--#region Hooking Item Use Functions
local itemUseHooks = {
	["UseContainerItem"] = function(bagID, slot)
		local icon, itemCount, _, _, _, _, itemLink, _, _, itemID, _ = GetContainerItemInfo(bagID, slot)
		if IsEquippableItem(itemID) then return end
		tryArcSpellsFromItem(itemID)
	end,
	["UseInventoryItem"] = function(slot)
		local itemID = GetInventoryItemID("player", slot)
		tryArcSpellsFromItem(itemID)
	end,
	["UseItemByName"] = function()

	end,
	["UseAction"] = function(action, unit, button)
		if IsUsableAction(action) then -- this must be true for us to continue - this filters items we no longer have in inventory / can't use
			local actionType, itemID = GetActionInfo(action)
			if actionType == "item" then
				tryArcSpellsFromItem(itemID)
			end
		end
	end,
	["ContainerFrame_UpdateCooldown"] = function(container, button)
		local itemID = GetContainerItemID(container, button:GetID());
		local itemFromCache = itemsWithSpellsCache[itemID]
		local cdRemaining, cdDuration = 0, 0
		if itemFromCache then
			if itemFromCache.phase then
				for k, commID in ipairs(itemFromCache.phase) do
					local _cdRemaining, _cdDuration = ns.Actions.Cooldowns.isSpellOnCooldown(commID, C_Epsilon.GetPhaseId())
					if _cdRemaining and _cdRemaining > cdRemaining then
						cdRemaining, cdDuration = _cdRemaining, _cdDuration
					end
				end
			end
			if itemFromCache.personal then
				for k, commID in ipairs(itemFromCache.personal) do
					local _cdRemaining, _cdDuration = ns.Actions.Cooldowns.isSpellOnCooldown(commID)
					if _cdRemaining and _cdRemaining > cdRemaining then
						cdRemaining, cdDuration = _cdRemaining, _cdDuration
					end
				end
			end
		end

		local enable
		if cdRemaining > 0 then
			enable = true
		end
		local cooldown = _G[button:GetName() .. "Cooldown"];
		if not button.ArcCooldown then
			button.ArcCooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
			button.ArcCooldown:SetSwipeTexture("", 0.35, 0.0, 0.55, 0.8)
			button.ArcCooldown:SetSwipeColor(0.45, 0.0, 0.55, 0.8)
		end
		CooldownFrame_Set(button.ArcCooldown, GetTime() - (cdDuration - cdRemaining), cdDuration, enable);
		if (cdRemaining > 0 and enable == 0) then
			SetItemButtonTextureVertexColor(button, 0.4, 0.4, 0.4);
		else
			SetItemButtonTextureVertexColor(button, 1, 1, 1);
		end
	end,
	["ActionButton_UpdateCooldown"] = function(self)
		--local actionID = ActionButton_GetPagedID(self)
		local actionID = self:GetPagedID()
		--local actionID = ActionButton_CalculateAction(self)
		local actionType, itemID = GetActionInfo(actionID)

		if actionType == "item" then
			local itemFromCache = itemsWithSpellsCache[itemID]
			local cdRemaining, cdDuration = 0, 0
			if itemFromCache then
				if itemFromCache.phase then
					for k, commID in ipairs(itemFromCache.phase) do
						local _cdRemaining, _cdDuration = ns.Actions.Cooldowns.isSpellOnCooldown(commID, C_Epsilon.GetPhaseId())
						if _cdRemaining and _cdRemaining > cdRemaining then
							cdRemaining, cdDuration = _cdRemaining, _cdDuration
						end
					end
				end
				if itemFromCache.personal then
					for k, commID in ipairs(itemFromCache.personal) do
						local _cdRemaining, _cdDuration = ns.Actions.Cooldowns.isSpellOnCooldown(commID)
						if _cdRemaining and _cdRemaining > cdRemaining then
							cdRemaining, cdDuration = _cdRemaining, _cdDuration
						end
					end
				end
			end

			local enable
			if cdRemaining > 0 then
				enable = true
			end
			if not self.ArcCooldown then
				self.ArcCooldown = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
				self.ArcCooldown:SetSwipeTexture("", 0.35, 0.0, 0.55, 0.8)
				self.ArcCooldown:SetSwipeColor(0.45, 0.0, 0.55, 0.8)
			end
			CooldownFrame_Set(self.ArcCooldown, GetTime() - (cdDuration - cdRemaining), cdDuration, enable);
		end
	end,
}

for k, v in pairs(itemUseHooks) do
	hooksecurefunc(k, v)
end

--#endregion

--#region Hooking Tooltips

local function GameTooltip_OnTooltipSetItem(tooltip)
	local _, link = tooltip:GetItem()
	if not link then return; end

	local itemString = match(link, "item[%-?%d:]+")
	local _, itemId = strsplit(":", itemString)

	--From idTip: http://www.wowinterface.com/downloads/info17033-idTip.html
	if itemId == "0" and TradeSkillFrame ~= nil and TradeSkillFrame:IsVisible() then
		if (GetMouseFocus():GetName()) == "TradeSkillSkillIcon" then
			itemId = GetTradeSkillItemLink(TradeSkillFrame.selectedSkill):match("item:(%d+):") or nil
		else
			for i = 1, 8 do
				if (GetMouseFocus():GetName()) == "TradeSkillReagent" .. i then
					itemId = GetTradeSkillReagentItemLink(TradeSkillFrame.selectedSkill, i):match("item:(%d+):") or nil
					break
				end
			end
		end
	end

	-- Handle Caching Data & Removing ArcTags
	-- Iterate through all of the lines on our tooltip.
	for i = 1, tooltip:NumLines() do
		local left = _G[tooltip:GetName() .. "TextLeft" .. i]
		local lText = left:GetText()
		local lR, lG, lB = left:GetTextColor()

		local right = _G[tooltip:GetName() .. "TextRight1"]
		-- Ignore any lines that have "Feral Attack Power" in them. Add everything else to a table used to reconstruct our tooltip later on.
		if lText:find("<arc") then
			testAndReplaceArcLinks(itemId, left)
			right:SetText(Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode("ArcCast"))
			right:Show()
			--tooltip:Show()
		end
	end

	-- handle adding ArcSpell Descriptions:
	if itemId and itemsWithSpellsCache[tonumber(itemId)] then
		tooltip:AddLine(" ") --blank line

		local missingCommIDs = ""
		local data = itemsWithSpellsCache[tonumber(itemId)]
		if next(data.personal) then
			local spells, numSpells, lastSpellCommID = "", 0, ""
			local spellDesc
			for k, commID in ipairs(data.personal) do
				if not tContains(data.phase, commID) then -- Skip if it exists in both Phase & Personal, Prioritize Phase
					local spellData = ns.Vault.personal.findSpellByID(commID)
					if spellData then
						if spellData.description then
							spellDesc = spellData.description
						end
						spells = spells .. spellData.fullName .. ", "
						lastSpellCommID = commID
						numSpells = k
					else
						missingCommIDs = missingCommIDs .. commID .. ", "
					end
				end
			end
			spells = strtrim(spells, " ,")
			local ttLine = "Use: Cast Personal ArcSpell" .. (numSpells > 1 and "s" or "") .. ": "
			if numSpells == 1 and spellDesc and spellDesc ~= "" then
				if (IsShiftKeyDown() or IsControlKeyDown()) then spellDesc = spellDesc .. " (ArcSpell: " .. lastSpellCommID .. ")" end
				tooltip:AddLine(Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode("Use: " .. spellDesc), nil, nil, nil, true)
			elseif spells ~= "" then
				tooltip:AddLine(Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode(ttLine .. spells), nil, nil, nil, true)
			end
		end
		if next(data.phase) then
			local spells, numSpells = "", 0
			local spellDesc
			for k, commID in ipairs(data.phase) do
				local spellData = ns.Vault.phase.findSpellByID(commID)
				if spellData then
					if spellData.description then
						spellDesc = spellData.description
					end
					spells = spells .. spellData.fullName .. ", "
					numSpells = k
				else
					missingCommIDs = missingCommIDs .. commID .. "*, "
				end
			end
			spells = strtrim(spells, " ,")
			local ttLine = "Use: Cast Phase ArcSpell" .. (numSpells > 1 and "s" or "") .. ": "
			if numSpells == 1 and spellDesc and spellDesc ~= "" then
				tooltip:AddLine(Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode("Use (P): " .. spellDesc), nil, nil, nil, true)
			elseif spells ~= "" then
				tooltip:AddLine(Constants.ADDON_COLORS.ADDON_COLOR:WrapTextInColorCode(ttLine .. spells), nil, nil, nil, true)
			end
		end
		if missingCommIDs ~= "" then
			missingCommIDs = strtrim(missingCommIDs, " ,")
			tooltip:AddLine(Constants.ADDON_COLORS.TOOLTIP_WARNINGRED:WrapTextInColorCode("The following ArcSpells are missing and could not be loaded:"), nil, nil, nil, true)
			tooltip:AddLine(Constants.ADDON_COLORS.TOOLTIP_WARNINGRED:WrapTextInColorCode(missingCommIDs), nil, nil, nil, true)
		end
	end
	tooltip:Show() -- refreshes the tooltip layout
end

GameTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)
ItemRefTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)

-- hooking ItemRefTooltip to listen for shift presses to preview the Arc Scripts

local SHIFT_KEY = "LSHIFT"
local CTRL_KEY = "LCTRL"
ItemRefTooltip:EnableKeyboard(true); ItemRefTooltip:SetPropagateKeyboardInput(true);
ItemRefTooltip:HookScript("OnKeyDown", function(self, key)
	self:SetPropagateKeyboardInput(key ~= SHIFT_KEY and key ~= CTRL_KEY)
	if key ~= SHIFT_KEY and key ~= CTRL_KEY then return end

	local _, link = self:GetItem()
	if not link then return; end

	local itemString = match(link, "item[%-?%d:]+")
	local _, itemID = strsplit(":", itemString)

	ItemRefTooltip:SetItemByID(itemID)
end)

ItemRefTooltip:SetScript("OnKeyUp", function(self, key)
	--if key ~= SHIFT_KEY then return end -- our propagate block stops any other keys but shift from firing OnKeyUp
	local _, link = self:GetItem()
	if not link then return; end

	local itemString = match(link, "item[%-?%d:]+")
	local _, itemID = strsplit(":", itemString)

	ItemRefTooltip:SetItemByID(itemID)
end)

--[[
hooksecurefunc("SetItemRef", function(link, ...)
	GameTooltip_OnTooltipSetItem(ItemRefTooltip)
end)
--]]

--#endregion

---@class UI_ItemIntegration_scripts
ns.UI.ItemIntegration.scripts = {
	updateCache = updateCache,
	triggerCooldowns = triggerCooldowns,

	getSpellsWithItemLinks = getSpellsWithItemLinks,
	addItemSpellLink = addItemSpellLink,

	deleteSpellFromItem = deleteSpellFromItem,
	deleteItemLink = deleteItemLink,

	LinkItemToSpell = safeAddItemToSpell,
	RemoveItemLinkFromSpell = safeRemoveItemFromSpell,
}
