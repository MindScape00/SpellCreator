---@class ns
local ns = select(2, ...)

local Cmd = ns.Cmd
local Execute = ns.Actions.Execute
local Logging = ns.Logging
local Permissions = ns.Permissions
local Vault = ns.Vault

local HTML = ns.Utils.HTML

local cmdWithDotCheck = Cmd.cmdWithDotCheck
local runMacroText = Cmd.runMacroText
local cprint, dprint, eprint = Logging.cprint, Logging.dprint, Logging.eprint
local executePhaseSpell = Execute.executePhaseSpell
local isDMEnabled = Permissions.isDMEnabled
local phaseVault = Vault.phase

local CloseGossip = CloseGossip or C_GossipInfo.CloseGossip;
local GetNumGossipOptions = GetNumGossipOptions or C_GossipInfo.GetNumOptions;
local SelectGossipOption = SelectGossipOption or C_GossipInfo.SelectOption;
local GetGossipText = GetGossipText or C_GossipInfo.GetText;

local modifiedGossips = {}
local isGossipLoaded

local spellsToCast = {}
local shouldAutoHide = false
local shouldLoadSpellVault = false
local loadPhaseVault
local lastGossipText
local currGossipText

local gossipScript
local gossipTags

local function gossipReloadCheck()
	return isGossipLoaded and lastGossipText and lastGossipText == currGossipText
end

---@return string
local function getGreetingText()
	if ImmersionFrame and ImmersionFrame.TalkBox and ImmersionFrame.TalkBox.TextFrame then
		return ImmersionFrame.TalkBox.TextFrame.Text.storedText
	end
	return GossipGreetingText:GetText()
end

---@param text string
local function setGreetingText(text)
	if ImmersionFrame and ImmersionFrame.TalkBox and ImmersionFrame.TalkBox.TextFrame then
		ImmersionFrame.TalkBox.TextFrame.Text.storedText = text
		ImmersionFrame.TalkBox.TextFrame.Text:RepeatTexts() -- this triggers Immersion to restart the text, pulling from its storedText, which we already cleaned.
	else
		GossipGreetingText:SetText(text)
	end
end

---@param index integer
---@return Button
local function getTitleButton(index)
	local titleButton = _G["GossipTitleButton" .. index]
	if ImmersionFrame then
		local immersionButton = _G["ImmersionTitleButton" .. index]
		if immersionButton then
			titleButton = immersionButton
		end
	end

	return titleButton
end

local function setGreeting()
	local gossipGreetPayload = nil
	local gossipGreetingText = getGreetingText()

	while gossipGreetingText and gossipGreetingText:match(gossipTags.default) do -- while gossipGreetingText has an arcTag - this allows multiple tags - For Immersion, we need to split our filters between the whole text, and the displayed text
		shouldLoadSpellVault = true
		gossipGreetPayload = gossipGreetingText:match(gossipTags.capture) -- capture the tag
		local strTag, strArg = strsplit(":", gossipGreetPayload, 2) -- split the tag from the data
		local mainTag, extTags = strsplit("_", strTag, 2) -- split the main tag from the extension tags

		if gossipReloadCheck() then
			dprint("Gossip Reload of the Same Page detected. Skipping Auto Functions.")
		else
			if isDMEnabled() then
				cprint("DM Enabled - Skipping Auto Function (" .. gossipGreetPayload .. ")")
			else
				if gossipTags.body[mainTag] then -- Checking Main Tags & Running their code if present
					gossipTags.body[mainTag].script(strArg)
				end
				if extTags then
					for _, v in ipairs(gossipTags.extensions) do -- Checking for any tag extensions
						if extTags:match(v.ext) then v.script() end
					end
				end
			end
		end


		if isDMEnabled() then -- Updating GossipGreetingText
			gossipGreetingText = gossipGreetingText:gsub(gossipTags.default, gossipTags.dm .. gossipGreetPayload .. ">", 1)
		else
			gossipGreetingText = gossipGreetingText:gsub(gossipTags.default, "", 1)
		end


		dprint("Saw a gossip greeting | Tag: " .. mainTag .. " | Spell: " .. (strArg or "none") .. " | Ext: " .. (tostring(extTags) or "none"))
	end

	setGreetingText(gossipGreetingText)
