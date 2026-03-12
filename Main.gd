extends Node2D

# Referencias a nodos hijo
var snake: Node2D
var enemy_manager: Node2D
var hud: CanvasLayer
var game_over_screen: CanvasLayer

var score: int = 0
var is_playing: bool = false

const GRID_SIZE: int = 40

func _ready():
	add_to_group("main")
	_build_background()
	_setup_nodes()
	_show_start_screen()

func _build_background():
	var screen = get_viewport_rect().size
	
	# Fondo oscuro
	var bg = ColorRect.new()
	bg.size = screen
	bg.color = Color(0.05, 0.05, 0.1)
	add_child(bg)
	
	# Grid sutil
	var grid_node = Node2D.new()
	add_child(grid_node)
	
	var grid_width = int(screen.x / GRID_SIZE)
	var grid_height = int(screen.y / GRID_SIZE)
	
	for x in range(grid_width + 1):
		var line = ColorRect.new()
		line.size = Vector2(1, screen.y)
		line.position = Vector2(x * GRID_SIZE, 0)
		line.color = Color(1, 1, 1, 0.03)
		grid_node.add_child(line)
	
	for y in range(grid_height + 1):
		var line = ColorRect.new()
		line.size = Vector2(screen.x, 1)
		line.position = Vector2(0, y * GRID_SIZE)
		line.color = Color(1, 1, 1, 0.03)
		grid_node.add_child(line)

func _setup_nodes():
	# Serpiente
	snake = Node2D.new()
	snake.set_script(load("res://Snake.gd"))
	add_child(snake)
	snake.connect("health_changed", _on_snake_health_changed)
	snake.connect("died", _on_snake_died)
	snake.connect("ate_enemy", _on_ate_enemy)
	
	# Enemy Manager
	enemy_manager = Node2D.new()
	enemy_manager.set_script(load("res://EnemyManager.gd"))
	add_child(enemy_manager)
	enemy_manager.connect("enemy_eaten", _on_enemy_eaten_score)
	
	# HUD
	hud = CanvasLayer.new()
	hud.set_script(load("res://HUD.gd"))
	add_child(hud)
	
	# Pantalla game over
	game_over_screen = CanvasLayer.new()
	_build_game_over_screen()
	add_child(game_over_screen)
	game_over_screen.visible = false

