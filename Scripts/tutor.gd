extends Control

@onready var stage_0 = $Stage_0
@onready var stage_1 = $Stage_1
@onready var shop_button = $"../ButtonsPanel/VBoxContainer/TextureButton2"

var is_spawn: bool = false
var is_save_init: bool = false
var type: int = 0

func _ready():
	stage_0.visible = true
	stage_1.visible = false
	shop_button.visible = false
	
	shop_button.tutor_end.connect(_on_tutor_end)
	SaveManager.save_data_loaded.connect(_on_save_data_loaded)
	
	if SaveManager.is_save_data_loaded:
		_on_save_data_loaded(SaveManager.save_data)

func _on_save_data_loaded(data: Dictionary) -> void:
	is_save_init = true
	
	type = int(data["tutor"])
	if type:
		_on_tutor_end()
	else:
		stage_0.visible = true
		
func _on_tutor_end() -> void:
	shop_button.button_active()
	if not type:
		SaveManager.update_save_data_parameter("tutor", 1)
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click") and !is_spawn and is_save_init:
		stage_0.visible = false
		is_spawn = true
		
		await get_tree().create_timer(1.0).timeout
		shop_button.button_active()
		stage_1.visible = true
