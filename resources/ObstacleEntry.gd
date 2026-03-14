class_name ObstacleEntry
extends Resource

# FORMAS:
#   0  SINGLE    1 bloque
#   1  DOUBLE_H  2 horizontales
#   2  DOUBLE_V  2 verticales
#   3  L_SHAPE   3 bloques en L
#   4  SQUARE    cuadrado 2x2

@export_enum("SINGLE", "DOUBLE_H", "DOUBLE_V", "L_SHAPE", "SQUARE") var shape: int = 0
@export var grid_x: int = 0
@export var grid_y: int = 0

func get_tiles() -> Array:
	var tiles = []
	match shape:
		0:
			tiles.append(Vector2i(grid_x, grid_y))
		1:
			tiles.append(Vector2i(grid_x,     grid_y))
			tiles.append(Vector2i(grid_x + 1, grid_y))
		2:
			tiles.append(Vector2i(grid_x, grid_y))
			tiles.append(Vector2i(grid_x, grid_y + 1))
		3:
			tiles.append(Vector2i(grid_x, grid_y))
			tiles.append(Vector2i(grid_x, grid_y + 1))
			tiles.append(Vector2i(grid_x + 1, grid_y + 1))
		4:
			tiles.append(Vector2i(grid_x,     grid_y))
			tiles.append(Vector2i(grid_x + 1, grid_y))
			tiles.append(Vector2i(grid_x,     grid_y + 1))
			tiles.append(Vector2i(grid_x + 1, grid_y + 1))
	return tiles