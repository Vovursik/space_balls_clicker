extends TextureButton

signal tutor_end()

@onready var cards_panel = $"../../../MarginContainer/CardsPanel"
@onready var animation_tree: AnimationTree = $"../../../MarginContainer/CardsPanel/AnimationTree"

var is_save_init: bool = false
var is_show: bool = false
var is_button_active: bool = false

func _ready() -> void:
	SaveManager.save_data_loaded.connect(_on_save_data_loaded)
	
	if SaveManager.is_save_data_loaded:
		_on_save_data_loaded(SaveManager.save_data)

func _on_save_data_loaded(_data: Dictionary) -> void:
	is_save_init = true

func button_active() -> void:
	is_button_active = true
	visible = true

func _pressed():
	if cards_panel and is_button_active and is_save_init:
		is_show = !is_show
		if is_show:
			animation_tree.set("parameters/conditions/is_hiding", false)
			animation_tree.set("parameters/conditions/is_showing", true)
		else: 
			animation_tree.set("parameters/conditions/is_hiding", true)
			animation_tree.set("parameters/conditions/is_showing", false)
		tutor_end.emit()
