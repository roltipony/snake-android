extends Node2D

const GRID_SIZE: int = 40

var velocity: Vector2 = Vector2.ZERO
var damage: int = 15
var snake_segments: Array = []
var snake_ref: Node2D = null
var screen_size: Vector2 = Vector2.ZERO

var bullet_visual: ColorRect
var trail_visuals: Array = []
const TRAIL_LENGTH: int = 4

signal hit_snake(damage_amount)

func _ready():
	screen_size = get_viewport_rect().size
	
	# Visual del proyectil
	bullet_visual = ColorRect.new()
	bullet_visual.size = Vector2(10, 10)
	bullet_visual.position = Vector2(-5, -5)
	bullet_visual.color = Color(1.0, 0.9, 0.1)
	add_child(bullet_visual)

func setup(start_pos: Vector2, dir: Vector2, spd: float, dmg: int, snake: Node2D):
	position = start_pos
	velocity = dir * spd
	damage = dmg
	snake_ref = snake

func _process(delta: float):
	position += velocity * delta
	
	# Destruir si sale de pantalla
	if position.x < -20 or position.x > screen_size.x + 20 or \
	   position.y < -20 or position.y > screen_size.y + 20:
		queue_free()
		return
	
	# Comprobar colisión con serpiente
	if is_instance_valid(snake_ref):
		var segs = snake_ref.get_segment_grid_positions()
		for seg in segs:
			var seg_world = Vector2(seg) * GRID_SIZE
			var dist = position.distance_to(seg_world + Vector2(GRID_SIZE / 2, GRID_SIZE / 2))
			if dist < GRID_SIZE * 0.55:
				emit_signal("hit_snake", damage)
				_explode()
				return

func _explode():
	# Flash de impacto
	if is_instance_valid(bullet_visual):
		bullet_visual.size = Vector2(20, 20)
		bullet_visual.position = Vector2(-10, -10)
		bullet_visual.color = Color(1, 0.3, 0.3)
	
	set_process(false)
	await get_tree().create_timer(0.08).timeout
	queue_free()
