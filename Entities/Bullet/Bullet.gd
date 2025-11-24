extends RigidBody2D

@export var bullet_speed = 200;
@export var hit_box_size: Vector2 = Vector2(15, 10) # bullet AABB size (tune as needed)

var wave_form
var damage
var all_waves
var bullet_angle
var bullet_piercing

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func shoot(bulletSpeed, waveForm, damage, all_waves, angle, bullet_piercing):
	bullet_speed = bulletSpeed
	wave_form = waveForm
	self.damage = damage
	self.all_waves = all_waves
	var color = wave_form["color"]
	set_tint(color)
	bullet_angle = angle
	self.bullet_piercing = bullet_piercing

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

	if (global_position.y < -100):
		queue_free()
		return

	for obj in candidates:
		# ensure candidate has get_aabb or else skip
		if not obj.has_method("get_aabb") || obj.has_method("take_damage"):
			continue
		var obj_rect = obj.get_aabb()
		if aabb.intersects(obj_rect):
			# narrow-phase: call enemy's hit method or do more precise shape checks
			if obj.has_method("on_hit"):
				obj.on_hit(wave_form, damage, all_waves)
				# destroy bullet after hit (adjust to your logic)
				if not bullet_piercing:
					queue_free()
			return

	linear_velocity = Vector2(bullet_angle, -bullet_speed)	
	pass
