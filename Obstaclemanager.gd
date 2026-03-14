extends Node2D

# =====================================================
# OBSTACLE MANAGER
# Recibe un Array[ObstacleEntry] desde Main cuando
# empieza un nivel y dibuja los obstáculos en pantalla.
#
# Snake y EnemyManager consultan get_occupied_tiles()
# para no spawnear/moverse encima de los obstáculos.
# =====================================================

const GRID_SIZE: int = 40

# Color base de la roca
const ROCK_COLOR:        Color = Color(0.42, 0.40, 0.38)
const ROCK_SHADOW_COLOR: Color = Color(0.28, 0.26, 0.25)
const ROCK_HIGHLIGHT:    Color = Color(0.60, 0.58, 0.55)

var _tiles: Array = []    # todos los tiles bloqueados
var _obstacle_nodes: Array = []

# ─────────────────────────────────────────────────────
func setup(entries: Array) -> void:
	clear()
	for entry in entries:
		if entry == null:
			continue
		var tiles = entry.get_tiles()
		for t in tiles:
			if t not in _tiles:
				_tiles.append(t)
		_draw_obstacle(entry)

func clear() -> void:
	for node in _obstacle_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_obstacle_nodes.clear()
	_tiles.clear()

# ─────────────────────────────────────────────────────
# Consultado por Snake._move() y EnemyManager._find_valid_spawn()
# ─────────────────────────────────────────────────────
func get_occupied_tiles() -> Array:
	return _tiles

func is_blocked(pos: Vector2i) -> bool:
	return pos in _tiles

# ─────────────────────────────────────────────────────
# DIBUJO
# ─────────────────────────────────────────────────────
func _draw_obstacle(entry: ObstacleEntry) -> void:
	var tiles = entry.get_tiles()

	# Grupo raíz del obstáculo
	var root = Node2D.new()
	add_child(root)
	_obstacle_nodes.append(root)

	for tile in tiles:
		var px = tile.x * GRID_SIZE
		var py = tile.y * GRID_SIZE

		# Sombra (offset 2px abajo-derecha)
		var shadow = ColorRect.new()
		shadow.size     = Vector2(GRID_SIZE - 2, GRID_SIZE - 2)
		shadow.position = Vector2(px + 3, py + 3)
		shadow.color    = ROCK_SHADOW_COLOR
		root.add_child(shadow)

		# Cuerpo principal
		var body = ColorRect.new()
		body.size     = Vector2(GRID_SIZE - 4, GRID_SIZE - 4)
		body.position = Vector2(px + 2, py + 2)
		body.color    = ROCK_COLOR
		root.add_child(body)

		# Highlight (esquina superior-izquierda)
		var hl = ColorRect.new()
		hl.size     = Vector2(GRID_SIZE - 16, 4)
		hl.position = Vector2(px + 6, py + 6)
		hl.color    = ROCK_HIGHLIGHT
		root.add_child(hl)

		var hl2 = ColorRect.new()
		hl2.size     = Vector2(4, GRID_SIZE - 16)
		hl2.position = Vector2(px + 6, py + 6)
		hl2.color    = ROCK_HIGHLIGHT
		root.add_child(hl2)

		# Textura: puntos oscuros para dar sensación de roca
		for dot_data in [[px+14, py+14], [px+24, py+20], [px+18, py+26]]:
			var dot = ColorRect.new()
			dot.size     = Vector2(3, 3)
			dot.position = Vector2(dot_data[0], dot_data[1])
			dot.color    = ROCK_SHADOW_COLOR
			root.add_child(dot)

	# Borde entre bloques contiguos: borrar la separación interior
	# dibujando un puente del color del cuerpo entre tiles adyacentes
	if tiles.size() > 1:
		for i in range(tiles.size()):
			for j in range(i + 1, tiles.size()):
				var a = tiles[i]
				var b = tiles[j]
				var dx = b.x - a.x
				var dy = b.y - a.y
				if (dx == 1 and dy == 0) or (dx == 0 and dy == 1):
					var bridge = ColorRect.new()
					if dx == 1:  # horizontal
						bridge.size     = Vector2(6, GRID_SIZE - 8)
						bridge.position = Vector2(a.x * GRID_SIZE + GRID_SIZE - 3, a.y * GRID_SIZE + 4)
					else:  # vertical
						bridge.size     = Vector2(GRID_SIZE - 8, 6)
						bridge.position = Vector2(a.x * GRID_SIZE + 4, a.y * GRID_SIZE + GRID_SIZE - 3)
					bridge.color = ROCK_COLOR
					root.add_child(bridge)