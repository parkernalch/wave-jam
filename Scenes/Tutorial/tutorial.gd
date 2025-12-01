extends Node2D

var dead_enemies = 0
var tutorial_done = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var path = "user://save_file.dat"

	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)

		if (file.get_var()):
			file.close()
			get_tree().change_scene_to_file("res://Scenes/Menus/menus.tscn")

	globals.available_wave_forms = constants.WAVE_FORMS.values()
	signal_bus.tutorial_enemy_killed.connect(_on_enemy_kill)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_enemy_kill() -> void:
	dead_enemies += 1
	if dead_enemies == 4:
		spatial_hash.clear()
		score.reset()
		tutorial_done = true
		var save_game = FileAccess.open("user://save_file.dat", FileAccess.WRITE)
		if save_game:
			save_game.store_var(tutorial_done)
			save_game.close()

		# var save_game = File.new()
		# save_game.open("user://savegame.save", File.WRITE)

		get_tree().change_scene_to_file("res://Scenes/Menus/menus.tscn")
