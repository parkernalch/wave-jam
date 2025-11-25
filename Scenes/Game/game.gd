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
	damage_timer.start()
	signal_bus.connect("form_changed", _on_form_changed)
	next_form_indicator = $UICanvas/UI/NextFormIndicator
	set_tint(next_form["color"])

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

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	spatial_hash.clear()
	score.reset()
	get_tree().change_scene_to_file("res://Scenes/Menus/menus.tscn")

func _process(_delta: float) -> void:
	# Update the progress bar's value to the remaining time of the damage_timer
	# As the time_left goes from wait_time down to 0, the bar decreases
	damage_progress_bar.value = damage_timer.time_left
	
	if damage_timer.time_left <= 0:
		damage_progress_bar.visible = false
	
	all_waves_progress_bar.value = all_waves_timer.time_left
	
	if all_waves_timer.time_left <= 0:
		all_waves_progress_bar.visible = false

	bullet_spread_bar.value = bullet_spread_timer.time_left
	
	if bullet_spread_timer.time_left <= 0:
		bullet_spread_bar.visible = false

	bullet_piercing_bar.value = bullet_piercing_timer.time_left

	if bullet_piercing_timer.time_left <= 0:
		bullet_piercing_bar.visible = false

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

func _on_form_changed(form_index):
	next_form_index = (form_index + 1) % globals.available_wave_forms.size()
	next_form = globals.available_wave_forms[next_form_index]
	set_tint(next_form["color"])