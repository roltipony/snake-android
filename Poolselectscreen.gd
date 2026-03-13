extends Control

# =====================================================
# POOL SELECT SCREEN
# - Click      → muestra descripción
# - Doble click → añade/quita del pool (orden inserción)
# - Click en inventario → quita del pool
# - Cualquier rareza se puede añadir libremente
# - PLAY bloqueado hasta que haya >= 3 COMMON en pool
# =====================================================

signal pool_confirmed(pool)

var _db: Node = null
var _pool: Array = []   # orden de inserción, sin sort

var _last_click_id:   String = ""
var _last_click_time: float  = 0.0
const DOUBLE_CLICK_SEC: float = 0.4

var _info_name:      Label   = null
var _info_desc:      Label   = null
var _info_rarity:    Label   = null
var _inventory_grid: Control = null
var _rule_label:     Label   = null
var _confirm_btn:    Button  = null
var _confirm_lbl:    Label   = null
var _grid_cells:     Array   = []

const MAX_POOL:         int = 6
const COMMONS_REQUIRED: int = 3
const CELL_SZ:          float = 52.0
const CELL_GAP:         float = 8.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(db: Node):
	_db = db
	await get_tree().process_frame
	_build()

# ─────────────────────────────────────────────────────
func _build():
	var W = size.x if size.x > 0 else get_viewport_rect().size.x

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.10)
	add_child(bg)

	var title = Label.new()
	title.position = Vector2(0, 10)
	title.size     = Vector2(W, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "BUILD YOUR POOL"
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	title.add_theme_font_size_override("font_size", 24)
	add_child(title)

	var sub = Label.new()
	sub.position = Vector2(0, 44)
	sub.size     = Vector2(W, 20)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text = "Double-click to add  ·  Click inventory slot to remove"
	sub.add_theme_color_override("font_color", Color(0.42, 0.42, 0.42))
	sub.add_theme_font_size_override("font_size", 12)
	add_child(sub)

	_rule_label = Label.new()
	_rule_label.position = Vector2(0, 64)
	_rule_label.size     = Vector2(W, 18)
	_rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rule_label.add_theme_font_size_override("font_size", 12)
	add_child(_rule_label)

	# Info panel
	var info_bg = ColorRect.new()
	info_bg.position = Vector2(10, 84)
	info_bg.size     = Vector2(W - 20, 68)
	info_bg.color    = Color(0.08, 0.08, 0.18)
	add_child(info_bg)

	_info_name = Label.new()
	_info_name.position = Vector2(10, 6)
	_info_name.size     = Vector2(W - 130, 22)
	_info_name.add_theme_color_override("font_color", Color.WHITE)
	_info_name.add_theme_font_size_override("font_size", 15)
	info_bg.add_child(_info_name)

	_info_rarity = Label.new()
	_info_rarity.position = Vector2(W - 120, 6)
	_info_rarity.size     = Vector2(100, 22)
	_info_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_info_rarity.add_theme_font_size_override("font_size", 12)
	info_bg.add_child(_info_rarity)

	_info_desc = Label.new()
	_info_desc.position = Vector2(10, 28)
	_info_desc.size     = Vector2(W - 40, 38)
	_info_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_info_desc.add_theme_font_size_override("font_size", 12)
	_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_bg.add_child(_info_desc)

	_show_info(null)

	# Grid de todas las mejoras
	var grid_y = 160.0
	var cols   = int((W - 20) / (CELL_SZ + CELL_GAP))
	for i in range(_db.ALL_UPGRADES.size()):
		var upg = _db.ALL_UPGRADES[i]
		var cx  = 10.0 + (i % cols) * (CELL_SZ + CELL_GAP)
		var cy  = grid_y + (i / cols) * (CELL_SZ + CELL_GAP)
		_make_cell(upg, cx, cy)

	var rows  = ceil(float(_db.ALL_UPGRADES.size()) / cols)
	var inv_y = grid_y + rows * (CELL_SZ + CELL_GAP) + 10

	var sep = ColorRect.new()
	sep.position = Vector2(10, inv_y - 4)
	sep.size     = Vector2(W - 20, 1)
	sep.color    = Color(0.2, 0.2, 0.32)
	add_child(sep)

	var inv_title = Label.new()
	inv_title.name     = "InvTitle"
	inv_title.position = Vector2(10, inv_y + 2)
	inv_title.size     = Vector2(W - 20, 18)
	inv_title.text     = "YOUR POOL  (0 / %d)" % MAX_POOL
	inv_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	inv_title.add_theme_font_size_override("font_size", 12)
	add_child(inv_title)

	_inventory_grid = Control.new()
	_inventory_grid.name     = "InvGrid"
	_inventory_grid.position = Vector2(10, inv_y + 22)
	_inventory_grid.size     = Vector2(W - 20, CELL_SZ)
	add_child(_inventory_grid)
	_init_slots()

	var btn_y = inv_y + 22 + CELL_SZ + 14
	_confirm_btn = Button.new()
	_confirm_btn.position   = Vector2((W - 240) / 2, btn_y)
	_confirm_btn.size       = Vector2(240, 52)
	_confirm_btn.flat       = true
	_confirm_btn.focus_mode = Control.FOCUS_NONE
	_confirm_btn.pressed.connect(_on_confirm)
	add_child(_confirm_btn)

	_confirm_lbl = Label.new()
	_confirm_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_confirm_lbl.add_theme_font_size_override("font_size", 20)
	_confirm_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_btn.add_child(_confirm_lbl)

	_refresh_rule_label()
	_refresh_confirm_btn()

# ─────────────────────────────────────────────────────
func _make_cell(upg: Dictionary, x: float, y: float):
	var rc  = _db.get_rarity_color(upg["rarity"])
	var btn = Button.new()
	btn.name       = "Cell_" + upg["id"]
	btn.position   = Vector2(x, y)
	btn.size       = Vector2(CELL_SZ, CELL_SZ)
	btn.flat       = true
	btn.focus_mode = Control.FOCUS_NONE

	var sn = StyleBoxFlat.new()
	sn.bg_color            = Color(0.10, 0.10, 0.18)
	sn.border_width_bottom = 2; sn.border_width_top   = 2
	sn.border_width_left   = 2; sn.border_width_right = 2
	sn.border_color        = rc.darkened(0.35)
	btn.add_theme_stylebox_override("normal", sn)
	var sh = sn.duplicate(); sh.border_color = rc
	btn.add_theme_stylebox_override("hover",  sh)
	btn.add_theme_stylebox_override("pressed", sh)

	var icon = Label.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon.text = upg["icon"]
	icon.add_theme_font_size_override("font_size", 24)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)

	var bar = ColorRect.new()
	bar.size     = Vector2(CELL_SZ, 4)
	bar.position = Vector2(0, CELL_SZ - 4)
	bar.color    = rc
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(bar)

	btn.pressed.connect(_on_cell_clicked.bind(upg))
	add_child(btn)

