if not IsAddOnLoaded("totalRP3_Extended") then return end
if not IsAddOnLoaded("totalRP3_Extended_Tools") then return end

---@class ns
local ns = select(2, ...)

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

local _texFrame = CreateFrame("Frame"); _texFrame:Hide()
-------------------------------- TRP3e Integration Test

local function emptyToNil(text)
	if text and #text > 0 then
		return text;
	end
	return nil;
end

local function addArcTRP3eEffect(key, editorFrame, editorData, effectScript)
	if type(editorFrame) == "function" then
		editorFrame = editorFrame()
	end
	editorData.editor = editorFrame
	TRP3_API.extended.tools.registerEffectEditor(key, editorData);
	TRP3_API.script.registerEffect(key, { method = effectScript, security = 2 })
end

local prismaticGemIcon = Ellyb.Texture(ns.UI.Gems.gemPath("Prismatic"))
local violetGemIcon = Ellyb.Texture(ns.UI.Gems.gemPath("Violet"))

local arcEffects = {
	arc_personal_cast = {
		editorFrame = function()
			if not TRP3_EffectEditorArcSpell then
				local f = CreateFrame("Frame", "TRP3_EffectEditorArcSpell", nil, "TRP3_EditorEffectTemplate")
				f:Hide()
				f:SetSize(500, 250)
				f.commID = CreateFrame("EditBox", nil, f, "TRP3_TitledHelpEditBox")
				f.commID:SetSize(260, 18)
				f.commID:SetPoint("TOP", 0, -65)
				f.commID.title:SetText("Arcanum Spell CommID")
				function f.load(scriptData)
					local data = scriptData.args or { {} };
					f.commID:SetText(data[1] or "commID");
				end

				function f.save(scriptData)
					scriptData.args[1] = emptyToNil(strtrim(f.commID:GetText())) or "**trp3e-effect: no commID**";
				end
			end
			return TRP3_EffectEditorArcSpell -- defined above, stop complaining intellisense ffs
		end,
		effectScript = function(structure, cArgs, eArgs)
			local commID = cArgs[1] or "**trp3e-effect: no commID**";
			ARC:CAST(commID)
			eArgs.LAST = 0;
		end,
		editorData = {
			title = "Cast Personal ArcSpell",
			icon = violetGemIcon,
			description = "Cast an Arcanum Spell by CommID from your Personal Vault",
			effectFrameDecorator = function(scriptStepFrame, args)
				scriptStepFrame.description:SetText("ArcSpell:|cff00ff00 " .. tostring(args[1]));
			end,
			getDefaultArgs = function()
				return { "commID" };
			end,
		},
	},
	arc_phase_cast = {
		editorFrame = function()
			if not TRP3_EffectEditorArcSpell then
				local f = CreateFrame("Frame", "TRP3_EffectEditorArcSpell", nil, "TRP3_EditorEffectTemplate")
				f:Hide()
				f:SetSize(500, 250)
				f.commID = CreateFrame("EditBox", nil, f, "TRP3_TitledHelpEditBox")
				f.commID:SetSize(260, 18)
				f.commID:SetPoint("TOP", 0, -65)
				f.commID.title:SetText("Arcanum Spell CommID")
				function f.load(scriptData)
					local data = scriptData.args or { {} };
					f.commID:SetText(data[1] or "commID");
				end

				function f.save(scriptData)
					scriptData.args[1] = emptyToNil(strtrim(f.commID:GetText())) or "**trp3e-effect: no commID**";
				end
			end
			return TRP3_EffectEditorArcSpell -- defined above, stop complaining intellisense ffs
		end,
		effectScript = function(structure, cArgs, eArgs)
			local commID = cArgs[1] or "**trp3e-effect: no commID**";
			ARC.PHASE:CAST(commID)
			eArgs.LAST = 0;
		end,
		editorData = {
			title = "Cast Phase ArcSpell",
			icon = prismaticGemIcon,
			-- icon = "inv_jewelcrafting_argusgemcut_purple_miscicons",
			description = "Cast an Arcanum Spell by CommID from the Phase Vault",
			effectFrameDecorator = function(scriptStepFrame, args)
				scriptStepFrame.description:SetText("Phase ArcSpell:|cff00ff00 " .. tostring(args[1]));
			end,
			getDefaultArgs = function()
				return { "commID" };
			end,
		},
	},
	arc_run_script = {
		editorFrame = function()
			if not TRP3_EffectEditorArcScript then
				local f = CreateFrame("Frame", "TRP3_EffectEditorArcScript", nil, "TRP3_EditorEffectTemplate")
				f:Hide()
				f:SetSize(650, 365)
				f.script = CreateFrame("Frame", nil, f, "TRP3_TextArea")
				f.script:SetPoint("TOP", 0, -60)
				f.script:SetPoint("BOTTOM", 0, 40)
				f.script:SetPoint("LEFT", 25, 0)
				f.script:SetPoint("RIGHT", -25, 0)
				function f.load(scriptData)
					local data = scriptData.args or {};
					f.script.scroll.text:SetText(data[1] or "");
				end

				function f.save(scriptData)
					scriptData.args[1] = emptyToNil(strtrim(f.script.scroll.text:GetText())) or "**trp3e-effect: no script given**";
				end
			end
			return TRP3_EffectEditorArcScript -- defined above, stop complaining intellisense ffs
		end,
		effectScript = function(structure, cArgs, eArgs)
			local script = cArgs[1] or "**trp3e-effect: no script given**";
			ns.Cmd.runMacroText(script)
			eArgs.LAST = 0;
		end,
		editorData = {
			title = "Run Insecure Script",
			icon = "inv_eng_gizmo3",
			description =
			"Run an Insecure Script. Calling secure functions, like /target or TargetUnit() here will fail, and probably totally break TRP3e - don't do it.",
			getDefaultArgs = function()
				return { "-- Your insecure script here" };
			end,
		},
	},
}

local function arc_trp3e_effects_init()
	local effectSubMenuCategory = "Arcanum"
	local effectsToAdd = {}
	for k, v in orderedPairs(arcEffects) do
		addArcTRP3eEffect(k, v.editorFrame, v.editorData, v.effectScript)
		tinsert(effectsToAdd, k)
	end

	-- replace getEffectOperandLocale with a custom one that always hotfixes our data in.
	local getEffectOperandLocale = TRP3_API.extended.tools.getEffectOperandLocale
	TRP3_API.extended.tools.getEffectOperandLocale = function(...)
		local effectMenu = getEffectOperandLocale(...)
		effectMenu[effectSubMenuCategory] = effectsToAdd
		tinsert(effectMenu.order, effectSubMenuCategory)
		return effectMenu
	end
	local effectMenu = TRP3_API.extended.tools.getEffectOperandLocale();

	--[[
	local effectMenu = TRP3_API.extended.tools.getEffectOperandLocale();
	if TRP3_ScriptEditorNormal.getCurrentMenuData then effectMenu = TRP3_ScriptEditorNormal.getCurrentMenuData() end -- custom edit to TRP3e that I've added a pull request for but can't be sure they do it.
	effectMenu["Arcanum"] = effectsToAdd
	tinsert(effectMenu.order, "Arcanum")
	--tinsert(effectMenu[TRP3_API.loc.MODE_EXPERT], "arc_cast")
	--]]

	--TRP3_API.extended.tools.initScript(TRP3_ToolFrame, effectMenu);
	TRP3_ScriptEditorNormal.init(TRP3_ToolFrame, effectMenu);
end
C_Timer.After(0, arc_trp3e_effects_init) -- // Delay until the next frame to avoid a bug where TRP3X_Tools is still finishing setup before we can hook
