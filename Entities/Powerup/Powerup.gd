extends RigidBody2D

@export var move_speed: float = 200.0

const POWER_UP_TYPES = [
	"SPEED",
	"FIRE_RATE",
	"DAMAGE",
	"MAX_HEALTH"
]

var powerup_type: String = ""

func _ready() -> void:
	randomize()	
	powerup_type = POWER_UP_TYPES[randi() % POWER_UP_TYPES.size()]
	var powerup_image_path = "Assets/Powerups/%s.png" % powerup_type
	$Sprite2D.texture = load(powerup_image_path)
	$Sprite2D.scale = Vector2(0.3, 0.3)

func _on_pickup(body) -> void:
	signal_bus.powerup_collected.emit(powerup_type)
	queue_free()

func _physics_process(delta: float) -> void:
	linear_velocity = Vector2(0, move_speed)