end

local function hookTitleButtons()
	dprint("Hooking Gossip TitleButtons...")
	local gossipOptionPayload = nil
	local needToHookLateForImmersion = false

	for i = 1, GetNumGossipOptions() do
		--[[	-- Replaced with a memory of modifiedGossips that we reset when gossip is closed instead.
		_G["GossipTitleButton" .. i]:SetScript("OnClick", function()
			SelectGossipOption(i)
		end)
		--]]
		local titleButton = getTitleButton(i)
		local titleButtonText = titleButton:GetText()

		while titleButtonText and titleButtonText:match(gossipTags.default) do
			shouldLoadSpellVault = true
			gossipOptionPayload = titleButtonText:match(gossipTags.capture) -- capture the tag
			local strTag, strArg = strsplit(":", gossipOptionPayload, 2) -- split the tag from the data
			local mainTag, extTags = strsplit("_", strTag, 2) -- split the main tag from the extension tags

			if gossipTags.option[mainTag] then -- Checking Main Tags & Running their code if present

				local function _newOnClickHook()
					gossipTags.option[mainTag].script(strArg)
					dprint("Hooked gossip clicked for <" .. mainTag .. ":" .. (strArg or "") .. ">")
				end

				if extTags then
					if extTags:match("auto") then -- legacy auto support - hard coded to avoid breaking gossipText
						if isDMEnabled() then
							cprint("Legacy Auto Gossip Option skipped due to DM Mode On.")
						else
							if mainTag == "cast" then
								dprint("Running Legacy Auto-Cast..")
								gossipScript.auto_cast(strArg)
							else
								dprint("Running Legacy Auto Tag Support.. This may not work.")
								gossipTags.option[mainTag].script(strArg)
							end
						end
					end
					if extTags == "auto_hide" then shouldAutoHide = true end -- legacy auto with hide support
					for k, v in ipairs(gossipTags.extensions) do -- Checking for any tag extensions
						if extTags:match(v.ext) then
							local _origNewOnClickHook = _newOnClickHook
							function _newOnClickHook(self, button)
								_origNewOnClickHook()
								v.script(strArg or button)
							end
						end
					end
				end

				if ImmersionFrame then
					if not titleButton.isHookedByArc then
						titleButton:HookScript("OnClick", _newOnClickHook)
						needToHookLateForImmersion = true
					end
				else
					titleButton:HookScript("OnClick", _newOnClickHook)
					titleButton.isHookedByArc = true
				end

				modifiedGossips[i] = titleButton
			end


			if isDMEnabled() then -- Update the text
				-- Is DM and Officer+
				titleButton:SetText(titleButtonText:gsub(gossipTags.default, gossipTags.dm .. gossipOptionPayload .. ">", 1));
			else
				-- Is not DM or Officer+
				titleButton:SetText(titleButtonText:gsub(gossipTags.default, "", 1));
			end

			titleButtonText = titleButton:GetText();
			dprint("Saw an option tag | Tag: " ..
				mainTag .. " | Spell: " .. (strArg or "none") .. " | Ext: " .. (tostring(extTags) or "none"))
		end

		if needToHookLateForImmersion then
			titleButton.isHookedByArc = true
		end
		GossipResize(titleButton) -- Fix the size if the gossip option changed number of lines.

	end
end

