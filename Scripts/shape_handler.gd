extends Node2D

@export var scene_paths: Array[String] = []
@export var fade_duration: float = 0.2
@export var shape_count: int = 9

var current_scene_index: int = 0
var loaded_scenes: Dictionary = {}
var current_scene_instance: Node = null

var is_transitioning: bool = false
var pending_index: int = -1

@onready var container_node: Node = self

func _ready():
	preload_scenes()
	
	SaveManager.stats_data_loaded.connect(_on_stats_data_loaded)
	SaveManager.update_stats_parameter.connect(_on_update_stats_parameters)
	
	if SaveManager.is_stats_data_loaded:
		_on_stats_data_loaded(SaveManager.stats_data)

func _on_stats_data_loaded(data: Dictionary) -> void:
	switch_to_scene(int(data["shape"]) % shape_count)

func _on_update_stats_parameters(param: String, value: Variant) -> void:
	if param == "shape":
		switch_to_scene(int(value) % shape_count)

func preload_scenes():
	for path in scene_paths:
		var scene_resource = load(path) as PackedScene
		if scene_resource:
			loaded_scenes[path] = scene_resource

func switch_to_scene(index: int):
	if is_transitioning:
		pending_index = index
		return
	
	if index < 0 or index >= scene_paths.size():
		return
	
	if index == current_scene_index and current_scene_instance:
		return
	
	is_transitioning = true
	
	if current_scene_instance and is_instance_valid(current_scene_instance):
		await fade_out_current_scene(index)
	else:
		await load_and_fade_in_scene(index)

func load_and_fade_in_scene(index: int):
	var scene_resource = loaded_scenes[scene_paths[index]]
	current_scene_instance = scene_resource.instantiate()
	
	# Устанавливаем начальную прозрачность (полностью прозрачная)
	current_scene_instance.modulate = Color(1, 1, 1, 0)
	
	# Добавляем в контейнер
	container_node.add_child(current_scene_instance)
	
	# Анимируем появление
	var tween = create_tween()
	tween.tween_property(current_scene_instance, "modulate", 
		Color(1, 1, 1, 1), fade_duration)
	await tween.finished
	
	current_scene_index = index
	is_transitioning = false
	
	if pending_index != -1:
		var next_pending = pending_index
		pending_index = -1
		switch_to_scene(next_pending)

func fade_out_current_scene(next_index: int):
	if not current_scene_instance or not is_instance_valid(current_scene_instance):
		await load_and_fade_in_scene(next_index)
		return
	
	# Анимируем исчезновение
	var tween = create_tween()
	tween.tween_property(current_scene_instance, "modulate", 
		Color(1, 1, 1, 0), fade_duration)
	await tween.finished
	
	# Удаляем старую сцену
	current_scene_instance.queue_free()
	current_scene_instance = null
	await get_tree().process_frame
	
	await load_and_fade_in_scene(next_index)
