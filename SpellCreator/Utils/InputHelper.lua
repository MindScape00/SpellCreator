---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local Utils = ns.Utils

------------------------------------------
-- Input Definitions

---@class InputChoiceKV<K, Display>: { [K]: Display}

---@class InputData
---@field name string
---@field type type
---@field choices? (string|InputChoiceKV)[]

---@alias InputsContainer InputData[]

------------------------------------------
-- Create an InputData table

---@param name string
---@param vType type|"unit"
---@param ... string|InputChoiceKV
---@return InputData
local function input(name, vType, ...)
	local isOptional
	if type(vType) == "string" and strfind(vType, "?") then
		isOptional = true
		vType = vType:gsub("?", "")
	end

	local data = {
		name = name,
		type = vType,
		optional = isOptional,
	}
	if ... then
		data.choices = { ... }
	end
	return data
end

------------------------------------------
-- Tooltips

local inputTypeTooltipRemaps = {
	boolean = "true|false",
	unit = "target|player"
}

---@param inputs any
---@param inputDesc any
---@param inputExample string
---@return function
local function generateInputsTooltip(inputs, inputDesc, inputExample)
	return function()
		local strings
		if inputDesc then strings = { inputDesc, " " } else strings = {} end
		table.insert(strings, "Inputs:")
		local numInputs = #inputs
		for k, v in ipairs(inputs) do
			local vType = v.type --[[@as string]]
			local isOptional = v.optional

			local inputType
			if v.choices then
				inputType = "  - " .. v.name .. (k ~= numInputs and "," or "") .. string.char(31)
				local numTypes = #v.choices
				for _ind, _opt in ipairs(v.choices) do
					if type(_opt) == "table" then _opt = _opt[1] end
					inputType = inputType .. Constants.ADDON_COLORS.TOOLTIP_NOREVERT:WrapTextInColorCode(_opt .. (_ind ~= numTypes and ", " or ""))
					if _ind % 5 == 0 then
						tinsert(strings, inputType)
						inputType = " " .. string.char(31)
					end
				end
				if #inputType > 2 then
					tinsert(strings, inputType)
				end
			else
				local inputTypeText
				local inputTypeOrig, inputTypeOverride = vType:match("(.*)<(.*)>")
				if inputTypeTooltipRemaps[vType] then
					inputTypeText = inputTypeTooltipRemaps[vType]
				elseif inputTypeOverride then
					inputTypeText = inputTypeOverride
				else
					inputTypeText = (vType)
				end

				if isOptional then inputTypeText = "Optional: " .. inputTypeText end -- Prepend Optional Tag

				local string = "  - " ..
					v.name ..
					(k ~= numInputs and "," or "") ..
					string.char(31) .. (Constants.ADDON_COLORS.TOOLTIP_NOREVERT:WrapTextInColorCode(inputTypeText))
				tinsert(strings, string)
			end
		end

		tinsert(strings, " ")
		if inputExample then
			if inputExample:find("<.*>") then
				-- convert < > to contrast text
				inputExample = inputExample:gsub("<(.-)>", Utils.Tooltip.genContrastText("%1"))
			end
			tinsert(strings, Utils.Tooltip.genTooltipText("example", inputExample))
		end
		tinsert(strings, Constants.ADDON_COLORS.TOOLTIP_NOREVERT:WrapTextInColorCode("All inputs on one line, separated by commas. Wrap in \" \" if you need a comma inside an input."))
		return strings
	end
end

---@class Utils_InputHelper
ns.Utils.InputHelper = {
	genTooltip = generateInputsTooltip,
	input = input,
}
