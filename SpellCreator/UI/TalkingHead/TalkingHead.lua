---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

-------------------------------------------------------------------------------
--
-- Talking head frame for dynamic dialogue.
--

local talkingHeadFontColor = {
	["Horde"] = { Name = CreateColor(0.28, 0.02, 0.02), Text = CreateColor(0.0, 0.0, 0.0), Shadow = CreateColor(0.0, 0.0, 0.0, 0.0) },
	["Alliance"] = { Name = CreateColor(0.02, 0.17, 0.33), Text = CreateColor(0.0, 0.0, 0.0), Shadow = CreateColor(0.0, 0.0, 0.0, 0.0) },
	["Neutral"] = { Name = CreateColor(0.33, 0.16, 0.02), Text = CreateColor(0.0, 0.0, 0.0), Shadow = CreateColor(0.0, 0.0, 0.0, 0.0) },
	["Normal"] = { Name = CreateColor(1, 0.82, 0.02), Text = CreateColor(1, 1, 1), Shadow = CreateColor(0.0, 0.0, 0.0, 1.0) },
	["Epsilon"] = { Name = CreateColor(0.894117647, 0.725490196, 0.0156862745), Text = CreateColor(1, 1, 1), Shadow = CreateColor(0.0, 0.0, 0.0, 1.0) },
}

local talkingHeadChatTypes = {
	["SAY"] = { Prefix = "|cFFE6E68E", Verbage = " says: " },
	["EMOTE"] = { Prefix = "|cFFFF7E40", Verbage = "" },
	["YELL"] = { Prefix = "|cFFFF3F40", Verbage = " whispers: " },
	["WHISPER"] = { Prefix = "|cFFFF7EFF", Verbage = " whispers: " },
}

function SCForgeTalkingHeadFrame_OnLoad(self)
	self:SetClampedToScreen(true)
	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	self:SetUserPlaced(true)
	self:RegisterForClicks("RightButtonUp");

	self.NameFrame.Name:SetPoint("TOPLEFT", self.PortraitFrame.Portrait, "TOPRIGHT", 2, -19);
	self.TextFrame.Text:SetFontObjectsToTry(SystemFont_Shadow_Large, SystemFont_Shadow_Med2, SystemFont_Shadow_Med1);

	self.TextFrame.Text:SetShadowColor(0, 0, 0, 0)

	local alertSystem = AlertFrame:AddExternallyAnchoredSubSystem(self);
	AlertFrame:SetSubSystemAnchorPriority(alertSystem, 0);
end

function SCForgeTalkingHeadFrame_OnShow(self)
	UIParent_ManageFramePositions();
end

function SCForgeTalkingHeadFrame_OnHide(self)
	UIParent_ManageFramePositions();
end

function SCForgeTalkingHeadFrame_CloseImmediately()
	local frame = SCForgeTalkingHeadFrame;
	if (frame.finishTimer) then
		frame.finishTimer:Cancel()
		frame.finishTimer = nil;
	end
	if (frame.closeTimer) then
		frame.closeTimer:Cancel()
		frame.closeTimer = nil;
	end
	frame.NameFrame.Fadein:Finish()
	frame.NameFrame.Fadeout:Finish()
	frame.NameFrame.Close:Finish()
	frame.TextFrame.Fadein:Finish()
	frame.TextFrame.Fadeout:Finish()
	frame.TextFrame.Close:Finish()
	frame.BackgroundFrame.Fadein:Finish()
	frame.BackgroundFrame.Close:Finish()
	frame.PortraitFrame.Fadein:Finish()
	frame.PortraitFrame.Close:Finish()
	frame.MainFrame.TalkingHeadsInAnim:Finish()
	frame.MainFrame.Close:Finish();
	frame:Hide();
end

function SCForgeTalkingHeadFrame_OnClick(self, button)
	if (button == "RightButton") then
		SCForgeTalkingHeadFrame_CloseImmediately();
		return true;
	end

	return false;
end

