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

var next_form
var next_form_indicator
var next_form_index

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
	set_tint(next_form["color"])
	time_slow_timer.connect("timeout", _on_time_slow_timeout)
	signal_bus.connect("time_slow_started", _start_time_slow)
	signal_bus.connect("game_paused", _on_pause)
	
func set_tint(color: Vector4) -> void:
	if next_form_indicator:
		if next_form_indicator.material and next_form_indicator.material is ShaderMaterial:
			var amat := (next_form_indicator.material as ShaderMaterial).duplicate(true) as ShaderMaterial
			next_form_indicator.material = amat
			amat.set_shader_parameter("tint_color", color)

func show_game_over():
	var panel = get_tree().get_current_scene().get_node("UICanvas/DeathUI")  # adjust path

	panel.visible = true
	get_tree().paused = true

func  on_enemy_destroyed() -> void:
	$ExplosionPlayer.play()
	ScoreLabel.text = str(score.score)

func _on_exit() -> void:
	get_tree().paused = false
	spatial_hash.clear()
	score.reset()
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

func _start_time_slow():
	time_slow_timer.start()

func _on_powerup_collected(powerup_type):
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

func _on_form_changed(form_index):
	next_form_index = (form_index + 1) % globals.available_wave_forms.size()
	next_form = globals.available_wave_forms[next_form_index]
	set_tint(next_form["color"])

func _on_time_slow_timeout() -> void:
	globals.time_slow_active = false

func _on_resume() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func _on_pause() -> void:
	pause_menu.visible = true
	get_tree().paused = true
