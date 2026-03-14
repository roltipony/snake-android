extends Node

# =====================================================
# LEVEL DATA
# Los niveles se cargan desde archivos .tres.
# Añadir nivel nuevo: crear .tres y añadir ruta aquí.
# =====================================================

const LEVEL_PATHS: Array[String] = [
	"res://resources/levels/level_1.tres",
	"res://resources/levels/level_2.tres",
	"res://resources/levels/level_3.tres",
	"res://resources/levels/level_4.tres",
	"res://resources/levels/level_5.tres",
]

var _levels: Array = []
var _loaded: bool = false

func _ready():
	_ensure_loaded()

func _ensure_loaded():
	if _loaded:
		return
	_loaded = true
	_levels.clear()
	for path in LEVEL_PATHS:
		if not ResourceLoader.exists(path):
			push_error("LevelData: archivo no encontrado: " + path)
			continue
		var res = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
		if res == null:
			push_error("LevelData: load() devolvio null para: " + path)
			continue
		if not res.has_method("to_dict"):
			push_error("LevelData: recurso no es LevelResource: " + path)
			continue
		_levels.append(res)
	print("LevelData: cargados %d niveles" % _levels.size())

func get_level(index: int) -> Dictionary:
	_ensure_loaded()
	if index >= 0 and index < _levels.size():
		return _levels[index].to_dict()
	return {}

func get_level_resource(index: int):
	_ensure_loaded()
	if index >= 0 and index < _levels.size():
		return _levels[index]
	return null

func get_level_count() -> int:
	_ensure_loaded()
	return _levels.size()