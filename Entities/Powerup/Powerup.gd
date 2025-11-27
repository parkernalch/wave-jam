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
	var label_instance = power_up_label.instantiate()
	get_parent().get_node("UICanvas").get_node("UI").add_child(label_instance)
	label_instance.position = position
	if label_instance.position.x > 200:
		label_instance.position.x = 200
	if label_instance.position.y > 750:
		label_instance.position.y = 750
	label_instance.text = label_text(powerup_type)
	signal_bus.powerup_collected.emit(powerup_type)
	queue_free()

func _physics_process(delta: float) -> void:
	if globals.time_slow_active:
		current_speed = move_speed * 0.25
	else:
		current_speed = move_speed

	linear_velocity = Vector2(0, current_speed)
