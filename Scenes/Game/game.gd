extends Node2D

var ScoreLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	signal_bus.connect("enemy_destroyed", on_enemy_destroyed)
	ScoreLabel = $UICanvas/UI/ColorRect/ScoreDisplay

func on_enemy_destroyed():
	ScoreLabel.text = str(score.score)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
