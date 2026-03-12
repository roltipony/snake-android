extends Node2D

const GRID_SIZE: int = 40
const BULLET_SPEED: float = 280.0

# Spawn configuración
const INITIAL_ENEMY_COUNT: int = 3
const MAX_ENEMIES: int = 8
var enemies: Array = []
var bullets: Array = []
var snake_ref: Node2D = null
var spawn_timer: float = 0.0
var elapsed_time: float = 0.0
var grid_width: int = 0
var grid_height: int = 0
var score: int = 0

# Spawn interval decreases over time: starts at 4s, min 1s
const SPAWN_INTERVAL_START: float = 4.0
const SPAWN_INTERVAL_MIN: float = 1.0
const SPAWN_RAMP_DURATION: float = 120.0  # segundos hasta llegar al mínimo

func get_current_spawn_interval() -> float:
	var t = clamp(elapsed_time / SPAWN_RAMP_DURATION, 0.0, 1.0)
	return lerp(SPAWN_INTERVAL_START, SPAWN_INTERVAL_MIN, t)

# Reservar espacio seguro alrededor del inicio de la serpiente
const SAFE_RADIUS: int = 5

signal enemy_eaten(points)

func _ready():
	pass  # grid_width y grid_height los fija Main.gd

func setup(snake: Node2D):
	# Limpiar todo antes de empezar partida nueva
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	for b in bullets:
		if is_instance_valid(b):
			b.queue_free()
	bullets.clear()
	score = 0
	spawn_timer = 0.0
	elapsed_time = 0.0
	snake_ref = snake
	set_process(true)
	for i in range(INITIAL_ENEMY_COUNT):
		_spawn_enemy()

func _process(delta: float):
	elapsed_time += delta
	spawn_timer += delta
	var interval = get_current_spawn_interval()
	if spawn_timer >= interval:
		spawn_timer = 0.0
		if enemies.size() < MAX_ENEMIES:
			_spawn_enemy()
	
	# Limpiar referencias inválidas
	enemies = enemies.filter(func(e): return is_instance_valid(e))
	bullets = bullets.filter(func(b): return is_instance_valid(b))

func _spawn_enemy():
	if not is_instance_valid(snake_ref):
		return
	
	var pos = _find_valid_spawn_position()
	if pos == Vector2i(-1, -1):
		return
	
	var enemy = load("res://Enemy.gd").new()
	add_child(enemy)
	
	# Elegir tipo según score
	var type = _choose_enemy_type()
	enemy.setup(pos, type, snake_ref)
	enemy.connect("bullet_fired", _on_bullet_fired)
	enemy.connect("enemy_eaten", _on_enemy_eaten)
	
	enemies.append(enemy)

func _find_valid_spawn_position() -> Vector2i:
	var snake_segs = snake_ref.get_segment_grid_positions() if is_instance_valid(snake_ref) else []
	var occupied: Array = []
	
	# Posiciones de la serpiente
	for seg in snake_segs:
		occupied.append(seg)
	
	# Posiciones de otros enemigos
	for e in enemies:
		if is_instance_valid(e):
			occupied.append(e.get_grid_pos())
	
	# Cabeza de la serpiente con radio de seguridad
	var head = snake_ref.get_head_grid_pos() if is_instance_valid(snake_ref) else Vector2i(grid_width/2, grid_height/2)
	
	# Intentar posición aleatoria válida
	for _attempt in range(50):
		var x = randi() % grid_width
		var y = randi() % grid_height
		var candidate = Vector2i(x, y)
		
		# Verificar radio seguro desde cabeza
		if abs(candidate.x - head.x) < SAFE_RADIUS and abs(candidate.y - head.y) < SAFE_RADIUS:
			continue
		
		# Verificar que no está ocupado
		var valid = true
		for occ in occupied:
			if candidate == occ:
				valid = false
				break
		
		if valid:
			return candidate
	
	return Vector2i(-1, -1)

func _choose_enemy_type():
	var roll = randf()
	if score < 5:
		return 0  # Solo BASIC al inicio
	elif score < 15:
		if roll < 0.7:
			return 0  # BASIC
		else:
			return 1  # FAST_SHOOTER
	else:
		if roll < 0.5:
			return 0
		elif roll < 0.8:
			return 1
		else:
			return 2  # TANK

func _on_bullet_fired(start_pos: Vector2, direction: Vector2, damage: int):
	var bullet = load("res://Bullet.gd").new()
	get_tree().current_scene.add_child(bullet)
	# start_pos viene en coordenadas locales del enemy_manager, convertir a mundo
	var world_pos = position + start_pos
	bullet.setup(world_pos, direction, BULLET_SPEED, damage, snake_ref, false)
	bullet.connect("hit_snake", _on_bullet_hit_snake)
	bullets.append(bullet)

func _on_bullet_hit_snake(damage_amount: int, segment_index: int):
	if is_instance_valid(snake_ref):
		if not snake_ref.is_alive:
			return
		snake_ref.take_damage(damage_amount, segment_index)

func stop():
	set_process(false)
	# Detener todos los enemigos y balas activos
	for e in enemies:
		if is_instance_valid(e):
			e.set_process(false)
	for b in bullets:
		if is_instance_valid(b):
			b.set_process(false)

func _on_enemy_eaten(grid_pos: Vector2i):
	pass

func check_snake_eat_enemy() -> bool:
	if not is_instance_valid(snake_ref):
		return false
	
	var head_pos = snake_ref.get_head_grid_pos()
	
	for i in range(enemies.size()):
		var e = enemies[i]
		if is_instance_valid(e) and e.get_grid_pos() == head_pos:
			# ¡Comido!
			var points = _get_enemy_points(e.enemy_type)
			score += 1
			var etype = e.enemy_type
			e.destroy()
			enemies.remove_at(i)
			emit_signal("enemy_eaten", points)
			snake_ref.eat_enemy(etype)
			return true
	
	return false

func _get_enemy_points(type) -> int:
	match type:
		0: return 10   # BASIC
		1: return 20   # FAST_SHOOTER
		2: return 30   # TANK
	return 10

func reset():
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	
	for b in bullets:
		if is_instance_valid(b):
			b.queue_free()
	bullets.clear()
	
	score = 0
	spawn_timer = 0.0
	
	if is_instance_valid(snake_ref):
		for i in range(INITIAL_ENEMY_COUNT):
			_spawn_enemy()