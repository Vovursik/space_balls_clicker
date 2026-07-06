extends Ball

@export var blast_radius: float = 150.0

func _self_event():
	var balls = get_tree().get_nodes_in_group("balls")
	var blast_position = global_position
	var destroyed_count = 0
	var to_destroy = []
	
	for ball in balls:
		if not is_instance_valid(ball): 
			continue
		if ball == self: 
			continue
		if ball.is_destroying or ball._destroy_started: 
			continue
		
		var distance = ball.global_position.distance_to(blast_position)
		if distance <= blast_radius:
			to_destroy.append(ball)
	
	for ball in to_destroy:
		if is_instance_valid(ball) and not ball.is_destroying and not ball._destroy_started:
			ball.is_destroying = true
			destroyed_count += 1
	
	var bonus = 0
	if destroyed_count > 0:
		bonus = destroyed_count
	
	GlobalValues.ball_score(bonus + score)
	print("Уничтожено шаров: ", destroyed_count, " | Бонус: ", bonus)
