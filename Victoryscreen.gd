extends Control

signal continue_pressed()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_victory(level_name: String, score: int, snake_lvl: int):
	_build(level_name, score, snake_lvl)

func _build(level_name: String, score: int, snake_lvl: int):
	var screen = get_viewport().get_visible_rect().size

	var overlay = ColorRect.new()
	overlay.size = screen
	overlay.color = Color(0, 0, 0, 0.82)
	add_child(overlay)

	var title = Label.new()
	title.position = Vector2(0, screen.y * 0.22)
	title.size = Vector2(screen.x, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "LEVEL COMPLETE!"
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	title.add_theme_font_size_override("font_size", 38)
	add_child(title)

	var name_lbl = Label.new()
	name_lbl.position = Vector2(0, screen.y * 0.34)
	name_lbl.size = Vector2(screen.x, 30)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text = level_name
	name_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	name_lbl.add_theme_font_size_override("font_size", 17)
	add_child(name_lbl)

	var score_lbl = Label.new()
	score_lbl.position = Vector2(0, screen.y * 0.44)
	score_lbl.size = Vector2(screen.x, 32)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.text = "Score: %d" % score
	score_lbl.add_theme_color_override("font_color", Color.WHITE)
	score_lbl.add_theme_font_size_override("font_size", 22)
	add_child(score_lbl)

	var lvl_lbl = Label.new()
	lvl_lbl.position = Vector2(0, screen.y * 0.52)
	lvl_lbl.size = Vector2(screen.x, 28)
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.text = "Snake Level: %d" % snake_lvl
	lvl_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	lvl_lbl.add_theme_font_size_override("font_size", 18)
	add_child(lvl_lbl)

	var btn = Button.new()
	btn.position = Vector2((screen.x - 220) / 2, screen.y * 0.66)
	btn.size = Vector2(220, 60)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.5, 0.2)
	btn.add_theme_stylebox_override("normal", style)
	var style_h = style.duplicate()
	style_h.bg_color = Color(0.15, 0.65, 0.28)
	btn.add_theme_stylebox_override("hover", style_h)
	var style_p = style.duplicate()
	style_p.bg_color = Color(0.07, 0.35, 0.14)
	btn.add_theme_stylebox_override("pressed", style_p)
	var btn_lbl = Label.new()
	btn_lbl.size = Vector2(220, 60)
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.text = "CONTINUE"
	btn_lbl.add_theme_color_override("font_color", Color.WHITE)
	btn_lbl.add_theme_font_size_override("font_size", 24)
	btn_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(btn_lbl)
	btn.pressed.connect(func(): emit_signal("continue_pressed"))
	add_child(btn)