func _on_cell_clicked(upg: Dictionary):
	var now       = Time.get_ticks_msec() / 1000.0
	var is_double = (_last_click_id == upg["id"]) and (now - _last_click_time < DOUBLE_CLICK_SEC)
	_last_click_id   = upg["id"]
	_last_click_time = now
	_show_info(upg)
	if is_double:
		_toggle_pool(upg)

func _toggle_pool(upg: Dictionary):
	for i in range(_pool.size()):
		if _pool[i]["id"] == upg["id"]:
			_pool.remove_at(i)
			_highlight_cell(upg["id"], false)
			_refresh_inventory()
			return
	if _pool.size() >= MAX_POOL:
		_flash_rule("Pool is full! (%d / %d)" % [_pool.size(), MAX_POOL])
		return
	_pool.append(upg)   # append preserva orden de inserción
	_highlight_cell(upg["id"], true)
	_refresh_inventory()

# ─────────────────────────────────────────────────────
# INVENTARIO
# ─────────────────────────────────────────────────────
func _init_slots():
	for s in _grid_cells:
		if is_instance_valid(s): s.queue_free()
	_grid_cells.clear()
	var W      = _inventory_grid.size.x
	var slot_w = (W - (MAX_POOL - 1) * CELL_GAP) / MAX_POOL
	for i in range(MAX_POOL):
		var btn = Button.new()
		btn.position   = Vector2(i * (slot_w + CELL_GAP), 0)
		btn.size       = Vector2(slot_w, CELL_SZ)
		btn.flat       = true
		btn.focus_mode = Control.FOCUS_NONE
		_style_empty(btn)
		_inventory_grid.add_child(btn)
		_grid_cells.append(btn)

func _refresh_inventory():
	var W      = _inventory_grid.size.x
	var slot_w = (W - (MAX_POOL - 1) * CELL_GAP) / MAX_POOL

	for i in range(_grid_cells.size()):
		var slot = _grid_cells[i]
		if not is_instance_valid(slot): continue

		# Limpiar hijos visuales
		for c in slot.get_children(): c.queue_free()
		# Desconectar TODAS las señales pressed acumuladas
		for conn in slot.pressed.get_connections():
			slot.pressed.disconnect(conn["callable"])

		if i < _pool.size():
			var upg = _pool[i]           # posición = orden de inserción
			var rc  = _db.get_rarity_color(upg["rarity"])

			var sn = StyleBoxFlat.new()
			sn.bg_color            = Color(0.10, 0.14, 0.22)
			sn.border_width_bottom = 2; sn.border_width_top   = 2
			sn.border_width_left   = 2; sn.border_width_right = 2
			sn.border_color        = rc
			slot.add_theme_stylebox_override("normal", sn)
			var sh = sn.duplicate()
			sh.bg_color     = Color(0.18, 0.07, 0.07)
			sh.border_color = Color(1.0, 0.25, 0.25)
			slot.add_theme_stylebox_override("hover", sh)

			var icon = Label.new()
			icon.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			icon.text = upg["icon"]
			icon.add_theme_font_size_override("font_size", 22)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(icon)

			var bar = ColorRect.new()
			bar.size     = Vector2(slot_w, 3)
			bar.position = Vector2(0, CELL_SZ - 3)
			bar.color    = rc
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(bar)

			# Captura ID — no índice — para ser inmune a reordenamientos
			var uid = upg["id"]
			slot.pressed.connect(func():
				for j in range(_pool.size()):
					if _pool[j]["id"] == uid:
						_pool.remove_at(j)
						_highlight_cell(uid, false)
						_refresh_inventory()
						break
			)
		else:
			_style_empty(slot)

	var inv_title = get_node_or_null("InvTitle")
	if inv_title:
		inv_title.text = "YOUR POOL  (%d / %d)" % [_pool.size(), MAX_POOL]

	_refresh_rule_label()
	_refresh_confirm_btn()

