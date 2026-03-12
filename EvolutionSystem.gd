extends Node

const MAX_EVOLUTION_POINTS: int = 100

# Traits use Loc keys for name/description
const UPGRADES = {
	"armor": {
		"id": "armor",
		"name_key": "trait_armor_name",
		"desc_key":  "trait_armor_desc",
		"cost": 50,
		"icon": "🛡️",
		"color": Color(0.3, 0.6, 1.0),
	},
	"speed_boost": {
		"id": "speed_boost",
		"name_key": "trait_speed_name",
		"desc_key":  "trait_speed_desc",
		"cost": 50,
		"icon": "⚡",
		"color": Color(1.0, 0.85, 0.1),
	},
}

var equipped: Dictionary = {}

func _ready():
	for key in UPGRADES:
		equipped[key] = false

func get_points_used() -> int:
	var total = 0
	for key in equipped:
		if equipped[key]:
			total += UPGRADES[key]["cost"]
	return total

func get_points_remaining() -> int:
	return MAX_EVOLUTION_POINTS - get_points_used()

func can_equip(upgrade_id: String) -> bool:
	if not UPGRADES.has(upgrade_id):
		return false
	if equipped[upgrade_id]:
		return true
	return get_points_remaining() >= UPGRADES[upgrade_id]["cost"]

func toggle_upgrade(upgrade_id: String) -> bool:
	if not UPGRADES.has(upgrade_id):
		return false
	if equipped[upgrade_id]:
		equipped[upgrade_id] = false
		return true
	if can_equip(upgrade_id):
		equipped[upgrade_id] = true
		return true
	return false

func is_equipped(upgrade_id: String) -> bool:
	return equipped.get(upgrade_id, false)

func get_defense_percent() -> float:
	return 0.20 if is_equipped("armor") else 0.0

func has_speed_boost() -> bool:
	return is_equipped("speed_boost")

func has_ghost_body() -> bool:
	return false