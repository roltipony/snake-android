extends Node2D

const GRID_SIZE: int = 40
const HUD_HEIGHT: int = 90   # píxeles reservados para el HUD en la parte superior

var snake: Node2D
var enemy_manager: Node2D
var hud
var game_over_screen
var levelup_screen = null

var score: int = 0
var is_playing: bool = false
var evo_sys: Node = null
var evo_screen = null
var upgrade_db: Node = null

var _waiting_for_touch: bool = false

func _ready():
	add_to_group("main")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_background()
	_setup_nodes()
	_show_start_screen()

# ─────────────────────────────────────────────────────
func _build_background():
	var screen = get_viewport_rect().size

	var bg = ColorRect.new()
	bg.size = screen
	bg.color = Color(0.05, 0.05, 0.1)
	add_child(bg)

	# Grid solo en la zona de juego (debajo del HUD)
	var grid_node = Node2D.new()
	grid_node.position = Vector2(0, HUD_HEIGHT)
	add_child(grid_node)

	var gw = int(screen.x / GRID_SIZE)
	var gh = int((screen.y - HUD_HEIGHT) / GRID_SIZE)

	for x in range(gw + 1):
		var line = ColorRect.new()
		line.size = Vector2(1, screen.y - HUD_HEIGHT)
		line.position = Vector2(x * GRID_SIZE, 0)
		line.color = Color(1, 1, 1, 0.03)
		grid_node.add_child(line)

	for y in range(gh + 1):
		var line = ColorRect.new()
		line.size = Vector2(screen.x, 1)
		line.position = Vector2(0, y * GRID_SIZE)
		line.color = Color(1, 1, 1, 0.03)
		grid_node.add_child(line)

# ─────────────────────────────────────────────────────
func _setup_nodes():
	upgrade_db = load("res://SegmentUpgradeDB.gd").new()
	add_child(upgrade_db)

	evo_sys = load("res://EvolutionSystem.gd").new()
	add_child(evo_sys)

	# Serpiente: desplazada hacia abajo por el HUD
	# Calcular grid UNA sola vez aquí para que snake y enemies sean consistentes
	var screen = get_viewport_rect().size
	var gw = int(screen.x / GRID_SIZE)
	var gh = int((screen.y - HUD_HEIGHT) / GRID_SIZE)

	snake = load("res://Snake.gd").new()
	snake.position = Vector2(0, HUD_HEIGHT)
	add_child(snake)
	snake.grid_width = gw
	snake.grid_height = gh
	snake.connect("health_changed", _on_health_changed)
	snake.connect("xp_changed", _on_xp_changed)
	snake.connect("leveled_up", _on_leveled_up)
	snake.connect("died", _on_snake_died)
	snake.connect("ate_enemy_signal", _on_ate_enemy)
	snake.connect("turret_fire", _on_turret_fire)

	enemy_manager = load("res://EnemyManager.gd").new()
	enemy_manager.position = Vector2(0, HUD_HEIGHT)
	add_child(enemy_manager)
	enemy_manager.grid_width = gw
	enemy_manager.grid_height = gh
	enemy_manager.connect("enemy_eaten", _on_enemy_eaten_score)

	# Dar ref cruzada para torretas
	snake.enemy_manager_ref = enemy_manager

	hud = load("res://HUD.gd").new()
	hud.layer = 10
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)

	game_over_screen = CanvasLayer.new()
	game_over_screen.layer = 20
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	_build_game_over_screen()
	add_child(game_over_screen)
	game_over_screen.visible = false