func _style_empty(btn: Button):
	var s = StyleBoxFlat.new()
	s.bg_color            = Color(0.08, 0.08, 0.14)
	s.border_width_bottom = 1; s.border_width_top   = 1
	s.border_width_left   = 1; s.border_width_right = 1
	s.border_color        = Color(0.20, 0.20, 0.30)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  s)

# ─────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────
func _count_commons() -> int:
	var c = 0
	for u in _pool:
		if u["rarity"] == _db.Rarity.COMMON: c += 1
	return c

func _highlight_cell(upg_id: String, selected: bool):
	var cell = get_node_or_null("Cell_" + upg_id)
	if not is_instance_valid(cell): return
	var rc = Color.WHITE
	for u in _db.ALL_UPGRADES:
		if u["id"] == upg_id:
			rc = _db.get_rarity_color(u["rarity"]); break
	var sn = StyleBoxFlat.new()
	sn.bg_color            = Color(0.10, 0.22, 0.14) if selected else Color(0.10, 0.10, 0.18)
	sn.border_width_bottom = 2; sn.border_width_top   = 2
	sn.border_width_left   = 2; sn.border_width_right = 2
	sn.border_color        = rc if selected else rc.darkened(0.4)
	cell.add_theme_stylebox_override("normal", sn)
	var sh = sn.duplicate(); sh.border_color = rc
	cell.add_theme_stylebox_override("hover",  sh)
	cell.add_theme_stylebox_override("pressed", sh)

func _show_info(upg):
	if upg == null:
		_info_name.text   = "Click an ability to see details"
		_info_desc.text   = "Double-click to add it to your pool"
		_info_rarity.text = ""
		return
	var rc = _db.get_rarity_color(upg["rarity"])
	_info_name.text   = upg["icon"] + "  " + Loc.t(upg.get("name_key", "???"))
	_info_desc.text   = Loc.t(upg.get("desc_key", "???"))
	_info_rarity.text = "◆ " + _db.get_rarity_name(upg["rarity"]).to_upper()
	_info_rarity.add_theme_color_override("font_color", rc)

func _refresh_rule_label():
	var c = _count_commons()
	if c < COMMONS_REQUIRED:
		_rule_label.text = "Need %d Common to start  (%d / %d)" % [COMMONS_REQUIRED, c, COMMONS_REQUIRED]
		_rule_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.15))
	else:
		_rule_label.text = "✓  Ready — %d Common in pool" % c
		_rule_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))

func _flash_rule(msg: String):
	_rule_label.text = "⚠  " + msg
	_rule_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))

func _refresh_confirm_btn():
	var ready = _count_commons() >= COMMONS_REQUIRED
	_confirm_btn.disabled = not ready
	var sn = StyleBoxFlat.new()
	sn.bg_color = Color(0.10, 0.48, 0.20) if ready else Color(0.16, 0.16, 0.16)
	_confirm_btn.add_theme_stylebox_override("normal", sn)
	var sh = sn.duplicate()
	sh.bg_color = Color(0.14, 0.62, 0.26) if ready else Color(0.16, 0.16, 0.16)
	_confirm_btn.add_theme_stylebox_override("hover", sh)
	var sp = sn.duplicate()
	sp.bg_color = Color(0.07, 0.34, 0.14) if ready else Color(0.16, 0.16, 0.16)
	_confirm_btn.add_theme_stylebox_override("pressed", sp)
	if ready:
		_confirm_lbl.text = "▶  PLAY"
		_confirm_lbl.add_theme_color_override("font_color", Color.WHITE)
	else:
		_confirm_lbl.text = "Need %d Common  (%d / %d)" % [COMMONS_REQUIRED, _count_commons(), COMMONS_REQUIRED]
		_confirm_lbl.add_theme_color_override("font_color", Color(0.75, 0.45, 0.15))

func _on_confirm():
	emit_signal("pool_confirmed", _pool.duplicate())