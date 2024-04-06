---@class ns
local ns = select(2, ...)

local LibRPMedia = ns.Libs.LibRPMedia

local Gems = ns.UI.Gems
local dprint = ns.Logging.dprint
local ASSETS_PATH = ns.Constants.ASSETS_PATH
local ICON_PATH = ASSETS_PATH .. "/icons/"

local function getIconSubPath(...)
	local paths = { ... }
	return ICON_PATH .. table.concat(paths, "/")
end

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
	getIconSubPath("Arcanum_ArcFox"),
	getIconSubPath("Arcanum_ArmourRed"),
	getIconSubPath("Arcanum_ArmourOrange"),
	getIconSubPath("Arcanum_ArmourYellow"),
	getIconSubPath("Arcanum_ArmourJade"),
	getIconSubPath("Arcanum_ArmourGreen"),
	getIconSubPath("Arcanum_ArmourBlue"),
	getIconSubPath("Arcanum_ArmourViolet"),
	getIconSubPath("Arcanum_ArmourIndigo"),
	getIconSubPath("Arcanum_ArmourPink"),
	getIconSubPath("Arcanum_ArmourPrismatic"),
	getIconSubPath("Arcanum_BarrageRed"),
	getIconSubPath("Arcanum_BarrageOrange"),
	getIconSubPath("Arcanum_BarrageYellow"),
	getIconSubPath("Arcanum_BarrageJade"),
	getIconSubPath("Arcanum_BarrageGreen"),
	getIconSubPath("Arcanum_BarrageBlue"),
	getIconSubPath("Arcanum_BarrageViolet"),
	getIconSubPath("Arcanum_BarrageIndigo"),
	getIconSubPath("Arcanum_BarragePink"),
	getIconSubPath("Arcanum_BarragePrismatic"),
	getIconSubPath("Arcanum_BarrierRed"),
	getIconSubPath("Arcanum_BarrierOrange"),
	getIconSubPath("Arcanum_BarrierYellow"),
	getIconSubPath("Arcanum_BarrierJade"),
	getIconSubPath("Arcanum_BarrierGreen"),
	getIconSubPath("Arcanum_BarrierBlue"),
	getIconSubPath("Arcanum_BarrierViolet"),
	getIconSubPath("Arcanum_BarrierIndigo"),
	getIconSubPath("Arcanum_BarrierPink"),
	getIconSubPath("Arcanum_BarrierPrismatic"),
	getIconSubPath("Arcanum_BladeRed"),
	getIconSubPath("Arcanum_BladeOrange"),
	getIconSubPath("Arcanum_BladeYellow"),
	getIconSubPath("Arcanum_BladeJade"),
	getIconSubPath("Arcanum_BladeGreen"),
	getIconSubPath("Arcanum_BladeBlue"),
	getIconSubPath("Arcanum_BladeViolet"),
	getIconSubPath("Arcanum_BladeIndigo"),
	getIconSubPath("Arcanum_BladePink"),
	getIconSubPath("Arcanum_BladePrismatic"),
	getIconSubPath("Arcanum_BookRed"),
	getIconSubPath("Arcanum_BookOrange"),
	getIconSubPath("Arcanum_BookYellow"),
	getIconSubPath("Arcanum_BookJade"),
	getIconSubPath("Arcanum_BookGreen"),
	getIconSubPath("Arcanum_BookBlue"),
	getIconSubPath("Arcanum_BookViolet"),
	getIconSubPath("Arcanum_BookIndigo"),
	getIconSubPath("Arcanum_BookPink"),
	getIconSubPath("Arcanum_BookPrismatic"),
	getIconSubPath("Arcanum_FistRed"),
	getIconSubPath("Arcanum_FistOrange"),
	getIconSubPath("Arcanum_FistYellow"),
	getIconSubPath("Arcanum_FistJade"),
	getIconSubPath("Arcanum_FistGreen"),
	getIconSubPath("Arcanum_FistBlue"),
	getIconSubPath("Arcanum_FistViolet"),
	getIconSubPath("Arcanum_FistIndigo"),
	getIconSubPath("Arcanum_FistPink"),
	getIconSubPath("Arcanum_FistPrismatic"),
	getIconSubPath("Arcanum_GemRed"),
	getIconSubPath("Arcanum_GemOrange"),
	getIconSubPath("Arcanum_GemYellow"),
	getIconSubPath("Arcanum_GemJade"),
	getIconSubPath("Arcanum_GemGreen"),
	getIconSubPath("Arcanum_GemBlue"),
	getIconSubPath("Arcanum_GemViolet"),
	getIconSubPath("Arcanum_GemIndigo"),
	getIconSubPath("Arcanum_GemPink"),
	getIconSubPath("Arcanum_GemPrismatic"),
	getIconSubPath("Arcanum_MiasmaRed"),
	getIconSubPath("Arcanum_MiasmaOrange"),
	getIconSubPath("Arcanum_MiasmaYellow"),
	getIconSubPath("Arcanum_MiasmaJade"),
	getIconSubPath("Arcanum_MiasmaGreen"),
	getIconSubPath("Arcanum_MiasmaBlue"),
	getIconSubPath("Arcanum_MiasmaViolet"),
	getIconSubPath("Arcanum_MiasmaIndigo"),
	getIconSubPath("Arcanum_MiasmaPink"),
	getIconSubPath("Arcanum_MiasmaPrismatic"),
	getIconSubPath("Arcanum_OrbRed"),
	getIconSubPath("Arcanum_OrbOrange"),
	getIconSubPath("Arcanum_OrbYellow"),
	getIconSubPath("Arcanum_OrbJade"),
	getIconSubPath("Arcanum_OrbGreen"),
	getIconSubPath("Arcanum_OrbBlue"),
	getIconSubPath("Arcanum_OrbViolet"),
	getIconSubPath("Arcanum_OrbIndigo"),
	getIconSubPath("Arcanum_OrbPink"),
	getIconSubPath("Arcanum_OrbPrismatic"),
	getIconSubPath("Arcanum_ShowerRed"),
	getIconSubPath("Arcanum_ShowerOrange"),
	getIconSubPath("Arcanum_ShowerYellow"),
	getIconSubPath("Arcanum_ShowerJade"),
	getIconSubPath("Arcanum_ShowerGreen"),
	getIconSubPath("Arcanum_ShowerBlue"),
	getIconSubPath("Arcanum_ShowerViolet"),
	getIconSubPath("Arcanum_ShowerIndigo"),
	getIconSubPath("Arcanum_ShowerPink"),
	getIconSubPath("Arcanum_ShowerPrismatic"),
	getIconSubPath("Arcanum_SprintRed"),
	getIconSubPath("Arcanum_SprintOrange"),
	getIconSubPath("Arcanum_SprintYellow"),
	getIconSubPath("Arcanum_SprintJade"),
	getIconSubPath("Arcanum_SprintGreen"),
	getIconSubPath("Arcanum_SprintBlue"),
	getIconSubPath("Arcanum_SprintViolet"),
	getIconSubPath("Arcanum_SprintIndigo"),
	getIconSubPath("Arcanum_SprintPink"),
	getIconSubPath("Arcanum_SprintPrismatic"),
	getIconSubPath("Arcanum_XtraApertus"),
	getIconSubPath("Arcanum_XtraArcanowl"),
	getIconSubPath("Arcanum_XtraArcTea"),
	getIconSubPath("Arcanum_XtraArcWolf"),
	getIconSubPath("Arcanum_XtraArrowDown"),
	getIconSubPath("Arcanum_XtraArrowLeft"),
	getIconSubPath("Arcanum_XtraArrowRight"),
	getIconSubPath("Arcanum_XtraArrowUp"),
	getIconSubPath("Arcanum_XtraBooks"),
	getIconSubPath("Arcanum_XtraCastle"),
	getIconSubPath("Arcanum_XtraChest"),
	getIconSubPath("Arcanum_XtraCoffee"),
	getIconSubPath("Arcanum_XtraCompass"),
	getIconSubPath("Arcanum_XtraHelmet"),
	getIconSubPath("Arcanum_XtraPortal"),
	getIconSubPath("Arcanum_XtraSpeech"),
	getIconSubPath("sf_black_anomaly"),
	getIconSubPath("sf_black_armour"),
	getIconSubPath("sf_black_barrage"),
	getIconSubPath("sf_black_barrier"),
	getIconSubPath("sf_black_blade"),
	getIconSubPath("sf_black_book"),
	getIconSubPath("sf_black_burst"),
	getIconSubPath("sf_black_claw"),
	getIconSubPath("sf_black_clothes"),
	getIconSubPath("sf_black_core"),
	getIconSubPath("sf_black_crystal"),
	getIconSubPath("sf_black_dewdrop"),
	getIconSubPath("sf_black_dragonflight"),
	getIconSubPath("sf_black_dragonseye"),
	getIconSubPath("sf_black_eye"),
	getIconSubPath("sf_black_fist"),
	getIconSubPath("sf_black_flower"),
	getIconSubPath("sf_black_gem"),
	getIconSubPath("sf_black_head"),
	getIconSubPath("sf_black_hourglass"),
	getIconSubPath("sf_black_key"),
	getIconSubPath("sf_black_magic"),
	getIconSubPath("sf_black_map"),
	getIconSubPath("sf_black_miasma"),
	getIconSubPath("sf_black_necklace"),
	getIconSubPath("sf_black_needle"),
	getIconSubPath("sf_black_nexusoff"),
	getIconSubPath("sf_black_nexuson"),
	getIconSubPath("sf_black_orb"),
	getIconSubPath("sf_black_ore"),
	getIconSubPath("sf_black_pearl"),
	getIconSubPath("sf_black_petal"),
	getIconSubPath("sf_black_potion"),
	getIconSubPath("sf_black_power"),
	getIconSubPath("sf_black_questionmark"),
	getIconSubPath("sf_black_return"),
	getIconSubPath("sf_black_ring"),
	getIconSubPath("sf_black_scroll"),
	getIconSubPath("sf_black_shower"),
	getIconSubPath("sf_black_sigil"),
	getIconSubPath("sf_black_speed"),
	getIconSubPath("sf_black_sprint"),
	getIconSubPath("sf_black_starflower"),
	getIconSubPath("sf_black_sword"),
	getIconSubPath("sf_black_teleport"),
	getIconSubPath("sf_black_thread"),
	getIconSubPath("sf_black_time"),
	getIconSubPath("sf_black_tome"),
	getIconSubPath("sf_black_transform"),
	getIconSubPath("sf_blue_anomaly"),
	getIconSubPath("sf_blue_armour"),
	getIconSubPath("sf_blue_barrage"),
	getIconSubPath("sf_blue_barrier"),
	getIconSubPath("sf_blue_blade"),
	getIconSubPath("sf_blue_book"),
	getIconSubPath("sf_blue_burst"),
	getIconSubPath("sf_blue_claw"),
	getIconSubPath("sf_blue_clothes"),
	getIconSubPath("sf_blue_core"),
	getIconSubPath("sf_blue_crystal"),
	getIconSubPath("sf_blue_dewdrop"),
	getIconSubPath("sf_blue_dragonflight"),
	getIconSubPath("sf_blue_dragonseye"),
	getIconSubPath("sf_blue_eye"),
	getIconSubPath("sf_blue_fist"),
	getIconSubPath("sf_blue_flower"),
	getIconSubPath("sf_blue_gem"),
	getIconSubPath("sf_blue_head"),
	getIconSubPath("sf_blue_hourglass"),
	getIconSubPath("sf_blue_key"),
	getIconSubPath("sf_blue_magic"),
	getIconSubPath("sf_blue_map"),
	getIconSubPath("sf_blue_miasma"),
	getIconSubPath("sf_blue_necklace"),
	getIconSubPath("sf_blue_needle"),
	getIconSubPath("sf_blue_nexusoff"),
	getIconSubPath("sf_blue_nexuson"),
	getIconSubPath("sf_blue_orb"),
	getIconSubPath("sf_blue_ore"),
	getIconSubPath("sf_blue_pearl"),
	getIconSubPath("sf_blue_petal"),
	getIconSubPath("sf_blue_potion"),
	getIconSubPath("sf_blue_power"),
	getIconSubPath("sf_blue_questionmark"),
	getIconSubPath("sf_blue_return"),
	getIconSubPath("sf_blue_ring"),
	getIconSubPath("sf_blue_scroll"),
	getIconSubPath("sf_blue_shower"),
	getIconSubPath("sf_blue_sigil"),
	getIconSubPath("sf_blue_speed"),
	getIconSubPath("sf_blue_sprint"),
	getIconSubPath("sf_blue_starflower"),
	getIconSubPath("sf_blue_sword"),
	getIconSubPath("sf_blue_teleport"),
	getIconSubPath("sf_blue_thread"),
	getIconSubPath("sf_blue_time"),
	getIconSubPath("sf_blue_tome"),
	getIconSubPath("sf_blue_transform"),
	getIconSubPath("sf_bronze_anomaly"),
	getIconSubPath("sf_bronze_armour"),
	getIconSubPath("sf_bronze_barrage"),
	getIconSubPath("sf_bronze_barrier"),
	getIconSubPath("sf_bronze_blade"),
	getIconSubPath("sf_bronze_book"),
	getIconSubPath("sf_bronze_burst"),
	getIconSubPath("sf_bronze_claw"),
	getIconSubPath("sf_bronze_clothes"),
	getIconSubPath("sf_bronze_core"),
	getIconSubPath("sf_bronze_crystal"),
	getIconSubPath("sf_bronze_dewdrop"),
	getIconSubPath("sf_bronze_dragonflight"),
	getIconSubPath("sf_bronze_dragonseye"),
	getIconSubPath("sf_bronze_eye"),
	getIconSubPath("sf_bronze_fist"),
	getIconSubPath("sf_bronze_flower"),
	getIconSubPath("sf_bronze_gem"),
	getIconSubPath("sf_bronze_head"),
	getIconSubPath("sf_bronze_hourglass"),
	getIconSubPath("sf_bronze_key"),
	getIconSubPath("sf_bronze_magic"),
	getIconSubPath("sf_bronze_map"),
	getIconSubPath("sf_bronze_miasma"),
	getIconSubPath("sf_bronze_necklace"),
	getIconSubPath("sf_bronze_needle"),
	getIconSubPath("sf_bronze_nexusoff"),
	getIconSubPath("sf_bronze_nexuson"),
	getIconSubPath("sf_bronze_orb"),
	getIconSubPath("sf_bronze_ore"),
	getIconSubPath("sf_bronze_pearl"),
	getIconSubPath("sf_bronze_petal"),
	getIconSubPath("sf_bronze_potion"),
	getIconSubPath("sf_bronze_power"),
	getIconSubPath("sf_bronze_questionmark"),
	getIconSubPath("sf_bronze_return"),
	getIconSubPath("sf_bronze_ring"),
	getIconSubPath("sf_bronze_scroll"),
	getIconSubPath("sf_bronze_shower"),
	getIconSubPath("sf_bronze_sigil"),
	getIconSubPath("sf_bronze_speed"),
	getIconSubPath("sf_bronze_sprint"),
	getIconSubPath("sf_bronze_starflower"),
	getIconSubPath("sf_bronze_sword"),
	getIconSubPath("sf_bronze_teleport"),
	getIconSubPath("sf_bronze_thread"),
	getIconSubPath("sf_bronze_time"),
	getIconSubPath("sf_bronze_tome"),
	getIconSubPath("sf_bronze_transform"),
	getIconSubPath("sf_fire_anomaly"),
	getIconSubPath("sf_fire_armour"),
	getIconSubPath("sf_fire_barrage"),
	getIconSubPath("sf_fire_barrier"),
	getIconSubPath("sf_fire_blade"),
	getIconSubPath("sf_fire_book"),
	getIconSubPath("sf_fire_burst"),
	getIconSubPath("sf_fire_claw"),
	getIconSubPath("sf_fire_clothes"),
	getIconSubPath("sf_fire_core"),
	getIconSubPath("sf_fire_crystal"),
	getIconSubPath("sf_fire_dewdrop"),
	getIconSubPath("sf_fire_dragonflight"),
	getIconSubPath("sf_fire_dragonseye"),
	getIconSubPath("sf_fire_eye"),
	getIconSubPath("sf_fire_fist"),
	getIconSubPath("sf_fire_flower"),
	getIconSubPath("sf_fire_gem"),
	getIconSubPath("sf_fire_head"),
	getIconSubPath("sf_fire_hourglass"),
	getIconSubPath("sf_fire_key"),
	getIconSubPath("sf_fire_magic"),
	getIconSubPath("sf_fire_map"),
	getIconSubPath("sf_fire_miasma"),
	getIconSubPath("sf_fire_necklace"),
	getIconSubPath("sf_fire_needle"),
	getIconSubPath("sf_fire_nexusoff"),
	getIconSubPath("sf_fire_nexuson"),
	getIconSubPath("sf_fire_orb"),
	getIconSubPath("sf_fire_ore"),
	getIconSubPath("sf_fire_pearl"),
	getIconSubPath("sf_fire_petal"),
	getIconSubPath("sf_fire_potion"),
	getIconSubPath("sf_fire_power"),
	getIconSubPath("sf_fire_questionmark"),
	getIconSubPath("sf_fire_return"),
	getIconSubPath("sf_fire_ring"),
	getIconSubPath("sf_fire_scroll"),
	getIconSubPath("sf_fire_shower"),
	getIconSubPath("sf_fire_sigil"),
	getIconSubPath("sf_fire_speed"),
	getIconSubPath("sf_fire_sprint"),
	getIconSubPath("sf_fire_starflower"),
	getIconSubPath("sf_fire_sword"),
	getIconSubPath("sf_fire_teleport"),
	getIconSubPath("sf_fire_thread"),
	getIconSubPath("sf_fire_time"),
	getIconSubPath("sf_fire_tome"),
	getIconSubPath("sf_fire_transform"),
	getIconSubPath("sf_green_anomaly"),
	getIconSubPath("sf_green_armour"),
	getIconSubPath("sf_green_barrage"),
	getIconSubPath("sf_green_barrier"),
	getIconSubPath("sf_green_blade"),
	getIconSubPath("sf_green_book"),
	getIconSubPath("sf_green_burst"),
	getIconSubPath("sf_green_claw"),
	getIconSubPath("sf_green_clothes"),
	getIconSubPath("sf_green_core"),
	getIconSubPath("sf_green_crystal"),
	getIconSubPath("sf_green_dewdrop"),
	getIconSubPath("sf_green_dragonflight"),
	getIconSubPath("sf_green_dragonseye"),
	getIconSubPath("sf_green_eye"),
	getIconSubPath("sf_green_fist"),
	getIconSubPath("sf_green_flower"),
	getIconSubPath("sf_green_gem"),
	getIconSubPath("sf_green_head"),
	getIconSubPath("sf_green_hourglass"),
	getIconSubPath("sf_green_key"),
	getIconSubPath("sf_green_magic"),
	getIconSubPath("sf_green_map"),
	getIconSubPath("sf_green_miasma"),
	getIconSubPath("sf_green_necklace"),
	getIconSubPath("sf_green_needle"),
	getIconSubPath("sf_green_nexusoff"),
	getIconSubPath("sf_green_nexuson"),
	getIconSubPath("sf_green_orb"),
	getIconSubPath("sf_green_ore"),
	getIconSubPath("sf_green_pearl"),
	getIconSubPath("sf_green_petal"),
	getIconSubPath("sf_green_potion"),
	getIconSubPath("sf_green_power"),
	getIconSubPath("sf_green_questionmark"),
	getIconSubPath("sf_green_return"),
	getIconSubPath("sf_green_ring"),
	getIconSubPath("sf_green_scroll"),
	getIconSubPath("sf_green_shower"),
	getIconSubPath("sf_green_sigil"),
	getIconSubPath("sf_green_speed"),
	getIconSubPath("sf_green_sprint"),
	getIconSubPath("sf_green_starflower"),
	getIconSubPath("sf_green_sword"),
	getIconSubPath("sf_green_teleport"),
	getIconSubPath("sf_green_thread"),
	getIconSubPath("sf_green_time"),
	getIconSubPath("sf_green_tome"),
	getIconSubPath("sf_green_transform"),
	getIconSubPath("sf_inf_anomaly"),
	getIconSubPath("sf_inf_armour"),
	getIconSubPath("sf_inf_barrage"),
	getIconSubPath("sf_inf_barrier"),
	getIconSubPath("sf_inf_blade"),
	getIconSubPath("sf_inf_book"),
	getIconSubPath("sf_inf_burst"),
	getIconSubPath("sf_inf_claw"),
	getIconSubPath("sf_inf_clothes"),
	getIconSubPath("sf_inf_core"),
	getIconSubPath("sf_inf_crystal"),
	getIconSubPath("sf_inf_dewdrop"),
	getIconSubPath("sf_inf_dragonflight"),
	getIconSubPath("sf_inf_dragonseye"),
	getIconSubPath("sf_inf_eye"),
	getIconSubPath("sf_inf_fist"),
	getIconSubPath("sf_inf_flower"),
	getIconSubPath("sf_inf_gem"),
	getIconSubPath("sf_inf_head"),
	getIconSubPath("sf_inf_hourglass"),
	getIconSubPath("sf_inf_key"),
	getIconSubPath("sf_inf_magic"),
	getIconSubPath("sf_inf_map"),
	getIconSubPath("sf_inf_miasma"),
	getIconSubPath("sf_inf_necklace"),
	getIconSubPath("sf_inf_needle"),
	getIconSubPath("sf_inf_nexusoff"),
	getIconSubPath("sf_inf_nexuson"),
	getIconSubPath("sf_inf_orb"),
	getIconSubPath("sf_inf_ore"),
	getIconSubPath("sf_inf_pearl"),
	getIconSubPath("sf_inf_petal"),
	getIconSubPath("sf_inf_potion"),
	getIconSubPath("sf_inf_power"),
	getIconSubPath("sf_inf_questionmark"),
	getIconSubPath("sf_inf_return"),
	getIconSubPath("sf_inf_ring"),
	getIconSubPath("sf_inf_scroll"),
	getIconSubPath("sf_inf_shower"),
	getIconSubPath("sf_inf_sigil"),
	getIconSubPath("sf_inf_speed"),
	getIconSubPath("sf_inf_sprint"),
	getIconSubPath("sf_inf_starflower"),
	getIconSubPath("sf_inf_sword"),
	getIconSubPath("sf_inf_teleport"),
	getIconSubPath("sf_inf_thread"),
	getIconSubPath("sf_inf_time"),
	getIconSubPath("sf_inf_tome"),
	getIconSubPath("sf_inf_transform"),
	getIconSubPath("sf_red_anomaly"),
	getIconSubPath("sf_red_armour"),
	getIconSubPath("sf_red_barrage"),
	getIconSubPath("sf_red_barrier"),
	getIconSubPath("sf_red_blade"),
	getIconSubPath("sf_red_book"),
	getIconSubPath("sf_red_burst"),
	getIconSubPath("sf_red_claw"),
	getIconSubPath("sf_red_clothes"),
	getIconSubPath("sf_red_core"),
	getIconSubPath("sf_red_crystal"),
	getIconSubPath("sf_red_dewdrop"),
	getIconSubPath("sf_red_dragonflight"),
	getIconSubPath("sf_red_dragonseye"),
	getIconSubPath("sf_red_eye"),
	getIconSubPath("sf_red_fist"),
	getIconSubPath("sf_red_flower"),
	getIconSubPath("sf_red_gem"),
	getIconSubPath("sf_red_head"),
	getIconSubPath("sf_red_hourglass"),
	getIconSubPath("sf_red_key"),
	getIconSubPath("sf_red_magic"),
	getIconSubPath("sf_red_map"),
	getIconSubPath("sf_red_miasma"),
	getIconSubPath("sf_red_necklace"),
	getIconSubPath("sf_red_needle"),
	getIconSubPath("sf_red_nexusoff"),
	getIconSubPath("sf_red_nexuson"),
	getIconSubPath("sf_red_orb"),
	getIconSubPath("sf_red_ore"),
	getIconSubPath("sf_red_pearl"),
	getIconSubPath("sf_red_petal"),
	getIconSubPath("sf_red_potion"),
	getIconSubPath("sf_red_power"),
	getIconSubPath("sf_red_questionmark"),
	getIconSubPath("sf_red_return"),
	getIconSubPath("sf_red_ring"),
	getIconSubPath("sf_red_scroll"),
	getIconSubPath("sf_red_shower"),
	getIconSubPath("sf_red_sigil"),
	getIconSubPath("sf_red_speed"),
	getIconSubPath("sf_red_sprint"),
	getIconSubPath("sf_red_starflower"),
	getIconSubPath("sf_red_sword"),
	getIconSubPath("sf_red_teleport"),
	getIconSubPath("sf_red_thread"),
	getIconSubPath("sf_red_time"),
	getIconSubPath("sf_red_tome"),
	getIconSubPath("sf_red_transform"),

	-- Halloween - SF Matching
	getIconSubPath("halloween", "halloween_anomaly"),
	getIconSubPath("halloween", "halloween_armour"),
	getIconSubPath("halloween", "halloween_barrage"),
	getIconSubPath("halloween", "halloween_barrier"),
	getIconSubPath("halloween", "halloween_blade"),
	getIconSubPath("halloween", "halloween_book"),
	getIconSubPath("halloween", "halloween_burst"),
	getIconSubPath("halloween", "halloween_claw"),
	getIconSubPath("halloween", "halloween_clothes"),
	getIconSubPath("halloween", "halloween_core"),
	getIconSubPath("halloween", "halloween_crystal"),
	getIconSubPath("halloween", "halloween_dewdrop"),
	getIconSubPath("halloween", "halloween_dragonflight"),
	getIconSubPath("halloween", "halloween_dragonseye"),
	getIconSubPath("halloween", "halloween_eye"),
	getIconSubPath("halloween", "halloween_fist"),
	getIconSubPath("halloween", "halloween_flower"),
	getIconSubPath("halloween", "halloween_gem"),
	getIconSubPath("halloween", "halloween_head"),
	getIconSubPath("halloween", "halloween_hourglass"),
	getIconSubPath("halloween", "halloween_key"),
	getIconSubPath("halloween", "halloween_magic"),
	getIconSubPath("halloween", "halloween_map"),
	getIconSubPath("halloween", "halloween_miasma"),
	getIconSubPath("halloween", "halloween_necklace"),
	getIconSubPath("halloween", "halloween_needle"),
	getIconSubPath("halloween", "halloween_nexusoff"),
	getIconSubPath("halloween", "halloween_nexuson"),
	getIconSubPath("halloween", "halloween_orb"),
	getIconSubPath("halloween", "halloween_ore"),
	getIconSubPath("halloween", "halloween_pearl"),
	getIconSubPath("halloween", "halloween_petal"),
	getIconSubPath("halloween", "halloween_potion"),
	getIconSubPath("halloween", "halloween_power"),
	getIconSubPath("halloween", "halloween_questionmark"),
	getIconSubPath("halloween", "halloween_return"),
	getIconSubPath("halloween", "halloween_ring"),
	getIconSubPath("halloween", "halloween_scroll"),
	getIconSubPath("halloween", "halloween_shower"),
	getIconSubPath("halloween", "halloween_sigil"),
	getIconSubPath("halloween", "halloween_speed"),
	getIconSubPath("halloween", "halloween_sprint"),
	getIconSubPath("halloween", "halloween_starflower"),
	getIconSubPath("halloween", "halloween_sword"),
	getIconSubPath("halloween", "halloween_teleport"),
	getIconSubPath("halloween", "halloween_thread"),
	getIconSubPath("halloween", "halloween_time"),
	getIconSubPath("halloween", "halloween_tome"),
	getIconSubPath("halloween", "halloween_transform"),

	-- Halloween - Tricks & Treats!
	getIconSubPath("halloween", "halloween_spectral_boiledsweets"),
	getIconSubPath("halloween", "halloween_spectral_caramel"),
	getIconSubPath("halloween", "halloween_spectral_cupcake"),
	getIconSubPath("halloween", "halloween_spectral_pumpkin"),
	getIconSubPath("halloween", "halloween_spectral_spellbookopen"),

	getIconSubPath("halloween", "halloween_caramel"),
	getIconSubPath("halloween", "halloween_chocolatemuffin"),
	getIconSubPath("halloween", "halloween_crystalball"),
	getIconSubPath("halloween", "halloween_donutsprinkles"),
	getIconSubPath("halloween", "halloween_epsinomicon"),
	getIconSubPath("halloween", "halloween_gnashingteeth"),
	getIconSubPath("halloween", "halloween_hallowedcandle"),
	getIconSubPath("halloween", "halloween_hardcandy"),
	getIconSubPath("halloween", "halloween_lollypop"),
	getIconSubPath("halloween", "halloween_magicbeans"),
	getIconSubPath("halloween", "halloween_necromanticorb"),
	getIconSubPath("halloween", "halloween_poisonapple"),
	getIconSubPath("halloween", "halloween_pumpkin"),
	getIconSubPath("halloween", "halloween_risenghoul"),
	getIconSubPath("halloween", "halloween_shatteredmask"),
	getIconSubPath("halloween", "halloween_sheetghost"),
	getIconSubPath("halloween", "halloween_spider"),
	getIconSubPath("halloween", "halloween_spiderweb"),
	getIconSubPath("halloween", "halloween_swirlycandy"),
	getIconSubPath("halloween", "halloween_toffeeapple"),
	getIconSubPath("halloween", "halloween_tombstone"),
	getIconSubPath("halloween", "halloween_treatbag"),
	getIconSubPath("halloween", "halloween_vial"),

	-- what's next?

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