function SCForgeTalkingHeadFrame_FadeinFrames()
	local frame = SCForgeTalkingHeadFrame
	frame.MainFrame.TalkingHeadsInAnim:Play();
	C_Timer.After(0.5, function()
		frame.NameFrame.Fadein:Play();
	end);
	C_Timer.After(0.75, function()
		frame.TextFrame.Fadein:Play();
	end);
	frame.BackgroundFrame.Fadein:Play();
	frame.PortraitFrame.Fadein:Play();
end

function SCForgeTalkingHeadFrame_FadeoutFrames()
	local frame = SCForgeTalkingHeadFrame
	frame.MainFrame.Close:Play();
	frame.NameFrame.Close:Play();
	frame.TextFrame.Close:Play();
	frame.BackgroundFrame.Close:Play();
	frame.PortraitFrame.Close:Play();
end

function SCForgeTalkingHeadFrame_Reset(frame, text, name)
	-- set alpha for all animating textures
	frame:StopAnimating();
	frame.BackgroundFrame.TextBackground:SetAlpha(0.01);
	frame.NameFrame.Name:SetAlpha(0.01);
	frame.TextFrame.Text:SetAlpha(0.01);
	frame.MainFrame.Sheen:SetAlpha(0.01);
	frame.MainFrame.TextSheen:SetAlpha(0.01);

	frame.MainFrame.Model:SetAlpha(0.01);
	frame.MainFrame.Model.PortraitBg:SetAlpha(0.01);
	frame.PortraitFrame.Portrait:SetAlpha(0.01);
	frame.MainFrame.Overlay.Glow_LeftBar:SetAlpha(0.01);
	frame.MainFrame.Overlay.Glow_RightBar:SetAlpha(0.01);
	frame.MainFrame.CloseButton:SetAlpha(0.01);

	frame.MainFrame:SetAlpha(1);
	frame.NameFrame.Name:SetText(name);
	frame.TextFrame.Text:SetText(text);
end

function SCForgeTalkingHeadFrame_SetUnit(displayID, name, textureKit, message, sound, chatType, timeout)
	local frame = SCForgeTalkingHeadFrame;

	textureKit = strlower(textureKit):gsub("^%l", string.upper) -- convert to Proper case
	chatType = strupper(chatType)                            -- always all caps

	if not talkingHeadFontColor[textureKit] then textureKit = "Normal" end
	if not talkingHeadChatTypes[chatType] and not (chatType == "NONE") then chatType = "SAY" end

	-- A Talking Head is playing, so add this one to the queue.
	-- We'll try again after this one finishes up.
	if frame:IsShown() then
		if not frame.Queue then
			frame.Queue = {}
		end

		local queuedFrame = {
			displayID = displayID,
			name = name,
			textureKit = textureKit,
			message = message,
			sound = sound,
			chatType = chatType,
			timeout = timeout,
		}
		tinsert(frame.Queue, queuedFrame)
		return;
	end

	local model = frame.MainFrame.Model;
	model.PortraitImage:Hide()

	if type(displayID) == "number" then
		model:SetDisplayInfo(displayID)
		model:SetPortraitZoom(1)
	elseif type(displayID) == "string" then
		model:SetDisplayInfo(1)
		model.PortraitImage:Show()
		model.PortraitImage:SetTexture(displayID)
	end
	frame.soundKitID = sound or nil;
	frame.NameFrame.Name:SetText(name or "Unknown")

	if textureKit == "Epsilon" then
		frame.BackgroundFrame.TextBackground:SetSize(570, 155);
		frame.BackgroundFrame.TextBackground:SetTexture(Constants.ASSETS_PATH .. "/TalkingHeads");
		frame.BackgroundFrame.TextBackground:SetTexCoord(0.000976562, 0.557617, 0.000976562, 0.152344);
		frame.PortraitFrame.Portrait:SetSize(143, 143);
		frame.PortraitFrame.Portrait:SetTexture(Constants.ASSETS_PATH .. "/TalkingHeads");
		frame.PortraitFrame.Portrait:SetTexCoord(0.55957, 0.699219, 0.000976562, 0.140625);
	else
		frame.BackgroundFrame.TextBackground:SetTexture("Interface/QUESTFRAME/TalkingHeads");
		frame.BackgroundFrame.TextBackground:SetTexCoord(0, 1, 0, 1);
		frame.PortraitFrame.Portrait:SetTexture("Interface/QUESTFRAME/TalkingHeads");
		frame.PortraitFrame.Portrait:SetTexCoord(0, 1, 0, 1);
		if textureKit == "Normal" then
			frame.BackgroundFrame.TextBackground:SetAtlas("TalkingHeads-TextBackground")
			frame.PortraitFrame.Portrait:SetAtlas("TalkingHeads-PortraitFrame")
		else
			frame.BackgroundFrame.TextBackground:SetAtlas("TalkingHeads-" .. textureKit .. "-TextBackground")
			frame.PortraitFrame.Portrait:SetAtlas("TalkingHeads-" .. textureKit .. "-PortraitFrame")
		end
	end

	local nameColor = talkingHeadFontColor[textureKit].Name;
	local textColor = talkingHeadFontColor[textureKit].Text;
	local shadowColor = talkingHeadFontColor[textureKit].Shadow;
	frame.NameFrame.Name:SetTextColor(nameColor:GetRGB());
	frame.NameFrame.Name:SetShadowColor(shadowColor:GetRGBA());
	frame.TextFrame.Text:SetTextColor(textColor:GetRGB());
	frame.TextFrame.Text:SetShadowColor(shadowColor:GetRGBA());

	SCForgeTalkingHeadFrame_PlayCurrent(message, chatType, timeout)
