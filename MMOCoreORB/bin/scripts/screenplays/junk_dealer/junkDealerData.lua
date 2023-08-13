junkWareType = {
	armor = 1,
	weapon = 2,
	uniform = 3,
	furniture = 4,
	container = 5,
	terminal = 6,
	installation = 7,
	hireling = 8,
	schematic = 9,
}


genericJunkData = {

    junkWeaponsList = {
        'rifle_dlt20','pistol_d18','carbine_dh17'
    },
    
    junkWeapons = {
        rifle_dlt20 = { index=0, type=junkWareType.weapon, display="@weapon_name:rifle_dlt20", item="object/weapon/ranged/rifle/rifle_dlt20.iff", cost=5000},
        pistol_d18 = { index=1, type=junkWareType.weapon, display="@weapon_name:pistol_d18", item="object/weapon/ranged/pistol/pistol_d18.iff", cost=5000},
        carbine_dh17 = { index=2, type=junkWareType.weapon, display="@weapon_name:carbine_dh17", item="object/weapon/ranged/carbine/carbine_dh17", cost=5000},
    },

    junkArmorList = {
        'armor_bone_s01_chest_plate', 'armor_bone_s01_helmet', 'armor_bone_s01_leggings'
    },

    junkArmor = {
        armor_bone_s01_chest_plate = { index=0, type=junkWareType.armor, display="@wearables_name:armor_bone_s01_chest_plate", item="object/tangible/wearables/armor/bone/armor_bone_s01_chest_plate.iff",cost=5000},
        armor_bone_s01_helmet = { index=1, type=junkWareType.armor, display="@wearables_name:armor_bone_s01_helmet", item="object/tangible/wearables/armor/bone/armor_bone_s01_helmet.iff",cost=5000},
        armor_bone_s01_leggings = { index=2, type=junkWareType.armor, display="@wearables_name:armor_bone_s01_leggings", item="object/tangible/wearables/armor/bone/armor_bone_s01_leggings.iff",cost=5000},
    },

    hirelingsList = {
        --'merc_brawler_novice'
        'boar_wolf_be',
    },

    hirelings = {
        --merc_brawler_novice = { type=junkWareType.hireling, display="Mercenary Contract: Novice Brawler ", item="object/intangible/pet/pet_control.iff", controlledObjectTemplate="merc_brawler_novice", cost=5000},
        boar_wolf_be = { type=junkWareType.hireling, display="@mob/creature_names:bio_engineered_boar_wolf", item="object/intangible/pet/pet_control.iff", controlledObjectTemplate="boar_wolf_hue", cost=5000},
    },
}

armsJunkData = {

    junkWeapons = {
        carbine_laser = { index=0, type=junkWareType.weapon, display="@weapon_name:carbine_laser", item="object/weapon/ranged/carbine/carbine_laser.iff", cost=1500},
    },

    junkArmor = {
        armor_marine_backpack = { index=0, type=junkWareType.armor, display="@wearables_name:armor_marine_backpack", item="object/tangible/wearables/armor/marine/armor_marine_backpack.iff",cost=1500},
    },
}