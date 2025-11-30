extends Node2D

var ScoreLabel

@onready var damage_timer: Timer = $DamageBoostTimer
@onready var damage_progress_bar: ProgressBar = $UICanvas/UI/DamageIncreaseBar
@onready var all_waves_timer: Timer = $AllWavesTimer
@onready var all_waves_progress_bar: ProgressBar = $UICanvas/UI/AllWavesBar
@onready var bullet_spread_bar: ProgressBar = $UICanvas/UI/BulletSpreadBar
@onready var bullet_spread_timer: Timer = $BulletSpreadTimer
@onready var bullet_piercing_bar: ProgressBar = $UICanvas/UI/BulletPiercingBar
@onready var bullet_piercing_timer: Timer = $BulletPiercingTimer
@onready var absorb_all_forms_bar: ProgressBar = $UICanvas/UI/AbsorbAllFormsBar
@onready var absorb_all_forms_timer: Timer = $AbsorbAllFormsTimer
@onready var time_slow_timer: Timer = $TimeSlowTimer
@onready var time_slow_progress_bar: ProgressBar = $UICanvas/UI/TimeSlowBar
@onready var pause_menu: Control = $UICanvas/PauseMenu
@onready var player_name_input = $UICanvas/DeathUI/HBoxContainer/VBoxContainer/HBoxContainer2/TextEdit
@onready var death_score_label = $UICanvas/DeathUI/HBoxContainer/VBoxContainer/HBoxContainer/Label
@onready var menu_instance = preload("res://Scenes/Menus/menus.tscn").instantiate()

var next_form
var next_form_indicator
var next_form_index

var bullet_speed_count
var fire_rate_count
var speed_count

var game_over

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	next_form_index = globals.available_wave_forms.size()-1
	next_form = globals.available_wave_forms[next_form_index]
	signal_bus.connect("enemy_destroyed", on_enemy_destroyed)
	ScoreLabel = $UICanvas/UI/ColorRect/ScoreDisplay
	signal_bus.connect("player_died", show_game_over)
	signal_bus.connect("powerup_collected", _on_powerup_collected)
	damage_progress_bar.max_value = damage_timer.wait_time
	signal_bus.connect("form_changed", _on_form_changed)
	next_form_indicator = $UICanvas/UI/NextFormIndicator
	globals.set_tint(next_form_indicator, next_form["color"], .5)
	time_slow_timer.connect("timeout", _on_time_slow_timeout)
	signal_bus.connect("time_slow_started", _start_time_slow)
	signal_bus.connect("game_paused", _on_pause)
	signal_bus.connect("game_resumed", _on_resume)
	game_jolt_helper.connect("scores_fetched", _change_to_menu)
	bullet_speed_count = 0
	fire_rate_count = 0
	speed_count = 0
	player_name_input.draw_tabs = false
	player_name_input.draw_spaces = false
	game_over = false



func show_game_over():
	var panel = get_tree().get_current_scene().get_node("UICanvas/DeathUI")  # adjust path

	player_name_input.text = globals.player_name
	death_score_label.text = "Score: " + str(score.score)
	globals.time_slow_active = false

	# Submit score as guest (no username/token needed for guest scores)
	# Parameters: score, sort, username, token, guest_name, table_id

	panel.visible = true
	get_tree().paused = true
	game_over = true

func  on_enemy_destroyed() -> void:
	$Audio/ExplosionPlayer.play()
	ScoreLabel.text = str(score.score)

func _change_to_menu(request_type: String, response_code: int) -> void:
	if request_type == "scores_fetched":
		get_tree().change_scene_to_file("res://Scenes/Menus/menus.tscn")

func _on_exit() -> void:
	globals.high_scores_menu_visible = false
	globals.settings_menu_visible = false
	globals.main_menu_visible = true

	globals.add_score(player_name_input)

	clean_up_game()

	get_tree().change_scene_to_file("res://Scenes/Menus/menus.tscn")

