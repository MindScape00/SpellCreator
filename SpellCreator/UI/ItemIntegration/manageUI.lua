---@class ns
local ns = select(2, ...)

local DataUtils = ns.Utils.Data
local AceGUI = ns.Libs.AceGUI
local AceConfig = ns.Libs.AceConfig
local AceConfigDialog = ns.Libs.AceConfigDialog
local AceConfigRegistry = ns.Libs.AceConfigRegistry
local Quickcast = ns.UI.Quickcast
local Tooltip = ns.Utils.Tooltip
local Popups = ns.UI.Popups
local Dropdown = ns.UI.Dropdown
local Constants = ns.Constants
local Permissions = ns.Permissions

local VAULT_TYPE = Constants.VAULT_TYPE

local ADDON_COLORS = ns.Constants.ADDON_COLORS

local cmd = ns.Cmd.cmd
local round = DataUtils.roundToNthDecimal
local orderedPairs = DataUtils.orderedPairs

-- -- -- -- -- -- -- -- -- -- -- --
--#region Sub Menu Generation for Item Connections
-- -- -- -- -- -- -- -- -- -- -- --

---@param spell VaultSpell
---@param isPhase boolean?
---@return boolean
---@return table
local function genItemMenuSubMenu(spell, isPhase)
	local spellItems = spell.items
	local hasSpells = false
	local vaultType = isPhase and VAULT_TYPE.PHASE or VAULT_TYPE.PERSONAL
	local vaultName = string.lower(vaultType)

	local items = {
		Dropdown.input("Connect Item", {
			placeholder = "Item ID / Link",
			hidden = (isPhase and not Permissions.isMemberPlus()),
			hyperlinkEnabled = true,
			set = function(self, val)
				if val then
					if not tonumber(val) then
						val = ns.Utils.Data.getItemInfoFromHyperlink(val)
					end
					if val then
						if ns.UI.ItemIntegration.scripts.LinkItemToSpell(spell, val, vaultType, true) then
							if isPhase then
								--ns.MainFuncs.uploadSpellDataToPhaseData(spell.commID, spell)
								ns.Vault.phase.uploadSingleSpellAndNotifyUsers(spell.commID, spell)
							end
						end
					else
						ns.Logging.uiErrorMessage("Invalid Item. Could not connect Item & ArcSpell.", Constants.ADDON_COLORS.TOOLTIP_WARNINGRED:GetRGB())
					end
				end
			end
		}),
	}
	if spellItems and type(spellItems) == "table" and next(spellItems) then
		hasSpells = true
		if not (isPhase and not Permissions.isMemberPlus()) then
			tinsert(items, Dropdown.spacer())
		end
		tinsert(items, Dropdown.header("Assigned Items:"))
		for i = 1, #spellItems do
			local itemID = spellItems[i]
			local subItems = {
				Dropdown.execute("Add Item", function() cmd("additem " .. itemID) end),
				Dropdown.execute("Unlink", function()
						if ns.UI.ItemIntegration.scripts.RemoveItemLinkFromSpell(spell, itemID, vaultType, true) then
							if isPhase then
								--ns.MainFuncs.uploadSpellDataToPhaseData(spell.commID, spell)
								ns.Vault.phase.uploadSingleSpellAndNotifyUsers(spell.commID, spell)
							end
						end
					end,
					{
						hidden = (isPhase and not Permissions.isMemberPlus())
					}
				)
			}
			local itemName, itemLink, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
			if not itemLink then
				itemLink = "Unknown Item"
				itemTexture = 136254
			end
			local itemNameLinkNoBrackets = string.gsub(itemLink, "%[(.*)%]", "%1")
			tinsert(items, Dropdown.submenu(
				itemNameLinkNoBrackets,
				subItems,
				{
					tooltipTitle = CreateTextureMarkup(itemTexture, 1, 1, 24, 24, 0, 1, 0, 1) .. itemNameLinkNoBrackets,
					tooltipText = "ItemID: " .. itemID,
				}
			))
		end
	end
	return hasSpells, items
end

-- -- -- -- -- -- -- -- -- -- -- --
--#endregion
-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- -- -- -- -- -- -- -- -- --
--#region Popup for "Do you wanna add dis item"
-- -- -- -- -- -- -- -- -- -- -- --

local function showAddItemsPopup(spell, spellLinks, spellItems)
	if not spellItems then spellItems = spell.items end
	local popup = ns.UI.Popups.showCustomGenericConfirmation(
		{
			text = ("ArcSpell %s is connected with the following item(s):\n" .. table.concat(spellLinks, "\n") .. "\n\rDo you want to add them?"):format(Tooltip.genContrastText(spell.fullName)),
			callback = function()
				for k, v in ipairs(spellItems) do
					ns.Cmd.cmd("additem " .. v)
				end
			end,
			acceptText = "Add Items",
			cancelText = "Ignore",
		}
	)
	popup:SetHyperlinksEnabled(true)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ITEM_DATA_LOAD_RESULT")
local itemsLoading = {}
local function ensureItemDataLoaded(items, callback)
	f:SetScript("OnEvent", function(self, event, itemID, success)
		if tContains(itemsLoading, itemID) then
			tDeleteItem(itemsLoading, itemID)
			if not success then
				ns.Logging.uiErrorMessage("Failed to load item " .. itemID, 1, 0, 0)
			end
		end
		if #itemsLoading == 0 then
			callback()
		end
	end)

	for _, itemID in ipairs(items) do
		if not GetItemInfo(itemID) then
			tinsert(itemsLoading, itemID)
			C_Item.RequestLoadItemDataByID(itemID)
		end
	end
	if #itemsLoading == 0 then
		callback()
	end
end

local function checkIfNeedItems(spell)
	if spell.items and next(spell.items) then
		local spellLinks = {}
		local spellItems = {}
		for k, v in ipairs(spell.items) do
			if GetItemCount(v) == 0 then
				local _, link = GetItemInfo(v)
				tinsert(spellLinks, link)
				tinsert(spellItems, v)
			end
		end

		ensureItemDataLoaded(spellItems, function() showAddItemsPopup(spell, spellLinks, spellItems) end)
	end
end
-- -- -- -- -- -- -- -- -- -- -- --
--#endregion
-- -- -- -- -- -- -- -- -- -- -- --
-- -- -- -- -- -- -- -- -- -- -- --
--#region Hooking UIErrors to prevent required proficiency text
-- -- -- -- -- -- -- -- -- -- -- --

local blockedMessages = {
	["You do not have the required proficiency for that item."] = true
}

local origUIErrorsOnEvent = UIErrorsFrame.OnEvent
UIErrorsFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "UI_ERROR_MESSAGE" then
		local messageType, message = ...;
		if blockedMessages[message] then
			return
		end
	end
	origUIErrorsOnEvent(self, event, ...)
end)

-- -- -- -- -- -- -- -- -- -- -- --
--#endregion
-- -- -- -- -- -- -- -- -- -- -- --

---@class UI_ItemIntegration_mangeUI
ns.UI.ItemIntegration.manageUI = {
	genItemMenuSubMenu = genItemMenuSubMenu,
	checkIfNeedItems = checkIfNeedItems,
}
