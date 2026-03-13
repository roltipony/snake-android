extends Node

# =====================================================
# LEVEL DATA — aquí defines los niveles de Campaña.
#
# PARA AÑADIR UN NIVEL nuevo:
#   1. Copia una entrada de CAMPAIGN_LEVELS y pégala al final.
#   2. Cambia "id", "name", "description".
#   3. Define enemy_waves (ver formato abajo).
#   4. Define win_conditions (ver tipos abajo).
#
# ── FORMATO DE WAVE ──────────────────────────────────
#   delay           : float  → segundos desde inicio hasta 1ª aparición
#   enemies         : Array  → [{ "type": int, "count": int }]
#                    tipos de enemigo: 0=Basic  1=FastShooter  2=Tank
#   repeat          : bool   → si true, la wave se repite
#   repeat_interval : float  → segundos entre repeticiones
#
# ── TIPOS DE WIN CONDITION ───────────────────────────
#   "survive"    value: segundos a sobrevivir
#   "kill_total" value: total de enemigos a matar
#   "kill_type"  value: cantidad  enemy_type: 0/1/2
#   "reach_level"value: nivel de serpiente a alcanzar
#
# Si hay varias condiciones, TODAS deben cumplirse.
# =====================================================

const CAMPAIGN_LEVELS: Array = [

	# ── LEVEL 1 ─────────────────────────────────────
	{
		"id":          "level_1",
		"name":        "Level 1  —  First Contact",
		"description": "Survive 30 seconds.\nOnly basic enemies.",
		"enemy_waves": [
			{ "delay": 0.0, "enemies": [{ "type": 0, "count": 3 }],
			  "repeat": true, "repeat_interval": 5.0 },
		],
		"win_conditions": [
			{ "type": "survive", "value": 30 },
		],
	},

	# ── LEVEL 2 ─────────────────────────────────────
	{
		"id":          "level_2",
		"name":        "Level 2  —  Sharpshooters",
		"description": "Kill 10 enemies.\nFast shooters appear.",
		"enemy_waves": [
			{ "delay": 0.0, "enemies": [{ "type": 0, "count": 3 }],
			  "repeat": true, "repeat_interval": 4.0 },
			{ "delay": 8.0, "enemies": [{ "type": 1, "count": 1 }],
			  "repeat": true, "repeat_interval": 6.0 },
		],
		"win_conditions": [
			{ "type": "kill_total", "value": 10 },
		],
	},

	# ── LEVEL 3 ─────────────────────────────────────
	{
		"id":          "level_3",
		"name":        "Level 3  —  Tank Buster",
		"description": "Kill 3 tanks.\nWatch out for backup.",
		"enemy_waves": [
			{ "delay": 0.0,  "enemies": [{ "type": 0, "count": 4 }],
			  "repeat": true, "repeat_interval": 4.0 },
			{ "delay": 5.0,  "enemies": [{ "type": 1, "count": 2 }],
			  "repeat": true, "repeat_interval": 7.0 },
			{ "delay": 12.0, "enemies": [{ "type": 2, "count": 1 }],
			  "repeat": false },
			{ "delay": 28.0, "enemies": [{ "type": 2, "count": 1 }],
			  "repeat": false },
			{ "delay": 46.0, "enemies": [{ "type": 2, "count": 1 }],
			  "repeat": false },
		],
		"win_conditions": [
			{ "type": "kill_type", "value": 3, "enemy_type": 2 },
		],
	},

	# ── LEVEL 4 ─────────────────────────────────────
	{
		"id":          "level_4",
		"name":        "Level 4  —  Evolution",
		"description": "Reach snake level 5.\nAll enemy types active.",
		"enemy_waves": [
			{ "delay": 0.0,  "enemies": [{ "type": 0, "count": 3 }, { "type": 1, "count": 1 }],
			  "repeat": true, "repeat_interval": 4.0 },
			{ "delay": 10.0, "enemies": [{ "type": 2, "count": 1 }],
			  "repeat": true, "repeat_interval": 12.0 },
		],
		"win_conditions": [
			{ "type": "reach_level", "value": 5 },
		],
	},

	# ── LEVEL 5 ─────────────────────────────────────
	{
		"id":          "level_5",
		"name":        "Level 5  —  Endurance",
		"description": "Survive 90s AND kill 20 enemies.\nAll types, increasing pressure.",
		"enemy_waves": [
			{ "delay": 0.0,  "enemies": [{ "type": 0, "count": 4 }],
			  "repeat": true, "repeat_interval": 3.5 },
			{ "delay": 5.0,  "enemies": [{ "type": 1, "count": 2 }],
			  "repeat": true, "repeat_interval": 5.0 },
			{ "delay": 20.0, "enemies": [{ "type": 2, "count": 1 }],
			  "repeat": true, "repeat_interval": 15.0 },
		],
		"win_conditions": [
			{ "type": "survive",    "value": 90 },
			{ "type": "kill_total", "value": 20 },
		],
	},

	# ── PLANTILLA PARA NUEVOS NIVELES ────────────────
	# Descomenta y rellena:
	#
	# {
	#   "id":          "level_6",
	#   "name":        "Level 6  —  Your Title",
	#   "description": "Description shown on level select.",
	#   "enemy_waves": [
	#     { "delay": 0.0, "enemies": [{ "type": 0, "count": 3 }],
	#       "repeat": true, "repeat_interval": 4.0 },
	#   ],
	#   "win_conditions": [
	#     { "type": "kill_total", "value": 15 },
	#   ],
	# },
]

func get_level(index: int) -> Dictionary:
	if index >= 0 and index < CAMPAIGN_LEVELS.size():
		return CAMPAIGN_LEVELS[index]
	return {}

func get_level_count() -> int:
	return CAMPAIGN_LEVELS.size()