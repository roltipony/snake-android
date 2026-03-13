extends Node2D

# =====================================================
# ENEMY MANAGER
# Modos:
#   campaign_mode = false → spawn automático (Horde)
#   campaign_mode = true  → ModeManager llama spawn_enemy_of_type()
# =====================================================

const GRID_SIZE:    int   = 40
const BULLET_SPEED: float = 280.0
const SAFE_RADIUS:  int   = 5

# Horde spawn config
const SPAWN_INTERVAL_START: float = 4.0
const SPAWN_INTERVAL_MIN:   float = 1.0
const SPAWN_RAMP_DURATION:  float = 120.0

# Campaign: sin límite fijo (ModeManager controla cuántos spawnean)
# Horde: límite progresivo
const HORDE_MAX_ENEMIES: int = 8

var enemies:       Array = []
var bullets:       Array = []
var snake_ref:     Node2D = null
var grid_width:    int   = 0
var grid_height:   int   = 0

var campaign_mode: bool  = false
var spawn_timer:   float = 0.0
var elapsed_time:  float = 0.0

signal enemy_eaten(points)

# ─────────────────────────────────────────────────────
func _ready():
	pass  # grid_width/height set by Main before use

func setup(snake: Node2D):
	# Limpiar partida anterior
	for e in enemies:
		if is_instance_valid(e): e.queue_free()
	enemies.clear()
	for b in bullets:
		if is_instance_valid(b): b.queue_free()
	bullets.clear()

	spawn_timer  = 0.0
	elapsed_time = 0.0
	snake_ref    = snake
	set_process(true)

func stop():
	set_process(false)
	for e in enemies:
		if is_instance_valid(e): e.set_process(false)
	for b in bullets:
		if is_instance_valid(b): b.set_process(false)

# ─────────────────────────────────────────────────────
func _process(delta: float):
	# Limpiar referencias inválidas
	enemies = enemies.filter(func(e): return is_instance_valid(e))
	bullets = bullets.filter(func(b): return is_instance_valid(b))

	if campaign_mode:
		return  # ModeManager gestiona el spawn

	# Horde: spawn automático creciente
	elapsed_time += delta
	spawn_timer  += delta
	var interval = _horde_interval()
	if spawn_timer >= interval:
		spawn_timer = 0.0
		if enemies.size() < HORDE_MAX_ENEMIES:
			_spawn_random()

func _horde_interval() -> float:
	var t = clamp(elapsed_time / SPAWN_RAMP_DURATION, 0.0, 1.0)
	return lerp(SPAWN_INTERVAL_START, SPAWN_INTERVAL_MIN, t)

# ─────────────────────────────────────────────────────
# SPAWN
# ─────────────────────────────────────────────────────

# Llamado por ModeManager en modo Campaign
func spawn_enemy_of_type(type: int):
	if not is_instance_valid(snake_ref):
		return
	var pos = _find_valid_spawn()
	if pos == Vector2i(-1, -1):
		return
	_create_enemy(pos, type)

# Usado en Horde
func _spawn_random():
	if not is_instance_valid(snake_ref):
		return
	var pos = _find_valid_spawn()
	if pos == Vector2i(-1, -1):
		return
	_create_enemy(pos, _horde_enemy_type())

func _create_enemy(pos: Vector2i, type: int):
	var enemy = load("res://Enemy.gd").new()
	add_child(enemy)
	enemy.setup(pos, type, snake_ref)
	enemy.connect("bullet_fired", _on_bullet_fired)
	enemy.connect("enemy_eaten",  _on_enemy_eaten)
	enemies.append(enemy)

func _horde_enemy_type() -> int:
	var roll = randf()
	if elapsed_time < 30.0:
		return 0
	elif elapsed_time < 90.0:
		return 0 if roll < 0.7 else 1
	else:
		if roll < 0.5: return 0
		elif roll < 0.8: return 1
		else: return 2

func _find_valid_spawn() -> Vector2i:
	if not is_instance_valid(snake_ref):
		return Vector2i(-1, -1)

	var occupied: Array = []
	for seg in snake_ref.get_segment_grid_positions():
		occupied.append(seg)
	for e in enemies:
		if is_instance_valid(e):
			occupied.append(e.get_grid_pos())

	var head = snake_ref.get_head_grid_pos()

	for _attempt in range(60):
		var x = randi() % grid_width
		var y = randi() % grid_height
		var c = Vector2i(x, y)
		if abs(c.x - head.x) < SAFE_RADIUS and abs(c.y - head.y) < SAFE_RADIUS:
			continue
		if c not in occupied:
			return c

	return Vector2i(-1, -1)

# ─────────────────────────────────────────────────────
# BULLETS
# ─────────────────────────────────────────────────────
func _on_bullet_fired(start_pos: Vector2, direction: Vector2, damage: int):
	var bullet = load("res://Bullet.gd").new()
	get_tree().current_scene.add_child(bullet)
	var world_pos = position + start_pos
	bullet.setup(world_pos, direction, BULLET_SPEED, damage, snake_ref, false)
	bullet.connect("hit_snake", _on_bullet_hit_snake)
	bullets.append(bullet)

func _on_bullet_hit_snake(damage_amount: int, segment_index: int):
	if is_instance_valid(snake_ref) and snake_ref.is_alive:
		snake_ref.take_damage(damage_amount, segment_index)

func _on_enemy_eaten(_grid_pos: Vector2i):
	pass

# ─────────────────────────────────────────────────────
# EAT CHECK — llamado desde Main en cada movimiento
# Devuelve enemy_type (0/1/2) o -1 si no se comió nada
# ─────────────────────────────────────────────────────
func check_snake_eat_enemy() -> int:
	if not is_instance_valid(snake_ref):
		return -1
	var head = snake_ref.get_head_grid_pos()
	for i in range(enemies.size()):
		var e = enemies[i]
		if is_instance_valid(e) and e.get_grid_pos() == head:
			var etype  = e.enemy_type
			var points = _enemy_points(etype)
			e.destroy()
			enemies.remove_at(i)
			emit_signal("enemy_eaten", points)
			snake_ref.eat_enemy(etype)
			return etype
	return -1

func _enemy_points(type: int) -> int:
	match type:
		0: return 10
		1: return 20
		2: return 30
	return 10