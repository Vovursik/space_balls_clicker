extends Control

signal ad_completed(success, ad_name)

const COOLDOWN := 90.0
const PREVIEW_TIME := 2
const RETRY_DELAY := 10.0

@onready var countdown: Control = self
@onready var countdown_label: Label = $CenterContainer/Control/HBoxContainer/Label2
@onready var animation_tree: AnimationTree = $AnimationTree

var cooldown_timer: Timer
var preview_timer: Timer
var retry_timer: Timer

var can_show_ad: bool = false
var pending_ad_name: String = ""
var current_count: int = PREVIEW_TIME

var _debug_mode = false

func _ready():
	if OS.is_debug_build():
		_debug_mode = true

	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = COOLDOWN
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(cooldown_timer)

	preview_timer = Timer.new()
	preview_timer.one_shot = true
	preview_timer.wait_time = 1.0
	preview_timer.timeout.connect(_on_preview_tick)
	preview_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(preview_timer)

	retry_timer = Timer.new()
	retry_timer.one_shot = true
	retry_timer.wait_time = RETRY_DELAY
	retry_timer.timeout.connect(_show_ad)
	add_child(retry_timer)

	WebBus.ad_closed.connect(_on_ad_closed)
	WebBus.ad_error.connect(_on_ad_error)
	WebBus.reward_added.connect(_on_reward_added)
	
	if animation_tree:
		animation_tree.active = true
		animation_tree.set("parameters/conditions/is_hiding", true)
		animation_tree.set("parameters/conditions/is_showing", false)
		
	_start_cooldown()

func show_ad_every_minute(ad_name: String):
	pending_ad_name = ad_name
	if can_show_ad:
		_start_preview()
	else:
		if _debug_mode: print("Ad: Ждем кулдаун")

func _start_cooldown():
	can_show_ad = false
	cooldown_timer.start()

func _on_cooldown_timeout():
	can_show_ad = true
	_start_preview()

func _start_preview():
	if countdown_label == null:
		return
	
	if animation_tree:
		animation_tree.set("parameters/conditions/is_hiding", false)
		animation_tree.set("parameters/conditions/is_showing", true)
	InitYandexGames.set_external_pause(true)
	current_count = PREVIEW_TIME
	_update_countdown_label()
	preview_timer.start()

func _on_preview_tick():
	current_count -= 1
	if current_count <= 0:
		_show_ad()
	else:
		_update_countdown_label()
		preview_timer.start()

func _update_countdown_label():
	if countdown_label != null:
		countdown_label.text = " " + str(current_count)

func _show_ad():
	if animation_tree:
		animation_tree.set("parameters/conditions/is_hiding", true)
		animation_tree.set("parameters/conditions/is_showing", false)
	
	WebBus.show_ad()

func _on_ad_closed():
	if _debug_mode: print("Ad: Реклама закрыта")
	_process_ad_result(false)  # false = без награды

func _on_reward_added():
	if _debug_mode: print("Ad: Награда получена!")
	_process_ad_result(true)  # true = с наградой

func _on_ad_error():
	_process_ad_result(false)

func _process_ad_result(success: bool):
	InitYandexGames.set_external_pause(false)
	
	if success:
		if _debug_mode: print("Ad: Реклама с наградой завершена успешно")
		emit_signal("ad_completed", true, pending_ad_name)
	else:
		if _debug_mode: print("Ad: Реклама без награды или ошибка")
		emit_signal("ad_completed", false, pending_ad_name)
	
	_start_cooldown()
