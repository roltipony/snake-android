extends Node2D

# === CONFIGURACIÓN ===
const GRID_SIZE: int = 40
const BULLET_SPEED: float = 280.0
const SHOOT_INTERVAL_MIN: float = 1.5
const SHOOT_INTERVAL_MAX: float = 3.5
const BULLET_DAMAGE: int = 7
const ENEMY_SIZE: float = 34.0

# Tipos de enemigo
enum EnemyType { BASIC, FAST_SHOOTER, TANK }

var enemy_type: EnemyType = EnemyType.BASIC
var shoot_timer: float = 0.0
var shoot_interval: float = 2.0
var grid_pos: Vector2i = Vector2i.ZERO
var snake_ref: Node2D = null
var is_active: bool = true

# Visual
var body_rect: ColorRect
var eye_left: ColorRect
var eye_right: ColorRect
var pulse_timer: float = 0.0

signal bullet_fired(start_pos, direction, damage)
signal enemy_eaten(grid_pos)

func _ready():
	_setup_visuals()
	shoot_interval = randf_range(SHOOT_INTERVAL_MIN, SHOOT_INTERVAL_MAX)
	shoot_timer = randf_range(0.5, shoot_interval)

func setup(pos: Vector2i, type: EnemyType, snake: Node2D):
	grid_pos = pos
	enemy_type = type
	snake_ref = snake
	position = Vector2(pos) * GRID_SIZE
	
	match type:
		EnemyType.BASIC:
			shoot_interval = randf_range(2.0, 3.5)
		EnemyType.FAST_SHOOTER:
			shoot_interval = randf_range(0.8, 1.5)
		EnemyType.TANK:
			shoot_interval = randf_range(3.0, 5.0)

func _setup_visuals():
	# Cuerpo principal
	body_rect = ColorRect.new()
	body_rect.size = Vector2(ENEMY_SIZE, ENEMY_SIZE)
	body_rect.position = Vector2((GRID_SIZE - ENEMY_SIZE) / 2, (GRID_SIZE - ENEMY_SIZE) / 2)
	add_child(body_rect)
	
	# Ojos
	eye_left = ColorRect.new()
	eye_left.size = Vector2(6, 6)
	eye_right = ColorRect.new()
	eye_right.size = Vector2(6, 6)
	eye_left.color = Color.WHITE
	eye_right.color = Color.WHITE
	
	var offset_x = (GRID_SIZE - ENEMY_SIZE) / 2
	var offset_y = (GRID_SIZE - ENEMY_SIZE) / 2
	eye_left.position = Vector2(offset_x + 6, offset_y + 8)
	eye_right.position = Vector2(offset_x + ENEMY_SIZE - 12, offset_y + 8)
	
	add_child(eye_left)
	add_child(eye_right)
	
	_update_color()

func _update_color():
	match enemy_type:
		EnemyType.BASIC:
			body_rect.color = Color(0.9, 0.2, 0.2)
		EnemyType.FAST_SHOOTER:
			body_rect.color = Color(0.9, 0.5, 0.1)
		EnemyType.TANK:
			body_rect.color = Color(0.6, 0.1, 0.7)

func _process(delta: float):
	if not is_active:
		return
	
	shoot_timer += delta
	
	# Pulso visual (avisa que va a disparar)
	pulse_timer += delta
	var pulse = sin(pulse_timer * (6.283 / shoot_interval) * 2.0) * 0.5 + 0.5
	_apply_pulse(pulse)
	
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		_shoot()

func _apply_pulse(t: float):
	if not is_instance_valid(body_rect):
		return
	match enemy_type:
		EnemyType.BASIC:
			body_rect.color = Color(0.9, 0.2 + t * 0.3, 0.2 + t * 0.1)
		EnemyType.FAST_SHOOTER:
			body_rect.color = Color(0.9, 0.5 + t * 0.2, 0.1 + t * 0.3)
		EnemyType.TANK:
			body_rect.color = Color(0.6 + t * 0.2, 0.1 + t * 0.1, 0.7 + t * 0.2)

func _shoot():
	if not is_instance_valid(snake_ref):
		return
	
	# start en coordenadas locales del enemy_manager (sin offset HUD)
	var start = position + Vector2(GRID_SIZE / 2, GRID_SIZE / 2)
	# target: posición mundo de la cabeza, restar offset del parent para igualar espacio
	var parent_offset = get_parent().position if get_parent() else Vector2.ZERO
	var target = snake_ref.get_head_world_pos() + snake_ref.position - parent_offset
	var dir = (target - start).normalized()
	
	if dir.length() < 0.01:
		dir = Vector2(0, 1)
	
	var dmg = BULLET_DAMAGE  # Basic: 7
	if enemy_type == EnemyType.FAST_SHOOTER:
		dmg = 5   # Fast: rápido pero débil
	elif enemy_type == EnemyType.TANK:
		dmg = 12  # Tank: fuerte pero lento
	
	emit_signal("bullet_fired", start, dir, dmg)

func get_grid_pos() -> Vector2i:
	return grid_pos

func destroy():
	is_active = false
	# Animación de muerte
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(self, "scale", Vector2(0, 0), 0.15)
	tween.tween_callback(queue_free)