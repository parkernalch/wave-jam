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

@onready var ScrollingEnemy = preload("res://Entities/ScrollingEnemy/ScrollingEnemy.tscn")
@onready var HoverEnemy = preload("res://Entities/HoverEnemy/HoverEnemy.tscn")
@onready var GruntEnemy = preload("res://Entities/GruntEnemy/GruntEnemy.tscn")

var enemies = []
var current_enemies = []
var available_enemies = []

var enemy_instance
var random_enemy_index

var hover_enemy_count

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemies.append(HoverEnemy);
	enemies.append(ScrollingEnemy);
	enemies.append(GruntEnemy);
	TimerHelper.make_timer(self, wave_duration + time_between_waves, spawn_enemy_wave, false, true)
	TimerHelper.make_timer(self, initial_delay, spawn_enemy_wave, true, true)
	wave_count_label = get_parent().find_child("UICanvas").find_child("UI").find_child("WaveCounter")
	display_wave_count_label_timer = TimerHelper.make_timer(self, display_wave_count_duration, hide_wave_count_label, true, false)

	var path = "user://save_file.dat"

	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var test = str(file.get_var())
		print(test == "yellow")
		globals.available_wave_forms = constants.WAVE_FORMS.values().slice(0,2)

		if (test == "green"):
			globals.available_wave_forms.append(CONSTANTS.DEFAULT_WAVE_FORMS.SAWTOOTH)
		elif (test == "yellow"):
			globals.available_wave_forms = constants.WAVE_FORMS.values()

		file.close()


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

func get_hover_enemy_count() -> int:
	# Prefer group lookup for speed and reliability
	var nodes := get_tree().get_nodes_in_group("HoverEnemy")
	if nodes.size() > 0:
		return nodes.size()

	# Fallback: scan tracked `current_enemies` and try to detect hover enemy scripts/names
	var count := 0
	for e in current_enemies:
		if e == null:
			continue
		# try script path detection
		var scr = null
		if e.has_method("get_script"):
			scr = e.get_script()
		if scr and scr.resource_path != "":
			if str(scr.resource_path).to_lower().find("hoverenemy") != -1:
				count += 1
				continue
		# fallback to name matching
		if str(e.name).to_lower().find("hoverenemy") != -1:
			count += 1

	return count


func save_to_file(input) -> void:
	var path = "user://save_file.dat"

	var file = FileAccess.open(path, FileAccess.WRITE)

	if file:
		file.store_var(input)
		file.close()

func spawn_enemy_wave() -> void:
	globals.current_wave += 1
	enemy_count_per_wave += 1
	display_wave_count_label_timer.start()

	if (globals.current_wave == 5 && globals.available_wave_forms.size() == 2):
		globals.available_wave_forms.append(CONSTANTS.DEFAULT_WAVE_FORMS.SAWTOOTH)
		save_to_file("green")
		# wave_count_label.text = "Wave: %d Sawtooth Form Added" % globals.current_wave
	elif (globals.current_wave == 15 && globals.available_wave_forms.size() == 3):
		globals.available_wave_forms.append(CONSTANTS.DEFAULT_WAVE_FORMS.SQUARE)
		save_to_file("yellow")
		# wave_count_label.text = "Wave: %d Square Form Added" % globals.current_wave
	# else:
	wave_count_label.text = "Wave: %d" % globals.current_wave

	signal_bus.wave_changed.emit(globals.current_wave)
	for i in range(0, enemy_count_per_wave + globals.current_wave - 1):
		if i == 0:
			spawn_enemy_instance()
		else:
			TimerHelper.make_timer(self, i, spawn_enemy_instance, true, true)

func spawn_enemy_instance() -> void:
	randomize()

	# update hover count each spawn attempt
	hover_enemy_count = get_hover_enemy_count()

	if hover_enemy_count > (globals.current_wave + 4) / 2:
		available_enemies = enemies.slice(1, enemies.size() - 1)
	else:
		available_enemies = enemies

	random_enemy_index = randi() % available_enemies.size()

	enemy_instance = available_enemies[random_enemy_index].instantiate()

	if random_enemy_index > 0:
		spawn_y = 50
	else:
		spawn_y = 10
	enemy_instance.position = get_spawn_point()
	current_enemies.append(enemy_instance)
	get_parent().add_child(enemy_instance)

func hide_wave_count_label() -> void:
	wave_count_label.text = ""
