extends Node

signal balls_updated(value: int)

var _current_balls: int = 0
var shape_progress: float = .0
var _shape_scale_factor: float = 1.6

const BASE_MULTIPLIER = 1.0
const MAX_MULTIPLIER = 2.0
const GROWTH_RATE = 0.3

func _ready() -> void:
	pass

#func _notification(what: int):
	#match what:
		#NOTIFICATION_WM_CLOSE_REQUEST:
			## Игрок закрывает игру
			#save_score_immediately()
			#get_tree().quit()
		#NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			## Игрок свернул игру
			#save_score_immediately()

func update_balls(value: int) -> void:
	_current_balls += value
	if _current_balls < 0: 
		_current_balls = 0
	balls_updated.emit(_current_balls)

func _get_asymptotic_multiplier(stat: int) -> float:
	var t = 1.0 - 1.0 / (1.0 + stat * GROWTH_RATE)
	return BASE_MULTIPLIER + (MAX_MULTIPLIER - BASE_MULTIPLIER) * t

func shape_score(amount: int) -> void:
	SaveManager.update_stats_data_parameter("score", SaveManager.get_stats_data_parameter("score") + amount * SaveManager.get_save_data_parameter("up_score_ring_level"))
	
	var max_balls = SaveManager.get_save_data_parameter("max_balls")
	var shape_stat = SaveManager.get_stats_data_parameter("shape")  # количество пройденных фигур
	
	# Асимптотический множитель на основе shape_stat
	var multiplier = _get_asymptotic_multiplier(shape_stat)
	
	# Базовая формула с множителем
	var progress = amount * multiplier / (_shape_scale_factor * max_balls)
	shape_progress += progress
	if shape_progress >= 100.0:
		shape_progress = .0
		SaveManager.update_stats_data_parameter("shape", SaveManager.get_stats_data_parameter("shape") + 1)

func ball_score(amount: int) -> void:
	SaveManager.update_stats_data_parameter("score", SaveManager.get_stats_data_parameter("score") + amount * SaveManager.get_save_data_parameter("up_score_level"))

func canSpawnBall() -> bool:
	return _current_balls < SaveManager.get_save_data_parameter("max_balls")

func wantBuy(amount, upgrade) -> bool:
	var cur_score = SaveManager.get_stats_data_parameter("score")
	if cur_score < amount:
		return false
	
	if upgrade == "up_balls_level":
		SaveManager.update_save_data_parameter("max_balls", SaveManager.get_save_data_parameter("up_balls_level") + SaveManager.basic_save_data.get("max_balls"), false)
	
	SaveManager.update_stats_data_parameter("score", cur_score - amount)
	SaveManager.update_save_data_parameter(upgrade, SaveManager.get_save_data_parameter(upgrade) + 1)
	return true
