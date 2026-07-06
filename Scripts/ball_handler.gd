extends Node2D

@export var ball_scenes: Array[PackedScene] = []

var chances: Array[int] = [100, 0, 0, 0]

var _spawn_locked: bool = false
var spawn_timer: Timer
var spawn_level: int = 1
var _debug_mode: bool = false

var is_save_init = false

@onready var ball_spawn_point = self

func _ready() -> void:
	if OS.is_debug_build():
		_debug_mode = true

	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer)

	SaveManager.save_data_loaded.connect(_on_save_data_loaded)
	SaveManager.update_save_parameter.connect(_on_update_save_parameters)
	
	if SaveManager.is_save_data_loaded:
		_on_save_data_loaded(SaveManager.save_data)

func _on_save_data_loaded(data: Dictionary) -> void:
	is_save_init = true
	
	spawn_level = int(data.get("up_score_spawn_time", 1))
	chances[1] = int(data.get("up_ball_1_level", 1))
	chances[2] = int(data.get("up_ball_2_level", 1))
	chances[3] = int(data.get("up_ball_3_level", 1))
	_normalize_chances()
	_update_spawn_timer()

func _on_update_save_parameters(param: String, value: Variant) -> void:
	match param:
		"up_score_spawn_time":
			spawn_level = int(value)
			_update_spawn_timer()
		"up_ball_1_level":
			chances[1] = int(value)
			_normalize_chances()
		"up_ball_2_level":
			chances[2] = int(value)
			_normalize_chances()
		"up_ball_3_level":
			chances[3] = int(value)
			_normalize_chances()

func _normalize_chances() -> void:
	for i in range(1, 4):
		chances[i] = clampi(chances[i], 0, 100)
	
	var total_others = chances[1] + chances[2] + chances[3]
	
	if total_others > 100:
		var ratio = 100.0 / total_others
		chances[1] = int(chances[1] * ratio)
		chances[2] = int(chances[2] * ratio)
		chances[3] = int(chances[3] * ratio)
		total_others = chances[1] + chances[2] + chances[3]
	
	chances[0] = 100 - total_others
	
	if _debug_mode:
		print("Проценты: 1=", chances[0], "%, 2=", chances[1], "%, 3=", chances[2], "%, 4=", chances[3], "%")

func _input(event):
	if event.is_action_pressed("click") and not _spawn_locked:
		spawn_ball()

func _on_spawn_timer():
	spawn_ball()

func spawn_ball():
	if not is_save_init: return
	
	if !GlobalValues.canSpawnBall():
		return
	
	if spawn_level < 1:
		return
	
	_spawn_locked = true
	
	var ball_scene = _select_ball_by_chance()
	if ball_scene:
		var ball = ball_scene.instantiate()
		ball.global_position = ball_spawn_point.global_position
		add_child(ball)
	
	await get_tree().process_frame
	_spawn_locked = false

func _select_ball_by_chance() -> PackedScene:
	var random = randf() * 100
	var cumulative = 0
	
	for i in range(chances.size()):
		cumulative += chances[i]
		if random < cumulative:
			return ball_scenes[i]
	
	return ball_scenes[0]

func get_spawn_time(level: int) -> float:
	if level <= 1:
		return -1.0
	if level <= 15:
		return 17.0 - level
	return 1.0 - (level - 14) * 0.1

func _update_spawn_timer():
	var time = get_spawn_time(spawn_level)
	if time < 0:
		spawn_timer.stop()
		if _debug_mode:
			print("Таймер спавна остановлен (уровень ", spawn_level, ")")
	else:
		spawn_timer.wait_time = time
		spawn_timer.start()
		if _debug_mode:
			print("Таймер спавна запущен: ", time, " сек (уровень ", spawn_level, ")")
