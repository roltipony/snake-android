extends CanvasLayer

# Muestra 2 mejoras de segmento al subir de nivel
# El jugador elige una; la seleccionada se añade al segmento nuevo

var upgrade_db: Node = null
var choices: Array = []
var chosen: Dictionary = {}

signal upgrade_chosen(upgrade_data)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_choices(db: Node, two_choices: Array):
	upgrade_db = db
	choices = two_choices
	_build_ui()

func _build_ui():
	var screen = get_viewport().get_visible_rect().size
	
	# Overlay oscuro semitransparente
	var overlay = ColorRect.new()
	overlay.size = screen
	overlay.color = Color(0, 0, 0, 0.82)
	add_child(overlay)
	
	# Título
	var title = Label.new()
	title.position = Vector2(0, screen.y * 0.1)
	title.size = Vector2(screen.x, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "¡NIVEL SUPERIOR!"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)
	
	var sub = Label.new()
	sub.position = Vector2(0, screen.y * 0.1 + 46)
	sub.size = Vector2(screen.x, 28)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text = "Elige una mejora para tu nuevo segmento"
	sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	sub.add_theme_font_size_override("font_size", 15)
	add_child(sub)
	
	# Tarjetas de elección
	var card_w = screen.x * 0.82
	var card_h = 210.0
	var gap = 24.0
	var total_h = card_h * 2 + gap
	var start_y = (screen.y - total_h) / 2 + 20
	
	for i in range(choices.size()):
		var upg = choices[i]
		var card_y = start_y + i * (card_h + gap)
		_build_card(upg, card_w, card_h, (screen.x - card_w) / 2, card_y, i)

func _build_card(upg: Dictionary, w: float, h: float, x: float, y: float, idx: int):
	var rarity_color = upgrade_db.get_rarity_color(upg["rarity"])
	var rarity_name = upgrade_db.get_rarity_name(upg["rarity"])
	
	# Fondo de la tarjeta
	var card = ColorRect.new()
	card.size = Vector2(w, h)
	card.position = Vector2(x, y)
	card.color = Color(0.07, 0.07, 0.15)
	card.set_meta("upgrade_idx", idx)
	card.set_meta("tap_rect", Rect2(Vector2(x, y), Vector2(w, h)))
	add_child(card)
	
	# Borde lateral de rareza
	var border = ColorRect.new()
	border.size = Vector2(6, h)
	border.color = rarity_color
	card.add_child(border)
	
	# Borde superior de rareza
	var border_top = ColorRect.new()
	border_top.size = Vector2(w, 4)
	border_top.color = rarity_color
	card.add_child(border_top)
	
	# Color del segmento (preview)
	var seg_preview = ColorRect.new()
	seg_preview.size = Vector2(52, 52)
	seg_preview.position = Vector2(16, (h - 52) / 2)
	seg_preview.color = upg["segment_color"]
	card.add_child(seg_preview)
	
	# Icono encima del preview
	var icon_lbl = Label.new()
	icon_lbl.position = Vector2(16, (h - 52) / 2)
	icon_lbl.size = Vector2(52, 52)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.text = upg["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 26)
	card.add_child(icon_lbl)
	
	# Nombre
	var name_lbl = Label.new()
	name_lbl.position = Vector2(80, 18)
	name_lbl.size = Vector2(w - 90, 30)
	name_lbl.text = upg["name"]
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_font_size_override("font_size", 20)
	card.add_child(name_lbl)
	
	# Rareza badge
	var rarity_lbl = Label.new()
	rarity_lbl.position = Vector2(80, 48)
	rarity_lbl.size = Vector2(w - 90, 22)
	rarity_lbl.text = "◆ " + rarity_name.to_upper()
	rarity_lbl.add_theme_color_override("font_color", rarity_color)
	rarity_lbl.add_theme_font_size_override("font_size", 12)
	card.add_child(rarity_lbl)
	
	# Descripción
	var desc_lbl = Label.new()
	desc_lbl.position = Vector2(80, 74)
	desc_lbl.size = Vector2(w - 92, 80)
	desc_lbl.text = upg["description"]
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(desc_lbl)
	
	# Botón ELEGIR
	var btn = ColorRect.new()
	btn.size = Vector2(w - 90, 36)
	btn.position = Vector2(80, h - 48)
	btn.color = rarity_color.darkened(0.3)
	card.add_child(btn)
	
	var btn_lbl = Label.new()
	btn_lbl.size = btn.size
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.text = "ELEGIR"
	btn_lbl.add_theme_color_override("font_color", Color.WHITE)
	btn_lbl.add_theme_font_size_override("font_size", 16)
	btn.add_child(btn_lbl)

func _input(event: InputEvent):
	var tap_pos = Vector2(-9999, -9999)
	if event is InputEventScreenTouch and event.pressed:
		tap_pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap_pos = event.position
	
	if tap_pos.x == -9999:
		return
	
	get_viewport().set_input_as_handled()
	
	for child in get_children():
		if child.has_meta("tap_rect"):
			var rect: Rect2 = child.get_meta("tap_rect")
			if rect.has_point(tap_pos):
				var idx = child.get_meta("upgrade_idx")
				chosen = choices[idx]
				emit_signal("upgrade_chosen", chosen)
				return