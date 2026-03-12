extends CanvasLayer

# El HUD vive en un CanvasLayer separado, encima de todo.
# Reserva 90px en la parte superior para no solapar el juego.
# Main.gd debe decirle al Snake y EnemyManager que empiecen
# a partir de Y=90 (ver GAME_OFFSET_Y en Main.gd)

const HUD_HEIGHT: int = 90

var health_fill: ColorRect
var health_label: Label
var xp_fill: ColorRect
var xp_label: Label
var score_label: Label
var level_label: Label
var message_label: Label
var message_timer: float = 0.0
const MESSAGE_DURATION: float = 1.4

func _ready():
	_build_hud()

func _build_hud():
	var screen = get_viewport().get_visible_rect().size
	var w = screen.x

	# ── Fondo del HUD ──────────────────────────────────
	var bg = ColorRect.new()
	bg.size = Vector2(w, HUD_HEIGHT)
	bg.color = Color(0.04, 0.04, 0.1, 1.0)
	add_child(bg)

	# Línea separadora inferior
	var sep = ColorRect.new()
	sep.size = Vector2(w, 2)
	sep.position = Vector2(0, HUD_HEIGHT - 2)
	sep.color = Color(0.25, 0.25, 0.4)
	add_child(sep)

	# ── Fila 1: Score | Nivel ──────────────────────────
	score_label = Label.new()
	score_label.position = Vector2(10, 6)
	score_label.size = Vector2(w * 0.5, 26)
	score_label.text = Loc.t("hud_score", [0])
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_font_size_override("font_size", 20)
	add_child(score_label)

	level_label = Label.new()
	level_label.position = Vector2(w * 0.5, 6)
	level_label.size = Vector2(w * 0.5 - 8, 26)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.text = Loc.t("hud_level", [1])
	level_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	level_label.add_theme_font_size_override("font_size", 20)
	add_child(level_label)

	# ── Barra HP ───────────────────────────────────────
	var hp_icon = Label.new()
	hp_icon.position = Vector2(8, 34)
	hp_icon.size = Vector2(22, 20)
	hp_icon.text = "❤"
	hp_icon.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	hp_icon.add_theme_font_size_override("font_size", 14)
	add_child(hp_icon)

	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(w - 42, 16)
	hp_bg.position = Vector2(32, 36)
	hp_bg.color = Color(0.25, 0.04, 0.04)
	add_child(hp_bg)

	health_fill = ColorRect.new()
	health_fill.size = Vector2(w - 42, 16)
	health_fill.position = Vector2(32, 36)
	health_fill.color = Color(0.0, 0.85, 0.2)
	add_child(health_fill)

	health_label = Label.new()
	health_label.position = Vector2(32, 34)
	health_label.size = Vector2(w - 42, 20)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.text = Loc.t("hud_hp", [100, 100])
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_label.add_theme_font_size_override("font_size", 11)
	add_child(health_label)

	# ── Barra XP ───────────────────────────────────────
	var xp_icon = Label.new()
	xp_icon.position = Vector2(8, 57)
	xp_icon.size = Vector2(22, 20)
	xp_icon.text = "✦"
	xp_icon.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
	xp_icon.add_theme_font_size_override("font_size", 14)
	add_child(xp_icon)

	var xp_bg = ColorRect.new()
	xp_bg.size = Vector2(w - 42, 16)
	xp_bg.position = Vector2(32, 59)
	xp_bg.color = Color(0.06, 0.06, 0.22)
	add_child(xp_bg)

	xp_fill = ColorRect.new()
	xp_fill.size = Vector2(0, 16)
	xp_fill.position = Vector2(32, 59)
	xp_fill.color = Color(0.3, 0.5, 1.0)
	add_child(xp_fill)

	xp_label = Label.new()
	xp_label.position = Vector2(32, 57)
	xp_label.size = Vector2(w - 42, 20)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.text = Loc.t("hud_xp", [0, 50])
	xp_label.add_theme_color_override("font_color", Color.WHITE)
	xp_label.add_theme_font_size_override("font_size", 11)
	add_child(xp_label)

	# ── Mensaje flotante ───────────────────────────────
	message_label = Label.new()
	message_label.position = Vector2(0, screen.y / 2 - 30)
	message_label.size = Vector2(screen.x, 44)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 26)
	message_label.visible = false
	add_child(message_label)

func _process(delta: float):
	if message_label.visible:
		message_timer -= delta
		if message_timer <= 0:
			message_label.visible = false
		else:
			message_label.modulate.a = clamp(message_timer / MESSAGE_DURATION, 0.0, 1.0)

func update_health(current: int, maximum: int):
	var w = get_viewport().get_visible_rect().size.x - 42
	var pct = float(current) / float(maximum)
	health_fill.size.x = w * pct
	if pct > 0.6:
		health_fill.color = Color(0.0, 0.85, 0.2)
	elif pct > 0.3:
		health_fill.color = Color(0.9, 0.75, 0.0)
	else:
		health_fill.color = Color(0.9, 0.1, 0.1)
	health_label.text = Loc.t("hud_hp", [current, maximum])

func update_xp(current: int, needed: int, level: int):
	var w = get_viewport().get_visible_rect().size.x - 42
	var pct = float(current) / float(needed)
	xp_fill.size.x = w * pct
	xp_label.text = Loc.t("hud_xp", [current, needed])
	level_label.text = Loc.t("hud_level", [level])

func update_score(new_score: int):
	score_label.text = Loc.t("hud_score", [new_score])

func show_message(text: String, color: Color):
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
	message_label.visible = true
	message_label.modulate.a = 1.0
	message_timer = MESSAGE_DURATION