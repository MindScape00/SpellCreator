---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local NineSlice = ns.Utils.NineSlice
local Permissions = ns.Permissions
local Tooltip = ns.Utils.Tooltip
local UIHelpers = ns.Utils.UIHelpers

local ASSETS_PATH = Constants.ASSETS_PATH
local SPELL_VISIBILITY = Constants.SPELL_VISIBILITY
local VAULT_TYPE = Constants.VAULT_TYPE

---@type integer?
local selectedRow = nil

---@return VaultType currentVault
local function getCurrentVault()
	local currentVaultTab = PanelTemplates_GetSelectedTab(SCForgeMainFrame.LoadSpellFrame)


	if currentVaultTab == 2 then
		return VAULT_TYPE.PHASE
	end

	return VAULT_TYPE.PERSONAL
end

---@return SpellVisibility visibility
local function getUploadToPhaseVisibility()
	return SCForgeMainFrame.LoadSpellFrame.PrivateUploadToggle:GetChecked() and SPELL_VISIBILITY.PRIVATE or SPELL_VISIBILITY.PUBLIC
end

---@return CommID?
local function getSelectedSpellCommID()
	if selectedRow then
		return SCForgeMainFrame.LoadSpellFrame.Rows[selectedRow].commID
	end
end

---@param rowID integer?
local function selectRow(rowID)
	if rowID then
		selectedRow = rowID
		if Permissions.isOfficerPlus() then
			SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Enable()
		else
			SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Disable()
		end
		SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:Enable()
	else
		selectedRow = nil
		SCForgeMainFrame.LoadSpellFrame.UploadToPhaseButton:Disable()
		SCForgeMainFrame.LoadSpellFrame.DownloadToPersonalButton:Disable()
	end
end

---@param frame Frame
---@param import fun()
local function createImportButton(frame, import)
	local importButton = CreateFrame("BUTTON", nil, frame)
	importButton:SetPoint("BOTTOMLEFT", 3, 3)
	importButton:SetSize(24,24)
	importButton:SetText("Import")
	importButton:SetMotionScriptsWhileDisabled(true)

	UIHelpers.setupCoherentButtonTextures(importButton, "interface/buttons/ui-microstream-yellow")

	-- overrides to flip the texture to point up & change pushed to the green arrow
	importButton.NormalTexture:SetTexCoord(0,1,1,0)
	importButton.HighlightTexture:SetTexCoord(0,1,1,0)
	importButton.PushedTexture:SetTexture("interface/buttons/ui-microstream-green")
	importButton.PushedTexture:SetTexCoord(0,1,1,0)
	-- I don't know how to clear these undefined fields..

	--[[
	importButton.backIcon = importButton:CreateTexture(nil, "BACKGROUND")
	importButton.backIcon:SetAllPoints(true)
	importButton.backIcon:SetAtlas("poi-workorders")
	--]]

	importButton:SetScript("OnClick", import)

	Tooltip.set(importButton,
		"Import an ArcSpell",
		"Paste an ArcSpell export code into the UI to save it to your Personal Vault."
	)

	return importButton
end

---@param frame Frame
---@param upload fun(commID: CommID)
local function createUploadToPhaseButton(frame, upload)
	local uploadButton = CreateFrame("BUTTON", nil, frame, "UIPanelButtonNoTooltipTemplate")
	uploadButton:SetPoint("BOTTOM", 0, 3)
	uploadButton:SetSize(24*5,24)
	uploadButton:SetText("    Phase Vault")
	uploadButton:SetMotionScriptsWhileDisabled(true)

	uploadButton.icon = uploadButton:CreateTexture(nil, "ARTWORK")
	uploadButton.icon:SetTexture(ASSETS_PATH .. "/icon-transfer")
	uploadButton.icon:SetTexCoord(0,1,1,0)
	uploadButton.icon:SetPoint("TOPLEFT", 5, 0)
	uploadButton.icon:SetSize(24,24)

	uploadButton:SetScript("OnClick", function()
		local commID = getSelectedSpellCommID()
		if commID then
			upload(commID)
		end
	end)

	uploadButton:SetScript("OnDisable", function(self)
		self.icon:SetDesaturated(true)
	end)
	uploadButton:SetScript("OnEnable", function(self)
		self.icon:SetDesaturated(false)
	end)

	Tooltip.set(uploadButton,
		"Copy to Phase Vault",
		function(self)
			if self:IsEnabled() then
				return "Copy the spell to the Phase Vault.\n\rShift-Click to automatically over-write any spell with the same command ID in the Phase Vault."
			elseif (not Permissions.isOfficerPlus()) then
				return "You do not currently have permissions to upload to this phase's vault.\n\rIf you were just given officer, rejoin the phase."
			end

			return "Select a spell above to copy it to the Phase Vault."
		end
	)

	return uploadButton
