extends TextureProgressBar


@export var healthy_color = Color.GREEN
@export var caution_color = Color.YELLOW
@export var danger_color = Color.RED

@export var caution_zone = 0.6
@export var danger_zone = 0.3


func _ready() -> void:
	signal_bus.amplitude_changed.connect(update)

func update(amplitude) -> void:
	value = amplitude
