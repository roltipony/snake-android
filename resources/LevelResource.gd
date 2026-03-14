class_name LevelResource
extends Resource

# =====================================================
# LEVEL RESOURCE
# Para crear un nivel nuevo:
#   1. En Godot: clic derecho → New Resource → LevelResource
#   2. Rellena los campos en el Inspector
#   3. Añade las oleadas (WaveEntry) al array enemy_waves
#   4. Guarda como res://resources/levels/level_N.tres
#   5. Añade el .tres al array en LevelData.gd
#
# ── TIPOS DE WIN CONDITION ───────────────────────────
#   "survive"     → win_value = segundos a sobrevivir
#   "kill_total"  → win_value = total enemigos a matar
#   "kill_type"   → win_value = cantidad, win_enemy_type = índice del tipo
#   "reach_level" → win_value = nivel de serpiente a alcanzar
#
# Si hay varias condiciones, TODAS deben cumplirse.
# =====================================================

## Identificador único del nivel
@export var id: String = ""

## Nombre que se muestra en la pantalla de selección
@export var display_name: String = ""

## Descripción corta (2 líneas max)
@export_multiline var description: String = ""

## Oleadas de enemigos — array de WaveEntry
@export var enemy_waves: Array[WaveEntry] = []

# ── Condición de victoria 1 ──────────────────────────
@export_enum("survive", "kill_total", "kill_type", "reach_level") var win_type_1: String = "survive"
@export var win_value_1: int = 30
## Solo para kill_type: índice del tipo de enemigo (0=Basic, 1=FastShooter, 2=Tank…)
@export var win_enemy_type_1: int = 0

# ── Condición de victoria 2 (opcional) ──────────────
## Activa una segunda condición de victoria simultánea
@export var use_win_condition_2: bool = false
@export_enum("survive", "kill_total", "kill_type", "reach_level") var win_type_2: String = "kill_total"
@export var win_value_2: int = 0
@export var win_enemy_type_2: int = 0

# ─────────────────────────────────────────────────────
# Helpers — convierten el recurso al formato de dict
# que usa ModeManager internamente
# ─────────────────────────────────────────────────────
func get_win_conditions() -> Array:
	var conds = []
	var c1 = { "type": win_type_1, "value": win_value_1 }
	if win_type_1 == "kill_type":
		c1["enemy_type"] = win_enemy_type_1
	conds.append(c1)
	if use_win_condition_2:
		var c2 = { "type": win_type_2, "value": win_value_2 }
		if win_type_2 == "kill_type":
			c2["enemy_type"] = win_enemy_type_2
		conds.append(c2)
	return conds

func get_waves_as_dicts() -> Array:
	var result = []
	for w in enemy_waves:
		var enemies = []
		for i in range(w.enemy_types.size()):
			enemies.append({
				"type":  w.enemy_types[i],
				"count": w.enemy_counts[i] if i < w.enemy_counts.size() else 1
			})
		result.append({
			"delay":           w.delay,
			"enemies":         enemies,
			"repeat":          w.repeat,
			"repeat_interval": w.repeat_interval,
		})
	return result

func to_dict() -> Dictionary:
	return {
		"id":              id,
		"name":            display_name,
		"description":     description,
		"enemy_waves":     get_waves_as_dicts(),
		"win_conditions":  get_win_conditions(),
	}
