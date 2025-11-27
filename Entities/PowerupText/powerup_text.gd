extends Label

func _ready() -> void:
	TimerHelper.make_timer(self, 3.0, _on_destroy, true, true);

func _on_destroy() -> void:
	queue_free()
