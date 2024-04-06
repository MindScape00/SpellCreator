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
	local dialog = StaticPopup_Show("SCFORGE_EXPORT_MENU", spellName, nil, nil, exportMenuFrame)
	dialog.insertedFrame.ScrollFrame.EditBox:SetText(data)
	dialog.insertedFrame.ScrollFrame.EditBox:SetFocus()
	dialog.insertedFrame.ScrollFrame.EditBox:HighlightText()
end

---@param spell VaultSpell
local function exportSpell(spell)
	showExportMenu("ArcSpell " .. ns.Utils.Tooltip.genContrastText(spell.fullName), spell.commID .. ":" .. Serializer.compressForExport(spell))
end

---@param text string input data
local function getDataFromImportString(text)
	if not text then
		ns.Logging.eprint("Import Error: No ArcSpell import data provided.")
		return
	end
	local rest
	text, rest = strsplit(":", text, 2)
	local spellData
	if text and rest and rest ~= "" then
		spellData = Serializer.decompressForImport(rest)
	elseif text ~= "" then
		spellData = Serializer.decompressForImport(text)
	else
		Logging.eprint("Import Error: Invalid ArcSpell data. Try again.")
		return
	end

	return spellData
end

---@param text string input data
---@param vocal boolean|string? if we should tell them
local function importSpell(text, vocal)
	if not text then
		ns.Logging.eprint("Import Error: No ArcSpell import data provided.")
		return
	end

	local spellData = getDataFromImportString(text)

	if spellData and spellData ~= "" then ns.MainFuncs.saveSpell(nil, nil, spellData, vocal) end
end

local function exportAllSparks()
	local thePhaseID = C_Epsilon.GetPhaseId()
	showExportMenu(("Sparks (Phase %s)"):format(thePhaseID), "Phase" .. thePhaseID .. "Sparks" .. ":" .. Serializer.compressForExport(ns.UI.SparkPopups.SparkPopups.getPhaseSparkTriggersCache()))
end

local function showImportSpellMenu()
	local dialog = StaticPopup_Show("SCFORGE_IMPORT_SPELL", nil, nil, nil, exportMenuFrame)
	dialog.insertedFrame.ScrollFrame.EditBox:SetText("")
	dialog.insertedFrame.ScrollFrame.EditBox:SetFocus()
end

local function showImportSparksMenu()
	local dialog = StaticPopup_Show("SCFORGE_IMPORT_SPARKS", nil, nil, nil, exportMenuFrame)
	dialog.insertedFrame.ScrollFrame.EditBox:SetText("")
	dialog.insertedFrame.ScrollFrame.EditBox:SetFocus()
end

local function init(saveSpell) -- this doesn't need an init anymore cuz we no longer need to pass saveSpell but WHATEVER
	StaticPopupDialogs["SCFORGE_EXPORT_MENU"] = {
		text = "Arcanum Export: %s",
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
			importSpell(text)
		end,
		hideOnEscape = true,
		whileDead = true,
	}

	StaticPopupDialogs["SCFORGE_IMPORT_SPARKS"] = {
		text = "Arcanum Sparks Import",
		subText = "CTRL+V to Paste\n\r" .. ns.Utils.Tooltip.genTooltipText("warning", "This will overwrite any sparks currently in the phase."),
		closeButton = true,
		enterClicksFirstButton = false,
		button1 = "Import",
		OnButton1 = function(self)
			local text = self.insertedFrame.ScrollFrame.EditBox:GetText()
			if not text then return end
			local text, rest = strsplit(":", text, 2)
			local sparkData
			if text and rest and rest ~= "" then
				sparkData = Serializer.decompressForImport(rest)
			elseif text ~= "" then
				sparkData = Serializer.decompressForImport(text)
			else
				Logging.dprint("Invalid Arc Spark data. Try again.")
				return
			end
			if sparkData and sparkData ~= "" then
				Logging.dprint(nil, "Imported Spark Data: ", sparkData)
				ns.UI.SparkPopups.SparkPopups.setPhaseSparkTriggersCache(sparkData)
				ns.UI.SparkPopups.SparkPopups.savePopupTriggersToPhaseData()
			end
		end,
		hideOnEscape = true,
		whileDead = true,
	}
end

---@class UI_ImportExport
ns.UI.ImportExport = {
	init = init,
	exportSpell = exportSpell,
	importSpell = importSpell,

	getDataFromImportString = getDataFromImportString,

	showImportSpellMenu = showImportSpellMenu,
	exportAllSparks = exportAllSparks,
	showImportSparksMenu = showImportSparksMenu,
}
