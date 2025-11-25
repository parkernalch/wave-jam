extends RigidBody2D

@export var bullet_speed = 200;
@export var hit_box_size: Vector2 = Vector2(8, 8) # bullet AABB size (tune as needed)

var current_speed
var current_wave_form

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func shoot(bulletSpeed, wave_form):
	current_wave_form = wave_form
	bullet_speed = bulletSpeed
	set_tint(current_wave_form["color"])

func set_tint(color: Vector4) -> void:
	# Root node material
	if material and material is ShaderMaterial:
		var mat := (material as ShaderMaterial).duplicate(true) as ShaderMaterial
		material = mat
		mat.set_shader_parameter("tint_color", color)
	
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

	if (global_position.y > 1000):
		queue_free()
		return

	if globals.time_slow_active:
		current_speed = bullet_speed * 0.25
	else:
		current_speed = bullet_speed

	for obj in candidates:
		# ensure candidate has get_aabb or else skip
		if not obj.has_method("get_aabb") || obj.has_method("on_hit"):
			continue
		var obj_rect = obj.get_aabb()
		if aabb.intersects(obj_rect):
			if obj.has_method("take_damage"):
				obj.take_damage(5, current_wave_form)
				spatial_hash.remove(self)
				queue_free()
			return
	# avoid calling Vector2 constructor on some runtime setups; set components directly
	linear_velocity.x = 0.0
	linear_velocity.y = current_speed
