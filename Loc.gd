extends Node

# =====================================================
# LOCALISATION SYSTEM
# Add new languages by duplicating the EN block.
# To switch language: Loc.set_language("es")
# To get a string:    Loc.t("key")
# =====================================================

var _language: String = "en"

const _STRINGS = {
	"en": {
		# HUD
		"hud_score":        "SCORE: %d",
		"hud_level":        "LVL %d",
		"hud_hp":           "%d/%d",
		"hud_xp":           "%d / %d XP",
		"hud_xp_gain":      "+XP  +HP",

		# Main menu
		"menu_title":       "SNAKE\nEATER",
		"menu_desc":        "Eat enemies to gain XP\nLevel up and choose abilities\nSwipe to move",
		"menu_play":        "PLAY",

		# Game over
		"gameover_title":   "GAME OVER",
		"gameover_score":   "Score: %d",
		"gameover_level":   "Level reached: %d",
		"gameover_tip":     "Eat enemies to level up!",
		"gameover_btn":     "CONTINUE",

		# Traits screen (pre-game upgrades, formerly "mejoras de evolución")
		"traits_title":     "TRAITS",
		"traits_subtitle":  "Equip traits before playing",
		"traits_points":    "Trait Points:  %d / %d  (available: %d)",
		"traits_equip":     "EQUIP",
		"traits_unequip":   "REMOVE",
		"traits_no_points": "NO TP",
		"traits_play":      "▶  PLAY",

		# Trait names & descriptions
		"trait_armor_name": "Hardened Scales",
		"trait_armor_desc": "Reduces damage taken by 20%.\nPercentage defense against attacks.",
		"trait_speed_name": "Adrenaline",
		"trait_speed_desc": "The snake starts the match\nwith increased movement speed.",

		# Level-up / ability screen (formerly "mejoras de segmento")
		"levelup_title":    "LEVEL UP!",
		"levelup_subtitle": "Choose an ability for your new segment",
		"levelup_pick":     "SELECT",

		# Rarity names
		"rarity_common":    "Common",
		"rarity_uncommon":  "Uncommon",
		"rarity_epic":      "Epic",
		"rarity_legendary": "Legendary",

		# Ability names & descriptions
		"ability_turret_name":  "Turret",
		"ability_turret_desc":  "This segment fires at the\nclosest enemy periodically.",
		"ability_wrap_name":    "Portal",
		"ability_wrap_desc":    "When hitting a wall you\nappear on the opposite side.",
		"ability_shield_name":  "Shield",
		"ability_shield_desc":  "Bullets that hit this segment\ndeal no damage.",
		"ability_ghost_name":   "Ghost Segment",
		"ability_ghost_desc":   "The snake can pass through\nitself at this segment.",

		# Enemy types (future use)
		"enemy_basic":      "Basic",
		"enemy_fast":       "Fast Shooter",
		"enemy_tank":       "Tank",
	},
	"es": {
		# HUD
		"hud_score":        "PUNTOS: %d",
		"hud_level":        "NVL %d",
		"hud_hp":           "%d/%d",
		"hud_xp":           "%d / %d XP",
		"hud_xp_gain":      "+XP  +VIDA",

		# Menú principal
		"menu_title":       "SNAKE\nEATER",
		"menu_desc":        "Come enemigos para ganar XP\nSube de nivel y elige habilidades\nDesliza para moverte",
		"menu_play":        "JUGAR",

		# Game over
		"gameover_title":   "GAME OVER",
		"gameover_score":   "Puntuación: %d",
		"gameover_level":   "Nivel alcanzado: %d",
		"gameover_tip":     "¡Come enemigos para subir de nivel!",
		"gameover_btn":     "CONTINUAR",

		# Pantalla de Traits
		"traits_title":     "TRAITS",
		"traits_subtitle":  "Equipa traits antes de jugar",
		"traits_points":    "Puntos de Trait:  %d / %d  (disponibles: %d)",
		"traits_equip":     "EQUIPAR",
		"traits_unequip":   "QUITAR",
		"traits_no_points": "SIN TP",
		"traits_play":      "▶  JUGAR",

		# Nombres y descripciones de traits
		"trait_armor_name": "Escamas Reforzadas",
		"trait_armor_desc": "Reduce el daño recibido un 20%.\nDefensa porcentual contra ataques.",
		"trait_speed_name": "Adrenalina",
		"trait_speed_desc": "La serpiente empieza\ncon mayor velocidad.",

		# Pantalla de subida de nivel / habilidades
		"levelup_title":    "¡NIVEL SUPERIOR!",
		"levelup_subtitle": "Elige una habilidad para tu nuevo segmento",
		"levelup_pick":     "ELEGIR",

		# Nombres de rareza
		"rarity_common":    "Común",
		"rarity_uncommon":  "Poco común",
		"rarity_epic":      "Épico",
		"rarity_legendary": "Legendario",

		# Nombres y descripciones de habilidades
		"ability_turret_name":  "Torreta",
		"ability_turret_desc":  "Este segmento dispara\nal enemigo más cercano.",
		"ability_wrap_name":    "Portal",
		"ability_wrap_desc":    "Al chocar con una pared\napareces en el lado opuesto.",
		"ability_shield_name":  "Escudo",
		"ability_shield_desc":  "Las balas que impacten aquí\nno causan daño.",
		"ability_ghost_name":   "Segmento Fantasma",
		"ability_ghost_desc":   "La serpiente puede atravesarse\na sí misma en este segmento.",

		# Tipos de enemigo
		"enemy_basic":      "Básico",
		"enemy_fast":       "Disparador Rápido",
		"enemy_tank":       "Tanque",
	},
}

func set_language(lang: String) -> void:
	if _STRINGS.has(lang):
		_language = lang

func t(key: String, args: Array = []) -> String:
	var lang_dict = _STRINGS.get(_language, _STRINGS["en"])
	var s = lang_dict.get(key, _STRINGS["en"].get(key, "???" + key))
	if args.is_empty():
		return s
	return s % args