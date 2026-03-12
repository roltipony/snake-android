extends Node2D

const GRID_SIZE: int = 40

var velocity: Vector2 = Vector2.ZERO
var damage: int = 15
var snake_ref: Node2D = null
var screen_size: Vector2 = Vector2.ZERO
var is_turret_bullet: bool = false
var enemy_manager_ref: Node = null
var _already_hit: bool = false

# Color se asigna en setup, se aplica en _ready
var _bullet_color: Color = Color(1.0, 0.9, 0.1)
var bullet_visual: ColorRect

signal hit_snake(damage_amount, segment_index)
signal hit_enemy(enemy_node)

func setup(start_pos: Vector2, dir: Vector2, spd: float, dmg: int, target_ref: Node, turret: bool = false):
	position = start_pos
	velocity = dir * spd
	damage = dmg
	is_turret_bullet = turret
	if turret:
		enemy_manager_ref = target_ref
		_bullet_color = Color(0.3, 0.9, 1.0)
	else:
		snake_ref = target_ref
		_bullet_color = Color(1.0, 0.9, 0.1)

func _ready():
	screen_size = get_viewport_rect().size
	bullet_visual = ColorRect.new()
	bullet_visual.size = Vector2(10, 10)
	bullet_visual.position = Vector2(-5, -5)
	bullet_visual.color = _bullet_color
	add_child(bullet_visual)

func _process(delta: float):
	if _already_hit:
		return

	position += velocity * delta

	if position.x < -20 or position.x > screen_size.x + 20 or \
	   position.y < -20 or position.y > screen_size.y + 20:
		queue_free()
		return

	if is_turret_bullet:
		_check_enemy_hit()
	else:
		_check_snake_hit()

func _check_snake_hit():
	if not is_instance_valid(snake_ref):
		return
	var segs = snake_ref.get_segment_grid_positions()
	# La serpiente está desplazada HUD_HEIGHT en mundo, pero sus segmentos
	# están en coordenadas locales. snake_ref.position ya tiene el offset.
	var snake_offset = snake_ref.position
	for i in range(segs.size()):
		var seg_world = snake_offset + Vector2(segs[i]) * GRID_SIZE + Vector2(GRID_SIZE / 2, GRID_SIZE / 2)
		if position.distance_to(seg_world) < GRID_SIZE * 0.6:
			_already_hit = true
			emit_signal("hit_snake", damage, i)
			_explode(false)
			return

func _check_enemy_hit():
	if not is_instance_valid(enemy_manager_ref):
		return
	# enemy_manager también tiene offset HUD en su position
	var em_offset = enemy_manager_ref.position
	for e in enemy_manager_ref.enemies:
		if not is_instance_valid(e):
			continue
		# e.position es relativa a enemy_manager, más el centro del tile
		var eworld = em_offset + e.position + Vector2(GRID_SIZE / 2, GRID_SIZE / 2)
		if position.distance_to(eworld) < GRID_SIZE * 0.6:
			_already_hit = true
			emit_signal("hit_enemy", e)
			_explode(true)
			return

func _explode(turret: bool):
	set_process(false)
	if is_instance_valid(bullet_visual):
		bullet_visual.size = Vector2(20, 20)
		bullet_visual.position = Vector2(-10, -10)
		bullet_visual.color = Color(0.3, 1.0, 0.5) if turret else Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.08).timeout
	queue_free()