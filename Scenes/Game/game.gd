extends Node2D

var ScoreLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	signal_bus.connect("enemy_destroyed", on_enemy_destroyed)
	ScoreLabel = $UICanvas/UI/ColorRect/ScoreDisplay
	signal_bus.connect("player_died", show_game_over)

func on_enemy_destroyed():
	ScoreLabel.text = str(score.score)

func show_game_over():
	var panel = get_tree().get_current_scene().get_node("UICanvas/DeathUI")  # adjust path

	panel.visible = true
	get_tree().paused = true

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	spatial_hash.clear()
	get_tree().change_scene_to_file("res://Scenes/Menus/menus.tscn")
