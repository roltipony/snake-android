extends Control

signal level_chosen(index)
signal back_pressed()

var _level_db: Node = null

func _ready():
	pass

func setup(db: Node, _mm: Node):
	_level_db = db
	_build()

func _build():
	var screen = get_viewport().get_visible_rect().size

	var bg = ColorRect.new()
	bg.size = screen
	bg.color = Color(0, 0, 0, 0.92)
	add_child(bg)

	# Title
	var title = Label.new()
	title.position = Vector2(0, 16)
	title.size = Vector2(screen.x, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "CAMPAIGN"
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)

	# Back button
	var back_btn = Button.new()
	back_btn.position = Vector2(10, 10)
	back_btn.size = Vector2(110, 38)
	back_btn.flat = true
	back_btn.focus_mode = Control.FOCUS_NONE
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.22, 0.22, 0.22)
	back_btn.add_theme_stylebox_override("normal", bs)
	back_btn.add_theme_stylebox_override("hover", bs)
	var bs2 = bs.duplicate()
	bs2.bg_color = Color(0.35, 0.35, 0.35)
	back_btn.add_theme_stylebox_override("pressed", bs2)
	var bl = Label.new()
	bl.size = Vector2(110, 38)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bl.text = "← BACK"
	bl.add_theme_color_override("font_color", Color.WHITE)
	bl.add_theme_font_size_override("font_size", 14)
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_btn.add_child(bl)
	back_btn.pressed.connect(func(): emit_signal("back_pressed"))
	add_child(back_btn)

	# Level cards
	var card_h = 105.0
	var gap    = 10.0
	var start_y = 68.0
	var count = _level_db.get_level_count()
	for i in range(count):
		var lvl = _level_db.get_level(i)
		var cy  = start_y + i * (card_h + gap)
		var cw  = screen.x - 40.0
		_make_level_card(lvl, i, cy, cw)

func _make_level_card(lvl: Dictionary, index: int, y: float, w: float):
	var h = 105.0

	var btn = Button.new()
	btn.position = Vector2(20, y)
	btn.size = Vector2(w, h)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.11, 0.20)
	btn.add_theme_stylebox_override("normal", style)
	var style_h = style.duplicate()
	style_h.bg_color = Color(0.12, 0.18, 0.32)
	btn.add_theme_stylebox_override("hover", style_h)
	var style_p = style.duplicate()
	style_p.bg_color = Color(0.05, 0.08, 0.15)
	btn.add_theme_stylebox_override("pressed", style_p)

	# Left accent bar
	var bar = ColorRect.new()
	bar.size = Vector2(5, h)
	bar.color = Color(0.2, 0.5, 1.0)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(bar)

	var name_lbl = Label.new()
	name_lbl.position = Vector2(14, 10)
	name_lbl.size = Vector2(w - 20, 30)
	name_lbl.text = lvl.get("name", "Level %d" % (index + 1))
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.position = Vector2(14, 46)
	desc_lbl.size = Vector2(w - 24, 52)
	desc_lbl.text = lvl.get("description", "")
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(desc_lbl)

	btn.pressed.connect(func(): emit_signal("level_chosen", index))
	add_child(btn)