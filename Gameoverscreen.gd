extends Control

signal continue_pressed()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_result(p_score: int, p_level: int):
	var screen = get_viewport_rect().size

	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.82)
	add_child(overlay)

	var title = Label.new()
	title.position = Vector2(0, screen.y * 0.25)
	title.size     = Vector2(screen.x, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = Loc.t("gameover_title")
	title.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	title.add_theme_font_size_override("font_size", 52)
	add_child(title)

	var sc = Label.new()
	sc.position = Vector2(0, screen.y * 0.44)
	sc.size     = Vector2(screen.x, 36)
	sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc.text = Loc.t("gameover_score", [p_score])
	sc.add_theme_color_override("font_color", Color.WHITE)
	sc.add_theme_font_size_override("font_size", 26)
	add_child(sc)

	var lv = Label.new()
	lv.position = Vector2(0, screen.y * 0.52)
	lv.size     = Vector2(screen.x, 30)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.text = Loc.t("gameover_level", [p_level])
	lv.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	lv.add_theme_font_size_override("font_size", 22)
	add_child(lv)

	var tip = Label.new()
	tip.position = Vector2(0, screen.y * 0.60)
	tip.size     = Vector2(screen.x, 26)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.text = Loc.t("gameover_tip")
	tip.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	tip.add_theme_font_size_override("font_size", 15)
	add_child(tip)

	var btn = Button.new()
	btn.position   = Vector2((screen.x - 220) / 2, screen.y * 0.70)
	btn.size       = Vector2(220, 60)
	btn.flat       = true
	btn.focus_mode = Control.FOCUS_NONE
	var bs = StyleBoxFlat.new(); bs.bg_color = Color(0.12, 0.55, 0.22)
	btn.add_theme_stylebox_override("normal", bs)
	var bsh = bs.duplicate(); bsh.bg_color = Color(0.16, 0.70, 0.28)
	btn.add_theme_stylebox_override("hover", bsh)
	var bsp = bs.duplicate(); bsp.bg_color = Color(0.08, 0.38, 0.15)
	btn.add_theme_stylebox_override("pressed", bsp)
	var bl = Label.new()
	bl.set_anchors_preset(Control.PRESET_FULL_RECT)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	bl.text = Loc.t("gameover_btn")
	bl.add_theme_color_override("font_color", Color.WHITE)
	bl.add_theme_font_size_override("font_size", 26)
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(bl)
	btn.pressed.connect(func(): emit_signal("continue_pressed"))
	add_child(btn)