extends Node

enum Rarity { COMMON, UNCOMMON, EPIC, LEGENDARY }

const RARITY_COLORS = {
	Rarity.COMMON:    Color(0.65, 0.65, 0.65),
	Rarity.UNCOMMON:  Color(0.2,  0.5,  1.0),
	Rarity.EPIC:      Color(0.65, 0.15, 0.9),
	Rarity.LEGENDARY: Color(1.0,  0.55, 0.05),
}

const RARITY_KEYS = {
	Rarity.COMMON:    "rarity_common",
	Rarity.UNCOMMON:  "rarity_uncommon",
	Rarity.EPIC:      "rarity_epic",
	Rarity.LEGENDARY: "rarity_legendary",
}

const RARITY_WEIGHTS = {
	Rarity.COMMON:    60,
	Rarity.UNCOMMON:  25,
	Rarity.EPIC:      12,
	Rarity.LEGENDARY: 3,
}

const ALL_UPGRADES = [
	{
		"id": "turret",
		"name_key": "ability_turret_name",
		"desc_key":  "ability_turret_desc",
		"rarity": Rarity.UNCOMMON,
		"icon": "🔫",
		"segment_color": Color(0.9, 0.3, 0.1),
		"effect_key": "turret",
	},
	{
		"id": "wraparound",
		"name_key": "ability_wrap_name",
		"desc_key":  "ability_wrap_desc",
		"rarity": Rarity.EPIC,
		"icon": "🌀",
		"segment_color": Color(0.3, 0.8, 1.0),
		"effect_key": "wraparound",
	},
	{
		"id": "shield",
		"name_key": "ability_shield_name",
		"desc_key":  "ability_shield_desc",
		"rarity": Rarity.EPIC,
		"icon": "🛡",
		"segment_color": Color(0.9, 0.85, 0.1),
		"effect_key": "shield",
	},
	{
		"id": "ghost_segment",
		"name_key": "ability_ghost_name",
		"desc_key":  "ability_ghost_desc",
		"rarity": Rarity.LEGENDARY,
		"icon": "👻",
		"segment_color": Color(0.55, 0.2, 0.85),
		"effect_key": "ghost_segment",
	},
]

func pick_two_random() -> Array:
	var remaining = ALL_UPGRADES.duplicate()
	var picked = []
	for _i in range(2):
		if remaining.is_empty():
			break
		var total_weight = 0
		for upg in remaining:
			total_weight += RARITY_WEIGHTS[upg["rarity"]]
		var roll = randi() % total_weight
		var cumulative = 0
		for j in range(remaining.size()):
			cumulative += RARITY_WEIGHTS[remaining[j]["rarity"]]
			if roll < cumulative:
				picked.append(remaining[j])
				remaining.remove_at(j)
				break
	while picked.size() < 2:
		picked.append(ALL_UPGRADES[randi() % ALL_UPGRADES.size()])
	return picked

func get_rarity_color(rarity: int) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

func get_rarity_name(rarity: int) -> String:
	return Loc.t(RARITY_KEYS.get(rarity, "rarity_common"))