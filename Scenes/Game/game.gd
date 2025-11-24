extends Node2D

var ScoreLabel

@onready var damage_timer: Timer = $DamageBoostTimer
@onready var damage_progress_bar: ProgressBar = $UICanvas/UI/DamageIncreaseBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	signal_bus.connect("enemy_destroyed", on_enemy_destroyed)
	ScoreLabel = $UICanvas/UI/ColorRect/ScoreDisplay
	signal_bus.connect("player_died", show_game_over)
	signal_bus.connect("powerup_collected", _on_powerup_collected)
	damage_progress_bar.max_value = damage_timer.wait_time
	damage_timer.start()

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
	get_tree().change_scene_to_file("res://Scenes/Menus/menus.tscn")

func _process(_delta: float) -> void:
	# Update the progress bar's value to the remaining time of the damage_timer
	# As the time_left goes from wait_time down to 0, the bar decreases
	damage_progress_bar.value = damage_timer.time_left
	if damage_timer.time_left <= 0:
		damage_progress_bar.visible = false

func _on_powerup_collected(powerup_type):
	if powerup_type == "DAMAGE":
		damage_timer.start()
		damage_progress_bar.visible = true