func _build_game_over_screen():
	var screen = get_viewport_rect().size
	
	var overlay = ColorRect.new()
	overlay.size = screen
	overlay.color = Color(0, 0, 0, 0.75)
	game_over_screen.add_child(overlay)
	
	var title = Label.new()
	title.position = Vector2(0, screen.y * 0.3)
	title.size = Vector2(screen.x, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "GAME OVER"
	title.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	title.add_theme_font_size_override("font_size", 48)
	game_over_screen.add_child(title)
	
	var score_lbl = Label.new()
	score_lbl.name = "ScoreLabel"
	score_lbl.position = Vector2(0, screen.y * 0.45)
	score_lbl.size = Vector2(screen.x, 40)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.text = "Score: 0"
	score_lbl.add_theme_color_override("font_color", Color.WHITE)
	score_lbl.add_theme_font_size_override("font_size", 26)
	game_over_screen.add_child(score_lbl)
	
	var tip = Label.new()
	tip.position = Vector2(0, screen.y * 0.55)
	tip.size = Vector2(screen.x, 40)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.text = "¡Come enemigos para curarte!"
	tip.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	tip.add_theme_font_size_override("font_size", 18)
	game_over_screen.add_child(tip)
	
	# Botón reiniciar
	var restart_btn = ColorRect.new()
	restart_btn.size = Vector2(220, 60)
	restart_btn.position = Vector2((screen.x - 220) / 2, screen.y * 0.68)
	restart_btn.color = Color(0.15, 0.6, 0.25)
	game_over_screen.add_child(restart_btn)
	
	var btn_label = Label.new()
	btn_label.size = Vector2(220, 60)
	btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_label.text = "REINICIAR"
	btn_label.add_theme_color_override("font_color", Color.WHITE)
	btn_label.add_theme_font_size_override("font_size", 24)
	restart_btn.add_child(btn_label)
	
	# Input para el botón
	var btn_area = TouchScreenButton.new()
	btn_area.position = restart_btn.position
	game_over_screen.add_child(btn_area)

func _show_start_screen():
	var screen = get_viewport_rect().size
	var start_overlay = CanvasLayer.new()
	start_overlay.name = "StartScreen"
	
	var bg = ColorRect.new()
	bg.size = screen
	bg.color = Color(0, 0, 0, 0.8)
	start_overlay.add_child(bg)
	
	var title = Label.new()
	title.position = Vector2(0, screen.y * 0.2)
	title.size = Vector2(screen.x, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "SNAKE\nEATER"
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
	title.add_theme_font_size_override("font_size", 52)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	start_overlay.add_child(title)
	
	var desc = Label.new()
	desc.position = Vector2(20, screen.y * 0.45)
	desc.size = Vector2(screen.x - 40, 100)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.text = "Los enemigos te disparan\n¡Cómetelos para curar tu vida!\nDesliza para moverte"
	desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	desc.add_theme_font_size_override("font_size", 18)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	start_overlay.add_child(desc)
	
	# Leyenda enemigos
	var legend_y = screen.y * 0.62
	var legends = [
		["🔴 Básico", "Disparo lento, 10pts"],
		["🟠 Rápido", "Disparo rápido, 20pts"],
		["🟣 Tanque", "Mucho daño, 30pts"]
	]
	for i in range(legends.size()):
		var lbl = Label.new()
		lbl.position = Vector2(20, legend_y + i * 30)
		lbl.size = Vector2(screen.x - 40, 28)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.text = "%s — %s" % [legends[i][0], legends[i][1]]
		lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
		lbl.add_theme_font_size_override("font_size", 16)
		start_overlay.add_child(lbl)
	
	var start_btn = ColorRect.new()
	start_btn.size = Vector2(220, 65)
	start_btn.position = Vector2((screen.x - 220) / 2, screen.y * 0.83)
	start_btn.color = Color(0.15, 0.6, 0.25)
	start_overlay.add_child(start_btn)
	
	var btn_lbl = Label.new()
	btn_lbl.size = Vector2(220, 65)
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.text = "JUGAR"
	btn_lbl.add_theme_color_override("font_color", Color.WHITE)
	btn_lbl.add_theme_font_size_override("font_size", 28)
	start_btn.add_child(btn_lbl)
	
	add_child(start_overlay)
	
	# Esperar toque para empezar
	await _wait_for_touch()
	start_overlay.queue_free()
	_start_game()

var _waiting_for_touch: bool = false

func _wait_for_touch() -> void:
	_waiting_for_touch = true
	while _waiting_for_touch:
		await get_tree().process_frame

func _unhandled_input(event: InputEvent):
	if _waiting_for_touch:
		if event is InputEventScreenTouch and event.pressed:
			_waiting_for_touch = false
		elif event is InputEventKey and event.pressed:
			_waiting_for_touch = false

func _start_game():
	score = 0
	is_playing = true
	snake.reset()
	enemy_manager.setup(snake)
	if hud:
		hud.update_score(0)
	game_over_screen.visible = false

func on_snake_moved(head_pos: Vector2):
	if not is_playing:
		return
	enemy_manager.check_snake_eat_enemy()

func _on_snake_health_changed(new_health: int, max_health: int):
	if hud:
		hud.update_health(new_health, max_health)

func _on_snake_died():
	is_playing = false
	var score_lbl = game_over_screen.get_node_or_null("ScoreLabel")
	if score_lbl:
		score_lbl.text = "Score: %d" % score
	game_over_screen.visible = true
	
	# Esperar toque para reiniciar
	await _wait_for_touch()
	_start_game()

func _on_ate_enemy():
	if hud:
		hud.show_message("+VIDA", Color(0.2, 1.0, 0.4))

func _on_enemy_eaten_score(points: int):
	score += points
	if hud:
		hud.update_score(score)

func _input(event: InputEvent):
	# Pasar input a la serpiente
	if is_playing and is_instance_valid(snake):
		snake._input(event)