func handle_progress_bar(progress_bar, timer) -> void:
	progress_bar.value = timer.time_left

	if timer.time_left <= 0:
		progress_bar.visible = false

func _process(_delta: float) -> void:
	handle_progress_bar(damage_progress_bar, damage_timer)
	handle_progress_bar(all_waves_progress_bar, all_waves_timer)
	handle_progress_bar(bullet_spread_bar, bullet_spread_timer)
	handle_progress_bar(bullet_piercing_bar, bullet_piercing_timer)
	handle_progress_bar(bullet_piercing_bar, bullet_piercing_timer)
	handle_progress_bar(absorb_all_forms_bar, absorb_all_forms_timer)
	handle_progress_bar(time_slow_progress_bar, time_slow_timer)

	if Input.is_action_pressed("pause"):
		if !get_tree().paused:
			signal_bus.game_resumed.emit()

func _start_time_slow():
	time_slow_timer.start()

func _on_powerup_collected(powerup_type):
	$Audio/PowerupPlayer.play()
	if powerup_type == "DAMAGE":
		damage_timer.start()
		damage_progress_bar.visible = true
	elif powerup_type == "ALL_WAVES":
		all_waves_timer.start()
		all_waves_progress_bar.visible = true
	elif powerup_type == "BULLET_SPREAD":
		bullet_spread_timer.start()
		bullet_spread_bar.visible = true
	elif powerup_type == "BULLET_PIERCING":
		bullet_piercing_timer.start()
		bullet_piercing_bar.visible = true
	elif powerup_type == "ABSORB_ALL_FORMS":
		absorb_all_forms_timer.start()
		absorb_all_forms_bar.visible = true
	elif powerup_type == "TIME_SLOW":
		time_slow_timer.start()
		time_slow_progress_bar.visible = true
	elif powerup_type == "SPEED":
		if speed_count == 0:
			$UICanvas/UI/SPEED.visible = true
		speed_count += 1
		update_stacking_count(powerup_type, speed_count)
	elif powerup_type == "FIRE_RATE":
		if fire_rate_count == 0:
			$UICanvas/UI/FIRE_RATE.visible = true
		fire_rate_count += 1
		update_stacking_count(powerup_type, fire_rate_count)
	elif powerup_type == "BULLET_SPEED":
		if bullet_speed_count == 0:
			$UICanvas/UI/BULLET_SPEED.visible = true
		bullet_speed_count += 1
		update_stacking_count(powerup_type, bullet_speed_count)


func update_stacking_count(powerup_type, count):
	$UICanvas/UI.get_node(powerup_type).get_node("Label").text = "x" + str(count);

func _on_form_changed(form_index):
	next_form_index = (form_index + 1) % globals.available_wave_forms.size()
	next_form = globals.available_wave_forms[next_form_index]
	globals.set_tint(next_form_indicator, next_form["color"], .5)

func _on_time_slow_timeout() -> void:
	globals.time_slow_active = false

func _on_resume() -> void:
	if game_over:
		return
	globals.is_paused = false
	get_tree().paused = false
	pause_menu.visible = false

func _on_pause() -> void:
	if game_over:
		return
	globals.is_paused = true
	pause_menu.visible = true
	get_tree().paused = true

func clean_up_game() -> void:
	globals.current_wave = 0
	spatial_hash.clear()
	score.reset()
	get_tree().paused = false

func _on_play_again_pressed() -> void:
	globals.add_score(player_name_input)

	clean_up_game()

	get_tree().change_scene_to_file("res://Scenes/Game/game.tscn")

func _on_high_scores_pressed() -> void:
	globals.add_score(player_name_input)

	globals.high_scores_menu_visible = true
	globals.settings_menu_visible = false
	globals.main_menu_visible = false

	clean_up_game()
	get_tree().change_scene_to_file("res://Scenes/Menus/menus.tscn")


func _on_text_edit_text_changed() -> void:
	if player_name_input.text.length() > 9:
		player_name_input.backspace()
