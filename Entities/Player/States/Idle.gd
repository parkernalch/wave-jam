extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	# player.animation_player.play("idle")
	pass
	
func physics_update(_delta: float) -> void:
	var input_direction_y := Input.get_axis("down", "up")
	var input_direction_x := Input.get_axis("left", "right")

	if abs(input_direction_x) > 0.1 || abs(input_direction_y) > 0.1:
		finished.emit(PlayerState.MOVE)

	pass
