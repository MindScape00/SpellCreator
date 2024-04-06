-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard -- Borrowed with permission from Skylar. Thank you Skylar!!
-------------------------------------------------------------------------------

--
-- Icon picker interface.
--

---@class ns
local ns = select(2, ...)

local NineSlice = ns.Utils.NineSlice

local Attic = ns.UI.MainFrame.Attic
local Icons = ns.UI.Icons

---@class UI_IconPicker
ns.UI.IconPicker = {}
---@class UI_IconPicker
local IconPicker = ns.UI.IconPicker
SCForgeIconFuncs = ns.UI.IconPicker

local startOffset = 0
local filteredList = nil

-------------------------------------------------------------------------------
-- When one of the icon buttons are clicked.
--
function IconPicker.IconPickerButton_OnClick(self)
	-- Apply the icon and close the picker.
	SCForgeMainFrame.IconButton:SelectTex(self.realTex)
	Attic.markEditorUnsaved()
	PlaySound(114990)
	IconPicker.IconPicker_Close()
end

-------------------------------------------------------------------------------
-- OnEnter handler, to magnify the icon and show the texture path.
--
function IconPicker.IconPickerButton_ShowTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

	local texture = self:GetNormalTexture():GetTexture()
	GameTooltip:AddLine("|T" .. texture .. ":64|t", 1, 1, 1, true)
	GameTooltip:AddLine(texture, 1, 0.81, 0, true)
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- OnLoad moved here from XML so we can use our ns.
--
function IconPicker.IconPicker_OnLoad(self)
	-- self.portrait:SetTexture("Interface/AddOns/DiceMaster/Texture/logo")
	ButtonFrameTemplate_HidePortrait(self)
	NineSlice.ApplyLayoutByName(self.NineSlice, "ArcanumFrameTemplateNoPortrait")
	self.TitleText:SetText("Icons")

	self:SetClampedToScreen(true)
	self:RegisterForDrag("LeftButton")
	ButtonFrameTemplate_HideAttic(self)

	-- create icon map
	self.icons = {}
	for y = 0, 7 do
		for x = 0, 6 do
			local btn = CreateFrame("Button", nil, self.selectorFrame, "SpellCreatorIconPickerButton")
			btn:SetPoint("TOPLEFT", "SpellCreatorIconPickerInset", 32 * x + 5, -32 * y - 5)
			btn:SetSize(32, 32)

			table.insert(self.icons, btn)
			btn.pickerIndex = #self.icons
			btn.realTex = nil
		end
	end

	SCForgeMainFrame:HookScript("OnHide", IconPicker.IconPicker_Close)
end

-------------------------------------------------------------------------------
-- When the mousewheel is used on the icon map.
--
function IconPicker.IconPicker_MouseScroll(delta)
	local a = SpellCreatorIconPicker.selectorFrame.scroller:GetValue() - delta
	-- todo: do we need to clamp?
	SpellCreatorIconPicker.selectorFrame.scroller:SetValue(a)
end

-------------------------------------------------------------------------------
-- When the scrollbar's value is changed.
--
function IconPicker.IconPicker_ScrollChanged(value)
	-- Our "step" is 6 icons, which is one line.
	startOffset = math.floor(value) * 7
	IconPicker.IconPicker_RefreshGrid()
end

-------------------------------------------------------------------------------
-- Set the textures of the icon grid from the icons in the list at the
-- current offset.
--
function IconPicker.IconPicker_RefreshGrid()
	local list = filteredList or Icons.iconList
	for k, v in ipairs(SpellCreatorIconPicker.icons) do
		local tex = list[startOffset + k]
		if tex then
			local texName = tex
			v:Show()
			if tex:find("Interface/") then
				tex = tex
			elseif tex:find("AddOns/") then
				tex = "Interface/" .. tex
			else
				tex = "Interface/Icons/" .. tex
			end

			v:SetNormalTexture(tex)
			v.realTex = Icons.getIconTextureFromName(texName)
		else
			v:Hide()
		end
	end
end

-------------------------------------------------------------------------------
-- Called when the user types into the search box.
--
function IconPicker.IconPicker_FilterChanged()
	local filter = SpellCreatorIconPicker.search:GetText():lower()
	if #filter < 3 then
		-- Ignore filters less than three characters
		if filteredList then
			filteredList = nil
			IconPicker.IconPicker_RefreshScroll()
			IconPicker.IconPicker_RefreshGrid()
		end
	else
		-- build new list
		filteredList = {}
		for k, v in ipairs(Icons.iconList) do
			if v:lower():find(filter) then
				table.insert(filteredList, v)
			end
		end
		IconPicker.IconPicker_RefreshScroll()
	end
end

-------------------------------------------------------------------------------
-- When we change the size of the list, update the scroll bar range.
--
-- @param reset Reset the scroll bar to the beginning.
--
function IconPicker.IconPicker_RefreshScroll(reset)
	local list = filteredList or Icons.iconList
	local max = math.floor((#list - 42) / 7)
	if max < 0 then max = 0 end
	SpellCreatorIconPicker.selectorFrame.scroller:SetMinMaxValues(0, max)

	if reset then
		SpellCreatorIconPicker.selectorFrame.scroller:SetValue(0)
	end
	-- todo: does scroller auto clamp value?

	IconPicker.IconPicker_ScrollChanged(SpellCreatorIconPicker.selectorFrame.scroller:GetValue())
end

-------------------------------------------------------------------------------
-- Close the icon picker window. Use this instead of a direct Hide()
--
function IconPicker.IconPicker_Close()
	-- unhighlight the traitIcon button.
	SCForgeMainFrame.IconButton:SetSelected(false)
	SpellCreatorIconPicker:Hide()
end

-------------------------------------------------------------------------------
-- Open the icon picker window.
--
function IconPicker.IconPicker_Open(parent)
	if parent then
		parent:SetSelected(true)
	else
		SpellCreatorIconPicker.parent = nil
	end
	filteredList = nil

	SpellCreatorIconPicker.CloseButton:SetScript("OnClick", IconPicker.IconPicker_Close)

	IconPicker.IconPicker_RefreshScroll(true)
	SpellCreatorIconPicker.search:SetText("")
	SpellCreatorIconPicker:Show()
end
