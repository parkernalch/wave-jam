extends Control

@onready var master_value_label = $SettingsMenu/HBoxContainer/VBoxContainer/Master/Value
@onready var music_value_label = $SettingsMenu/HBoxContainer/VBoxContainer/Music/Value
@onready var sfx_value_label = $SettingsMenu/HBoxContainer/VBoxContainer/SFX/Value
@onready var master_slider = $SettingsMenu/HBoxContainer/VBoxContainer/Master/HSlider
@onready var music_slider = $SettingsMenu/HBoxContainer/VBoxContainer/Music/HSlider
@onready var sfx_slider = $SettingsMenu/HBoxContainer/VBoxContainer/SFX/HSlider

func _ready() -> void:
	$MainMenu.visible = true
	$SettingsMenu.visible = false
	$HighScoresMenu.visible = false

	master_slider.value = globals.master_volume
	music_slider.value = globals.music_volume
	sfx_slider.value = globals.sfx_volume

	master_value_label.text = str(int(round(globals.db_to_percent(globals.master_volume)))) + " %"
	music_value_label.text = str(int(round(globals.db_to_percent(globals.music_volume)))) + " %"
	sfx_value_label.text = str(int(round(globals.db_to_percent(globals.sfx_volume)))) + " %"


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

func _on_master_slider_drag_ended(value_changed) -> void:
	print(value_changed)
	# `value_changed` is expected to be dB in range [-80, 0]
	globals.master_volume = value_changed
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), globals.master_volume)
	master_value_label.text = str(int(round(globals.db_to_percent(globals.master_volume)))) + " %"

func _on_music_slider_changed(value: float) -> void:
	globals.music_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), globals.music_volume)
	music_value_label.text = str(int(round(globals.db_to_percent(globals.music_volume)))) + " %"

func _on_sfx_slider_changed(value: float) -> void:
	globals.sfx_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), globals.sfx_volume)
	sfx_value_label.text = str(int(round(globals.db_to_percent(globals.sfx_volume)))) + " %"
