extends Node

# =====================================================
# SEGMENT UPGRADE DB
# Las mejoras ya no están hardcodeadas aquí.
# Cada mejora es un archivo .tres en res://resources/upgrades/
#
# PARA AÑADIR UNA MEJORA NUEVA:
#   1. Clic derecho en FileSystem → New Resource → UpgradeResource
#   2. Rellena los campos en el Inspector
#   3. Guarda como res://resources/upgrades/nombre.tres
#   4. Añade la ruta al array UPGRADE_PATHS aquí abajo
# =====================================================

enum Rarity { COMMON, UNCOMMON, EPIC, LEGENDARY }

const UPGRADE_PATHS: Array[String] = [
	"res://resources/upgrades/heal_segment.tres",
	"res://resources/upgrades/speed_segment.tres",
	"res://resources/upgrades/armor_segment.tres",
	"res://resources/upgrades/xp_boost.tres",
	"res://resources/upgrades/turret.tres",
	"res://resources/upgrades/wraparound.tres",
	"res://resources/upgrades/shield.tres",
	"res://resources/upgrades/ghost_segment.tres",
]

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

const COMMON_REQUIRED_FOR_UNCOMMON:  int = 3
const COMMON_REQUIRED_FOR_EPIC:      int = 3
const COMMON_REQUIRED_FOR_LEGENDARY: int = 3

# Array de dicts — mismo formato que antes para no romper PoolSelectScreen ni Snake
var ALL_UPGRADES: Array = []

var active_pool: Array = []

func _ready():
	_load_upgrades()

func _load_upgrades():
	ALL_UPGRADES.clear()
	for path in UPGRADE_PATHS:
		var res: UpgradeResource = load(path)
		if res == null:
			push_error("SegmentUpgradeDB: no se pudo cargar " + path)
			continue
		ALL_UPGRADES.append(_resource_to_dict(res))

func _resource_to_dict(res: UpgradeResource) -> Dictionary:
	return {
		"id":            res.id,
		"name_key":      res.name_key,
		"desc_key":      res.desc_key,
		"rarity":        res.rarity,
		"icon":          res.icon,
		"segment_color": res.segment_color,
		"effect_key":    res.effect_key,
	}

# ─────────────────────────────────────────────────────
# Pool activo
# ─────────────────────────────────────────────────────
func set_active_pool(pool: Array):
	active_pool = pool.duplicate()

func get_active_pool() -> Array:
	return active_pool

func count_commons_in_pool() -> int:
	var c = 0
	for u in active_pool:
		if u["rarity"] == Rarity.COMMON:
			c += 1
	return c

# ─────────────────────────────────────────────────────
# Pick 2 aleatorio ponderado del pool activo
# ─────────────────────────────────────────────────────
func pick_two_random() -> Array:
	var pool = active_pool if not active_pool.is_empty() else ALL_UPGRADES
	var remaining = pool.duplicate()
	var picked = []
	for _i in range(2):
		if remaining.is_empty():
			break
		var total = 0
		for u in remaining:
			total += RARITY_WEIGHTS[u["rarity"]]
		var roll = randi() % max(total, 1)
		var cum  = 0
		for j in range(remaining.size()):
			cum += RARITY_WEIGHTS[remaining[j]["rarity"]]
			if roll < cum:
				picked.append(remaining[j])
				remaining.remove_at(j)
				break
	while picked.size() < 2:
		picked.append(pool[randi() % pool.size()])
	return picked

# ─────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────
func get_rarity_color(rarity: int) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

func get_rarity_name(rarity: int) -> String:
	return Loc.t(RARITY_KEYS.get(rarity, "rarity_common"))

func get_upgrade_by_id(id: String) -> Dictionary:
	for u in ALL_UPGRADES:
		if u["id"] == id:
			return u
	return {}
