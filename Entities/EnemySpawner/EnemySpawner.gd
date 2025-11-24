extends Node2D

@export var wave_duration : float = 30.0
@export var enemy_count_per_wave : int = 5
@export var time_between_waves : float = 5.0
@export var initial_delay : float = 3.0
@export var spawn_min_x: int = 0
@export var spawn_max_x: int = 400
@export var spawn_y: int = 10
@export var spawn_min_distance: float = 20.0
@export var display_wave_count_duration: float = 3.0

var wave_count_label
var display_wave_count_label_timer
var wave: int = 0

@onready var ScrollingEnemyEnemy = preload("res://Entities/ScrollingEnemy/ScrollingEnemy.tscn")
@onready var HoverEnemyEnemy = preload("res://Entities/HoverEnemy/HoverEnemy.tscn")

var enemies = []
var current_enemies = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemies.append(ScrollingEnemyEnemy);
	enemies.append(HoverEnemyEnemy);
	TimerHelper.make_timer(self, wave_duration + time_between_waves, spawn_enemy_wave, false, true)
	TimerHelper.make_timer(self, initial_delay, spawn_enemy_wave, true, true)
	wave_count_label = get_parent().find_child("UICanvas").find_child("UI").find_child("WaveCounter")
	display_wave_count_label_timer = TimerHelper.make_timer(self, display_wave_count_duration, hide_wave_count_label, true, false)

func get_spawn_point() -> Vector2:
	# Try to find a spawn X that is at least `spawn_min_distance` away
	# from any existing enemy. After MAX_TRIES we fall back to a random
	# position to avoid an infinite loop.
	randomize()
	const MAX_TRIES := 50
	var tries := 0
	while tries < MAX_TRIES:
		var random_x = spawn_min_x + (randi() % max(1, spawn_max_x - spawn_min_x + 1))
		var candidate = Vector2(random_x, spawn_y)
		var ok := true
		for e in current_enemies:
			if e == null:
				continue
			var e_pos = e.position
			if e.get_parent() != null:
				e_pos = e.global_position
			if candidate.distance_to(e_pos) <= spawn_min_distance:
				ok = false
				break
		if ok:
			return candidate
		tries += 1
	# fallback
	var fallback_x = spawn_min_x + (randi() % max(1, spawn_max_x - spawn_min_x + 1))
	return Vector2(fallback_x, spawn_y)

func spawn_enemy_wave() -> void:
	wave += 1
	wave_count_label.text = "Wave: %d" % wave
	display_wave_count_label_timer.start()
	for i in range(0, enemy_count_per_wave + wave - 1):
		if i == 0:
			spawn_enemy_instance()
		else:
			TimerHelper.make_timer(self, i, spawn_enemy_instance, true, true)
		
func spawn_enemy_instance() -> void:
	randomize()
	var random_enemy_index = randi() % enemies.size()
	var enemy_instance = enemies[random_enemy_index].instantiate()
	if random_enemy_index > 0:
		spawn_y = 50
	else:
		spawn_y = 10
	enemy_instance.position = get_spawn_point()
	current_enemies.append(enemy_instance)
	get_parent().add_child(enemy_instance)

func hide_wave_count_label() -> void:
	wave_count_label.text = ""