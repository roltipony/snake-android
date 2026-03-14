extends Node2D

# =====================================================
# MAIN
# =====================================================

const GRID_SIZE:  int = 40
const HUD_HEIGHT: int = 90

var snake:            Node2D = null
var enemy_manager:    Node2D = null
var tile_manager: Node2D = null
var hud:              Node   = null

var upgrade_db:   Node = null
var level_db:     Node = null
var mode_manager: Node = null

# UI layer — existe todo el tiempo, intercambiamos el hijo
var _ui_layer:    CanvasLayer = null
var _ui_control:  Control     = null   # pantalla activa

var score:               int    = 0
var is_playing:          bool   = false
var current_mode:        String = ""
var current_level_index: int    = 0

# Flags de navegación (set por lambdas conectadas a señales)
var _chosen_mode:    String = ""
var _chosen_level:   int    = -1
var _went_back:      bool   = false
var _evo_done:       bool   = false
var _levelup_choice: Dictionary = {}
var _victory_done:   bool   = false
var _gameover_done:  bool   = false

var evo_screen:     Node = null
var levelup_screen: Node = null
var victory_screen: Node = null

# ─────────────────────────────────────────────────────
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("main")
	_build_background()
	_setup_systems()
	_setup_game_nodes()
	_setup_hud()
	_setup_ui_layer()
	_show_menu()

# ─────────────────────────────────────────────────────
# SETUP
# ─────────────────────────────────────────────────────
func _build_background():
	var screen = get_viewport_rect().size
	var bg = ColorRect.new()
	bg.size  = screen
	bg.color = Color(0.05, 0.05, 0.1)
	add_child(bg)
	var grid_node = Node2D.new()
	grid_node.position = Vector2(0, HUD_HEIGHT)
	add_child(grid_node)
	var gw = int(screen.x / GRID_SIZE)
	var gh = int((screen.y - HUD_HEIGHT) / GRID_SIZE)
	for x in range(gw + 1):
		var l = ColorRect.new()
		l.size = Vector2(1, screen.y - HUD_HEIGHT)
		l.position = Vector2(x * GRID_SIZE, 0)
		l.color = Color(1, 1, 1, 0.03)
		grid_node.add_child(l)
	for y in range(gh + 1):
		var l = ColorRect.new()
		l.size = Vector2(screen.x, 1)
		l.position = Vector2(0, y * GRID_SIZE)
		l.color = Color(1, 1, 1, 0.03)
		grid_node.add_child(l)

func _setup_systems():
	upgrade_db   = load("res://SegmentUpgradeDB.gd").new(); add_child(upgrade_db)
	level_db     = load("res://LevelData.gd").new();        add_child(level_db)
	mode_manager = load("res://ModeManager.gd").new();      add_child(mode_manager)

func _setup_game_nodes():
	var screen = get_viewport_rect().size
	var gw = int(screen.x / GRID_SIZE)
	var gh = int((screen.y - HUD_HEIGHT) / GRID_SIZE)

	snake = load("res://Snake.gd").new()
	snake.position    = Vector2(0, HUD_HEIGHT)
	snake.grid_width  = gw
	snake.grid_height = gh
	add_child(snake)
	snake.connect("health_changed",   _on_health_changed)
	snake.connect("xp_changed",       _on_xp_changed)
	snake.connect("leveled_up",       _on_leveled_up)
	snake.connect("died",             _on_snake_died)
	snake.connect("ate_enemy_signal", _on_ate_enemy)
	snake.connect("turret_fire",      _on_turret_fire)

	enemy_manager = load("res://EnemyManager.gd").new()
	enemy_manager.position    = Vector2(0, HUD_HEIGHT)
	enemy_manager.grid_width  = gw
	enemy_manager.grid_height = gh
	add_child(enemy_manager)
	enemy_manager.connect("enemy_eaten", _on_enemy_eaten_score)

	snake.enemy_manager_ref = enemy_manager
	mode_manager.setup(level_db, enemy_manager)
	mode_manager.connect("level_won", _on_level_won)

	tile_manager = load("res://TileManager.gd").new()
	tile_manager.position = Vector2(0, HUD_HEIGHT)
	add_child(tile_manager)
	snake.tile_manager_ref = tile_manager
	enemy_manager.tile_manager_ref = tile_manager

func _setup_hud():
	hud = load("res://HUD.gd").new()
	hud.layer        = 10
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)