local function onGossipShow()
	spellsToCast = {} -- make sure our variables are reset before we start processing
	shouldAutoHide = false
	shouldLoadSpellVault = false
	currGossipText = GetGossipText();

	setGreeting()
	hookTitleButtons()

	if shouldLoadSpellVault and not isGossipLoaded then
		local castTheSpells = function()
			if next(spellsToCast) == nil then
				dprint("No Auto Cast Spells in Gossip")
				return
			end

			for _, j in pairs(spellsToCast) do
				executePhaseSpell(j)
			end

			spellsToCast = {} -- empty the table.
		end

		if phaseVault.isLoaded then
			castTheSpells()
		else
			loadPhaseVault(castTheSpells)
		end
	end

	isGossipLoaded = true
	lastGossipText = currGossipText

	-- Final check if we toggled shouldAutoHide and close gossip if so.
	if shouldAutoHide and not isDMEnabled() then
		CloseGossip()
	end
end

local function onGossipClosed()
	for k, v in pairs(modifiedGossips) do
		v:SetScript("OnClick", function()
			SelectGossipOption(k)
		end)
		v.isHookedByArc = nil
		modifiedGossips[k] = nil
	end

	isGossipLoaded = false
end

local function isLoaded()
	return isGossipLoaded
end

---@param callbacks { openArcanum: fun(), saveToPersonal: fun(phaseVaultIndex: integer, sendLearnedMessage: boolean), loadPhaseVault: fun(callback: fun()) }
local function init(callbacks)
	loadPhaseVault = callbacks.loadPhaseVault

	gossipScript = {
		show = callbacks.openArcanum,
		auto_cast = function(payLoad)
			table.insert(spellsToCast, payLoad)
			dprint("Adding AutoCast from Gossip: '" .. payLoad .. "'.")
		end,
		click_cast = function(payLoad)
			if phaseVault.isSavingOrLoadingAddonData then
				eprint("Phase Vault was still loading. Casting when loaded..!")
				table.insert(spellsToCast, payLoad)
				return
			end
			executePhaseSpell(payLoad)
		end,
		save = function(payLoad)
			if phaseVault.isSavingOrLoadingAddonData then eprint("Phase Vault was still loading. Please try again in a moment."); return; end
			dprint("Scanning Phase Vault for Spell to Save: " .. payLoad)

			local index = Vault.phase.findSpellIndexByID(payLoad)
			if index ~= nil then
				dprint("Found & Saving Spell '" .. payLoad .. "' (" .. index .. ") to your Personal Vault.")
				callbacks.saveToPersonal(index, true)
			end
		end,
		copy = function(payLoad)
			HTML.copyLink(nil, payLoad)
		end,
		cmd = function(payLoad)
			cmdWithDotCheck(payLoad)
		end,
		hide_check = function(button)
			if button then -- came from an OnClick, so we need to close now, instead of toggling AutoHide which already past.
				CloseGossip();
			else
				shouldAutoHide = true
			end
		end,
	}

	gossipTags = {
		default = "<arc[anum]-_.->",
		capture = "<arc[anum]-_(.-)>",
		dm = "<arc-DM :: ",
		body = { -- tag is pointless, I changed it to tags are the table key, but kept for readability
			show = { tag = "show", script = gossipScript.show },
			cast = { tag = "cast", script = gossipScript.auto_cast },
			save = { tag = "save", script = gossipScript.save },
			cmd = { tag = "cmd", script = gossipScript.cmd },
			macro = { tag = "macro", script = runMacroText },
			copy = { tag = "copy", script = gossipScript.copy },
		},
		option = {
			show = { tag = "show", script = gossipScript.show },
			toggle = { tag = "toggle", script = gossipScript.show }, -- kept for back-compatibility, but undocumented. They should use Show now.
			cast = { tag = "cast", script = gossipScript.click_cast },
			save = { tag = "save", script = gossipScript.save },
			cmd = { tag = "cmd", script = gossipScript.cmd },
			macro = { tag = "macro", script = runMacroText },
			copy = { tag = "copy", script = gossipScript.copy },
		},
		extensions = {
			{ ext = "hide", script = gossipScript.hide_check },
			-- auto is also a legacy tag, defined below. They shouldn't really use it but it's still useful for making gob tele's with auto.
		},
	}
end

ns.Gossip = {
	init = init,
	onGossipShow = onGossipShow,
	onGossipClosed = onGossipClosed,
	isLoaded = isLoaded,
}