end

---@param frame LoadSpellFrame
local function createPrivateUploadToggle(frame)
	local privateUploadToggle = CreateFrame("CHECKBUTTON", nil, frame)
	privateUploadToggle:SetPoint("LEFT", frame.UploadToPhaseButton, "RIGHT", 6, 0)
	privateUploadToggle:SetSize(20,20)
	--privateUploadToggle.text:SetText("Private")

	UIHelpers.setupCoherentButtonTextures(privateUploadToggle, ASSETS_PATH .. "/icon_visible_32", false)
	privateUploadToggle.HighlightTexture:SetAlpha(0.2) -- override, 0.33 is still too bright

	privateUploadToggle.NormalTexture:SetVertexColor(0.9,0.65,0)
	privateUploadToggle.PushedTexture:SetVertexColor(0.9,0.65,0)
	privateUploadToggle:SetCheckedTexture("")

	privateUploadToggle.updateTex = function(self)
		if self:GetChecked() then
			self:SetNormalTexture(ASSETS_PATH .. "/icon_hidden_32")
			self:GetNormalTexture():SetVertexColor(0.6,0.6,0.6)
			self:SetPushedTexture(ASSETS_PATH .. "/icon_hidden_32")
			self.HighlightTexture:SetTexture(ASSETS_PATH .. "/icon_hidden_32")
		else
			self:SetNormalTexture(ASSETS_PATH .. "/icon_visible_32")
			self:GetNormalTexture():SetVertexColor(0.9,0.65,0)
			self:SetPushedTexture(ASSETS_PATH .. "/icon_visible_32")
			self.HighlightTexture:SetTexture(ASSETS_PATH .. "/icon_visible_32")
		end
		self.PushedTexture:SetVertexColor(self:GetNormalTexture():GetVertexColor())
	end

	privateUploadToggle:SetScript("OnClick", function(self)
		self:updateTex()
	end)
	privateUploadToggle:SetScript("OnShow", function(self)
		self:updateTex()
	end)

	Tooltip.set(privateUploadToggle,
		function(self)
			local visibility = self:GetChecked() and "Private" or "Public"
			return "Uploading as: " .. visibility .. " Spell"
		end,
		function(self)
			local oppositeVisibility = self:GetChecked() and "Public" or "Private"
			return {
				"Click to switch to " .. oppositeVisibility .. " Visibility",
				"\nWhen uploaded as a private spell, only Officers+ will be able to see it in the Phase Vault - however, it can still be used by anyone (i.e., via Gossip integration).\n\rThe main use of this is to reduce clutter for normal players if you have specific ArcSpells for background use, like an NPC Gossip."
			}
		end,
		{ updateOnClick = true }
	)

	return privateUploadToggle
end

---@param frame Frame
---@param downloadToPersonal fun(commID: CommID)
local function createDownloadToPersonalButton(frame, downloadToPersonal)
	local downloadToPersonalButton = CreateFrame("BUTTON", nil, frame, "UIPanelButtonNoTooltipTemplate")
	downloadToPersonalButton:SetPoint("BOTTOM", 0, 3)
	downloadToPersonalButton:SetSize(24*5.5,24)
	downloadToPersonalButton:SetText("     Personal Vault")
	downloadToPersonalButton:SetMotionScriptsWhileDisabled(true)

	downloadToPersonalButton.icon = downloadToPersonalButton:CreateTexture(nil, "ARTWORK")
	downloadToPersonalButton.icon:SetTexture(ASSETS_PATH .. "/icon-transfer")
	downloadToPersonalButton.icon:SetTexCoord(0,1,1,0)
	downloadToPersonalButton.icon:SetPoint("TOPLEFT", 5, 0)
	downloadToPersonalButton.icon:SetSize(24,24)

	downloadToPersonalButton:SetScript("OnClick", function()
		local commID = getSelectedSpellCommID()
		if commID then
			downloadToPersonal(commID)
		end
	end)

	downloadToPersonalButton:SetScript("OnDisable", function(self)
		self.icon:SetDesaturated(true)
	end)
	downloadToPersonalButton:SetScript("OnEnable", function(self)
		self.icon:SetDesaturated(false)
	end)

	Tooltip.set(downloadToPersonalButton,
		"Transfer to Personal Vault",
		function(self)
			if self:IsEnabled() then
				return "Transfer the spell to your Personal Vault."
			end
			return "Select a spell above to transfer it."
		end
	)

	downloadToPersonalButton:SetScript("OnShow", function(self)
		if not getSelectedSpellCommID() then self:Disable(); end
	end)

	return downloadToPersonalButton
