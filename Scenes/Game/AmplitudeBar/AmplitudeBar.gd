extends Control

@export var healthy_color = Color.GREEN
@export var caution_color = Color.YELLOW
@export var danger_color = Color.RED

@export var caution_zone = 0.6
@export var danger_zone = 0.3

var max_value = 100.0
@onready var progress = $Progress

func _ready() -> void:
	set_color()
	signal_bus.amplitude_changed.connect(update)


func update(amplitude) -> void:
	progress.value = amplitude
	set_color()

func set_color():
	if progress.value / max_value >= caution_zone:
		globals.set_tint(progress, healthy_color, 1)
	elif progress.value / max_value >= danger_zone:
		globals.set_tint(progress, caution_color, 1)
	else:
		globals.set_tint(progress, danger_color, 1)
