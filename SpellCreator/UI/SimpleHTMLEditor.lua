---@class ns
local ns = select(2, ...)

local baseHTMLString = [[<html><body>

</body></html>]]

-- string helpers
--- @return number StartPos, number EndPos highlight pos in this editbox.
local function GetTextHighlightPos ( editbox )
    local Text, Cursor = editbox:GetText(), editbox:GetCursorPosition();
    editbox:Insert( "" ); -- Delete selected text
    local TextNew, CursorNew = editbox:GetText(), editbox:GetCursorPosition();
    -- Restore previous text
    editbox:SetText( Text );
    editbox:SetCursorPosition( Cursor );
    local Start, End = CursorNew, #Text - ( #TextNew - CursorNew );
    editbox:HighlightText( Start, End );
    return Start, End;
end

---Wraps this editbox's selected text with the given tag.
---@param editbox any
---@param tagSyntax any
---@param attributes any?
local function WrapSelectionInTag ( editbox, tagSyntax, attributes )
    if not editbox or not tagSyntax then return end

    local Start, End = GetTextHighlightPos( editbox );
    local Text, Cursor = editbox:GetText(), editbox:GetCursorPosition();
    if ( Start == End ) then -- Nothing selected
      Start, End = Cursor, Cursor; -- Wrap around cursor
      --return; -- Wrapping the cursor in a color code and hitting backspace crashes the client!
    end

    local Selection = Text:sub( Start + 1, End );
    local finalText = tagSyntax

    local attributesString = ""
    if attributes then
        for k,v in pairs(attributes) do
            attributesString = " " .. attributesString .. k .. '="'..v..'"'
        end
    end
    finalText = finalText:gsub("%%attributes", attributesString)
    finalText = finalText:gsub("%%text", Selection)

    editbox:Insert(finalText)

    editbox:SetCursorPosition( Cursor );
    -- Highlight selection and wrapper
    editbox:HighlightText( Start, (Start + #finalText) );
end

-- Frames

local mainFrame = CreateFrame("Frame", "ARC_SimpleHTMLEditor", UIParent, "ButtonFrameTemplate")
mainFrame:Hide()
mainFrame:SetSize(DEFAULT_ITEM_TEXT_FRAME_WIDTH, DEFAULT_ITEM_TEXT_FRAME_HEIGHT)
mainFrame:SetPoint("CENTER")
ButtonFrameTemplate_HidePortrait(mainFrame)
mainFrame:SetTitle("Simple HTML Editor")

mainFrame.ScrollEditor = CreateFrame("ScrollFrame", nil, mainFrame.Inset, "InputScrollFrameTemplate")
mainFrame.ScrollEditor.CharCount:Hide()
--mainFrame.ScrollEditor:SetSize(350, 100)
--mainFrame.ScrollEditor:SetPoint("CENTER")
mainFrame.ScrollEditor:SetAllPoints()
local inputEntryBox = mainFrame.ScrollEditor.EditBox --[[@as SpellRowFrameInput]]
inputEntryBox:SetWidth(mainFrame.ScrollEditor:GetWidth() - 18)
inputEntryBox:SetText(baseHTMLString)

local buttonsOrder = {"h1", "h2", "h3", "p", "img", "a", "br"}
local buttons = {
    h1 = { name = "Header 1", syntax = "<h1%attributes>%text</h1>", attributes = {{name = "align", options = "left", "center", "right" }}},
    h2 = { name = "Header 2", syntax = "<h2%attributes>%text</h2>", attributes = {{name = "align", options = "left", "center", "right" }}},
    h3 = { name = "Header 3", syntax = "<h3%attributes>%text</h3>", attributes = {{name = "align", options = "left", "center", "right" }}},
    p = { name = "Paragraph", syntax = "<p%attributes>%text</p>", attributes = {{name = "align", options = "left", "center", "right" }}},

    --img = {name = "Image", syntax = "<img%attributes />", attributes = {{name = "align", options = "left", "center", "right"}, {name = "width", type = "number"}, {name = "height", type = "number"}, {name = "src", type = "string"}} },
    --a = {name = "Link", syntax = "<a%attributes>%text</a>", attributes = {{name = "href", type = "string"}}},
    br = {name = "Line Break", syntax = "<br/>"}
}

local function buttonFunc(button)
    local buttonData = buttons[button.htmlTag]
    local editor = mainFrame.ScrollEditor.EditBox
    WrapSelectionInTag(editor, buttonData.syntax)
end

local lastButton
for k, buttonName in ipairs(buttonsOrder) do
    local buttonData = buttons[buttonName]
    if buttonData then
        local button = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
        button:SetText(buttonName)
        button.htmlTag = buttonName
        button:SetWidth(button.Text:GetUnboundedStringWidth() + 20)
        if not lastButton then
            button:SetPoint("BOTTOMLEFT", 0, 2)
        else
            button:SetPoint("LEFT", lastButton, "RIGHT", 10, 0)
        end
        lastButton = button
        button:SetScript("OnClick", buttonFunc)
    end
end

local function openEditor(frame, text)

end

-- ARC_SimpleHTMLEditor_Preview
--/run ARC_SimpleHTMLEditor_Preview.PageBg:SetTexCoord(0,1,0,1)
-- Preview Frame
local previewFrame = CreateFrame("Frame", "ARC_SimpleHTMLEditor_Preview", mainFrame, "ButtonFrameTemplate")
previewFrame:SetSize(DEFAULT_ITEM_TEXT_FRAME_WIDTH, DEFAULT_ITEM_TEXT_FRAME_HEIGHT)
previewFrame:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT")
ButtonFrameTemplate_HidePortrait(previewFrame)
ButtonFrameTemplate_HideAttic(previewFrame)
ButtonFrameTemplate_HideButtonBar(previewFrame)
previewFrame:SetTitle("Simple HTML Preview")
previewFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, previewFrame.Inset, "UIPanelScrollFrameTemplate")
--previewFrame.ScrollFrame:SetAllPoints(previewFrame.Inset)
previewFrame.ScrollFrame:SetPoint("TOPLEFT", 3, -4)
previewFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)
--previewFrame.Bg:SetAtlas("QuestDetailsBackgrounds");
previewFrame.PageBg = previewFrame:CreateTexture()
previewFrame.PageBg:SetTexture("Interface\\QuestFrame\\QuestBG");
previewFrame.PageBg:SetPoint("TOPLEFT", 2, -21)
previewFrame.PageBg:SetPoint("BOTTOMRIGHT", -4, 4)
--previewFrame.PageBg:SetAllPoints()
previewFrame.PageBg:SetTexCoord(0, 0.585, 0, 0.65)
previewFrame.Inset.Bg:Hide()

