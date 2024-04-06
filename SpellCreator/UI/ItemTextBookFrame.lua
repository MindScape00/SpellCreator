---@class ns
local ns = select(2, ...)

local ItemTextFrame = ArcanumItemTextFrame
local ItemTextScrollFrame = ItemTextFrame.ScrollFrame
local ItemTextCurrentPage = ItemTextFrame.CurrentPage
local ItemTextStatusBar = ItemTextFrame.StatusBar
local ItemTextPrevPageButton = ItemTextFrame.PrevPageButton
local ItemTextNextPageButton = ItemTextFrame.NextPageButton
local ItemTextPageText = ItemTextFrame.ScrollFrame.ScrollChild.PageText
local ItemTextScrollFrameScrollBar = ItemTextFrame.ScrollFrame.ScrollBar
local ItemTextMaterialTopLeft = ItemTextFrame.MaterialTopLeft
local ItemTextMaterialTopRight = ItemTextFrame.MaterialTopRight
local ItemTextMaterialBotLeft = ItemTextFrame.MaterialBotLeft
local ItemTextMaterialBotRight = ItemTextFrame.MaterialBotRight
local ItemTextFramePageBg = ItemTextFrame.PageBg

local newPageDelim = "||"

--local textColor, titleColor = { CreateColorFromHexString("FF000000"):GetRGB() }, { CreateColorFromHexString("FF000000"):GetRGB() }

local function registerToMethod(method, func)
	ItemTextFrame:HookScript(method, func)
end

---@class ItemTextFrame_FakeItemData
local FakeItemData = {
	title = "Title of the Book/Page/Text/Whatever!",
	pages = {"Lorem Ipsom..."},
	currentPage = 1,
	numPages = 1,
	fullPage = nil,
	material = nil,
}

local materials = {
	-- defaults
	Parchment = true,
	ParchmentLarge = true,

	-- special cases
	bronze = true,
	marble = true,
	silver = true,
	stone = true,
	valentine = true,
	progenitor = false, -- SL Only; switch to true in SL
}
local defaultMaterial = "Parchment"

local function assertMaterial(material)

	-- Load from FakeItemData if not given
	if not material then
		material = FakeItemData.material
	end

	-- Check if valid material, return default if not valid
	if material and materials[material] then
		return material
	else
		return defaultMaterial
	end
end

---@param material string?
local function ItemTextFrame_Begin(material)
	local self = ArcanumItemTextFrame
	material = assertMaterial(material)

	self.TitleText:SetText(FakeItemData.title);
	ItemTextScrollFrame:Hide();
	ItemTextCurrentPage:Hide();
	ItemTextStatusBar:Hide();
	ItemTextPrevPageButton:Hide();
	ItemTextNextPageButton:Hide();

	-- Set up fonts
	local fontTable = ITEM_TEXT_FONTS[material];
	if fontTable == nil then fontTable = ITEM_TEXT_FONTS["default"] end
	for tag, font in pairs(fontTable) do
		ItemTextPageText:SetFontObject(tag, font);
	end

	-- Set up text colors
	local textColor, titleColor = GetMaterialTextColors(material);
	ItemTextPageText:SetTextColor("P", textColor[1], textColor[2], textColor[3]);
	ItemTextPageText:SetTextColor("H1", titleColor[1], titleColor[2], titleColor[3]);
	ItemTextPageText:SetTextColor("H2", titleColor[1], titleColor[2], titleColor[3]);
	ItemTextPageText:SetTextColor("H3", titleColor[1], titleColor[2], titleColor[3]);
end

