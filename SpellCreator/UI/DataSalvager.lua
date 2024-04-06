---@class ns
local ns = select(2, ...)

local LibDeflate = ns.Libs.LibDeflate
local AceSerializer = ns.Libs.AceSerializer

local function compressForAddonMsg(str)
	print("original:", str)
	--str = AceSerializer:Serialize(str)
	--print("serialized:", str)
	str = LibDeflate:CompressDeflate(str, { level = 9 })
	print("compressed:", str)
	str = LibDeflate:EncodeForWoWChatChannel(str)
	print("encoded:", str)
	return str;
end

local function decompressForAddonMsg(str)
	print("original:", str)
	str = LibDeflate:DecodeForWoWChatChannel(str)
	print("decoded:", str)
	str = LibDeflate:DecompressDeflate(str)
	print("decompressed:", str)
	--_, str = AceSerializer:Deserialize(str)
	--print("deserialized:", str)
	return str;
end

local function compressForExport(str)
	print("original:", str)
	--str = AceSerializer:Serialize(str)
	--print("serialized:", str)
	str = LibDeflate:CompressDeflate(str, { level = 9 })
	print("compressed:", str)
	str = LibDeflate:EncodeForPrint(str)
	print("encoded:", str)
	return str;
end

local function decompressForImport(str)
	print("original:", str)
	str = LibDeflate:DecodeForPrint(str)
	print("decoded:", str)
	str = LibDeflate:DecompressDeflate(str)
	print("decompressed:", str)
	--_, str = AceSerializer:Deserialize(str)
	--print("deserialized:", str)
	return str;
end

