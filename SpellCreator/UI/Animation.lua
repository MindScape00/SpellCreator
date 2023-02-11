---@class ns
local ns = select(2, ...)

local function hsvToRgb(h, s, v)
    local r, g, b

    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return r * 255, g * 255, b * 255
end

local function setRainbowVertex(frame, parentIfNeeded)
	frame.elapsed = 0
	frame.rainbowVertex = true
	local scriptFrame = parentIfNeeded or frame
	scriptFrame:HookScript("OnUpdate", function(self,elapsed)
		if frame.rainbowVertex then
			elapsed = elapsed/10
			frame.elapsed = frame.elapsed + elapsed
			if frame.elapsed > 1 then frame.elapsed = 0 end
			local r,g,b = hsvToRgb(frame.elapsed, 1, 1)
			frame:SetVertexColor(r/255, g/255, b/255)
		end
	end)
end

local function stopRainbowVertex(frame)
    frame.rainbowVertex = false
end

local function stopFrameFlicker(frame, endAlpha, optFadeTime)
	if not frame.flickerTimer then return end
	for i = 1, #frame.flickerTimer do
		frame.flickerTimer[i]:Cancel()
		frame.flickerTimer[i] = nil
	end
	if optFadeTime then
		UIFrameFadeOut(frame, optFadeTime, frame:GetAlpha(), endAlpha)
	else
		frame:SetAlpha(endAlpha or 1)
	end
end

local function setFrameFlicker(frame, iter, timeToFadeOut, timeToFadeIn, startAlpha, endAlpha, repeatnum)
	if not frame then return; end

	if not timeToFadeOut then timeToFadeOut = 0.1 end
	if not timeToFadeIn then timeToFadeIn = 0.5 end
	if not startAlpha then startAlpha = 1 end
	if not endAlpha then endAlpha = 0.33 end

	if repeatnum then
		if not frame.flickerTimer then frame.flickerTimer = {} end
		frame.flickerTimer[repeatnum] = C_Timer.NewTimer((fastrandom(10,30)/10), function()
			UIFrameFadeOut(frame,timeToFadeOut,startAlpha,endAlpha)
			frame.fadeInfo.finishedFunc = function() UIFrameFadeIn(frame,timeToFadeIn,endAlpha,startAlpha) end
			setFrameFlicker(frame, nil, timeToFadeOut, timeToFadeIn, startAlpha, endAlpha, repeatnum)
		end)
	else
		if frame.flickerTimer and next(frame.flickerTimer) then stopFrameFlicker(frame, startAlpha) end -- assume we're starting a new flicker and don't want the old one.
		if not iter then iter = 1 end
		for i = 1,iter do
			if not frame.flickerTimer then frame.flickerTimer = {} end
			if frame.flickerTimer[i] then frame.flickerTimer[i]:Cancel() end
			frame.flickerTimer[i] = C_Timer.NewTimer((fastrandom(10,30)/10), function()
				UIFrameFadeOut(frame,timeToFadeOut,startAlpha,endAlpha)
				frame.fadeInfo.finishedFunc = function() UIFrameFadeIn(frame,timeToFadeIn,endAlpha,startAlpha) end
				setFrameFlicker(frame, nil, timeToFadeOut, timeToFadeIn, startAlpha, endAlpha, i)
			end)
		end
	end
end

---@class UI_Animation
ns.UI.Animation = {
    setRainbowVertex = setRainbowVertex,
    stopRainbowVertex = stopRainbowVertex,
    setFrameFlicker = setFrameFlicker,
    stopFrameFlicker = stopFrameFlicker,
}
