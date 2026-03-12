extends Node2D

# === CONFIGURACIÓN ===
const GRID_SIZE: int = 40
const INITIAL_SPEED: float = 0.18  # segundos entre movimientos
const MIN_SPEED: float = 0.08
const SPEED_INCREMENT: float = 0.005

# Salud
const MAX_HEALTH: int = 100
const HEAL_AMOUNT: int = 25
const DAMAGE_PER_SECOND: float = 0.0  # daño solo por proyectiles

# === ESTADO ===
var segments: Array = []          # posiciones de los segmentos (Vector2i en grid)
var direction: Vector2i = Vector2i(1, 0)
var next_direction: Vector2i = Vector2i(1, 0)
var move_timer: float = 0.0
var current_speed: float = INITIAL_SPEED
var health: int = MAX_HEALTH
var is_alive: bool = true
var grow_count: int = 0

# Tamaño del grid (se calcula en _ready)
var grid_width: int = 0
var grid_height: int = 0

# Nodos
var head_node: Node2D
var segment_nodes: Array = []

# Swipe input
var touch_start: Vector2 = Vector2.ZERO
var min_swipe_distance: float = 30.0

# Mejoras activas (se aplican al llamar apply_upgrades)
var defense_percent: float = 0.0
var has_ghost_body: bool = false
var speed_boost_active: bool = false

signal health_changed(new_health, max_health)
signal died()
signal ate_enemy()

func apply_upgrades(evo_sys: Node):
	if evo_sys == null:
		return
	defense_percent = evo_sys.get_defense_percent()
	has_ghost_body = evo_sys.has_ghost_body()
	speed_boost_active = evo_sys.has_speed_boost()

func _ready():
	# Calcular grid según pantalla
	var screen = get_viewport_rect().size
	grid_width = int(screen.x / GRID_SIZE)
	grid_height = int(screen.y / GRID_SIZE)
	
	# Empieza inactiva hasta que Main llame a reset()
	is_alive = false
	set_process(false)

func _initialize_snake():
	# Limpiar segmentos previos
	for node in segment_nodes:
		if is_instance_valid(node):
			node.queue_free()
	segment_nodes.clear()
	segments.clear()
	
	# Posición inicial: centro del grid
	var start_x: int = grid_width / 2
	var start_y: int = grid_height / 2
	
	segments.append(Vector2i(start_x, start_y))
	segments.append(Vector2i(start_x - 1, start_y))
	segments.append(Vector2i(start_x - 2, start_y))
	
	for i in range(segments.size()):
		_create_segment_node(i)
	
	direction = Vector2i(1, 0)
	next_direction = Vector2i(1, 0)
	move_timer = 0.0
	current_speed = INITIAL_SPEED

func _create_segment_node(index: int) -> Node2D:
	var seg = Node2D.new()
	add_child(seg)
	
	var rect = ColorRect.new()
	rect.size = Vector2(GRID_SIZE - 2, GRID_SIZE - 2)
	rect.position = Vector2(1, 1)
	
	if index == 0:
		rect.color = Color(0.2, 0.9, 0.3)  # cabeza: verde brillante
	else:
		var t = float(index) / max(segments.size() - 1, 1)
		rect.color = Color(0.1 + t * 0.1, 0.6 - t * 0.2, 0.2)
	
	seg.add_child(rect)
	seg.position = Vector2(segments[index]) * GRID_SIZE
	
	if index == segment_nodes.size():
		segment_nodes.append(seg)
	else:
		segment_nodes.insert(index, seg)
	
	return seg

func _process(delta: float):
	if not is_alive:
		return
	
	move_timer += delta
	if move_timer >= current_speed:
		move_timer = 0.0
		_move()

func _input(event: InputEvent):
	if not is_alive:
		return
	
	# Swipe táctil
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
	elif event is InputEventScreenDrag:
		var diff = event.position - touch_start
		if diff.length() >= min_swipe_distance:
			_process_swipe(diff)
			touch_start = event.position
	
	# Teclado (debug en PC)
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_W:
				_try_set_direction(Vector2i(0, -1))
			KEY_DOWN, KEY_S:
				_try_set_direction(Vector2i(0, 1))
			KEY_LEFT, KEY_A:
				_try_set_direction(Vector2i(-1, 0))
			KEY_RIGHT, KEY_D:
				_try_set_direction(Vector2i(1, 0))