end

function SCForgeTalkingHeadFrame_PlayCurrent(message, chatType, timeout)
	local frame = SCForgeTalkingHeadFrame;
	local model = frame.MainFrame.Model;
	model.sequence = nil;
	SCForgeTalkingHeadFrame.animations = {};
	local animIndex = { ["."] = 60, ["!"] = 64, ["?"] = 65 }

	message:gsub("%p", function(c) table.insert(SCForgeTalkingHeadFrame.animations, animIndex[c]) end)

	if chatType ~= "NONE" then
		print(talkingHeadChatTypes[chatType].Prefix .. (frame.NameFrame.Name:GetText() or "Unknown") .. talkingHeadChatTypes[chatType].Verbage .. message);
	end

	frame:Show();

	if not SCForgeTalkingHeadFrame.animations[1] or model:HasAnimation(SCForgeTalkingHeadFrame.animations[1]) == false then SCForgeTalkingHeadFrame.animations[1] = 60 end;
	model:SetAnimation(SCForgeTalkingHeadFrame.animations[1])
	frame.TextFrame.Text:SetText(message)

	if SCForgeTalkingHeadFrame.soundKitID then
		PlaySound(SCForgeTalkingHeadFrame.soundKitID, "Dialog")
	end

	SCForgeTalkingHeadFrame_FadeinFrames()

	-- If player does not specify timeout,
	-- calculate one based on # of text lines
	local stringHeight = frame.TextFrame.Text:GetStringHeight() / 16
	if not (timeout) then
		timeout = 5 + (2 * stringHeight);
	end

	frame.finishTimer = C_Timer.After(timeout, function()
		model:SetAnimation(0)
		SCForgeTalkingHeadFrame_FadeoutFrames()
		frame.finishTimer = nil;
	end
	);
	frame.closeTimer = C_Timer.After(timeout + 1, function()
		SCForgeTalkingHeadFrame:Hide();
		frame.closeTimer = nil;

		if frame.Queue and #frame.Queue >= 1 then
			-- We still have more Talking Heads to show.
			local displayID = frame.Queue[1].displayID;
			local name = frame.Queue[1].name;
			local textureKit = frame.Queue[1].textureKit;
			local message = frame.Queue[1].message;
			local sound = frame.Queue[1].sound;
			local chatType = frame.Queue[1].chatType

			SCForgeTalkingHeadFrame_SetUnit(displayID, name, textureKit, message, sound, chatType)
			tremove(frame.Queue, 1)
		end
	end
	);
end

---@class UI_TalkingHead_TalkingHead
ns.UI.TalkingHead.TalkingHead = {

}
