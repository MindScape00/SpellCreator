---@class ns
local ns = select(2, ...)

local LibRPMedia = ns.Libs.LibRPMedia

local Gems = ns.UI.Gems
local dprint = ns.Logging.dprint
local ASSETS_PATH = ns.Constants.ASSETS_PATH

local FALLBACK_ICON = "Interface/Icons/inv_misc_questionmark"

local iconList = {};

-- Generate the default icon list using LibRPMedia.


local numLibIcons -- this will end as the number of icons in the Library database. Anything over that is custom. We don't currently use this however..

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
	ASSETS_PATH .. "/icons/" .. "Arcanum_ArcFox",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ArmourRed",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ArmourOrange",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ArmourYellow",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ArmourJade",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ArmourGreen",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ArmourBlue",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ArmourViolet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ArmourIndigo",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ArmourPink",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ArmourPrismatic",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrageRed",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrageOrange",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrageYellow",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrageJade",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrageGreen",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrageBlue",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrageViolet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrageIndigo",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarragePink",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarragePrismatic",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrierRed",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrierOrange",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrierYellow",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrierJade",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrierGreen",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrierBlue",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrierViolet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrierIndigo",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrierPink",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BarrierPrismatic",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BladeRed",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BladeOrange",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BladeYellow",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BladeJade",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BladeGreen",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BladeBlue",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BladeViolet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BladeIndigo",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BladePink",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BladePrismatic",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BookRed",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BookOrange",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BookYellow",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BookJade",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BookGreen",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BookBlue",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BookViolet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BookIndigo",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BookPink",
	ASSETS_PATH .. "/icons/" .. "Arcanum_BookPrismatic",
	ASSETS_PATH .. "/icons/" .. "Arcanum_FistRed",
	ASSETS_PATH .. "/icons/" .. "Arcanum_FistOrange",
	ASSETS_PATH .. "/icons/" .. "Arcanum_FistYellow",
	ASSETS_PATH .. "/icons/" .. "Arcanum_FistJade",
	ASSETS_PATH .. "/icons/" .. "Arcanum_FistGreen",
	ASSETS_PATH .. "/icons/" .. "Arcanum_FistBlue",
	ASSETS_PATH .. "/icons/" .. "Arcanum_FistViolet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_FistIndigo",
	ASSETS_PATH .. "/icons/" .. "Arcanum_FistPink",
	ASSETS_PATH .. "/icons/" .. "Arcanum_FistPrismatic",
	ASSETS_PATH .. "/icons/" .. "Arcanum_GemRed",
	ASSETS_PATH .. "/icons/" .. "Arcanum_GemOrange",
	ASSETS_PATH .. "/icons/" .. "Arcanum_GemYellow",
	ASSETS_PATH .. "/icons/" .. "Arcanum_GemJade",
	ASSETS_PATH .. "/icons/" .. "Arcanum_GemGreen",
	ASSETS_PATH .. "/icons/" .. "Arcanum_GemBlue",
	ASSETS_PATH .. "/icons/" .. "Arcanum_GemViolet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_GemIndigo",
	ASSETS_PATH .. "/icons/" .. "Arcanum_GemPink",
	ASSETS_PATH .. "/icons/" .. "Arcanum_GemPrismatic",
	ASSETS_PATH .. "/icons/" .. "Arcanum_MiasmaRed",
	ASSETS_PATH .. "/icons/" .. "Arcanum_MiasmaOrange",
	ASSETS_PATH .. "/icons/" .. "Arcanum_MiasmaYellow",
	ASSETS_PATH .. "/icons/" .. "Arcanum_MiasmaJade",
	ASSETS_PATH .. "/icons/" .. "Arcanum_MiasmaGreen",
	ASSETS_PATH .. "/icons/" .. "Arcanum_MiasmaBlue",
	ASSETS_PATH .. "/icons/" .. "Arcanum_MiasmaViolet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_MiasmaIndigo",
	ASSETS_PATH .. "/icons/" .. "Arcanum_MiasmaPink",
	ASSETS_PATH .. "/icons/" .. "Arcanum_MiasmaPrismatic",
	ASSETS_PATH .. "/icons/" .. "Arcanum_OrbRed",
	ASSETS_PATH .. "/icons/" .. "Arcanum_OrbOrange",
	ASSETS_PATH .. "/icons/" .. "Arcanum_OrbYellow",
	ASSETS_PATH .. "/icons/" .. "Arcanum_OrbJade",
	ASSETS_PATH .. "/icons/" .. "Arcanum_OrbGreen",
	ASSETS_PATH .. "/icons/" .. "Arcanum_OrbBlue",
	ASSETS_PATH .. "/icons/" .. "Arcanum_OrbViolet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_OrbIndigo",
	ASSETS_PATH .. "/icons/" .. "Arcanum_OrbPink",
	ASSETS_PATH .. "/icons/" .. "Arcanum_OrbPrismatic",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ShowerRed",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ShowerOrange",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ShowerYellow",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ShowerJade",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ShowerGreen",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ShowerBlue",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ShowerViolet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ShowerIndigo",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ShowerPink",
	ASSETS_PATH .. "/icons/" .. "Arcanum_ShowerPrismatic",
	ASSETS_PATH .. "/icons/" .. "Arcanum_SprintRed",
	ASSETS_PATH .. "/icons/" .. "Arcanum_SprintOrange",
	ASSETS_PATH .. "/icons/" .. "Arcanum_SprintYellow",
	ASSETS_PATH .. "/icons/" .. "Arcanum_SprintJade",
	ASSETS_PATH .. "/icons/" .. "Arcanum_SprintGreen",
	ASSETS_PATH .. "/icons/" .. "Arcanum_SprintBlue",
	ASSETS_PATH .. "/icons/" .. "Arcanum_SprintViolet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_SprintIndigo",
	ASSETS_PATH .. "/icons/" .. "Arcanum_SprintPink",
	ASSETS_PATH .. "/icons/" .. "Arcanum_SprintPrismatic",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraApertus",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraArcanowl",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraArcTea",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraArcWolf",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraArrowDown",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraArrowLeft",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraArrowRight",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraArrowUp",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraBooks",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraCastle",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraChest",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraCoffee",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraCompass",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraHelmet",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraPortal",
	ASSETS_PATH .. "/icons/" .. "Arcanum_XtraSpeech",
}

