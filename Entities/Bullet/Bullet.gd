extends RigidBody2D

@export var bullet_speed = 200;
# TODO Change to wave name
var left_bullet: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func shoot(bulletSpeed, leftBullet):
	bullet_speed = bulletSpeed
	left_bullet = leftBullet
	var color = Vector4(1.0,0.0,0.0,.5) if left_bullet else Vector4(0.0,0.0,1.0,1.0)
	set_tint(color)

func set_tint(color: Vector4) -> void:
	# Root node material
	if material and material is ShaderMaterial:
		var mat := (material as ShaderMaterial).duplicate(true) as ShaderMaterial
		material = mat
		mat.set_shader_parameter("tint_color", color)
	
	# AnimatedSprite2D material
	if has_node("AnimatedSprite2D"):
		var anim := $AnimatedSprite2D
		if anim.material and anim.material is ShaderMaterial:
			var amat := (anim.material as ShaderMaterial).duplicate(true) as ShaderMaterial
			anim.material = amat
			amat.set_shader_parameter("tint_color", color)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	linear_velocity = Vector2(0, -bullet_speed)	
	pass
