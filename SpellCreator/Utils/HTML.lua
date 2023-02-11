---@class ns
local ns = select(2, ...)

local Logging = ns.Logging

local eprint = Logging.eprint

local directReplacements = {
	["/col"] = "|r",
};

local function strTexture(iconPath, iconSize)
	assert(iconPath, "Icon path is nil.");
	iconSize = iconSize or 15;
	return strconcat("|T", iconPath, ":", iconSize, ":", iconSize, "|t");
end

--- Gives the full texture path of an individual icon.
--- Handle using icon as a string
--- @param icon string
--- @return string
local function getIconTexture(icon)
	return "Interface\\ICONS\\" .. tostring(icon)
end

-- Return an texture text tag based on the given icon url and size.
local function strIcon(iconPath, iconSize)
	return strTexture(getIconTexture(iconPath), iconSize);
end

-- Return a color tag based on a letter
local function strColor(color)
	color = color or "w"; -- default color if bad argument
	if color == "r" then return "|cffff0000" end -- red
	if color == "g" then return "|cff00ff00" end -- green
	if color == "b" then return "|cff0000ff" end -- blue
	if color == "y" then return "|cffffff00" end -- yellow
	if color == "p" then return "|cffff00ff" end -- purple
	if color == "c" then return "|cff00ffff" end -- cyan
	if color == "w" then return "|cffffffff" end -- white
	if color == "0" then return "|cff000000" end -- black
	if color == "o" then return "|cffffaa00" end -- orange
end

local function convertTextTag(tag)

	if directReplacements[tag] then -- Direct replacement
		return directReplacements[tag];
	elseif tag:match("^col%:%a$") then -- Color replacement
		return strColor(tag:match("^col%:(%a)$"));
	elseif tag:match("^col:%x%x%x%x%x%x$") then -- Hexa color replacement
		return "|cff"..tag:match("^col:(%x%x%x%x%x%x)$");
	elseif tag:match("^icon%:[^:]+%:%d+$") then -- Icon
		local icon, size = tag:match("^icon%:([^:]+)%:(%d+)$");
		return strIcon(icon, size);
	end

	return "{"..tag.."}";
end

local function convertTextTags(text)
	if text then
		text = text:gsub("%{(.-)%}", convertTextTag);
		return text;
	end
end

local escapedHTMLCharacters = {
	["<"] = "&lt;",
	[">"] = "&gt;",
	["\""] = "&quot;",
};

local structureTags = {
	["{h(%d)}"] = "<h%1>",
	["{h(%d):c}"] = "<h%1 align=\"center\">",
	["{h(%d):r}"] = "<h%1 align=\"right\">",
	["{/h(%d)}"] = "</h%1>",

	["{p}"] = "<P>",
	["{p:c}"] = "<P align=\"center\">",
	["{p:r}"] = "<P align=\"right\">",
	["{/p}"] = "</P>",
};

--- alignmentAttributes is a conversion table for taking a single-character
--  alignment specifier and getting a value suitable for use in the HTML
--  "align" attribute.
local alignmentAttributes = {
	["c"] = "center",
	["l"] = "left",
	["r"] = "right",
};

--- IMAGE_PATTERN is the string pattern used for performing image replacements
--  in strings that should be rendered as HTML.
---
--- The accepted form this is "{img:<src>:<width>:<height>[:align]}".
---
--- Each individual segment matches up to the next present colon. The third
--- match (height) and everything thereafter needs to check up-to the next
--- colon -or- ending bracket since they could be the final segment.
---
--- Optional segments should of course have the "?" modifer attached to
--- their preceeding colon, and should use * for the content match rather
--- than +.
local IMAGE_PATTERN = [[{img%:([^:]+)%:([^:]+)%:([^:}]+)%:?([^:}]*)%}]];

--- Note that the image tag has to be outside a <P> tag.
---@language HTML
local IMAGE_TAG = [[</P><img src="%s" width="%s" height="%s" align="%s"/><P>]];

-- Convert the given text by his HTML representation

