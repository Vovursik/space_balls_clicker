extends TextureButton

@export var err_sound : AudioStream = null
@export var buy_sound : AudioStream = null
@onready var audio_player = $AudioStreamPlayer2D

@onready var price_label = $"../HBoxContainer2/Label"
@onready var level_label = $"../HBoxContainer3/Label2"
@onready var desc_label = $"../MarginContainer/Label"

@export var card_upgrade: String = "up_balls_level"
@export var card_key_desc: String = "KEY_CARDDESC_1"
@export var purchase_count: int = 10
@export var price_scale: float = 1.9
@export var max_level: int = 30
@export var is_percent: bool = false
@export var is_time: bool = false

var is_save_init = false
var level: int = 1
var _debug_mode = false

func _ready():
	if OS.is_debug_build():
		_debug_mode = true

	SaveManager.save_data_loaded.connect(_on_save_data_loaded)
	SaveManager.update_save_parameter.connect(_on_update_save_parameters)
	
	if SaveManager.is_save_data_loaded:
		_on_save_data_loaded(SaveManager.save_data)

func _on_save_data_loaded(data: Dictionary) -> void:
	is_save_init = true
	level = int(data[card_upgrade])
	_update_text()

func _on_update_save_parameters(param: String, value: Variant) -> void:
	if param == card_upgrade:
		level = int(value)
		_update_text()

func _pressed() -> void:
	_handle_click()

func _on_card_updated(upgrade_name, new_level):
	if upgrade_name == card_upgrade:
		level = new_level
		_update_text()

func _update_text():
	if max_level != 0 && level >= max_level:
		price_label.text = "MAX"
	else:
		price_label.text = str(Utils.format_number(int(purchase_count * pow(level, price_scale)),1))
		
	level_label.text = str(level)
	
	desc_label.text = tr(card_key_desc) + " "
	
	if is_time:
		var tex: String
		if level <= 1:
			tex = "0"
		elif level <= 15:
			tex = str(17.0 - level)
		else: 
			tex = str(1.0 - (level - 14) * 0.1)
		desc_label.text += str(tex)
	else:
		desc_label.text += str(level)
	
	if is_percent:
		desc_label.text += "%"
	if is_time:
		desc_label.text += tr("KEY_TIME_SEC")

func _play_sound(sound):
	if sound and audio_player and is_instance_valid(audio_player):
		audio_player.stream = sound
		audio_player.play()

func _handle_click() -> void:
	if not is_save_init: return
	
	if max_level != 0 and level >= max_level:
		_play_sound(err_sound) 
		return
	
	var val = int(purchase_count * pow(level, price_scale))
	if GlobalValues.wantBuy(val, card_upgrade):
		_play_sound(buy_sound)
	else:
		_play_sound(err_sound) 