local scrollFrame = previewFrame.ScrollFrame
local scrollChild = CreateFrame("Frame")
scrollFrame.scrollChild = scrollChild
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(scrollFrame:GetWidth()-18)
scrollChild:SetHeight(10)

local simpleHTMLsize = { x=270, y=304 }
scrollChild.SimpleHTMLFrame = CreateFrame('SimpleHTML', nil, scrollChild);
scrollChild.SimpleHTMLFrame:SetSize(simpleHTMLsize.x, simpleHTMLsize.y)
scrollChild.SimpleHTMLFrame:SetPoint("TOP")
scrollChild.SimpleHTMLFrame:SetText('<html><body><h1>Heading1</h1><p>A paragraph</p></body></html>');
scrollChild.SimpleHTMLFrame:SetFont('Fonts\\FRIZQT__.TTF', 11);

local fontTable = ITEM_TEXT_FONTS["default"]
for tag, font in pairs(fontTable) do
    scrollChild.SimpleHTMLFrame:SetFontObject(tag, font);
end

inputEntryBox:HookScript("OnTextChanged", function(self)
    scrollChild.SimpleHTMLFrame:SetText(self:GetText())
end)

local previewToggleButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
previewToggleButton:SetText("Preview")
previewToggleButton:SetWidth(previewToggleButton.Text:GetUnboundedStringWidth() + 20)
previewToggleButton:SetPoint("TOPRIGHT", -16, -24)
previewToggleButton:SetScript("OnClick", function()
    previewFrame:SetShown(not previewFrame:IsShown())
end)

---@class UI_SimpleHTMLEditor
ns.UI.SimpleHTMLEditor = {
    open = openEditor,
}