end

---@param callbacks { import: fun(), upload: fun(commID: CommID), downloadToPersonal: fun(commID: CommID) }
local function init(callbacks)
	---@class LoadSpellFrame: ButtonFrameTemplate, Frame
	local loadSpellFrame = CreateFrame("Frame", "SCForgeLoadFrame", SCForgeMainFrame, "ButtonFrameTemplate")
	ButtonFrameTemplate_HidePortrait(loadSpellFrame)

	NineSlice.ApplyLayoutByName(loadSpellFrame.NineSlice, "ArcanumFrameTemplateNoPortrait")

	loadSpellFrame:SetPoint("TOPLEFT", SCForgeMainFrame, "TOPRIGHT", 0, 0)
	loadSpellFrame:SetSize(280,SCForgeMainFrame:GetHeight())
	loadSpellFrame:SetFrameStrata("MEDIUM")

	do
		loadSpellFrame.Inset.Bg2 = loadSpellFrame.Inset:CreateTexture(nil, "BACKGROUND")
		local background = loadSpellFrame.Inset.Bg2
		background:SetTexture(ASSETS_PATH .. "/SpellForgeVaultBG")
		background:SetVertTile(false)
		background:SetHorizTile(false)
		background:SetTexCoord(0.0546875,1-0.0546875,0.228515625,1-0.228515625)
		--background:SetTexture(ASSETS_PATH .. "/FrameBG_Darkblue-thin") -- FOR ARCANUM 2.0 // VAULT FIRST
		background:SetPoint("TOPLEFT")
		background:SetPoint("BOTTOMRIGHT",-19,0)
	end

	loadSpellFrame:SetTitle("Spell Vault")
	loadSpellFrame.TitleBgColor = loadSpellFrame:CreateTexture(nil, "BACKGROUND")
	loadSpellFrame.TitleBgColor:SetPoint("TOPLEFT", loadSpellFrame.TitleBg)
	loadSpellFrame.TitleBgColor:SetPoint("BOTTOMRIGHT", loadSpellFrame.TitleBg)
	loadSpellFrame.TitleBgColor:SetColorTexture(0.40,0.10,0.50,0.5)

	loadSpellFrame.ImportSpellButton = createImportButton(loadSpellFrame, callbacks.import)
	loadSpellFrame.UploadToPhaseButton = createUploadToPhaseButton(loadSpellFrame, callbacks.upload)
	loadSpellFrame.PrivateUploadToggle = createPrivateUploadToggle(loadSpellFrame)
	loadSpellFrame.DownloadToPersonalButton = createDownloadToPersonalButton(loadSpellFrame, callbacks.downloadToPersonal)

	loadSpellFrame.UploadToPhaseButton:SetScript("OnShow", function(self)
		if not getSelectedSpellCommID() then self:Disable() end
		loadSpellFrame.PrivateUploadToggle:Show()
	end)

	loadSpellFrame.UploadToPhaseButton:SetScript("OnHide", function()
		loadSpellFrame.PrivateUploadToggle:Hide()
	end)

	return loadSpellFrame
end

---@class UI_LoadSpellFrame
ns.UI.LoadSpellFrame = {
	init = init,
	getCurrentVault = getCurrentVault,
	getUploadToPhaseVisibility = getUploadToPhaseVisibility,
	selectRow = selectRow,
}
