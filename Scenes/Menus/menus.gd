extends Control

@onready var master_value_label = $SettingsMenu/HBoxContainer/VBoxContainer/Master/Value
@onready var music_value_label = $SettingsMenu/HBoxContainer/VBoxContainer/Music/Value
@onready var sfx_value_label = $SettingsMenu/HBoxContainer/VBoxContainer/SFX/Value
@onready var master_slider = $SettingsMenu/HBoxContainer/VBoxContainer/Master/HSlider
@onready var music_slider = $SettingsMenu/HBoxContainer/VBoxContainer/Music/HSlider
@onready var sfx_slider = $SettingsMenu/HBoxContainer/VBoxContainer/SFX/HSlider
@onready var score_scene = preload("res://Scenes/Menus/score.tscn")

var scores_loaded = false
var score_index

func _ready() -> void:
	game_jolt_helper.scores_fetched.connect(_on_scores_received)

	get_scores()

	handle_button_press(globals.main_menu_visible, globals.settings_menu_visible, globals.high_scores_menu_visible, false)

	master_slider.value = globals.master_volume
	music_slider.value = globals.music_volume
	sfx_slider.value = globals.sfx_volume

	master_value_label.text = str(int(round(globals.db_to_percent(globals.master_volume)))) + " %"
	music_value_label.text = str(int(round(globals.db_to_percent(globals.music_volume)))) + " %"
	sfx_value_label.text = str(int(round(globals.db_to_percent(globals.sfx_volume)))) + " %"

	TimerHelper.make_timer(self, 1, check_scores, false, true)

func get_scores():
	game_jolt_helper.fetch_scores('', '', 10, 1045389)

func check_scores() -> void:
	if !scores_loaded:
		get_scores()

func handle_button_press(main_menu, settings_menu, high_scores_menu, set_globals=true):
	if set_globals:
		globals.main_menu_visible = main_menu
		globals.settings_menu_visible = settings_menu
		globals.high_scores_menu_visible = high_scores_menu

	$MainMenu.visible = globals.main_menu_visible
	$SettingsMenu.visible = globals.settings_menu_visible
	$HighScoresMenu.visible = globals.high_scores_menu_visible

func handle_menu_press():
	handle_button_press(true, false, false)

func handle_settings_press():
	handle_button_press(false, true, false)

func handle_high_scores_press():
	get_scores()
	handle_button_press(false, false, true)

func handle_start_game():
	get_tree().change_scene_to_file("res://Scenes/Game/game.tscn")

func _on_master_slider_drag_ended(value_changed) -> void:
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

func _on_scores_received(fetched_scores) -> void:
	clear_list()
	add_scores_to_list(fetched_scores)
	scores_loaded = true
	print("Scores loaded.")


func add_scores_to_list(scores) -> void:
	score_index = 1

	for score in scores:
		var score_instance = score_scene.instantiate()
		score_instance.get_node("HBoxContainer3").get_node("HBoxContainer").get_node("Username").text = score["guest"]
		score_instance.get_node("HBoxContainer3").get_node("HBoxContainer2").get_node("Score").text = str(score["score"])
		score_instance.get_node("HBoxContainer3").get_node("HBoxContainer").get_node("Place").text = str(score_index)
		score_index += 1
		$HighScoresMenu/HBoxContainer/VBoxContainer/Scores.add_child(score_instance)


func clear_list() -> void:
	for child in $HighScoresMenu/HBoxContainer/VBoxContainer/Scores.get_children():
		child.queue_free()
