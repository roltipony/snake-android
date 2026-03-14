extends Node2D

# === CONFIGURACIÓN ===
const GRID_SIZE: int = 40
const INITIAL_SPEED: float = 0.18
const MIN_SPEED: float = 0.09
const SPEED_INCREMENT: float = 0.004

# Salud
const BASE_MAX_HEALTH: int = 100
const HEALTH_PER_LEVEL: int = 20
const HEAL_ON_EAT: int = 15

# XP
const XP_PER_LEVEL_BASE: int = 50
const XP_SCALE_PER_LEVEL: float = 1.4

# XP por tipo de enemigo
const XP_BY_ENEMY_TYPE = [15, 25, 40]  # BASIC, FAST_SHOOTER, TANK

# === ESTADO ===
var segments: Array = []
var direction: Vector2i = Vector2i(1, 0)
var next_direction: Vector2i = Vector2i(1, 0)
var move_timer: float = 0.0
var current_speed: float = INITIAL_SPEED
var health: int = BASE_MAX_HEALTH
var max_health: int = BASE_MAX_HEALTH
var is_alive: bool = true
var grow_count: int = 0

# XP y niveles
var current_xp: int = 0
var current_level: int = 1
var xp_to_next_level: int = XP_PER_LEVEL_BASE

# Mejoras de segmento: indice -> datos
var segment_upgrades: Dictionary = {}
var turret_timers: Dictionary = {}

const TURRET_INTERVAL: float = 2.5
const TURRET_DAMAGE: int = 18

# Grid
var grid_width: int = 0
var grid_height: int = 0

# Nodos
var segment_nodes: Array = []

# Swipe
var touch_start: Vector2 = Vector2.ZERO
var min_swipe_distance: float = 30.0

# Bonuses calculados del pool activo de segmentos
var defense_percent: float = 0.0

# Ref a EnemyManager para torretas
var enemy_manager_ref: Node = null

# Ref a ObstacleManager para colisiones
var tile_manager_ref: Node = null

signal health_changed(new_health, max_health)
signal xp_changed(current_xp, xp_needed, level)
signal leveled_up(new_level, new_segment_index)
signal died()
signal ate_enemy_signal()
signal turret_fire(start_pos, dir, damage)

func apply_upgrades(_unused = null):
	defense_percent = 0.0  # recalculated from segment effects

func _ready():
	# grid_width y grid_height los fija Main.gd antes de usar la serpiente
	is_alive = false
	set_process(false)

func _initialize_snake():
	for node in segment_nodes:
		if is_instance_valid(node):
			node.queue_free()
	segment_nodes.clear()
	segments.clear()
	segment_upgrades.clear()
	turret_timers.clear()
	
	var start_x = grid_width / 2
	var start_y = grid_height / 2
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
	rect.color = _get_segment_color(index)
	seg.add_child(rect)
	seg.position = Vector2(segments[index]) * GRID_SIZE
	if index == segment_nodes.size():
		segment_nodes.append(seg)
	else:
		segment_nodes.insert(index, seg)
	return seg

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

func _get_segment_color(index: int) -> Color:
	if index == 0:
		return Color(0.2, 0.9, 0.3)
	if segment_upgrades.has(index):
		return segment_upgrades[index]["segment_color"]
	var t = float(index) / max(segments.size() - 1, 1)
	return Color(0.1 + t * 0.05, 0.65 - t * 0.25, 0.2)

func _update_visual_positions():
	for i in range(min(segments.size(), segment_nodes.size())):
		if is_instance_valid(segment_nodes[i]):
			segment_nodes[i].position = Vector2(segments[i]) * GRID_SIZE

func _update_segment_colors():
	for i in range(min(segments.size(), segment_nodes.size())):
		if is_instance_valid(segment_nodes[i]):
			var rect = segment_nodes[i].get_child(0) as ColorRect
			if rect:
				rect.color = _get_segment_color(i)

func _process(delta: float):
	if not is_alive:
		return
	move_timer += delta
	if move_timer >= current_speed:
		move_timer = 0.0
		_move()
	_process_turrets(delta)
	_process_speed_buff(delta)

