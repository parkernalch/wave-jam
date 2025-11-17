extends TextureProgressBar


func _ready() -> void:
	signal_bus.amplitude_changed.connect(update)

func update(amplitude) -> void:
	value = amplitude
