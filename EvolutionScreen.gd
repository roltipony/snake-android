extends CanvasLayer

# Referencia al sistema de evolución
var evo_sys: Node = null

# UI refs
var points_label: Label
var card_nodes: Array = []
var play_btn: ColorRect
var play_btn_label: Label

signal ready_to_play()

func _ready():
	pass

func setup(evolution_system: Node):
	evo_sys = evolution_system
	_build_ui()

func _build_ui():
	var screen = get_viewport().get_visible_rect().size
	
	# Fondo
	var bg = ColorRect.new()
	bg.size = screen
	bg.color = Color(0.04, 0.04, 0.1)
	add_child(bg)
	
	# Título
	var title = Label.new()
	title.position = Vector2(0, 30)
	title.size = Vector2(screen.x, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "EVOLUCIÓN"
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5))
	title.add_theme_font_size_override("font_size", 36)
	add_child(title)
	
	var subtitle = Label.new()
	subtitle.position = Vector2(0, 75)
	subtitle.size = Vector2(screen.x, 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = "Equipa mejoras antes de jugar"
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	subtitle.add_theme_font_size_override("font_size", 15)
	add_child(subtitle)
	
	# Panel de puntos
	var points_panel = ColorRect.new()
	points_panel.size = Vector2(screen.x - 40, 44)
	points_panel.position = Vector2(20, 110)
	points_panel.color = Color(0.1, 0.1, 0.2)
	add_child(points_panel)
	
	var ep_icon = Label.new()
	ep_icon.position = Vector2(30, 110)
	ep_icon.size = Vector2(44, 44)
	ep_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ep_icon.text = "⚙️"
	ep_icon.add_theme_font_size_override("font_size", 22)
	add_child(ep_icon)
	
	points_label = Label.new()
	points_label.position = Vector2(70, 110)
	points_label.size = Vector2(screen.x - 90, 44)
	points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 17)
	add_child(points_label)
	_refresh_points_label()
	
	# Tarjetas de mejoras
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
	
	# Separador
	var sep = ColorRect.new()
	sep.size = Vector2(screen.x - 40, 2)
	sep.position = Vector2(20, card_y_start + upgrades.size() * (card_h + card_gap) + 4)
	sep.color = Color(0.2, 0.2, 0.3)
	add_child(sep)
	
	# Botón JUGAR
	var btn_y = card_y_start + upgrades.size() * (card_h + card_gap) + 20
	play_btn = ColorRect.new()
	play_btn.size = Vector2(screen.x - 60, 65)
	play_btn.position = Vector2(30, btn_y)
	play_btn.color = Color(0.1, 0.55, 0.2)
	add_child(play_btn)
	
	play_btn_label = Label.new()
	play_btn_label.size = play_btn.size
	play_btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_btn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	play_btn_label.text = "▶  JUGAR"
	play_btn_label.add_theme_color_override("font_color", Color.WHITE)
	play_btn_label.add_theme_font_size_override("font_size", 26)
	play_btn.add_child(play_btn_label)

