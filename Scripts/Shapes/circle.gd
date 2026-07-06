extends Shape

func _create_collision() -> void:
	# Откладываем создание коллизий
	call_deferred("_deferred_create_collision")

func _deferred_create_collision():
	var radius = collision_radius
	var thickness = collision_thickness
	
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	
	await get_tree().process_frame
	
	_deferred_create_ring_collision(radius, thickness)

func _deferred_create_ring_collision(radius: float, thickness: float) -> void:
	var segments = 16
	
	for i in range(segments):
		var angle1 = (float(i) / segments) * 2.0 * PI
		var angle2 = (float(i + 1) / segments) * 2.0 * PI
		
		var wall = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		
		var segment_length = 2.0 * radius * PI / segments
		shape.extents = Vector2(segment_length / 2.0, thickness / 2.0)
		
		var mid_angle = (angle1 + angle2) / 2.0
		wall.position = Vector2(cos(mid_angle) * radius, sin(mid_angle) * radius)
		wall.rotation = mid_angle + PI/2
		wall.shape = shape
		
		add_child(wall)

func _draw() -> void:
	if draw_debug and _debug_mode:
		var radius = collision_radius
		var thickness = collision_thickness
		var segments = 32
		
		draw_arc(Vector2.ZERO, radius + thickness/2, 0, 2*PI, segments, debug_color, 2.0)
		draw_arc(Vector2.ZERO, radius - thickness/2, 0, 2*PI, segments, debug_color, 2.0)
		
		for i in range(8):
			var angle = i * PI/4
			var from = Vector2(cos(angle) * (radius - thickness/2), sin(angle) * (radius - thickness/2))
			var to = Vector2(cos(angle) * (radius + thickness/2), sin(angle) * (radius + thickness/2))
			draw_line(from, to, debug_color, 1.0)
