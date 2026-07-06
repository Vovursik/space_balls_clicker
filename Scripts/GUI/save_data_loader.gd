extends Control

func _ready() -> void:
	SaveManager.save_data_loaded.connect(_on_save_data_loaded)
	
	if SaveManager.is_save_data_loaded:
		_on_save_data_loaded({})

func _on_save_data_loaded(_data: Dictionary) -> void:
	queue_free()
