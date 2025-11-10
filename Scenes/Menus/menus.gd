extends Control

func _ready() -> void:
	$MainMenu.visible = true
	$SettingsMenu.visible = false
	$HighScoresMenu.visible = false

func handle_menu_press():
	$MainMenu.visible = true
	$SettingsMenu.visible = false
	$HighScoresMenu.visible = false

func handle_settings_press():
	$MainMenu.visible = false
	$SettingsMenu.visible = true
	$HighScoresMenu.visible = false

func handle_high_scores_press():
	$MainMenu.visible = false
	$SettingsMenu.visible = false
	$HighScoresMenu.visible = true

func handle_start_game():
	get_tree().change_scene_to_file("res://Scenes/Game/game.tscn")
