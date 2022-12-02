---@class ns
local ns = select(2, ...)

local Comms = ns.Comms
local Constants = ns.Constants

local ADDON_COLOR, ASSETS_PATH = Constants.ADDON_COLOR, Constants.ASSETS_PATH
local VAULT_TYPE = Constants.VAULT_TYPE

local tooltipButton

---@param spell VaultSpell
---@param vaultType VaultType
---@return string chatLink
local function generateSpellLink(spell, vaultType)
	local spellName = spell.fullName
	local spellComm = spell.commID
	local spellDesc = spell.description
	if spellDesc == nil then spellDesc = "" end
	local charOrPhase
	if vaultType == VAULT_TYPE.PHASE then
		charOrPhase = C_Epsilon.GetPhaseId()
	else
		charOrPhase = GetUnitName("player",false)
	end
	local numActions = #spell.actions
	local chatLink = ADDON_COLOR.."|HarcSpell:"..spellComm..":"..charOrPhase..":"..numActions..":"..spellDesc.."|h["..spellName.."]|h|r"
	return chatLink;
end

---@param spell VaultSpell
---@param vaultType VaultType
local function linkSpell(spell, vaultType)
	local link = generateSpellLink(spell, vaultType)

	-- from ChatEdit_LinkItem
	if ChatEdit_GetActiveWindow() then
		ChatEdit_InsertLink(link)
	else
		ChatFrame_OpenChat(link)
	end
end

local _ChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow
function ChatFrame_OnHyperlinkShow(...)
	pcall(_ChatFrame_OnHyperlinkShow, ...)
	if IsModifiedClick() then return end
	local linkType, linkData, displayText = LinkUtil.ExtractLink(select(3, ...))
	if linkType == "arcSpell" then
		local spellComm, charOrPhase, spellName, numActions, spellDesc = strsplit(":", linkData)
		if not spellDesc then spellDesc = numActions; numActions = spellName end -- legacy support for old link types
		local spellName = displayText:gsub("%[(.+)%]","%1")
		local spellIconPath = ASSETS_PATH .. "/BookIcon"
		local spellIconSize = 24
		local spellIconSequence = "|T"..spellIconPath..":"..spellIconSize.."|t "
		local tooltipTitle = spellIconSequence..ADDON_COLOR..spellName
		--local tooltipTitle = ADDON_COLOR..spellName
		GameTooltip_SetTitle(ItemRefTooltip, tooltipTitle)
		--ItemRefTooltip:AddTexture(spellIconPath, {width=spellIconSize, height=spellIconSize, anchor=ItemRefTooltip.LeftTop })
		ItemRefTooltip:AddLine(spellDesc, nil, nil, nil, true)
		ItemRefTooltip:AddLine(" ")
		ItemRefTooltip:AddDoubleLine("Command: "..spellComm, "Actions: "..numActions, 1, 1, 1, 1, 1, 1)
		ItemRefTooltip:AddDoubleLine( "Arcanum Spell", charOrPhase, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75 )
		--ItemRefTooltip:AddLine("Actions: "..numActions, 1, 1, 1, 1 )
		--ItemRefTooltip:AddLine(" ")
			C_Timer.After(0, function()
				if tonumber(charOrPhase) then -- is a phase, not a character
					if charOrPhase == "169" then
						ItemRefTooltip:AddLine(" ")
						ItemRefTooltip:AddLine("Get it from the Main Phase Vault")
					else
						ItemRefTooltip:AddLine(" ")
						ItemRefTooltip:AddLine("Get it from Phase "..charOrPhase.."'s Vault")
					end
				elseif charOrPhase == UnitName("player") then
					ItemRefTooltip:AddLine(" ")
					ItemRefTooltip:AddLine("This is your spell.")
				else
					if not tooltipButton then
						tooltipButton = CreateFrame("BUTTON", "SCForgeSpellRefTooltipButton", ItemRefTooltip, "UIPanelButtonTemplate")
						tooltipButton:SetScript("OnClick", function(self)
							Comms.requestSpellFromPlayer(self.playerName, self.commID)
						end)
						tooltipButton:SetText("Request Spell")
					end
					tooltipButton:SetHeight(GameTooltip_InsertFrame(ItemRefTooltip, tooltipButton))
					tooltipButton:SetPoint("RIGHT", -10, 0)
					tooltipButton.playerName = charOrPhase
					tooltipButton.commID = spellComm
				end

				ItemRefTooltip:Show()
				if ItemRefTooltipTextLeft1:GetRight() > ItemRefCloseButton:GetLeft() then
					ItemRefTooltip:SetPadding(16, 0)
				end
			end)

	end
end

---@class UI_ChatLink
ns.UI.ChatLink = {
    linkSpell = linkSpell,
}