local function stringToHTML(text, noColor)

	local linkColor = "|cff00ff00";
	if noColor then
		linkColor = "";
	end

	-- 1) Replacement : & character
	text = text:gsub("&", "&amp;");

	-- 2) Replacement : escape HTML characters
	for pattern, replacement in pairs(escapedHTMLCharacters) do
		text = text:gsub(pattern, replacement);
	end

	-- 3) Replace Markdown
	local titleFunction = function(titleChars, title)
		local titleLevel = #titleChars;
		return "\n<h" .. titleLevel .. ">" .. strtrim(title) .. "</h" .. titleLevel .. ">";
	end;

	text = text:gsub("^(#+)(.-)\n", titleFunction);
	text = text:gsub("\n(#+)(.-)\n", titleFunction);
	text = text:gsub("\n(#+)(.-)$", titleFunction);
	text = text:gsub("^(#+)(.-)$", titleFunction);

	-- 4) Replacement : text tags
	for pattern, replacement in pairs(structureTags) do
		text = text:gsub(pattern, replacement);
	end

	local tab = {};
	local i=1;
	while text:find("<") and i<500 do

		local before;
		before = text:sub(1, text:find("<") - 1);
		if #before > 0 then
			tinsert(tab, before);
		end

		local tagText;

		local tag = text:match("</(.-)>");
		if tag then
			tagText = text:sub( text:find("<"), text:find("</") + #tag + 2);
			if #tagText == #tag + 3 then
				return "Error in pattern."
			end
			tinsert(tab, tagText);
		else
			return "Error in pattern."
		end

		local after;
		after = text:sub(#before + #tagText + 1);
		text = after;

		--- 	Log.log("Iteration "..i);
		--- 	Log.log("before ("..(#before).."): "..before);
		--- 	Log.log("tagText ("..(#tagText).."): "..tagText);
		--- 	Log.log("after ("..(#before).."): "..after);

		i = i+1;
		if i == 500 then
			eprint("HTML overfloooow!");
		end
	end
	if #text > 0 then
		tinsert(tab, text); -- Rest of the text
	end

	--- log("Parts count "..(#tab));

	local finalText = "";
	for _, line in pairs(tab) do

		if not line:find("<") then
			line = "<P>" .. line .. "</P>";
		end
		line = line:gsub("\n","<br/>");

		-- Image tag. Specifiers after the height are optional, so they
		-- must be suitably defaulted and validated.
		line = line:gsub(IMAGE_PATTERN, function(img, width, height, align)
			-- If you've not given an alignment, or it's entirely invalid,
			-- you'll get the old default of center.
			align = alignmentAttributes[align] or "center";

			-- Don't blow up on non-numeric inputs. They won't display properly
			-- but that's a separate issue.
			width = tonumber(width) or 128;
			height = tonumber(height) or 128;

			-- Width and height should be absolute.
			-- The tag accepts negative value but people used that to fuck up their profiles
			return string.format(IMAGE_TAG, img, math.abs(width), math.abs(height), align);
		end);

		line = line:gsub("%!%[(.-)%]%((.-)%)", function(icon, size)
			if icon:find("\\") then
				-- If icon text contains \ we have a full texture path
				local width, height;
				if size:find("%,") then
					width, height = strsplit(",", size);
				else
					width = tonumber(size) or 128;
					height = width;
				end
				-- Width and height should be absolute.
				-- The tag accepts negative value but people used that to fuck up their profiles
				return string.format(IMAGE_TAG, icon, math.abs(width), math.abs(height), "center");
			end
			return strIcon(icon, tonumber(size) or 25);
		end);

		line = line:gsub("%[(.-)%]%((.-)%)",
			"<a href=\"%2\">" .. linkColor .. "[%1]|r</a>");

		line = line:gsub("{link%*(.-)%*(.-)}",
			"<a href=\"%1\">" .. linkColor .. "[%2]|r</a>");

		line = line:gsub("{twitter%*(.-)%*(.-)}",
			"<a href=\"twitter%1\">|cff61AAEE%2|r</a>");

		finalText = finalText .. line;
	end

	finalText = convertTextTags(finalText);

	return "<HTML><BODY>" .. finalText .. "</BODY></HTML>";
end

local HyperLinkCopyDialogName = "HTMLUTILS_HYPERLINK_COPYBOX" -- Rename this if you want to hook into your own popup dialog, otherwise this will use a default one
if not StaticPopupDialogs[HyperLinkCopyDialogName] then
	StaticPopupDialogs[HyperLinkCopyDialogName] = {
		text = "%s",
		button1 = CLOSE,
		OnAccept = function(self)
			self.editBox:SetText("")
		end,
		hasEditBox = true,
		timeout = 0,
		cancels = HyperLinkCopyDialogName,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
end

local function copyLink(self, link)
	local popup = StaticPopup_Show(HyperLinkCopyDialogName, link);
	local width = max(popup.text:GetStringWidth(), 100)
	width = min((GetScreenWidth()*.8), width) -- clamp to 80% screen width so it's not obnoxiously large..
	popup.editBox:SetWidth(width);
	popup:SetWidth(width+50)
	popup.text:SetText(BROWSER_COPY_LINK)
	popup.editBox:SetText(link)
	popup.editBox:SetFocus()
	popup.editBox:HighlightText()
end

---@class Utils_HTML
ns.Utils.HTML = {
    copyLink = copyLink,
	stringToHTML = stringToHTML,
}
