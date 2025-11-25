extends RigidBody2D

@export var move_speed: float = 200.0

const POWER_UP_TYPES = [
	"SPEED",
	"FIRE_RATE",
	"DAMAGE",
	# "MAX_HEALTH",
	"ALL_WAVES",
	"BULLET_SPREAD",
	"BULLET_PIERCING",
	"BULLET_SPEED",
	"ABSORB_ALL_FORMS"
]

var powerup_type: String = ""
var available_wave_forms
var player: Player

func _ready() -> void:
	player = get_tree().get_current_scene().get_node("Player")
	randomize()	
	available_wave_forms = POWER_UP_TYPES.duplicate()

	if player.speed >= player.max_speed:
		available_wave_forms = POWER_UP_TYPES.filter(func(t): return t != "SPEED")

	if player.bullet_speed >= player.max_bullet_speed:
		available_wave_forms = available_wave_forms.filter(func(t): return t != "BULLET_SPEED")

	if player.amplitude <= 30:
		available_wave_forms = ["MAX_HEALTH"]


	powerup_type = available_wave_forms[randi() % available_wave_forms.size()]

	var powerup_image_path = "Assets/Powerups/%s.png" % powerup_type
	$Sprite2D.texture = load(powerup_image_path)
	$Sprite2D.scale = Vector2(0.1, 0.1)

func _on_pickup(body) -> void:
	signal_bus.powerup_collected.emit(powerup_type)
	queue_free()

func _physics_process(delta: float) -> void:
	linear_velocity = Vector2(0, move_speed)