local salvagerMenu
local function showSalvagerMenu()
	if not salvagerMenu then
		-- Backdrop with gold border
		local backdrop = {
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/GLUES/Common/Glue-Tooltip-Border",
			tile = true,
			edgeSize = 11,
			tileSize = 10,
			insets = {
				left = 5,
				right = 3,
				top = 3,
				bottom = 5,
			},
		}

		-- Backdrop with thin silver border
		local backdrop2 = {
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			edgeSize = 8,
			tileSize = 10,
			insets = {
				left = 1,
				right = 1,
				top = 1,
				bottom = 1,
			},
		}

		salvagerMenu = CreateFrame("Frame", nil, UIParent)
		salvagerMenu:SetSize(524, 300)
		salvagerMenu:SetPoint("CENTER")
		salvagerMenu:SetFrameStrata("BACKGROUND")
		salvagerMenu:SetBackdrop(backdrop)
		salvagerMenu:SetBackdropColor(0, 0, 0, 0.5)
		salvagerMenu:SetMovable(true)
		salvagerMenu:SetResizable(true)
		salvagerMenu:EnableMouse(true)
		salvagerMenu:RegisterForDrag("LeftButton")
		salvagerMenu:SetScript("OnDragStart", salvagerMenu.StartMoving)
		salvagerMenu:SetScript("OnDragStop", salvagerMenu.StopMovingOrSizing)
		salvagerMenu:SetMinResize(303, 150);
		tinsert(UISpecialFrames, salvagerMenu:GetName())


		salvagerMenu.Title = salvagerMenu:CreateFontString("HeaderString", "OVERLAY", "GameFontNormalLarge")
		salvagerMenu.Title:SetPoint("TOPLEFT", 10, -8)
		salvagerMenu.Title:SetText("Arcanum - Data Salvager")

		salvagerMenu.Close = CreateFrame("Button", "$parentClose", salvagerMenu)
		salvagerMenu.Close:SetSize(32, 32)
		salvagerMenu.Close:SetPoint("TOPRIGHT")
		salvagerMenu.Close:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
		salvagerMenu.Close:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
		salvagerMenu.Close:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight", "ADD")
		salvagerMenu.Close:SetScript("OnClick", function(self)
			self:GetParent():Hide()
		end)

		salvagerMenu.Clear = CreateFrame("Button", "$parentClear", salvagerMenu, "UIPanelButtonTemplate")
		salvagerMenu.Clear:SetSize(48, 21)
		salvagerMenu.Clear:SetPoint("RIGHT", salvagerMenu.Close, "LEFT")
		salvagerMenu.Clear:SetText("Clear")
		salvagerMenu.Clear:SetScript("OnClick", function(self)
			self:GetParent().Text:SetText("")
		end)

		salvagerMenu.Select = CreateFrame("Button", "$parentSelect", salvagerMenu, "UIPanelButtonTemplate")
		salvagerMenu.Select:SetSize(48, 21)
		salvagerMenu.Select:SetPoint("RIGHT", salvagerMenu.Clear, "LEFT", -5, 0)
		salvagerMenu.Select:SetText("Select")
		salvagerMenu.Select:SetScript("OnClick", function(self)
			self:GetParent().Text:HighlightText()
			self:GetParent().Text:SetFocus()
		end)

		salvagerMenu.EncodeAddOn = CreateFrame("Button", "$parentSpawn", salvagerMenu, "UIPanelButtonTemplate")
		salvagerMenu.EncodeAddOn:SetSize(128, 24)
		salvagerMenu.EncodeAddOn:SetPoint("BOTTOM", -64, 9)
		salvagerMenu.EncodeAddOn:SetText("Encode (AddOn)")
		salvagerMenu.EncodeAddOn:SetScript("OnClick", function(self)
			local str = self:GetParent().Text:GetText()
			str = compressForAddonMsg(str)
			self:GetParent().Text:SetText(str)
		end)

		salvagerMenu.DecodeAddOn = CreateFrame("Button", "$parentSpawn", salvagerMenu, "UIPanelButtonTemplate")
		salvagerMenu.DecodeAddOn:SetSize(128, 24)
		salvagerMenu.DecodeAddOn:SetPoint("RIGHT", salvagerMenu.EncodeAddOn, "LEFT", 0, 0)
		salvagerMenu.DecodeAddOn:SetText("Decode (AddOn)")
		salvagerMenu.DecodeAddOn:SetScript("OnClick", function(self)
			local str = self:GetParent().Text:GetText()
			str = decompressForAddonMsg(str)
			self:GetParent().Text:SetText(str)
		end)

		salvagerMenu.EncodeExport = CreateFrame("Button", "$parentSpawn", salvagerMenu, "UIPanelButtonTemplate")
		salvagerMenu.EncodeExport:SetSize(128, 24)
		salvagerMenu.EncodeExport:SetPoint("BOTTOM", 64, 9)
		salvagerMenu.EncodeExport:SetText("Encode (Export)")
		salvagerMenu.EncodeExport:SetScript("OnClick", function(self)
			local str = self:GetParent().Text:GetText()
			str = compressForExport(str)
			self:GetParent().Text:SetText(str)
		end)

		salvagerMenu.DecodeExport = CreateFrame("Button", "$parentSpawn", salvagerMenu, "UIPanelButtonTemplate")
		salvagerMenu.DecodeExport:SetSize(128, 24)
		salvagerMenu.DecodeExport:SetPoint("LEFT", salvagerMenu.EncodeExport, "RIGHT", 0, 0)
		salvagerMenu.DecodeExport:SetText("Decode (Export)")
		salvagerMenu.DecodeExport:SetScript("OnClick", function(self)
			local str = self:GetParent().Text:GetText()
			str = decompressForImport(str)
			self:GetParent().Text:SetText(str)
		end)

		salvagerMenu.SF = CreateFrame("ScrollFrame", "$parent_DF", salvagerMenu, "UIPanelScrollFrameTemplate")
		salvagerMenu.SF:SetPoint("TOPLEFT", salvagerMenu, 12, -30)
		salvagerMenu.SF:SetPoint("BOTTOMRIGHT", salvagerMenu, -30, 35)
		salvagerMenu.SF:SetScript("OnMouseUp", function(self)
			salvagerMenu.Text:SetFocus()
			salvagerMenu.Text:SetCursorPosition(salvagerMenu.Text:GetNumLetters())
		end)
		salvagerMenu.SF.backdrop = CreateFrame("FRAME", "$parent_Backdrop", salvagerMenu.SF)
		salvagerMenu.SF.backdrop:SetPoint("TOPLEFT", salvagerMenu.SF, -3, 3)
		salvagerMenu.SF.backdrop:SetPoint("BOTTOMRIGHT", salvagerMenu.SF, 2, -2)
		salvagerMenu.SF.backdrop:SetBackdrop(backdrop2)
		salvagerMenu.SF.backdrop:SetBackdropColor(0, 0, 0, 0.5)
		salvagerMenu.SF.backdrop:SetFrameLevel(2)


		salvagerMenu.Text = CreateFrame("EditBox", "$parent_DF_Text", salvagerMenu)
		salvagerMenu.Text:SetMultiLine(true)
		salvagerMenu.Text:SetSize(salvagerMenu.SF:GetWidth() - 5, salvagerMenu.SF:GetHeight())
		salvagerMenu.Text:SetPoint("TOPLEFT", salvagerMenu.SF)
		salvagerMenu.Text:SetPoint("BOTTOMRIGHT", salvagerMenu.SF)
		--f.Text:SetMaxLetters(99999)
		salvagerMenu.Text:SetFontObject(GameFontNormal)
		salvagerMenu.Text:SetTextColor(10, 10, 10, 1)
		salvagerMenu.Text:SetAutoFocus(false)
		salvagerMenu.Text:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		salvagerMenu.SF:SetScrollChild(salvagerMenu.Text)
		salvagerMenu:Hide()
	end

	salvagerMenu:SetShown(not salvagerMenu:IsShown())
end

---@class UI_DataSalvager
ns.UI.DataSalvager = {
	showSalvagerMenu = showSalvagerMenu
}
