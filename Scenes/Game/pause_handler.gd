extends Node2D

var allow_input: bool = true
var allow_input_timer: Timer

func _ready() -> void:
	allow_input_timer = TimerHelper.make_timer(self, .01, reset_allow_input, true, false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") && allow_input:
		if !globals.is_paused:
			signal_bus.game_paused.emit()
			allow_input = false
			allow_input_timer.start()
		else:
			signal_bus.game_resumed.emit()
			allow_input = false
			allow_input_timer.start()

func reset_allow_input() -> void:
	allow_input = true
