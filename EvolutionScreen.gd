extends Control

var evo_sys: Node = null
var points_label: Label
var card_nodes: Array = []

signal ready_to_play()

func _ready():
	pass

func setup(evolution_system: Node):
	evo_sys = evolution_system
	_build_ui()

func _build_ui():
	var screen = get_viewport().get_visible_rect().size

	var bg = ColorRect.new()
	bg.size = screen
	bg.color = Color(0.04, 0.04, 0.1)
	add_child(bg)

	var title = Label.new()
	title.position = Vector2(0, 30)
	title.size = Vector2(screen.x, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = Loc.t("traits_title")
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5))
	title.add_theme_font_size_override("font_size", 36)
	add_child(title)

	var subtitle = Label.new()
	subtitle.position = Vector2(0, 75)
	subtitle.size = Vector2(screen.x, 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = Loc.t("traits_subtitle")
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	subtitle.add_theme_font_size_override("font_size", 15)
	add_child(subtitle)

	var points_panel = ColorRect.new()
	points_panel.size = Vector2(screen.x - 40, 44)
	points_panel.position = Vector2(20, 110)
	points_panel.color = Color(0.1, 0.1, 0.2)
	add_child(points_panel)

	points_label = Label.new()
	points_label.position = Vector2(28, 110)
	points_label.size = Vector2(screen.x - 56, 44)
	points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 15)
	add_child(points_label)
	_refresh_points_label()

	var card_y_start = 175.0
	var card_h = 148.0
	var card_gap = 12.0
	var upgrades = evo_sys.UPGRADES
	var idx = 0
	for key in upgrades:
		var upg = upgrades[key]
		var card_y = card_y_start + idx * (card_h + card_gap)
		_build_upgrade_card(upg, card_y, screen.x)
		idx += 1

	# PLAY button — uses Button node so mouse works
	var btn_y = card_y_start + upgrades.size() * (card_h + card_gap) + 20
	var play_btn = Button.new()
	play_btn.position = Vector2(30, btn_y)
	play_btn.size = Vector2(screen.x - 60, 65)
	play_btn.flat = true
	play_btn.focus_mode = Control.FOCUS_NONE
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.1, 0.55, 0.2)
	play_btn.add_theme_stylebox_override("normal", ps)
	var ps_h = ps.duplicate(); ps_h.bg_color = Color(0.14, 0.7, 0.26)
	play_btn.add_theme_stylebox_override("hover", ps_h)
	var ps_p = ps.duplicate(); ps_p.bg_color = Color(0.07, 0.38, 0.14)
	play_btn.add_theme_stylebox_override("pressed", ps_p)
	var pl = Label.new()
	pl.size = Vector2(screen.x - 60, 65)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pl.text = Loc.t("traits_play")
	pl.add_theme_color_override("font_color", Color.WHITE)
	pl.add_theme_font_size_override("font_size", 26)
	pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_btn.add_child(pl)
	play_btn.pressed.connect(func(): emit_signal("ready_to_play"))
	add_child(play_btn)

