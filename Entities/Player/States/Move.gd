extends PlayerState

var play_left = 0
var play_right = 400
var play_top = 0
var play_bottom = 800

func enter(previous_state_path: String, data := {}) -> void:
	pass
	
func is_in_bounds():
	if (player.global_position.x < play_left):
		return false
	if (player.global_position.x > play_right):
		return false
	if (player.global_position.y < play_top):
		return false
	if (player.global_position.y > play_bottom):
		return false
	return true

func clamp_to_play_space(_delta: float) -> void:
	if(player.global_position.x < play_left):
		player.global_position.x = play_left
	if(player.global_position.x > play_right):
		player.global_position.x = play_right
	if(player.global_position.y < play_top):
		player.global_position.y = play_top
	if (player.global_position.y > play_bottom):
		player.global_position.y = play_bottom
	return

func physics_update(_delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    
	player.velocity = dir * player.speed

	if Input.is_action_pressed("boost") && player.amplitude > 1:
		player.velocity *= player.boost_multiplier
		player.amplitude -= 20 * _delta
		signal_bus.amplitude_changed.emit(player.amplitude)

	if (is_in_bounds()):
		player.move_and_slide()
		if (!is_in_bounds()):
			clamp_to_play_space(_delta)

	if abs(player.velocity.x) < 0.1 && abs(player.velocity.y) < 0.1:
		finished.emit(PlayerState.IDLE)

	pass
