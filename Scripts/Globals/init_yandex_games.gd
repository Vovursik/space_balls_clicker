extends Node

enum PauseSource { TAB, PLATFORM, EXTERNAL }

var pause_state: Dictionary = {
	PauseSource.TAB: false,
	PauseSource.PLATFORM: false,
	PauseSource.EXTERNAL: false
}

var MasterIndex: int
var is_muted: bool = false

func _ready() -> void:
	MasterIndex = AudioServer.get_bus_index("Master")
	WebBus.inited.connect(_on_game_initialized)
	
	if WebBus.is_init:
		_on_game_initialized()
		
	# Подключаемся к сигналам WebBus
	WebBus.focused.connect(_on_platform_resumed)
	WebBus.unfocused.connect(_on_platform_paused)
		
	# Сигналы рекламы
	WebBus.ad_started.connect(_on_ad_started)
	WebBus.ad_closed.connect(_on_ad_closed)
		
	# Сигналы фокуса окна/вкладки
	#get_window().focus_entered.connect(_on_tab_activated)
	#get_window().focus_exited.connect(_on_tab_deactivated)

	WebBus.ready()
	WebBus.start_gameplay()

#func _on_tab_activated() -> void:
	#print("Вкладка активирована")
	#pause_state[PauseSource.TAB] = false
	#_update_pause()
#
#func _on_tab_deactivated() -> void:
	#print("Вкладка деактивирована")
	#pause_state[PauseSource.TAB] = true
	#_update_pause()

func _on_game_initialized() -> void:
	var lang: String = WebBus.get_language()
	TranslationServer.set_locale(lang)

func _on_platform_paused() -> void:
	pause_state[PauseSource.PLATFORM] = true
	_update_pause()

func _on_platform_resumed() -> void:
	pause_state[PauseSource.PLATFORM] = false
	_update_pause()

func _on_ad_started() -> void:
	pause_state[PauseSource.PLATFORM] = true
	_update_pause()

func _on_ad_closed() -> void:
	pass

func set_external_pause(paused: bool) -> void:
	pause_state[PauseSource.EXTERNAL] = paused
	_update_pause()

func _update_pause() -> void:
	var should_pause = pause_state[PauseSource.TAB] or pause_state[PauseSource.PLATFORM] or pause_state[PauseSource.EXTERNAL]
	
	if should_pause:
		_apply_pause()
	else:
		_apply_resume()

func _apply_pause() -> void:
	get_tree().paused = true
	AudioServer.set_bus_mute(MasterIndex, true)
	WebBus.stop_gameplay()

func _apply_resume() -> void:
	get_tree().paused = false
	if not is_muted:
		AudioServer.set_bus_mute(MasterIndex, false)
	WebBus.start_gameplay()

# Для ручного управления звуком (например, из настроек)
func set_muted(muted: bool) -> void:
	is_muted = muted
	if muted:
		AudioServer.set_bus_mute(MasterIndex, true)
	else:
		# Включаем звук только если нет активной паузы
		if not get_tree().paused:
			AudioServer.set_bus_mute(MasterIndex, false)

# Для проверки текущего состояния
func is_any_pause_active() -> bool:
	return pause_state.values().has(true)

func get_pause_sources() -> String:
	var sources = []
	if pause_state[PauseSource.TAB]:
		sources.append("TAB")
	if pause_state[PauseSource.PLATFORM]:
		sources.append("PLATFORM")
	if pause_state[PauseSource.EXTERNAL]:
		sources.append("EXTERNAL")
	return ", ".join(sources) if sources.size() > 0 else "none"
