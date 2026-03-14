extends Node2D

# =====================================================
# TILE MANAGER
# Gestiona todas las casillas especiales del nivel:
# obstáculos, bufos, trampas, etc.
#
# PARA AÑADIR UN TIPO NUEVO:
#   1. Añade el tipo al enum en TileEntry.gd
#   2. Si bloquea movimiento: actualiza TileEntry.is_blocking()
#   3. Añade su visual en _draw_tile_type()
#   4. Añade su efecto en _apply_tile_effect()
#   5. Crea un .tres con ese tipo y añádelo al nivel
#
# Snake llama check_and_apply(head_pos) en cada movimiento.
# EnemyManager llama get_blocking_tiles() para evitar spawn.
# =====================================================

const GRID_SIZE: int = 40

# Colores por tipo
const COLORS = {
	# OBSTACLE
	0: { "body": Color(0.42, 0.40, 0.38), "shadow": Color(0.28, 0.26, 0.25), "highlight": Color(0.60, 0.58, 0.55) },
	# BUFF_SPEED
	1: { "body": Color(0.15, 0.55, 0.95), "shadow": Color(0.08, 0.30, 0.60), "highlight": Color(0.55, 0.85, 1.00) },
	# BUFF_HEAL
	2: { "body": Color(0.15, 0.75, 0.35), "shadow": Color(0.05, 0.40, 0.18), "highlight": Color(0.55, 1.00, 0.65) },
}

# Iconos de texto para bufos
const ICONS = { 1: "⚡", 2: "💊" }

# Duración del bufo de velocidad (segundos)
const BUFF_SPEED_DURATION: float = 5.0
const BUFF_SPEED_MULT:     float = 1.5   # multiplica la velocidad actual
const BUFF_HEAL_AMOUNT:    int   = 25

# ─────────────────────────────────────────────────────
# Estado interno
# ─────────────────────────────────────────────────────
var _entries:        Array = []   # Array de TileEntry
var _tile_nodes:     Dictionary = {}   # Vector2i -> Node2D (para animar/destruir bufos)
var _blocking_tiles: Array = []   # tiles que bloquean movimiento

signal tile_activated(tile_type: int, tiles: Array)

# ─────────────────────────────────────────────────────
func setup(entries: Array) -> void:
	clear()
	_entries = entries.duplicate()
	for entry in _entries:
		if entry == null:
			continue
		var tiles = entry.get_tiles()
		if entry.is_blocking():
			for t in tiles:
				if t not in _blocking_tiles:
					_blocking_tiles.append(t)
		_draw_tile(entry)

func clear() -> void:
	for node in _tile_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	_tile_nodes.clear()
	_blocking_tiles.clear()
	_entries.clear()

# ─────────────────────────────────────────────────────
# Consultado por EnemyManager — no spawnear aquí
# ─────────────────────────────────────────────────────
func get_blocking_tiles() -> Array:
	return _blocking_tiles

func is_blocked(pos: Vector2i) -> bool:
	return pos in _blocking_tiles

# ─────────────────────────────────────────────────────
# Llamado por Snake en cada movimiento
# Devuelve true si el tile mata a la serpiente
# ─────────────────────────────────────────────────────
func check_and_apply(pos: Vector2i, snake: Node2D) -> bool:
	for entry in _entries:
		if entry == null:
			continue
		var tiles = entry.get_tiles()
		if pos in tiles:
			return _apply_tile_effect(entry, tiles, snake)
	return false

func _apply_tile_effect(entry: TileEntry, tiles: Array, snake: Node2D) -> bool:
	match entry.tile_type:
		0:  # OBSTACLE — mata
			return true
		1:  # BUFF_SPEED — aumenta velocidad temporalmente y consume el tile
			if is_instance_valid(snake):
				snake.apply_speed_buff(BUFF_SPEED_MULT, BUFF_SPEED_DURATION)
			_consume_tile(entry, tiles)
			emit_signal("tile_activated", 1, tiles)
			return false
		2:  # BUFF_HEAL — cura y consume el tile
			if is_instance_valid(snake):
				snake.heal(BUFF_HEAL_AMOUNT)
			_consume_tile(entry, tiles)
			emit_signal("tile_activated", 2, tiles)
			return false
	return false

func _consume_tile(entry: TileEntry, tiles: Array) -> void:
	# Eliminar de _entries para que no vuelva a activarse
	_entries.erase(entry)
	# Destruir nodos visuales
	for t in tiles:
		if _tile_nodes.has(t):
			if is_instance_valid(_tile_nodes[t]):
				var node = _tile_nodes[t]
				# Animación de desaparición
				var tw = node.create_tween()
				tw.tween_property(node, "scale", Vector2(1.4, 1.4), 0.08)
				tw.tween_property(node, "scale", Vector2(0.0, 0.0), 0.12)
				tw.tween_callback(node.queue_free)
			_tile_nodes.erase(t)

