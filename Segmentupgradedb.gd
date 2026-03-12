extends Node

# =====================================================
# SISTEMA DE MEJORAS DE SEGMENTO
# Cada cuadrícula nueva al subir nivel puede tener una
# =====================================================

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

# Colores de rareza
const RARITY_COLORS = {
	Rarity.COMMON:    Color(0.7, 0.7, 0.7),      # Gris
	Rarity.UNCOMMON:  Color(0.2, 0.8, 0.2),      # Verde
	Rarity.RARE:      Color(0.2, 0.4, 1.0),      # Azul
	Rarity.LEGENDARY: Color(1.0, 0.6, 0.05),     # Naranja dorado
}

const RARITY_NAMES = {
	Rarity.COMMON:    "Común",
	Rarity.UNCOMMON:  "Poco común",
	Rarity.RARE:      "Rara",
	Rarity.LEGENDARY: "Legendaria",
}

# Pesos de aparición por rareza (mayor = más probable)
const RARITY_WEIGHTS = {
	Rarity.COMMON:    60,
	Rarity.UNCOMMON:  25,
	Rarity.RARE:      12,
	Rarity.LEGENDARY: 3,
}

# Definición de todas las mejoras de segmento disponibles
# Cada mejora tiene: id, name, description, rarity, icon, segment_color, effect_key
const ALL_UPGRADES = [
	{
		"id": "turret",
		"name": "Torreta",
		"description": "Este segmento dispara\nal enemigo más cercano\nperiódicamente.",
		"rarity": Rarity.UNCOMMON,
		"icon": "🔫",
		"segment_color": Color(0.9, 0.3, 0.1),
		"effect_key": "turret",
	},
	{
		"id": "wraparound",
		"name": "Portal",
		"description": "Al chocar con una pared,\napareces en el lado\nopuesto de la arena.",
		"rarity": Rarity.RARE,
		"icon": "🌀",
		"segment_color": Color(0.3, 0.8, 1.0),
		"effect_key": "wraparound",
	},
	{
		"id": "shield",
		"name": "Escudo",
		"description": "Las balas que impacten\nen este segmento no\ncausan daño.",
		"rarity": Rarity.RARE,
		"icon": "🛡",
		"segment_color": Color(0.9, 0.85, 0.1),
		"effect_key": "shield",
	},
]

# Devuelve 2 mejoras aleatorias únicas ponderadas por rareza
func pick_two_random() -> Array:
	var pool = ALL_UPGRADES.duplicate()
	pool.shuffle()
	
	# Weighted random pick
	var picked = []
	var remaining = pool.duplicate()
	
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
	
	# Si solo hay 1 tipo, duplicamos
	while picked.size() < 2:
		picked.append(ALL_UPGRADES[randi() % ALL_UPGRADES.size()])
	
	return picked

func get_rarity_color(rarity: int) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

func get_rarity_name(rarity: int) -> String:
	return RARITY_NAMES.get(rarity, "?")