for i = 1, #SCFORGE_CUSTOM_ICONS do
	iconList[#iconList + 1] = SCFORGE_CUSTOM_ICONS[i]
end

local function getNumCustomIcons()
	return #SCFORGE_CUSTOM_ICONS
end

-- Handlers

local function convertPathToCustomIconIndex(path)
	return tIndexOf(SCFORGE_CUSTOM_ICONS, path)
end

local function getCustomIconPathFromIndex(index)
	return SCFORGE_CUSTOM_ICONS[tonumber(index)] or FALLBACK_ICON
end

local function getIconTextureFromName(name)
	local path
	if strfind(strlower(name), "addons/") then
		path = name
	else
		path = LibRPMedia:GetIconFileByName(name)
	end
	return path
end

local function SelectIcon(self, texID)
	if tonumber(texID) and tonumber(texID) < 10000 then
		texID = getCustomIconPathFromIndex(texID)
	end
	self.selectedTex = texID
	self:SetNormalTexture(texID)
end

local function ResetIcon(self)
	self.selectedTex = nil
	self:SetNormalTexture(FALLBACK_ICON)
end

local function getFinalIcon(icon)
	if icon then
		if tonumber(icon) and tonumber(icon) < 10000 then
			icon = getCustomIconPathFromIndex(icon)
			dprint(nil, "Path of Custom Icon: " .. icon)
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