func _setup_ui_layer():
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer        = 30
	_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui_layer)

# ─────────────────────────────────────────────────────
# UI HELPER — muestra una pantalla, espera flag, limpia
# ─────────────────────────────────────────────────────
func _show_screen(screen: Control):
	# Eliminar pantalla anterior si existe
	if is_instance_valid(_ui_control):
		_ui_control.queue_free()
	_ui_control = screen
	_ui_layer.add_child(screen)
	# Forzar tamaño completo DESPUÉS de estar en árbol
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.size = get_viewport_rect().size

func _clear_screen():
	if is_instance_valid(_ui_control):
		_ui_control.queue_free()
		_ui_control = null

# ─────────────────────────────────────────────────────
# MENU FLOW
# ─────────────────────────────────────────────────────
func _show_menu():
	_chosen_mode = ""
	var menu = load("res://MenuScreen.gd").new()
	menu.connect("mode_selected", func(m): _chosen_mode = m)
	_show_screen(menu)
	while _chosen_mode == "":
		await get_tree().process_frame
	_clear_screen()

	current_mode = _chosen_mode
	if _chosen_mode == "campaign":
		await _show_campaign_select()
	else:
		await _show_evolution_screen()
		_start_horde()

func _show_campaign_select():
	_chosen_level = -1
	_went_back    = false
	var sel = load("res://CampaignSelectScreen.gd").new()
	sel.connect("level_chosen", func(idx): _chosen_level = idx)
	sel.connect("back_pressed",  func():    _went_back    = true)
	_show_screen(sel)
	await get_tree().process_frame   # esperar un frame para que _build() tenga size correcto
	sel.setup(level_db, mode_manager)
	while _chosen_level == -1 and not _went_back:
		await get_tree().process_frame
	_clear_screen()

	if _went_back:
		await _show_menu()
	else:
		current_level_index = _chosen_level
		await _show_evolution_screen()
		_start_campaign(current_level_index)

func _show_evolution_screen():
	_evo_done = false
	evo_screen = load("res://PoolSelectScreen.gd").new()
	evo_screen.connect("pool_confirmed", func(pool):
		upgrade_db.set_active_pool(pool)
		_evo_done = true
	)
	_show_screen(evo_screen)
	await get_tree().process_frame
	evo_screen.setup(upgrade_db)
	while not _evo_done:
		await get_tree().process_frame
	_clear_screen()
	evo_screen = null

func _show_levelup_screen():
	_levelup_choice = {}
	var choices = upgrade_db.pick_two_random()
	levelup_screen = load("res://LevelUpScreen.gd").new()
	levelup_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	levelup_screen.connect("upgrade_chosen", func(upg): _levelup_choice = upg)
	_show_screen(levelup_screen)
	await get_tree().process_frame
	levelup_screen.show_choices(upgrade_db, choices)
	while _levelup_choice.is_empty():
		await get_tree().process_frame
	_clear_screen()
	levelup_screen = null
	snake.apply_segment_upgrade(_levelup_choice)

func _show_victory_screen(lvl_name: String):
	_victory_done = false
	victory_screen = load("res://VictoryScreen.gd").new()
	victory_screen.connect("continue_pressed", func(): _victory_done = true)
	_show_screen(victory_screen)
	await get_tree().process_frame
	victory_screen.show_victory(lvl_name, score, snake.current_level)
	while not _victory_done:
		await get_tree().process_frame
	_clear_screen()
	victory_screen = null

func _show_gameover_screen():
	_gameover_done = false
	var go = load("res://GameOverScreen.gd").new()
	go.connect("continue_pressed", func(): _gameover_done = true)
	_show_screen(go)
	await get_tree().process_frame
	go.show_result(score, snake.current_level)
	while not _gameover_done:
		await get_tree().process_frame
	_clear_screen()

# ─────────────────────────────────────────────────────
# GAME START
# ─────────────────────────────────────────────────────
func _start_campaign(level_index: int):
	score               = 0
	is_playing          = true
	current_level_index = level_index
	hud.set_campaign_mode(true)
	# Cargar obstáculos del nivel
	var lvl_res = level_db.get_level_resource(level_index)
	if lvl_res and lvl_res.special_tiles.size() > 0:
		tile_manager.setup(lvl_res.special_tiles)
	else:
		tile_manager.clear()
	snake.reset()
	enemy_manager.campaign_mode = true
	enemy_manager.setup(snake)
	mode_manager.start_campaign(level_index)
	hud.update_score(0)
	hud.update_health(snake.health, snake.max_health)
	hud.update_xp(0, snake.xp_to_next_level, 1)
	hud.update_objective(mode_manager.get_objective_text())

