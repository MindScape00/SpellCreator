---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local Execute = ns.Actions.Execute
local Gossip = ns.Gossip
local SavedVariables = ns.SavedVariables
local Vault = ns.Vault

local Tooltip = ns.Utils.Tooltip

local ChatLink = ns.UI.ChatLink
local ImportExport = ns.UI.ImportExport
local LoadSpellFrame = ns.UI.LoadSpellFrame
local Popups = ns.UI.Popups
local Quickcast = ns.UI.Quickcast

local ADDON_COLORS = ns.Constants.ADDON_COLORS
local VAULT_TYPE = Constants.VAULT_TYPE

local executeSpell = Execute.executeSpell
local getCurrentVault = LoadSpellFrame.getCurrentVault

local contextDropDownMenu = CreateFrame("BUTTON", "ARCLoadRowContextMenu", UIParent, "UIDropDownMenuTemplate")

---@type fun(index: integer)
local downloadToPersonal
---@type fun(spell: VaultSpell)
local loadSpell
---@type fun(commID: CommID)
local upload
---@type fun()
local updateRows

---@param commID CommID
---@param profileName string
local function setSpellProfile(commID, profileName)
	local spell = Vault.personal.findSpellByID(commID)

	if spell then
		spell.profile = profileName
	end
	Vault.personal.findSpellByID(commID).profile = profileName

	updateRows()
end

---@param commID CommID
---@param profileName string?
local function createAndSetProfile(commID, profileName)
	if not profileName then
		Popups.showNewProfilePopup(commID, setSpellProfile)
		return
	end

	setSpellProfile(commID, profileName)
end

