extends Control

var upgrade_db: Node = null
var choices: Array = []

signal upgrade_chosen(upgrade_data)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_choices(db: Node, two_choices: Array):
	upgrade_db = db
	choices = two_choices
	_build_ui()

func _build_ui():
	var screen = get_viewport().get_visible_rect().size

	var overlay = ColorRect.new()
	overlay.size = screen
	overlay.color = Color(0, 0, 0, 0.82)
	add_child(overlay)

	var title = Label.new()
	title.position = Vector2(0, screen.y * 0.08)
	title.size = Vector2(screen.x, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = Loc.t("levelup_title")
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)

	var sub = Label.new()
	sub.position = Vector2(0, screen.y * 0.08 + 46)
	sub.size = Vector2(screen.x, 28)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text = Loc.t("levelup_subtitle")
	sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	sub.add_theme_font_size_override("font_size", 15)
	add_child(sub)

	var card_w = screen.x * 0.82
	var card_h = 210.0
	var gap    = 24.0
	var total_h = card_h * 2 + gap
	var start_y = (screen.y - total_h) / 2 + 20

	for i in range(choices.size()):
		var upg   = choices[i]
		var card_y = start_y + i * (card_h + gap)
		_build_card(upg, card_w, card_h, (screen.x - card_w) / 2, card_y, i)

func _build_card(upg: Dictionary, w: float, h: float, x: float, y: float, idx: int):
	var rarity_color = upgrade_db.get_rarity_color(upg["rarity"])
	var rarity_name  = upgrade_db.get_rarity_name(upg["rarity"])

	# Use a Button as the card so mouse clicks work
	var card = Button.new()
	card.position = Vector2(x, y)
	card.size = Vector2(w, h)
	card.flat = true
	card.focus_mode = Control.FOCUS_NONE
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.07, 0.07, 0.15)
	card.add_theme_stylebox_override("normal", s)
	var sh = s.duplicate(); sh.bg_color = Color(0.11, 0.11, 0.22)
	card.add_theme_stylebox_override("hover", sh)
	var sp = s.duplicate(); sp.bg_color = Color(0.04, 0.04, 0.1)
	card.add_theme_stylebox_override("pressed", sp)
	card.pressed.connect(func(): emit_signal("upgrade_chosen", choices[idx]))
	add_child(card)

	var border = ColorRect.new()
	border.size = Vector2(6, h)
	border.color = rarity_color
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(border)

	var border_top = ColorRect.new()
	border_top.size = Vector2(w, 4)
	border_top.color = rarity_color
	border_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(border_top)

	var seg_preview = ColorRect.new()
	seg_preview.size = Vector2(52, 52)
	seg_preview.position = Vector2(16, (h - 52) / 2)
	seg_preview.color = upg["segment_color"]
	seg_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(seg_preview)

	var icon_lbl = Label.new()
	icon_lbl.position = Vector2(16, (h - 52) / 2)
	icon_lbl.size = Vector2(52, 52)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.text = upg["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 26)
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_lbl)

	var name_lbl = Label.new()
	name_lbl.position = Vector2(80, 18)
	name_lbl.size = Vector2(w - 90, 30)
	name_lbl.text = Loc.t(upg.get("name_key", "???"))
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	var rarity_lbl = Label.new()
	rarity_lbl.position = Vector2(80, 48)
	rarity_lbl.size = Vector2(w - 90, 22)
	rarity_lbl.text = "◆ " + rarity_name.to_upper()
	rarity_lbl.add_theme_color_override("font_color", rarity_color)
	rarity_lbl.add_theme_font_size_override("font_size", 12)
	rarity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rarity_lbl)

	var desc_lbl = Label.new()
	desc_lbl.position = Vector2(80, 74)
	desc_lbl.size = Vector2(w - 92, 80)
	desc_lbl.text = Loc.t(upg.get("desc_key", "???"))
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc_lbl)

	# SELECT button inside card
	var pick_btn = Button.new()
	pick_btn.position = Vector2(80, h - 48)
	pick_btn.size = Vector2(w - 90, 36)
	pick_btn.flat = true
	pick_btn.focus_mode = Control.FOCUS_NONE
	var bs = StyleBoxFlat.new()
	bs.bg_color = rarity_color.darkened(0.3)
	pick_btn.add_theme_stylebox_override("normal", bs)
	var bsh = bs.duplicate(); bsh.bg_color = rarity_color.darkened(0.1)
	pick_btn.add_theme_stylebox_override("hover", bsh)
	pick_btn.pressed.connect(func(): emit_signal("upgrade_chosen", choices[idx]))
	var pl = Label.new()
	pl.size = Vector2(w - 90, 36)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pl.text = Loc.t("levelup_pick")
	pl.add_theme_color_override("font_color", Color.WHITE)
	pl.add_theme_font_size_override("font_size", 16)
	pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pick_btn.add_child(pl)
	card.add_child(pick_btn)