func _build_upgrade_card(upg: Dictionary, y: float, screen_w: float):
	var card_w = screen_w - 40
	var card_h = 148.0
	var is_eq = evo_sys.is_equipped(upg["id"])
	
	# Panel de fondo
	var card = ColorRect.new()
	card.name = "Card_" + upg["id"]
	card.size = Vector2(card_w, card_h)
	card.position = Vector2(20, y)
	card.color = Color(0.08, 0.08, 0.18) if not is_eq else Color(0.08, 0.22, 0.12)
	add_child(card)
	card_nodes.append(card)
	
	# Borde de color
	var border = ColorRect.new()
	border.name = "Border"
	border.size = Vector2(5, card_h)
	border.position = Vector2.ZERO
	border.color = upg["color"] if is_eq else Color(0.25, 0.25, 0.35)
	card.add_child(border)
	
	# Icono
	var icon_lbl = Label.new()
	icon_lbl.position = Vector2(14, 10)
	icon_lbl.size = Vector2(50, 50)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.text = upg["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 30)
	card.add_child(icon_lbl)
	
	# Nombre
	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.position = Vector2(70, 10)
	name_lbl.size = Vector2(card_w - 80, 30)
	name_lbl.text = upg["name"]
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_font_size_override("font_size", 18)
	card.add_child(name_lbl)
	
	# Descripción
	var desc_lbl = Label.new()
	desc_lbl.position = Vector2(70, 42)
	desc_lbl.size = Vector2(card_w - 80, 55)
	desc_lbl.text = upg["description"]
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(desc_lbl)
	
	# Costo
	var cost_lbl = Label.new()
	cost_lbl.name = "CostLabel"
	cost_lbl.position = Vector2(14, 100)
	cost_lbl.size = Vector2(120, 28)
	cost_lbl.text = "⚙️ %d EP" % upg["cost"]
	cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	cost_lbl.add_theme_font_size_override("font_size", 14)
	card.add_child(cost_lbl)
	
	# Botón equipar/desequipar
	var eq_btn = ColorRect.new()
	eq_btn.name = "EquipBtn"
	eq_btn.size = Vector2(130, 34)
	eq_btn.position = Vector2(card_w - 140, 100)
	eq_btn.color = Color(0.1, 0.5, 0.8) if not is_eq else Color(0.6, 0.1, 0.1)
	card.add_child(eq_btn)
	
	var eq_lbl = Label.new()
	eq_lbl.name = "EquipLabel"
	eq_lbl.size = Vector2(130, 34)
	eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eq_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eq_lbl.text = "EQUIPAR" if not is_eq else "QUITAR"
	eq_lbl.add_theme_color_override("font_color", Color.WHITE)
	eq_lbl.add_theme_font_size_override("font_size", 15)
	eq_btn.add_child(eq_lbl)
	
	# Guardar upgrade id en metadata del card para el input
	card.set_meta("upgrade_id", upg["id"])
	card.set_meta("btn_rect", Rect2(card.position + eq_btn.position, eq_btn.size))

func _refresh_cards():
	for card in card_nodes:
		if not is_instance_valid(card):
			continue
		var uid = card.get_meta("upgrade_id")
		var upg = evo_sys.UPGRADES[uid]
		var is_eq = evo_sys.is_equipped(uid)
		var can_eq = evo_sys.can_equip(uid)
		
		# Fondo tarjeta
		card.color = Color(0.08, 0.22, 0.12) if is_eq else Color(0.08, 0.08, 0.18)
		
		# Borde
		var border = card.get_node_or_null("Border")
		if border:
			border.color = upg["color"] if is_eq else Color(0.25, 0.25, 0.35)
		
		# Botón
		var eq_btn = card.get_node_or_null("EquipBtn")
		var eq_lbl = card.get_node_or_null("EquipBtn/EquipLabel") 
		if eq_btn and eq_lbl:
			if is_eq:
				eq_btn.color = Color(0.6, 0.1, 0.1)
				eq_lbl.text = "QUITAR"
			elif can_eq:
				eq_btn.color = Color(0.1, 0.5, 0.8)
				eq_lbl.text = "EQUIPAR"
			else:
				eq_btn.color = Color(0.25, 0.25, 0.25)
				eq_lbl.text = "SIN EP"
		
		# Actualizar rect del botón para input
		if eq_btn:
			card.set_meta("btn_rect", Rect2(card.position + eq_btn.position, eq_btn.size))

func _refresh_points_label():
	var used = evo_sys.get_points_used()
	var remaining = evo_sys.get_points_remaining()
	var max_ep = evo_sys.MAX_EVOLUTION_POINTS
	points_label.text = "Evolution Points:  %d / %d  (disponibles: %d)" % [used, max_ep, remaining]
	if remaining == 0:
		points_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	else:
		points_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

func _input(event: InputEvent):
	var tap_pos: Vector2 = Vector2(-999, -999)
	
	if event is InputEventScreenTouch and event.pressed:
		tap_pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap_pos = event.position
	
	if tap_pos == Vector2(-999, -999):
		return
	
	# Consumir SIEMPRE el evento para que no llegue a Main
	get_viewport().set_input_as_handled()
	
	# ¿Tocó el botón JUGAR?
	if is_instance_valid(play_btn):
		var play_rect = Rect2(play_btn.position, play_btn.size)
		if play_rect.has_point(tap_pos):
			emit_signal("ready_to_play")
			return
	
	# ¿Tocó algún botón de mejora?
	for card in card_nodes:
		if not is_instance_valid(card):
			continue
		var btn_rect: Rect2 = card.get_meta("btn_rect")
		if btn_rect.has_point(tap_pos):
			var uid = card.get_meta("upgrade_id")
			var success = evo_sys.toggle_upgrade(uid)
			if not success:
				points_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
			_refresh_points_label()
			_refresh_cards()
			return