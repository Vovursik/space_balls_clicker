extends RigidBody2D
class_name Ball

@export var hit_sound : AudioStream = null
@export var blast_sound : AudioStream = null
@export var min_pitch : float = 0.8
@export var max_pitch : float = 1.2
@export var min_volume : float = -10.0
@export var max_volume : float = 0.0

@export var score : int = 1

@export var speed : float = 400.0
@export var rand_speed : float = 50.0
@export var max_squash : float = 0.75
@export var squash_duration : float = 0.15
@export var collision_threshold : int = 40
@export var sprite2_color : Color = Color.WHITE

@onready var particle : CPUParticles2D = $CPUParticles2D

@export var kill_distance : float = 700.0

@export var death_fade_duration : float = 0.5
@export var hold_time : float = 0.3

@export var rotation_speed : float = 20.0

var squash_timer : float = 0.0
var squash_normal : Vector2 = Vector2.UP
var collision_count : int = 0
var initial_scale : Vector2
var is_power : bool = false
var is_destroying : bool = false
var _event_triggered : bool = false
var _destroy_started : bool = false
var _spawn_position : Vector2
var _death_timer : float = 0.0
var _original_modulate : Color

var target_rotation : float = 0.0
var current_rotation : float = 0.0

@onready var sprite : Sprite2D = $Sprite2D
@onready var sprite2 : Sprite2D = $Sprite2D2
@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var audio_player : AudioStreamPlayer2D = $AudioStreamPlayer2D

var sprite2_material : ShaderMaterial = null

func _ready():
	add_to_group("balls")
	GlobalValues.update_balls(1)
	
	_spawn_position = global_position
	initial_scale = sprite.scale
	_original_modulate = sprite2.modulate
	sprite2.visible = false
	
	linear_velocity = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized() * speed
	angular_velocity = 0
	
	_create_materials()
	_update_colors()
	
	var variation = randf_range(0, rand_speed)
	speed += variation
	
	current_rotation = sprite.rotation
	target_rotation = current_rotation

func _physics_process(delta):
	if squash_timer > 0:
		squash_timer -= delta
		var t = squash_timer / squash_duration
		var factor = lerp(1.0, max_squash, t)
		
		current_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)
		sprite.rotation = current_rotation
		sprite.scale = Vector2(initial_scale.x / factor, initial_scale.y * factor)
	else:
		current_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)
		sprite.rotation = current_rotation
		sprite.scale = initial_scale
	
	if not is_destroying and not _destroy_started:
		var distance = global_position.distance_to(_spawn_position)
		if distance > kill_distance:
			is_destroying = true
	
	# 👇 ОБНОВЛЕНО: плавное изменение прозрачности с задержкой через шейдер
	if _destroy_started and sprite2.visible:
		_death_timer += delta
		var progress = min(_death_timer / death_fade_duration, 1.0)
		
		# Задержка перед началом затухания
		if progress < hold_time / death_fade_duration:
			# Время задержки - держим полную видимость
			if sprite2_material:
				sprite2_material.set_shader_parameter("color", Color(sprite2_color.r, sprite2_color.g, sprite2_color.b, 1.0))
		else:
			# Плавное затухание
			var fade_progress = (progress - hold_time / death_fade_duration) / (1.0 - hold_time / death_fade_duration)
			var alpha = 1.0 - fade_progress
			
			# Применяем альфу через шейдер
			if sprite2_material:
				sprite2_material.set_shader_parameter("color", Color(sprite2_color.r, sprite2_color.g, sprite2_color.b, alpha))
			
			# Для не-шейдерного режима (если материал не шейдерный)
			var new_color = sprite2.modulate
			new_color.a = alpha
			sprite2.modulate = new_color
		
		if progress >= 1.0:
			sprite2.visible = false
			# Восстанавливаем оригинальный modulate и цвет в шейдере
			sprite2.modulate = _original_modulate
			if sprite2_material:
				sprite2_material.set_shader_parameter("color", sprite2_color)
	
	if is_destroying and not _destroy_started:
		_destroy_started = true
		_self_destroy()

func _create_materials():
	if sprite2.material and sprite2.material is ShaderMaterial:
		sprite2_material = sprite2.material.duplicate() as ShaderMaterial
		sprite2.material = sprite2_material

func _update_colors():
	if sprite2_material:
		sprite2_material.set_shader_parameter("color", sprite2_color)
	if particle:
		particle.modulate = sprite2_color

func _play_sound(sound):
	if sound and audio_player and is_instance_valid(audio_player):
		audio_player.pitch_scale = randf_range(min_pitch, max_pitch)
		audio_player.volume_db = randf_range(min_volume, max_volume)
		audio_player.stream = sound
		audio_player.play()

func _integrate_forces(state):
	if is_destroying or _destroy_started:
		return
	
	linear_velocity = linear_velocity.normalized() * speed
	
	var contact_count = state.get_contact_count()
	var destroyed_this_frame = false
	
	for i in range(contact_count):
		var collider = state.get_contact_collider_object(i)
		if collider == null:
			continue

		if is_power and collider != self and collider.is_in_group("balls"):
			if not destroyed_this_frame:
				if is_instance_valid(collider) and not collider.is_destroying and not collider._destroy_started:
					collider.is_destroying = true
				is_destroying = true
				destroyed_this_frame = true
			return
		
		var normal = state.get_contact_local_normal(i)
		
		target_rotation = normal.angle()
		squash_normal = normal.normalized()
		squash_timer = squash_duration
		
		collision_count += 1
		_play_sound(hit_sound)
		GlobalValues.shape_score(1)
		
		if collision_count >= int(collision_threshold / 2.0) and !is_power:
			sprite2.visible = true
			is_power = true
		
		if collision_count >= collision_threshold and not destroyed_this_frame:
			is_destroying = true
			destroyed_this_frame = true

func _self_destroy():
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	
	if particle:
		particle.emitting = true
	
	if collision_shape:
		collision_shape.disabled = true
	
	sprite.visible = false
	sprite2.visible = true
	_death_timer = 0.0
	
	if not _event_triggered:
		_event_triggered = true
		_self_event()
	
	GlobalValues.update_balls(-1)
	_play_sound(blast_sound)
	
	var timer = Timer.new()
	timer.wait_time = death_fade_duration + 0.2
	timer.one_shot = true
	timer.timeout.connect(_on_destroy_timer)
	get_tree().root.add_child(timer)
	timer.start()

func _on_destroy_timer():
	if is_instance_valid(self) and not is_queued_for_deletion():
		queue_free()

func _self_event():
	GlobalValues.ball_score(score)
