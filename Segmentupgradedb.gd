extends Node

# =====================================================
# SEGMENT UPGRADE DB
# Añadir mejoras nuevas: copiar una entrada de ALL_UPGRADES.
# Rarezas disponibles: COMMON, UNCOMMON, EPIC, LEGENDARY
# =====================================================

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

# Peso para pick_two_random — sólo afecta a mejoras dentro del pool activo
const RARITY_WEIGHTS = {
	Rarity.COMMON:    60,
	Rarity.UNCOMMON:  25,
	Rarity.EPIC:      12,
	Rarity.LEGENDARY: 3,
}

# Regla de composición del pool:
# Para añadir mejoras de rareza superior necesitas mínimo este número de COMMON en el pool
const COMMON_REQUIRED_FOR_UNCOMMON: int = 3
const COMMON_REQUIRED_FOR_EPIC:     int = 3
const COMMON_REQUIRED_FOR_LEGENDARY:int = 3

const ALL_UPGRADES: Array = [
	# ── COMMON ──────────────────────────────────────
	{
		"id": "heal_segment",
		"name_key": "ability_heal_name",
		"desc_key":  "ability_heal_desc",
		"rarity": Rarity.COMMON,
		"icon": "💊",
		"segment_color": Color(0.2, 0.85, 0.45),
		"effect_key": "heal_segment",
	},
	{
		"id": "speed_segment",
		"name_key": "ability_speed_name",
		"desc_key":  "ability_speed_desc",
		"rarity": Rarity.COMMON,
		"icon": "⚡",
		"segment_color": Color(1.0, 0.9, 0.1),
		"effect_key": "speed_segment",
	},
	{
		"id": "armor_segment",
		"name_key": "ability_armor_name",
		"desc_key":  "ability_armor_desc",
		"rarity": Rarity.COMMON,
		"icon": "🛡",
		"segment_color": Color(0.55, 0.65, 0.75),
		"effect_key": "armor_segment",
	},
	{
		"id": "xp_boost",
		"name_key": "ability_xp_name",
		"desc_key":  "ability_xp_desc",
		"rarity": Rarity.COMMON,
		"icon": "✦",
		"segment_color": Color(0.3, 0.5, 1.0),
		"effect_key": "xp_boost",
	},
	# ── UNCOMMON ────────────────────────────────────
	{
		"id": "turret",
		"name_key": "ability_turret_name",
		"desc_key":  "ability_turret_desc",
		"rarity": Rarity.UNCOMMON,
		"icon": "🔫",
		"segment_color": Color(0.9, 0.3, 0.1),
		"effect_key": "turret",
	},
	# ── EPIC ────────────────────────────────────────
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
	# ── LEGENDARY ───────────────────────────────────
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

# ─────────────────────────────────────────────────────
# Pool activo — definido por el jugador en PoolSelectScreen
# ─────────────────────────────────────────────────────
var active_pool: Array = []   # Array de upgrade dicts

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

func can_add_to_pool(upg: Dictionary) -> bool:
	var r = upg["rarity"]
	if r == Rarity.COMMON:
		return true
	var commons = count_commons_in_pool()
	if r == Rarity.UNCOMMON:
		return commons >= COMMON_REQUIRED_FOR_UNCOMMON
	if r == Rarity.EPIC:
		return commons >= COMMON_REQUIRED_FOR_EPIC
	if r == Rarity.LEGENDARY:
		return commons >= COMMON_REQUIRED_FOR_LEGENDARY
	return false

# ─────────────────────────────────────────────────────
# Pick 2 del pool activo (para la pantalla de level up)
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

func get_rarity_color(rarity: int) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

func get_rarity_name(rarity: int) -> String:
	return Loc.t(RARITY_KEYS.get(rarity, "rarity_common"))

func get_upgrade_by_id(id: String) -> Dictionary:
	for u in ALL_UPGRADES:
		if u["id"] == id:
			return u
	return {}