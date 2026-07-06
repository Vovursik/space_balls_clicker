extends RigidBody2D
class_name Shape

@export var rotation_speed: float = .2

@export var collision_radius: float = 1.0
@export var collision_thickness: float = 1.0

@export var draw_debug = false
@export var debug_color: Color = Color(1, 0, 0, 0.5)

var _debug_mode = false

func _ready() -> void:
	if OS.is_debug_build():
		_debug_mode = true
	
	angular_velocity = rotation_speed
	
	_create_collision()

func _physics_process(delta: float) -> void:
	rotation += rotation_speed * delta

func update_collision():
	call_deferred("_create_collision")

func _create_collision() -> void:
	pass

func _draw() -> void:
	pass
