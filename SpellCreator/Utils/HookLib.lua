---@class ns
local ns = select(2, ...)

---@class HookLib
local HookLib = {}

---worker frame
local f = CreateFrame("Frame")

--*--*--*--*--*--*--*--*--
--#region Hooked Frame Methods
--*--*--*--*--*--*--*--*--

---@class HookData
---@field func function
---@field unhook? boolean

---@type table<Frame, table<ScriptType, HookData[]>>
local hookedFrames = {}

---Internal function to safely manage the hooks tables
---@param object Frame
---@param method ScriptFrame
---@param callback function
---@param unhookWhenDone? boolean
---@return string|false success
local function safeAddFrameHook(object, method, callback, unhookWhenDone)
	if not object or not method or (type(callback) ~= "function") then return false end
	if method == "OnEvent" then return error("HookFrameScript() cannot hook OnEvent, use HookEvent()") end --hard exclude OnEvent - why? they might have a usage if they want to hide the frame and only listen when it's shown instead of always? MEH..

	if not hookedFrames[object] then hookedFrames[object] = {} end
	if not hookedFrames[object][method] then
		-- this method was not hooked yet, define the table, then hook the method
		hookedFrames[object][method] = {}
		object:HookScript(method, function(self, ...)
			local unhooks = {}
			local hooks = hookedFrames[self][method]
			--ns.Utils.Debug.ddump(hooks)

			--handle running hooked scripts
			for i = 1, #hooks do
				local hook = hooks[i]
				local hookCallback = hook.func
				if hookCallback then hookCallback(self, ...) else print("HookLib Error: Index (", i, ") Callback:", hookCallback, " | Did Not Exist") end
				if hook.unhook then
					tinsert(unhooks, hook.func)
				end
			end

			--handle unhooks if the script is a single use
			local numUnhooks = #unhooks
			if numUnhooks > 0 then
				for i = 1, numUnhooks do
					local funcToUnhook = unhooks[i]
					HookLib.UnhookFrameScript(object, method, funcToUnhook)
				end
			end
		end)
	end

	local callbackData = { func = callback, unhook = unhookWhenDone }

	tinsert(hookedFrames[object][method], callbackData)
	return tostring(callback)
end

---Hook a Frame Script that can be removed later
---@param object Frame
---@param method ScriptFrame
---@param callback function
---@return string|false success if the hook succeeded, return the function reference string, if not, return false
function HookLib.HookFrameScript(object, method, callback)
	if not object or not method or not callback then return error("Usage: HookFrameScript(object, method, callback)") end
	return safeAddFrameHook(object, method, callback)
end

---Hook a Frame Script that is then removed after the first run
---@param object Frame
---@param method ScriptFrame
---@param callback function
---@return string|false success if the hook succeeded, return the function reference string, if not, return false
function HookLib.HookFrameScriptOneShot(object, method, callback)
	if not object or not method or not callback then return error("Usage: HookFrameScript(object, method, callback)") end
	return safeAddFrameHook(object, method, callback, true)
end

---@param object Frame
---@param method ScriptType
---@param hookData HookData
---@return boolean success
local function safeRemoveFrameHook(object, method, hookData)
	if not object or not method then return false end
	if type(hookData) ~= "table" then return false end

	tDeleteItem(hookedFrames[object][method], hookData)
	return true
end

---Unhooks a specific callback on a frame script by it's handler.
---@param object Frame
---@param method ScriptType
---@param callback string|function
---@return boolean success if the event was successfully unhooked
function HookLib.UnhookFrameScript(object, method, callback)
	-- convert a func ref string to a callback registered in the table
	if not object or not method or not callback then return error("Usage: UnhookFrameScript(object, method, callback)") end

	local hookDataToUnhook
	local hooks = hookedFrames[object][method]
	if hooks then
		for i = 1, #hooks do
			local hookData = hooks[i]
			local hookCallback = hookData.func
			if (hookCallback == callback) or (tostring(hookCallback) == callback) then -- this function matches our reference, use it and break the loop
				hookDataToUnhook = hookData
				break
			end
		end
	end
	return safeRemoveFrameHook(object, method, hookDataToUnhook)
end

--*--*--*--*--*--*--*--*--
--#endregion
--#region Pre-Hooked Function Hooks
--*--*--*--*--*--*--*--*--

local hookedFuncs = {}

--*--*--*--*--*--*--*--*--
--#endregion
--#region Secure Function Hooks
--*--*--*--*--*--*--*--*--

---@type table<function, function[]>
local hookedSecureFuncs = {}


--*--*--*--*--*--*--*--*--
--#endregion
--#region Event Hooks
--*--*--*--*--*--*--*--*--

---@type table<WowEvent, function[]>
local hookedEvents = {}

---setup OnEvent handler
f:HookScript("OnEvent", function(self, event, ...)
	local hooks = hookedEvents[event]
	if hooks then
		for i = 1, #hooks do
			local hook = hooks[i]
			hook(nil, event, ...) -- do not give access to the f frame, it's private
		end
	end
end)

---Internal function to safely manage the hooks tables
---@param event string
---@param callback function
---@return string|false success
local function safeAddEventHook(event, callback)
	if not event or (type(callback) ~= "function") then return false end
	if not hookedEvents[event] then hookedEvents[event] = {} end
	tinsert(hookedEvents[event], callback)
	return tostring(callback)
end

---Hook An Event that can be removed later
---@param event string
---@param callback function
---@return string|false success if the hook succeeded, return the function reference string, if not, return false
function HookLib.HookEvent(event, callback)
	f:RegisterEvent(event)
	return safeAddEventHook(event, callback)
end

---@param event string
---@param callback function
---@return boolean success
local function safeRemoveEventHook(event, callback)
	if type(callback) ~= "function" then return false end
	tDeleteItem(hookedEvents[event], callback)
	if not next(hookedEvents[event]) then -- no more hooks, unregister
		f:UnregisterEvent(event)
	end
	return true
end

---Unhooks a specific callback by it's handler.
---@param event string
---@param callback string|function
---@return boolean success if the event was successfully unhooked
function HookLib.UnhookEvent(event, callback)
	-- convert a func ref string to a callback registered in the table
	if type(callback) == "string" then
		local hooks = hookedEvents[event]
		if hooks then
			for i = 1, #hooks do
				local hook = hooks[i]
				if tostring(hook) == callback then -- this function matches our reference, use it
					callback = hook
				end
			end
		end
	end
	return safeRemoveEventHook(event, callback --[[@as function]])
end

--*--*--*--*--*--*--*--*--
--#endregion
--*--*--*--*--*--*--*--*--

---@class Utils_Hooks: HookLib
ns.Utils.Hooks = HookLib