---@param spell VaultSpell
local function createOptions(spell)
	local vault = getCurrentVault()
	local menuList = {}
	local item
	local playerName = GetUnitName("player")
	local _profile
	if vault == VAULT_TYPE.PHASE then
		menuList = {
			{
				text = spell.fullName,
				notCheckable = true,
				isTitle = true
			},
			{
				text = "Cast",
				notCheckable = true,
				func = function()
					executeSpell(spell.actions, nil, spell.fullName, spell)
				end
			},
			{
				text = "Edit",
				notCheckable = true,
				func = function()
					loadSpell(spell)
				end
			},
			{
				text = "Transfer",
				tooltipTitle = "Copy to Personal Vault",
				tooltipOnButton = true,
				notCheckable = true,
				func = function()
					downloadToPersonal(spell.commID)
				end
			},
		}
		item = {
			text = "Add to Gossip",
			notCheckable = true,
			func = function()
				_G["scForgeLoadRow" .. spell.commID].gossipButton:Click()
			end,
		}

		if not Gossip.isLoaded() then
			item.disabled = true
			item.text = "(Open a Gossip Menu)"
		end

		tinsert(menuList, item)
	else
		_profile = spell.profile
		menuList = {
			{
				text = spell.fullName,
				notCheckable = true,
				isTitle = true
			},
			{
				text = "Cast",
				notCheckable = true,
				func = function()
					ARC:CAST(spell.commID)
				end
			},
			{
				text = "Edit",
				notCheckable = true,
				func = function()
					loadSpell(spell)
				end,
			},
			{
				text = "Transfer",
				tooltipTitle = "Copy to Phase Vault",
				tooltipOnButton = true,
				notCheckable = true,
				func = function()
					upload(spell.commID)
				end,
			},
		}

		-- Profiles Menu
		item = {
			text = "Profile",
			notCheckable = true,
			hasArrow = true,
			keepShownOnClick = true,
			menuList = {
				{
					text = "Account",
					isNotRadio = (_profile == "Account"),
					checked = (_profile == "Account"),
					disabled = (_profile == "Account"),
					disablecolor = ((_profile == "Account") and ADDON_COLORS.MENU_SELECTED:GenerateHexColorMarkup() or nil),
					func = function()
						setSpellProfile(spell.commID, "Account")
						CloseDropDownMenus()
					end
				},
				{
					text = playerName,
					isNotRadio = (_profile == playerName),
					checked = (_profile == playerName),
					disabled = (_profile == playerName),
					disablecolor = ((_profile == playerName) and ADDON_COLORS.MENU_SELECTED:GenerateHexColorMarkup() or nil),
					func = function()
						setSpellProfile(spell.commID, playerName)
						CloseDropDownMenus()
					end
				},
			},
		}

		local profileNames = SavedVariables.getProfileNames(true, true)
		sort(profileNames)

		for _, profileName in ipairs(profileNames) do
			item.menuList[#item.menuList + 1] = {
				text = profileName,
				isNotRadio = (_profile == profileName),
				checked = (_profile == profileName),
				disabled = (_profile == profileName),
				disablecolor = ((_profile == profileName) and ADDON_COLORS.MENU_SELECTED:GenerateHexColorMarkup() or nil),
				func = function()
					setSpellProfile(spell.commID, profileName)
					CloseDropDownMenus()
				end
			}
		end

		item.menuList[#item.menuList + 1] = {
			text = "Add New",
			fontObject = GameFontNormalSmallLeft,
			func = function()
				createAndSetProfile(spell.commID)
				CloseDropDownMenus()
			end
		}

		tinsert(menuList, item)

		if not spell.author then
			local item = {
				text = "Assign Author",
				tooltipTitle = "Assign Author",
				tooltipText = "This spell has no assigned author. You can manually set the author now.",
				tooltipOnButton = true,
				notCheckable = true,
				func = function()
					Popups.showAssignPersonalSpellAuthorPopup(spell.commID)
				end,
			}
			menuList[#menuList + 1] = item
		else
			local item = {
				text = "Change Author",
				tooltipTitle = "Change Author",
				tooltipText = "You can change the author of this spell. If you did not author this spell, please respect the original author and leave their credit.\n\rCurrent Author: "
					.. Tooltip.genContrastText(spell.author),
				tooltipOnButton = true,
				notCheckable = true,
				func = function()
					Popups.showAssignPersonalSpellAuthorPopup(spell.commID, spell.author)
				end,
			}
			menuList[#menuList + 1] = item
		end

		-- Tags Menu
		--[[
		item = {text = "Edit Tags", notCheckable=true, hasArrow=true, keepShownOnClick=true,
			menuList = {}
		}
		for k,v in ipairs(baseVaultFilterTags) do
			interTagTable[v] = false
		end
		if spell.tags then
			for k,v in pairs(spell.tags) do
				interTagTable[k] = true
			end
		end
		for k,v in orderedPairs(interTagTable) do
			tinsert(item.menuList, { text = k, checked = v, keepShownOnClick=true, func = function(self) editVaultTags(k, spellCommID, 1); end })
		end
		--tinsert(item.menuList, { })
		--tinsert(item.menuList, { text = "Add New", })
		tinsert(menuList, item)
		--]]
		if tContains(SpellCreatorMasterTable.quickCastSpells, spell.commID) then
			menuList[#menuList + 1] = {
				text = "Remove from QuickCast",
				notCheckable = true,
				func = function()
					tDeleteItem(SpellCreatorMasterTable.quickCastSpells, spell.commID)
					Quickcast.hideCastCuttons()
				end,
			}
		else
			menuList[#menuList + 1] = {
				text = "Add to QuickCast",
				notCheckable = true,
				func = function()
					tinsert(SpellCreatorMasterTable.quickCastSpells, spell.commID);
				end,
			}
		end

		menuList[#menuList + 1] = {
			text = "Link Hotkey",
			notCheckable = true,
			func = function()
				Popups.showLinkHotkeyDialog(spell.commID)
			end,
		}
	end

	menuList[#menuList + 1] = {
		text = "Chatlink",
		notCheckable = true,
		func = function()
			ChatLink.linkSpell(spell, vault)
		end,
	}

	menuList[#menuList + 1] = {
		text = "Export",
		notCheckable = true,
		func = function()
			ImportExport.exportSpell(spell)
		end,
	}

	return menuList
end

---@param spell VaultSpell
local function show(spell)
	EasyMenu(createOptions(spell), contextDropDownMenu, "cursor", 0, 0, "MENU");
end

---@param inject { loadSpell: fun(spell: VaultSpell), downloadToPersonal: fun(index: integer), upload: fun(commID: CommID), updateRows: fun() }
local function init(inject)
	loadSpell = inject.loadSpell
	downloadToPersonal = inject.downloadToPersonal
	upload = inject.upload
	updateRows = inject.updateRows
end

---@class UI_SpellLoadRowContextMenu
ns.UI.SpellLoadRowContextMenu = {
	init = init,
	show = show,
}