func _process_swipe(diff: Vector2):
	if abs(diff.x) > abs(diff.y):
		if diff.x > 0:
			_try_set_direction(Vector2i(1, 0))
		else:
			_try_set_direction(Vector2i(-1, 0))
	else:
		if diff.y > 0:
			_try_set_direction(Vector2i(0, 1))
		else:
			_try_set_direction(Vector2i(0, -1))

func _try_set_direction(new_dir: Vector2i):
	# No puede ir en dirección opuesta
	if new_dir != -direction:
		next_direction = new_dir

func _move():
	direction = next_direction
	
	var new_head = segments[0] + direction
	
	# Colisión con paredes
	if new_head.x < 0 or new_head.x >= grid_width or new_head.y < 0 or new_head.y >= grid_height:
		_die()
		return
	
	# Colisión con el propio cuerpo (skip tail ya que se mueve)
	if not has_ghost_body:
		for i in range(segments.size() - 1):
			if new_head == segments[i]:
				_die()
				return
	
	# Mover segmentos
	if grow_count > 0:
		segments.insert(0, new_head)
		grow_count -= 1
		_create_segment_node_at_front()
	else:
		segments.insert(0, new_head)
		var tail = segments.pop_back()
		_update_visual_positions()
	
	# Actualizar colores (cabeza siempre verde brillante)
	_update_segment_colors()
	
	# Notificar posición de la cabeza al EnemyManager
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.on_snake_moved(get_head_world_pos())

func _create_segment_node_at_front():
	var seg = Node2D.new()
	add_child(seg)
	
	var rect = ColorRect.new()
	rect.size = Vector2(GRID_SIZE - 2, GRID_SIZE - 2)
	rect.position = Vector2(1, 1)
	rect.color = Color(0.2, 0.9, 0.3)
	seg.add_child(rect)
	seg.position = Vector2(segments[0]) * GRID_SIZE
	
	segment_nodes.insert(0, seg)

func _update_visual_positions():
	for i in range(min(segments.size(), segment_nodes.size())):
		if is_instance_valid(segment_nodes[i]):
			segment_nodes[i].position = Vector2(segments[i]) * GRID_SIZE

func _update_segment_colors():
	for i in range(min(segments.size(), segment_nodes.size())):
		if is_instance_valid(segment_nodes[i]):
			var rect = segment_nodes[i].get_child(0) as ColorRect
			if rect:
				if i == 0:
					rect.color = Color(0.2, 0.9, 0.3)
				else:
					var t = float(i) / max(segments.size() - 1, 1)
					rect.color = Color(0.1 + t * 0.05, 0.65 - t * 0.25, 0.2)

func get_head_world_pos() -> Vector2:
	return Vector2(segments[0]) * GRID_SIZE + Vector2(GRID_SIZE / 2, GRID_SIZE / 2)

func get_head_grid_pos() -> Vector2i:
	return segments[0]

func get_segment_grid_positions() -> Array:
	return segments

func eat_enemy():
	# Curar al comer enemigo
	health = min(health + HEAL_AMOUNT, MAX_HEALTH)
	grow_count += 2
	
	# Aumentar velocidad ligeramente
	current_speed = max(current_speed - SPEED_INCREMENT, MIN_SPEED)
	
	emit_signal("health_changed", health, MAX_HEALTH)
	emit_signal("ate_enemy")

func take_damage(amount: int):
	if not is_alive:
		return
	var actual = int(ceil(amount * (1.0 - defense_percent)))
	health -= actual
	health = max(health, 0)
	emit_signal("health_changed", health, MAX_HEALTH)
	
	# Flash rojo
	_flash_red()
	
	if health <= 0:
		_die()

func _flash_red():
	for node in segment_nodes:
		if is_instance_valid(node):
			var rect = node.get_child(0) as ColorRect
			if rect:
				var original = rect.color
				rect.color = Color(1, 0.2, 0.2)
				await get_tree().create_timer(0.1).timeout
				if is_instance_valid(rect):
					rect.color = original

func _die():
	is_alive = false
	set_process(false)
	emit_signal("died")

func reset():
	is_alive = true
	health = MAX_HEALTH
	grow_count = 0
	current_speed = INITIAL_SPEED * (0.6 if speed_boost_active else 1.0)
	set_process(true)
	_initialize_snake()
	emit_signal("health_changed", health, MAX_HEALTH)