func _build_upgrade_card(upg: Dictionary, y: float, screen_w: float):
	var card_w = screen_w - 40
	var card_h = 148.0
	var is_eq = evo_sys.is_equipped(upg["id"])

	var card = ColorRect.new()
	card.name = "Card_" + upg["id"]
	card.size = Vector2(card_w, card_h)
	card.position = Vector2(20, y)
	card.color = Color(0.08, 0.22, 0.12) if is_eq else Color(0.08, 0.08, 0.18)
	add_child(card)
	card_nodes.append(card)

	var border = ColorRect.new()
	border.name = "Border"
	border.size = Vector2(5, card_h)
	border.color = upg["color"] if is_eq else Color(0.25, 0.25, 0.35)
	card.add_child(border)

	var icon_lbl = Label.new()
	icon_lbl.position = Vector2(14, 10)
	icon_lbl.size = Vector2(50, 50)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.text = upg["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 30)
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_lbl)

	var name_lbl = Label.new()
	name_lbl.position = Vector2(70, 10)
	name_lbl.size = Vector2(card_w - 80, 30)
	name_lbl.text = Loc.t(upg.get("name_key", "???"))
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.position = Vector2(70, 42)
	desc_lbl.size = Vector2(card_w - 80, 55)
	desc_lbl.text = Loc.t(upg.get("desc_key", "???"))
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc_lbl)

	var cost_lbl = Label.new()
	cost_lbl.position = Vector2(14, 104)
	cost_lbl.size = Vector2(120, 28)
	cost_lbl.text = "⚙️ %d TP" % upg["cost"]
	cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	cost_lbl.add_theme_font_size_override("font_size", 14)
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(cost_lbl)

	# Equip button — Button node
	var eq_btn = Button.new()
	eq_btn.name = "EquipBtn"
	eq_btn.size = Vector2(130, 34)
	eq_btn.position = Vector2(card_w - 140, 104)
	eq_btn.flat = true
	eq_btn.focus_mode = Control.FOCUS_NONE
	_style_equip_btn(eq_btn, is_eq, evo_sys.can_equip(upg["id"]))
	eq_btn.pressed.connect(_on_equip_pressed.bind(upg["id"]))
	card.add_child(eq_btn)

	var eq_lbl = Label.new()
	eq_lbl.name = "EquipLabel"
	eq_lbl.size = Vector2(130, 34)
	eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eq_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eq_lbl.text = Loc.t("traits_unequip") if is_eq else Loc.t("traits_equip")
	eq_lbl.add_theme_color_override("font_color", Color.WHITE)
	eq_lbl.add_theme_font_size_override("font_size", 15)
	eq_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eq_btn.add_child(eq_lbl)

	card.set_meta("upgrade_id", upg["id"])

func _style_equip_btn(btn: Button, is_eq: bool, can_eq: bool):
	var col: Color
	if is_eq:        col = Color(0.6, 0.1, 0.1)
	elif can_eq:     col = Color(0.1, 0.5, 0.8)
	else:            col = Color(0.25, 0.25, 0.25)
	var s = StyleBoxFlat.new()
	s.bg_color = col
	btn.add_theme_stylebox_override("normal", s)
	var sh = s.duplicate(); sh.bg_color = col.lightened(0.15)
	btn.add_theme_stylebox_override("hover", sh)
	var sp = s.duplicate(); sp.bg_color = col.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", sp)

func _on_equip_pressed(uid: String):
	evo_sys.toggle_upgrade(uid)
	_refresh_points_label()
	_refresh_cards()

func _refresh_cards():
	for card in card_nodes:
		if not is_instance_valid(card): continue
		var uid = card.get_meta("upgrade_id")
		var upg = evo_sys.UPGRADES[uid]
		var is_eq  = evo_sys.is_equipped(uid)
		var can_eq = evo_sys.can_equip(uid)
		card.color = Color(0.08, 0.22, 0.12) if is_eq else Color(0.08, 0.08, 0.18)
		var border = card.get_node_or_null("Border")
		if border: border.color = upg["color"] if is_eq else Color(0.25, 0.25, 0.35)
		var eq_btn = card.get_node_or_null("EquipBtn")
		var eq_lbl = card.get_node_or_null("EquipBtn/EquipLabel")
		if eq_btn:
			_style_equip_btn(eq_btn, is_eq, can_eq)
		if eq_lbl:
			if is_eq:    eq_lbl.text = Loc.t("traits_unequip")
			elif can_eq: eq_lbl.text = Loc.t("traits_equip")
			else:        eq_lbl.text = Loc.t("traits_no_points")

func _refresh_points_label():
	var used      = evo_sys.get_points_used()
	var remaining = evo_sys.get_points_remaining()
	var max_ep    = evo_sys.MAX_EVOLUTION_POINTS
	points_label.text = Loc.t("traits_points", [used, max_ep, remaining])
	var col = Color(1.0, 0.4, 0.4) if remaining == 0 else Color(0.85, 0.85, 0.85)
	points_label.add_theme_color_override("font_color", col)