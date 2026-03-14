extends Node

# =====================================================
# LEVEL DATA
# Los niveles ya no están hardcodeados aquí.
# Cada nivel es un archivo .tres en res://resources/levels/
#
# PARA AÑADIR UN NIVEL NUEVO:
#   1. Clic derecho en FileSystem → New Resource → LevelResource
#   2. Rellena los campos en el Inspector
#   3. Guarda como res://resources/levels/level_N.tres
#   4. Añade la ruta al array LEVEL_PATHS aquí abajo
# =====================================================

const LEVEL_PATHS: Array[String] = [
	"res://resources/levels/level_1.tres",
	"res://resources/levels/level_2.tres",
	"res://resources/levels/level_3.tres",
	"res://resources/levels/level_4.tres",
	"res://resources/levels/level_5.tres",
]

var _levels: Array = []

func _ready():
	_load_levels()

func _load_levels():
	_levels.clear()
	for path in LEVEL_PATHS:
		var res = load(path)
		if res == null:
			push_error("LevelData: no se pudo cargar " + path)
			continue
		_levels.append(res)

func get_level(index: int) -> Dictionary:
	if index >= 0 and index < _levels.size():
		return _levels[index].to_dict()
	return {}

func get_level_resource(index: int) -> LevelResource:
	if index >= 0 and index < _levels.size():
		return _levels[index]
	return null

func get_level_count() -> int:
	return _levels.size()