func _process_turrets(delta: float):
	for seg_idx in segment_upgrades.keys():
		var upg = segment_upgrades[seg_idx]
		if upg["effect_key"] != "turret":
			continue
		if not turret_timers.has(seg_idx):
			turret_timers[seg_idx] = 0.0
		turret_timers[seg_idx] += delta
		if turret_timers[seg_idx] >= TURRET_INTERVAL:
			turret_timers[seg_idx] = 0.0
			_fire_turret(seg_idx)

func _fire_turret(seg_idx: int):
	if seg_idx >= segments.size():
		return
	var origin = Vector2(segments[seg_idx]) * GRID_SIZE + Vector2(GRID_SIZE / 2, GRID_SIZE / 2)
	var nearest_pos = Vector2.ZERO
	var nearest_dist = INF
	if is_instance_valid(enemy_manager_ref):
		for e in enemy_manager_ref.enemies:
			if is_instance_valid(e):
				var epos = Vector2(e.get_grid_pos()) * GRID_SIZE + Vector2(GRID_SIZE / 2, GRID_SIZE / 2)
				var d = origin.distance_to(epos)
				if d < nearest_dist:
					nearest_dist = d
					nearest_pos = epos
	if nearest_dist < INF:
		var dir = (nearest_pos - origin).normalized()
		emit_signal("turret_fire", origin, dir, TURRET_DAMAGE)

func _input(event: InputEvent):
	if not is_alive:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
	elif event is InputEventScreenDrag:
		var diff = event.position - touch_start
		if diff.length() >= min_swipe_distance:
			_process_swipe(diff)
			touch_start = event.position
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_W:    _try_set_direction(Vector2i(0, -1))
			KEY_DOWN, KEY_S:  _try_set_direction(Vector2i(0, 1))
			KEY_LEFT, KEY_A:  _try_set_direction(Vector2i(-1, 0))
			KEY_RIGHT, KEY_D: _try_set_direction(Vector2i(1, 0))

func _process_swipe(diff: Vector2):
	if abs(diff.x) > abs(diff.y):
		_try_set_direction(Vector2i(1 if diff.x > 0 else -1, 0))
	else:
		_try_set_direction(Vector2i(0, 1 if diff.y > 0 else -1))

func _try_set_direction(new_dir: Vector2i):
	if new_dir != -direction:
		next_direction = new_dir

func _move():
	direction = next_direction
	var new_head = segments[0] + direction
	
	var out = new_head.x < 0 or new_head.x >= grid_width or new_head.y < 0 or new_head.y >= grid_height
	if out:
		if _has_segment_upgrade("wraparound"):
			new_head.x = posmod(new_head.x, grid_width)
			new_head.y = posmod(new_head.y, grid_height)
		else:
			_die()
			return
	
	for i in range(segments.size() - 1):
		if new_head == segments[i]:
			# Si ese segmento tiene ghost_segment, se puede atravesar
			if segment_upgrades.has(i) and segment_upgrades[i]["effect_key"] == "ghost_segment":
				continue
			_die()
			return

	# Colisión / activación de tiles especiales
	if is_instance_valid(tile_manager_ref):
		if tile_manager_ref.check_and_apply(new_head, self):
			_die()
			return
	
	if grow_count > 0:
		segments.insert(0, new_head)
		grow_count -= 1
		_create_segment_node_at_front()
	else:
		segments.insert(0, new_head)
		segments.pop_back()
		_update_visual_positions()
	
	_update_segment_colors()
	
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.on_snake_moved(get_head_world_pos())

func _has_segment_upgrade(effect_key: String) -> bool:
	for upg in segment_upgrades.values():
		if upg["effect_key"] == effect_key:
			return true
	return false