# ─────────────────────────────────────────────────────
# DIBUJO
# ─────────────────────────────────────────────────────
func _draw_tile(entry: TileEntry) -> void:
	var tiles   = entry.get_tiles()
	var c       = COLORS.get(entry.tile_type, COLORS[0])
	var root    = Node2D.new()
	add_child(root)

	for tile in tiles:
		_tile_nodes[tile] = root
		_draw_tile_type(root, tile, entry.tile_type, c)

	# Puentes entre bloques adyacentes del mismo tile
	if tiles.size() > 1:
		for i in range(tiles.size()):
			for j in range(i + 1, tiles.size()):
				var a  = tiles[i]
				var b  = tiles[j]
				var dx = b.x - a.x
				var dy = b.y - a.y
				if (dx == 1 and dy == 0) or (dx == 0 and dy == 1):
					var bridge = ColorRect.new()
					if dx == 1:
						bridge.size     = Vector2(6, GRID_SIZE - 8)
						bridge.position = Vector2(a.x * GRID_SIZE + GRID_SIZE - 3, a.y * GRID_SIZE + 4)
					else:
						bridge.size     = Vector2(GRID_SIZE - 8, 6)
						bridge.position = Vector2(a.x * GRID_SIZE + 4, a.y * GRID_SIZE + GRID_SIZE - 3)
					bridge.color = c["body"]
					root.add_child(bridge)

func _draw_tile_type(root: Node2D, tile: Vector2i, tile_type: int, c: Dictionary) -> void:
	var px = tile.x * GRID_SIZE
	var py = tile.y * GRID_SIZE

	match tile_type:
		0:  # OBSTACLE — roca
			var shadow = ColorRect.new()
			shadow.size     = Vector2(GRID_SIZE - 2, GRID_SIZE - 2)
			shadow.position = Vector2(px + 3, py + 3)
			shadow.color    = c["shadow"]
			root.add_child(shadow)

			var body = ColorRect.new()
			body.size     = Vector2(GRID_SIZE - 4, GRID_SIZE - 4)
			body.position = Vector2(px + 2, py + 2)
			body.color    = c["body"]
			root.add_child(body)

			var hl = ColorRect.new()
			hl.size     = Vector2(GRID_SIZE - 16, 4)
			hl.position = Vector2(px + 6, py + 6)
			hl.color    = c["highlight"]
			root.add_child(hl)

			var hl2 = ColorRect.new()
			hl2.size     = Vector2(4, GRID_SIZE - 16)
			hl2.position = Vector2(px + 6, py + 6)
			hl2.color    = c["highlight"]
			root.add_child(hl2)

			for dot_data in [[px+14, py+14], [px+24, py+20], [px+18, py+26]]:
				var dot = ColorRect.new()
				dot.size     = Vector2(3, 3)
				dot.position = Vector2(dot_data[0], dot_data[1])
				dot.color    = c["shadow"]
				root.add_child(dot)

		1, 2:  # BUFF — casilla de bufo (velocidad o cura)
			# Fondo con borde brillante
			var shadow = ColorRect.new()
			shadow.size     = Vector2(GRID_SIZE - 4, GRID_SIZE - 4)
			shadow.position = Vector2(px + 2, py + 2)
			shadow.color    = c["shadow"]
			root.add_child(shadow)

			var body = ColorRect.new()
			body.size     = Vector2(GRID_SIZE - 8, GRID_SIZE - 8)
			body.position = Vector2(px + 4, py + 4)
			body.color    = c["body"]
			root.add_child(body)

			# Brillo en esquina
			var hl = ColorRect.new()
			hl.size     = Vector2(GRID_SIZE - 18, 3)
			hl.position = Vector2(px + 7, py + 7)
			hl.color    = c["highlight"]
			root.add_child(hl)

			# Icono centrado
			var icon_lbl = Label.new()
			icon_lbl.size               = Vector2(GRID_SIZE, GRID_SIZE)
			icon_lbl.position           = Vector2(px, py)
			icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			icon_lbl.text               = ICONS.get(tile_type, "?")
			icon_lbl.add_theme_font_size_override("font_size", 18)
			icon_lbl.mouse_filter       = Control.MOUSE_FILTER_IGNORE
			root.add_child(icon_lbl)