---@param material string?
local function ItemTextFrame_Ready(material)
	local self = ArcanumItemTextFrame
	material = assertMaterial(material)

	if (material == "ParchmentLarge") then
		self:SetWidth(EXPANDED_ITEM_TEXT_FRAME_WIDTH);
		self:SetHeight(EXPANDED_ITEM_TEXT_FRAME_HEIGHT);
		ItemTextScrollFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", -27, -89);
		ItemTextScrollFrame:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 6, 6);
		ItemTextPageText:SetPoint("TOPLEFT", 34, -15);
		ItemTextPageText:SetWidth(412);
		ItemTextPageText:SetHeight(440);
	else
		self:SetWidth(DEFAULT_ITEM_TEXT_FRAME_WIDTH);
		self:SetHeight(DEFAULT_ITEM_TEXT_FRAME_HEIGHT);
		if (FakeItemData.fullPage) then
			ItemTextScrollFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", -31, -63);
			ItemTextScrollFrame:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 6, 6);
			ItemTextPageText:SetPoint("TOPLEFT", 0, 0);
			ItemTextPageText:SetWidth(301);
			ItemTextPageText:SetHeight(355);
		else
			ItemTextScrollFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", -31, -63);
			ItemTextScrollFrame:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 6, 6);
			ItemTextPageText:SetPoint("TOPLEFT", 18, -15);
			ItemTextPageText:SetWidth(270);
			ItemTextPageText:SetHeight(304);
		end
	end

	local creator = FakeItemData.creator;
	if (creator) then
		creator = "\n\n" .. ITEM_TEXT_FROM .. "\n" .. creator .. "\n";
		ItemTextPageText:SetText(FakeItemData.pages[FakeItemData.currentPage] .. creator);
	else
		ItemTextPageText:SetText(FakeItemData.pages[FakeItemData.currentPage]);
	end

	-- Add some padding at the bottom if the bar can scroll appreciably
	ItemTextScrollFrame:GetScrollChild():SetHeight(1);
	ItemTextScrollFrame:UpdateScrollChildRect();
	if (floor(ItemTextScrollFrame:GetVerticalScrollRange()) > 0) then
		ItemTextScrollFrame:GetScrollChild():SetHeight(ItemTextScrollFrame:GetHeight() + ItemTextScrollFrame:GetVerticalScrollRange() + 30);
	end
	ItemTextScrollFrameScrollBar:SetValue(0);
	ItemTextScrollFrame:Show();
	local page = FakeItemData.currentPage;
	local hasNext = FakeItemData.numPages > FakeItemData.currentPage;

	ItemTextFramePageBg:Show();
	ItemTextFramePageBg:SetAtlas("Book-bg", true);

	if ( material == "Parchment" ) then
		ItemTextMaterialTopLeft:Hide();
		ItemTextMaterialTopRight:Hide();
		ItemTextMaterialBotLeft:Hide();
		ItemTextMaterialBotRight:Hide();
		ItemTextFramePageBg:Show();
		ItemTextFramePageBg:SetTexture("Interface\\QuestFrame\\QuestBG");
		ItemTextFramePageBg:SetWidth(512);
		ItemTextFramePageBg:SetHeight(543);
	elseif ( material == "ParchmentLarge" ) then
		ItemTextMaterialTopLeft:Hide();
		ItemTextMaterialTopRight:Hide();
		ItemTextMaterialBotLeft:Hide();
		ItemTextMaterialBotRight:Hide();
		ItemTextFramePageBg:Show();
		ItemTextFramePageBg:SetAtlas("Book-bg", true);
	else
		ItemTextFramePageBg:Hide();
		ItemTextMaterialTopLeft:Show();
		ItemTextMaterialTopRight:Show();
		ItemTextMaterialBotLeft:Show();
		ItemTextMaterialBotRight:Show();
		ItemTextMaterialTopLeft:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-TopLeft");
		ItemTextMaterialTopRight:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-TopRight");
		ItemTextMaterialBotLeft:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-BotLeft");
		ItemTextMaterialBotRight:SetTexture("Interface\\ItemTextFrame\\ItemText-"..material.."-BotRight");
	end

	if ((page > 1) or hasNext) then
		ItemTextCurrentPage:SetText(page);
		ItemTextCurrentPage:Show();
		if (page > 1) then
			ItemTextPrevPageButton:Show();
		else
			ItemTextPrevPageButton:Hide();
		end
		if (hasNext) then
			ItemTextNextPageButton:Show();
		else
			ItemTextNextPageButton:Hide();
		end
	end
	ItemTextStatusBar:Hide();
	ShowUIPanel(self);
end

local function ItemTextFrame_Close(self)
	HideUIPanel(self);
end

local function ItemTextFrame_OnUpdate(self, elapsed)
	if (ItemTextStatusBar:IsShown()) then
		elapsed = self.translationElapsed + elapsed;
		ItemTextStatusBar:SetValue(elapsed);
		self.translationElapsed = elapsed;
	end
end
registerToMethod("OnUpdate", ItemTextFrame_OnUpdate)

local function ItemTextFrame_OnShow(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);
end
registerToMethod("OnShow", ItemTextFrame_OnShow)

local function ItemTextFrame_OnHide(self)
	--CloseItemText();
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
end
registerToMethod("OnHide", ItemTextFrame_OnHide)

UIPanelWindows["ArcanumItemTextFrame"] = { area = "left", pushable = 0 };

---Open an Item Text with advanced options. Data Arg is a table of options settings.
---@param data ItemTextFrame_FakeItemData
local function openAdvancedItemText(data)
	FakeItemData = data

	ItemTextFrame_Begin()
	ItemTextFrame_Ready()
end

---Open an Item Text using default settings and just needing title & text.
---@param title string
---@param text string
---@param creator string?
local function openSimpleItemText(title, text, creator)
	local currentPage = 1
	local numPages = 1

	-- Clear Table
	table.wipe(FakeItemData)

	-- Set Table
	FakeItemData.currentPage = currentPage
	FakeItemData.numPages = numPages
	FakeItemData.pages = { strsplit(newPageDelim, text) }
	FakeItemData.title = title
	FakeItemData.creator = creator

	-- Open
	ItemTextFrame_Begin()
	ItemTextFrame_Ready()
end


---@class UI_ItemTextBookFrame
ns.UI.ItemTextBookFrame = {
	Close = ItemTextFrame_Close,
	Open = openSimpleItemText,
	Advanced = openAdvancedItemText,
}

ARC.BOOKFRAME = ns.UI.ItemTextBookFrame