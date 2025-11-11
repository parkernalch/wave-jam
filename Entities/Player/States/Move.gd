extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	pass

func physics_update(_delta: float) -> void:
	var input_direction_y := Input.get_axis("up", "down")
	var input_direction_x := Input.get_axis("left", "right")
	
	player.velocity.x = player.speed * input_direction_x
	player.velocity.y = player.speed * input_direction_y

	player.move_and_slide()

	if abs(player.velocity.x) < 0.1 && abs(player.velocity.y) < 0.1:
		finished.emit(PlayerState.IDLE)

	pass
