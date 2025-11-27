extends RigidBody2D

@export var move_speed: float = 200.0
var current_speed

const POWER_UP_TYPES = [
	"SPEED",
	"FIRE_RATE",
	"DAMAGE",
	"ALL_WAVES",
	"BULLET_SPREAD",
	"BULLET_PIERCING",
	"BULLET_SPEED",
	"ABSORB_ALL_FORMS",
	"TIME_SLOW"
]

var powerup_type: String = ""
var available_wave_forms
var player: Player

@onready var power_up_label = preload("res://Entities/PowerupText/powerup_label.tscn")

func _ready() -> void:
	player = get_tree().get_current_scene().get_node("Player")
	randomize()
	available_wave_forms = POWER_UP_TYPES.duplicate()

	if player.speed >= player.max_speed:
		available_wave_forms = POWER_UP_TYPES.filter(func(t): return t != "SPEED")

	if player.bullet_speed >= player.max_bullet_speed:
		available_wave_forms = available_wave_forms.filter(func(t): return t != "BULLET_SPEED")

	if player.shoot_cooldown == 0:
		available_wave_forms = available_wave_forms.filter(func(t): return t != "FIRE_RATE")

	if player.shoot_cooldown >= .20 && randi() % 6 == 0:
		available_wave_forms = ["FIRE_RATE"]

	if player.amplitude <= 30:
		available_wave_forms = ["MAX_HEALTH"]

	powerup_type = available_wave_forms[randi() % available_wave_forms.size()]

	var powerup_image_path = "Assets/Powerups/%s.png" % powerup_type
	$Sprite2D.texture = load(powerup_image_path)
	$Sprite2D.scale = Vector2(0.1, 0.1)

	# Ensure the Area2D is connected to the pickup handler so bodies trigger _on_pickup
	if has_node("Area2D"):
		var area = $Area2D
		area.connect("body_entered", _on_pickup)

func label_text(powerup_type) -> String:
	if powerup_type == "ALL_WAVES":
		return "ALL WAVES UNLOCKED"
	elif powerup_type == "FIRE_RATE":
		return "MAX FIRE RATE UP"
	elif powerup_type == "DAMAGE":
		return "DAMAGE INCREASED"
	elif powerup_type == "SPEED":
		return "MAX SPEED INCREASED"
	elif powerup_type == "BULLET_SPREAD":
		return "BULLET SPREAD INCREASED"
	elif powerup_type == "BULLET_PIERCING":
		return "BULLET PIERCING ENABLED"
	elif powerup_type == "BULLET_SPEED":
		return "MAX BULLET SPEED INCREASED"
	elif powerup_type == "ABSORB_ALL_FORMS":
		return "ABSORB ALL FORMS ENABLED"
	elif powerup_type == "TIME_SLOW":
		return "TIME SLOW ENABLED"

	return powerup_type

func _on_pickup(body) -> void:
	# Instantiate the label scene and add it to the UI at a non-overlapping position.
	var label_instance = power_up_label.instantiate()
	var ui = get_parent().get_node("UICanvas").get_node("UI")
	var desired_pos = position
	var final_pos = _find_non_overlapping_label_position(ui, desired_pos)
	label_instance.position = final_pos
	ui.add_child(label_instance)
	label_instance.text = label_text(powerup_type)
	signal_bus.powerup_collected.emit(powerup_type)
	queue_free()


func _find_non_overlapping_label_position(ui: Node, desired_pos: Vector2) -> Vector2:
	# Try stacking labels upward if there's an existing powerup label too close to desired_pos.
	var adjusted := desired_pos
	var offset := Vector2(0, -28)
	var attempts := 0
	var max_attempts := 8
	while attempts < max_attempts:
		var conflict := false
		for c in ui.get_children():
			var scr = null
			if c.get_script() != null:
				scr = c.get_script()
			if scr and typeof(scr.resource_path) == TYPE_STRING and scr.resource_path.ends_with("powerup_text.gd"):
				# distance threshold to consider as overlapping
				if c.position.distance_to(adjusted) < 100:
					conflict = true
					break
		if not conflict:
			break
		adjusted += offset
		attempts += 1

	# Clamp within UI bounds similar to original behavior
	if adjusted.x > 100:
		adjusted.x = 100
	if adjusted.y > 750:
		adjusted.y = 750

	return adjusted

func _physics_process(delta: float) -> void:
	if globals.time_slow_active:
		current_speed = move_speed * 0.25
	else:
		current_speed = move_speed

	linear_velocity = Vector2(0, current_speed)
