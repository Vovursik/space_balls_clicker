extends MarginContainer

@onready var score_label: Label = $HBoxContainer/TextureRect/HBoxContainer/Label
@onready var balls_label: Label = $HBoxContainer/TextureRect2/HBoxContainer/Label
@onready var shape_label: Label = $HBoxContainer/VBoxContainer/Label
@onready var progress_bar: TextureProgressBar = $HBoxContainer/VBoxContainer/TextureProgressBar

var max_balls: int = 0
var current_balls: int = 0

func _ready() -> void:
	SaveManager.save_data_loaded.connect(_on_save_data_loaded)
	SaveManager.stats_data_loaded.connect(_on_stats_data_loaded)
	SaveManager.update_save_parameter.connect(_on_update_save_parameters)
	SaveManager.update_stats_parameter.connect(_on_update_stats_parameters)
	
	if SaveManager.is_save_data_loaded:
		_on_save_data_loaded(SaveManager.save_data)
	
	if SaveManager.is_stats_data_loaded:
		_on_stats_data_loaded(SaveManager.stats_data)
	
	GlobalValues.balls_updated.connect(_on_balls_updated)

func _physics_process(_delta):
	progress_bar.value = GlobalValues.shape_progress

func _on_save_data_loaded(data: Dictionary) -> void:
	for key in ["max_balls"]:
		_on_update_save_parameters(key, data[key])

func _on_stats_data_loaded(data: Dictionary) -> void:
	for key in ["score", "shape"]:
		_on_update_stats_parameters(key, data[key])

func _on_update_save_parameters(param: String, value: Variant) -> void:
	match param:
		"max_balls":
			max_balls = int(value)
			balls_label.text = str(current_balls) + "/" + str(max_balls)

func _on_update_stats_parameters(param: String, value: Variant) -> void:
	match param:
		"score":
			score_label.text = Utils.format_number(int(value), 3)
		"shape":
			shape_label.text = tr("KEY_RINGS_COUNT") + " " + str(int(value))			

func _on_balls_updated(value: int) -> void:
	current_balls = value
	balls_label.text = str(current_balls) + "/" + str(max_balls)
