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
	ASSETS_PATH .. "/icons/" .. "sf_black_anomaly",
	ASSETS_PATH .. "/icons/" .. "sf_black_armour",
	ASSETS_PATH .. "/icons/" .. "sf_black_barrage",
	ASSETS_PATH .. "/icons/" .. "sf_black_barrier",
	ASSETS_PATH .. "/icons/" .. "sf_black_blade",
	ASSETS_PATH .. "/icons/" .. "sf_black_book",
	ASSETS_PATH .. "/icons/" .. "sf_black_burst",
	ASSETS_PATH .. "/icons/" .. "sf_black_claw",
	ASSETS_PATH .. "/icons/" .. "sf_black_clothes",
	ASSETS_PATH .. "/icons/" .. "sf_black_core",
	ASSETS_PATH .. "/icons/" .. "sf_black_crystal",
	ASSETS_PATH .. "/icons/" .. "sf_black_dewdrop",
	ASSETS_PATH .. "/icons/" .. "sf_black_dragonflight",
	ASSETS_PATH .. "/icons/" .. "sf_black_dragonseye",
	ASSETS_PATH .. "/icons/" .. "sf_black_eye",
	ASSETS_PATH .. "/icons/" .. "sf_black_fist",
	ASSETS_PATH .. "/icons/" .. "sf_black_flower",
	ASSETS_PATH .. "/icons/" .. "sf_black_gem",
	ASSETS_PATH .. "/icons/" .. "sf_black_head",
	ASSETS_PATH .. "/icons/" .. "sf_black_hourglass",
	ASSETS_PATH .. "/icons/" .. "sf_black_key",
	ASSETS_PATH .. "/icons/" .. "sf_black_magic",
	ASSETS_PATH .. "/icons/" .. "sf_black_map",
	ASSETS_PATH .. "/icons/" .. "sf_black_miasma",
	ASSETS_PATH .. "/icons/" .. "sf_black_necklace",
	ASSETS_PATH .. "/icons/" .. "sf_black_needle",
	ASSETS_PATH .. "/icons/" .. "sf_black_nexusoff",
	ASSETS_PATH .. "/icons/" .. "sf_black_nexuson",
	ASSETS_PATH .. "/icons/" .. "sf_black_orb",
	ASSETS_PATH .. "/icons/" .. "sf_black_ore",
	ASSETS_PATH .. "/icons/" .. "sf_black_pearl",
	ASSETS_PATH .. "/icons/" .. "sf_black_petal",
	ASSETS_PATH .. "/icons/" .. "sf_black_potion",
	ASSETS_PATH .. "/icons/" .. "sf_black_power",
	ASSETS_PATH .. "/icons/" .. "sf_black_questionmark",
	ASSETS_PATH .. "/icons/" .. "sf_black_return",
	ASSETS_PATH .. "/icons/" .. "sf_black_ring",
	ASSETS_PATH .. "/icons/" .. "sf_black_scroll",
	ASSETS_PATH .. "/icons/" .. "sf_black_shower",
	ASSETS_PATH .. "/icons/" .. "sf_black_sigil",
	ASSETS_PATH .. "/icons/" .. "sf_black_speed",
	ASSETS_PATH .. "/icons/" .. "sf_black_sprint",
	ASSETS_PATH .. "/icons/" .. "sf_black_starflower",
	ASSETS_PATH .. "/icons/" .. "sf_black_sword",
	ASSETS_PATH .. "/icons/" .. "sf_black_teleport",
	ASSETS_PATH .. "/icons/" .. "sf_black_thread",
	ASSETS_PATH .. "/icons/" .. "sf_black_time",
	ASSETS_PATH .. "/icons/" .. "sf_black_tome",
	ASSETS_PATH .. "/icons/" .. "sf_black_transform",
	ASSETS_PATH .. "/icons/" .. "sf_blue_anomaly",
	ASSETS_PATH .. "/icons/" .. "sf_blue_armour",
	ASSETS_PATH .. "/icons/" .. "sf_blue_barrage",
	ASSETS_PATH .. "/icons/" .. "sf_blue_barrier",
	ASSETS_PATH .. "/icons/" .. "sf_blue_blade",
	ASSETS_PATH .. "/icons/" .. "sf_blue_book",
	ASSETS_PATH .. "/icons/" .. "sf_blue_burst",
	ASSETS_PATH .. "/icons/" .. "sf_blue_claw",
	ASSETS_PATH .. "/icons/" .. "sf_blue_clothes",
	ASSETS_PATH .. "/icons/" .. "sf_blue_core",
	ASSETS_PATH .. "/icons/" .. "sf_blue_crystal",
	ASSETS_PATH .. "/icons/" .. "sf_blue_dewdrop",
	ASSETS_PATH .. "/icons/" .. "sf_blue_dragonflight",
	ASSETS_PATH .. "/icons/" .. "sf_blue_dragonseye",
	ASSETS_PATH .. "/icons/" .. "sf_blue_eye",
	ASSETS_PATH .. "/icons/" .. "sf_blue_fist",
	ASSETS_PATH .. "/icons/" .. "sf_blue_flower",
	ASSETS_PATH .. "/icons/" .. "sf_blue_gem",
	ASSETS_PATH .. "/icons/" .. "sf_blue_head",
	ASSETS_PATH .. "/icons/" .. "sf_blue_hourglass",
	ASSETS_PATH .. "/icons/" .. "sf_blue_key",
	ASSETS_PATH .. "/icons/" .. "sf_blue_magic",
	ASSETS_PATH .. "/icons/" .. "sf_blue_map",
	ASSETS_PATH .. "/icons/" .. "sf_blue_miasma",
	ASSETS_PATH .. "/icons/" .. "sf_blue_necklace",
	ASSETS_PATH .. "/icons/" .. "sf_blue_needle",
	ASSETS_PATH .. "/icons/" .. "sf_blue_nexusoff",
	ASSETS_PATH .. "/icons/" .. "sf_blue_nexuson",
	ASSETS_PATH .. "/icons/" .. "sf_blue_orb",
	ASSETS_PATH .. "/icons/" .. "sf_blue_ore",
	ASSETS_PATH .. "/icons/" .. "sf_blue_pearl",
	ASSETS_PATH .. "/icons/" .. "sf_blue_petal",
	ASSETS_PATH .. "/icons/" .. "sf_blue_potion",
	ASSETS_PATH .. "/icons/" .. "sf_blue_power",
	ASSETS_PATH .. "/icons/" .. "sf_blue_questionmark",
	ASSETS_PATH .. "/icons/" .. "sf_blue_return",
	ASSETS_PATH .. "/icons/" .. "sf_blue_ring",
	ASSETS_PATH .. "/icons/" .. "sf_blue_scroll",
	ASSETS_PATH .. "/icons/" .. "sf_blue_shower",
	ASSETS_PATH .. "/icons/" .. "sf_blue_sigil",
	ASSETS_PATH .. "/icons/" .. "sf_blue_speed",
	ASSETS_PATH .. "/icons/" .. "sf_blue_sprint",
	ASSETS_PATH .. "/icons/" .. "sf_blue_starflower",
	ASSETS_PATH .. "/icons/" .. "sf_blue_sword",
	ASSETS_PATH .. "/icons/" .. "sf_blue_teleport",
	ASSETS_PATH .. "/icons/" .. "sf_blue_thread",
	ASSETS_PATH .. "/icons/" .. "sf_blue_time",
	ASSETS_PATH .. "/icons/" .. "sf_blue_tome",
	ASSETS_PATH .. "/icons/" .. "sf_blue_transform",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_anomaly",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_armour",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_barrage",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_barrier",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_blade",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_book",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_burst",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_claw",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_clothes",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_core",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_crystal",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_dewdrop",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_dragonflight",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_dragonseye",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_eye",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_fist",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_flower",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_gem",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_head",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_hourglass",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_key",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_magic",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_map",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_miasma",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_necklace",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_needle",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_nexusoff",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_nexuson",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_orb",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_ore",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_pearl",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_petal",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_potion",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_power",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_questionmark",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_return",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_ring",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_scroll",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_shower",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_sigil",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_speed",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_sprint",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_starflower",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_sword",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_teleport",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_thread",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_time",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_tome",
	ASSETS_PATH .. "/icons/" .. "sf_bronze_transform",
	ASSETS_PATH .. "/icons/" .. "sf_fire_anomaly",
	ASSETS_PATH .. "/icons/" .. "sf_fire_armour",
	ASSETS_PATH .. "/icons/" .. "sf_fire_barrage",
	ASSETS_PATH .. "/icons/" .. "sf_fire_barrier",
	ASSETS_PATH .. "/icons/" .. "sf_fire_blade",
	ASSETS_PATH .. "/icons/" .. "sf_fire_book",
	ASSETS_PATH .. "/icons/" .. "sf_fire_burst",
	ASSETS_PATH .. "/icons/" .. "sf_fire_claw",
	ASSETS_PATH .. "/icons/" .. "sf_fire_clothes",
	ASSETS_PATH .. "/icons/" .. "sf_fire_core",
	ASSETS_PATH .. "/icons/" .. "sf_fire_crystal",
	ASSETS_PATH .. "/icons/" .. "sf_fire_dewdrop",
	ASSETS_PATH .. "/icons/" .. "sf_fire_dragonflight",
	ASSETS_PATH .. "/icons/" .. "sf_fire_dragonseye",
	ASSETS_PATH .. "/icons/" .. "sf_fire_eye",
	ASSETS_PATH .. "/icons/" .. "sf_fire_fist",
	ASSETS_PATH .. "/icons/" .. "sf_fire_flower",
	ASSETS_PATH .. "/icons/" .. "sf_fire_gem",
	ASSETS_PATH .. "/icons/" .. "sf_fire_head",
	ASSETS_PATH .. "/icons/" .. "sf_fire_hourglass",
	ASSETS_PATH .. "/icons/" .. "sf_fire_key",
	ASSETS_PATH .. "/icons/" .. "sf_fire_magic",
	ASSETS_PATH .. "/icons/" .. "sf_fire_map",
	ASSETS_PATH .. "/icons/" .. "sf_fire_miasma",
	ASSETS_PATH .. "/icons/" .. "sf_fire_necklace",
	ASSETS_PATH .. "/icons/" .. "sf_fire_needle",
	ASSETS_PATH .. "/icons/" .. "sf_fire_nexusoff",
	ASSETS_PATH .. "/icons/" .. "sf_fire_nexuson",
	ASSETS_PATH .. "/icons/" .. "sf_fire_orb",
	ASSETS_PATH .. "/icons/" .. "sf_fire_ore",
	ASSETS_PATH .. "/icons/" .. "sf_fire_pearl",
	ASSETS_PATH .. "/icons/" .. "sf_fire_petal",
	ASSETS_PATH .. "/icons/" .. "sf_fire_potion",
	ASSETS_PATH .. "/icons/" .. "sf_fire_power",
	ASSETS_PATH .. "/icons/" .. "sf_fire_questionmark",
	ASSETS_PATH .. "/icons/" .. "sf_fire_return",
	ASSETS_PATH .. "/icons/" .. "sf_fire_ring",
	ASSETS_PATH .. "/icons/" .. "sf_fire_scroll",
	ASSETS_PATH .. "/icons/" .. "sf_fire_shower",
	ASSETS_PATH .. "/icons/" .. "sf_fire_sigil",
	ASSETS_PATH .. "/icons/" .. "sf_fire_speed",
	ASSETS_PATH .. "/icons/" .. "sf_fire_sprint",
	ASSETS_PATH .. "/icons/" .. "sf_fire_starflower",
	ASSETS_PATH .. "/icons/" .. "sf_fire_sword",
	ASSETS_PATH .. "/icons/" .. "sf_fire_teleport",
	ASSETS_PATH .. "/icons/" .. "sf_fire_thread",
	ASSETS_PATH .. "/icons/" .. "sf_fire_time",
	ASSETS_PATH .. "/icons/" .. "sf_fire_tome",
	ASSETS_PATH .. "/icons/" .. "sf_fire_transform",
	ASSETS_PATH .. "/icons/" .. "sf_green_anomaly",
	ASSETS_PATH .. "/icons/" .. "sf_green_armour",
	ASSETS_PATH .. "/icons/" .. "sf_green_barrage",
	ASSETS_PATH .. "/icons/" .. "sf_green_barrier",
	ASSETS_PATH .. "/icons/" .. "sf_green_blade",
	ASSETS_PATH .. "/icons/" .. "sf_green_book",
	ASSETS_PATH .. "/icons/" .. "sf_green_burst",
	ASSETS_PATH .. "/icons/" .. "sf_green_claw",
	ASSETS_PATH .. "/icons/" .. "sf_green_clothes",
	ASSETS_PATH .. "/icons/" .. "sf_green_core",
	ASSETS_PATH .. "/icons/" .. "sf_green_crystal",
	ASSETS_PATH .. "/icons/" .. "sf_green_dewdrop",
	ASSETS_PATH .. "/icons/" .. "sf_green_dragonflight",
	ASSETS_PATH .. "/icons/" .. "sf_green_dragonseye",
	ASSETS_PATH .. "/icons/" .. "sf_green_eye",
	ASSETS_PATH .. "/icons/" .. "sf_green_fist",
	ASSETS_PATH .. "/icons/" .. "sf_green_flower",
	ASSETS_PATH .. "/icons/" .. "sf_green_gem",
	ASSETS_PATH .. "/icons/" .. "sf_green_head",
	ASSETS_PATH .. "/icons/" .. "sf_green_hourglass",
	ASSETS_PATH .. "/icons/" .. "sf_green_key",
	ASSETS_PATH .. "/icons/" .. "sf_green_magic",
	ASSETS_PATH .. "/icons/" .. "sf_green_map",
	ASSETS_PATH .. "/icons/" .. "sf_green_miasma",
	ASSETS_PATH .. "/icons/" .. "sf_green_necklace",
	ASSETS_PATH .. "/icons/" .. "sf_green_needle",
	ASSETS_PATH .. "/icons/" .. "sf_green_nexusoff",
	ASSETS_PATH .. "/icons/" .. "sf_green_nexuson",
	ASSETS_PATH .. "/icons/" .. "sf_green_orb",
	ASSETS_PATH .. "/icons/" .. "sf_green_ore",
	ASSETS_PATH .. "/icons/" .. "sf_green_pearl",
	ASSETS_PATH .. "/icons/" .. "sf_green_petal",
	ASSETS_PATH .. "/icons/" .. "sf_green_potion",
	ASSETS_PATH .. "/icons/" .. "sf_green_power",
	ASSETS_PATH .. "/icons/" .. "sf_green_questionmark",
	ASSETS_PATH .. "/icons/" .. "sf_green_return",
	ASSETS_PATH .. "/icons/" .. "sf_green_ring",
	ASSETS_PATH .. "/icons/" .. "sf_green_scroll",
	ASSETS_PATH .. "/icons/" .. "sf_green_shower",
	ASSETS_PATH .. "/icons/" .. "sf_green_sigil",
	ASSETS_PATH .. "/icons/" .. "sf_green_speed",
	ASSETS_PATH .. "/icons/" .. "sf_green_sprint",
	ASSETS_PATH .. "/icons/" .. "sf_green_starflower",
	ASSETS_PATH .. "/icons/" .. "sf_green_sword",
	ASSETS_PATH .. "/icons/" .. "sf_green_teleport",
	ASSETS_PATH .. "/icons/" .. "sf_green_thread",
	ASSETS_PATH .. "/icons/" .. "sf_green_time",
	ASSETS_PATH .. "/icons/" .. "sf_green_tome",
	ASSETS_PATH .. "/icons/" .. "sf_green_transform",
	ASSETS_PATH .. "/icons/" .. "sf_inf_anomaly",
	ASSETS_PATH .. "/icons/" .. "sf_inf_armour",
	ASSETS_PATH .. "/icons/" .. "sf_inf_barrage",
	ASSETS_PATH .. "/icons/" .. "sf_inf_barrier",
	ASSETS_PATH .. "/icons/" .. "sf_inf_blade",
	ASSETS_PATH .. "/icons/" .. "sf_inf_book",
	ASSETS_PATH .. "/icons/" .. "sf_inf_burst",
	ASSETS_PATH .. "/icons/" .. "sf_inf_claw",
	ASSETS_PATH .. "/icons/" .. "sf_inf_clothes",
	ASSETS_PATH .. "/icons/" .. "sf_inf_core",
	ASSETS_PATH .. "/icons/" .. "sf_inf_crystal",
	ASSETS_PATH .. "/icons/" .. "sf_inf_dewdrop",
	ASSETS_PATH .. "/icons/" .. "sf_inf_dragonflight",
	ASSETS_PATH .. "/icons/" .. "sf_inf_dragonseye",
	ASSETS_PATH .. "/icons/" .. "sf_inf_eye",
	ASSETS_PATH .. "/icons/" .. "sf_inf_fist",
	ASSETS_PATH .. "/icons/" .. "sf_inf_flower",
	ASSETS_PATH .. "/icons/" .. "sf_inf_gem",
	ASSETS_PATH .. "/icons/" .. "sf_inf_head",
	ASSETS_PATH .. "/icons/" .. "sf_inf_hourglass",
	ASSETS_PATH .. "/icons/" .. "sf_inf_key",
	ASSETS_PATH .. "/icons/" .. "sf_inf_magic",
	ASSETS_PATH .. "/icons/" .. "sf_inf_map",
	ASSETS_PATH .. "/icons/" .. "sf_inf_miasma",
	ASSETS_PATH .. "/icons/" .. "sf_inf_necklace",
	ASSETS_PATH .. "/icons/" .. "sf_inf_needle",
	ASSETS_PATH .. "/icons/" .. "sf_inf_nexusoff",
	ASSETS_PATH .. "/icons/" .. "sf_inf_nexuson",
	ASSETS_PATH .. "/icons/" .. "sf_inf_orb",
	ASSETS_PATH .. "/icons/" .. "sf_inf_ore",
	ASSETS_PATH .. "/icons/" .. "sf_inf_pearl",
	ASSETS_PATH .. "/icons/" .. "sf_inf_petal",
	ASSETS_PATH .. "/icons/" .. "sf_inf_potion",
	ASSETS_PATH .. "/icons/" .. "sf_inf_power",
	ASSETS_PATH .. "/icons/" .. "sf_inf_questionmark",
	ASSETS_PATH .. "/icons/" .. "sf_inf_return",
	ASSETS_PATH .. "/icons/" .. "sf_inf_ring",
	ASSETS_PATH .. "/icons/" .. "sf_inf_scroll",
	ASSETS_PATH .. "/icons/" .. "sf_inf_shower",
	ASSETS_PATH .. "/icons/" .. "sf_inf_sigil",
	ASSETS_PATH .. "/icons/" .. "sf_inf_speed",
	ASSETS_PATH .. "/icons/" .. "sf_inf_sprint",
	ASSETS_PATH .. "/icons/" .. "sf_inf_starflower",
	ASSETS_PATH .. "/icons/" .. "sf_inf_sword",
	ASSETS_PATH .. "/icons/" .. "sf_inf_teleport",
	ASSETS_PATH .. "/icons/" .. "sf_inf_thread",
	ASSETS_PATH .. "/icons/" .. "sf_inf_time",
	ASSETS_PATH .. "/icons/" .. "sf_inf_tome",
	ASSETS_PATH .. "/icons/" .. "sf_inf_transform",
	ASSETS_PATH .. "/icons/" .. "sf_red_anomaly",
	ASSETS_PATH .. "/icons/" .. "sf_red_armour",
	ASSETS_PATH .. "/icons/" .. "sf_red_barrage",
	ASSETS_PATH .. "/icons/" .. "sf_red_barrier",
	ASSETS_PATH .. "/icons/" .. "sf_red_blade",
	ASSETS_PATH .. "/icons/" .. "sf_red_book",
	ASSETS_PATH .. "/icons/" .. "sf_red_burst",
	ASSETS_PATH .. "/icons/" .. "sf_red_claw",
	ASSETS_PATH .. "/icons/" .. "sf_red_clothes",
	ASSETS_PATH .. "/icons/" .. "sf_red_core",
	ASSETS_PATH .. "/icons/" .. "sf_red_crystal",
	ASSETS_PATH .. "/icons/" .. "sf_red_dewdrop",
	ASSETS_PATH .. "/icons/" .. "sf_red_dragonflight",
	ASSETS_PATH .. "/icons/" .. "sf_red_dragonseye",
	ASSETS_PATH .. "/icons/" .. "sf_red_eye",
	ASSETS_PATH .. "/icons/" .. "sf_red_fist",
	ASSETS_PATH .. "/icons/" .. "sf_red_flower",
	ASSETS_PATH .. "/icons/" .. "sf_red_gem",
	ASSETS_PATH .. "/icons/" .. "sf_red_head",
	ASSETS_PATH .. "/icons/" .. "sf_red_hourglass",
	ASSETS_PATH .. "/icons/" .. "sf_red_key",
	ASSETS_PATH .. "/icons/" .. "sf_red_magic",
	ASSETS_PATH .. "/icons/" .. "sf_red_map",
	ASSETS_PATH .. "/icons/" .. "sf_red_miasma",
	ASSETS_PATH .. "/icons/" .. "sf_red_necklace",
	ASSETS_PATH .. "/icons/" .. "sf_red_needle",
	ASSETS_PATH .. "/icons/" .. "sf_red_nexusoff",
	ASSETS_PATH .. "/icons/" .. "sf_red_nexuson",
	ASSETS_PATH .. "/icons/" .. "sf_red_orb",
	ASSETS_PATH .. "/icons/" .. "sf_red_ore",
	ASSETS_PATH .. "/icons/" .. "sf_red_pearl",
	ASSETS_PATH .. "/icons/" .. "sf_red_petal",
	ASSETS_PATH .. "/icons/" .. "sf_red_potion",
	ASSETS_PATH .. "/icons/" .. "sf_red_power",
	ASSETS_PATH .. "/icons/" .. "sf_red_questionmark",
	ASSETS_PATH .. "/icons/" .. "sf_red_return",
	ASSETS_PATH .. "/icons/" .. "sf_red_ring",
	ASSETS_PATH .. "/icons/" .. "sf_red_scroll",
	ASSETS_PATH .. "/icons/" .. "sf_red_shower",
	ASSETS_PATH .. "/icons/" .. "sf_red_sigil",
	ASSETS_PATH .. "/icons/" .. "sf_red_speed",
	ASSETS_PATH .. "/icons/" .. "sf_red_sprint",
	ASSETS_PATH .. "/icons/" .. "sf_red_starflower",
	ASSETS_PATH .. "/icons/" .. "sf_red_sword",
	ASSETS_PATH .. "/icons/" .. "sf_red_teleport",
	ASSETS_PATH .. "/icons/" .. "sf_red_thread",
	ASSETS_PATH .. "/icons/" .. "sf_red_time",
	ASSETS_PATH .. "/icons/" .. "sf_red_tome",
	ASSETS_PATH .. "/icons/" .. "sf_red_transform",
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
			--dprint(nil, "Path of Custom Icon: " .. icon)
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
