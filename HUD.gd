extends CanvasLayer

var health_bar: ColorRect
var health_fill: ColorRect
var health_label: Label
var score_label: Label
var message_label: Label
var message_timer: float = 0.0
const MESSAGE_DURATION: float = 1.5

func _ready():
	_build_hud()

func _build_hud():
	var screen = get_viewport().get_visible_rect().size
	
	# --- Panel superior ---
	var top_panel = ColorRect.new()
	top_panel.size = Vector2(screen.x, 60)
	top_panel.position = Vector2(0, 0)
	top_panel.color = Color(0, 0, 0, 0.6)
	add_child(top_panel)
	
	# Score
	score_label = Label.new()
	score_label.position = Vector2(10, 8)
	score_label.size = Vector2(200, 40)
	score_label.text = "SCORE: 0"
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_font_size_override("font_size", 22)
	add_child(score_label)
	
	# --- Barra de salud ---
	var health_bg = ColorRect.new()
	health_bg.size = Vector2(screen.x - 20, 18)
	health_bg.position = Vector2(10, 38)
	health_bg.color = Color(0.3, 0.0, 0.0)
	add_child(health_bg)
	
	health_fill = ColorRect.new()
	health_fill.size = Vector2(screen.x - 20, 18)
	health_fill.position = Vector2(10, 38)
	health_fill.color = Color(0.0, 0.85, 0.2)
	add_child(health_fill)
	
	health_label = Label.new()
	health_label.position = Vector2(10, 36)
	health_label.size = Vector2(screen.x - 20, 22)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.text = "HP: 100/100"
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_label.add_theme_font_size_override("font_size", 13)
	add_child(health_label)
	
	# --- Icono corazón ---
	var heart_label = Label.new()
	heart_label.position = Vector2(screen.x - 40, 8)
	heart_label.size = Vector2(35, 30)
	heart_label.text = "❤"
	heart_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	heart_label.add_theme_font_size_override("font_size", 22)
	add_child(heart_label)
	
	# --- Mensaje flotante (curación / daño) ---
	message_label = Label.new()
	message_label.position = Vector2(0, screen.y / 2 - 40)
	message_label.size = Vector2(screen.x, 50)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.text = ""
	message_label.add_theme_font_size_override("font_size", 28)
	message_label.visible = false
	add_child(message_label)

func _process(delta: float):
	if message_label.visible:
		message_timer -= delta
		if message_timer <= 0:
			message_label.visible = false
		else:
			# Fade out
			message_label.modulate.a = clamp(message_timer / MESSAGE_DURATION, 0, 1)

func update_health(current: int, maximum: int):
	var screen = get_viewport().get_visible_rect().size
	var pct = float(current) / float(maximum)
	health_fill.size.x = (screen.x - 20) * pct
	
	# Color según salud
	if pct > 0.6:
		health_fill.color = Color(0.0, 0.85, 0.2)
	elif pct > 0.3:
		health_fill.color = Color(0.9, 0.75, 0.0)
	else:
		health_fill.color = Color(0.9, 0.1, 0.1)
	
	health_label.text = "HP: %d/%d" % [current, maximum]

func update_score(new_score: int):
	score_label.text = "SCORE: %d" % new_score

func show_message(text: String, color: Color):
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
	message_label.visible = true
	message_label.modulate.a = 1.0
	message_timer = MESSAGE_DURATION
