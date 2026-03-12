extends Node

# =====================================================
# SISTEMA DE MEJORAS DE SEGMENTO
# Rarezas: Común | Poco común | Épico | Legendario
# Colores:  Gris  |   Azul     | Morado | Naranja
# =====================================================

enum Rarity { COMMON, UNCOMMON, EPIC, LEGENDARY }

const RARITY_COLORS = {
	Rarity.COMMON:    Color(0.65, 0.65, 0.65),   # Gris
	Rarity.UNCOMMON:  Color(0.2,  0.5,  1.0),    # Azul
	Rarity.EPIC:      Color(0.65, 0.15, 0.9),    # Morado
	Rarity.LEGENDARY: Color(1.0,  0.55, 0.05),   # Naranja
}

const RARITY_NAMES = {
	Rarity.COMMON:    "Común",
	Rarity.UNCOMMON:  "Poco común",
	Rarity.EPIC:      "Épico",
	Rarity.LEGENDARY: "Legendario",
}

# Pesos de aparición (mayor = más probable)
const RARITY_WEIGHTS = {
	Rarity.COMMON:    60,
	Rarity.UNCOMMON:  25,
	Rarity.EPIC:      12,
	Rarity.LEGENDARY: 3,
}

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
		"rarity": Rarity.EPIC,
		"icon": "🌀",
		"segment_color": Color(0.3, 0.8, 1.0),
		"effect_key": "wraparound",
	},
	{
		"id": "shield",
		"name": "Escudo",
		"description": "Las balas que impacten\nen este segmento no\ncausan daño.",
		"rarity": Rarity.EPIC,
		"icon": "🛡",
		"segment_color": Color(0.9, 0.85, 0.1),
		"effect_key": "shield",
	},
	{
		"id": "ghost_segment",
		"name": "Segmento Fantasma",
		"description": "La serpiente puede\natraversarse a sí misma\npor este segmento.",
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
	return RARITY_NAMES.get(rarity, "?")