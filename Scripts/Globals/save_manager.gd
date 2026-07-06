extends Node

signal save_data_loaded(data: Dictionary)
signal stats_data_loaded(data: Dictionary)
signal update_save_parameter(param: String, value: Variant)
signal update_stats_parameter(param: String, value: Variant)

var basic_save_data: Dictionary = {
	"up_score_spawn_time": 1.0,
	"up_score_ring_level": 1.0,
	"up_score_level": 1.0,
	"up_balls_level": 1.0,
	"up_ball_1_level": 1.0,
	"up_ball_2_level": 1.0,
	"up_ball_3_level": 1.0,
	"max_balls": 3.0,
	"tutor": .0,
}

var basic_stats_data: Dictionary = {
	"score": .0,
	"shape": .0
}

var leaderboard = "leaders"
var leaderboard_key = "shape"

var save_data: Dictionary = {}
var stats_data: Dictionary = {}

var _debug_mode = false

var save_timer: Timer
var stats_timer: Timer

var has_changes_data: bool = false
var has_changes_stats: bool = false
var has_changes_leaderboard: bool = false

var is_data_saved: bool = true
var is_stats_data_loaded: bool = false
var is_save_data_loaded: bool = false

func _ready() -> void:
	if OS.is_debug_build():
		_debug_mode = true
	
	WebBus.inited.connect(_on_game_initialized)
	WebBus.data_received.connect(_on_data_loaded)
	WebBus.stats_received.connect(_on_stats_loaded)
	
	save_timer = Timer.new()
	save_timer.wait_time = 2.0
	save_timer.one_shot = true
	save_timer.timeout.connect(_on_save_timer_timeout)
	add_child(save_timer)
	
	stats_timer = Timer.new()
	stats_timer.wait_time = 1.5
	stats_timer.one_shot = true
	stats_timer.timeout.connect(_on_stats_timer_timeout)
	add_child(stats_timer)
	
	if WebBus.is_init:
		_on_game_initialized()
	
	# ---	
	# Убрать 4 строки ниже чтобы работало в яндексе
	# ---
	TranslationServer.set_locale(OS.get_locale_language())
	_on_game_initialized()
	_on_data_loaded(basic_save_data)
	_on_stats_loaded(basic_stats_data)

# Таймаут таймера — разрешает следующие сохранения
func _on_save_timer_timeout() -> void:
	if has_changes_data:
		WebBus.set_data(save_data)
		has_changes_data = false
	
		save_timer.start()

func _on_stats_timer_timeout() -> void:
	if has_changes_stats:
		WebBus.set_stats(stats_data)
		if has_changes_leaderboard:
			update_leaderboards()
			has_changes_leaderboard = false
		has_changes_stats = false
	
		stats_timer.start()

func _save_all_immediately() -> void:
	if has_changes_data:
		if _debug_mode: print("SaveManager: Немедленное сохранение data: ", save_data)
		WebBus.set_data(save_data)
		has_changes_data = false
		if save_timer:
			save_timer.stop()  # сбрасываем, если вдруг был запущен
	
	if has_changes_stats:
		if _debug_mode: print("SaveManager: Немедленное сохранение stats: ", stats_data)
		WebBus.set_stats(stats_data)
		if has_changes_leaderboard:
			update_leaderboards()
			has_changes_leaderboard = false
		has_changes_stats = false
		if stats_timer:
			stats_timer.stop()

func _on_game_initialized() -> void:
	var data_keys = basic_save_data.keys()
	var stats_keys = basic_stats_data.keys()
	
	WebBus.get_data(data_keys)
	WebBus.get_stats(stats_keys)

func _on_stats_loaded(data: Dictionary) -> void:
	if data.size() != basic_stats_data.size():
		if _debug_mode: print("SaveManager: Неверные stats данные, загружаю данные по умолчанию: ", basic_stats_data)
		stats_data = basic_stats_data.duplicate(true)
	else:
		if _debug_mode: print("SaveManager: Получены корректные stats данные, загружаю: ", data)
		stats_data = data.duplicate(true)
	
	is_stats_data_loaded = true
	_check_all_loaded()

func _on_data_loaded(data: Dictionary) -> void:
	if data.size() != basic_save_data.size():
		if _debug_mode: print("SaveManager: Неверные save данные, загружаю данные по умолчанию: ", basic_save_data)
		save_data = basic_save_data.duplicate(true)
	else:
		if _debug_mode: print("SaveManager: Получены корректные save данные, загружаю: ", data)
		save_data = data.duplicate(true)
	
	is_save_data_loaded = true
	_check_all_loaded()

func _check_all_loaded() -> void:
	if is_save_data_loaded and is_stats_data_loaded:
		if _debug_mode: 
			print("SaveManager: Все данные загружены")
			print("Data: ", save_data)
			print("Stats: ", stats_data)
		
		save_data_loaded.emit(save_data)
		stats_data_loaded.emit(stats_data)

func _on_data_saved(status: bool) -> void:
	if _debug_mode: print("SaveManager: Статус сохранения получен: ", status)

func update_save_data_parameter(key: String, value: Variant, save_now: bool = true) -> void:
	save_data[key] = value
	has_changes_data = true
	update_save_parameter.emit(key, value)
	
	if save_now and save_timer and save_timer.is_stopped():
		if _debug_mode: print("SaveManager: Сохранение data сразу: ", save_data)
		WebBus.set_data(save_data)
		has_changes_data = false
	
		save_timer.start()

func update_stats_data_parameter(key: String, value: Variant, save_now: bool = true) -> void:
	stats_data[key] = value
	has_changes_stats = true
	if key == leaderboard_key:
		has_changes_leaderboard = true
	update_stats_parameter.emit(key, value)
	
	if save_now and stats_timer and stats_timer.is_stopped():
		if _debug_mode: print("SaveManager: Сохранение stats сразу: ", stats_data)
		WebBus.set_stats(stats_data)
		if has_changes_leaderboard:
			update_leaderboards()
			has_changes_leaderboard = false
		has_changes_stats = false
	
		stats_timer.start()

func update_leaderboards() -> void:
	WebBus.set_leaderboard_score(leaderboard, stats_data.get(leaderboard_key, 0))

func get_save_data_parameter(key: String) -> Variant:
	return save_data.get(key, .0)

func get_stats_data_parameter(key: String) -> Variant:
	return stats_data.get(key, .0)
