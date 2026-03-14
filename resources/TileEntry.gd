class_name TileEntry
extends Resource

# =====================================================
# TILE ENTRY
# Define una casilla especial en el mapa de un nivel.
#
# PARA AÑADIR UN TIPO NUEVO:
#   1. Añade el nombre al enum tile_type
#   2. Decide si bloquea (is_blocking) en TileManager
#   3. Añade su visual en TileManager._draw_tile()
#   4. Si tiene efecto al pisarlo, añádelo en TileManager._on_snake_stepped()
#
# TIPOS ACTUALES:
#   0  OBSTACLE   — roca, mata a la serpiente al chocar
#   1  BUFF_SPEED — casilla de bufo de velocidad
#   2  BUFF_HEAL  — casilla de cura
#
# FORMAS:
#   0  SINGLE    — 1 bloque
#   1  DOUBLE_H  — 2 bloques horizontales  [■■]
#   2  DOUBLE_V  — 2 bloques verticales    [■]
#                                          [■]
#   3  L_SHAPE   — 3 bloques en L          [■]
#                                          [■■]
#   4  SQUARE    — cuadrado 2×2            [■■]
#                                          [■■]
#
# Nota: los bufos usan normalmente SINGLE.
# La posición es la esquina superior-izquierda (o el único bloque).
# =====================================================

## Tipo de casilla especial
@export_enum("OBSTACLE", "BUFF_SPEED", "BUFF_HEAL") var tile_type: int = 0

## Forma que ocupa en el grid
@export_enum("SINGLE", "DOUBLE_H", "DOUBLE_V", "L_SHAPE", "SQUARE") var shape: int = 0

## Columna en el grid (0 = izquierda)
@export var grid_x: int = 0

## Fila en el grid (0 = arriba)
@export var grid_y: int = 0

# ─────────────────────────────────────────────────────
func get_tiles() -> Array:
	var tiles = []
	match shape:
		0:  # SINGLE
			tiles.append(Vector2i(grid_x, grid_y))
		1:  # DOUBLE_H
			tiles.append(Vector2i(grid_x,     grid_y))
			tiles.append(Vector2i(grid_x + 1, grid_y))
		2:  # DOUBLE_V
			tiles.append(Vector2i(grid_x, grid_y))
			tiles.append(Vector2i(grid_x, grid_y + 1))
		3:  # L_SHAPE
			tiles.append(Vector2i(grid_x, grid_y))
			tiles.append(Vector2i(grid_x, grid_y + 1))
			tiles.append(Vector2i(grid_x + 1, grid_y + 1))
		4:  # SQUARE
			tiles.append(Vector2i(grid_x,     grid_y))
			tiles.append(Vector2i(grid_x + 1, grid_y))
			tiles.append(Vector2i(grid_x,     grid_y + 1))
			tiles.append(Vector2i(grid_x + 1, grid_y + 1))
	return tiles

func is_blocking() -> bool:
	return tile_type == 0  # solo OBSTACLE bloquea