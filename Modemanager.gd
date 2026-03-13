extends Node

# =====================================================
# MODE MANAGER
# Responsabilidades:
#   - Saber si estamos en Campaign o Horde
#   - En Campaign: disparar waves según timing
#   - Trackear contadores (kills, tiempo, nivel serpiente)
#   - Detectar condición de victoria y emitir level_won
#
# Para añadir condiciones nuevas: añadir caso en
#   _condition_met() y get_objective_text()
# =====================================================

enum Mode     { NONE, CAMPAIGN, HORDE }
enum WinState { PLAYING, WON }

# ── Estado ───────────────────────────────────────────
var current_mode:       int        = Mode.NONE
var current_level_data: Dictionary = {}
var win_state:          int        = WinState.PLAYING

# ── Contadores ───────────────────────────────────────
var elapsed_time:  float      = 0.0
var kills_total:   int        = 0
var kills_by_type: Dictionary = {}   # type_int → count
var snake_level:   int        = 1

# ── Waves ────────────────────────────────────────────
var _wave_clock: Array = []   # tiempo acumulado por wave
var _wave_fired: Array = []   # veces disparada por wave

# ── Referencias ──────────────────────────────────────
var _level_db:    Node = null
var _enemy_mgr:   Node = null

signal level_won()

# ─────────────────────────────────────────────────────
func _ready():
	set_process(false)

func setup(db: Node, em: Node):
	_level_db  = db
	_enemy_mgr = em

# ─────────────────────────────────────────────────────
func start_campaign(level_index: int):
	current_level_data = _level_db.get_level(level_index)
	current_mode       = Mode.CAMPAIGN
	_reset()
	_init_waves()
	set_process(true)

func start_horde():
	current_level_data = {}
	current_mode       = Mode.HORDE
	_reset()
	set_process(true)

func stop():
	set_process(false)

# ─────────────────────────────────────────────────────
func _reset():
	elapsed_time  = 0.0
	kills_total   = 0
	kills_by_type = {}
	snake_level   = 1
	win_state     = WinState.PLAYING

func _init_waves():
	_wave_clock.clear()
	_wave_fired.clear()
	for _w in current_level_data.get("enemy_waves", []):
		_wave_clock.append(0.0)
		_wave_fired.append(0)

# ─────────────────────────────────────────────────────
func _process(delta: float):
	if win_state == WinState.WON:
		return
	elapsed_time += delta
	if current_mode == Mode.CAMPAIGN:
		_tick_waves(delta)
		_check_win()

# ─────────────────────────────────────────────────────
# WAVE SYSTEM
# Cada wave:
#   delay           → segundos desde inicio hasta 1ª aparición
#   enemies         → [{type: 0|1|2, count: N}]
#   repeat          → true/false
#   repeat_interval → segundos entre repeticiones
# ─────────────────────────────────────────────────────
func _tick_waves(delta: float):
	var waves = current_level_data.get("enemy_waves", [])
	for i in range(waves.size()):
		_wave_clock[i] += delta
		var w       = waves[i]
		var delay   = float(w.get("delay", 0.0))
		var fired   = _wave_fired[i]
		var repeats = w.get("repeat", false)

		if fired == 0:
			if _wave_clock[i] >= delay:
				_fire_wave(w, i)
		elif repeats:
			var interval      = float(w.get("repeat_interval", 10.0))
			var next_fire_at  = delay + fired * interval
			if _wave_clock[i] >= next_fire_at:
				_fire_wave(w, i)

func _fire_wave(wave: Dictionary, index: int):
	if not is_instance_valid(_enemy_mgr):
		return
	_wave_fired[index] += 1
	for entry in wave.get("enemies", []):
		var type  = int(entry.get("type",  0))
		var count = int(entry.get("count", 1))
		for _j in range(count):
			_enemy_mgr.spawn_enemy_of_type(type)

# ─────────────────────────────────────────────────────
# WIN CONDITIONS
# Tipos disponibles:
#   "survive"     value: segundos
#   "kill_total"  value: número de kills
#   "kill_type"   value: número  enemy_type: 0|1|2
#   "reach_level" value: nivel de serpiente
# ─────────────────────────────────────────────────────
func _check_win():
	var conditions = current_level_data.get("win_conditions", [])
	if conditions.is_empty():
		return
	for cond in conditions:
		if not _condition_met(cond):
			return
	win_state = WinState.WON
	set_process(false)
	emit_signal("level_won")

func _condition_met(cond: Dictionary) -> bool:
	match cond.get("type", ""):
		"survive":
			return elapsed_time >= float(cond["value"])
		"kill_total":
			return kills_total >= int(cond["value"])
		"kill_type":
			var et = int(cond.get("enemy_type", 0))
			return kills_by_type.get(et, 0) >= int(cond["value"])
		"reach_level":
			return snake_level >= int(cond["value"])
	return false

# ─────────────────────────────────────────────────────
# CALLBACKS — llamados desde Main
# ─────────────────────────────────────────────────────
func on_enemy_killed(enemy_type: int):
	kills_total += 1
	kills_by_type[enemy_type] = kills_by_type.get(enemy_type, 0) + 1

func on_snake_level_changed(level: int):
	snake_level = level

# ─────────────────────────────────────────────────────
# HUD TEXT
# ─────────────────────────────────────────────────────
func get_objective_text() -> String:
	if current_mode == Mode.HORDE:
		return "Time: %ds" % int(elapsed_time)

	var parts: Array = []
	for cond in current_level_data.get("win_conditions", []):
		match cond.get("type", ""):
			"survive":
				var left = max(0, int(cond["value"]) - int(elapsed_time))
				parts.append("Survive: %ds" % left)
			"kill_total":
				parts.append("Kills: %d / %d" % [kills_total, int(cond["value"])])
			"kill_type":
				var et    = int(cond.get("enemy_type", 0))
				var names = ["Basic", "Fast", "Tank"]
				parts.append("%s kills: %d / %d" % [names[clamp(et,0,2)], kills_by_type.get(et,0), int(cond["value"])])
			"reach_level":
				parts.append("Level: %d / %d" % [snake_level, int(cond["value"])])
	return "  ·  ".join(parts)