func _start_horde():
	score      = 0
	is_playing = true
	hud.set_campaign_mode(false)
	tile_manager.clear()
	snake.reset()
	enemy_manager.campaign_mode = false
	enemy_manager.setup(snake)
	mode_manager.start_horde()
	hud.update_score(0)
	hud.update_health(snake.health, snake.max_health)
	hud.update_xp(0, snake.xp_to_next_level, 1)
	hud.update_objective("")

# ─────────────────────────────────────────────────────
# SNAKE CALLBACKS
# ─────────────────────────────────────────────────────
func on_snake_moved(_head_pos: Vector2):
	if not is_playing: return
	var killed = enemy_manager.check_snake_eat_enemy()
	if killed >= 0:
		mode_manager.on_enemy_killed(killed)
	hud.update_objective(mode_manager.get_objective_text())

func _on_health_changed(hp: int, max_hp: int):
	hud.update_health(hp, max_hp)

func _on_xp_changed(xp: int, needed: int, level: int):
	hud.update_xp(xp, needed, level)
	mode_manager.on_snake_level_changed(level)

func _on_leveled_up(new_level: int, _seg: int):
	hud.show_message("LEVEL %d!" % new_level, Color(1.0, 0.85, 0.1))
	await get_tree().create_timer(0.25).timeout
	_set_paused(true)
	await _show_levelup_screen()
	_set_paused(false)

func _on_ate_enemy():
	hud.show_message(Loc.t("hud_xp_gain"), Color(0.3, 1.0, 0.5))

func _on_enemy_eaten_score(points: int):
	score += points
	hud.update_score(score)

# ─────────────────────────────────────────────────────
# TURRET
# ─────────────────────────────────────────────────────
func _on_turret_fire(start_pos: Vector2, dir: Vector2, dmg: int):
	var bullet = load("res://Bullet.gd").new()
	add_child(bullet)
	bullet.setup(snake.position + start_pos, dir, 320.0, dmg, enemy_manager, true)
	bullet.connect("hit_enemy", _on_turret_hit_enemy)

func _on_turret_hit_enemy(enemy_node: Node):
	if not is_instance_valid(enemy_node): return
	var etype = enemy_node.enemy_type
	enemy_node.destroy()
	enemy_manager.enemies.erase(enemy_node)
	score += 5
	hud.update_score(score)
	mode_manager.on_enemy_killed(etype)
	snake._add_xp(int(snake.XP_BY_ENEMY_TYPE[clamp(etype,0,2)] / 2.0))

# ─────────────────────────────────────────────────────
# PAUSE
# ─────────────────────────────────────────────────────
func _set_paused(paused: bool):
	is_playing = false if paused else snake.is_alive
	snake.set_process(not paused)
	snake.set_process_input(not paused)
	enemy_manager.set_process(not paused)
	for e in enemy_manager.enemies:
		if is_instance_valid(e): e.set_process(not paused)
	for b in enemy_manager.bullets:
		if is_instance_valid(b): b.set_process(not paused)
	mode_manager.set_process(not paused)

# ─────────────────────────────────────────────────────
# LEVEL WON
# ─────────────────────────────────────────────────────
func _on_level_won():
	# Parar TODO inmediatamente
	_set_paused(true)
	enemy_manager.stop()
	mode_manager.stop()
	is_playing = false
	var lvl_name = level_db.get_level(current_level_index).get(
		"name", "Level %d" % (current_level_index + 1))
	await _show_victory_screen(lvl_name)
	# Volver siempre a la selección de nivel
	await _show_campaign_select()

# ─────────────────────────────────────────────────────
# GAME OVER
# ─────────────────────────────────────────────────────
func _on_snake_died():
	is_playing = false
	enemy_manager.stop()
	mode_manager.stop()
	await _show_gameover_screen()
	await _show_menu()

# ─────────────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────────────
func _input(event: InputEvent):
	if is_playing and levelup_screen == null and evo_screen == null and victory_screen == null:
		snake._input(event)
