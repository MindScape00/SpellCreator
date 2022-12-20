---@class ns
local ns = select(2, ...)

local LibRPMedia = ns.Libs.LibRPMedia

local Gems = ns.UI.Gems
local dprint = ns.Logging.dprint

local FALLBACK_ICON = "Interface/Icons/inv_misc_questionmark"

local iconList = {};

-- Generate the default icon list using LibRPMedia.

local numLibIcons -- this will end as the number of icons in the Library database. Anything over that is custom.

for index, name in LibRPMedia:FindAllIcons() do
	numLibIcons = #iconList
	iconList[numLibIcons + 1] = name;
end

-- Insert the custom icons.

local SCFORGE_CUSTOM_ICONS = { -- manually defined because it needs to be stable. Do not add things in the middle, only add to the end! And don't delete either!
    Gems.gemPath("Red"),
    Gems.gemPath("Orange"),
    Gems.gemPath("Yellow"),
    Gems.gemPath("Jade"),
    Gems.gemPath("Green"),
    Gems.gemPath("Blue"),
    Gems.gemPath("Violet"),
    Gems.gemPath("Indigo"),
    Gems.gemPath("Pink"),
    Gems.gemPath("Prismatic"),
}

for i = 1, #SCFORGE_CUSTOM_ICONS do
	iconList[#iconList + 1] = SCFORGE_CUSTOM_ICONS[i]
end

local function getNumCustomIcons()
	return #SCFORGE_CUSTOM_ICONS
end

-- Handlers

local function convertPathToCustomIconIndex( path )
    return tIndexOf(SCFORGE_CUSTOM_ICONS, path)
end

local function getCustomIconPathFromIndex(index)
    return SCFORGE_CUSTOM_ICONS[tonumber(index)] or FALLBACK_ICON
end

local function getIconTextureFromName( name )
    local path
    if strfind(strlower(name),"addons/") then
        path = name
    else
        path = LibRPMedia:GetIconFileByName(name)
    end
    return path
end

local function SelectIcon( self, texID )
    if tonumber(texID) and tonumber(texID) < 10000 then
        texID = getCustomIconPathFromIndex(texID)
    end
    self.selectedTex = texID
    self:SetNormalTexture( texID )
end

local function ResetIcon( self )
    self.selectedTex = nil
    self:SetNormalTexture(FALLBACK_ICON)
end

local function getFinalIcon( icon )
    if icon then
        if tonumber(icon) and tonumber(icon) < 10000 then
            icon = getCustomIconPathFromIndex(icon)
			dprint(nil, "Path of Custom Icon: "..icon)
        else
            icon = icon
        end
    else
        --icon = "Interface/Icons/inv_misc_questionmark"
        --icon = Gems.gemPath("Violet")
		icon = FALLBACK_ICON
    end
    return icon
end

---@class UI_Icons
ns.UI.Icons = {
	FALLBACK_ICON = FALLBACK_ICON,
    iconList = iconList,
    SelectIcon = SelectIcon,
    ResetIcon = ResetIcon,
    getIconTextureFromName = getIconTextureFromName,
    convertPathToCustomIconIndex = convertPathToCustomIconIndex,
    getCustomIconPathFromIndex = getCustomIconPathFromIndex,
    getFinalIcon = getFinalIcon,
	getNumCustomIcons = getNumCustomIcons,
}
