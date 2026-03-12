extends Node

# === SISTEMA DE EVOLUCIÓN ===
# Gestiona las mejoras equipables antes de cada partida

const MAX_EVOLUTION_POINTS: int = 100

# Definición de todas las mejoras disponibles
const UPGRADES = {
	"armor": {
		"id": "armor",
		"name": "Escamas Reforzadas",
		"description": "Reduce el daño recibido un 20%.\nDefensa por porcentaje contra ataques básicos.",
		"cost": 50,
		"icon": "🛡️",
		"color": Color(0.3, 0.6, 1.0),
	},
	"speed_boost": {
		"id": "speed_boost",
		"name": "Adrenalina",
		"description": "La serpiente empieza la partida\ncon mayor velocidad de movimiento.",
		"cost": 50,
		"icon": "⚡",
		"color": Color(1.0, 0.85, 0.1),
	},
	"ghost_body": {
		"id": "ghost_body",
		"name": "Cuerpo Fantasma",
		"description": "Puedes atravesar tu propio\ncuerpo sin morir.",
		"cost": 50,
		"icon": "👻",
		"color": Color(0.7, 0.4, 1.0),
	},
}

# Estado actual: qué mejoras están equipadas
var equipped: Dictionary = {}  # id -> bool
var evolution_points_used: int = 0

func _ready():
	# Inicializar todas como no equipadas
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
		return true  # ya equipada, puede desequiparse
	var cost = UPGRADES[upgrade_id]["cost"]
	return get_points_remaining() >= cost

func toggle_upgrade(upgrade_id: String) -> bool:
	if not UPGRADES.has(upgrade_id):
		return false
	
	if equipped[upgrade_id]:
		# Desequipar siempre es posible
		equipped[upgrade_id] = false
		return true
	else:
		# Equipar solo si hay puntos
		if can_equip(upgrade_id):
			equipped[upgrade_id] = true
			return true
		return false

func is_equipped(upgrade_id: String) -> bool:
	return equipped.get(upgrade_id, false)

# Getters de cada mejora para usar en Snake.gd
func get_defense_percent() -> float:
	if is_equipped("armor"):
		return 0.20  # 20% reducción
	return 0.0

func has_speed_boost() -> bool:
	return is_equipped("speed_boost")

func has_ghost_body() -> bool:
	return is_equipped("ghost_body")