func eat_enemy(enemy_type: int = 0):
	# Base heal
	var bonus_heal = 0
	var xp_multiplier = 1.0
	for upg in segment_upgrades.values():
		match upg.get("effect_key", ""):
			"heal_segment": bonus_heal += 10
			"xp_boost":     xp_multiplier += 0.20
	health = min(health + HEAL_ON_EAT + bonus_heal, max_health)
	emit_signal("health_changed", health, max_health)
	emit_signal("ate_enemy_signal")
	var xp_gain = XP_BY_ENEMY_TYPE[clamp(enemy_type, 0, XP_BY_ENEMY_TYPE.size() - 1)]
	_add_xp(int(xp_gain * xp_multiplier))

func _add_xp(amount: int):
	current_xp += amount
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		_level_up()
	emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

func _level_up():
	current_level += 1
	xp_to_next_level = int(XP_PER_LEVEL_BASE * pow(XP_SCALE_PER_LEVEL, current_level - 1))
	max_health += HEALTH_PER_LEVEL
	health = min(health + HEALTH_PER_LEVEL, max_health)
	grow_count += 1
	emit_signal("health_changed", health, max_health)
	emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)
	emit_signal("leveled_up", current_level, segments.size())

func apply_segment_upgrade(upgrade_data: Dictionary):
	var target_idx = segments.size() - 1
	segment_upgrades[target_idx] = upgrade_data
	if upgrade_data["effect_key"] == "turret":
		turret_timers[target_idx] = 0.0
	if upgrade_data["effect_key"] == "speed_segment":
		# Each speed segment gives 8% speed boost (lower move_timer interval)
		var speed_count = 0
		for upg in segment_upgrades.values():
			if upg.get("effect_key","") == "speed_segment":
				speed_count += 1
		current_speed = INITIAL_SPEED * pow(0.92, speed_count)
		current_speed = max(current_speed, MIN_SPEED)
	_update_segment_colors()

# ─────────────────────────────────────────────────────
# TILE BUFFS — llamados por TileManager
# ─────────────────────────────────────────────────────
func heal(amount: int) -> void:
	if not is_alive:
		return
	health = min(health + amount, max_health)
	emit_signal("health_changed", health, max_health)

var _speed_buff_timer: float = 0.0
var _speed_buff_active: bool = false
var _speed_buff_original: float = 0.0

func apply_speed_buff(multiplier: float, duration: float) -> void:
	if not is_alive:
		return
	if not _speed_buff_active:
		_speed_buff_original = current_speed
	_speed_buff_active = true
	_speed_buff_timer  = duration
	current_speed = max(_speed_buff_original / multiplier, MIN_SPEED)

func _process_speed_buff(delta: float) -> void:
	if not _speed_buff_active:
		return
	_speed_buff_timer -= delta
	if _speed_buff_timer <= 0.0:
		_speed_buff_active = false
		current_speed = _speed_buff_original

func take_damage(amount: int, hit_segment_index: int = -1):
	if not is_alive:
		return
	if hit_segment_index >= 0 and segment_upgrades.has(hit_segment_index):
		if segment_upgrades[hit_segment_index]["effect_key"] == "shield":
			return
	# Count armor segments
	var total_defense = defense_percent
	for upg in segment_upgrades.values():
		if upg.get("effect_key","") == "armor_segment":
			total_defense += 0.15
	total_defense = clamp(total_defense, 0.0, 0.75)
	var actual = int(ceil(amount * (1.0 - total_defense)))
	health -= actual
	health = max(health, 0)
	emit_signal("health_changed", health, max_health)
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

func get_head_world_pos() -> Vector2:
	return Vector2(segments[0]) * GRID_SIZE + Vector2(GRID_SIZE / 2, GRID_SIZE / 2)

func get_head_grid_pos() -> Vector2i:
	return segments[0]

func get_segment_grid_positions() -> Array:
	return segments

func reset():
	is_alive = true
	current_level = 1
	current_xp = 0
	xp_to_next_level = XP_PER_LEVEL_BASE
	max_health = BASE_MAX_HEALTH
	health = max_health
	grow_count = 0
	set_process(true)
	_initialize_snake()
	emit_signal("health_changed", health, max_health)
	emit_signal("xp_changed", 0, xp_to_next_level, 1)
