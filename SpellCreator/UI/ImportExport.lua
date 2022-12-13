---@class ns
local ns = select(2, ...)

local Logging = ns.Logging
local Serializer = ns.Serializer

local exportMenuFrame = CreateFrame("Frame")
exportMenuFrame:SetSize(350, 120)
exportMenuFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, exportMenuFrame, "InputScrollFrameTemplate")
exportMenuFrame.ScrollFrame.CharCount:Hide()
exportMenuFrame.ScrollFrame:SetSize(350, 100)
exportMenuFrame.ScrollFrame:SetPoint("CENTER")
exportMenuFrame.ScrollFrame.EditBox:SetWidth(exportMenuFrame.ScrollFrame:GetWidth() - 18)
exportMenuFrame.ScrollFrame.EditBox:SetScript("OnEscapePressed", function(self)
	self:GetParent():GetParent():GetParent():Hide()
end)
exportMenuFrame:Hide()

---@param spellName string
---@param data string
local function showExportMenu(spellName, data)
	local dialog = StaticPopup_Show("SCFORGE_EXPORT_SPELL", spellName, nil, nil, exportMenuFrame)
	dialog.insertedFrame.ScrollFrame.EditBox:SetText(data)
	dialog.insertedFrame.ScrollFrame.EditBox:SetFocus()
	dialog.insertedFrame.ScrollFrame.EditBox:HighlightText()
end

---@param spell VaultSpell
local function exportSpell(spell)
	showExportMenu(spell.fullName, spell.commID .. ":" .. Serializer.compressForExport(spell))
end

local function showImportMenu()
	local dialog = StaticPopup_Show("SCFORGE_IMPORT_SPELL", nil, nil, nil, exportMenuFrame)
	dialog.insertedFrame.ScrollFrame.EditBox:SetText("")
	dialog.insertedFrame.ScrollFrame.EditBox:SetFocus()
end

local function init(saveSpell)
	StaticPopupDialogs["SCFORGE_EXPORT_SPELL"] = {
		text = "ArcSpell Export: %s",
		subText = "CTRL+C to Copy",
		closeButton = true,
		enterClicksFirstButton = true,
		button1 = DONE,
		hideOnEscape = true,
		whileDead = true,
	}

	StaticPopupDialogs["SCFORGE_IMPORT_SPELL"] = {
		text = "ArcSpell Import",
		subText = "CTRL+V to Paste",
		closeButton = true,
		enterClicksFirstButton = true,
		button1 = "Import",
		OnButton1 = function(self)
			local text = self.insertedFrame.ScrollFrame.EditBox:GetText()
			if not text then return end
			local text, rest = strsplit(":", text, 2)
			local spellData
			if text and rest and rest ~= "" then
				spellData = Serializer.decompressForImport(rest)
			elseif text ~= "" then
				spellData = Serializer.decompressForImport(text)
			else
				Logging.dprint("Invalid ArcSpell data. Try again.")
				return
			end
			if spellData and spellData ~= "" then saveSpell(nil, nil, spellData) end
		end,
		hideOnEscape = true,
		whileDead = true,
	}
end

---@class UI_ImportExport
ns.UI.ImportExport = {
	init = init,
	exportSpell = exportSpell,
	showImportMenu = showImportMenu,
}
