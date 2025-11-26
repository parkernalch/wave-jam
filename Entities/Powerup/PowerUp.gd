extends RigidBody2D

@export var drop_speed = 200

const PowerUpType = [
	{"type": "HEALTH", "img": ""},
	{"type": "SPEED", "img": ""},
	{"type": "DAMAGE", "img": ""},
	{"type": "FIRE_RATE", "img": ""}
]

var power_up_type

func _ready() -> void:
	$Area2D.connect("body_entered", _on_area_2d_area_entered)
	power_up_type = PowerUpType[randi() % PowerUpType.size()]
	print(power_up_type.type)

func _physics_process(delta: float) -> void:
	linear_velocity = Vector2(0, drop_speed)	
	
func _on_area_2d_area_entered(body) -> void:
	print("Entered:", body)
	signal_bus.powerup.emit(power_up_type.type)
	queue_free()
