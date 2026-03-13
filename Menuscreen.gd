extends Control

signal mode_selected(mode)

func _ready():
	await get_tree().process_frame
	_build()

func _build():
	var screen = get_viewport().get_visible_rect().size

	var bg = ColorRect.new()
	bg.size = screen
	bg.color = Color(0, 0, 0, 0.92)
	add_child(bg)

	var title = Label.new()
	title.position = Vector2(0, screen.y * 0.12)
	title.size = Vector2(screen.x, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "SNAKE\nEATER"
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
	title.add_theme_font_size_override("font_size", 52)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(title)

	var sub = Label.new()
	sub.position = Vector2(0, screen.y * 0.33)
	sub.size = Vector2(screen.x, 28)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text = "SELECT MODE"
	sub.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	sub.add_theme_font_size_override("font_size", 16)
	add_child(sub)

	_make_btn("CAMPAIGN", "Story levels with objectives",
		Color(0.1, 0.4, 0.75), screen.y * 0.42, screen, "campaign")
	_make_btn("HORDE", "Endless survival — beat your score",
		Color(0.65, 0.12, 0.12), screen.y * 0.62, screen, "horde")

func _make_btn(label: String, desc: String, col: Color, y: float, screen: Vector2, mode_id: String):
	var w = screen.x - 60.0
	var h = 110.0
	var x = 30.0

	var btn = Button.new()
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE

	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = col
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	var style_press = style.duplicate()
	style_press.bg_color = col.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", style_press)

	var lbl = Label.new()
	lbl.position = Vector2(0, 12)
	lbl.size = Vector2(w, 44)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.text = label
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

	var dlbl = Label.new()
	dlbl.position = Vector2(0, 62)
	dlbl.size = Vector2(w, 36)
	dlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dlbl.text = desc
	dlbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	dlbl.add_theme_font_size_override("font_size", 14)
	dlbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(dlbl)

	btn.pressed.connect(func(): emit_signal("mode_selected", mode_id))
	add_child(btn)