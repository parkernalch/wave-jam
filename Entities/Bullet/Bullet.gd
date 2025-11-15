extends RigidBody2D

@export var bullet_speed = 200;
@export var hit_box_size: Vector2 = Vector2(8, 8) # bullet AABB size (tune as needed)

# TODO Change to wave name
var wave_form


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func shoot(bulletSpeed, waveForm):
	bullet_speed = bulletSpeed
	wave_form = waveForm
	var color = wave_form["color"]
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
	var aabb = Rect2(global_position - hit_box_size * 0.5, hit_box_size)

	var candidates = spatial_hash.query(aabb)
	for obj in candidates:
		# ensure candidate has get_aabb or else skip
		if not obj.has_method("get_aabb"):
			continue
		var obj_rect = obj.get_aabb()
		if aabb.intersects(obj_rect):
			# narrow-phase: call enemy's hit method or do more precise shape checks
			if obj.has_method("on_hit"):
				obj.on_hit(wave_form)
			# destroy bullet after hit (adjust to your logic)
			queue_free()
			return

	linear_velocity = Vector2(0, -bullet_speed)	
	pass
