extends TextureButton

var normal_texture = preload("res://Textures2D/TextureAtlas/ButtonsAtlas/sound_on.tres")
var muted_texture = preload("res://Textures2D/TextureAtlas/ButtonsAtlas/sound_off.tres")
var normal_pres_texture = preload("res://Textures2D/TextureAtlas/ButtonsAtlas/sound_on_pressed.tres")
var muted_pres_texture = preload("res://Textures2D/TextureAtlas/ButtonsAtlas/sound_off_pressed.tres")

func _ready():
	update_button_texture()

func update_button_texture():
	if InitYandexGames.is_muted:
		texture_normal = muted_texture
		texture_pressed = muted_pres_texture
	else:
		texture_normal = normal_texture
		texture_pressed = normal_pres_texture

func _pressed():
	var master_bus = AudioServer.get_bus_index("Master")
	var is_muted = AudioServer.is_bus_mute(master_bus)
	
	# Переключаем звук
	InitYandexGames.set_muted(!InitYandexGames.is_muted)
	
	# Обновляем текстуру кнопки
	update_button_texture()