# ─────────────────────────────────────────────────────
func _build_game_over_screen():
	var screen = get_viewport_rect().size

	var overlay = ColorRect.new()
	overlay.size = screen
	overlay.color = Color(0, 0, 0, 0.78)
	game_over_screen.add_child(overlay)

	var title = Label.new()
	title.position = Vector2(0, screen.y * 0.28)
	title.size = Vector2(screen.x, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = Loc.t("gameover_title")
	title.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	title.add_theme_font_size_override("font_size", 48)
	game_over_screen.add_child(title)

	var score_lbl = Label.new()
	score_lbl.name = "ScoreLabel"
	score_lbl.position = Vector2(0, screen.y * 0.42)
	score_lbl.size = Vector2(screen.x, 36)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_color_override("font_color", Color.WHITE)
	score_lbl.add_theme_font_size_override("font_size", 24)
	game_over_screen.add_child(score_lbl)

	var level_lbl = Label.new()
	level_lbl.name = "LevelLabel"
	level_lbl.position = Vector2(0, screen.y * 0.5)
	level_lbl.size = Vector2(screen.x, 30)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	level_lbl.add_theme_font_size_override("font_size", 20)
	game_over_screen.add_child(level_lbl)

	var tip = Label.new()
	tip.position = Vector2(0, screen.y * 0.58)
	tip.size = Vector2(screen.x, 30)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.text = Loc.t("gameover_tip")
	tip.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	tip.add_theme_font_size_override("font_size", 15)
	game_over_screen.add_child(tip)

	var btn = ColorRect.new()
	btn.size = Vector2(220, 60)
	btn.position = Vector2((screen.x - 220) / 2, screen.y * 0.68)
	btn.color = Color(0.12, 0.55, 0.22)
	game_over_screen.add_child(btn)

	var btn_lbl = Label.new()
	btn_lbl.size = Vector2(220, 60)
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.text = Loc.t("gameover_btn")
	btn_lbl.add_theme_color_override("font_color", Color.WHITE)
	btn_lbl.add_theme_font_size_override("font_size", 24)
	btn.add_child(btn_lbl)

# ─────────────────────────────────────────────────────
func _show_start_screen():
	var screen = get_viewport_rect().size
	var overlay = CanvasLayer.new()
	overlay.layer = 30
	overlay.name = "StartScreen"

	var bg = ColorRect.new()
	bg.size = screen
	bg.color = Color(0, 0, 0, 0.85)
	overlay.add_child(bg)

	var title = Label.new()
	title.position = Vector2(0, screen.y * 0.18)
	title.size = Vector2(screen.x, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = Loc.t("menu_title")
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
	title.add_theme_font_size_override("font_size", 52)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	overlay.add_child(title)

	var desc = Label.new()
	desc.position = Vector2(20, screen.y * 0.42)
	desc.size = Vector2(screen.x - 40, 80)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.text = Loc.t("menu_desc")
	desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	desc.add_theme_font_size_override("font_size", 17)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	overlay.add_child(desc)

	var start_btn = ColorRect.new()
	start_btn.size = Vector2(220, 65)
	start_btn.position = Vector2((screen.x - 220) / 2, screen.y * 0.82)
	start_btn.color = Color(0.12, 0.55, 0.22)
	overlay.add_child(start_btn)

	var btn_lbl = Label.new()
	btn_lbl.size = Vector2(220, 65)
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.text = Loc.t("menu_play")
	btn_lbl.add_theme_color_override("font_color", Color.WHITE)
	btn_lbl.add_theme_font_size_override("font_size", 28)
	start_btn.add_child(btn_lbl)

	add_child(overlay)
	await _wait_for_touch()
	overlay.queue_free()
	await _show_evolution_screen()
	_start_game()

# ─────────────────────────────────────────────────────
func _wait_for_touch() -> void:
	_waiting_for_touch = true
	while _waiting_for_touch:
		await get_tree().process_frame

func _unhandled_input(event: InputEvent):
	if evo_screen != null or levelup_screen != null:
		return
	if _waiting_for_touch:
		if event is InputEventScreenTouch and event.pressed:
			_waiting_for_touch = false
		elif event is InputEventKey and event.pressed:
			_waiting_for_touch = false

func _show_evolution_screen() -> void:
	evo_screen = load("res://EvolutionScreen.gd").new()
	add_child(evo_screen)
	await get_tree().process_frame
	evo_screen.setup(evo_sys)
	await evo_screen.ready_to_play
	evo_screen.queue_free()
	evo_screen = null

# ─────────────────────────────────────────────────────
func _start_game():
	score = 0
	is_playing = true
	snake.apply_upgrades(evo_sys)
	snake.reset()
	enemy_manager.setup(snake)
	if hud:
		hud.update_score(0)
		hud.update_health(snake.health, snake.max_health)
		hud.update_xp(0, snake.xp_to_next_level, 1)
	game_over_screen.visible = false

func on_snake_moved(_head_pos: Vector2):
	if not is_playing:
		return
	enemy_manager.check_snake_eat_enemy()

# ─────────────────────────────────────────────────────
# Señales de la serpiente
# ─────────────────────────────────────────────────────
func _on_health_changed(new_hp: int, max_hp: int):
	if hud:
		hud.update_health(new_hp, max_hp)

func _on_xp_changed(cur_xp: int, xp_needed: int, level: int):
	if hud:
		hud.update_xp(cur_xp, xp_needed, level)

func _on_leveled_up(new_level: int, _seg_idx: int):
	if hud:
		hud.show_message("LEVEL %d!" % new_level, Color(1.0, 0.85, 0.1))
	await get_tree().create_timer(0.25).timeout
	_set_game_paused(true)
	await _show_levelup_screen()
	_set_game_paused(false)

func _set_game_paused(paused: bool):
	if not paused:
		is_playing = snake.is_alive
	else:
		is_playing = false
	if is_instance_valid(snake):
		snake.set_process(not paused)
		snake.set_process_input(not paused)
	if is_instance_valid(enemy_manager):
		enemy_manager.set_process(not paused)
		for e in enemy_manager.enemies:
			if is_instance_valid(e):
				e.set_process(not paused)
		for b in enemy_manager.bullets:
			if is_instance_valid(b):
				b.set_process(not paused)

func _show_levelup_screen() -> void:
	var choices = upgrade_db.pick_two_random()
	levelup_screen = load("res://LevelUpScreen.gd").new()
	levelup_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(levelup_screen)
	await get_tree().process_frame
	levelup_screen.show_choices(upgrade_db, choices)
	var chosen = await levelup_screen.upgrade_chosen
	levelup_screen.queue_free()
	levelup_screen = null
	snake.apply_segment_upgrade(chosen)

func _on_snake_died():
	is_playing = false
	if is_instance_valid(enemy_manager):
		enemy_manager.stop()
	var score_lbl = game_over_screen.get_node_or_null("ScoreLabel")
	if score_lbl:
		score_lbl.text = Loc.t("gameover_score", [score])
	var lvl_lbl = game_over_screen.get_node_or_null("LevelLabel")
	if lvl_lbl:
		lvl_lbl.text = Loc.t("gameover_level", [snake.current_level])
	game_over_screen.visible = true
	await _wait_for_touch()
	game_over_screen.visible = false
	await _show_start_screen()

func _on_ate_enemy():
	if hud:
		hud.show_message(Loc.t("hud_xp_gain"), Color(0.3, 1.0, 0.5))

func _on_enemy_eaten_score(points: int):
	score += points
	if hud:
		hud.update_score(score)

# ─────────────────────────────────────────────────────
# Torretas
# ─────────────────────────────────────────────────────
func _on_turret_fire(start_pos: Vector2, dir: Vector2, dmg: int):
	var bullet = load("res://Bullet.gd").new()
	add_child(bullet)
	# start_pos ya viene en coordenadas locales del snake (sin offset HUD)
	# lo convertimos a mundo sumando el offset de snake
	var world_pos = snake.position + start_pos
	bullet.setup(world_pos, dir, 320.0, dmg, enemy_manager, true)
	bullet.connect("hit_enemy", _on_turret_hit_enemy)

func _on_turret_hit_enemy(enemy_node: Node):
	if is_instance_valid(enemy_node):
		var etype = enemy_node.enemy_type
		enemy_node.destroy()
		enemy_manager.enemies.erase(enemy_node)
		score += 5
		if hud:
			hud.update_score(score)
		# XP reducida a la mitad por kill de torreta
		var xp_values = snake.XP_BY_ENEMY_TYPE
		var half_xp = int(xp_values[clamp(etype, 0, xp_values.size()-1)] / 2.0)
		snake._add_xp(half_xp)

func _input(event: InputEvent):
	if is_playing and is_instance_valid(snake) and levelup_screen == null and evo_screen == null:
		snake._input(event)